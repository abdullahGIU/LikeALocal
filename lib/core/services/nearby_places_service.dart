import 'dart:convert';

import 'package:http/http.dart' as http;

import '../constants/api_keys.dart';
import '../models/place.dart';

/// Fetches real nearby POIs from Mapbox Search Box API.
class NearbyPlacesService {
  static const Map<String, String> categoryToMapboxId = {
    'Cafés': 'coffee',
    'Restaurants': 'restaurant',
    'Parks': 'park',
    'Museums': 'museum',
  };

  Future<List<Place>> fetchNearby({
    required double latitude,
    required double longitude,
    double radiusKm = 20,
  }) async {
    if (!ApiKeys.hasMapboxToken) return [];

    final bbox = _bboxAround(latitude, longitude, radiusKm);
    final proximity = '$longitude,$latitude';
    final places = <Place>[];
    final seenIds = <String>{};

    for (final entry in categoryToMapboxId.entries) {
      final uri = Uri.https(
        'api.mapbox.com',
        '/search/searchbox/v1/category/${entry.value}',
        {
          'access_token': ApiKeys.mapboxAccessToken,
          'proximity': proximity,
          'bbox': bbox,
          'limit': '25',
          'language': 'en',
        },
      );

      try {
        final response = await http.get(uri);
        if (response.statusCode != 200) continue;

        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final features = data['features'] as List<dynamic>? ?? [];

        for (final feature in features) {
          if (feature is! Map<String, dynamic>) continue;
          final place = Place.fromMapboxFeature(feature, entry.key);
          if (seenIds.add(place.id)) {
            places.add(place);
          }
        }
      } catch (_) {
        continue;
      }
    }

    return places;
  }

  String _bboxAround(double lat, double lng, double radiusKm) {
    final delta = radiusKm / 111.0;
    final minLng = (lng - delta).clamp(-180.0, 180.0);
    final maxLng = (lng + delta).clamp(-180.0, 180.0);
    final minLat = (lat - delta).clamp(-85.0, 85.0);
    final maxLat = (lat + delta).clamp(-85.0, 85.0);
    return '$minLng,$minLat,$maxLng,$maxLat';
  }
}
