import 'dart:math';
import 'package:http/http.dart' as http;
import '../models/message_model.dart';

// Callback type for message notifications
typedef MessageNotificationCallback = void Function(MessageModel message);

class MessageService {
  static final MessageService _instance = MessageService._internal();

  // Message listeners for real-time updates
  final Map<String, List<MessageNotificationCallback>> _messageListeners = {};

  factory MessageService() {
    return _instance;
  }

  MessageService._internal() {
    // Inicjalizacja danych demo na starcie
    _initializeDemoData();
  }

  // Lokalne przechowywanie konwersacji
  List<ConversationModel> _conversations = [];

  // Lokalne przechowywanie wiadomości dla każdej konwersacji
  final Map<String, List<MessageModel>> _conversationMessages = {};

  // Inicjalizacja danych demonstracyjnych
  void _initializeDemoData() {
    // Przygotuj kilka przykładowych konwersacji z demo zwierzętami
    final demoConversation1 = ConversationModel(
      id: 'conv_wawel',
      petId: 'pet1',
      petName: 'Wawel',
      petImageUrl: 'assets/demo/wawel1.jpg',
      shelterName: 'Łódzkie Schronisko',
      lastMessage: 'Dzień dobry, chciałbym dowiedzieć się więcej o Wawelu.',
      lastMessageTime: DateTime.now().subtract(Duration(hours: 2)),
      unread: false,
    );

    final demoConversation2 = ConversationModel(
      id: 'conv_misia',
      petId: 'pet2',
      petName: 'Misia',
      petImageUrl: 'assets/demo/misia1.jpg',
      shelterName: 'Azyl Pod Sercem',
      lastMessage: 'Czy Misia toleruje inne zwierzęta?',
      lastMessageTime: DateTime.now().subtract(Duration(days: 1)),
      unread: true,
    );

    _conversations = [demoConversation1, demoConversation2];

    // Przygotuj wiadomości dla pierwszej konwersacji
    _conversationMessages['conv_wawel'] = [
      MessageModel(
        id: 'msg_wawel_1',
        senderId: 'user123',
        conversationId: 'conv_wawel',
        content: 'Dzień dobry, chciałbym dowiedzieć się więcej o Wawelu.',
        timestamp: DateTime.now().subtract(Duration(hours: 3)),
        type: MessageType.text,
      ),
      MessageModel(
        id: 'msg_wawel_2',
        senderId: 's1',
        conversationId: 'conv_wawel',
        content: 'Dzień dobry! Wawel to wspaniały pies, bardzo przyjazny i energiczny. Jest u nas już od 6 miesięcy.',
        timestamp: DateTime.now().subtract(Duration(hours: 2, minutes: 30)),
        type: MessageType.text,
      ),
      MessageModel(
        id: 'msg_wawel_3',
        senderId: 'user123',
        conversationId: 'conv_wawel',
        content: 'Jak wygląda proces adopcyjny? Czy mogę przyjść go zobaczyć?',
        timestamp: DateTime.now().subtract(Duration(hours: 2)),
        type: MessageType.text,
      ),
    ];

    // Przygotuj wiadomości dla drugiej konwersacji
    _conversationMessages['conv_misia'] = [
      MessageModel(
        id: 'msg_misia_1',
        senderId: 'user123',
        conversationId: 'conv_misia',
        content: 'Witam, zauważyłem że Misia jest oznaczona jako pilna do adopcji. Co to dokładnie oznacza?',
        timestamp: DateTime.now().subtract(Duration(days: 1, hours: 5)),
        type: MessageType.text,
      ),
      MessageModel(
        id: 'msg_misia_2',
        senderId: 's2',
        conversationId: 'conv_misia',
        content: 'Dzień dobry, Misia jest u nas na leczeniu i potrzebujemy dla niej domu na stałe jak najszybciej. Jest bardzo przyjazna i towarzyska.',
        timestamp: DateTime.now().subtract(Duration(days: 1, hours: 4)),
        type: MessageType.text,
      ),
      MessageModel(
        id: 'msg_misia_3',
        senderId: 'user123',
        conversationId: 'conv_misia',
        content: 'Czy Misia toleruje inne zwierzęta?',
        timestamp: DateTime.now().subtract(Duration(days: 1)),
        type: MessageType.text,
      ),
    ];
  }

  // Dodaj listener dla nowych wiadomości w konwersacji
  void addMessageListener(String conversationId, MessageNotificationCallback callback) {
    if (!_messageListeners.containsKey(conversationId)) {
      _messageListeners[conversationId] = [];
    }
    _messageListeners[conversationId]!.add(callback);
  }

  // Usuń listener dla konwersacji
  void removeMessageListener(String conversationId, MessageNotificationCallback callback) {
    if (_messageListeners.containsKey(conversationId)) {
      _messageListeners[conversationId]!.remove(callback);
      if (_messageListeners[conversationId]!.isEmpty) {
        _messageListeners.remove(conversationId);
      }
    }
  }

  // Notyfikuj subskrybentów o nowej wiadomości
  void _notifyMessageListeners(String conversationId, MessageModel message) {
    if (_messageListeners.containsKey(conversationId)) {
      for (final callback in _messageListeners[conversationId]!) {
        callback(message);
      }
    }
  }

  // Pobieranie listy konwersacji
  Future<List<ConversationModel>> getConversations() async {
    // Zwracanie lokalnej kopii konwersacji
    return _conversations;
  }

  // Pobierz wiadomości dla konkretnej konwersacji
  Future<List<MessageModel>> getMessages(String conversationId) async {
    // Jeśli nie mamy wiadomości dla tej konwersacji, inicjalizujemy pustą listę
    if (!_conversationMessages.containsKey(conversationId)) {
      _conversationMessages[conversationId] = [];
    }

    return _conversationMessages[conversationId]!;
  }

  // Wyślij nową wiadomość
  Future<MessageModel> sendMessage(String conversationId, String content, {MessageType type = MessageType.text}) async {
    const String currentUserId = 'user123'; // ID aktualnego użytkownika

    // Tworzenie nowej wiadomości
    final newMessage = MessageModel(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      senderId: currentUserId,
      conversationId: conversationId,
      content: content,
      timestamp: DateTime.now(),
      type: type,
    );

    // Dodajemy wiadomość do lokalnego przechowywania
    if (!_conversationMessages.containsKey(conversationId)) {
      _conversationMessages[conversationId] = [];
    }
    _conversationMessages[conversationId]!.add(newMessage);

    // Aktualizujemy konwersację o ostatnią wiadomość
    int idx = _conversations.indexWhere((conv) => conv.id == conversationId);
    if (idx != -1) {
      final updatedConversation = ConversationModel(
        id: _conversations[idx].id,
        petId: _conversations[idx].petId,
        petName: _conversations[idx].petName,
        petImageUrl: _conversations[idx].petImageUrl,
        shelterName: _conversations[idx].shelterName,
        lastMessage: content,
        lastMessageTime: DateTime.now(),
        unread: false, // Własna wiadomość jest zawsze przeczytana
      );

      _conversations[idx] = updatedConversation;

      // Sortowanie konwersacji od najnowszej
      _conversations.sort((a, b) => b.lastMessageTime.compareTo(a.lastMessageTime));
    }

    // Symulacja odpowiedzi ze schroniska po 1-3 sekundach
    _simulateShelterResponse(conversationId);

    return newMessage;
  }

  // Symulacja odpowiedzi ze schroniska
  void _simulateShelterResponse(String conversationId) async {
    // Znajdź konwersację
    final conversationIndex = _conversations.indexWhere((conv) => conv.id == conversationId);

    // Jeśli nie znaleziono konwersacji, przerwij
    if (conversationIndex == -1) return;

    // Pobierz konwersację
    final conversation = _conversations[conversationIndex];

    final random = Random();

    // Lista możliwych odpowiedzi ze schroniska
    final responses = [
      'Z przyjemnością umówimy spotkanie. Kiedy byłby Panu/Pani dogodny termin?',
    ];

    // Losowy czas odpowiedzi (1-3 sekund)
    final replyDelay = Duration(milliseconds: 1000 + random.nextInt(2000));

    // Opóźnienie przed wysłaniem odpowiedzi
    await Future.delayed(replyDelay);

    // ID schroniska wyciągamy z ID zwierzaka
    String shelterId = 's${conversation.id.replaceAll(RegExp(r'[^0-9]'), '')}';
    if (shelterId == 's') {
      // Fallback jeśli nie możemy wyciągnąć ID z konwersacji
      shelterId = 'shelter${random.nextInt(5) + 1}';
    }

    // Tworzymy odpowiedź
    final shelterMessage = MessageModel(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      senderId: shelterId,
      conversationId: conversationId,
      content: responses[random.nextInt(responses.length)],
      timestamp: DateTime.now(),
      type: MessageType.text,
    );

    // Dodajemy odpowiedź do lokalnego przechowywania
    _conversationMessages[conversationId]!.add(shelterMessage);

    // Aktualizujemy konwersację o ostatnią wiadomość
    int idx = _conversations.indexWhere((conv) => conv.id == conversationId);
    if (idx != -1) {
      final updatedConversation = ConversationModel(
        id: _conversations[idx].id,
        petId: _conversations[idx].petId,
        petName: _conversations[idx].petName,
        petImageUrl: _conversations[idx].petImageUrl,
        shelterName: _conversations[idx].shelterName,
        lastMessage: shelterMessage.content,
        lastMessageTime: DateTime.now(),
        unread: true, // Nowa wiadomość od schroniska jest nieprzeczytana
      );

      _conversations[idx] = updatedConversation;

      // Sortowanie konwersacji od najnowszej
      _conversations.sort((a, b) => b.lastMessageTime.compareTo(a.lastMessageTime));
    }

    // Powiadom nasłuchujących o nowej wiadomości
    _notifyMessageListeners(conversationId, shelterMessage);
  }

  // Oznacz wiadomości jako przeczytane
  Future<void> markMessagesAsRead(String conversationId) async {
    int idx = _conversations.indexWhere((conv) => conv.id == conversationId);
    if (idx != -1 && _conversations[idx].unread) {
      final updatedConversation = ConversationModel(
        id: _conversations[idx].id,
        petId: _conversations[idx].petId,
        petName: _conversations[idx].petName,
        petImageUrl: _conversations[idx].petImageUrl,
        shelterName: _conversations[idx].shelterName,
        lastMessage: _conversations[idx].lastMessage,
        lastMessageTime: _conversations[idx].lastMessageTime,
        unread: false, // Oznaczamy jako przeczytane
      );

      _conversations[idx] = updatedConversation;
    }
  }

  // Utwórz nową konwersację
  Future<String> createConversation({
    required String petId,
    required String petName,
    required String shelterId,
    required String shelterName,
    required String petImageUrl,
  }) async {
    // Sprawdź czy konwersacja dla tego zwierzaka już istnieje
    final existingIndex = _conversations.indexWhere((conv) => conv.petId == petId);

    if (existingIndex != -1) {
      return _conversations[existingIndex].id;
    }

    // Tworzenie nowej konwersacji
    final conversationId = 'conv_${DateTime.now().millisecondsSinceEpoch}';

    final newConversation = ConversationModel(
      id: conversationId,
      petId: petId,
      petName: petName,
      petImageUrl: petImageUrl,
      shelterName: shelterName,
      lastMessage: 'Nawiązano kontakt', // Początkowo pusta wiadomość
      lastMessageTime: DateTime.now(),
      unread: false,
    );

    // Dodajemy nową konwersację na początku listy
    _conversations.insert(0, newConversation);

    // Inicjalizujemy pustą listę wiadomości dla tej konwersacji
    _conversationMessages[conversationId] = [];

    return conversationId;
  }

  // Usuń konwersację
  Future<void> deleteConversation(String conversationId) async {
    // Usuwamy konwersację z listy
    _conversations.removeWhere((conv) => conv.id == conversationId);

    // Usuwamy wiadomości powiązane z tą konwersacją
    _conversationMessages.remove(conversationId);

    // Usuwamy wszystkie listenery dla tej konwersacji
    _messageListeners.remove(conversationId);
  }
}