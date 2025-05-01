import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import '../models/message_model.dart';

class MessageService {
  static final MessageService _instance = MessageService._internal();

  factory MessageService() {
    return _instance;
  }

  MessageService._internal();

  /// TODO: Zastąpić symulację API rzeczywistym wywołaniem
  // Symulacja API
  Future<List<ConversationModel>> getConversations() async {
    try {
      final random = Random();

      final petNames = [
        'Reksio', 'Luna', 'Bella', 'Azor', 'Max',
        'Puszek', 'Figa', 'Kora', 'Mruczek', 'Filemon'
      ];

      final shelters = [
        'Schronisko Poznań', 'Fundacja Kocie Łapki', 'Schronisko Warszawa',
        'Schronisko Kraków', 'Azyl Dla Zwierząt', 'Fundacja Psie Serca'
      ];

      final lastMessages = [
        'Dzień dobry, czy mogę umówić się na spotkanie?',
        'Potwierdzam, jutro o 15:00 możesz odwiedzić zwierzaka.',
        'Dziękuję za zainteresowanie. Zapraszamy do schroniska!',
        'Czy potrzebne są jakieś dokumenty do adopcji?',
        'Tak, wszystkie zwierzęta są zaszczepione i odrobaczone.',
        'Kiedy mogę przyjść na spotkanie?',
        'Czy ten pies jest przyjazny dla dzieci?',
        'Mamy jeszcze kilka formalności do wypełnienia.'
      ];

      final imageUrls = [
        'https://images.pexels.com/photos/1805164/pexels-photo-1805164.jpeg',
        'https://images.pexels.com/photos/2253275/pexels-photo-2253275.jpeg',
        'https://images.pexels.com/photos/1346086/pexels-photo-1346086.jpeg',
        'https://images.pexels.com/photos/45201/kitty-cat-kitten-pet-45201.jpeg',
        'https://images.pexels.com/photos/1056251/pexels-photo-1056251.jpeg',
        'https://images.pexels.com/photos/320014/pexels-photo-320014.jpeg'
      ];

      final conversationCount = random.nextInt(6) + 3;

      List<ConversationModel> conversations = [];

      for (int i = 0; i < conversationCount; i++) {
        final petName = petNames[random.nextInt(petNames.length)];
        final shelterName = shelters[random.nextInt(shelters.length)];
        final lastMessage = lastMessages[random.nextInt(lastMessages.length)];
        final imageUrl = imageUrls[random.nextInt(imageUrls.length)];

        final lastMessageTime = DateTime.now().subtract(
            Duration(
                days: random.nextInt(5),
                hours: random.nextInt(24),
                minutes: random.nextInt(60)
            )
        );

        final unread = random.nextInt(4) == 0;

        conversations.add(
          ConversationModel(
            id: 'conv_$i',
            petId: 'pet_$i',
            petName: petName,
            petImageUrl: imageUrl,
            shelterName: shelterName,
            lastMessage: lastMessage,
            lastMessageTime: lastMessageTime,
            unread: unread,
          ),
        );
      }

      conversations.sort((a, b) => b.lastMessageTime.compareTo(a.lastMessageTime));

      return conversations;
    } catch (e) {
      rethrow;
    }
  }

  // Pobierz wiadomości dla konkretnej konwersacji
  Future<List<MessageModel>> getMessages(String conversationId) async {
    try {
      /// TODO: Zastąpić symulację API rzeczywistym wywołaniem
      // Symulacja API
      final random = Random();
      final now = DateTime.now();

      const String currentUserId = 'user123';
      final shelterId = 'shelter${conversationId.replaceAll('conv_', '')}';

      final userMessages = [
        'Dzień dobry, zainteresował mnie zwierzak z Państwa schroniska.',
        'Czy mogę umówić się na spotkanie?',
        'O której godzinie jest otwarty ośrodek?',
        'Czy potrzebuję przynieść jakieś dokumenty?',
        'Czy zwierzak jest już zaszczepiony?',
        'Dziękuję za informacje!',
        'Do zobaczenia jutro!',
        'Czy ma zalecenia żywieniowe?',
        'Jak wygląda proces adopcyjny?',
      ];

      final shelterMessages = [
        'Dzień dobry, w czym możemy pomóc?',
        'To wspaniały pupil! Jest u nas od miesiąca, bardzo przyjazny.',
        'Oczywiście! Jesteśmy otwarci od 10:00 do 18:00, od poniedziałku do soboty.',
        'Proszę przyjść do recepcji i zapytać o opiekuna.',
        'Tak, wszystkie nasze zwierzęta są zaszczepione i przebadane przez weterynarza.',
        'Potrzebny będzie dowód osobisty do podpisania umowy adopcyjnej.',
        'Zapraszamy, będziemy czekać!',
        'Czy ma Pan/Pani jakieś dodatkowe pytania?',
        'Dziękujemy za zainteresowanie naszymi podopiecznymi.',
      ];

      final messageCount = random.nextInt(11) + 5;

      List<MessageModel> messages = [];

      for (int i = 0; i < messageCount; i++) {
        final isUserMessage = i % 2 == 0;
        final senderId = isUserMessage ? currentUserId : shelterId;

        final content = isUserMessage
            ? userMessages[random.nextInt(userMessages.length)]
            : shelterMessages[random.nextInt(shelterMessages.length)];

        final baseTime = now.subtract(Duration(days: 2));
        final messageTime = baseTime.add(Duration(
            hours: (i * 2) + random.nextInt(2),
            minutes: random.nextInt(60)
        ));

        messages.add(
          MessageModel(
            id: 'msg_${conversationId}_$i',
            senderId: senderId,
            conversationId: conversationId,
            content: content,
            timestamp: messageTime,
            type: MessageType.text,
          ),
        );
      }

      // Sortowanie wiadomości od najstarszej
      messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));

      return messages;
    } catch (e) {
      rethrow;
    }
  }

  // Wyślij nową wiadomość
  Future<MessageModel> sendMessage(String conversationId, String content, {MessageType type = MessageType.text}) async {
    try {
      const String currentUserId = 'user123'; // ID aktualnego użytkownika

      return MessageModel(
        id: 'msg_new_${DateTime.now().millisecondsSinceEpoch}',
        senderId: currentUserId,
        conversationId: conversationId,
        content: content,
        timestamp: DateTime.now(),
        type: type,
      );
    } catch (e) {
      rethrow;
    }
  }

  // Oznacz wiadomości jako przeczytane
  Future<void> markMessagesAsRead(String conversationId) async {
    try {
      // W rzeczywistej implementacji, tutaj byłoby wywołanie API
      return;
    } catch (e) {
      rethrow;
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
    try {
      // Symulacja tworzenia konwersacji
      final conversationId = 'conv_${DateTime.now().millisecondsSinceEpoch}';

      // W rzeczywistej implementacji, tutaj byłoby wywołanie API
      // które tworzyłoby konwersację i zwracało jej ID

      return conversationId;
    } catch (e) {
      rethrow;
    }
  }

  // Usuń konwersację
  Future<void> deleteConversation(String conversationId) async {
    try {
      return;
    } catch (e) {
      rethrow;
    }
  }
}