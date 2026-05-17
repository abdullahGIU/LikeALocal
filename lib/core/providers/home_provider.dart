import 'package:flutter/material.dart';
import '../models/place.dart';
import 'place_provider.dart';

/// Home tab reads from [PlaceProvider].
class HomeProvider extends ChangeNotifier {
  PlaceProvider? _places;

  void bind(PlaceProvider places) {
    if (_places == places) return;
    _places?.removeListener(notifyListeners);
    _places = places;
    _places!.addListener(notifyListeners);
    notifyListeners();
  }

  Map<String, int> get trendingCategories =>
      _places?.trendingCategories ?? {for (final c in PlaceProvider.defaultCategories) c: 0};

  List<Place> get nearbyPlaces => _places?.nearbyPlaces ?? const [];

  bool get isLoading => _places?.isLoading ?? false;

  String? get errorMessage => _places?.errorMessage;

  String? get locationMessage => _places?.locationMessage;

  Future<void> initialize() => _places?.refresh() ?? Future.value();
}
