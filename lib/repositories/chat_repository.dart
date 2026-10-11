import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/chat_message.dart';

class ChatRepository {
  ChatRepository(this._firestore);
  final FirebaseFirestore _firestore;

  Stream<List<ChatMessage>> streamMessages(String bookingId) {
    return _firestore
        .collection('chats')
        .doc(bookingId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .limit(100)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => ChatMessage.fromFirestore(doc)).toList();
    });
  }

  Future<void> sendMessage({
    required String bookingId,
    required String senderId,
    required String senderName,
    String? senderPhoto,
    required String text,
  }) async {
    final chatDoc = _firestore.collection('chats').doc(bookingId);

    final msg = ChatMessage(
      id: '',
      bookingId: bookingId,
      senderId: senderId,
      senderName: senderName,
      senderPhoto: senderPhoto,
      text: text.trim(),
      createdAt: DateTime.now(),
    );

    await chatDoc.collection('messages').add(msg.toFirestore());

    // Update parent chat summary
    await chatDoc.set({
      'lastMessage': text.trim(),
      'lastSenderId': senderId,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return ChatRepository(FirebaseFirestore.instance);
});

final chatMessagesStreamProvider =
    StreamProvider.family<List<ChatMessage>, String>((ref, bookingId) {
  return ref.watch(chatRepositoryProvider).streamMessages(bookingId);
});
