import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_colors.dart';
import '../core/providers/auth_provider.dart';
import '../core/providers/place_provider.dart';
import '../core/providers/user_provider.dart';
import '../core/services/ai_service.dart';
import '../screens/chat/ai_chat_screen.dart';
import '../screens/profile/subscription_screen.dart';

class AiRecommendationsCard extends StatefulWidget {
  const AiRecommendationsCard({super.key});

  @override
  State<AiRecommendationsCard> createState() => _AiRecommendationsCardState();
}

class _AiRecommendationsCardState extends State<AiRecommendationsCard> {
  final _ai = AiService();
  String? _text;
  bool _loading = false;

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _text = null;
    });
    final places = context.read<PlaceProvider>().nearbyPlaces;
    final prefs = context.read<UserProvider>();

    try {
      final result = await _ai.getRecommendations(
        nearbyPlaces: places,
        budget: prefs.budget,
        atmosphere: prefs.atmosphere,
      );
      if (mounted) setState(() => _text = result);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    final isPremium = (user?.isPremium ?? false) || (user?.isSuperUser ?? false);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.auto_awesome, color: AppColors.primaryGreen),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'AI Suggested Places',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (!isPremium)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Premium',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              if (_loading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: CircularProgressIndicator(
                      color: AppColors.primaryGreen,
                    ),
                  ),
                )
              else if (_text != null)
                MarkdownBody(
                  data: _text!,
                  styleSheet: MarkdownStyleSheet(
                    p: const TextStyle(fontSize: 14, color: Colors.black87, height: 1.45),
                    strong: const TextStyle(
                      fontWeight: FontWeight.bold, 
                      color: Colors.black
                    ),
                    listBullet: const TextStyle(
                      fontSize: 14, 
                      color: Colors.black87
                    ),
                  ),
                )
              else
                const Text(
                  'Tap below for personalized picks based on your budget and vibe.',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              const SizedBox(height: 12),
              Row(
                children: [
                  TextButton.icon(
                    onPressed: _loading ? null : _load,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Get suggestions'),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      if (!isPremium) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const SubscriptionScreen(),
                          ),
                        );
                      } else {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AiChatScreen(),
                          ),
                        );
                      }
                    },
                    child: Text(isPremium ? 'Open chat' : 'Upgrade'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
