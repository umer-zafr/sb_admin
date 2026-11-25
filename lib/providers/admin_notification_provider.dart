import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/admin_notification_model.dart';

class AdminNotificationsNotifier extends Notifier<List<AdminNotificationItem>> {
  @override
  List<AdminNotificationItem> build() => [];

  void addNotification(AdminNotificationItem notification) {
    state = [notification, ...state];
  }

  void markAsRead(String id) {
    state = state.map((item) {
      if (item.id == id) {
        return item.copyWith(isRead: true);
      }
      return item;
    }).toList();
  }

  void markAllAsRead() {
    state = state.map((item) => item.copyWith(isRead: true)).toList();
  }

  void clearAll() {
    state = [];
  }
}

final adminNotificationsProvider =
    NotifierProvider<AdminNotificationsNotifier, List<AdminNotificationItem>>(
  AdminNotificationsNotifier.new,
);

final adminUnreadNotificationsCountProvider = Provider<int>((ref) {
  final list = ref.watch(adminNotificationsProvider);
  return list.where((item) => !item.isRead).length;
});

class LiveBannerAlertNotifier extends Notifier<AdminNotificationItem?> {
  @override
  AdminNotificationItem? build() => null;

  void setAlert(AdminNotificationItem? alert) {
    state = alert;
  }

  void clear() {
    state = null;
  }
}

final liveBannerAlertProvider =
    NotifierProvider<LiveBannerAlertNotifier, AdminNotificationItem?>(
  LiveBannerAlertNotifier.new,
);
