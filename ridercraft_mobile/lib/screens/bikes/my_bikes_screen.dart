import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/bike.dart';
import '../../providers/bike_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/loading_view.dart';

/// My Bike — manage the rider's motorcycles locally (the backend has no Bike
/// endpoints). The selected bike's model string is used in service bookings.
class MyBikesScreen extends StatefulWidget {
  const MyBikesScreen({super.key});

  @override
  State<MyBikesScreen> createState() => _MyBikesScreenState();
}

class _MyBikesScreenState extends State<MyBikesScreen> {
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _ensureLoaded();
  }

  Future<void> _ensureLoaded() async {
    try {
      final provider = context.read<BikeProvider>();
      if (!provider.loaded) await provider.load();
    } catch (_) {
      // Load failures degrade to an empty garage; the list still renders.
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bikesProvider = context.watch<BikeProvider>();
    final bikes = bikesProvider.bikes;

    return Scaffold(
      appBar: AppBar(title: const Text('My Bikes')),
      floatingActionButton: _loading
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _showBikeForm(context),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add Bike'),
            ),
      body: _loading
          ? const LoadingView(label: 'Loading bikes…')
          : bikes.isEmpty
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
    if (confirmed != true || !context.mounted) return;
    try {
      await context.read<BikeProvider>().deleteBike(bike.id);
    } on Exception {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not remove the bike. Please try again.'),
        ),
      );
    }
  }

  Future<void> _showBikeForm(BuildContext context, {Bike? bike}) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => _BikeFormSheet(bike: bike),
    );

    if (saved == true && mounted) {
      // Bike list updated via provider.
    }
  }
}

class _BikeFormSheet extends StatefulWidget {
  final Bike? bike;

  const _BikeFormSheet({this.bike});

  @override
  State<_BikeFormSheet> createState() => _BikeFormSheetState();
}

class _BikeFormSheetState extends State<_BikeFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _brandController =
      TextEditingController(text: widget.bike?.brand ?? '');
  late final TextEditingController _modelController =
      TextEditingController(text: widget.bike?.model ?? '');
  late final TextEditingController _regController =
      TextEditingController(text: widget.bike?.registrationNumber ?? '');
  late final TextEditingController _yearController =
      TextEditingController(text: widget.bike?.year ?? '');
  late final TextEditingController _ccController =
      TextEditingController(text: widget.bike?.engineCapacity ?? '');

  @override
  void dispose() {
    _brandController.dispose();
    _modelController.dispose();
    _regController.dispose();
    _yearController.dispose();
    _ccController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final providers = context.read<BikeProvider>();
    final bike = widget.bike;
    try {
      final now = DateTime.now().millisecondsSinceEpoch.toString();
      final newBike = Bike(
        id: bike?.id ?? now,
        brand: _brandController.text.trim(),
        model: _modelController.text.trim(),
        registrationNumber: _regController.text.trim(),
        year: _yearController.text.trim(),
        engineCapacity: _ccController.text.trim(),
      );
      if (bike == null) {
        await providers.addBike(newBike);
      } else {
        await providers.updateBike(newBike);
      }
      if (mounted) Navigator.of(context).pop(true);
    } on Exception {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not save your bike. Please try again.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bike = widget.bike;
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
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
                controller: _brandController,
                label: 'Brand',
                hint: 'e.g. Honda',
                prefixIcon: Icons.directions_bike_rounded,
                validator: (value) =>
                    (value == null || value.trim().isEmpty)
                        ? 'Brand is required'
                        : null,
              ),
              const SizedBox(height: 12),
              AppTextField(
                controller: _modelController,
                label: 'Model',
                hint: 'e.g. SP 125',
                prefixIcon: Icons.settings_outlined,
                validator: (value) =>
                    (value == null || value.trim().isEmpty)
                        ? 'Model is required'
                        : null,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: AppTextField(
                      controller: _regController,
                      label: 'Registration No.',
                      hint: 'e.g. MH-12-AB-1234',
                      keyboardType: TextInputType.text,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppTextField(
                      controller: _yearController,
                      label: 'Year',
                      hint: 'e.g. 2022',
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              AppTextField(
                controller: _ccController,
                label: 'Engine capacity (cc)',
                hint: 'e.g. 125',
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 20),
              CustomButton(
                label: bike == null ? 'Save Bike' : 'Update Bike',
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
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
      child: SingleChildScrollView(
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
