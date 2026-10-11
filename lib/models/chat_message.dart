import 'package:cloud_firestore/cloud_firestore.dart';

class ChatMessage {
  final String id;
  final String bookingId;
  final String senderId;
  final String senderName;
  final String? senderPhoto;
  final String text;
  final DateTime createdAt;
  final bool isRead;

  const ChatMessage({
    required this.id,
    required this.bookingId,
    required this.senderId,
    required this.senderName,
    this.senderPhoto,
    required this.text,
    required this.createdAt,
    this.isRead = false,
  });

  factory ChatMessage.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    DateTime created = DateTime.now();
    if (data['createdAt'] is Timestamp) {
      created = (data['createdAt'] as Timestamp).toDate();
    } else if (data['createdAt'] is String) {
      created = DateTime.tryParse(data['createdAt'] as String) ?? DateTime.now();
    }

    return ChatMessage(
      id: doc.id,
      bookingId: data['bookingId'] as String? ?? '',
      senderId: data['senderId'] as String? ?? '',
      senderName: data['senderName'] as String? ?? 'User',
      senderPhoto: data['senderPhoto'] as String?,
      text: data['text'] as String? ?? '',
      createdAt: created,
      isRead: data['isRead'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'bookingId': bookingId,
      'senderId': senderId,
      'senderName': senderName,
      'senderPhoto': senderPhoto,
      'text': text,
      'createdAt': FieldValue.serverTimestamp(),
      'isRead': isRead,
    };
  }
}
