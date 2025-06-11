import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/notification_item.dart';
import '../../services/notification_service.dart';
import '../../styles/colors.dart';

class NotificationsSheet extends StatefulWidget {
  const NotificationsSheet({super.key});

  @override
  State<NotificationsSheet> createState() => _NotificationsSheetState();
}

class _NotificationsSheetState extends State<NotificationsSheet> {
  final _service = NotificationService();
  late Future<List<NotificationItem>> _future;

  @override
  void initState() {
    super.initState();
    _future = _service.getNotifications();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.8,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[400], borderRadius: BorderRadius.circular(4))),
            const SizedBox(height: 12),
            Expanded(
              child: FutureBuilder(
                future: _future,
                builder: (_, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final items = snapshot.data!;
                  if (items.isEmpty) {
                    return const Center(child: Text('Brak powiadomień'));
                  }
                  return ListView.separated(
                    controller: controller,
                    padding: const EdgeInsets.all(16),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, i) => _notifTile(items[i]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _notifTile(NotificationItem n) => ListTile(
    leading: Icon(n.read ? Icons.notifications_none : Icons.notifications, color: AppColors.primaryColor),
    title: Text(n.title, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
    subtitle: Text(n.body, maxLines: 2, overflow: TextOverflow.ellipsis),
    trailing: Text('${n.date.hour}:${n.date.minute.toString().padLeft(2, '0')}'),
    onTap: () async {
      await _service.markAsRead(n.id);
      Navigator.pop(context);
    },
  );
}