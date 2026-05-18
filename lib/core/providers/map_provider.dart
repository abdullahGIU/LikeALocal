import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/place.dart';
import 'place_provider.dart';

enum FocusUserResult {
  focused,
  mapLoading,
  locationUnavailable,
}

class MapProvider extends ChangeNotifier {
  PlaceProvider? _places;
  static const double _minZoom = 3;
  static const double _maxZoom = 20;
  static const double _zoomStep = 1;

  final MapController mapController = MapController();

  List<Place> _visiblePlaces = [];
  Place? _selectedPlace;
  double _radiusKm = PlaceProvider.nearbyRadiusKm;
  bool _nearMeFilterEnabled = true;
  bool _mapReady = false;
  String? _categoryFilter;
  bool _showPinnedOnly = false;
  bool _requestingUserFocusRefresh = false;
  bool _pendingFocusUser = false;

  List<Place> get visiblePlaces => _visiblePlaces;
  List<Place> get pinnedPlaces => _places?.pinnedPlaces ?? const [];
  Place? get selectedPlace => _selectedPlace;
  bool get nearMeFilterEnabled => _nearMeFilterEnabled;
  double get radiusKm => _radiusKm;
  String? get categoryFilter => _categoryFilter;
  bool get showPinnedOnly => _showPinnedOnly;
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
    if (pinnedPlaces.isNotEmpty) {
      final first = pinnedPlaces.first;
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
    if (_mapReady && !(_places?.isLoading ?? false)) {
      if (_nearMeFilterEnabled && !_showPinnedOnly) {
        final pos = _places?.userPosition;
        if (pos != null) {
          mapController.move(LatLng(pos.latitude, pos.longitude), 15);
        } else {
          moveToInitial();
        }
      } else {
        moveToInitial();
      }
    }
    notifyListeners();
  }

  void setCategoryFilter(String? category) {
    _categoryFilter = category;
    _showPinnedOnly = false;
    _applyRadiusFilter();
    notifyListeners();
  }

  void setShowPinnedOnly(bool value) {
    _showPinnedOnly = value;
    if (value) _categoryFilter = null;
    _applyRadiusFilter();
    notifyListeners();
    if (value && pinnedPlaces.isNotEmpty) {
      focusOnPlace(pinnedPlaces.first);
    }
  }

  void focusOnPlace(Place place) {
    selectPlace(place);
    if (!_mapReady) return;
    mapController.move(
      LatLng(place.latitude, place.longitude),
      16,
    );
  }

  void _syncFromPlaces() {
    _applyRadiusFilter();
  }

  void onMapReady() {
    _mapReady = true;
    if (_pendingFocusUser) {
      _pendingFocusUser = false;
      focusOnUser();
      return;
    }
    if (_showPinnedOnly && pinnedPlaces.isNotEmpty) {
      focusOnPlace(pinnedPlaces.first);
    } else if (_nearMeFilterEnabled) {
      focusOnUser();
    } else {
      moveToInitial();
    }
  }

  void moveToInitial() {
    if (!_mapReady) return;
    mapController.move(initialCenter, initialZoom);
  }

  void zoomIn() {
    _zoomBy(_zoomStep);
  }

  void zoomOut() {
    _zoomBy(-_zoomStep);
  }

  void _zoomBy(double delta) {
    if (!_mapReady) return;
    final camera = mapController.camera;
    final nextZoom = (camera.zoom + delta).clamp(_minZoom, _maxZoom).toDouble();
    if (nextZoom == camera.zoom) return;
    mapController.move(camera.center, nextZoom);
    notifyListeners();
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
    _showPinnedOnly = false;
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

  Future<FocusUserResult> focusOnUser() async {
    if (!_mapReady) {
      _pendingFocusUser = true;
      notifyListeners();
      if (!_requestingUserFocusRefresh) {
        _requestingUserFocusRefresh = true;
        try {
          await _places?.refresh();
        } finally {
          _requestingUserFocusRefresh = false;
        }
      }
      return FocusUserResult.mapLoading;
    }

    if (_requestingUserFocusRefresh) {
      return FocusUserResult.mapLoading;
    }

    var pos = _places?.userPosition;
    if (pos == null) {
      _requestingUserFocusRefresh = true;
      try {
        await _places?.refresh();
      } finally {
        _requestingUserFocusRefresh = false;
      }
      pos = _places?.userPosition;
    }

    if (pos != null) {
      mapController.move(LatLng(pos.latitude, pos.longitude), 15);
      notifyListeners();
      return FocusUserResult.focused;
    }

    notifyListeners();
    return FocusUserResult.locationUnavailable;
  }

  void _applyRadiusFilter() {
    if (_showPinnedOnly) {
      _visiblePlaces = List<Place>.from(pinnedPlaces);
      return;
    }

    var all = _places?.allPlaces ?? [];

    if (_categoryFilter != null) {
      all = all.where((place) => place.category == _categoryFilter).toList();
    }

    if (_nearMeFilterEnabled && _places?.userPosition != null) {
      all = all
          .where((place) => (place.distanceKm ?? double.infinity) <= _radiusKm)
          .toList();
    }

    _visiblePlaces = all;
  }

  @override
  void dispose() {
    _places?.removeListener(_onPlacesChanged);
    mapController.dispose();
    super.dispose();
  }
}
