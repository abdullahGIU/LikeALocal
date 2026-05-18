import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/providers/auth_provider.dart';
import '../core/providers/notification_provider.dart';
import '../core/providers/place_provider.dart';
import '../core/providers/user_provider.dart';
import '../core/services/nearby_monitor_service.dart';
import '../core/services/notification_service.dart';

/// Initializes notifications, user prefs, and nearby monitoring after login.
class AppBootstrap extends StatefulWidget {
  final Widget child;

  const AppBootstrap({super.key, required this.child});

  @override
  State<AppBootstrap> createState() => _AppBootstrapState();
}

class _AppBootstrapState extends State<AppBootstrap> {
  final NearbyMonitorService _nearbyMonitor = NearbyMonitorService();
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  Future<void> _bootstrap() async {
    if (_initialized) return;
    _initialized = true;

    await NotificationService.instance.initialize();
    if (!mounted) return;

    final notificationProvider = context.read<NotificationProvider>();
    final authProvider = context.read<AuthProvider>();
    final userProvider = context.read<UserProvider>();
    final places = context.read<PlaceProvider>();

    await notificationProvider.load();
    await authProvider.checkCurrentUser();

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      await userProvider.loadForUser(uid);
    }

    if (!mounted) return;
    places.addListener(_syncNearbyMonitor);
    _syncNearbyMonitor();
    _nearbyMonitor.start();
  }

  void _syncNearbyMonitor() {
    if (!mounted) return;
    _nearbyMonitor.updatePinnedPlaces(
      context.read<PlaceProvider>().pinnedPlaces,
    );
  }

  @override
  void dispose() {
    context.read<PlaceProvider>().removeListener(_syncNearbyMonitor);
    _nearbyMonitor.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
