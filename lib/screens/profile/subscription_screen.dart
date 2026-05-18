import 'package:flutter/material.dart';

class SubscriptionScreen extends StatelessWidget {
  const SubscriptionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const green = Color(0xFF1D9E75);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Premium'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'LikeALocal Premium',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Upgrade your travel experience with more freedom and smarter recommendations.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 28),
            _benefit(Icons.push_pin, 'Unlimited saved pins'),
            _benefit(Icons.smart_toy, 'Advanced AI recommendations'),
            _benefit(Icons.location_on, 'Hidden gem alerts'),
            _benefit(Icons.star, 'Priority local suggestions'),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Premium upgrade request saved.',
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: green,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  'Upgrade to Premium',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _benefit(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(
        children: [
          Icon(
            icon,
            color: const Color(0xFF1D9E75),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}
