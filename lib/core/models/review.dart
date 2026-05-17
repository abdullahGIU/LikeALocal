import 'package:cloud_firestore/cloud_firestore.dart';

class Review {
  final String id;
  final String userId;
  final String userName;
  final String placeId;
  final String comment;
  final int rating;
  final DateTime createdAt;

  const Review({
    required this.id,
    required this.userId,
    required this.userName,
    required this.placeId,
    required this.comment,
    required this.rating,
    required this.createdAt,
  });

  factory Review.fromDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> doc, {
    required String placeId,
  }) {
    final data = doc.data();
    return Review(
      id: doc.id,
      userId: (data['userId'] as String?) ?? '',
      userName: (data['userName'] as String?) ?? 'Anonymous',
      placeId: placeId,
      comment: (data['comment'] as String?) ?? '',
      rating: (data['rating'] as num?)?.toInt() ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
