import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/providers/auth_provider.dart';

class SubscriptionScreen extends StatelessWidget {
  const SubscriptionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;
    final isPremium = user?.isPremium ?? false;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Premium')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF00BC7D), Color(0xFF009689)],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.workspace_premium,
                    color: Colors.white, size: 40),
                const SizedBox(height: 12),
                Text(
                  isPremium ? 'You are Premium' : 'Upgrade to Premium',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  isPremium
                      ? 'Enjoy unlimited pins and AI recommendations.'
                      : 'Unlock the full LikeALocal experience.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _PlanCard(
            title: 'Free',
            price: '\$0',
            period: 'forever',
            features: const [
              '5 saved pins',
              'Basic place search',
              'Map & nearby places',
              'Standard notifications',
            ],
            highlighted: !isPremium,
            isCurrent: !isPremium,
          ),
          const SizedBox(height: 16),
          _PlanCard(
            title: 'Premium',
            price: '\$4.99',
            period: '/ month',
            features: const [
              'Unlimited pins',
              'AI chat recommendations',
              'Priority AI suggestions',
              'Exclusive local places',
              'Nearby place alerts',
            ],
            highlighted: true,
            isCurrent: isPremium,
            accent: true,
          ),
          const SizedBox(height: 28),
          if (!isPremium)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: auth.isLoading
                    ? null
                    : () async {
                        final ok = await auth.upgradeToPremium();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                ok
                                    ? 'Welcome to Premium! (demo upgrade)'
                                    : auth.errorMessage ??
                                        'Could not upgrade.',
                              ),
                            ),
                          );
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: auth.isLoading
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Upgrade to Premium',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            )
          else
            OutlinedButton(
              onPressed: null,
              child: const Text('Current plan'),
            ),
          const SizedBox(height: 12),
          Text(
            'Demo: upgrade sets isPremium in Firestore — no real payment.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final String title;
  final String price;
  final String period;
  final List<String> features;
  final bool highlighted;
  final bool isCurrent;
  final bool accent;

  const _PlanCard({
    required this.title,
    required this.price,
    required this.period,
    required this.features,
    this.highlighted = false,
    this.isCurrent = false,
    this.accent = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: highlighted ? AppColors.primaryGreen : Colors.grey.shade300,
          width: highlighted ? 2 : 1,
        ),
        boxShadow: [
          if (highlighted)
            BoxShadow(
              color: AppColors.primaryGreen.withValues(alpha: 0.12),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              if (isCurrent)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primaryGreen.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Current',
                    style: TextStyle(
                      color: AppColors.primaryGreen,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                price,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: accent ? AppColors.primaryGreen : null,
                ),
              ),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(period, style: const TextStyle(color: Colors.grey)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...features.map(
            (f) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    size: 18,
                    color: accent
                        ? AppColors.primaryGreen
                        : Colors.grey.shade500,
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: Text(f)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
