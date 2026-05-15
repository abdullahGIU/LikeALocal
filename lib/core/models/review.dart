class Review {
  final String id;
  final String userId;
  final String placeId;
  final String content;
  final double rating;
  final DateTime createdAt;

  Review({
    required this.id,
    required this.userId,
    required this.placeId,
    required this.content,
    required this.rating,
    required this.createdAt,
  });
}
