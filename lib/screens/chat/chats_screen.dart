import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/services/chat_service.dart';
import 'chat_room_screen.dart';

class ChatsScreen extends StatelessWidget {
  const ChatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Chats')),
        body: const Center(
          child: Text('Login to view your chats.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Chats')),
      body: StreamBuilder<QuerySnapshot>(
        stream: ChatService().getUserChats(currentUser.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Error loading chats:\n${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'No conversations yet.\nStart chatting with a place owner!',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          // Sort by updatedAt descending in Dart (avoids needing a Firestore composite index)
          final chats = snapshot.data!.docs.toList()
            ..sort((a, b) {
              final aData = a.data() as Map<String, dynamic>;
              final bData = b.data() as Map<String, dynamic>;
              final aTime = aData['updatedAt'] as Timestamp?;
              final bTime = bData['updatedAt'] as Timestamp?;
              if (aTime == null && bTime == null) return 0;
              if (aTime == null) return 1;
              if (bTime == null) return -1;
              return bTime.compareTo(aTime);
            });

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: chats.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final chat = chats[index];
              final data = chat.data() as Map<String, dynamic>;
              final chatId = data['chatId'] ?? chat.id;
              final touristId = data['touristId'] ?? '';
              final ownerId = data['ownerId'] ?? '';
              final lastMessage = data['lastMessage'] as String?;
              final peerId =
                  touristId == currentUser.uid ? ownerId : touristId;

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('users')
                    .doc(peerId)
                    .get(),
                builder: (context, userSnapshot) {
                  final peerName =
                      userSnapshot.hasData && userSnapshot.data!.exists
                          ? (userSnapshot.data!['fullName'] as String? ?? peerId)
                          : peerId;

                  return Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: const Color(0xFF1D9E75),
                        child: Text(
                          peerName.isNotEmpty
                              ? peerName[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(
                        peerName,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        lastMessage != null && lastMessage.isNotEmpty
                            ? lastMessage
                            : 'Tap to open the chat',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChatRoomScreen(chatId: chatId),
                          ),
                        );
                      },
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
