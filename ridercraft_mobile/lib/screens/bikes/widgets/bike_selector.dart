import 'package:flutter/material.dart';

import '../../../models/bike.dart';
import '../../../theme/app_tokens.dart';
import '../../../widgets/rc_chip.dart';

/// Horizontal garage selector for riders with more than one motorcycle.
///
/// The active bike is shown on the card with its check badge, so the selector
/// only lists the remaining bikes as plain pills. A trailing "+ Add" chip
/// opens the existing add-motorcycle flow.
class BikeSelector extends StatelessWidget {
  final List<Bike> bikes;
  final Bike? selectedBike;
  final ValueChanged<Bike> onSelect;
  final VoidCallback onAdd;

  const BikeSelector({
    super.key,
    required this.bikes,
    required this.selectedBike,
    required this.onSelect,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final others = bikes
        .where((bike) => bike.id != selectedBike?.id)
        .toList(growable: false);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Row(
        children: [
          for (final bike in others) ...[
            RcChip(
              label: bike.displayName,
              selected: false,
              onTap: () => onSelect(bike),
            ),
            const SizedBox(width: AppSpacing.sm),
          ],
          RcChip(
            label: 'Add',
            icon: Icons.add_rounded,
            selected: false,
            onTap: onAdd,
          ),
        ],
      ),
    );
  }
}