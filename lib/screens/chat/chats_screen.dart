import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import 'ai_chat_screen.dart';
import 'chat_privacy_screen.dart';
import 'chat_room_screen.dart';

class ChatsScreen extends StatelessWidget {
  const ChatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Chats')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _ChatEntryCard(
            icon: Icons.auto_awesome,
            iconColor: AppColors.primaryGreen,
            title: 'AI Local Guide',
            subtitle: 'Get personalized place recommendations',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AiChatScreen()),
            ),
          ),
          const SizedBox(height: 12),
          _ChatEntryCard(
            icon: Icons.chat_bubble_outline,
            title: 'Chat with place owner',
            subtitle: 'Message a venue from place details',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ChatRoomScreen()),
            ),
          ),
          const SizedBox(height: 12),
          _ChatEntryCard(
            icon: Icons.privacy_tip_outlined,
            title: 'Chat privacy',
            subtitle: 'Email visibility and read receipts',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ChatPrivacyScreen()),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatEntryCard extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ChatEntryCard({
    required this.icon,
    this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: (iconColor ?? AppColors.primaryGreen)
              .withValues(alpha: 0.15),
          child: Icon(icon, color: iconColor ?? AppColors.primaryGreen),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
