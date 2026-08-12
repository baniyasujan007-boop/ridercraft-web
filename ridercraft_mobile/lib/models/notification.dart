/// Notification document returned by `GET /notifications`.
class AppNotification {
  final String id;
  final String title;
  final String body;
  final String type;
  final bool isRead;
  final DateTime? createdAt;

  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    this.type = 'general',
    this.isRead = false,
    this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) =>
      AppNotification(
        id: (json['_id'] ?? '') as String,
        title: (json['title'] ?? '') as String,
        body: (json['body'] ?? '') as String,
        type: (json['type'] ?? 'general') as String,
        isRead: (json['isRead'] ?? false) as bool,
        createdAt: json['createdAt'] != null
            ? DateTime.tryParse(json['createdAt'] as String)
            : null,
      );
}
