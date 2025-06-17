class NotificationItem {
  final String id;
  final String title;
  final String body;
  final DateTime date;
  final bool read;
  final String? conversationId;
  final String? petName;

  NotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.date,
    this.read = false,
    this.conversationId,
    this.petName,
  });

  bool get isChatNotification => conversationId != null;
}