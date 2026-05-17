import 'package:cloud_firestore/cloud_firestore.dart';

class Place {
  final String id;
  final String ownerId;
  final String ownerName;
  final String name;
  final String description;
  final String category;
  final String address;
  final double? latitude;
  final double? longitude;
  final String localTips;
  final String recommendedDishes;
  final List<String> mediaUrls;
  final List<String> mediaTypes;
  final double rating;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Place({
    required this.id,
    required this.ownerId,
    required this.ownerName,
    required this.name,
    required this.description,
    required this.category,
    required this.address,
    this.latitude,
    this.longitude,
    this.localTips = '',
    this.recommendedDishes = '',
    this.mediaUrls = const [],
    this.mediaTypes = const [],
    this.rating = 0,
    this.createdAt,
    this.updatedAt,
  });

  List<String> get imageUrls {
    final images = <String>[];
    for (var i = 0; i < mediaUrls.length; i++) {
      final type = i < mediaTypes.length ? mediaTypes[i] : '';
      if (type == 'image') {
        images.add(mediaUrls[i]);
      }
    }
    return images;
  }

  factory Place.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    return Place.fromMap(snapshot.data() ?? <String, dynamic>{}, snapshot.id);
  }

  factory Place.fromMap(Map<String, dynamic> map, [String? documentId]) {
    DateTime? readDate(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      return null;
    }

    double? readDouble(dynamic value) {
      if (value == null) return null;
      if (value is num) return value.toDouble();
      return double.tryParse(value.toString());
    }

    return Place(
      id: documentId ?? map['id'] ?? '',
      ownerId: map['ownerId'] ?? '',
      ownerName: map['ownerName'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      category: map['category'] ?? '',
      address: map['address'] ?? '',
      latitude: readDouble(map['latitude']),
      longitude: readDouble(map['longitude']),
      localTips: map['localTips'] ?? '',
      recommendedDishes: map['recommendedDishes'] ?? '',
      mediaUrls: List<String>.from(map['mediaUrls'] ?? map['imageUrls'] ?? []),
      mediaTypes: List<String>.from(map['mediaTypes'] ?? []),
      rating: readDouble(map['rating']) ?? 0,
      createdAt: readDate(map['createdAt']),
      updatedAt: readDate(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'ownerId': ownerId,
      'ownerName': ownerName,
      'name': name,
      'description': description,
      'category': category,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'localTips': localTips,
      'recommendedDishes': recommendedDishes,
      'mediaUrls': mediaUrls,
      'mediaTypes': mediaTypes,
      'rating': rating,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  Place copyWith({
    String? id,
    String? ownerId,
    String? ownerName,
    String? name,
    String? description,
    String? category,
    String? address,
    double? latitude,
    double? longitude,
    String? localTips,
    String? recommendedDishes,
    List<String>? mediaUrls,
    List<String>? mediaTypes,
    double? rating,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Place(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      ownerName: ownerName ?? this.ownerName,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      localTips: localTips ?? this.localTips,
      recommendedDishes: recommendedDishes ?? this.recommendedDishes,
      mediaUrls: mediaUrls ?? this.mediaUrls,
      mediaTypes: mediaTypes ?? this.mediaTypes,
      rating: rating ?? this.rating,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
