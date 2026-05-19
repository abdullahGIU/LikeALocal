import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

import '../models/place.dart';
import 'user_score_service.dart';

class PlaceService {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  PlaceService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance;

  CollectionReference<Map<String, dynamic>> get _places =>
      _firestore.collection('places');

  User get _currentUser {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('You must be logged in to manage places.');
    }
    return user;
  }

  String createPlaceId() => _places.doc().id;

  String get currentUserId => _currentUser.uid;

  String get currentOwnerName {
    final user = _currentUser;
    final displayName = user.displayName?.trim();
    if (displayName != null && displayName.isNotEmpty) return displayName;
    return user.email ?? 'Local user';
  }

  Future<Place> createPlace(Place place) async {
    final user = _currentUser;
    if (place.ownerId != user.uid) {
      throw Exception('You can only create places for your own account.');
    }

    final now = DateTime.now();
    final placeToSave = place.copyWith(
      id: place.id.isEmpty ? createPlaceId() : place.id,
      createdAt: place.createdAt ?? now,
      updatedAt: now,
    );

    await _places.doc(placeToSave.id).set(placeToSave.toMap());

    // Increment user's postsCount and update score
    final userRef = _firestore.collection('users').doc(user.uid);
    await _firestore.runTransaction((transaction) async {
      final userSnapshot = await transaction.get(userRef);
      if (userSnapshot.exists) {
        final currentPosts =
            (userSnapshot.data()?['postsCount'] as num?)?.toInt() ?? 0;
        transaction.update(userRef, {'postsCount': currentPosts + 1});
      }
    });
    await UserScoreService().updateUserScore(user.uid);

    return placeToSave;
  }

  Future<Place> updatePlace(Place place) async {
    final user = _currentUser;
    if (place.ownerId != user.uid) {
      throw Exception('You can only edit places you created.');
    }

    final placeToSave = place.copyWith(updatedAt: DateTime.now());
    await _places.doc(placeToSave.id).update(placeToSave.toMap());
    return placeToSave;
  }

  Future<void> deletePlace(Place place) async {
    final user = _currentUser;
    if (place.ownerId != user.uid) {
      throw Exception('You can only delete places you created.');
    }

    await _places.doc(place.id).delete();

    // Decrement user's postsCount and update score
    final userRef = _firestore.collection('users').doc(user.uid);
    await _firestore.runTransaction((transaction) async {
      final userSnapshot = await transaction.get(userRef);
      if (userSnapshot.exists) {
        final currentPosts =
            (userSnapshot.data()?['postsCount'] as num?)?.toInt() ?? 0;
        transaction.update(userRef, {
          'postsCount': currentPosts > 0 ? currentPosts - 1 : 0,
        });
      }
    });
    await UserScoreService().updateUserScore(user.uid);

    for (final url in place.mediaUrls) {
      try {
        await deleteMediaFromStorage(url);
      } catch (_) {
        // Storage cleanup should not block deleting the Firestore document.
      }
    }
  }

  Future<List<Place>> getMyPlaces() async {
    final user = _currentUser;
    final snapshot = await _places.where('ownerId', isEqualTo: user.uid).get();

    final places = snapshot.docs.map(Place.fromFirestore).toList()
      ..sort((a, b) {
        final aDate = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bDate = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bDate.compareTo(aDate);
      });

    return places;
  }

  Future<List<String>> uploadMediaToStorage({
    required String placeId,
    required List<XFile> mediaFiles,
  }) async {
    final user = _currentUser;
    final urls = <String>[];

    for (final file in mediaFiles) {
      final fileName = _cleanFileName(file.name);
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final path = 'places/${user.uid}/$placeId/${timestamp}_$fileName';
      final ref = _storage.ref().child(path);

      await ref.putData(
        await file.readAsBytes(),
        SettableMetadata(contentType: file.mimeType),
      );
      urls.add(await ref.getDownloadURL());
    }

    return urls;
  }

  Future<void> deleteMediaFromStorage(String mediaUrl) async {
    await _storage.refFromURL(mediaUrl).delete();
  }

  String _cleanFileName(String value) {
    final cleaned = value.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
    return cleaned.isEmpty ? 'media' : cleaned;
  }
}
