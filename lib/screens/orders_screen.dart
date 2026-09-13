import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.grey.shade100,
        appBar: AppBar(
          title: const Text('My Orders', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
          backgroundColor: Colors.white,
          elevation: 0.5,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
          bottom: const TabBar(
            labelColor: Color(0xFF008080),
            unselectedLabelColor: Colors.black54,
            indicatorColor: Color(0xFF008080),
            indicatorWeight: 3,
            tabs: [
              Tab(text: 'Purchases (Bought)'),
              Tab(text: 'Sales (To Ship)'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Tab 1: Buyer View (no index needed)
            _OrdersList(
              query: FirebaseFirestore.instance
                  .collection('orders')
                  .where('buyerId', isEqualTo: currentUserId),
              isSellerView: false,
            ),

            // Tab 2: Seller View (no index needed)
            _OrdersList(
              query: FirebaseFirestore.instance
                  .collection('orders')
                  .where('sellerId', isEqualTo: currentUserId),
              isSellerView: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _OrdersList extends StatelessWidget {
  final Query query;
  final bool isSellerView;

  const _OrdersList({required this.query, required this.isSellerView});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFF008080)));
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isSellerView ? Icons.storefront_outlined : Icons.shopping_bag_outlined,
                  size: 64,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 12),
                Text(
                  isSellerView ? 'No sales yet!' : 'No purchases yet!',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text(
                  isSellerView
                      ? 'Orders placed for your items will show up here.'
                      : 'Items you buy will be tracked here safely in escrow.',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final orderData = docs[index].data() as Map<String, dynamic>;
            final orderDocId = docs[index].id;

            return _OrderCard(
              orderId: orderDocId,
              order: orderData,
              isSeller: isSellerView,
            );
          },
        );
      },
    );
  }
}

class _OrderCard extends StatelessWidget {
  final String orderId;
  final Map<String, dynamic> order;
  final bool isSeller;

  const _OrderCard({
    required this.orderId,
    required this.order,
    required this.isSeller,
  });

  Color _getStatusColor(String status) {
    switch (status) {
      case 'paidEscrowHeld':
        return Colors.orange.shade700;
      case 'shipped':
        return Colors.blue.shade700;
      case 'completed':
        return Colors.green.shade700;
      default:
        return Colors.grey.shade700;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'paidEscrowHeld':
        return 'Escrow Held (Awaiting Shipping)';
      case 'shipped':
        return 'In Transit (Shipped)';
      case 'completed':
        return 'Completed & Funds Released';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = order['status'] ?? 'paidEscrowHeld';
    final trackingNumber = order['trackingNumber'] as String?;
    final itemPrice = (order['itemPrice'] as num?)?.toDouble() ?? 0.0;
    final shippingFee = (order['shippingFee'] as num?)?.toDouble() ?? 0.0;
    final sellerEarnings = itemPrice + shippingFee; // Seller receives item price + shipping reimbursement

    return Card(
      elevation: 0.5,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order ID & Status Chip
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Order #${orderId.substring(0, 8).toUpperCase()}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black54),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(status).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _getStatusText(status),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: _getStatusColor(status),
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 16),

            // Item Details Row
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: (order['itemImageUrl'] != null && (order['itemImageUrl'] as String).isNotEmpty)
                      ? Image.network(order['itemImageUrl'], width: 60, height: 60, fit: BoxFit.cover)
                      : Container(width: 60, height: 60, color: Colors.grey.shade200),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order['itemTitle'] ?? 'Item',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Method: ${order['shippingMethod']}',
                        style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isSeller
                            ? 'Your Payout: R${sellerEarnings.toStringAsFixed(2)}'
                            : 'Paid Total: R${(order['totalAmount'] as num?)?.toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF008080), fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Shipping destination details (critical for Seller to package)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Deliver To: ${order['recipientName']} (${order['recipientPhone']})',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  Text('Drop-point/Address: ${order['deliveryDetails']}',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                  if (trackingNumber != null && trackingNumber.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text('Waybill/Tracking: $trackingNumber',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF008080))),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),

            // --- Action Buttons based on Role & Status ---

            // 1. SELLER ACTION: If order is paid, seller can add tracking and mark shipped
            if (isSeller && status == 'paidEscrowHeld')
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF008080),
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.local_shipping, size: 18),
                  label: const Text('Mark Shipped & Add Waybill'),
                  onPressed: () => _showAddTrackingDialog(context),
                ),
              ),

            // 2. BUYER ACTION: If shipped, buyer can confirm receipt and release funds
            if (!isSeller && status == 'shipped')
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.check_circle_outline, size: 18),
                  label: const Text('Item Received & All Good (Release Funds)'),
                  onPressed: () => _confirmReceiptAndReleaseEscrow(context, sellerEarnings),
                ),
              ),

            // Completed badge notice
            if (status == 'completed')
              Container(
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.verified, size: 16, color: Colors.green.shade700),
                    const SizedBox(width: 4),
                    Text(
                      isSeller ? 'Escrow released to your balance!' : 'Order completed! Thank you for confirming.',
                      style: TextStyle(fontSize: 12, color: Colors.green.shade700, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Dialog for Seller to enter tracking number
  void _showAddTrackingDialog(BuildContext context) {
    final trackingController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Enter Courier Waybill / PIN'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Once you drop off the parcel at Pudo, PAXI, or with the courier, enter the tracking code below so the buyer can track it.',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: trackingController,
              decoration: const InputDecoration(
                labelText: 'Tracking / Waybill Number *',
                hintText: 'e.g. PUDO-123456 or PAXI-789',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF008080),
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final code = trackingController.text.trim();
              if (code.isEmpty) return;

              await FirebaseFirestore.instance.collection('orders').doc(orderId).update({
                'status': 'shipped',
                'trackingNumber': code,
              });

              if (context.mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Order marked as shipped! 🚀')),
                );
              }
            },
            child: const Text('Confirm Shipped'),
          ),
        ],
      ),
    );
  }

  // Buyer confirms receipt -> Releases escrow to Seller's wallet balance
  void _confirmReceiptAndReleaseEscrow(BuildContext context, double sellerPayout) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Item Received?'),
        content: Text(
          'Are you satisfied with the item?\n\nConfirming will release R${sellerPayout.toStringAsFixed(2)} from escrow directly to the seller.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Not Yet'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade700,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final firestore = FirebaseFirestore.instance;
              final sellerId = order['sellerId'];

              // Atomic Batch: Update Order to 'completed' AND increment Seller's Wallet Balance
              final batch = firestore.batch();

              final orderRef = firestore.collection('orders').doc(orderId);
              batch.update(orderRef, {'status': 'completed'});

              final walletRef = firestore.collection('wallets').doc(sellerId);
              batch.set(
                walletRef,
                {
                  'availableBalance': FieldValue.increment(sellerPayout),
                  'updatedAt': FieldValue.serverTimestamp(),
                },
                SetOptions(merge: true),
              );

              await batch.commit();

              if (context.mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Order completed and funds released to seller! 🎉')),
                );
              }
            },
            child: const Text('Yes, Release Funds'),
          ),
        ],
      ),
    );
  }
}