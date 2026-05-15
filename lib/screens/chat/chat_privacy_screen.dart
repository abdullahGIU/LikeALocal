import 'package:flutter/material.dart';

class ChatPrivacyScreen extends StatelessWidget {
  const ChatPrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chat Privacy')),
      body: const Center(
        child: Text('Chat Privacy Screen'),
      ),
    );
  }
}
