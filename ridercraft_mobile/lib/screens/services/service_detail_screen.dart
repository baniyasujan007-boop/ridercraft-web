import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../models/service_package.dart';
import '../../../providers/auth_provider.dart';
import '../../../routes/route_names.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_tokens.dart';
import '../../../widgets/rc_button.dart';
import '../../../widgets/rc_card.dart';
import '../main_scaffold.dart';

/// Service detail screen — shows full information about a service package
/// and provides a "Book Now" call-to-action.
class ServiceDetailScreen extends StatelessWidget {
  final ServicePackage package;

  const ServiceDetailScreen({
    super.key,
    required this.package,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(package.label),
        actions: [
          if (context.read<AuthProvider>().isAuthenticated)
            IconButton(
              icon: const Icon(Icons.calendar_month_outlined),
              tooltip: 'My Bookings',
              onPressed: () => MainScaffold.switchToTab(3),
            ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero header
            _buildHeroHeader(context, isDark),
            // Details section
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                AppSpacing.xl,
              ),
              child: _buildDetailsSection(context, isDark),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroHeader(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.xl,
      ),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.surface.withValues(alpha: 0.8)
            : AppColors.surface,
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(AppRadius.hero),
        ),
        gradient: isDark
            ? null
            : LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.primary.withValues(alpha: 0.08),
                  Colors.transparent,
                ],
              ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () => Navigator.of(context).maybePop(),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      package.label,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      package.summary,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 15,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsSection(BuildContext context, bool isDark) {
    return RcCard(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Included items
            if (package.includes.isNotEmpty) ...[
              Text(
                'Includes',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              _IncludedList(package.includes),
              const SizedBox(height: AppSpacing.md),
            ],

            // Price info note
            _priceNote(),

            const SizedBox(height: AppSpacing.md),

            // What to expect
            Text(
              'What to expect',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            _WhatToExpect(),

            const Spacer(),

            // Book Now / Sign in to book
            _buildBookNowCTA(context),
          ],
        ),
      ),
    );
  }

  Widget _buildBookNowCTA(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final isSignedIn = auth.isAuthenticated;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      transitionBuilder: (Widget child, Animation<double> animation) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.1),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        );
      },
      child: isSignedIn
          ? RcButton(
              label: 'Book Now',
              icon: Icons.calendar_today_rounded,
              onPressed: () {
                if (!context.mounted) return;
                Navigator.of(context).pushNamed(
                  RouteNames.serviceBooking,
                  arguments: package,
                );
              },
              fullWidth: true,
            )
          : RcSecondaryButton(
              label: 'Sign in to book',
              icon: Icons.login_rounded,
              onPressed: () {
                if (!context.mounted) return;
                Navigator.of(context).pushNamed(RouteNames.login);
              },
            ),
    );
  }

  Widget _priceNote() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(AppRadius.medium),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Icon(
              Icons.info_outlined,
              size: 18,
              color: AppColors.textMuted,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                'Pricing is determined after the service is completed. '
                'You will receive a final confirmation with the total cost.',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IncludedList extends StatelessWidget {
  final List<String> items;

  const _IncludedList(this.items);

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.xs,
      children: List.generate(items.length, (index) => _IncludeChip(items[index])),
    );
  }
}

class _IncludeChip extends StatelessWidget {
  final String label;

  const _IncludeChip(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

class _WhatToExpect extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Text(
      'Your motorcycle will receive expert attention using genuine parts. '
      'Service includes comprehensive diagnostics, quality checks, and a '
      'final walkthrough with recommendations for ongoing maintenance.',
      style: TextStyle(
        color: AppColors.textSecondary,
        fontSize: 14,
        height: 1.5,
      ),
    );
  }
}