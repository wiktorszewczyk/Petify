class MessageModel {
  final String id;
  final String senderId;
  final String conversationId;
  final String content;
  final DateTime timestamp;
  final bool isRead;
  final MessageType type;

  MessageModel({
    required this.id,
    required this.senderId,
    required this.conversationId,
    required this.content,
    required this.timestamp,
    this.isRead = false,
    this.type = MessageType.text,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id']?.toString() ?? '',
      senderId: json['sender'] ?? json['senderId'] ?? '',
      conversationId: json['roomId']?.toString() ?? json['conversationId'] ?? '',
      content: json['content'] ?? '',
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
      isRead: json['isRead'] ?? false,
      type: _parseMessageType(json['type'] ?? 'text'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sender': senderId,
      'roomId': conversationId,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead,
      'type': type.toString().split('.').last,
    };
  }

  static MessageType _parseMessageType(String type) {
    switch (type) {
      case 'image':
        return MessageType.image;
      case 'document':
        return MessageType.document;
      case 'system':
        return MessageType.system;
      default:
        return MessageType.text;
    }
  }
}

class ConversationModel {
  final String id;
  final String petId;
  final String petName;
  final String petImageUrl;
  final String shelterName;
  final String lastMessage;
  final DateTime lastMessageTime;
  final bool unread;

  ConversationModel({
    required this.id,
    required this.petId,
    required this.petName,
    required this.petImageUrl,
    required this.shelterName,
    required this.lastMessage,
    required this.lastMessageTime,
    this.unread = false,
  });

  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    return ConversationModel(
      id: json['id']?.toString() ?? '',
      petId: json['petId']?.toString() ?? '',
      petName: json['petName'] ?? '',
      petImageUrl: json['petImageUrl'] ?? 'assets/images/empty_pets.png',
      shelterName: json['shelterName'] ?? '',
      lastMessage: json['lastMessage'] ?? '',
      lastMessageTime: json['lastMessageTime'] != null
          ? DateTime.parse(json['lastMessageTime'])
          : DateTime.now(),
      unread: json['unread'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'petId': petId,
      'petName': petName,
      'petImageUrl': petImageUrl,
      'shelterName': shelterName,
      'lastMessage': lastMessage,
      'lastMessageTime': lastMessageTime.toIso8601String(),
      'unread': unread,
    };
  }
}

enum MessageType {
  text,
  image,
  document,
  system,
}