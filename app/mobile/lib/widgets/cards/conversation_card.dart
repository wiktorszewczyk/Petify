import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../models/message_model.dart';
import '../../styles/colors.dart';

class ConversationCard extends StatelessWidget {
  final ConversationModel conversation;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const ConversationCard({
    super.key,
    required this.conversation,
    required this.onTap,
    required this.onDelete,
  });

  ImageProvider _getImageProvider(String path) {
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return NetworkImage(path);
    } else {
      return AssetImage(path);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(conversation.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white, size: 28),
      ),
      onDismissed: (_) => onDelete(),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.primaryColor, width: 2),
                      image: DecorationImage(
                        fit: BoxFit.cover,
                        image: _getImageProvider(conversation.petImageUrl),
                        onError: (exception, stackTrace) {
                          return const AssetImage('assets/images/pet_placeholder.png');
                        } as ImageErrorListener,
                      ),
                    ),
                  ),
                  if (conversation.unread)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: const BoxDecoration(
                          color: AppColors.primaryColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Flexible(
                                child: Text(
                                  conversation.petName,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: conversation.unread ? FontWeight.bold : FontWeight.w500,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  '· ${conversation.shelterName}',
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _formatTimestamp(conversation.lastMessageTime),
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: conversation.unread ? AppColors.primaryColor : Colors.grey[500],
                            fontWeight: conversation.unread ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      conversation.lastMessage,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: conversation.unread ? Colors.black87 : Colors.grey[600],
                        fontWeight: conversation.unread ? FontWeight.w500 : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateOnly = DateTime(timestamp.year, timestamp.month, timestamp.day);

    if (dateOnly == today) return DateFormat('HH:mm').format(timestamp);
    if (dateOnly == yesterday) return 'Wczoraj';
    if (now.difference(timestamp).inDays < 7) {
      return DateFormat('EEEE', 'pl').format(timestamp);
    }
    return DateFormat('dd.MM.yyyy').format(timestamp);
  }
}
