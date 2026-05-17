import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../chat/chat_room_screen.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/chat_service.dart';

class PlaceDetailsScreen extends StatelessWidget {
  final String placeId;
  final String ownerId;
  final String placeName;

  const PlaceDetailsScreen({
    super.key,
    this.placeId = 'post123',
    this.ownerId = 'owner123',
    this.placeName = 'Local Place',
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(placeName),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            final currentUser = FirebaseAuth.instance.currentUser;
            if (currentUser == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Please login to start a chat.'),
                ),
              );
              return;
            }

            if (currentUser.uid == ownerId) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('You cannot chat with yourself.'),
                ),
              );
              return;
            }

            final authService = AuthService();
            final canChat = await authService.canOpenChatWithUser(ownerId);
            if (!context.mounted) return;

            if (!canChat) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'The owner is not accepting chats at this time.',
                  ),
                ),
              );
              return;
            }

            final chatService = ChatService();
            final chatId = await chatService.createOrOpenChat(
              touristId: currentUser.uid,
              ownerId: ownerId,
              postId: placeId,
            );
            if (!context.mounted) return;

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ChatRoomScreen(
                  chatId: chatId,
                ),
              ),
            );
          },
          child: const Text('Message Owner'),
        ),
      ),
    );
  }
}
