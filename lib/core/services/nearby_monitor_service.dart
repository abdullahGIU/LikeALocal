import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import '../models/place.dart';
import 'location_service.dart';
import 'notification_service.dart';

/// Demo geofencing: compares user location to pinned places periodically.
class NearbyMonitorService {
  NearbyMonitorService({
    LocationService? locationService,
    NotificationService? notificationService,
  })  : _locationService = locationService ?? LocationService(),
        _notifications = notificationService ?? NotificationService.instance;

  final LocationService _locationService;
  final NotificationService _notifications;

  static const double _radiusMeters = 500;

  Timer? _timer;
  List<Place> _pinnedPlaces = [];
  final Set<String> _notifiedPlaceIds = {};

  void updatePinnedPlaces(List<Place> places) {
    _pinnedPlaces = places;
  }

  void start() {
    _timer ??= Timer.periodic(
      const Duration(seconds: 45),
      (_) => _checkNearby(),
    );
    _checkNearby();
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    _notifiedPlaceIds.clear();
  }

  Future<void> _checkNearby() async {
    if (_pinnedPlaces.isEmpty) return;

    final position = await _locationService.getCurrentPosition();
    if (position == null) return;

    for (final place in _pinnedPlaces) {
      if (_notifiedPlaceIds.contains(place.id)) continue;

      final meters = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        place.latitude,
        place.longitude,
      );

      if (meters <= _radiusMeters) {
        _notifiedPlaceIds.add(place.id);
        await _notifications.notifyNearbyPlace(place.name);
        if (kDebugMode) {
          debugPrint('Nearby alert: ${place.name} (${meters.toStringAsFixed(0)}m)');
        }
      }
    }
  }

  /// Manual demo trigger from settings (uses closest pinned place or generic).
  Future<void> triggerDemoNotification(List<Place> pinned) async {
    if (pinned.isEmpty) {
      await _notifications.showLocalNotification(
        title: 'Nearby demo',
        body: 'Pin a place first, then walk within 500m to get an alert.',
        type: 'nearby',
      );
      return;
    }

    final place = pinned.first;
    await _notifications.notifyNearbyPlace(place.name);
  }
}
