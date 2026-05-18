import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/providers/user_provider.dart';

class ChatPrivacyScreen extends StatelessWidget {
  const ChatPrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final prefs = context.watch<UserProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Chat privacy')),
      body: ListView(
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Control how you appear in owner chats and what data is shared.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          SwitchListTile(
            title: const Text('Hide email in chats'),
            subtitle: const Text('Only your display name is shown'),
            value: prefs.chatPrivacyHideEmail,
            activeColor: AppColors.primaryGreen,
            onChanged: prefs.setChatPrivacyHideEmail,
          ),
          SwitchListTile(
            title: const Text('Read receipts'),
            subtitle: const Text('Let others see when you read messages'),
            value: prefs.chatPrivacyReadReceipts,
            activeColor: AppColors.primaryGreen,
            onChanged: prefs.setChatPrivacyReadReceipts,
          ),
          const Padding(
            padding: EdgeInsets.all(16),
            child: Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Data we use',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Location is used for nearby recommendations and geofencing alerts. '
                      'AI prompts may include your budget and atmosphere preferences — never your password.',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
