import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/user.dart';
import '../../providers/auth_provider.dart';
import '../../routes/route_names.dart';
import '../../services/api_exception.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/loading_view.dart';
import '../../widgets/rc_image.dart';
import '../main_scaffold.dart';

/// Profile tab — the rider's account backed by the real `GET/PUT /auth/profile`
/// endpoints, matching the website's profile settings (name, email, contact
/// number, delivery address), plus links to the existing Orders, Bookings,
/// Notifications and My Bikes screens and a signed-out flow.
///
/// Guests see a sign-in prompt; while the session is restoring a loading state
/// is shown. The layout is responsive (centred constrained column on tablets)
/// and never overflows at small widths or large system text.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  bool _initialized = false;
  bool _saving = false;
  String? _formError;
  String? _formSuccess;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final auth = context.read<AuthProvider>();
    if (!_initialized && auth.isAuthenticated) {
      _initialized = true;
      _syncFromUser(auth.user);
      // Refresh the profile so the form always shows the latest server data.
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        try {
          final user = await context.read<AuthProvider>().reloadProfile();
          _applyUser(user);
        } catch (_) {
          // Refresh failure is non-fatal: the cached profile stays visible.
        }
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _contactController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _syncFromUser(User? user) {
    if (user == null) return;
    _nameController.text = user.name;
    _emailController.text = user.email;
    _contactController.text = user.contactNumber;
    _addressController.text = user.deliveryAddress;
  }

  void _applyUser(User? user) {
    if (!mounted) return;
    setState(() => _syncFromUser(user));
  }

  Future<void> _reload() async {
    final auth = context.read<AuthProvider>();
    try {
      await auth.reloadProfile();
    } catch (_) {
      // Keep showing the current profile on refresh failure.
    }
    if (!mounted) return;
    setState(() {
      _formError = null;
      _formSuccess = null;
      _syncFromUser(auth.user);
    });
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() {
        _formError = 'Name is required.';
        _formSuccess = null;
      });
      return;
    }

    setState(() {
      _saving = true;
      _formError = null;
      _formSuccess = null;
    });

    final auth = context.read<AuthProvider>();
    try {
      await auth.updateProfile(
        name: name,
        contactNumber: _contactController.text.trim(),
        deliveryAddress: _addressController.text.trim(),
      );
      if (!mounted) return;
      setState(() {
        _saving = false;
        _formSuccess = 'Profile updated successfully';
      });
      _syncFromUser(auth.user);
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _formError = error.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _formError = 'Failed to update profile. Please try again.';
      });
    }
  }

  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text(
          'You will need to sign back in to see your orders and bookings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
            ),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final auth = context.read<AuthProvider>();
    await auth.logout();
    if (!mounted) return;
    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil(RouteNames.login, (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          if (auth.isAuthenticated)
            IconButton(
              tooltip: 'Refresh profile',
              icon: const Icon(Icons.refresh_rounded),
              onPressed: _reload,
            ),
        ],
      ),
      body: _buildBody(auth, user),
    );
  }

  Widget _buildBody(AuthProvider auth, User? user) {
    if (auth.isRestoring || auth.status == AuthStatus.unknown) {
      return const LoadingView(label: 'Loading profile…');
    }
    if (!auth.isAuthenticated || user == null) {
      return const _GuestProfileView();
    }

    return RefreshIndicator(
      onRefresh: _reload,
      color: AppColors.primary,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final maxWidth = constraints.maxWidth >= 680 ? 600.0 : double.infinity;
          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _ProfileHeaderCard(user: user),
                    const SizedBox(height: 16),
                    _ProfileFormCard(
                      nameController: _nameController,
                      emailController: _emailController,
                      contactController: _contactController,
                      addressController: _addressController,
                      saving: _saving,
                      errorText: _formError,
                      successText: _formSuccess,
                      onSave: _save,
                    ),
                    const SizedBox(height: 16),
                    const _AccountLinksCard(),
                    const SizedBox(height: 16),
                    _SignOutCard(onLogout: _confirmLogout),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Guest (unauthenticated) state: a sign-in prompt matching the Bookings and
/// Notifications tabs.
class _GuestProfileView extends StatelessWidget {
  const _GuestProfileView();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 24),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.lock_outline_rounded,
                  size: 48,
                  color: AppColors.textMuted,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Sign in to manage your rider profile.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Save your details, track orders and manage service '
                  'bookings.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                ),
                const SizedBox(height: 20),
                CustomButton(
                  label: 'Sign in',
                  icon: Icons.login_rounded,
                  onPressed: () =>
                      Navigator.of(context).pushNamed(RouteNames.login),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ProfileHeaderCard extends StatelessWidget {
  final User user;

  const _ProfileHeaderCard({required this.user});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            _Avatar(user: user),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.name.isEmpty ? 'Rider' : user.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    user.email,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                  if (user.contactNumber.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          Icons.phone_outlined,
                          size: 14,
                          color: AppColors.textMuted,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            user.contactNumber,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final User user;

  const _Avatar({required this.user});

  @override
  Widget build(BuildContext context) {
    const size = 64.0;
    if (user.avatar.trim().isNotEmpty) {
      return ClipOval(
        child: RcImage(user.avatar, width: size, height: size),
      );
    }

    final initials = (user.name.trim().isEmpty
            ? 'R'
            : user.name
                .trim()
                .split(RegExp(r'\s+'))
                .where((part) => part.isNotEmpty)
                .take(2)
                .map((part) => part[0].toUpperCase())
                .join())
        .toUpperCase();

    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: AppColors.primaryGradient,
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Text(
            initials,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileFormCard extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController contactController;
  final TextEditingController addressController;
  final bool saving;
  final String? errorText;
  final String? successText;
  final VoidCallback onSave;

  const _ProfileFormCard({
    required this.nameController,
    required this.emailController,
    required this.contactController,
    required this.addressController,
    required this.saving,
    required this.errorText,
    required this.successText,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Profile Settings',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Keep your details up to date for faster delivery.',
              style: TextStyle(color: AppColors.textMuted, fontSize: 12.5),
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: nameController,
              label: 'Full Name',
              hint: 'Your full name',
              prefixIcon: Icons.person_outline_rounded,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),
            AppTextField(
              controller: emailController,
              label: 'Email',
              prefixIcon: Icons.alternate_email_rounded,
              enabled: false,
            ),
            const SizedBox(height: 12),
            AppTextField(
              controller: contactController,
              label: 'Contact Number',
              hint: '+1 555 000 0000',
              prefixIcon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),
            AppTextField(
              controller: addressController,
              label: 'Delivery Address',
              hint: 'Street, City, State, ZIP',
              prefixIcon: Icons.location_on_outlined,
              keyboardType: TextInputType.multiline,
              textInputAction: TextInputAction.newline,
              onChanged: null,
            ),
            if (successText != null) ...[
              const SizedBox(height: 12),
              Text(
                successText!,
                style: const TextStyle(color: AppColors.success, fontSize: 13),
              ),
            ],
            if (errorText != null) ...[
              const SizedBox(height: 12),
              Text(
                errorText!,
                style: const TextStyle(color: AppColors.error, fontSize: 13),
              ),
            ],
            const SizedBox(height: 18),
            CustomButton(
              label: 'Save Changes',
              icon: Icons.save_outlined,
              loading: saving,
              onPressed: saving ? null : onSave,
            ),
          ],
        ),
      ),
    );
  }
}

class _AccountLinksCard extends StatelessWidget {
  const _AccountLinksCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'Your Account',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          _MenuTile(
            icon: Icons.receipt_long_outlined,
            title: 'My Orders',
            subtitle: 'Track and review your orders',
            onTap: () => Navigator.of(context).pushNamed(RouteNames.orders),
          ),
          const _MenuDivider(),
          _MenuTile(
            icon: Icons.calendar_month_outlined,
            title: 'My Bookings',
            subtitle: 'Your service schedule',
            onTap: () => MainScaffold.switchToTab(3),
          ),
          const _MenuDivider(),
          _MenuTile(
            icon: Icons.notifications_outlined,
            title: 'Notifications',
            subtitle: 'Order and service alerts',
            onTap: () =>
                Navigator.of(context).pushNamed(RouteNames.notifications),
          ),
          const _MenuDivider(),
          _MenuTile(
            icon: Icons.sports_motorsports_outlined,
            title: 'My Bikes',
            subtitle: 'Your garage',
            onTap: () => Navigator.of(context).pushNamed(RouteNames.myBikes),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _MenuDivider extends StatelessWidget {
  const _MenuDivider();

  @override
  Widget build(BuildContext context) {
    return const Divider(
      height: 1,
      thickness: 1,
      indent: 16,
      endIndent: 16,
      color: AppColors.border,
    );
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _MenuTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppColors.primary, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
      ),
      trailing: const Icon(
        Icons.chevron_right_rounded,
        size: 20,
        color: AppColors.textMuted,
      ),
    );
  }
}

class _SignOutCard extends StatelessWidget {
  final VoidCallback onLogout;

  const _SignOutCard({required this.onLogout});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Sign Out',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Log out of your RiderCraft account on this device.',
              style: TextStyle(color: AppColors.textMuted, fontSize: 12.5),
            ),
            const SizedBox(height: 14),
            CustomButton(
              label: 'Logout',
              icon: Icons.logout_rounded,
              backgroundColor: AppColors.surfaceElevated,
              onPressed: onLogout,
            ),
          ],
        ),
      ),
    );
  }
}