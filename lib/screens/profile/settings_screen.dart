import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/providers/notification_provider.dart';
import '../../core/providers/place_provider.dart';
import '../../core/providers/user_provider.dart';
import '../../core/services/nearby_monitor_service.dart';
import '../../core/services/notification_service.dart';
import '../chat/ai_chat_screen.dart';
import '../chat/chat_privacy_screen.dart';
import '../notifications/notifications_screen.dart';
import 'subscription_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final prefs = context.watch<UserProvider>();
    final userId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          _SectionHeader('Notifications'),
          SwitchListTile(
            title: const Text('Enable notifications'),
            subtitle: const Text('Push and local alerts'),
            value: prefs.notificationsEnabled,
            activeColor: AppColors.primaryGreen,
            onChanged: prefs.setNotificationsEnabled,
          ),
          ListTile(
            leading: const Icon(Icons.notifications_outlined),
            title: const Text('Notification inbox'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const NotificationsScreen(),
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.near_me),
            title: const Text('Test nearby alert'),
            subtitle: const Text('Geofencing demo for pinned places'),
            onTap: () async {
              final pinned = context.read<PlaceProvider>().pinnedPlaces;
              await NearbyMonitorService().triggerDemoNotification(pinned);
              if (context.mounted) {
                await context.read<NotificationProvider>().load();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Nearby notification sent')),
                );
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.send_outlined),
            title: const Text('Send test push (local)'),
            onTap: () async {
              await NotificationService.instance.sendTestNotification();
              if (context.mounted) {
                await context.read<NotificationProvider>().load();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Test notification sent')),
                );
              }
            },
          ),
          const Divider(),
          _SectionHeader('AI & recommendations'),
          ListTile(
            leading: const Icon(Icons.auto_awesome),
            title: const Text('AI local guide'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AiChatScreen()),
            ),
          ),
          ListTile(
            title: const Text('Budget preference'),
            subtitle: Text(prefs.budget),
            trailing: DropdownButton<String>(
              value: prefs.budget,
              items: const [
                DropdownMenuItem(value: 'low', child: Text('Cheap')),
                DropdownMenuItem(value: 'medium', child: Text('Medium')),
                DropdownMenuItem(value: 'high', child: Text('High')),
              ],
              onChanged: (v) {
                if (v != null) {
                  prefs.setBudget(v);
                  if (userId != null) prefs.syncPreferencesToFirestore(userId);
                }
              },
            ),
          ),
          ListTile(
            title: const Text('Atmosphere preference'),
            subtitle: Text(prefs.atmosphere),
            trailing: DropdownButton<String>(
              value: prefs.atmosphere,
              items: const [
                DropdownMenuItem(value: 'quiet', child: Text('Quiet')),
                DropdownMenuItem(value: 'lively', child: Text('Lively')),
                DropdownMenuItem(value: 'romantic', child: Text('Romantic')),
                DropdownMenuItem(value: 'traditional', child: Text('Traditional')),
              ],
              onChanged: (v) {
                if (v != null) {
                  prefs.setAtmosphere(v);
                  if (userId != null) prefs.syncPreferencesToFirestore(userId);
                }
              },
            ),
          ),
          const Divider(),
          _SectionHeader('Chat & privacy'),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('Chat privacy'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ChatPrivacyScreen()),
            ),
          ),
          const Divider(),
          _SectionHeader('Premium'),
          ListTile(
            leading: const Icon(Icons.workspace_premium, color: Colors.amber),
            title: const Text('Subscription plans'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SubscriptionScreen()),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: AppColors.primaryGreen,
        ),
      ),
    );
  }
}
