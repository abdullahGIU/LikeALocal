import 'package:flutter/material.dart';

import '../../core/models/place.dart';
import '../../core/services/place_service.dart';
import '../../widgets/place_form.dart';

class EditPlaceScreen extends StatefulWidget {
  final Place place;

  const EditPlaceScreen({
    super.key,
    required this.place,
  });

  @override
  State<EditPlaceScreen> createState() => _EditPlaceScreenState();
}

class _EditPlaceScreenState extends State<EditPlaceScreen> {
  final PlaceService _placeService = PlaceService();
  bool _isLoading = false;

  bool get _isOwner => _placeService.currentUserId == widget.place.ownerId;

  Future<void> _submit(PlaceFormResult result) async {
    if (!_isOwner) {
      _showMessage('You can only edit places you created.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final uploadedUrls = await _placeService.uploadMediaToStorage(
        placeId: widget.place.id,
        mediaFiles: result.newMedia.map((item) => item.file).toList(),
      );

      final removedUrls = widget.place.mediaUrls
          .where((url) => !result.existingMediaUrls.contains(url))
          .toList();

      final updatedPlace = Place(
        id: widget.place.id,
        ownerId: widget.place.ownerId,
        ownerName: widget.place.ownerName,
        name: result.name,
        description: result.description,
        category: result.category,
        address: result.address,
        latitude: result.latitude ?? 0.0,
        longitude: result.longitude ?? 0.0,
        localTips: result.localTips,
        recommendedDishes: result.recommendedDishes,
        mediaUrls: [
          ...result.existingMediaUrls,
          ...uploadedUrls,
        ],
        mediaTypes: [
          ...result.existingMediaTypes,
          ...result.newMedia.map((item) => item.type),
        ],
        rating: widget.place.rating,
        createdAt: widget.place.createdAt,
      );

      await _placeService.updatePlace(updatedPlace);

      for (final url in removedUrls) {
        try {
          await _placeService.deleteMediaFromStorage(url);
        } catch (_) {
          // A failed media cleanup should not fail a successful place update.
        }
      }

      if (!mounted) return;
      _showMessage('Place updated successfully.');
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      _showMessage(_cleanError(error));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _confirmDelete() async {
    if (!_isOwner) {
      _showMessage('You can only delete places you created.');
      return;
    }

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete place?'),
        content: const Text('This cannot be undone.'),
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

    setState(() => _isLoading = true);
    try {
      await _placeService.deletePlace(widget.place);
      if (!mounted) return;
      _showMessage('Place deleted successfully.');
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      _showMessage(_cleanError(error));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  String _cleanError(Object error) {
    return error.toString().replaceFirst('Exception: ', '');
  }

  @override
  Widget build(BuildContext context) {
    if (!_isOwner) {
      return Scaffold(
        appBar: AppBar(title: const Text('Edit Place')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text('You can only edit places you created.'),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Place'),
        actions: [
          IconButton(
            onPressed: _isLoading ? null : _confirmDelete,
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Delete place',
          ),
        ],
      ),
      body: PlaceForm(
        initialPlace: widget.place,
        isLoading: _isLoading,
        submitLabel: 'Save Changes',
        onSubmit: _submit,
      ),
    );
  }
}
