import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import '../models/place.dart';
import '../models/review.dart';

class FirestoreService {
  final FirebaseFirestore _firestore;

  FirestoreService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _placesCollection =>
      _firestore.collection('places');

  Future<void> upsertPlaces(List<Place> places) async {
    if (places.isEmpty) return;

    final batch = _firestore.batch();
    for (final place in places) {
      batch.set(
        _placesCollection.doc(place.id),
        {
          'name': place.name,
          'description': place.description,
          'address': place.address,
          'category': place.category,
          'latitude': place.latitude,
          'longitude': place.longitude,
          'location': GeoPoint(place.latitude, place.longitude),
          'imageUrls': place.imageUrls,
          'tips': place.tips,
          'rating': place.rating,
          'reviewCount': place.reviewCount,
          'isOpen': place.isOpen,
          'budget': place.budget,
          'atmosphere': place.atmosphere,
          'source': 'mapbox',
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    }
    await batch.commit();
  }

  Future<List<Place>> fetchPlaces({String? category}) async {
    Query<Map<String, dynamic>> query = _placesCollection;
    if (category != null && category != 'All') {
      query = query.where('category', isEqualTo: category);
    }
    final snapshot = await query.get();
    final places = snapshot.docs.map(Place.fromDoc).toList();
    places.sort((a, b) => b.rating.compareTo(a.rating));
    return places;
  }

  Future<List<Place>> fetchNearbyPlaces({
    required double userLatitude,
    required double userLongitude,
    double radiusKm = 20,
    String? category,
  }) async {
    final places = await fetchPlaces(category: category);
    return places
        .map(
          (place) => place.copyWith(
            distanceKm: Geolocator.distanceBetween(
                  userLatitude,
                  userLongitude,
                  place.latitude,
                  place.longitude,
                ) /
                1000,
          ),
        )
        .where((place) => (place.distanceKm ?? double.infinity) <= radiusKm)
        .toList()
      ..sort((a, b) => (a.distanceKm ?? 0).compareTo(b.distanceKm ?? 0));
  }

  Future<Place?> getPlaceById(String placeId) async {
    final doc = await _placesCollection.doc(placeId).get();
    if (!doc.exists) return null;
    return Place.fromDoc(doc);
  }

  Stream<List<Review>> streamPlaceReviews(String placeId) {
    return _placesCollection
        .doc(placeId)
        .collection('reviews')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Review.fromDoc(doc, placeId: placeId))
              .toList(),
        );
  }

  Future<bool> isPlacePinned({
    required String userId,
    required String placeId,
  }) async {
    final pinDoc = await _firestore
        .collection('users')
        .doc(userId)
        .collection('pins')
        .doc(placeId)
        .get();
    return pinDoc.exists;
  }

  Future<void> togglePinPlace({
    required String userId,
    required Place place,
  }) async {
    final pinRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('pins')
        .doc(place.id);

    final pinSnapshot = await pinRef.get();
    if (pinSnapshot.exists) {
      await pinRef.delete();
      return;
    }

    await pinRef.set({
      'placeId': place.id,
      'name': place.name,
      'category': place.category,
      'imageUrl': place.imageUrls.isNotEmpty ? place.imageUrls.first : null,
      'rating': place.rating,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
