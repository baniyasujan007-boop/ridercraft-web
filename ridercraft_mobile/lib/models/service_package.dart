/// A fixed RiderCraft service package choice.
///
/// The backend has NO service catalog. These three packages mirror the
/// backend's `packageType` enum (`basic | full | premium`) and reuse the
/// labels / summaries / included items from the existing RiderCraft web
/// client. Prices, durations, images and categories are intentionally absent
/// because the backend does not store them.
class ServicePackage {
  final String type;
  final String label;
  final String summary;
  final List<String> includes;

  const ServicePackage({
    required this.type,
    required this.label,
    required this.summary,
    required this.includes,
  });
}

const List<ServicePackage> servicePackages = [
  ServicePackage(
    type: 'basic',
    label: 'Basic Tune-Up',
    summary:
        'Brake check, chain lube, tire pressure, and quick safety inspection.',
    includes: [
      'Brake check',
      'Chain lubrication',
      'Tire pressure setup',
      'Safety inspection',
    ],
  ),
  ServicePackage(
    type: 'full',
    label: 'Full Service',
    summary:
        'Complete drivetrain cleaning, brake alignment, and multi-point diagnostics.',
    includes: [
      'Drivetrain deep clean',
      'Brake alignment',
      'Bolt torque check',
      'Multi-point diagnostics',
    ],
  ),
  ServicePackage(
    type: 'premium',
    label: 'Premium Care',
    summary:
        'Suspension setup, wheel truing, deep clean, and performance optimization.',
    includes: [
      'Suspension setup',
      'Wheel truing',
      'Full detailing',
      'Performance optimization',
    ],
  ),
];

/// Resolves a package by its backend `packageType` value.
ServicePackage servicePackageForType(String type) =>
    servicePackages.firstWhere(
      (package) => package.type == type,
      orElse: () => servicePackages.first,
    );
