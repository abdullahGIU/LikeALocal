import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../core/models/place.dart';
import '../core/utils/place_image_urls.dart';

/// Loads a place photo with a unique fallback if the primary URL fails.
class PlaceImage extends StatelessWidget {
  final Place place;
  final int variant;
  final BoxFit fit;
  final Widget? placeholder;

  const PlaceImage({
    super.key,
    required this.place,
    this.variant = 0,
    this.fit = BoxFit.cover,
    this.placeholder,
  });

  @override
  Widget build(BuildContext context) {
    final urls = place.displayImageUrls;
    final primary =
        variant < urls.length ? urls[variant] : place.primaryImageUrl;
    final fallback = PlaceImageUrls.fallback(seed: place.id, variant: variant);

    return CachedNetworkImage(
      imageUrl: primary,
      fit: fit,
      placeholder: (_, __) => placeholder ?? _defaultPlaceholder(),
      errorWidget: (_, __, ___) => CachedNetworkImage(
        imageUrl: fallback,
        fit: fit,
        placeholder: (_, __) => placeholder ?? _defaultPlaceholder(),
        errorWidget: (_, __, ___) => placeholder ?? _defaultPlaceholder(),
      ),
    );
  }

  Widget _defaultPlaceholder() {
    return Container(
      color: Colors.grey.shade300,
      child: const Center(
        child: Icon(Icons.image_outlined, color: Colors.white70),
      ),
    );
  }
}
