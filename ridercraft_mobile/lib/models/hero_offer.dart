/// Hero offer from `GET /hero-offers`.
class HeroOffer {
  final String id;
  final String title;
  final String offerType;
  final DateTime? startsAt;
  final DateTime? endsAt;
  final int priority;
  final String ctaQuery;
  final String status;
  final int remainingSeconds;

  const HeroOffer({
    required this.id,
    required this.title,
    this.offerType = 'tag',
    this.startsAt,
    this.endsAt,
    this.priority = 1,
    this.ctaQuery = '',
    this.status = 'active',
    this.remainingSeconds = 0,
  });

  factory HeroOffer.fromJson(Map<String, dynamic> json) => HeroOffer(
        id: (json['_id'] ?? '') as String,
        title: (json['title'] ?? '') as String,
        offerType: (json['offerType'] ?? 'tag') as String,
        startsAt: json['startsAt'] != null
            ? DateTime.tryParse(json['startsAt'] as String)
            : null,
        endsAt: json['endsAt'] != null
            ? DateTime.tryParse(json['endsAt'] as String)
            : null,
        priority: ((json['priority'] ?? 1) as num).toInt(),
        ctaQuery: (json['ctaQuery'] ?? '') as String,
        status: (json['status'] ?? 'active') as String,
        remainingSeconds: ((json['remainingSeconds'] ?? 0) as num).toInt(),
      );
}
