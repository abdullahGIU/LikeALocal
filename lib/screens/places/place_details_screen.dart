import 'package:flutter/material.dart';
import '../../core/models/place.dart';
import '../../core/models/review.dart';
import '../../core/services/firestore_service.dart';
import '../../core/services/auth_service.dart';

class PlaceDetailsScreen extends StatefulWidget {
  final Place place;

  const PlaceDetailsScreen({super.key, required this.place});

  @override
  State<PlaceDetailsScreen> createState() => _PlaceDetailsScreenState();
}

class _PlaceDetailsScreenState extends State<PlaceDetailsScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();
  
  List<Review> _reviews = [];
  bool _isLoadingReviews = true;
  bool _isPinned = false;
  bool _isCheckingPin = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await Future.wait([
      _loadReviews(),
      _checkIfPinned(),
    ]);
  }

  Future<void> _loadReviews() async {
    try {
      final reviews = await _firestoreService.getReviewsForPlace(widget.place.id);
      setState(() {
        _reviews = reviews;
        _isLoadingReviews = false;
      });
    } catch (e) {
      setState(() { _isLoadingReviews = false; });
    }
  }

  Future<void> _checkIfPinned() async {
    final user = _authService.currentFirebaseUser;
    if (user == null) {
      setState(() { _isCheckingPin = false; });
      return;
    }

    try {
      final appUser = await _authService.getCurrentAppUser();
      setState(() {
        _isPinned = appUser?.savedPlaces.contains(widget.place.id) ?? false;
        _isCheckingPin = false;
      });
    } catch (e) {
      setState(() { _isCheckingPin = false; });
    }
  }

  Future<void> _togglePin() async {
    final user = _authService.currentFirebaseUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to pin places')),
      );
      return;
    }

    setState(() { _isCheckingPin = true; });

    try {
      if (_isPinned) {
        await _firestoreService.unpinPlace(user.uid, widget.place.id);
        if (!mounted) return;
        setState(() { _isPinned = false; });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Place unpinned')),
        );
      } else {
        await _firestoreService.pinPlace(user.uid, widget.place.id);
        if (!mounted) return;
        setState(() { _isPinned = true; });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Place pinned successfully')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      setState(() { _isCheckingPin = false; });
    }
  }

  void _showAddReviewDialog() {
    final user = _authService.currentFirebaseUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to add a review')),
      );
      return;
    }

    double rating = 5.0;
    final contentController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Add Review'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return IconButton(
                        icon: Icon(
                          index < rating ? Icons.star : Icons.star_border,
                          color: Colors.amber,
                        ),
                        onPressed: () {
                          setDialogState(() {
                            rating = index + 1.0;
                          });
                        },
                      );
                    }),
                  ),
                  TextField(
                    controller: contentController,
                    decoration: const InputDecoration(hintText: 'Write your review...'),
                    maxLines: 3,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (contentController.text.trim().isEmpty) return;
                    
                    Navigator.pop(context); // Close dialog
                    if (!mounted) return;
                    setState(() { _isLoadingReviews = true; });

                    try {
                      await _firestoreService.addReview(
                        placeId: widget.place.id,
                        userId: user.uid,
                        rating: rating,
                        content: contentController.text.trim(),
                      );
                      await _loadReviews(); // Refresh
                    } catch (e) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error adding review: $e')),
                      );
                      setState(() { _isLoadingReviews = false; });
                    }
                  },
                  child: const Text('Submit'),
                ),
              ],
            );
          }
        );
      },
    );
  }
  
  void _deleteReview(String reviewId) async {
    setState(() { _isLoadingReviews = true; });
    try {
      await _firestoreService.deleteReview(reviewId: reviewId, placeId: widget.place.id);
      await _loadReviews();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting review: $e')),
      );
      setState(() { _isLoadingReviews = false; });
    }
  }

  void _showEditReviewDialog(Review review) {
    double rating = review.rating;
    final contentController = TextEditingController(text: review.content);

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Edit Review'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return IconButton(
                        icon: Icon(
                          index < rating ? Icons.star : Icons.star_border,
                          color: Colors.amber,
                        ),
                        onPressed: () {
                          setDialogState(() {
                            rating = index + 1.0;
                          });
                        },
                      );
                    }),
                  ),
                  TextField(
                    controller: contentController,
                    decoration: const InputDecoration(hintText: 'Edit your review...'),
                    maxLines: 3,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (contentController.text.trim().isEmpty) return;
                    
                    Navigator.pop(context); // Close dialog
                    if (!mounted) return;
                    setState(() { _isLoadingReviews = true; });

                    try {
                      await _firestoreService.updateReview(
                        reviewId: review.id,
                        placeId: widget.place.id,
                        rating: rating,
                        content: contentController.text.trim(),
                      );
                      await _loadReviews(); // Refresh
                    } catch (e) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error updating review: $e')),
                      );
                      setState(() { _isLoadingReviews = false; });
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          }
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _authService.currentFirebaseUser;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.place.name),
        actions: [
          _isCheckingPin
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                )
              : IconButton(
                  icon: Icon(_isPinned ? Icons.bookmark : Icons.bookmark_border),
                  onPressed: _togglePin,
                ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.place.imageUrls.isNotEmpty)
              Image.network(
                widget.place.imageUrls.first,
                height: 200,
                fit: BoxFit.cover,
              )
            else
              Container(
                height: 200,
                color: Colors.grey[300],
                child: const Icon(Icons.image, size: 50, color: Colors.grey),
              ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.place.name,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.place.address,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber),
                      const SizedBox(width: 4),
                      Text(
                        '${widget.place.rating.toStringAsFixed(1)} (${widget.place.ratingCount} reviews)',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.place.description,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const Divider(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Reviews',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      ElevatedButton(
                        onPressed: _showAddReviewDialog,
                        child: const Text('Add Review'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (_isLoadingReviews)
                    const Center(child: CircularProgressIndicator())
                  else if (_reviews.isEmpty)
                    const Text('No reviews yet. Be the first!')
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _reviews.length,
                      itemBuilder: (context, index) {
                        final review = _reviews[index];
                        final isMyReview = user != null && review.userId == user.uid;
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            title: Row(
                              children: [
                                Row(
                                  children: List.generate(5, (starIndex) {
                                    return Icon(
                                      starIndex < review.rating ? Icons.star : Icons.star_border,
                                      size: 16,
                                      color: Colors.amber,
                                    );
                                  }),
                                ),
                              ],
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(review.content),
                            ),
                            trailing: isMyReview
                                ? Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit, color: Colors.blue),
                                        onPressed: () => _showEditReviewDialog(review),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete, color: Colors.red),
                                        onPressed: () => _deleteReview(review.id),
                                      ),
                                    ],
                                  )
                                : null,
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
