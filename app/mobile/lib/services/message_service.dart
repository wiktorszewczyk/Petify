import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';
import '../models/message_model.dart';
import '../models/user.dart';
import 'api/initial_api.dart';
import 'token_repository.dart';
import 'user_service.dart';
import 'notification_service.dart';
import '../settings.dart';
import 'cache/cache_manager.dart';

typedef MessageNotificationCallback = void Function(MessageModel message);

class MessageService with CacheableMixin {
  static final MessageService _instance = MessageService._internal();

  late final Dio _dio;
  late final TokenRepository _tokenRepository;
  late final UserService _userService;
  late final NotificationService _notificationService;

  StompClient? _stompClient;
  bool _isStompConnected = false;
  final Set<String> _subscribedRooms = {};

  final Map<String, List<MessageNotificationCallback>> _messageListeners = {};

  final Map<String, List<MessageModel>> _conversationMessages = {};
  List<ConversationModel>? _cachedConversations;

  User? _currentUser;

  factory MessageService() {
    return _instance;
  }

  MessageService._internal() {
    _dio = InitialApi().dio;
    _tokenRepository = TokenRepository();
    _userService = UserService();
    _notificationService = NotificationService();
  }

  Future<String> _getCurrentUsername() async {
    try {
      if (_currentUser == null) {
        _currentUser = await _userService.getCurrentUser();
      }
      return _currentUser?.username ?? '';
    } catch (e) {
      print('Error getting current username: $e');
      return '';
    }
  }

  Future<User?> getCurrentUser() async {
    try {
      if (_currentUser == null) {
        _currentUser = await _userService.getCurrentUser();
      }
      return _currentUser;
    } catch (e) {
      print('Error getting current user: $e');
      return null;
    }
  }

  Future<void> _setupStompConnection() async {
    if (_isStompConnected) return;

    try {
      final token = await _tokenRepository.getToken();
      if (token == null) return;

      final wsUrl = Settings.getServerUrl() + '/ws-chat';

      _stompClient = StompClient(
        config: StompConfig.sockJS(
          url: wsUrl,
          onConnect: (StompFrame frame) {
            print('STOMP connected successfully');
            _isStompConnected = true;
          },
          onWebSocketError: (dynamic error) {
            print('STOMP WebSocket error: $error');
            _isStompConnected = false;
          },
          onStompError: (StompFrame frame) {
            print('STOMP error: ${frame.body}');
            _isStompConnected = false;
          },
          onDisconnect: (StompFrame frame) {
            print('STOMP disconnected');
            _isStompConnected = false;
            _subscribedRooms.clear();
          },
          stompConnectHeaders: {
            'Authorization': 'Bearer $token',
          },
          webSocketConnectHeaders: {
            'Authorization': 'Bearer $token',
          },
        ),
      );

      _stompClient!.activate();
    } catch (e) {
      print('Error setting up STOMP connection: $e');
    }
  }

  Future<void> _subscribeToRoom(String roomId) async {
    if (_subscribedRooms.contains(roomId)) return;

    try {
      final currentUser = await getCurrentUser();
      if (currentUser == null) return;

      final username = currentUser.username;

      if (!_isStompConnected) {
        await _setupStompConnection();
        await Future.delayed(const Duration(milliseconds: 500));
        if (!_isStompConnected) {
          print('Failed to establish STOMP connection');
          return;
        }
      }

      print('Subscribing to /user/$username/queue/chat/$roomId');

      _stompClient!.subscribe(
        destination: '/user/$username/queue/chat/$roomId',
        callback: (StompFrame frame) {
          try {
            print('Received STOMP message: ${frame.body}');
            final messageData = json.decode(frame.body!);
            final message = MessageModel(
              id: messageData['id'].toString(),
              senderId: messageData['sender'],
              conversationId: roomId,
              content: messageData['content'],
              timestamp: DateTime.parse(messageData['timestamp']),
              type: MessageType.text,
            );

            if (!_conversationMessages.containsKey(roomId)) {
              _conversationMessages[roomId] = [];
            }
            _conversationMessages[roomId]!.add(message);

            _handleIncomingMessage(message);

            _notifyMessageListeners(roomId, message);
          } catch (e) {
            print('Error parsing STOMP message: $e');
          }
        },
      );

      if (_subscribedRooms.isEmpty) {
        _stompClient!.subscribe(
          destination: '/user/$username/queue/unread',
          callback: (StompFrame frame) {
            try {
              final unreadCount = json.decode(frame.body!) as int;
              print('Unread count updated: $unreadCount');
              // TODO: Update unread count in UI if needed
            } catch (e) {
              print('Error parsing unread count: $e');
            }
          },
        );
      }

      _subscribedRooms.add(roomId);
    } catch (e) {
      print('Error subscribing to room $roomId: $e');
    }
  }

  Future<void> _handleIncomingMessage(MessageModel message) async {
    try {
      final currentUsername = await _getCurrentUsername();

      if (_cachedConversations != null) {
        final idx = _cachedConversations!.indexWhere((conv) => conv.id == message.conversationId);
        if (idx != -1) {
          final updatedConversation = ConversationModel(
            id: _cachedConversations![idx].id,
            petId: _cachedConversations![idx].petId,
            petName: _cachedConversations![idx].petName,
            petImageUrl: _cachedConversations![idx].petImageUrl,
            shelterName: _cachedConversations![idx].shelterName,
            lastMessage: message.content,
            lastMessageTime: message.timestamp,
            unread: message.senderId != currentUsername,
          );

          _cachedConversations![idx] = updatedConversation;
          _cachedConversations!.sort((a, b) => b.lastMessageTime.compareTo(a.lastMessageTime));
        }
      }

      if (message.senderId != currentUsername) {
        final conversation = _cachedConversations?.firstWhere(
              (conv) => conv.id == message.conversationId,
          orElse: () => ConversationModel(
            id: message.conversationId,
            petId: '',
            petName: 'Nieznany zwierzak',
            petImageUrl: 'assets/images/empty_pets.png',
            shelterName: 'Schronisko',
            lastMessage: message.content,
            lastMessageTime: message.timestamp,
            unread: true,
          ),
        );

        if (conversation != null) {
          await _notificationService.addChatNotification(
            title: 'Nowa wiadomość o ${conversation.petName}',
            body: message.content,
            conversationId: message.conversationId,
            petName: conversation.petName,
          );
        }
      }
    } catch (e) {
      print('Error handling incoming message notification: $e');
    }
  }

  void addMessageListener(String conversationId, MessageNotificationCallback callback) {
    if (!_messageListeners.containsKey(conversationId)) {
      _messageListeners[conversationId] = [];
    }
    _messageListeners[conversationId]!.add(callback);
  }

  void removeMessageListener(String conversationId, MessageNotificationCallback callback) {
    if (_messageListeners.containsKey(conversationId)) {
      _messageListeners[conversationId]!.remove(callback);
      if (_messageListeners[conversationId]!.isEmpty) {
        _messageListeners.remove(conversationId);
      }
    }
  }

  void _notifyMessageListeners(String conversationId, MessageModel message) {
    if (_messageListeners.containsKey(conversationId)) {
      for (final callback in _messageListeners[conversationId]!) {
        callback(message);
      }
    }
  }

  void clearCache() {
    _cachedConversations = null;
    _conversationMessages.clear();
  }

  Future<List<ConversationModel>> getConversations({bool forceRefresh = false}) async {
    try {
      if (forceRefresh) {
        clearCache();
      }

      final response = await _dio.get('/chat/rooms');

      if (response.statusCode == 200) {
        final List<dynamic> roomsData = response.data;

        final conversations = <ConversationModel>[];

        for (final roomData in roomsData) {
          try {
            final petResponse = await _dio.get('/pets/${roomData['petId']}');
            final petData = petResponse.data;

            String shelterName = 'Unknown Shelter';
            try {
              if (petData['shelterId'] != null) {
                final shelterResponse = await _dio.get('/shelters/${petData['shelterId']}');
                final shelterData = shelterResponse.data;
                shelterName = shelterData['name'] ?? 'Unknown Shelter';
              }
            } catch (e) {
              print('Error fetching shelter details: $e');
              shelterName = roomData['shelterName'] ?? 'Unknown Shelter';
            }

            String lastMessage = 'Naciśnij aby rozpocząć czat';
            DateTime lastMessageTime = DateTime.now();

            try {
              final historyResponse = await _dio.get('/chat/history/${roomData['id']}?size=1');
              if (historyResponse.statusCode == 200) {
                final historyData = historyResponse.data;
                final List<dynamic> lastMessages = historyData['content'] ?? [];
                if (lastMessages.isNotEmpty) {
                  final lastMessageData = lastMessages.first;
                  lastMessage = lastMessageData['content'] ?? 'Wiadomość';
                  lastMessageTime = DateTime.parse(lastMessageData['timestamp']);
                }
              }
            } catch (e) {
              print('Error fetching last message for room ${roomData['id']}: $e');
            }

            final conversation = ConversationModel(
              id: roomData['id'].toString(),
              petId: roomData['petId'].toString(),
              petName: petData['name'] ?? 'Unknown Pet',
              petImageUrl: petData['imageUrl'] ?? 'assets/images/empty_pets.png',
              shelterName: shelterName,
              lastMessage: lastMessage,
              lastMessageTime: lastMessageTime,
              unread: (roomData['unreadCount'] ?? 0) > 0,
            );

            conversations.add(conversation);
          } catch (e) {
            print('Error fetching pet details for pet ${roomData['petId']}: $e');

            String lastMessage = 'Naciśnij aby rozpocząć czat';
            DateTime lastMessageTime = DateTime.now();

            try {
              final historyResponse = await _dio.get('/chat/history/${roomData['id']}?size=1');
              if (historyResponse.statusCode == 200) {
                final historyData = historyResponse.data;
                final List<dynamic> lastMessages = historyData['content'] ?? [];
                if (lastMessages.isNotEmpty) {
                  final lastMessageData = lastMessages.first;
                  lastMessage = lastMessageData['content'] ?? 'Wiadomość';
                  lastMessageTime = DateTime.parse(lastMessageData['timestamp']);
                }
              }
            } catch (e) {
              print('Error fetching last message for room ${roomData['id']} (fallback): $e');
            }

            final conversation = ConversationModel(
              id: roomData['id'].toString(),
              petId: roomData['petId'].toString(),
              petName: 'Unknown Pet',
              petImageUrl: 'assets/images/empty_pets.png',
              shelterName: roomData['shelterName'] ?? 'Unknown Shelter',
              lastMessage: lastMessage,
              lastMessageTime: lastMessageTime,
              unread: (roomData['unreadCount'] ?? 0) > 0,
            );
            conversations.add(conversation);
          }
        }

        conversations.sort((a, b) => b.lastMessageTime.compareTo(a.lastMessageTime));

        _cachedConversations = conversations;
        return conversations;
      } else {
        throw Exception('Failed to load conversations: ${response.statusCode}');
      }
    } catch (e) {
      print('Error loading conversations: $e');
      return _cachedConversations ?? [];
    }
  }

  Future<List<MessageModel>> getMessages(String conversationId) async {
    try {
      if (_conversationMessages.containsKey(conversationId)) {
        print('Returning cached messages for conversation $conversationId: ${_conversationMessages[conversationId]!.length} messages');
        return _conversationMessages[conversationId]!;
      }

      print('Fetching message history for conversation $conversationId');
      final response = await _dio.get('/chat/history/$conversationId');

      if (response.statusCode == 200) {
        final data = response.data;
        print('Message history response: $data');
        final List<dynamic> messagesData = data['content'] ?? [];
        print('Found ${messagesData.length} messages in history');

        final messages = messagesData.map((messageData) {
          return MessageModel(
            id: messageData['id'].toString(),
            senderId: messageData['sender'],
            conversationId: conversationId,
            content: messageData['content'],
            timestamp: DateTime.parse(messageData['timestamp']),
            type: MessageType.text,
          );
        }).toList();

        messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));

        _conversationMessages[conversationId] = messages;

        await _setupStompConnection();
        await _subscribeToRoom(conversationId);

        return messages;
      } else {
        throw Exception('Failed to load messages: ${response.statusCode}');
      }
    } catch (e) {
      print('Error loading messages for conversation $conversationId: $e');
      return _conversationMessages[conversationId] ?? [];
    }
  }

  Future<MessageModel> sendMessage(String conversationId, String content, {MessageType type = MessageType.text}) async {
    try {
      final currentUsername = await _getCurrentUsername();

      if (_isStompConnected && _stompClient != null) {
        print('Sending message via STOMP to /app/chat/$conversationId: $content');
        _stompClient!.send(
          destination: '/app/chat/$conversationId',
          body: content,
        );
      } else {
        print('STOMP not connected, cannot send message');
      }

      final newMessage = MessageModel(
        id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
        senderId: currentUsername,
        conversationId: conversationId,
        content: content,
        timestamp: DateTime.now(),
        type: type,
      );

      if (!_conversationMessages.containsKey(conversationId)) {
        _conversationMessages[conversationId] = [];
      }
      _conversationMessages[conversationId]!.add(newMessage);

      if (_cachedConversations != null) {
        final idx = _cachedConversations!.indexWhere((conv) => conv.id == conversationId);
        if (idx != -1) {
          final updatedConversation = ConversationModel(
            id: _cachedConversations![idx].id,
            petId: _cachedConversations![idx].petId,
            petName: _cachedConversations![idx].petName,
            petImageUrl: _cachedConversations![idx].petImageUrl,
            shelterName: _cachedConversations![idx].shelterName,
            lastMessage: content,
            lastMessageTime: newMessage.timestamp,
            unread: false,
          );

          _cachedConversations![idx] = updatedConversation;
          _cachedConversations!.sort((a, b) => b.lastMessageTime.compareTo(a.lastMessageTime));
        }
      }

      return newMessage;
    } catch (e) {
      print('Error sending message: $e');
      throw Exception('Failed to send message: $e');
    }
  }


  Future<void> markMessagesAsRead(String conversationId) async {
    try {
      // await _dio.post('/chat/rooms/$conversationId/read');

      if (_cachedConversations != null) {
        final idx = _cachedConversations!.indexWhere((conv) => conv.id == conversationId);
        if (idx != -1 && _cachedConversations![idx].unread) {
          final updatedConversation = ConversationModel(
            id: _cachedConversations![idx].id,
            petId: _cachedConversations![idx].petId,
            petName: _cachedConversations![idx].petName,
            petImageUrl: _cachedConversations![idx].petImageUrl,
            shelterName: _cachedConversations![idx].shelterName,
            lastMessage: _cachedConversations![idx].lastMessage,
            lastMessageTime: _cachedConversations![idx].lastMessageTime,
            unread: false,
          );

          _cachedConversations![idx] = updatedConversation;
        }
      }
    } catch (e) {
      print('Error marking messages as read: $e');
    }
  }

  Future<String> createConversation({
    required String petId,
    required String petName,
    required String shelterId,
    required String shelterName,
    required String petImageUrl,
  }) async {
    try {
      final conversations = await getConversations();
      final existingConversation = conversations
          .where((conv) => conv.petId == petId)
          .toList();

      if (existingConversation.isNotEmpty) {
        return existingConversation.first.id;
      }

      final response = await _dio.get('/chat/room/$petId');

      if (response.statusCode == 200) {
        final roomData = response.data;

        final conversationId = roomData['id'].toString();

        String actualShelterName = shelterName;
        try {
          final shelterResponse = await _dio.get('/shelters/$shelterId');
          final shelterData = shelterResponse.data;
          actualShelterName = shelterData['name'] ?? shelterName;
        } catch (e) {
          print('Error fetching shelter details in createConversation: $e');
        }

        final newConversation = ConversationModel(
          id: conversationId,
          petId: petId,
          petName: petName,
          petImageUrl: petImageUrl,
          shelterName: actualShelterName,
          lastMessage: 'Nawiązano kontakt',
          lastMessageTime: DateTime.now(),
          unread: false,
        );

        if (_cachedConversations == null) {
          _cachedConversations = [];
        }
        _cachedConversations!.insert(0, newConversation);

        _conversationMessages[conversationId] = [];

        await _setupStompConnection();
        await _subscribeToRoom(conversationId);

        return conversationId;
      } else {
        throw Exception('Failed to create conversation: ${response.statusCode}');
      }
    } catch (e) {
      print('Error creating conversation: $e');
      throw Exception('Failed to create conversation: $e');
    }
  }

  Future<void> deleteConversation(String conversationId) async {
    try {
      await _dio.delete('/chat/rooms/$conversationId');

      _cachedConversations?.removeWhere((conv) => conv.id == conversationId);

      _conversationMessages.remove(conversationId);

      if (_stompClient != null && _subscribedRooms.contains(conversationId)) {
        final currentUser = await getCurrentUser();
        if (currentUser != null) {
          final username = currentUser.username;
        }
        _subscribedRooms.remove(conversationId);
      }

      _messageListeners.remove(conversationId);
    } catch (e) {
      print('Error deleting conversation: $e');
      throw Exception('Failed to delete conversation: $e');
    }
  }

  Future<int> getUnreadMessageCount() async {
    try {
      final response = await _dio.get('/chat/unread/count');
      if (response.statusCode == 200) {
        return response.data as int;
      }
      return 0;
    } catch (e) {
      print('Error getting unread count: $e');
      return 0;
    }
  }

  void dispose() {
    if (_stompClient != null) {
      _stompClient!.deactivate();
    }
    _stompClient = null;
    _isStompConnected = false;
    _subscribedRooms.clear();
    _messageListeners.clear();
  }
}