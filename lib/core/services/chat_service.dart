import 'package:cloud_firestore/cloud_firestore.dart';

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
      'updatedAt': FieldValue.serverTimestamp(),
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

  Stream<QuerySnapshot> getUserChats(
    String userId,
  ) {
    return _firestore
        .collection('chats')
        .where(
          'users',
          arrayContains: userId,
        )
        .orderBy(
          'updatedAt',
          descending: true,
        )
        .snapshots();
  }
}
