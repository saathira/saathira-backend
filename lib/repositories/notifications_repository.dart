import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/network/api_client.dart';
import '../models/app_notification.dart';

class NotificationsRepository {
  NotificationsRepository(this._ref);
  final Ref _ref;

  Future<List<AppNotification>> fetchNotifications({int page = 1, int pageSize = 30}) async {
    final res = await _ref.read(apiClientProvider).get<Map<String, dynamic>>(
      '/notifications',
      queryParameters: {'page': page, 'pageSize': pageSize},
    );
    final data = res.data;
    if (data == null || data['items'] == null) return [];

    final list = data['items'] as List<dynamic>;
    return list.map((e) => AppNotification.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> updateFcmToken(String fcmToken) async {
    await _ref.read(apiClientProvider).patch<Map<String, dynamic>>(
      '/notifications/fcm-token',
      data: {'fcmToken': fcmToken},
    );
  }

  Future<void> markAsRead(String id) async {
    await _ref.read(apiClientProvider).patch<Map<String, dynamic>>('/notifications/$id/read');
  }

  Future<void> markAllAsRead() async {
    await _ref.read(apiClientProvider).post<Map<String, dynamic>>('/notifications/read-all');
  }
}

final notificationsRepositoryProvider = Provider<NotificationsRepository>((ref) {
  return NotificationsRepository(ref);
});

final notificationsListProvider = FutureProvider<List<AppNotification>>((ref) async {
  return ref.watch(notificationsRepositoryProvider).fetchNotifications();
});

final unreadNotificationsCountProvider = Provider<int>((ref) {
  final notifs = ref.watch(notificationsListProvider).value ?? [];
  return notifs.where((n) => !n.isRead).length;
});
