import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/user.dart';
import '../../providers/auth_provider.dart';
import '../../routes/route_names.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_tokens.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/rc_entrance.dart';

/// Garage Partner profile — read-only view of the backend `garageProfile`
/// (the API has no garage-profile editing endpoints, so no editing controls
/// are offered) plus the account email and the existing logout flow.
class GarageProfileScreen extends StatelessWidget {
  const GarageProfileScreen({super.key});

  Future<void> _confirmLogout(BuildContext context, AuthProvider auth) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Sign out of garage?'),
        content: const Text(
          'You will need to sign in again to manage bookings.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await auth.logout();
    if (!context.mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil(
      RouteNames.login,
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final profile = user?.garageProfile;

    return Scaffold(
      appBar: AppBar(title: const Text('Garage Profile')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.sm,
          AppSpacing.lg,
          AppSpacing.xxl,
        ),
        children: [
          RcEntrance(child: _Header(profile: profile, userName: user?.name)),
          const SizedBox(height: AppSpacing.lg),
          RcEntrance(
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(AppRadius.large),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: Column(
                children: [
                  _tile(Icons.storefront_outlined, 'Garage Name',
                      profile?.garageName ?? '—'),
                  _tile(Icons.location_city_rounded, 'Address',
                      profile?.garageAddress ?? '—'),
                  _tile(Icons.radar_rounded, 'Service Radius',
                      '${_radius(profile)} km'),
                  _tile(Icons.place_outlined, 'Location',
                      profile?.hasLocation == true
                          ? profile!.locationLabel
                          : 'Not set'),
                  _tile(Icons.circle, 'Availability',
                      (profile?.isAvailable ?? false) ? 'Available' : 'Unavailable'),
                  _tile(Icons.alternate_email_rounded, 'Account Email',
                      user?.email ?? '—'),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
          RcEntrance(
            child: CustomButton(
              label: 'Sign Out',
              icon: Icons.logout_rounded,
              onPressed: () => _confirmLogout(context, auth),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          const Text(
            'Garage details are managed by RiderCraft support.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textMuted, fontSize: 12.5),
          ),
        ],
      ),
    );
  }

  static String _radius(GarageProfile? profile) {
    final radius = profile?.serviceRadiusKm;
    if (radius == null) return '15';
    return radius == radius.roundToDouble()
        ? radius.toInt().toString()
        : radius.toString();
  }

  Widget _tile(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.surfaceAlt,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final GarageProfile? profile;
  final String? userName;

  const _Header({required this.profile, required this.userName});

  @override
  Widget build(BuildContext context) {
    final available = profile?.isAvailable ?? false;
    final garageName = profile?.garageName.isNotEmpty ?? false
        ? profile!.garageName
        : (userName?.isNotEmpty ?? false ? userName! : 'Garage');

    final color = available ? AppColors.success : AppColors.error;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2A3646), Color(0xFF141A22)],
        ),
        borderRadius: BorderRadius.circular(AppRadius.hero),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.storefront_rounded, color: AppColors.primaryLight, size: 30),
          const SizedBox(height: AppSpacing.md),
          Text(
            garageName,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(AppRadius.pill),
              border: Border.all(color: color.withValues(alpha: 0.5)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.circle, size: 10, color: color),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    available ? 'AVAILABLE' : 'UNAVAILABLE',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: color,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}