import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';

import '../../models/booking_draft.dart';
import '../../models/bike.dart';
import '../../models/service_package.dart';
import '../../providers/bike_provider.dart';
import '../../routes/route_names.dart';
import '../../theme/app_colors.dart';
import '../../utils/formatters.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/custom_button.dart';

/// Booking form for a selected service package.
///
/// Collects the fields `POST /service-requests` requires: bike, date, time,
/// pickup address + location, contact number, and the optional priority /
/// breakdown issue / notes. No prices, slots or availability are shown — the
/// backend does not provide them.
class ServiceBookingScreen extends StatefulWidget {
  final ServicePackage package;

  const ServiceBookingScreen({super.key, required this.package});

  @override
  State<ServiceBookingScreen> createState() => _ServiceBookingScreenState();
}

class _ServiceBookingScreenState extends State<ServiceBookingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _addressController = TextEditingController();
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();
  final _contactController = TextEditingController();
  final _breakdownController = TextEditingController();
  final _notesController = TextEditingController();

  Bike? _selectedBike;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  double? _accuracyMeters;
  DateTime? _capturedAt;
  String _priority = 'normal';
  bool _locating = false;

  @override
  void dispose() {
    _addressController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    _contactController.dispose();
    _breakdownController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 90)),
      helpText: 'Select preferred date',
    );
    if (date != null) setState(() => _selectedDate = date);
  }

  Future<void> _pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? const TimeOfDay(hour: 10, minute: 0),
      helpText: 'Select preferred time',
    );
    if (time != null) setState(() => _selectedTime = time);
  }

  Future<void> _captureLocation() async {
    setState(() => _locating = true);
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception(
            'Location services are off. Enable them or enter coordinates manually.');
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied) {
        throw Exception(
            'Location permission denied. Booking needs a pickup location.');
      }
      if (permission == LocationPermission.deniedForever) {
        throw Exception(
            'Location permission is disabled for this app. Enable it in settings '
            'or enter coordinates manually.');
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
        ),
      );
      if (!mounted) return;
      setState(() {
        _latitudeController.text =
            position.latitude.toStringAsFixed(6);
        _longitudeController.text =
            position.longitude.toStringAsFixed(6);
        _accuracyMeters = position.accuracy;
        _capturedAt = position.timestamp.toLocal();
      });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<void> _continue() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedBike == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a bike to continue.')),
      );
      return;
    }
    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a preferred date to continue.')),
      );
      return;
    }
    if (_selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a preferred time to continue.')),
      );
      return;
    }
    if (_priority == 'emergency' &&
        _breakdownController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Describe the breakdown issue for emergency service.'),
        ),
      );
      return;
    }

    final draft = BookingDraft(
      packageType: widget.package.type,
      packageLabel: widget.package.label,
      bikeModel: _selectedBike!.displayName,
      preferredDate: _selectedDate,
      preferredTime: _selectedTime,
      pickupAddress: _addressController.text.trim(),
      latitude: double.tryParse(_latitudeController.text.trim()),
      longitude: double.tryParse(_longitudeController.text.trim()),
      accuracyMeters: _accuracyMeters,
      capturedAt: _capturedAt,
      contactNumber: _contactController.text.trim(),
      priority: _priority,
      breakdownIssue: _breakdownController.text.trim(),
      notes: _notesController.text.trim(),
    );

    if (!mounted) return;
    Navigator.of(context).pushNamed(
      RouteNames.bookingReview,
      arguments: draft,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bikes = context.watch<BikeProvider>().bikes;

    return Scaffold(
      appBar: AppBar(title: Text(widget.package.label)),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _SectionHeader(title: 'Bike', icon: Icons.two_wheeler_rounded),
            const SizedBox(height: 10),
            if (bikes.isEmpty)
              _NoBikes(onAdd: () async {
                await Navigator.of(context).pushNamed(RouteNames.myBikes);
                if (!mounted) return;
                setState(() {});
              })
            else
              for (final bike in bikes) ...[
                _BikeOption(
                  bike: bike,
                  selected: bike.id == _selectedBike?.id,
                  onTap: () => setState(() => _selectedBike = bike),
                ),
                const SizedBox(height: 10),
              ],
            const Divider(height: 32),

            _SectionHeader(title: 'Preferred schedule', icon: Icons.event_rounded),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _PickerTile(
                    label: 'Date',
                    value: _selectedDate == null
                        ? 'Select date'
                        : Formatters.fullDateLabel(_selectedDate!),
                    icon: Icons.calendar_month_outlined,
                    onTap: _pickDate,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _PickerTile(
                    label: 'Time',
                    value: _selectedTime == null
                        ? 'Select time'
                        : Formatters.timeOfDayLabel(_selectedTime!),
                    icon: Icons.schedule_rounded,
                    onTap: _pickTime,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'We treat this as your requested date and time. The final slot is '
              'confirmed by RiderCraft after your booking is accepted.',
              style: TextStyle(color: AppColors.textMuted, fontSize: 12.5),
            ),
            const Divider(height: 32),

            _SectionHeader(title: 'Pickup location', icon: Icons.location_on_outlined),
            const SizedBox(height: 10),
            AppTextField(
              controller: _addressController,
              label: 'Pickup address',
              hint: 'House, street, area, city',
              prefixIcon: Icons.home_outlined,
              validator: (value) => (value == null || value.trim().isEmpty)
                  ? 'Pickup address is required'
                  : null,
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: AppTextField(
                    controller: _latitudeController,
                    label: 'Latitude',
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                      signed: true,
                    ),
                    validator: (value) => _validCoordinate(value, -90, 90)
                        ? null
                        : 'Invalid latitude',
                    onChanged: _clearGpsMetadata,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppTextField(
                    controller: _longitudeController,
                    label: 'Longitude',
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                      signed: true,
                    ),
                    validator: (value) => _validCoordinate(value, -180, 180)
                        ? null
                        : 'Invalid longitude',
                    onChanged: _clearGpsMetadata,
                  ),
                ),
              ],
            ),
            if (_accuracyMeters != null) ...[
              const SizedBox(height: 8),
              Text(
                'Captured via GPS — ${_accuracyMeters!.toStringAsFixed(0)}m accuracy',
                style: const TextStyle(color: AppColors.success, fontSize: 12.5),
              ),
            ],
            const SizedBox(height: 14),
            CustomButton(
              label: 'Use my current location',
              icon: Icons.my_location_rounded,
              backgroundColor: AppColors.surfaceElevated,
              loading: _locating,
              onPressed: _captureLocation,
            ),
            const Divider(height: 32),

            _SectionHeader(title: 'Contact', icon: Icons.phone_outlined),
            const SizedBox(height: 10),
            AppTextField(
              controller: _contactController,
              label: 'Contact number',
              hint: 'e.g. 98765 43210',
              prefixIcon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              validator: (value) {
                final cleaned = value?.trim().replaceAll(' ', '') ?? '';
                if (cleaned.isEmpty) return 'Contact number is required';
                if (cleaned.length < 10) return 'Enter a valid phone number';
                return null;
              },
            ),
            const Divider(height: 32),

            _SectionHeader(title: 'Optional details', icon: Icons.tune_rounded),
            const SizedBox(height: 10),
            Text('Priority', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _PriorityPill(
                  label: 'Normal',
                  icon: Icons.event_available_rounded,
                  selected: _priority == 'normal',
                  onTap: () => setState(() => _priority = 'normal'),
                ),
                _PriorityPill(
                  label: 'Emergency',
                  icon: Icons.emergency_rounded,
                  selected: _priority == 'emergency',
                  onTap: () => setState(() => _priority = 'emergency'),
                ),
              ],
            ),
            if (_priority == 'emergency') ...[
              const SizedBox(height: 14),
              AppTextField(
                controller: _breakdownController,
                label: 'Breakdown issue',
                hint: 'Required for emergency service',
                prefixIcon: Icons.build_outlined,
              ),
            ],
            const SizedBox(height: 14),
            AppTextField(
              controller: _notesController,
              label: 'Notes (optional)',
              hint: 'Anything the garage should know',
              prefixIcon: Icons.notes_rounded,
              textInputAction: TextInputAction.done,
            ),
            const SizedBox(height: 28),
            CustomButton(
              label: 'Continue to Review',
              icon: Icons.arrow_forward_rounded,
              onPressed: _continue,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  bool _validCoordinate(String? value, double min, double max) {
    final parsed = double.tryParse(value?.trim() ?? '');
    return parsed != null && parsed >= min && parsed <= max;
  }

  /// If the rider types coordinates after using GPS, the captured accuracy /
  /// timestamp no longer describes those coordinates, so drop them to avoid
  /// sending mismatched metadata to the backend.
  void _clearGpsMetadata(String _) {
    if (_accuracyMeters == null && _capturedAt == null) return;
    setState(() {
      _accuracyMeters = null;
      _capturedAt = null;
    });
  }
}

class _PriorityPill extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _PriorityPill({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.1)
              : AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: selected ? AppColors.primary : AppColors.textMuted,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  color: selected
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;

  const _SectionHeader({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(title, style: Theme.of(context).textTheme.titleMedium),
        ),
      ],
    );
  }
}

class _PickerTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final VoidCallback onTap;

  const _PickerTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: AppColors.textMuted),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BikeOption extends StatelessWidget {
  final Bike bike;
  final bool selected;
  final VoidCallback onTap;

  const _BikeOption({
    required this.bike,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary.withValues(alpha: 0.1) : AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.two_wheeler_rounded,
              color: selected ? AppColors.primary : AppColors.textMuted,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    bike.displayName,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (bike.subtitle.isNotEmpty)
                    Text(
                      bike.subtitle,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                ],
              ),
            ),
            Icon(
              selected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_off_rounded,
              color: selected ? AppColors.primary : AppColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}

class _NoBikes extends StatelessWidget {
  final VoidCallback onAdd;

  const _NoBikes({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.two_wheeler_rounded,
            size: 40,
            color: AppColors.textMuted,
          ),
          const SizedBox(height: 12),
          const Text(
            "You don't have a bike saved yet.",
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),
          CustomButton(
            label: 'Add My Bike',
            icon: Icons.add_rounded,
            onPressed: onAdd,
          ),
        ],
      ),
    );
  }
}
