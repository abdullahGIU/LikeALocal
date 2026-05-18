import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/providers/auth_provider.dart';

class ChatPrivacyScreen extends StatefulWidget {
  const ChatPrivacyScreen({super.key});

  @override
  State<ChatPrivacyScreen> createState() => _ChatPrivacyScreenState();
}

class _ChatPrivacyScreenState extends State<ChatPrivacyScreen> {
  bool _initialized = false;
  bool chatEnabled = true;
  bool scheduleEnabled = false;
  TimeOfDay chatFrom = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay chatTo = const TimeOfDay(hour: 22, minute: 0);
  bool _isSaving = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;

    final user = context.read<AuthProvider>().currentUser;
    if (user != null) {
      chatEnabled = user.chatEnabled;
      scheduleEnabled = user.chatScheduleEnabled;
      chatFrom = _parseTime(user.chatAvailableFrom) ?? chatFrom;
      chatTo = _parseTime(user.chatAvailableTo) ?? chatTo;
    }
    _initialized = true;
  }

  TimeOfDay? _parseTime(String value) {
    final parts = value.split(':');
    if (parts.length != 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    return TimeOfDay(hour: hour, minute: minute);
  }

  String _formatTime(TimeOfDay value) {
    return value.format(context);
  }

  Future<void> _pickTime({required bool isStart}) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart ? chatFrom : chatTo,
    );

    if (picked == null) return;
    setState(() {
      if (isStart) {
        chatFrom = picked;
      } else {
        chatTo = picked;
      }
    });
  }

  Future<void> _savePrivacySettings() async {
    setState(() {
      _isSaving = true;
    });

    final success = await context.read<AuthProvider>().updateChatPrivacy(
          chatEnabled: chatEnabled,
          chatScheduleEnabled: scheduleEnabled,
          chatAvailableFrom:
              '${chatFrom.hour.toString().padLeft(2, '0')}:${chatFrom.minute.toString().padLeft(2, '0')}',
          chatAvailableTo:
              '${chatTo.hour.toString().padLeft(2, '0')}:${chatTo.minute.toString().padLeft(2, '0')}',
        );

    setState(() {
      _isSaving = false;
    });

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success
            ? 'Your chat privacy settings were saved.'
            : 'Failed to save chat settings. Please try again.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Chat Privacy')),
        body: const Center(
          child: Text('You must be logged in to configure chat privacy.'),
        ),
      );
    }

    if (!_initialized) {
      chatEnabled = user.chatEnabled;
      scheduleEnabled = user.chatScheduleEnabled;
      chatFrom = _parseTime(user.chatAvailableFrom) ?? chatFrom;
      chatTo = _parseTime(user.chatAvailableTo) ?? chatTo;
      _initialized = true;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat Privacy'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SwitchListTile(
              title: const Text('Allow users to chat with me'),
              subtitle: const Text(
                  'If disabled, others cannot start a chat with you.'),
              value: chatEnabled,
              onChanged: (value) {
                setState(() {
                  chatEnabled = value;
                });
              },
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Use chat availability schedule'),
              subtitle:
                  const Text('Only allow chats during the selected hours.'),
              value: scheduleEnabled,
              onChanged: chatEnabled
                  ? (value) {
                      setState(() {
                        scheduleEnabled = value;
                      });
                    }
                  : null,
            ),
            if (scheduleEnabled && chatEnabled) ...[
              const SizedBox(height: 16),
              ListTile(
                title: const Text('Available from'),
                subtitle: Text(_formatTime(chatFrom)),
                trailing: const Icon(Icons.keyboard_arrow_down),
                onTap: () => _pickTime(isStart: true),
              ),
              ListTile(
                title: const Text('Available until'),
                subtitle: Text(_formatTime(chatTo)),
                trailing: const Icon(Icons.keyboard_arrow_down),
                onTap: () => _pickTime(isStart: false),
              ),
            ],
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isSaving ? null : _savePrivacySettings,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: _isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Save Settings'),
            ),
          ],
        ),
      ),
    );
  }
}
