import 'package:flutter/material.dart';

import '../../core/models/place.dart';
import '../../core/services/place_service.dart';
import '../../widgets/place_form.dart';

class AddPlaceScreen extends StatefulWidget {
  const AddPlaceScreen({super.key});

  @override
  State<AddPlaceScreen> createState() => _AddPlaceScreenState();
}

class _AddPlaceScreenState extends State<AddPlaceScreen> {
  final PlaceService _placeService = PlaceService();
  bool _isLoading = false;

  Future<void> _submit(PlaceFormResult result) async {
    setState(() => _isLoading = true);

    try {
      final placeId = _placeService.createPlaceId();
      final mediaUrls = await _placeService.uploadMediaToStorage(
        placeId: placeId,
        mediaFiles: result.newMedia.map((item) => item.file).toList(),
      );

      final place = Place(
        id: placeId,
        ownerId: _placeService.currentUserId,
        ownerName: _placeService.currentOwnerName,
        name: result.name,
        description: result.description,
        category: result.category,
        address: result.address,
        latitude: result.latitude,
        longitude: result.longitude,
        localTips: result.localTips,
        recommendedDishes: result.recommendedDishes,
        mediaUrls: mediaUrls,
        mediaTypes: result.newMedia.map((item) => item.type).toList(),
      );

      await _placeService.createPlace(place);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Place added successfully.')),
      );
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_cleanError(error))),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _cleanError(Object error) {
    return error.toString().replaceFirst('Exception: ', '');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Place')),
      body: PlaceForm(
        isLoading: _isLoading,
        submitLabel: 'Add Place',
        onSubmit: _submit,
      ),
    );
  }
}
