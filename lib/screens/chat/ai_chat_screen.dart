import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/api_keys.dart';
import '../../core/constants/app_colors.dart';
import '../../core/models/ai_message.dart';
import '../../core/providers/place_provider.dart';
import '../../core/providers/user_provider.dart';
import '../../core/services/ai_service.dart';

class AiChatScreen extends StatefulWidget {
  const AiChatScreen({super.key});

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final _ai = AiService();
  final List<AiMessage> _messages = [];
  bool _loading = false;

  static const _starters = [
    'Cheap local seafood near me',
    'Quiet café to work from',
    'Traditional restaurants with lively vibe',
  ];

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _send([String? text]) async {
    final content = (text ?? _controller.text).trim();
    if (content.isEmpty || _loading) return;

    _controller.clear();
    setState(() {
      _messages.add(AiMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        role: AiMessageRole.user,
        text: content,
        createdAt: DateTime.now(),
      ));
      _loading = true;
    });
    _scrollToEnd();

    final places = context.read<PlaceProvider>().nearbyPlaces;
    final prefs = context.read<UserProvider>();

    try {
      final reply = await _ai.chat(
        userMessage: content,
        history: _messages,
        nearbyPlaces: places,
        budget: prefs.budget,
        atmosphere: prefs.atmosphere,
      );
      if (!mounted) return;
      setState(() {
        _messages.add(AiMessage(
          id: '${DateTime.now().millisecondsSinceEpoch}_ai',
          role: AiMessageRole.assistant,
          text: reply,
          createdAt: DateTime.now(),
        ));
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _messages.add(AiMessage(
          id: '${DateTime.now().millisecondsSinceEpoch}_err',
          role: AiMessageRole.assistant,
          text: 'Sorry, I could not respond right now. Please try again.',
          createdAt: DateTime.now(),
        ));
      });
    } finally {
      if (mounted) setState(() => _loading = false);
      _scrollToEnd();
    }
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final isLoggedIn = FirebaseAuth.instance.currentUser != null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('AI Local Guide'),
        actions: [
          if (!ApiKeys.hasGeminiKey)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Chip(
                label: const Text('Demo mode', style: TextStyle(fontSize: 11)),
                backgroundColor: Colors.amber.shade100,
                padding: EdgeInsets.zero,
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          if (!isLoggedIn)
            Material(
              color: Colors.amber.shade50,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.amber.shade900),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text('Log in to save preferences for better tips.'),
                    ),
                  ],
                ),
              ),
            ),
          Expanded(
            child: _messages.isEmpty
                ? _EmptyChat(onSuggestionTap: _send)
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length + (_loading ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (_loading && index == _messages.length) {
                        return const Padding(
                          padding: EdgeInsets.all(12),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        );
                      }
                      return _Bubble(message: _messages[index]);
                    },
                  ),
          ),
          if (_messages.isEmpty)
            SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: _starters
                    .map(
                      (s) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ActionChip(
                          label: Text(s, style: const TextStyle(fontSize: 12)),
                          onPressed: () => _send(s),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          _InputBar(
            controller: _controller,
            loading: _loading,
            onSend: () => _send(),
          ),
        ],
      ),
    );
  }
}

class _EmptyChat extends StatelessWidget {
  final void Function(String) onSuggestionTap;

  const _EmptyChat({required this.onSuggestionTap});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.auto_awesome, size: 56, color: AppColors.primaryGreen),
            const SizedBox(height: 16),
            const Text(
              'Ask for local recommendations',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Example: "I want cheap local seafood near me"',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  final AiMessage message;

  const _Bubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.82,
        ),
        decoration: BoxDecoration(
          color: isUser ? AppColors.primaryGreen : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            if (!isUser)
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 8,
              ),
          ],
        ),
        child: Text(
          message.text,
          style: TextStyle(
            color: isUser ? Colors.white : AppColors.textPrimary,
            height: 1.4,
          ),
        ),
      ),
    );
  }
}

class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final bool loading;
  final VoidCallback onSend;

  const _InputBar({
    required this.controller,
    required this.loading,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => onSend(),
                decoration: InputDecoration(
                  hintText: 'Ask about places near you...',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Material(
              color: AppColors.primaryGreen,
              shape: const CircleBorder(),
              child: IconButton(
                onPressed: loading ? null : onSend,
                icon: const Icon(Icons.send, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
