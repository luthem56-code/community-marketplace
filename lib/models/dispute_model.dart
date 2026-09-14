import 'package:cloud_firestore/cloud_firestore.dart';

enum DisputeReason {
  damaged('Item is damaged, torn, or stained'),
  notAsDescribed('Significantly not as described in photos'),
  wrongItem('Received the wrong item entirely'),
  counterfeit('Item appears to be counterfeit / fake'),
  missingParcel('Courier marked delivered but nothing received');

  final String label;
  const DisputeReason(this.label);
}

class DisputeModel {
  final String disputeId;
  final String orderId;
  final String buyerId;
  final String sellerId;
  final DisputeReason reason;
  final String description;
  final String status; // 'under_review', 'resolved_refunded', 'resolved_seller_paid'
  final DateTime createdAt;

  DisputeModel({
    required this.disputeId,
    required this.orderId,
    required this.buyerId,
    required this.sellerId,
    required this.reason,
    required this.description,
    this.status = 'under_review',
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
    'disputeId': disputeId,
    'orderId': orderId,
    'buyerId': buyerId,
    'sellerId': sellerId,
    'reason': reason.name,
    'description': description,
    'status': status,
    'createdAt': FieldValue.serverTimestamp(),
  };

  factory DisputeModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return DisputeModel(
      disputeId: doc.id,
      orderId: data['orderId'] ?? '',
      buyerId: data['buyerId'] ?? '',
      sellerId: data['sellerId'] ?? '',
      reason: DisputeReason.values.firstWhere(
        (r) => r.name == data['reason'],
        orElse: () => DisputeReason.notAsDescribed,
      ),
      description: data['description'] ?? '',
      status: data['status'] ?? 'under_review',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}