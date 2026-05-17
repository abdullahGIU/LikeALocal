import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/api_keys.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/mapbox_config.dart';
import '../../core/providers/main_navigation_provider.dart';
import '../../core/providers/map_provider.dart';
import '../../core/models/place.dart';
import '../places/place_details_screen.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  static const int _mapTabIndex = 2;

  MainNavigationProvider? _navigation;
  bool _mapSurfaceBuilt = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final nav = context.read<MainNavigationProvider>();
    if (_navigation != nav) {
      _navigation?.removeListener(_onNavigationChanged);
      _navigation = nav;
      _navigation!.addListener(_onNavigationChanged);
    }
    _ensureMapSurface();
  }

  @override
  void dispose() {
    _navigation?.removeListener(_onNavigationChanged);
    super.dispose();
  }

  void _onNavigationChanged() {
    if (!mounted) return;
    _ensureMapSurface();

    final nav = _navigation;
    if (nav == null) return;
    if (nav.currentIndex == _mapTabIndex && nav.mapNearMeOnOpen) {
      if (nav.consumeMapNearMeFlag()) {
        context.read<MapProvider>().enableNearMeFilter();
      }
    }
  }

  void _ensureMapSurface() {
    final nav = _navigation;
    if (nav == null || !mounted) return;
    if (nav.currentIndex == _mapTabIndex && !_mapSurfaceBuilt) {
      setState(() => _mapSurfaceBuilt = true);
    }
  }

  Future<void> _openDirections(Place place) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=${place.latitude},${place.longitude}',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final map = context.watch<MapProvider>();
    final nav = context.watch<MainNavigationProvider>();
    final isMapTabActive = nav.currentIndex == _mapTabIndex;

    if (isMapTabActive && !_mapSurfaceBuilt) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _mapSurfaceBuilt = true);
      });
    }

    return Scaffold(
      body: Column(
        children: [
          Material(
            elevation: 6,
            color: Colors.white,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => context
                            .read<MainNavigationProvider>()
                            .openSearch(),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F3F5),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.search, color: Colors.grey.shade600),
                              const SizedBox(width: 8),
                              Text(
                                'Search cafés, restaurants...',
                                style: TextStyle(color: Colors.grey.shade700),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    _MapIconButton(
                      icon: Icons.my_location,
                      onPressed: map.focusOnUser,
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (_mapSurfaceBuilt && isMapTabActive && ApiKeys.hasMapboxToken)
                  FlutterMap(
                    mapController: map.mapController,
                    options: MapOptions(
                      initialCenter: map.initialCenter,
                      initialZoom: map.initialZoom,
                      minZoom: 3,
                      maxZoom: 20,
                      interactionOptions: const InteractionOptions(
                        flags: InteractiveFlag.all,
                      ),
                      onTap: (_, __) => map.clearSelectedPlace(),
                      onMapReady: map.onMapReady,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: MapboxConfig.tileUrlTemplate(
                          ApiKeys.mapboxAccessToken,
                        ),
                        retinaMode: RetinaMode.isHighDensity(context),
                      ),
                      RichAttributionWidget(
                        alignment: AttributionAlignment.bottomLeft,
                        attributions: [
                          TextSourceAttribution(
                            'Mapbox',
                            onTap: () => launchUrl(
                              Uri.parse('https://www.mapbox.com/about/maps/'),
                              mode: LaunchMode.externalApplication,
                            ),
                          ),
                          TextSourceAttribution(
                            'OpenStreetMap',
                            onTap: () => launchUrl(
                              Uri.parse(
                                'https://www.openstreetmap.org/copyright',
                              ),
                              mode: LaunchMode.externalApplication,
                            ),
                          ),
                        ],
                      ),
                      if (map.userLatLng != null)
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: map.userLatLng!,
                              width: 48,
                              height: 48,
                              child: const Icon(
                                Icons.my_location,
                                color: Colors.blue,
                                size: 36,
                              ),
                            ),
                          ],
                        ),
                      MarkerLayer(
                        markers: [
                          for (final place in map.visiblePlaces)
                            Marker(
                              point:
                                  LatLng(place.latitude, place.longitude),
                              width: 48,
                              height: 48,
                              child: GestureDetector(
                                onTap: () => map.selectPlace(place),
                                child: Icon(
                                  Icons.location_on,
                                  size: 44,
                                  color: map.selectedPlace?.id == place.id
                                      ? AppColors.tertiaryBlue
                                      : AppColors.primaryGreen,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  )
                else if (!ApiKeys.hasMapboxToken)
                  const Center(child: Text('Mapbox token missing.'))
                else
                  ColoredBox(
                    color: Colors.grey.shade200,
                    child: Center(
                      child: Icon(
                        Icons.map_outlined,
                        size: 64,
                        color: Colors.grey.shade400,
                      ),
                    ),
                  ),
                if (map.isLoading)
                  const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primaryGreen,
                    ),
                  ),
                if (map.errorMessage != null)
                  Positioned(
                    left: 16,
                    right: 16,
                    top: 12,
                    child: Material(
                      elevation: 4,
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.red.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(
                          map.errorMessage!,
                          style: TextStyle(color: Colors.red.shade900),
                        ),
                      ),
                    ),
                  ),
                if (map.selectedPlace != null)
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: 24,
                    child: _PlaceMapCard(
                      place: map.selectedPlace!,
                      onClose: map.clearSelectedPlace,
                      onViewDetails: () {
                        final place = map.selectedPlace!;
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => PlaceDetailsScreen(place: place),
                          ),
                        );
                      },
                      onDirections: () => _openDirections(map.selectedPlace!),
                    ),
                  ),
                Positioned(
                  right: 16,
                  bottom: map.selectedPlace != null ? 180 : 24,
                  child: Column(
                    children: [
                      FloatingActionButton(
                        heroTag: 'near_me',
                        backgroundColor: AppColors.primaryGreen,
                        onPressed: () =>
                            map.enableNearMeFilter(radiusKm: map.radiusKm),
                        child: const Icon(Icons.near_me, color: Colors.white),
                      ),
                      if (map.nearMeFilterEnabled) ...[
                        const SizedBox(height: 10),
                        FloatingActionButton.small(
                          heroTag: 'clear_near_me',
                          backgroundColor: Colors.white,
                          onPressed: map.disableNearMeFilter,
                          child: const Icon(
                            Icons.close,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MapIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _MapIconButton({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.primaryGreen,
      shape: const CircleBorder(),
      elevation: 3,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Icon(icon, color: Colors.white),
        ),
      ),
    );
  }
}

class _PlaceMapCard extends StatelessWidget {
  final Place place;
  final VoidCallback onClose;
  final VoidCallback onViewDetails;
  final VoidCallback onDirections;

  const _PlaceMapCard({
    required this.place,
    required this.onClose,
    required this.onViewDetails,
    required this.onDirections,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    place.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: onClose,
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            Row(
              children: [
                const Icon(Icons.star, color: Colors.amber, size: 20),
                const SizedBox(width: 4),
                Text(
                  place.rating.toStringAsFixed(1),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                if (place.distanceKm != null) ...[
                  const SizedBox(width: 12),
                  Text('${place.distanceKm!.toStringAsFixed(1)} km away'),
                ],
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onViewDetails,
                    child: const Text('View Details'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onDirections,
                    child: const Text('Directions'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
