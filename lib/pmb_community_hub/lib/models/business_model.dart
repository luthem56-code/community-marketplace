import 'package:cloud_firestore/cloud_firestore.dart';

class BusinessModel {
  final String id;
  final String name;
  final String category;
  final String suburb;
  final String address;
  final String phone;
  final String whatsapp;
  final String description;
  final double rating;
  final int reviewCount;
  final bool isVerified;
  final bool isFeatured;
  final String? imageUrl;

  BusinessModel({
    required this.id,
    required this.name,
    required this.category,
    required this.suburb,
    required this.address,
    required this.phone,
    required this.whatsapp,
    required this.description,
    required this.rating,
    required this.reviewCount,
    required this.isVerified,
    required this.isFeatured,
    this.imageUrl,
  });

  factory BusinessModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return BusinessModel(
      id: doc.id,
      name: data['name'] ?? 'Local Business',
      category: data['category'] ?? 'General',
      suburb: data['suburb'] ?? 'Pietermaritzburg',
      address: data['address'] ?? '',
      phone: data['phone'] ?? '',
      whatsapp: data['whatsapp'] ?? '',
      description: data['description'] ?? '',
      rating: double.tryParse(data['rating']?.toString() ?? '5.0') ?? 5.0,
      reviewCount: int.tryParse(data['reviewCount']?.toString() ?? '0') ?? 0,
      isVerified: data['isVerified'] == true,
      isFeatured: data['isFeatured'] == true,
      imageUrl: data['imageUrl'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'category': category,
      'suburb': suburb,
      'address': address,
      'phone': phone,
      'whatsapp': whatsapp,
      'description': description,
      'rating': rating,
      'reviewCount': reviewCount,
      'isVerified': isVerified,
      'isFeatured': isFeatured,
      'imageUrl': imageUrl,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}