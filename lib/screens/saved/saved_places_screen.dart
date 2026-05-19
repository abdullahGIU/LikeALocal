import 'package:flutter/material.dart';
import '../../core/models/place.dart';
import '../../core/services/firestore_service.dart';
import '../../core/services/auth_service.dart';
import '../places/place_details_screen.dart';

class SavedPlacesScreen extends StatefulWidget {
  const SavedPlacesScreen({super.key});

  @override
  State<SavedPlacesScreen> createState() => _SavedPlacesScreenState();
}

class _SavedPlacesScreenState extends State<SavedPlacesScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();
  List<Place> _savedPlaces = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSavedPlaces();
  }

  Future<void> _loadSavedPlaces() async {
    final user = _authService.currentFirebaseUser;
    if (user != null) {
      try {
        final places = await _firestoreService.getSavedPlaces(user.uid);
        setState(() {
          _savedPlaces = places;
          _isLoading = false;
        });
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error loading saved places: $e')),
          );
        }
      }
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Saved Places')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _savedPlaces.isEmpty
              ? const Center(child: Text('No saved places yet.'))
              : ListView.builder(
                  itemCount: _savedPlaces.length,
                  itemBuilder: (context, index) {
                    final place = _savedPlaces[index];
                    return ListTile(
                      leading: place.imageUrls.isNotEmpty
                          ? Image.network(
                              place.imageUrls.first,
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                            )
                          : const Icon(Icons.place, size: 50),
                      title: Text(place.name),
                      subtitle: Text(place.address),
                      trailing: Text('⭐ ${place.rating.toStringAsFixed(1)}'),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PlaceDetailsScreen(place: place),
                          ),
                        ).then((_) => _loadSavedPlaces()); // Reload after returning
                      },
                    );
                  },
                ),
    );
  }
}
