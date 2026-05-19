import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/models/place.dart';
import '../core/providers/place_provider.dart';
import '../core/providers/auth_provider.dart';
import '../screens/places/place_details_screen.dart';
import 'place_card.dart';

class SponsoredPlacesSection extends StatelessWidget {
  const SponsoredPlacesSection({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    if (user != null && (user.isPremium || user.isSuperUser)) {
      return const SizedBox.shrink();
    }

    final sponsored = context.watch<PlaceProvider>().sponsoredPlaces;
    if (sponsored.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.amber.shade100,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'SPONSORED',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.amber.shade900,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Featured local places',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: sponsored.length,
            itemBuilder: (context, index) {
              final place = sponsored[index];
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: _SponsoredCard(place: place),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _SponsoredCard extends StatelessWidget {
  final Place place;

  const _SponsoredCard({required this.place});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 280,
      child: Stack(
        children: [
          PlaceCard(
            place: place,
            horizontal: true,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PlaceDetailsScreen(place: place),
              ),
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.amber.shade800,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'Ad',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
