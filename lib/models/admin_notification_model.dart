class AdminNotificationItem {
  AdminNotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.timestamp,
    required this.type,
    this.route,
    this.isRead = false,
  });

  final String id;
  final String title;
  final String message;
  final DateTime timestamp;
  final String type; // 'application', 'booking', 'payment'
  final String? route;
  bool isRead;

  AdminNotificationItem copyWith({
    String? id,
    String? title,
    String? message,
    DateTime? timestamp,
    String? type,
    String? route,
    bool? isRead,
  }) {
    return AdminNotificationItem(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      timestamp: timestamp ?? this.timestamp,
      type: type ?? this.type,
      route: route ?? this.route,
      isRead: isRead ?? this.isRead,
    );
  }
}
