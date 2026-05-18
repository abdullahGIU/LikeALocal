import 'package:flutter/material.dart';

import '../../core/models/place.dart';
import '../../core/services/place_service.dart';
import 'add_place_screen.dart';
import 'edit_place_screen.dart';

class MyPlacesScreen extends StatefulWidget {
  const MyPlacesScreen({super.key});

  @override
  State<MyPlacesScreen> createState() => _MyPlacesScreenState();
}

class _MyPlacesScreenState extends State<MyPlacesScreen> {
  final PlaceService _placeService = PlaceService();
  late Future<List<Place>> _placesFuture;

  @override
  void initState() {
    super.initState();
    _placesFuture = _placeService.getMyPlaces();
  }

  void _refresh() {
    setState(() {
      _placesFuture = _placeService.getMyPlaces();
    });
  }

  Future<void> _openAdd() async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const AddPlaceScreen()),
    );
    if (changed == true) _refresh();
  }

  Future<void> _openEdit(Place place) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => EditPlaceScreen(place: place)),
    );
    if (changed == true) _refresh();
  }

  Future<void> _deletePlace(Place place) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete place?'),
        content: Text('Delete ${place.name}? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (shouldDelete != true) return;

    try {
      await _placeService.deletePlace(place);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Place deleted successfully.')),
      );
      _refresh();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Places')),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAdd,
        child: const Icon(Icons.add),
      ),
      body: FutureBuilder<List<Place>>(
        future: _placesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return _StateMessage(
              icon: Icons.error_outline,
              message:
                  snapshot.error.toString().replaceFirst('Exception: ', ''),
              actionLabel: 'Retry',
              onAction: _refresh,
            );
          }

          final places = snapshot.data ?? [];
          if (places.isEmpty) {
            return _StateMessage(
              icon: Icons.place_outlined,
              message: 'No places added yet.',
              actionLabel: 'Add Place',
              onAction: _openAdd,
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: places.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final place = places[index];
              return _MyPlaceCard(
                place: place,
                onEdit: () => _openEdit(place),
                onDelete: () => _deletePlace(place),
              );
            },
          );
        },
      ),
    );
  }
}

class _MyPlaceCard extends StatelessWidget {
  final Place place;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _MyPlaceCard({
    required this.place,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final firstImageUrl =
        place.imageUrls.isNotEmpty ? place.imageUrls.first : null;

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 88,
                height: 88,
                color: Colors.black12,
                child: firstImageUrl == null
                    ? const Icon(Icons.place_outlined)
                    : Image.network(firstImageUrl, fit: BoxFit.cover),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    place.name,
                    style: Theme.of(context).textTheme.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    place.category,
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    place.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      TextButton.icon(
                        onPressed: onEdit,
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        label: const Text('Edit'),
                      ),
                      TextButton.icon(
                        onPressed: onDelete,
                        icon: const Icon(Icons.delete_outline, size: 18),
                        label: const Text('Delete'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StateMessage extends StatelessWidget {
  final IconData icon;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  const _StateMessage({
    required this.icon,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 42),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: onAction,
              child: Text(actionLabel),
            ),
          ],
        ),
      ),
    );
  }
}
