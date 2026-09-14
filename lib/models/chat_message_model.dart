import 'package:cloud_firestore/cloud_firestore.dart';

class ChatMessageModel {
  final String senderId;
  final String text;
  final DateTime timestamp;

  ChatMessageModel({
    required this.senderId,
    required this.text,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() => {
    'senderId': senderId,
    'text': text,
    'timestamp': FieldValue.serverTimestamp(),
  };

  factory ChatMessageModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChatMessageModel(
      senderId: data['senderId'] ?? '',
      text: data['text'] ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}