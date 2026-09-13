import 'package:cloud_firestore/cloud_firestore.dart';

enum OrderStatus {
  pendingPayment('Pending Payment'),
  paidEscrowHeld('Paid - Funds in Escrow'),
  shipped('Shipped'),
  delivered('Delivered'),
  completed('Completed'),
  disputed('Disputed'),
  cancelled('Cancelled');

  final String label;
  const OrderStatus(this.label);
}

class OrderModel {
  final String orderId;
  final String listingId;
  final String itemTitle;
  final String itemImageUrl;
  final String buyerId;
  final String sellerId;
  final double itemPrice;
  final double shippingFee;
  final double buyerProtectionFee;
  final double totalAmount;
  final String shippingMethod;
  final String recipientName;
  final String recipientPhone;
  final String deliveryDetails; // Locker location, PEP branch code, or street address
  final OrderStatus status;
  final String? trackingNumber;
  final DateTime createdAt;

  OrderModel({
    required this.orderId,
    required this.listingId,
    required this.itemTitle,
    required this.itemImageUrl,
    required this.buyerId,
    required this.sellerId,
    required this.itemPrice,
    required this.shippingFee,
    required this.buyerProtectionFee,
    required this.totalAmount,
    required this.shippingMethod,
    required this.recipientName,
    required this.recipientPhone,
    required this.deliveryDetails,
    this.status = OrderStatus.paidEscrowHeld,
    this.trackingNumber,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
    'orderId': orderId,
    'listingId': listingId,
    'itemTitle': itemTitle,
    'itemImageUrl': itemImageUrl,
    'buyerId': buyerId,
    'sellerId': sellerId,
    'itemPrice': itemPrice,
    'shippingFee': shippingFee,
    'buyerProtectionFee': buyerProtectionFee,
    'totalAmount': totalAmount,
    'shippingMethod': shippingMethod,
    'recipientName': recipientName,
    'recipientPhone': recipientPhone,
    'deliveryDetails': deliveryDetails,
    'status': status.name,
    'trackingNumber': trackingNumber,
    'createdAt': FieldValue.serverTimestamp(),
  };
}