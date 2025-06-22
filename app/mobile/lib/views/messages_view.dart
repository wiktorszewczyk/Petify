import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/message_model.dart';
import '../models/pet.dart';
import '../services/message_service.dart';
import '../styles/colors.dart';
import '../widgets/cards/conversation_card.dart';
import '../views/chat_view.dart';

class MessagesView extends StatefulWidget {
  const MessagesView({Key? key}) : super(key: key);

  @override
  State<MessagesView> createState() => _MessagesViewState();
}

class _MessagesViewState extends State<MessagesView> with AutomaticKeepAliveClientMixin {
  late final MessageService _messageService;
  List<ConversationModel>? _conversations;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _messageService = MessageService();
    _loadConversations();
  }

  Future<void> _loadConversations() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final conversations = await _messageService.getConversations();
      setState(() {
        _conversations = conversations;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Nie udało się załadować konwersacji. Spróbuj ponownie.';
        _isLoading = false;
      });
    }
  }

  void _deleteConversation(ConversationModel conversation) async {
    try {
      setState(() {
        _conversations!.removeWhere((c) => c.id == conversation.id);
      });

      await _messageService.deleteConversation(conversation.id);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Konwersacja z ${conversation.petName} została usunięta'),
          action: SnackBarAction(
            label: 'Cofnij',
            onPressed: () async {
              try {
                await _loadConversations();
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Nie udało się przywrócić konwersacji'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
          ),
        ),
      );
    } catch (e) {
      setState(() {
        _conversations!.add(conversation);
        _conversations!.sort((a, b) => b.lastMessageTime.compareTo(a.lastMessageTime));
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Nie udało się usunąć konwersacji: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Text(
                    'Wiadomości',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryColor,
                    ),
                  ),
                  const Spacer(),
                  if (_conversations != null && _conversations!.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.search),
                      onPressed: () {
                        // TODO: zaimplementować szukanie po wiadomościach
                      },
                      tooltip: 'Szukaj w wiadomościach',
                    ),
                ],
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation(AppColors.primaryColor),
              ))
                  : _errorMessage != null
                  ? RefreshIndicator(
                onRefresh: _loadConversations,
                color: AppColors.primaryColor,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: SizedBox(
                    height: MediaQuery.of(context).size.height * 0.6,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _errorMessage!,
                            style: const TextStyle(color: Colors.red),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _loadConversations,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryColor,
                              foregroundColor: Colors.black,
                            ),
                            child: const Text('Spróbuj ponownie'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              )
                  : _conversations!.isEmpty
                  ? RefreshIndicator(
                onRefresh: _loadConversations,
                color: AppColors.primaryColor,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: SizedBox(
                    height: MediaQuery.of(context).size.height * 0.6,
                    child: _buildEmptyState(),
                  ),
                ),
              )
                  : RefreshIndicator(
                onRefresh: _loadConversations,
                color: AppColors.primaryColor,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _conversations!.length,
                  separatorBuilder: (context, index) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final conversation = _conversations![index];
                    return ConversationCard(
                      conversation: conversation,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChatView(conversationId: conversation.id),
                          ),
                        ).then((_) => _loadConversations());
                      },
                      onDelete: () => _deleteConversation(conversation),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline_rounded,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Brak wiadomości',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Gdy polubisz jakieś zwierzę, możesz skontaktować\nsię z jego opiekunem.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            icon: const Icon(Icons.pets_rounded),
            label: const Text('Przeglądaj zwierzaki'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}