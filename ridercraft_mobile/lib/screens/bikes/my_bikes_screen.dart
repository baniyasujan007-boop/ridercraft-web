import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/bike.dart';
import '../../providers/bike_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/custom_button.dart';

/// My Bike — manage the rider's motorcycles locally (the backend has no Bike
/// endpoints). The selected bike's model string is used in service bookings.
class MyBikesScreen extends StatefulWidget {
  const MyBikesScreen({super.key});

  @override
  State<MyBikesScreen> createState() => _MyBikesScreenState();
}

class _MyBikesScreenState extends State<MyBikesScreen> {
  @override
  Widget build(BuildContext context) {
    final bikesProvider = context.watch<BikeProvider>();
    final bikes = bikesProvider.bikes;

    return Scaffold(
      appBar: AppBar(title: const Text('My Bikes')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showBikeForm(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Bike'),
      ),
      body: bikes.isEmpty
          ? _EmptyBikes(onAdd: () => _showBikeForm(context))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: bikes.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final bike = bikes[index];
                final selected = bike.id == bikesProvider.selectedBike?.id;
                return _BikeTile(
                  bike: bike,
                  selected: selected,
                  onTap: () => bikesProvider.selectBike(bike.id),
                  onEdit: () => _showBikeForm(context, bike: bike),
                  onDelete: () => _confirmDelete(context, bike),
                );
              },
            ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, Bike bike) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove bike?'),
        content: Text('${bike.displayName} will be removed from your bikes.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await context.read<BikeProvider>().deleteBike(bike.id);
    }
  }

  Future<void> _showBikeForm(BuildContext context, {Bike? bike}) async {
    final brandController = TextEditingController(text: bike?.brand ?? '');
    final modelController = TextEditingController(text: bike?.model ?? '');
    final regController =
        TextEditingController(text: bike?.registrationNumber ?? '');
    final yearController = TextEditingController(text: bike?.year ?? '');
    final ccController = TextEditingController(text: bike?.engineCapacity ?? '');

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  bike == null ? 'Add your bike' : 'Edit bike',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 20),
                AppTextField(
                  controller: brandController,
                  label: 'Brand',
                  hint: 'e.g. Honda',
                  prefixIcon: Icons.directions_bike_rounded,
                  validator: (value) => (value == null || value.trim().isEmpty)
                      ? 'Brand is required'
                      : null,
                ),
                const SizedBox(height: 12),
                AppTextField(
                  controller: modelController,
                  label: 'Model',
                  hint: 'e.g. SP 125',
                  prefixIcon: Icons.settings_outlined,
                  validator: (value) => (value == null || value.trim().isEmpty)
                      ? 'Model is required'
                      : null,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: AppTextField(
                        controller: regController,
                        label: 'Registration No.',
                        hint: 'e.g. MH-12-AB-1234',
                        keyboardType: TextInputType.text,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AppTextField(
                        controller: yearController,
                        label: 'Year',
                        hint: 'e.g. 2022',
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                AppTextField(
                  controller: ccController,
                  label: 'Engine capacity (cc)',
                  hint: 'e.g. 125',
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 20),
                CustomButton(
                  label: bike == null ? 'Save Bike' : 'Update Bike',
                  onPressed: () async {
                    final providers = context.read<BikeProvider>();
                    final now = DateTime.now().millisecondsSinceEpoch.toString();
                    final newBike = Bike(
                      id: bike?.id ?? now,
                      brand: brandController.text.trim(),
                      model: modelController.text.trim(),
                      registrationNumber: regController.text.trim(),
                      year: yearController.text.trim(),
                      engineCapacity: ccController.text.trim(),
                    );
                    if (bike == null) {
                      await providers.addBike(newBike);
                    } else {
                      await providers.updateBike(newBike);
                    }
                    if (sheetContext.mounted) {
                      Navigator.of(sheetContext).pop(true);
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );

    brandController.dispose();
    modelController.dispose();
    regController.dispose();
    yearController.dispose();
    ccController.dispose();

    if (saved == true && mounted) {
      // Bike list updated via provider.
    }
  }
}

class _BikeTile extends StatelessWidget {
  final Bike bike;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _BikeTile({
    required this.bike,
    required this.selected,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.primary.withValues(alpha: 0.08) : AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.border,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.surfaceAlt,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.sports_motorsports_rounded,
                  color: AppColors.primary,
                  size: 26,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            bike.displayName,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (selected) ...[
                          const SizedBox(width: 6),
                          const Icon(
                            Icons.check_circle_rounded,
                            color: AppColors.primary,
                            size: 16,
                          ),
                        ],
                      ],
                    ),
                    if (bike.subtitle.isNotEmpty)
                      Text(
                        bike.subtitle,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Edit',
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined, size: 20),
              ),
              IconButton(
                tooltip: 'Delete',
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline_rounded,
                    size: 20, color: AppColors.error),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyBikes extends StatelessWidget {
  final VoidCallback onAdd;

  const _EmptyBikes({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.sports_motorsports_rounded,
              size: 56,
              color: AppColors.textMuted,
            ),
            const SizedBox(height: 16),
            const Text(
              'No bikes added yet.',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Add your bike to book services faster.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add Bike'),
            ),
          ],
        ),
      ),
    );
  }
}
