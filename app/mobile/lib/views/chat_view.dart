import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/message_model.dart';
import '../models/pet.dart';
import '../services/message_service.dart';
import '../services/user_service.dart';
import '../styles/colors.dart';

class ChatView extends StatefulWidget {
  final String? conversationId; // Made optional for backward compatibility
  final String? chatRoomId; // New parameter from PostDetailsView
  final String? recipientName; // New parameter for display name
  final String? context; // New parameter for chat context
  final bool isNewConversation;
  final Pet? pet; // Optional pet model for new conversations

  const ChatView({
    Key? key,
    this.conversationId,
    this.chatRoomId,
    this.recipientName,
    this.context,
    this.isNewConversation = false,
    this.pet,
  }) : super(key: key);

  @override
  State<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<ChatView> {
  late final MessageService _messageService;
  late final UserService _userService;
  List<MessageModel>? _messages;
  bool _isLoading = true;
  String? _errorMessage;
  ConversationModel? _conversation;
  String? _currentUserId;

  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isSending = false;
  bool _initialLoadAttempted = false;

  // Get the actual conversation ID (support both old and new parameters)
  String get _actualConversationId => widget.chatRoomId ?? widget.conversationId ?? '';

  @override
  void initState() {
    super.initState();
    _messageService = MessageService();
    _userService = UserService();
    _initializeCurrentUser();
    _loadConversationDetails();

    // Dodanie nasłuchiwania na nowe wiadomości
    _messageService.addMessageListener(_actualConversationId, _onNewMessage);
  }

  Future<void> _initializeCurrentUser() async {
    try {
      final user = await _userService.getCurrentUser();
      setState(() {
        _currentUserId = user.username; // Use username instead of ID
      });
    } catch (e) {
      print('Error getting current user: $e');
    }
  }

  @override
  void dispose() {
    // Usunięcie nasłuchiwania przy zniszczeniu widoku
    _messageService.removeMessageListener(_actualConversationId, _onNewMessage);
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // Obsługa nowej wiadomości
  void _onNewMessage(MessageModel message) {
    // Upewnij się, że nie dodajemy wiadomości wysłanych przez aktualnego użytkownika,
    // ponieważ te zostały już dodane w _sendMessage
    // Również sprawdź, czy wiadomość już nie istnieje w liście
    if (message.senderId != _currentUserId && mounted) {
      setState(() {
        _messages ??= [];
        // Sprawdź czy wiadomość już nie istnieje (unikaj duplikatów)
        final exists = _messages!.any((msg) =>
        msg.id == message.id ||
            (msg.content == message.content &&
                msg.timestamp.difference(message.timestamp).inSeconds.abs() < 5)
        );
        if (!exists) {
          _messages!.add(message);
        }
      });
      _scrollToBottom();
    }
  }

  Future<void> _loadConversationDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // If we have recipient name and context from PostDetailsView, create a virtual conversation
      if (widget.recipientName != null && widget.context != null) {
        setState(() {
          _conversation = ConversationModel(
            id: _actualConversationId,
            petId: '',
            petName: widget.context ?? 'Ogłoszenie',
            petImageUrl: 'assets/images/default_shelter.jpg',
            shelterName: widget.recipientName ?? 'Schronisko',
            lastMessage: 'Naciśnij aby rozpocząć czat',
            lastMessageTime: DateTime.now(),
            unread: false,
          );
        });
      } else {
        final conversations = await _messageService.getConversations();
        final conversation = conversations.firstWhere(
              (conv) => conv.id == _actualConversationId,
          orElse: () => throw Exception('Nie znaleziono konwersacji'),
        );

        setState(() {
          _conversation = conversation;
        });
      }

      await _loadMessages();
    } catch (e) {
      if (mounted) {
        setState(() {
          if (widget.pet != null && widget.isNewConversation) {
            _conversation = ConversationModel(
              id: _actualConversationId,
              petId: widget.pet!.id.toString(),
              petName: widget.pet!.name,
              petImageUrl: widget.pet!.imageUrl ?? 'assets/images/pet_placeholder.png',
              shelterName: widget.pet!.shelterName ?? 'Schronisko',
              lastMessage: '',
              lastMessageTime: DateTime.now(),
              unread: false,
            );
            _messages = [];
            _isLoading = false;
          } else {
            _errorMessage = 'Nie udało się załadować konwersacji. Spróbuj ponownie.';
            _isLoading = false;
          }
        });
      }
    }
  }

  Future<void> _loadMessages() async {
    if (_initialLoadAttempted && (_messages?.isNotEmpty ?? false)) {
      // Jeśli to ponowna próba i mamy już wiadomości, nie ładuj ponownie
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Tylko próbuj pobrać wiadomości, jeśli to nie jest nowa konwersacja
      if (!widget.isNewConversation) {
        final messages = await _messageService.getMessages(_actualConversationId);

        // Oznacz wiadomości jako przeczytane
        await _messageService.markMessagesAsRead(_actualConversationId);

        if (mounted) {
          setState(() {
            _messages = messages;
            _isLoading = false;
            _initialLoadAttempted = true;
          });

          // Przewiń do najnowszej wiadomości
          if (messages.isNotEmpty) {
            _scrollToBottom();
          }
        }
      } else {
        // Dla nowej konwersacji po prostu inicjalizujemy pustą listę
        if (mounted) {
          setState(() {
            _messages = [];
            _isLoading = false;
            _initialLoadAttempted = true;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Nie udało się załadować wiadomości. Sprawdź połączenie z internetem i spróbuj ponownie.';
          _isLoading = false;
          _initialLoadAttempted = true;
        });
      }
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty || _isSending) {
      return;
    }

    setState(() {
      _isSending = true;
    });

    _messageController.clear();

    try {
      final newMessage = await _messageService.sendMessage(_actualConversationId, content);

      // Don't add message to UI here - it will be added through the WebSocket listener
      // or already added by the MessageService for immediate UI update
      setState(() {
        _isSending = false;
      });

      _scrollToBottom();
    } catch (e) {
      setState(() {
        _isSending = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nie udało się wysłać wiadomości'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _formatMessageTimestamp(DateTime timestamp) {
    return DateFormat('HH:mm').format(timestamp);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: SafeArea(
        child: Column(
          children: [
            // Główny obszar czatu
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation(AppColors.primaryColor),
              ))
                  : _errorMessage != null
                  ? _buildErrorState()
                  : (_messages == null || _messages!.isEmpty)
                  ? _buildEmptyChat()
                  : _buildChatMessages(),
            ),
            // Obszar wprowadzania wiadomości
            _buildMessageInput(),
          ],
        ),
      ),
    );
  }

  ImageProvider _getImageProvider(String path) {
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return NetworkImage(path);
    } else {
      return AssetImage(path);
    }
  }

  Widget _buildEmptyChat() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_conversation != null) ...[
              Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  image: DecorationImage(
                    fit: BoxFit.cover,
                    image: _getImageProvider(_conversation!.petImageUrl),
                    onError: (exception, stackTrace) {
                      return const AssetImage('assets/images/pet_placeholder.png');
                    } as ImageErrorListener,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Rozpocznij czat o ${_conversation!.petName}',
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                _conversation!.shelterName,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 48,
                    color: AppColors.primaryColor,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Napisz pierwszą wiadomość!',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Zapytaj o zwierzaka, proces adopcji lub umów się na spotkanie.',
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: [
                _suggestionChip('Dzień dobry! Czy mogę dowiedzieć się więcej o tym zwierzaku?'),
                _suggestionChip('Kiedy mogę przyjechać na spotkanie?'),
                _suggestionChip('Jak wygląda proces adopcji?'),
                _suggestionChip('Czy zwierzak jest przyjazny dla dzieci?'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _suggestionChip(String text) {
    return InkWell(
      onTap: () {
        _messageController.text = text;
        // Nie wysyłamy automatycznie, aby użytkownik mógł edytować sugestię
        FocusScope.of(context).requestFocus(FocusNode());
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.primaryColor.withOpacity(0.5)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          text,
          style: GoogleFonts.poppins(
            fontSize: 13,
            color: AppColors.primaryColor,
          ),
        ),
      ),
    );
  }


  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red[300],
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Text(
              _errorMessage!,
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Colors.red[700],
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadConversationDetails,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            icon: const Icon(Icons.refresh),
            label: const Text('Spróbuj ponownie'),
          ),
        ],
      ),
    );
  }

  Widget _buildChatMessages() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _messages!.length,
      itemBuilder: (context, index) {
        final message = _messages![index];
        final isMe = message.senderId == _currentUserId;

        // Sprawdź, czy pokazać datę
        final showDate = index == 0 ||
            !_isSameDay(_messages![index].timestamp, _messages![index - 1].timestamp);

        return Column(
          children: [
            // Pokaż datę, jeśli potrzeba
            if (showDate) _buildDateSeparator(message.timestamp),

            // Wiadomość
            Align(
              alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
              child: Column(
                crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  // Pokaż nazwę nadawcy dla wiadomości od schroniska
                  if (!isMe && _conversation != null)
                    Padding(
                      padding: const EdgeInsets.only(left: 16, bottom: 4),
                      child: Text(
                        _conversation!.shelterName,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: isMe ? AppColors.primaryColor : Colors.grey[200],
                      borderRadius: BorderRadius.circular(16),
                    ),
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.75,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          message.content,
                          style: GoogleFonts.poppins(
                            color: isMe ? Colors.black : Colors.black87,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _formatMessageTimestamp(message.timestamp),
                          style: GoogleFonts.poppins(
                            color: isMe ? Colors.black87 : Colors.grey[600],
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  Widget _buildDateSeparator(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate = DateTime(date.year, date.month, date.day);

    String dateText;
    if (messageDate == today) {
      dateText = 'Dzisiaj';
    } else if (messageDate == yesterday) {
      dateText = 'Wczoraj';
    } else {
      dateText = DateFormat('dd.MM.yyyy').format(date);
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Expanded(child: Divider(color: Colors.grey[300])),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              dateText,
              style: GoogleFonts.poppins(
                color: Colors.grey[600],
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(child: Divider(color: Colors.grey[300])),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            offset: const Offset(0, -1),
            blurRadius: 6,
            color: Colors.black.withOpacity(0.1),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.attach_file),
            onPressed: () {
              // TODO: Implementacja załączania plików
            },
          ),
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Napisz wiadomość...',
                hintStyle: GoogleFonts.poppins(color: Colors.grey),
                filled: true,
                fillColor: Colors.grey[100],
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(color: AppColors.primaryColor, width: 1),
                ),
              ),
              textCapitalization: TextCapitalization.sentences,
              minLines: 1,
              maxLines: 5,
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          IconButton(
            icon: _isSending
                ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(AppColors.primaryColor),
              ),
            )
                : Icon(
              Icons.send_rounded,
              color: AppColors.primaryColor,
            ),
            onPressed: _isSending ? null : _sendMessage,
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: _conversation != null
          ? Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundImage: _getImageProvider(_conversation!.petImageUrl),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.recipientName ?? _conversation!.shelterName,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                if (widget.context != null)
                  Text(
                    widget.context!,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                    overflow: TextOverflow.ellipsis,
                  )
                else if (_conversation!.petName.isNotEmpty)
                  Text(
                    'W sprawie: ${_conversation!.petName}',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
        ],
      )
          : Text(
        'Chat',
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
      backgroundColor: Colors.white,
      elevation: 1,
      iconTheme: const IconThemeData(color: Colors.black87),
    );
  }
}