import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../models/place.dart';
import '../services/firestore_service.dart';
import '../services/location_service.dart';
import '../services/nearby_places_service.dart';

/// Shared source for places shown on Home, Map, and Search.
class PlaceProvider extends ChangeNotifier {
  static const List<String> defaultCategories = [
    'Cafés',
    'Restaurants',
    'Parks',
    'Museums',
  ];

  final FirestoreService _firestoreService;
  final LocationService _locationService;
  final NearbyPlacesService _nearbyPlacesService;

  PlaceProvider({
    FirestoreService? firestoreService,
    LocationService? locationService,
    NearbyPlacesService? nearbyPlacesService,
  })  : _firestoreService = firestoreService ?? FirestoreService(),
        _locationService = locationService ?? LocationService(),
        _nearbyPlacesService = nearbyPlacesService ?? NearbyPlacesService();

  static const double nearbyRadiusKm = 20;

  List<Place> _allPlaces = [];
  List<Place> _nearbyPlaces = [];
  Position? _userPosition;
  bool _isLoading = false;
  String? _errorMessage;
  String? _locationMessage;

  List<Place> get allPlaces => _allPlaces;
  List<Place> get nearbyPlaces => _nearbyPlaces;
  Position? get userPosition => _userPosition;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get locationMessage => _locationMessage;
  bool get hasLocation => _userPosition != null;

  Map<String, int> get trendingCategories => {
        for (final category in defaultCategories)
          category: _allPlaces.where((p) => p.category == category).length,
      };

  Future<void> refresh() async {
    _isLoading = true;
    _errorMessage = null;
    _locationMessage = null;
    notifyListeners();

    try {
      _userPosition = await _locationService.getCurrentPosition();
      if (_userPosition == null) {
        _locationMessage =
            'Enable location to see real cafés and places near you.';
      }

      final firestorePlaces = await _firestoreService.fetchPlaces();
      var discoveredPlaces = <Place>[];

      if (_userPosition != null) {
        discoveredPlaces = await _nearbyPlacesService.fetchNearby(
          latitude: _userPosition!.latitude,
          longitude: _userPosition!.longitude,
          radiusKm: nearbyRadiusKm,
        );
        if (discoveredPlaces.isNotEmpty) {
          _firestoreService.upsertPlaces(discoveredPlaces).ignore();
        }
      }

      _allPlaces = _mergePlaces(firestorePlaces, discoveredPlaces);
      _attachDistances();
      _nearbyPlaces = _filterNearby(_allPlaces);
    } catch (_) {
      _errorMessage = 'Failed to load places near you.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  List<Place> _mergePlaces(List<Place> firestore, List<Place> discovered) {
    final merged = <String, Place>{};
    for (final place in [...firestore, ...discovered]) {
      merged[place.id] = place;
    }
    return merged.values.toList();
  }

  void _attachDistances() {
    if (_userPosition == null) return;
    _allPlaces = _allPlaces
        .map(
          (place) => place.copyWith(
            distanceKm: _locationService.distanceInKm(
              fromLatitude: _userPosition!.latitude,
              fromLongitude: _userPosition!.longitude,
              toLatitude: place.latitude,
              toLongitude: place.longitude,
            ),
          ),
        )
        .toList();
  }

  List<Place> _filterNearby(List<Place> places) {
    if (_userPosition == null) {
      return places.take(20).toList();
    }
    return places
        .where((p) => (p.distanceKm ?? double.infinity) <= nearbyRadiusKm)
        .toList()
      ..sort((a, b) => (a.distanceKm ?? 0).compareTo(b.distanceKm ?? 0));
  }

  List<Place> placesWithinRadius(double radiusKm) {
    if (_userPosition == null) return List<Place>.from(_allPlaces);
    return _allPlaces
        .where((p) => (p.distanceKm ?? double.infinity) <= radiusKm)
        .toList();
  }
}
