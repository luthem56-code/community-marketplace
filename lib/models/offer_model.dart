import 'package:cloud_firestore/cloud_firestore.dart';

enum OfferStatus {
  pending('Pending Review'),
  accepted('Offer Accepted'),
  declined('Offer Declined'),
  countered('Counter-Offer Sent');

  final String label;
  const OfferStatus(this.label);
}

class OfferModel {
  final String offerId;
  final String listingId;
  final String itemTitle;
  final String itemImageUrl;
  final double originalPrice;
  final double offeredPrice;
  final String buyerId;
  final String sellerId;
  final OfferStatus status;
  final DateTime createdAt;

  OfferModel({
    required this.offerId,
    required this.listingId,
    required this.itemTitle,
    required this.itemImageUrl,
    required this.originalPrice,
    required this.offeredPrice,
    required this.buyerId,
    required this.sellerId,
    this.status = OfferStatus.pending,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
    'offerId': offerId,
    'listingId': listingId,
    'itemTitle': itemTitle,
    'itemImageUrl': itemImageUrl,
    'originalPrice': originalPrice,
    'offeredPrice': offeredPrice,
    'buyerId': buyerId,
    'sellerId': sellerId,
    'status': status.name,
    'createdAt': FieldValue.serverTimestamp(),
  };

  factory OfferModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return OfferModel(
      offerId: doc.id,
      listingId: data['listingId'] ?? '',
      itemTitle: data['itemTitle'] ?? '',
      itemImageUrl: data['itemImageUrl'] ?? '',
      originalPrice: (data['originalPrice'] as num?)?.toDouble() ?? 0.0,
      offeredPrice: (data['offeredPrice'] as num?)?.toDouble() ?? 0.0,
      buyerId: data['buyerId'] ?? '',
      sellerId: data['sellerId'] ?? '',
      status: OfferStatus.values.firstWhere(
        (s) => s.name == data['status'],
        orElse: () => OfferStatus.pending,
      ),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}