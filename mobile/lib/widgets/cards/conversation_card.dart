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
    Key? key,
    required this.conversation,
    required this.onTap,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(conversation.id),
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(
          Icons.delete,
          color: Colors.white,
          size: 28,
        ),
      ),
      direction: DismissDirection.endToStart,
      onDismissed: (direction) {
        onDelete();
      },
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar zwierzaka
              Stack(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.primaryColor,
                        width: 2,
                      ),
                      image: DecorationImage(
                        fit: BoxFit.cover,
                        image: NetworkImage(conversation.petImageUrl),
                        onError: (exception, stackTrace) {
                          // Placeholder w przypadku błędu ładowania obrazu
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
              // Treść konwersacji
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          conversation.petName,
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: conversation.unread ? FontWeight.bold : FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '· ${conversation.shelterName}',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        const Spacer(),
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
    final messageDate = DateTime(timestamp.year, timestamp.month, timestamp.day);

    if (messageDate == today) {
      // Jeśli wiadomość jest z dzisiaj, pokaż tylko godzinę
      return DateFormat('HH:mm').format(timestamp);
    } else if (messageDate == yesterday) {
      // Jeśli wiadomość jest z wczoraj, pokaż "wczoraj"
      return 'Wczoraj';
    } else if (now.difference(timestamp).inDays < 7) {
      // Jeśli wiadomość jest z tego tygodnia, pokaż dzień tygodnia
      return DateFormat('EEEE', 'pl').format(timestamp);
    } else {
      // W przeciwnym razie pokaż datę
      return DateFormat('dd.MM.yyyy').format(timestamp);
    }
  }
}