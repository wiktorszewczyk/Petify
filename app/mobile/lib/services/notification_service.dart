import 'dart:async';
import '../models/notification_item.dart';

class NotificationService {
  Future<List<NotificationItem>> getNotifications() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return List.generate(8, NotificationItem.fake);
  }

  Future<void> markAsRead(String id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    // TODO: call API
  }
}