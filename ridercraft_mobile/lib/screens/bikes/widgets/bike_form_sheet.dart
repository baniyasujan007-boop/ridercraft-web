import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../models/bike.dart';
import '../../../providers/bike_provider.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_tokens.dart';
import '../../../widgets/rc_button.dart';
import '../../auth/widgets/auth_field.dart';

/// Opens the premium add/edit motorcycle sheet. Returns `true` when a bike
/// was saved.
Future<bool?> showBikeFormSheet(BuildContext context, {Bike? bike}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => BikeFormSheet(bike: bike),
  );
}

/// Premium add/edit motorcycle sheet.
///
/// Same fields and validation as the original flow (brand, model,
/// registration, year, engine capacity) — only the presentation is redesigned
/// to the RiderCraft auth input style: dark elevated fields, RiderCraft Red
/// focus accent, animated focus glow, inline validation, and a loading save
/// state.
class BikeFormSheet extends StatefulWidget {
  final Bike? bike;

  const BikeFormSheet({super.key, this.bike});

  @override
  State<BikeFormSheet> createState() => _BikeFormSheetState();
}

class _BikeFormSheetState extends State<BikeFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _brandController;
  late final TextEditingController _modelController;
  late final TextEditingController _regController;
  late final TextEditingController _yearController;
  late final TextEditingController _ccController;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    final bike = widget.bike;
    _brandController = TextEditingController(text: bike?.brand ?? '');
    _modelController = TextEditingController(text: bike?.model ?? '');
    _regController = TextEditingController(text: bike?.registrationNumber ?? '');
    _yearController = TextEditingController(text: bike?.year ?? '');
    _ccController = TextEditingController(text: bike?.engineCapacity ?? '');
  }

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
    setState(() => _submitting = true);
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
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  String? _required(String? value, String message) =>
      (value == null || value.trim().isEmpty) ? message : null;

  /// Registration + Year sit side-by-side on wide screens and stack on
  /// narrow / high-text-scale viewports so they never overflow.
  Widget _buildRegAndYear(double maxWidth) {
    final reg = AuthField(
      controller: _regController,
      label: 'Registration No.',
      hint: 'e.g. MH-12AB-1234',
      prefixIcon: Icons.confirmation_number_outlined,
      keyboardType: TextInputType.text,
    );
    final year = AuthField(
      controller: _yearController,
      label: 'Year',
      hint: 'e.g. 2022',
      prefixIcon: Icons.calendar_month_outlined,
      keyboardType: TextInputType.number,
    );
    if (maxWidth < 400) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          reg,
          const SizedBox(height: AppSpacing.md),
          year,
        ],
      );
    }
    return Row(
      children: [
        Expanded(child: reg),
        const SizedBox(width: AppSpacing.md),
        Expanded(child: year),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final bike = widget.bike;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final isEditing = bike != null;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.hero)),
      ),
      child: Padding(
        padding: EdgeInsets.only(
          left: AppSpacing.xl,
          right: AppSpacing.xl,
          top: AppSpacing.md,
          bottom: bottomInset + AppSpacing.xxl,
        ),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                const Text(
                  'BIKE DETAILS',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  isEditing ? 'Edit bike' : 'Add your bike',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                AuthField(
                  controller: _brandController,
                  label: 'Brand',
                  hint: 'e.g. Honda',
                  prefixIcon: Icons.directions_bike_rounded,
                  validator: (value) => _required(value, 'Brand is required'),
                ),
                const SizedBox(height: AppSpacing.md),
                AuthField(
                  controller: _modelController,
                  label: 'Model',
                  hint: 'e.g. SP 125',
                  prefixIcon: Icons.settings_outlined,
                  validator: (value) => _required(value, 'Model is required'),
                ),
                const SizedBox(height: AppSpacing.md),
                LayoutBuilder(
                  builder: (context, constraints) =>
                      _buildRegAndYear(constraints.maxWidth),
                ),
                const SizedBox(height: AppSpacing.md),
                AuthField(
                  controller: _ccController,
                  label: 'Engine capacity (cc)',
                  hint: 'e.g. 125',
                  prefixIcon: Icons.speed_rounded,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.done,
                ),
                const SizedBox(height: AppSpacing.xl),
                RcButton(
                  label: isEditing ? 'Update Bike' : 'Save Bike',
                  icon: isEditing
                      ? Icons.check_rounded
                      : Icons.add_rounded,
                  loading: _submitting,
                  onPressed: _submitting ? null : _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
