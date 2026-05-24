import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:provider/provider.dart';

import '../../core/constants/ai_prompt_suggestions.dart';
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
  List<String> _suggestions = [];

  @override
  void initState() {
    super.initState();
    _reshuffleSuggestions();
  }

  void _reshuffleSuggestions() {
    setState(() {
      _suggestions = AiPromptSuggestions.shuffled(count: 16);
    });
  }

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
    final priorHistory = _messages.length > 1
        ? _messages.sublist(0, _messages.length - 1)
        : <AiMessage>[];

    try {
      final reply = await _ai.chat(
        userMessage: content,
        history: priorHistory,
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
        _suggestions = AiPromptSuggestions.shuffled(count: 16);
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
        _suggestions = AiPromptSuggestions.shuffled(count: 16);
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
          IconButton(
            icon: const Icon(Icons.shuffle),
            tooltip: 'New suggestions',
            onPressed: _loading ? null : _reshuffleSuggestions,
          ),
          if (!ApiKeys.hasGeminiKey)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Chip(
                label: const Text('Demo', style: TextStyle(fontSize: 11)),
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
                ? _EmptyChat()
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length + (_loading ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (_loading && index == _messages.length) {
                        return const _TypingIndicator();
                      }
                      return _Bubble(message: _messages[index]);
                    },
                  ),
          ),
          _SuggestionBar(
            suggestions: _suggestions,
            loading: _loading,
            onTap: _send,
            onShuffle: _reshuffleSuggestions,
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
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.auto_awesome, size: 56, color: AppColors.primaryGreen),
            SizedBox(height: 16),
            Text(
              'Your local AI guide',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Tap a suggestion below or type your own question.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _SuggestionBar extends StatelessWidget {
  final List<String> suggestions;
  final bool loading;
  final void Function(String) onTap;
  final VoidCallback onShuffle;

  const _SuggestionBar({
    required this.suggestions,
    required this.loading,
    required this.onTap,
    required this.onShuffle,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 8, 0),
            child: Row(
              children: [
                const Text(
                  'Try asking',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: loading ? null : onShuffle,
                  icon: const Icon(Icons.shuffle, size: 16),
                  label: const Text('Shuffle', style: TextStyle(fontSize: 12)),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 108,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 10),
              itemCount: suggestions.length,
              itemBuilder: (context, index) {
                final text = suggestions[index];
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ActionChip(
                    label: Text(
                      text,
                      style: const TextStyle(fontSize: 12),
                    ),
                    backgroundColor: const Color(0xFFE8FFF5),
                    side: BorderSide(
                      color: AppColors.primaryGreen.withOpacity( 0.35),
                    ),
                    onPressed: loading ? null : () => onTap(text),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity( 0.06),
                blurRadius: 8,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primaryGreen,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'LikeALocal is thinking…',
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
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
          maxWidth: MediaQuery.sizeOf(context).width * 0.85,
        ),
        decoration: BoxDecoration(
          color: isUser ? AppColors.primaryGreen : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 16),
          ),
          boxShadow: [
            if (!isUser)
              BoxShadow(
                color: Colors.black.withOpacity( 0.06),
                blurRadius: 8,
              ),
          ],
        ),
        child: isUser
            ? Text(
                message.text,
                style: TextStyle(
                  color: isUser ? Colors.white : AppColors.textPrimary,
                  height: 1.45,
                  fontSize: 15,
                ),
              )
            : MarkdownBody(
                data: message.text,
                styleSheet: MarkdownStyleSheet(
                  p: const TextStyle(fontSize: 14, color: Colors.black87),
                  strong: const TextStyle(
                    fontWeight: FontWeight.bold, 
                    color: Colors.black
                  ),
                  listBullet: const TextStyle(
                    fontSize: 14, 
                    color: Colors.black87
                  ),
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
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
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
