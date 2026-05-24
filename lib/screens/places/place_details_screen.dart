import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/providers/search_provider.dart';
import '../../core/providers/place_provider.dart';
import '../../core/models/place.dart';
import '../../core/models/review.dart';
import '../../core/services/firestore_service.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/chat_service.dart';
import '../profile/subscription_screen.dart';
import '../chat/chat_room_screen.dart';
import '../../widgets/place_image.dart';
import '../../widgets/network_video_player.dart';

class PlaceDetailsScreen extends StatefulWidget {
  final Place place;

  const PlaceDetailsScreen({super.key, required this.place});

  @override
  State<PlaceDetailsScreen> createState() => _PlaceDetailsScreenState();
}

class _PlaceDetailsScreenState extends State<PlaceDetailsScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  bool _isPinned = false;
  bool _pinLoading = false;

  @override
  void initState() {
    super.initState();
    _loadPinState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<SearchProvider>().recordPlaceView(widget.place);
    });
  }

  Future<void> _loadPinState() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;
    final pinned = await _firestoreService.isPlacePinned(
      userId: userId,
      placeId: widget.place.id,
    );
    if (mounted) setState(() => _isPinned = pinned);
  }

  Future<void> _togglePin() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to pin places.')),
      );
      return;
    }
    final wasPinned = _isPinned;
    setState(() => _pinLoading = true);
    try {
      await _firestoreService.togglePinPlace(
        userId: userId,
        place: widget.place,
      );
      if (mounted) {
        setState(() => _isPinned = !wasPinned);
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(
                wasPinned
                    ? 'Place unpinned successfully.'
                    : 'Place pinned successfully.',
              ),
            ),
          );
      }
    } on PinLimitReachedException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            action: SnackBarAction(
              label: 'Upgrade',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const SubscriptionScreen(),
                ),
              ),
            ),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not update pin.')),
        );
      }
    } finally {
      if (mounted) setState(() => _pinLoading = false);
    }
  }

  Future<void> _openChat() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to start a chat.')),
      );
      return;
    }

    final ownerId = widget.place.ownerId;

    if (ownerId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This place has no owner to chat with.')),
      );
      return;
    }

    if (currentUser.uid == ownerId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You cannot chat with yourself.')),
      );
      return;
    }

    final canChat = await AuthService().canOpenChatWithUser(ownerId);
    if (!mounted) return;

    if (!canChat) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('The owner is not accepting chats at this time.'),
        ),
      );
      return;
    }

    final chatId = await ChatService().createOrOpenChat(
      touristId: currentUser.uid,
      ownerId: ownerId,
      postId: widget.place.id,
    );
    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatRoomScreen(chatId: chatId, recipientId: ownerId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final place = widget.place;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 260,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: _PlacePhotoGallery(place: place),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    place.name,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    place.category,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber),
                      const SizedBox(width: 4),
                      Text(
                        '${place.rating.toStringAsFixed(1)} (${place.reviewCount} reviews)',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      if (place.distanceKm != null) ...[
                        const SizedBox(width: 16),
                        const Icon(
                          Icons.place_outlined,
                          size: 18,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text('${place.distanceKm!.toStringAsFixed(1)} km'),
                      ],
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _pinLoading ? null : _togglePin,
                          icon: Icon(
                            _isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                          ),
                          label: Text(_isPinned ? 'Unpin' : 'Pin Place'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primaryGreen,
                            side: const BorderSide(color: AppColors.primaryGreen),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                      if (place.ownerId.isNotEmpty &&
                          place.ownerId != FirebaseAuth.instance.currentUser?.uid) ...[
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _openChat,
                            icon: const Icon(Icons.chat_bubble_outline),
                            label: const Text('Chat Owner'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF7C4DFF),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 28),
                  const Text(
                    'About',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    place.description.isNotEmpty
                        ? place.description
                        : 'No description available.',
                    style: const TextStyle(
                      height: 1.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  if (place.tips.isNotEmpty) ...[
                    const SizedBox(height: 28),
                    const Text(
                      'Tips',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    ...place.tips.map(_tipCard),
                  ],
                  const SizedBox(height: 28),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Reviews',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      TextButton.icon(
                        onPressed: () => _showReviewDialog(),
                        icon: const Icon(Icons.add_comment_outlined, size: 18, color: AppColors.primaryGreen),
                        label: const Text(
                          'Write Review',
                          style: TextStyle(color: AppColors.primaryGreen, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  StreamBuilder<List<Review>>(
                    stream: _firestoreService.streamPlaceReviews(place.id),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Center(
                            child: CircularProgressIndicator(
                              color: AppColors.primaryGreen,
                            ),
                          ),
                        );
                      }
                      final reviews = snapshot.data ?? [];
                      if (reviews.isEmpty) {
                        return const Text(
                          'No reviews yet. Be the first to write one!',
                          style: TextStyle(color: AppColors.textSecondary),
                        );
                      }
                      return Column(
                        children: reviews.map(_reviewCard).toList(),
                      );
                    },
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tipCard(String tip) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFE082)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.lightbulb_outline, color: Color(0xFFF9A825)),
          const SizedBox(width: 10),
          Expanded(child: Text(tip)),
        ],
      ),
    );
  }

  Widget _reviewCard(Review review) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final isMyReview = review.userId == currentUserId;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.primaryGreen.withOpacity(0.15),
                  child: Text(
                    review.userName.isNotEmpty
                        ? review.userName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      color: AppColors.primaryGreen,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        review.userName,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Row(
                        children: List.generate(5, (index) {
                          return Icon(
                            index < review.rating
                                ? Icons.star
                                : Icons.star_border,
                            size: 16,
                            color: Colors.amber,
                          );
                        }),
                      ),
                    ],
                  ),
                ),
                if (isMyReview) ...[
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 20, color: Colors.blue),
                    onPressed: () => _showReviewDialog(existingReview: review),
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.all(4),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                    onPressed: () => _deleteReview(review),
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.all(4),
                  ),
                ],
              ],
            ),
            if (review.comment.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(review.comment),
            ],
          ],
        ),
      ),
    );
  }

  void _showReviewDialog({Review? existingReview}) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to leave a review.')),
      );
      return;
    }

    final isEdit = existingReview != null;
    int rating = existingReview?.rating ?? 5;
    final commentController =
        TextEditingController(text: existingReview?.comment ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    isEdit ? 'Edit Your Review' : 'Add a Review',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Rating',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      final starRating = index + 1;
                      return IconButton(
                        iconSize: 36,
                        icon: Icon(
                          starRating <= rating
                              ? Icons.star
                              : Icons.star_border,
                          color: Colors.amber,
                        ),
                        onPressed: () {
                          setModalState(() {
                            rating = starRating;
                          });
                        },
                      );
                    }),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Comment',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: commentController,
                    maxLines: 4,
                    minLines: 2,
                    decoration: InputDecoration(
                      hintText: 'Share your experience, tips, or recommended dishes...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.primaryGreen, width: 2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            final comment = commentController.text.trim();
                            if (isEdit) {
                              await _firestoreService.editReview(
                                placeId: widget.place.id,
                                reviewId: existingReview.id,
                                userId: currentUser.uid,
                                comment: comment,
                                rating: rating,
                              );
                            } else {
                              final userName = currentUser.displayName?.trim().isNotEmpty == true
                                  ? currentUser.displayName!
                                  : (currentUser.email ?? 'Local traveler');
                              await _firestoreService.addReview(
                                placeId: widget.place.id,
                                userId: currentUser.uid,
                                userName: userName,
                                comment: comment,
                                rating: rating,
                              );
                            }

                            if (!context.mounted) return;
                            context.read<PlaceProvider>().refresh();
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  isEdit
                                      ? 'Review updated successfully!'
                                      : 'Review added successfully!',
                                ),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryGreen,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(isEdit ? 'Update' : 'Submit'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _deleteReview(Review review) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Review'),
        content: const Text('Are you sure you want to delete this review? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    try {
      await _firestoreService.deleteReview(
        placeId: widget.place.id,
        reviewId: review.id,
        userId: review.userId,
      );
      if (mounted) {
        context.read<PlaceProvider>().refresh();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Review deleted successfully.')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to delete review.')),
        );
      }
    }
  }
}

class _PlacePhotoGallery extends StatefulWidget {
  final Place place;

  const _PlacePhotoGallery({required this.place});

  @override
  State<_PlacePhotoGallery> createState() => _PlacePhotoGalleryState();
}

class _PlacePhotoGalleryState extends State<_PlacePhotoGallery> {
  late final PageController _controller;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _controller = PageController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final media = widget.place.displayMedia;
    final count = media.length;

    return Stack(
      fit: StackFit.expand,
      children: [
        PageView.builder(
          controller: _controller,
          itemCount: count,
          onPageChanged: (i) => setState(() => _index = i),
          itemBuilder: (context, index) {
            final item = media[index];
            if (item.type == 'video') {
              return NetworkVideoPlayer(url: item.url);
            }
            return PlaceImage(
              place: widget.place,
              variant: index,
              imageUrl: item.url,
            );
          },
        ),
        if (count > 1)
          Positioned(
            bottom: 12,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(count, (i) {
                final active = i == _index;
                return Container(
                  width: active ? 10 : 7,
                  height: 7,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: active
                        ? Colors.white
                        : Colors.white.withOpacity(0.5),
                  ),
                );
              }),
            ),
          ),
      ],
    );
  }
}
