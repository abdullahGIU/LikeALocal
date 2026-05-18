import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class ViewedPlaceEntry {
  final String id;
  final String name;

  const ViewedPlaceEntry({required this.id, required this.name});
}

/// Stores places the user opened (viewed details), not search queries.
class SearchHistoryService {
  static const _key = 'viewed_places_history';
  static const _maxItems = 15;

  Future<List<ViewedPlaceEntry>> getViewedPlaces() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];
    return raw
        .map((entry) {
          try {
            final map = jsonDecode(entry) as Map<String, dynamic>;
            final id = map['id'] as String?;
            final name = map['name'] as String?;
            if (id == null || name == null) return null;
            return ViewedPlaceEntry(id: id, name: name);
          } catch (_) {
            return null;
          }
        })
        .whereType<ViewedPlaceEntry>()
        .toList();
  }

  Future<void> addViewedPlace({
    required String placeId,
    required String placeName,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final history = prefs.getStringList(_key) ?? [];
    final encoded = jsonEncode({'id': placeId, 'name': placeName});

    history.removeWhere((entry) {
      try {
        final map = jsonDecode(entry) as Map<String, dynamic>;
        return map['id'] == placeId;
      } catch (_) {
        return false;
      }
    });
    history.insert(0, encoded);
    if (history.length > _maxItems) {
      history.removeRange(_maxItems, history.length);
    }
    await prefs.setStringList(_key, history);
  }

  Future<void> removePlace(String placeId) async {
    final prefs = await SharedPreferences.getInstance();
    final history = prefs.getStringList(_key) ?? [];
    history.removeWhere((entry) {
      try {
        final map = jsonDecode(entry) as Map<String, dynamic>;
        return map['id'] == placeId;
      } catch (_) {
        return false;
      }
    });
    await prefs.setStringList(_key, history);
  }
}
