import 'dart:async';
import '../models/notification_item.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final List<NotificationItem> _notifications = [];

  final StreamController<List<NotificationItem>> _notificationStreamController =
  StreamController<List<NotificationItem>>.broadcast();

  Stream<List<NotificationItem>> get notificationStream => _notificationStreamController.stream;
  Future<List<NotificationItem>> getNotifications() async {
    await Future.delayed(const Duration(milliseconds: 500));

    final allNotifications = [..._notifications];

    allNotifications.sort((a, b) => b.date.compareTo(a.date));

    return allNotifications;
  }

  Future<void> markAsRead(String id) async {
    await Future.delayed(const Duration(milliseconds: 200));

    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      final notification = _notifications[index];
      _notifications[index] = NotificationItem(
        id: notification.id,
        title: notification.title,
        body: notification.body,
        date: notification.date,
        read: true,
        conversationId: notification.conversationId,
        petName: notification.petName,
      );

      _notificationStreamController.add(_notifications);
    }
  }

  Future<void> addChatNotification({
    required String title,
    required String body,
    required String conversationId,
    required String petName,
  }) async {
    final notification = NotificationItem(
      id: 'chat_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      body: body,
      date: DateTime.now(),
      read: false,
      conversationId: conversationId,
      petName: petName,
    );

    _notifications.insert(0, notification);

    if (_notifications.length > 50) {
      _notifications.removeRange(50, _notifications.length);
    }

    _notificationStreamController.add(_notifications);
  }

  int getUnreadCount() {
    return _notifications.where((n) => !n.read).length;
  }

  Future<void> clearAllNotifications() async {
    _notifications.clear();
    _notificationStreamController.add(_notifications);
  }

  void dispose() {
    _notificationStreamController.close();
  }
}