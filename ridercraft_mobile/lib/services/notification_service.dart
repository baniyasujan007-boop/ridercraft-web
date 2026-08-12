import '../models/notification.dart';
import 'api_client.dart';

/// Notification endpoints.
///
/// - GET /notifications          (auth)
/// - PUT /notifications/read-all (auth)
/// - PUT /notifications/:id/read (auth)
class NotificationService {
  final ApiClient _api;

  NotificationService(this._api);

  Future<List<AppNotification>> listNotifications() async {
    final data = await _api.get('/notifications');
    if (data is! List) return <AppNotification>[];
    return data
        .map((item) => AppNotification.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> markAllRead() async {
    await _api.put('/notifications/read-all');
  }

  Future<void> markRead(String id) async {
    await _api.put('/notifications/$id/read');
  }
}
