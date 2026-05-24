import 'package:cloud_firestore/cloud_firestore.dart';
import 'user_score_service.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String createChatId({
    required String touristId,
    required String ownerId,
    required String postId,
  }) {
    return '${touristId}_${ownerId}_$postId';
  }

  Future<String> createOrOpenChat({
    required String touristId,
    required String ownerId,
    required String postId,
  }) async {
    final chatId = createChatId(
      touristId: touristId,
      ownerId: ownerId,
      postId: postId,
    );

    final chatRef = _firestore.collection('chats').doc(chatId);

    final chatDoc = await chatRef.get();

    if (!chatDoc.exists) {
      await chatRef.set({
        'chatId': chatId,
        'touristId': touristId,
        'ownerId': ownerId,
        'postId': postId,
        'users': [touristId, ownerId],
        'lastMessage': '',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }

    return chatId;
  }

  Future<void> sendMessage({
    required String chatId,
    required String senderId,
    required String recipientId,
    required String text,
  }) async {
    if (text.trim().isEmpty) return;

    final messagesRef =
        _firestore.collection('chats').doc(chatId).collection('messages');

    await messagesRef.add({
      'senderId': senderId,
      'text': text.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    });

    await _firestore.collection('chats').doc(chatId).update({
      'lastMessage': text.trim(),
      'lastSenderId': senderId,
      'unreadFor': recipientId,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // Update sender's chatCount and dynamic user score
    final userRef = _firestore.collection('users').doc(senderId);
    await _firestore.runTransaction((transaction) async {
      final userSnapshot = await transaction.get(userRef);
      if (userSnapshot.exists) {
        final currentChats =
            (userSnapshot.data()?['chatCount'] as num?)?.toInt() ?? 0;
        transaction.update(userRef, {'chatCount': currentChats + 1});
      }
    });
    await UserScoreService().updateUserScore(senderId);
  }

  Future<void> clearUnread(String chatId) async {
    await _firestore.collection('chats').doc(chatId).update({
      'unreadFor': '',
    });
  }

  Stream<QuerySnapshot> getMessages(
    String chatId,
  ) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy(
          'createdAt',
          descending: false,
        )
        .snapshots();
  }

  Stream<QuerySnapshot> getUserChats(String userId) {
    return _firestore
        .collection('chats')
        .where('users', arrayContains: userId)
        .snapshots();
  }
}
