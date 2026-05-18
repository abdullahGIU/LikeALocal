import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/services/chat_service.dart';

class ChatRoomScreen extends StatefulWidget {
  final String chatId;

  const ChatRoomScreen({
    super.key,
    required this.chatId,
  });

  @override
  State<ChatRoomScreen> createState() {
    return _ChatRoomScreenState();
  }
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  final TextEditingController _messageController = TextEditingController();

  final ChatService _chatService = ChatService();

  String get currentUserId => FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  Widget build(BuildContext context) {
    if (currentUserId.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Chat'),
        ),
        body: const Center(
          child: Text('You must be logged in to send messages.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Chat"),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _chatService.getMessages(
                widget.chatId,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text(
                      "No messages yet",
                    ),
                  );
                }

                final messages = snapshot.data!.docs;

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final text = message['text'] ?? '';
                    final senderId = message['senderId'] ?? '';
                    final isMe = senderId == currentUserId;

                    return Align(
                      alignment:
                          isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(
                          vertical: 4,
                        ),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isMe ? Colors.green : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          text,
                          style: TextStyle(
                            color: isMe ? Colors.white : Colors.black,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: "Type a message",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                IconButton(
                  onPressed: () async {
                    final text = _messageController.text.trim();

                    if (text.isEmpty) return;

                    await _chatService.sendMessage(
                      chatId: widget.chatId,
                      senderId: currentUserId,
                      text: text,
                    );

                    _messageController.clear();
                  },
                  icon: const Icon(
                    Icons.send,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
