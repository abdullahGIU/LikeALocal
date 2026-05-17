import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/place.dart';
import 'place_provider.dart';

class MapProvider extends ChangeNotifier {
  PlaceProvider? _places;

  final MapController mapController = MapController();

  List<Place> _visiblePlaces = [];
  Place? _selectedPlace;
  double _radiusKm = PlaceProvider.nearbyRadiusKm;
  bool _nearMeFilterEnabled = true;
  bool _mapReady = false;

  List<Place> get visiblePlaces => _visiblePlaces;
  Place? get selectedPlace => _selectedPlace;
  bool get nearMeFilterEnabled => _nearMeFilterEnabled;
  double get radiusKm => _radiusKm;
  bool get isLoading => _places?.isLoading ?? false;
  String? get errorMessage => _places?.errorMessage;

  LatLng? get userLatLng {
    final pos = _places?.userPosition;
    if (pos == null) return null;
    return LatLng(pos.latitude, pos.longitude);
  }

  LatLng get initialCenter {
    final pos = _places?.userPosition;
    if (pos != null) {
      return LatLng(pos.latitude, pos.longitude);
    }
    if (_visiblePlaces.isNotEmpty) {
      final first = _visiblePlaces.first;
      return LatLng(first.latitude, first.longitude);
    }
    return const LatLng(30.0444, 31.2357);
  }

  double get initialZoom {
    if (_places?.userPosition != null) return 15;
    if (_visiblePlaces.isNotEmpty) return 13;
    return 11;
  }

  void bind(PlaceProvider places) {
    if (_places == places) return;
    _places?.removeListener(_onPlacesChanged);
    _places = places;
    _places!.addListener(_onPlacesChanged);
    _syncFromPlaces();
  }

  void _onPlacesChanged() {
    _syncFromPlaces();
    if (_mapReady) {
      if (_nearMeFilterEnabled) {
        focusOnUser();
      } else {
        moveToInitial();
      }
    }
    notifyListeners();
  }

  void _syncFromPlaces() {
    _applyRadiusFilter();
  }

  Future<void> initialize() async {
    await _places?.refresh();
    _applyRadiusFilter();
    notifyListeners();
  }

  void onMapReady() {
    _mapReady = true;
    focusOnUser();
  }

  void moveToInitial() {
    if (!_mapReady) return;
    mapController.move(initialCenter, initialZoom);
  }

  void selectPlace(Place place) {
    _selectedPlace = place;
    notifyListeners();
    if (!_mapReady) return;
    mapController.move(
      LatLng(place.latitude, place.longitude),
      mapController.camera.zoom < 15 ? 15 : mapController.camera.zoom,
    );
  }

  void clearSelectedPlace() {
    _selectedPlace = null;
    notifyListeners();
  }

  void enableNearMeFilter({double? radiusKm}) {
    _nearMeFilterEnabled = true;
    if (radiusKm != null) _radiusKm = radiusKm;
    _applyRadiusFilter();
    notifyListeners();
    focusOnUser();
  }

  void disableNearMeFilter() {
    _nearMeFilterEnabled = false;
    _applyRadiusFilter();
    notifyListeners();
  }

  Future<void> focusOnUser() async {
    if (!_mapReady) return;

    final pos = _places?.userPosition;
    if (pos != null) {
      mapController.move(LatLng(pos.latitude, pos.longitude), 15);
      notifyListeners();
      return;
    }

    await _places?.refresh();
    final updated = _places?.userPosition;
    if (updated != null && _mapReady) {
      mapController.move(LatLng(updated.latitude, updated.longitude), 15);
    }
    notifyListeners();
  }

  void _applyRadiusFilter() {
    final all = _places?.allPlaces ?? [];
    if (_nearMeFilterEnabled && _places?.userPosition != null) {
      _visiblePlaces = all
          .where((place) => (place.distanceKm ?? double.infinity) <= _radiusKm)
          .toList();
    } else {
      _visiblePlaces = List<Place>.from(all);
    }
  }

  @override
  void dispose() {
    _places?.removeListener(_onPlacesChanged);
    mapController.dispose();
    super.dispose();
  }
}
