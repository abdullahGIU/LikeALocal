import 'package:flutter/material.dart';
import '../core/models/place.dart';
import '../screens/places/place_details_screen.dart';
import 'place_image.dart';

class PlaceCard extends StatelessWidget {
  final Place place;
  final VoidCallback? onTap;
  final bool showOpenStatus;
  final bool horizontal;

  const PlaceCard({
    super.key,
    required this.place,
    this.onTap,
    this.showOpenStatus = false,
    this.horizontal = false,
  });

  void _defaultOnTap(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PlaceDetailsScreen(place: place),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: horizontal ? 300 : null,
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 6),
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap ?? () => _defaultOnTap(context),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: SizedBox(
                    width: 92,
                    height: 92,
                    child: PlaceImage(
                      place: place,
                      placeholder: _placeholderImage(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        place.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        place.category,
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            size: 18,
                            color: Colors.amber,
                          ),
                          const SizedBox(width: 4),
                          Text(place.rating.toStringAsFixed(1)),
                          const SizedBox(width: 10),
                          if (place.distanceKm != null)
                            _chip(
                              '${place.distanceKm!.toStringAsFixed(1)} km',
                              const Color(0xFFE8FFF5),
                              const Color(0xFF007A53),
                            ),
                          if (showOpenStatus) ...[
                            const SizedBox(width: 8),
                            _chip(
                              place.isOpen ? 'Open' : 'Closed',
                              place.isOpen
                                  ? const Color(0xFFE6F7ED)
                                  : const Color(0xFFFDEDED),
                              place.isOpen
                                  ? const Color(0xFF1E8E3E)
                                  : const Color(0xFFB3261E),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _placeholderImage() {
    return Container(
      color: Colors.grey.shade300,
      child: const Icon(Icons.image, color: Colors.white70, size: 28),
    );
  }

  Widget _chip(String label, Color background, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }
}
