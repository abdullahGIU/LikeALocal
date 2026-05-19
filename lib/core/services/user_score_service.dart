import 'package:cloud_firestore/cloud_firestore.dart';

class UserScoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> updateUserScore(String userId) async {
    final userRef = _firestore.collection('users').doc(userId);
    final userDoc = await userRef.get();

    if (!userDoc.exists) return;

    final data = userDoc.data()!;

    final postsCount = data['postsCount'] ?? 0;
    final reviewsCount = data['reviewsCount'] ?? 0;
    final helpfulCount = data['helpfulCount'] ?? 0;
    final chatCount = data['chatCount'] ?? 0;
    final rating = data['rating'] ?? 0;

    final score = (postsCount * 5) +
        (reviewsCount * 2) +
        (helpfulCount * 3) +
        (chatCount * 1) +
        (rating * 10);

    final isPremium = data['isPremium'] ?? false;
    final isSuper = isPremium || score >= 100;

    await userRef.update({
      'score': score,
      'isSuperUser': isSuper,
      'pinLimit': isSuper ? 999 : 5,
    });
  }
}
