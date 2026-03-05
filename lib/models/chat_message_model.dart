import 'package:cloud_firestore/cloud_firestore.dart';

class ChatMessageModel {
  final String messageId;
  final String chatId;
  final String senderId;
  final String recipientId;
  final String text;
  final DateTime createdAt;
  final List<String> readBy;

  ChatMessageModel({
    required this.messageId,
    required this.chatId,
    required this.senderId,
    required this.recipientId,
    required this.text,
    required this.createdAt,
    required this.readBy,
  });

  factory ChatMessageModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    return ChatMessageModel(
      messageId: doc.id,
      chatId: (data['chatId'] ?? '').toString(),
      senderId: (data['senderId'] ?? '').toString(),
      recipientId: (data['recipientId'] ?? '').toString(),
      text: (data['text'] ?? '').toString(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      readBy: List<String>.from(data['readBy'] ?? const <String>[]),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'chatId': chatId,
      'senderId': senderId,
      'recipientId': recipientId,
      'text': text,
      'createdAt': Timestamp.fromDate(createdAt),
      'readBy': readBy,
    };
  }
}
