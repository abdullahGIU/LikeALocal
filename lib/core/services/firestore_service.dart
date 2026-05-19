import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/place.dart';
import '../models/review.dart';
import '../models/app_user.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Reviews
  Future<List<Review>> getReviewsForPlace(String placeId) async {
    final snapshot = await _firestore
        .collection('reviews')
        .where('placeId', isEqualTo: placeId)
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => Review.fromMap(doc.data(), doc.id))
        .toList();
  }

  Future<void> addReview({
    required String placeId,
    required String userId,
    required double rating,
    required String content,
  }) async {
    final reviewRef = _firestore.collection('reviews').doc();
    final newReview = Review(
      id: reviewRef.id,
      userId: userId,
      placeId: placeId,
      content: content,
      rating: rating,
      createdAt: DateTime.now(),
    );

    await reviewRef.set(newReview.toMap());
    await _updatePlaceRating(placeId);
    await _incrementSuperUserScore(userId, 10); // 10 points for a review
  }

  Future<void> updateReview({
    required String reviewId,
    required String placeId,
    required double rating,
    required String content,
  }) async {
    await _firestore.collection('reviews').doc(reviewId).update({
      'rating': rating,
      'content': content,
    });
    await _updatePlaceRating(placeId);
  }

  Future<void> deleteReview({
    required String reviewId,
    required String placeId,
  }) async {
    await _firestore.collection('reviews').doc(reviewId).delete();
    await _updatePlaceRating(placeId);
  }

  Future<void> _updatePlaceRating(String placeId) async {
    final reviewsSnapshot = await _firestore
        .collection('reviews')
        .where('placeId', isEqualTo: placeId)
        .get();

    if (reviewsSnapshot.docs.isEmpty) {
      await _firestore.collection('places').doc(placeId).update({
        'rating': 0.0,
        'ratingCount': 0,
      });
      return;
    }

    double totalRating = 0;
    for (var doc in reviewsSnapshot.docs) {
      totalRating += (doc.data()['rating'] ?? 0.0).toDouble();
    }

    final averageRating = totalRating / reviewsSnapshot.docs.length;

    await _firestore.collection('places').doc(placeId).update({
      'rating': averageRating,
      'ratingCount': reviewsSnapshot.docs.length,
    });
  }

  // Pinning
  Future<void> pinPlace(String userId, String placeId) async {
    final userDoc = await _firestore.collection('users').doc(userId).get();
    if (!userDoc.exists) return;

    final userData = userDoc.data()!;
    List<String> savedPlaces = List<String>.from(userData['savedPlaces'] ?? []);
    bool isPremium = userData['isPremium'] ?? false;
    int pinLimit = userData['pinLimit'] ?? 5;

    if (!isPremium && savedPlaces.length >= pinLimit) {
      throw Exception('Pin limit reached for free user. Upgrade to premium to pin more places.');
    }

    if (!savedPlaces.contains(placeId)) {
      savedPlaces.add(placeId);
      await _firestore.collection('users').doc(userId).update({
        'savedPlaces': savedPlaces,
      });
      await _incrementSuperUserScore(userId, 2); // 2 points for pinning
    }
  }

  Future<void> unpinPlace(String userId, String placeId) async {
    final userDoc = await _firestore.collection('users').doc(userId).get();
    if (!userDoc.exists) return;

    final userData = userDoc.data()!;
    List<String> savedPlaces = List<String>.from(userData['savedPlaces'] ?? []);

    if (savedPlaces.contains(placeId)) {
      savedPlaces.remove(placeId);
      await _firestore.collection('users').doc(userId).update({
        'savedPlaces': savedPlaces,
      });
    }
  }

  Future<List<Place>> getSavedPlaces(String userId) async {
    final userDoc = await _firestore.collection('users').doc(userId).get();
    if (!userDoc.exists) return [];

    final userData = userDoc.data()!;
    List<String> savedPlaces = List<String>.from(userData['savedPlaces'] ?? []);

    if (savedPlaces.isEmpty) return [];

    // Firestore allows 'whereIn' queries up to 10 items. For more, need chunks.
    // Simplifying assuming < 10 for basic free limit.
    final chunkedPlaces = <Place>[];
    for (var i = 0; i < savedPlaces.length; i += 10) {
      final end = (i + 10 < savedPlaces.length) ? i + 10 : savedPlaces.length;
      final currentChunk = savedPlaces.sublist(i, end);
      
      final snapshot = await _firestore
          .collection('places')
          .where(FieldPath.documentId, whereIn: currentChunk)
          .get();
          
      chunkedPlaces.addAll(
          snapshot.docs.map((doc) => Place.fromMap(doc.data(), doc.id)).toList());
    }

    return chunkedPlaces;
  }

  // Super User
  Future<void> _incrementSuperUserScore(String userId, int points) async {
    final userDoc = await _firestore.collection('users').doc(userId).get();
    if (!userDoc.exists) return;

    final userData = userDoc.data()!;
    int currentScore = userData['superUserScore'] ?? 0;
    bool isSuperUser = userData['isSuperUser'] ?? false;
    
    int newScore = currentScore + points;
    bool newIsSuperUser = isSuperUser || newScore >= 100; // Become super user at 100 points

    await _firestore.collection('users').doc(userId).update({
      'superUserScore': newScore,
      'isSuperUser': newIsSuperUser,
    });
  }
}
