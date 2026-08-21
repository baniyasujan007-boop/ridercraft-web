import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart' show ImageSource;
import 'package:provider/provider.dart';

import '../../models/user.dart';
import '../../providers/auth_provider.dart';
import '../../routes/route_names.dart';
import '../../services/api_exception.dart';
import '../../services/avatar_image_picker.dart';
import '../../theme/app_colors.dart';
import '../../utils/avatar_processor.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/rc_button.dart';
import '../../widgets/rc_card.dart';
import '../../widgets/rc_image.dart';
import '../../widgets/rc_skeleton.dart';
import '../../widgets/section_header.dart';
import '../../widgets/staggered_entry.dart';
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
  /// Injectable picker so widget tests can fake the native photo picker.
  final AvatarImagePicker picker;

  const ProfileScreen({super.key, this.picker = const AvatarImagePicker()});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  bool _initialized = false;
  bool _saving = false;
  bool _avatarChanging = false;
  String? _formError;
  String? _formSuccess;
  String? _avatarPreviewUri;

  late final AnimationController _entranceController;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
  }

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
    // Start entrance animation once after first build
    if (!_entranceController.isAnimating && _entranceController.value == 0) {
      if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
        _entranceController.value = 1;
      } else {
        _entranceController.forward();
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _contactController.dispose();
    _addressController.dispose();
    _entranceController.dispose();
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

  Future<void> _showAvatarOptions() async {
    if (_avatarChanging || _saving) return;
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(sheetContext).size.height * 0.6,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Change profile picture',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 16),
                _AvatarOptionTile(
                  icon: Icons.camera_alt_outlined,
                  title: 'Take Photo',
                  onTap: () => Navigator.of(sheetContext).pop(ImageSource.camera),
                ),
                const SizedBox(height: 8),
                _AvatarOptionTile(
                  icon: Icons.photo_library_outlined,
                  title: 'Choose from Gallery',
                  onTap: () =>
                      Navigator.of(sheetContext).pop(ImageSource.gallery),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => Navigator.of(sheetContext).pop(),
                  child: const Text('Cancel'),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (source == null || !mounted) return;
    await _changeAvatar(source);
  }

  Future<void> _changeAvatar(ImageSource source) async {
    setState(() {
      _avatarChanging = true;
      _formError = null;
      _formSuccess = null;
    });

    final messenger = ScaffoldMessenger.of(context);
    try {
      final bytes = source == ImageSource.camera
          ? await widget.picker.pickCamera()
          : await widget.picker.pickGallery();
      if (bytes == null) {
        // User dismissed the picker: do nothing.
        if (!mounted) return;
        setState(() => _avatarChanging = false);
        return;
      }

      final dataUri = AvatarProcessor.processImage(bytes);
      if (!mounted) return;
      setState(() => _avatarPreviewUri = dataUri);

      await context.read<AuthProvider>().updateProfile(avatar: dataUri);

      if (!mounted) return;
      setState(() {
        _avatarChanging = false;
        _avatarPreviewUri = null;
      });
      messenger.showSnackBar(
        const SnackBar(content: Text('Profile picture updated')),
      );
    } on AvatarProcessException catch (error) {
      if (!mounted) return;
      setState(() {
        _avatarChanging = false;
        _avatarPreviewUri = null;
      });
      messenger.showSnackBar(SnackBar(content: Text(error.message)));
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _avatarChanging = false;
        _avatarPreviewUri = null;
      });
      messenger.showSnackBar(SnackBar(content: Text(error.message)));
    } on PlatformException catch (_) {
      // e.g. camera unavailable / permission denied on the platform side.
      if (!mounted) return;
      setState(() {
        _avatarChanging = false;
        _avatarPreviewUri = null;
      });
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Could not open the camera or photo library.'),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _avatarChanging = false;
        _avatarPreviewUri = null;
      });
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'Failed to update profile picture. Please try again.',
          ),
        ),
      );
    }
  }

  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surface,
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

  Future<void> _showForgotPassword() async {
    final emailController = TextEditingController(
      text: _emailController.text,
    );
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Reset Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter your email address and we\'ll send you a link to reset your password.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: emailController,
              label: 'Email',
              hint: 'your@email.com',
              prefixIcon: Icons.alternate_email_rounded,
              keyboardType: TextInputType.emailAddress,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Send Reset Link'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final email = emailController.text.trim();
    if (email.isEmpty) return;

    final messenger = ScaffoldMessenger.of(context);
    try {
      await context.read<AuthProvider>().forgotPassword(email: email);
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(content: Text('Password reset link sent')),
      );
    } on ApiException catch (error) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(error.message)));
    } catch (_) {
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Failed to send reset link. Please try again.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        centerTitle: false,
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
      return const ProfileSkeleton();
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
                    // Profile Hero
                    StaggeredEntry(
                      parent: _entranceController,
                      index: 0,
                      child: _ProfileHeroCard(
                        user: user,
                        avatarLoading: _avatarChanging,
                        avatarPreviewUri: _avatarPreviewUri,
                        onChangePhoto: _showAvatarOptions,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Personal Info
                    StaggeredEntry(
                      parent: _entranceController,
                      index: 1,
                      child: _ProfileInfoCard(
                        user: user,
                        saving: _saving,
                        errorText: _formError,
                        successText: _formSuccess,
                        nameController: _nameController,
                        emailController: _emailController,
                        contactController: _contactController,
                        addressController: _addressController,
                        onSave: _save,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Account Actions
                    StaggeredEntry(
                      parent: _entranceController,
                      index: 2,
                      child: _AccountActionsCard(
                        onMyOrders: () =>
                            Navigator.of(context).pushNamed(RouteNames.orders),
                        onMyBookings: () => MainScaffold.switchToTab(3),
                        onNotifications: () =>
                            Navigator.of(context).pushNamed(RouteNames.notifications),
                        onMyBikes: () =>
                            Navigator.of(context).pushNamed(RouteNames.myBikes),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Security
                    StaggeredEntry(
                      parent: _entranceController,
                      index: 3,
                      child: _SecurityCard(
                        onForgotPassword: _showForgotPassword,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Sign Out
                    StaggeredEntry(
                      parent: _entranceController,
                      index: 4,
                      child: _SignOutCard(onLogout: _confirmLogout),
                    ),
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

/// Skeleton loading state for the profile screen.
class ProfileSkeleton extends StatelessWidget {
  const ProfileSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: Text(
            'Loading profile…',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
          ),
        ),
        const Divider(height: 1, color: AppColors.borderSubtle),
        Expanded(
          child: RcSkeleton(
            child: ListView(
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              children: const [
                RcSkeletonBox(width: double.infinity, height: 140),
                SizedBox(height: 16),
                RcSkeletonBox(width: double.infinity, height: 320),
                SizedBox(height: 16),
                RcSkeletonBox(width: double.infinity, height: 240),
                SizedBox(height: 16),
                RcSkeletonBox(width: double.infinity, height: 180),
                SizedBox(height: 16),
                RcSkeletonBox(width: double.infinity, height: 120),
              ],
            ),
          ),
        ),
      ],
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
        const SizedBox(height: 48),
        RcCard(
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
              RcButton(
                label: 'Sign in',
                icon: Icons.login_rounded,
                onPressed: () =>
                    Navigator.of(context).pushNamed(RouteNames.login),
                fullWidth: false,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Premium profile hero card with large avatar and key info.
class _ProfileHeroCard extends StatelessWidget {
  final User user;
  final bool avatarLoading;
  final String? avatarPreviewUri;
  final VoidCallback onChangePhoto;

  const _ProfileHeroCard({
    required this.user,
    required this.avatarLoading,
    required this.avatarPreviewUri,
    required this.onChangePhoto,
  });

  @override
  Widget build(BuildContext context) {
    return RcCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              _EditableAvatar(
                user: user,
                previewUri: avatarPreviewUri,
                loading: avatarLoading,
                onTap: onChangePhoto,
              ),
              if (avatarLoading)
                Positioned.fill(
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Color(0x80000000),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: SizedBox(
                        width: 28,
                        height: 28,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            user.name.isEmpty ? 'Rider' : user.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            user.email,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

/// The profile picture with an edit badge; tapping opens the change-photo
/// options. While a new picture is being picked/uploaded a spinner covers the
/// avatar and the tapped image is previewed immediately.
class _EditableAvatar extends StatelessWidget {
  final User user;
  final String? previewUri;
  final bool loading;
  final VoidCallback onTap;

  const _EditableAvatar({
    required this.user,
    this.previewUri,
    required this.loading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const double size = 96;

    final display =
        previewUri ?? (user.avatar.trim().isNotEmpty ? user.avatar : '');

    final avatar = Stack(
      clipBehavior: Clip.none,
      children: [
        if (display.isNotEmpty)
          ClipOval(
            child: RcImage(display, width: size, height: size, fit: BoxFit.cover),
          )
        else
          Container(
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
                padding: const EdgeInsets.all(24),
                child: Text(
                  _initials(user),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 30,
                  ),
                ),
              ),
            ),
          ),
        Positioned(
          right: 0,
          bottom: 0,
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.border, width: 1.5),
            ),
            child: Icon(
              Icons.photo_camera_outlined,
              size: 16,
              color: AppColors.primary,
            ),
          ),
        ),
      ],
    );

    return Tooltip(
      message: 'Change profile picture',
      child: InkWell(
        borderRadius: BorderRadius.circular(size / 2),
        onTap: loading ? null : onTap,
        child: avatar,
      ),
    );
  }

  String _initials(User user) {
    final parts = user.name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0].toUpperCase())
        .toList();
    final init = (parts.isEmpty ? 'R' : parts.join()).toUpperCase();
    return init;
  }
}

/// Avatar option tile for the change-photo bottom sheet.
class _AvatarOptionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _AvatarOptionTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: AppColors.primaryLight,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Personal information card with editable fields.
class _ProfileInfoCard extends StatelessWidget {
  final User user;
  final bool saving;
  final String? errorText;
  final String? successText;
  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController contactController;
  final TextEditingController addressController;
  final VoidCallback onSave;

  const _ProfileInfoCard({
    required this.user,
    required this.saving,
    required this.errorText,
    required this.successText,
    required this.nameController,
    required this.emailController,
    required this.contactController,
    required this.addressController,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return RcCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SectionHeader(
            kicker: 'Profile',
            title: 'Profile Settings',
            showDivider: true,
          ),
          const SizedBox(height: 8),
          const Text(
            'Keep your details up to date for faster delivery.',
            style: TextStyle(color: AppColors.textMuted, fontSize: 12.5),
          ),
          const SizedBox(height: 20),
          AppTextField(
            controller: nameController,
            label: 'Full Name',
            hint: 'Your full name',
            prefixIcon: Icons.person_outline_rounded,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 16),
          AppTextField(
            controller: emailController,
            label: 'Email',
            prefixIcon: Icons.alternate_email_rounded,
            enabled: false,
          ),
          const SizedBox(height: 16),
          AppTextField(
            controller: contactController,
            label: 'Contact Number',
            hint: '+1 555 000 0000',
            prefixIcon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 16),
          AppTextField(
            controller: addressController,
            label: 'Delivery Address',
            hint: 'Street, City, State, ZIP',
            prefixIcon: Icons.location_on_outlined,
            keyboardType: TextInputType.multiline,
            textInputAction: TextInputAction.newline,
          ),
          if (successText != null) ...[
            const SizedBox(height: 16),
            Text(
              successText!,
              style: const TextStyle(color: AppColors.success, fontSize: 13),
            ),
          ],
          if (errorText != null) ...[
            const SizedBox(height: 16),
            Text(
              errorText!,
              style: const TextStyle(color: AppColors.error, fontSize: 13),
            ),
          ],
          const SizedBox(height: 20),
          RcButton(
            label: 'Save Changes',
            icon: Icons.save_outlined,
            loading: saving,
            onPressed: saving ? null : onSave,
          ),
        ],
      ),
    );
  }
}

/// Account actions card with grouped sections.
class _AccountActionsCard extends StatelessWidget {
  final VoidCallback onMyOrders;
  final VoidCallback onMyBookings;
  final VoidCallback onNotifications;
  final VoidCallback onMyBikes;

  const _AccountActionsCard({
    required this.onMyOrders,
    required this.onMyBookings,
    required this.onNotifications,
    required this.onMyBikes,
  });

  @override
  Widget build(BuildContext context) {
    return RcCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SectionHeader(
            kicker: 'Account',
            title: 'Your Account',
            showDivider: true,
          ),
          _ActionTile(
            icon: Icons.receipt_long_outlined,
            title: 'My Orders',
            subtitle: 'Track and review your orders',
            onTap: onMyOrders,
          ),
          const _ActionDivider(),
          _ActionTile(
            icon: Icons.calendar_month_outlined,
            title: 'My Bookings',
            subtitle: 'Your service schedule',
            onTap: onMyBookings,
          ),
          const _ActionDivider(),
          _ActionTile(
            icon: Icons.notifications_outlined,
            title: 'Notifications',
            subtitle: 'Order and service alerts',
            onTap: onNotifications,
          ),
          const _ActionDivider(),
          _ActionTile(
            icon: Icons.sports_motorsports_outlined,
            title: 'My Bikes',
            subtitle: 'Your garage',
            onTap: onMyBikes,
          ),
        ],
      ),
    );
  }
}

class _ActionDivider extends StatelessWidget {
  const _ActionDivider();

  @override
  Widget build(BuildContext context) {
    return const Divider(
      height: 1,
      thickness: 1,
      indent: 16,
      endIndent: 16,
      color: AppColors.borderSubtle,
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.surfaceAlt,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppColors.primary, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12.5,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: AppColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}

/// Security card with password reset functionality.
class _SecurityCard extends StatelessWidget {
  final VoidCallback onForgotPassword;

  const _SecurityCard({required this.onForgotPassword});

  @override
  Widget build(BuildContext context) {
    return RcCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SectionHeader(
            kicker: 'Security',
            title: 'Account Security',
            showDivider: true,
          ),
          _ActionTile(
            icon: Icons.lock_outline_rounded,
            title: 'Change Password',
            subtitle: 'Forgot your password? Reset it here',
            onTap: onForgotPassword,
          ),
        ],
      ),
    );
  }
}

/// Sign out card.
class _SignOutCard extends StatelessWidget {
  final VoidCallback onLogout;

  const _SignOutCard({required this.onLogout});

  @override
  Widget build(BuildContext context) {
    return RcCard(
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
            RcSecondaryButton(
              label: 'Logout',
              icon: Icons.logout_rounded,
              onPressed: onLogout,
            ),
          ],
        ),
      ),
    );
  }
}