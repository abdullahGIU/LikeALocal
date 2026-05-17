import 'package:cloud_firestore/cloud_firestore.dart';

class Place {
  final String id;
  final String name;
  final String description;
  final String address;
  final String category;
  final double latitude;
  final double longitude;
  final List<String> imageUrls;
  final List<String> tips;
  final double rating;
  final int reviewCount;
  final bool isOpen;
  final String budget;
  final String atmosphere;
  final String? ownerId;
  final double? distanceKm;

  const Place({
    required this.id,
    required this.name,
    required this.description,
    required this.address,
    required this.category,
    required this.latitude,
    required this.longitude,
    required this.imageUrls,
    required this.tips,
    required this.rating,
    required this.reviewCount,
    required this.isOpen,
    required this.budget,
    required this.atmosphere,
    this.ownerId,
    this.distanceKm,
  });

  factory Place.fromMapboxFeature(
    Map<String, dynamic> feature,
    String category,
  ) {
    final props = feature['properties'] as Map<String, dynamic>? ?? {};
    final geometry = feature['geometry'] as Map<String, dynamic>? ?? {};
    final coordinates = geometry['coordinates'] as List<dynamic>? ?? [0, 0];
    final lng = (coordinates.first as num).toDouble();
    final lat = (coordinates.last as num).toDouble();
    final mapboxId = props['mapbox_id'] as String? ?? feature['id']?.toString();

    final name = (props['name_preferred'] as String?) ??
        (props['name'] as String?) ??
        'Unnamed place';
    final address = (props['full_address'] as String?) ??
        (props['place_formatted'] as String?) ??
        (props['address'] as String?) ??
        '';

    return Place(
      id: 'mapbox_${mapboxId ?? '$lat,$lng'}',
      name: name,
      description: address,
      address: address,
      category: category,
      latitude: lat,
      longitude: lng,
      imageUrls: const [],
      tips: const [],
      rating: 4.0,
      reviewCount: 0,
      isOpen: true,
      budget: 'medium',
      atmosphere: 'lively',
    );
  }

  factory Place.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    final geoPoint = data['location'] as GeoPoint?;
    final latitude = (data['latitude'] as num?)?.toDouble() ?? geoPoint?.latitude ?? 0;
    final longitude = (data['longitude'] as num?)?.toDouble() ?? geoPoint?.longitude ?? 0;

    return Place(
      id: doc.id,
      name: (data['name'] as String?)?.trim().isNotEmpty == true
          ? (data['name'] as String).trim()
          : 'Unnamed place',
      description: (data['description'] as String?) ?? '',
      address: (data['address'] as String?) ?? '',
      category: (data['category'] as String?) ?? 'Other',
      latitude: latitude,
      longitude: longitude,
      imageUrls: (data['imageUrls'] as List<dynamic>? ?? const [])
          .map((e) => e.toString())
          .where((e) => e.isNotEmpty)
          .toList(),
      tips: (data['tips'] as List<dynamic>? ?? const [])
          .map((e) => e.toString())
          .where((e) => e.isNotEmpty)
          .toList(),
      rating: (data['rating'] as num?)?.toDouble() ?? 0,
      reviewCount: (data['reviewCount'] as num?)?.toInt() ?? 0,
      isOpen: (data['isOpen'] as bool?) ?? ((data['status'] as String?)?.toLowerCase() == 'open'),
      budget: ((data['budget'] as String?) ?? 'medium').toLowerCase(),
      atmosphere: ((data['atmosphere'] as String?) ?? 'lively').toLowerCase(),
      ownerId: data['ownerId'] as String?,
    );
  }

  Place copyWith({
    String? id,
    String? name,
    String? description,
    String? address,
    String? category,
    double? latitude,
    double? longitude,
    List<String>? imageUrls,
    List<String>? tips,
    double? rating,
    int? reviewCount,
    bool? isOpen,
    String? budget,
    String? atmosphere,
    String? ownerId,
    double? distanceKm,
  }) {
    return Place(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      address: address ?? this.address,
      category: category ?? this.category,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      imageUrls: imageUrls ?? this.imageUrls,
      tips: tips ?? this.tips,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      isOpen: isOpen ?? this.isOpen,
      budget: budget ?? this.budget,
      atmosphere: atmosphere ?? this.atmosphere,
      ownerId: ownerId ?? this.ownerId,
      distanceKm: distanceKm ?? this.distanceKm,
    );
  }
}
