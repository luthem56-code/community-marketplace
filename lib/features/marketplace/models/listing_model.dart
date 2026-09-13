import 'package:cloud_firestore/cloud_firestore.dart';

enum ItemCondition {
  brandNewWithTags('Brand New (with tags)'),
  brandNewNoTags('Brand New (no tags)'),
  likeNew('Like New'),
  good('Good'),
  fair('Fair');

  final String label;
  const ItemCondition(this.label);
}

class ShippingOption {
  final String method; // e.g. "Pudo Locker", "PAXI", "PostNet", "Door Courier"
  final double price;  // e.g. 60.00
  final bool isEnabled;

  ShippingOption({
    required this.method,
    required this.price,
    required this.isEnabled,
  });

  Map<String, dynamic> toMap() => {
    'method': method,
    'price': price,
    'isEnabled': isEnabled,
  };

  factory ShippingOption.fromMap(Map<String, dynamic> map) => ShippingOption(
    method: map['method'] ?? '',
    price: (map['price'] as num?)?.toDouble() ?? 0.0,
    isEnabled: map['isEnabled'] ?? false,
  );
}

class ListingModel {
  final String id;
  final String sellerId;
  final String title;
  final String description;
  final String category;
  final String subCategory;
  final String size;
  final String brand;
  final ItemCondition condition;
  final double price; // in ZAR (Rands)
  final List<String> imageUrls;
  final List<ShippingOption> shippingOptions;
  final String status; // 'active', 'reserved', 'sold', 'archived'
  final DateTime createdAt;

  ListingModel({
    required this.id,
    required this.sellerId,
    required this.title,
    required this.description,
    required this.category,
    required this.subCategory,
    required this.size,
    required this.brand,
    required this.condition,
    required this.price,
    required this.imageUrls,
    required this.shippingOptions,
    this.status = 'active',
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'sellerId': sellerId,
    'title': title,
    'description': description,
    'category': category,
    'subCategory': subCategory,
    'size': size,
    'brand': brand,
    'condition': condition.name,
    'price': price,
    'imageUrls': imageUrls,
    'shippingOptions': shippingOptions.map((e) => e.toMap()).toList(),
    'status': status,
    'createdAt': FieldValue.serverTimestamp(),
  };

  factory ListingModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ListingModel(
      id: doc.id,
      sellerId: data['sellerId'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      category: data['category'] ?? '',
      subCategory: data['subCategory'] ?? '',
      size: data['size'] ?? '',
      brand: data['brand'] ?? '',
      condition: ItemCondition.values.firstWhere(
        (c) => c.name == data['condition'],
        orElse: () => ItemCondition.good,
      ),
      price: (data['price'] as num?)?.toDouble() ?? 0.0,
      imageUrls: List<String>.from(data['imageUrls'] ?? []),
      shippingOptions: (data['shippingOptions'] as List<dynamic>? ?? [])
          .map((item) => ShippingOption.fromMap(item as Map<String, dynamic>))
          .toList(),
      status: data['status'] ?? 'active',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}