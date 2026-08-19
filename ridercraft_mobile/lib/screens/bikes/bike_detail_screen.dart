import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/bike.dart';
import '../../providers/bike_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_tokens.dart';
import '../../widgets/press_scale.dart';
import '../../widgets/rc_button.dart';
import '../../widgets/rc_entrance.dart';
import '../../widgets/rc_image.dart';
import 'widgets/bike_form_sheet.dart';
import 'widgets/delete_bike_sheet.dart';

/// Premium motorcycle detail — the rider's command-centre view of a single
/// bike. Presentational only; every action (set active, edit, remove) goes
/// through the existing BikeProvider flow.
class BikeDetailScreen extends StatefulWidget {
  final String bikeId;

  const BikeDetailScreen({super.key, required this.bikeId});

  @override
  State<BikeDetailScreen> createState() => _BikeDetailScreenState();
}

class _BikeDetailScreenState extends State<BikeDetailScreen> {
  Future<void> _openEdit(Bike bike) async {
    await showBikeFormSheet(context, bike: bike);
  }

  Future<void> _confirmDelete(Bike bike) async {
    final confirmed = await showDeleteBikeSheet(context, bike);
    if (confirmed != true || !mounted) return;
    try {
      await context.read<BikeProvider>().deleteBike(bike.id);
      if (!mounted) return;
      Navigator.of(context).pop();
    } on Exception {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not remove the bike. Please try again.'),
        ),
      );
    }
  }

  static Bike? _bikeById(List<Bike> bikes, String id) {
    for (final b in bikes) {
      if (b.id == id) return b;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BikeProvider>();
    final bike = _bikeById(provider.bikes, widget.bikeId);

    if (bike == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          foregroundColor: AppColors.textPrimary,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
        ),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(AppSpacing.xxxl),
            child: Text(
              'This bike is no longer in your garage.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 15),
            ),
          ),
        ),
      );
    }

    final isActive = provider.selectedBike?.id == bike.id;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Bike Details',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: AppSpacing.xxxl),
        children: [
          RcEntrance(child: _DetailHero(bike: bike)),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: RcEntrance(
              offset: 12,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'YOUR RIDE',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.6,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    bike.displayName,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.4,
                      height: 1.15,
                    ),
                  ),
                  if (bike.subtitle.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      bike.subtitle,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.xxl),
                  _SpecList(bike: bike),
                  const SizedBox(height: AppSpacing.xxl),
                  if (isActive)
                    _ActiveBanner()
                  else
                    RcButton(
                      label: 'Set as Active Bike',
                      icon: Icons.check_rounded,
                      onPressed: () =>
                          context.read<BikeProvider>().selectBike(bike.id),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(
            top: BorderSide(color: AppColors.borderSubtle),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                Expanded(
                  child: RcSecondaryButton(
                    label: 'Edit Details',
                    icon: Icons.edit_outlined,
                    onPressed: () => _openEdit(bike),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _RemoveButton(
                    onPressed: () => _confirmDelete(bike),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DetailHero extends StatelessWidget {
  final Bike bike;

  const _DetailHero({required this.bike});

  @override
  Widget build(BuildContext context) {
    final hasImage = bike.image.trim().isNotEmpty;
    return SizedBox(
      width: double.infinity,
      height: 240,
      child: hasImage
          ? RcImage(bike.image, fit: BoxFit.cover)
          : Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF22262E), Color(0xFF0E1013)],
                ),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Positioned(
                    right: -50,
                    top: -60,
                    child: Container(
                      width: 260,
                      height: 260,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            AppColors.primary.withValues(alpha: 0.22),
                            AppColors.primary.withValues(alpha: 0),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Center(
                    child: Icon(
                      Icons.sports_motorsports_rounded,
                      size: 130,
                      color: AppColors.primary.withValues(alpha: 0.32),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _SpecList extends StatelessWidget {
  final Bike bike;

  const _SpecList({required this.bike});

  @override
  Widget build(BuildContext context) {
    final specs = [
      ('YEAR', bike.year.isEmpty ? '—' : bike.year),
      ('ENGINE', bike.engineCapacity.isEmpty ? '—' : '${bike.engineCapacity} cc'),
      (
        'REG. NO.',
        bike.registrationNumber.isEmpty ? '—' : bike.registrationNumber,
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(AppRadius.large),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        children: [
          for (var i = 0; i < specs.length; i++) ...[
            if (i > 0)
              const Divider(
                height: 1,
                thickness: 1,
                indent: AppSpacing.lg,
                endIndent: AppSpacing.lg,
                color: AppColors.borderSubtle,
              ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      specs[i].$1,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.lg),
                  Flexible(
                    child: Text(
                      specs[i].$2,
                      textAlign: TextAlign.end,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ActiveBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.large),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.35)),
      ),
      child: const Row(
        children: [
          Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 22),
          SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              'This is your active bike — used in service bookings.',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RemoveButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _RemoveButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return PressScale(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(AppRadius.medium),
      child: Container(
        height: 50,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppRadius.medium),
          border: Border.all(color: AppColors.error.withValues(alpha: 0.45)),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.delete_outline_rounded,
              color: AppColors.error,
              size: 18,
            ),
            SizedBox(width: AppSpacing.sm),
            Text(
              'Remove',
              style: TextStyle(
                color: AppColors.error,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
