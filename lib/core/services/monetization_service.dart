import 'package:cloud_firestore/cloud_firestore.dart';

class MonetizationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<bool> canPinPlace(String userId) async {
    final userDoc = await _firestore.collection('users').doc(userId).get();

    if (!userDoc.exists) return false;

    final data = userDoc.data()!;
    final isPremium = data['isPremium'] ?? false;
    final pinCount = data['pinCount'] ?? 0;
    final pinLimit = data['pinLimit'] ?? 5;

    if (isPremium) return true;

    return pinCount < pinLimit;
  }

  Future<void> increasePinCount(String userId) async {
    await _firestore.collection('users').doc(userId).update({
      'pinCount': FieldValue.increment(1),
    });
  }
}
