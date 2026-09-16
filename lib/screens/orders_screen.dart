import 'package:community_marketplace/services/whatsapp_helper.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/offer_model.dart';
import '../models/listing_model.dart';
import 'raise_dispute_screen.dart';
import 'checkout_screen.dart';

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

    return DefaultTabController(
      length: 3, // 3 Tabs now!
      child: Scaffold(
        backgroundColor: Colors.grey.shade100,
        appBar: AppBar(
          title: const Text('Orders & Offers', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
          backgroundColor: Colors.white,
          elevation: 0.5,
          leading: Navigator.canPop(context)
    ? IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.black),
        onPressed: () => Navigator.pop(context),
      )
    : null,
          bottom: const TabBar(
            labelColor: Color(0xFF008080),
            unselectedLabelColor: Colors.black54,
            indicatorColor: Color(0xFF008080),
            indicatorWeight: 3,
            tabs: [
              Tab(text: 'Purchases'),
              Tab(text: 'Sales'),
              Tab(text: 'Offers'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Tab 1: Buyer Orders
            _OrdersList(
              query: FirebaseFirestore.instance
                  .collection('orders')
                  .where('buyerId', isEqualTo: currentUserId),
              isSellerView: false,
            ),

            // Tab 2: Seller Orders
            _OrdersList(
              query: FirebaseFirestore.instance
                  .collection('orders')
                  .where('sellerId', isEqualTo: currentUserId),
              isSellerView: true,
            ),

            // Tab 3: Active Offers (Negotiations)
            _OffersList(currentUserId: currentUserId),
          ],
        ),
      ),
    );
  }
}

// --- Tab 3: Active Offers List (Realtime Negotiations) ---
class _OffersList extends StatelessWidget {
  final String currentUserId;
  const _OffersList({required this.currentUserId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('offers')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFF008080)));
        }

        final allDocs = snapshot.data?.docs ?? [];
        
        // Filter offers where the user is either the Buyer or the Seller
        final relevantOffers = allDocs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return data['buyerId'] == currentUserId || data['sellerId'] == currentUserId;
        }).toList();

        if (relevantOffers.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.local_offer_outlined, size: 64, color: Colors.grey.shade400),
                const SizedBox(height: 12),
                const Text('No active offers', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 6),
                Text('Price negotiations will appear here.', style: TextStyle(color: Colors.grey.shade600)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: relevantOffers.length,
          itemBuilder: (context, index) {
            final offer = OfferModel.fromFirestore(relevantOffers[index]);
            final isSeller = offer.sellerId == currentUserId;

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              child: Padding(
                padding: const EdgeInsets.all(14.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: offer.itemImageUrl.isNotEmpty
                              ? Image.network(offer.itemImageUrl, width: 55, height: 55, fit: BoxFit.cover)
                              : Container(width: 55, height: 55, color: Colors.grey.shade200),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(offer.itemTitle, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), maxLines: 1),
                              const SizedBox(height: 2),
                              Text('Listed Price: R${offer.originalPrice.toStringAsFixed(0)}', style: TextStyle(color: Colors.grey.shade600, fontSize: 12, decoration: TextDecoration.lineThrough)),
                              const SizedBox(height: 2),
                              Text('Offered: R${offer.offeredPrice.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF008080), fontSize: 15)),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: offer.status == OfferStatus.accepted
                                ? Colors.green.shade50
                                : offer.status == OfferStatus.declined
                                    ? Colors.red.shade50
                                    : Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            offer.status.label,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: offer.status == OfferStatus.accepted
                                  ? Colors.green.shade800
                                  : offer.status == OfferStatus.declined
                                      ? Colors.red.shade800
                                      : Colors.orange.shade800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // --- SELLER CONTROLS: Accept or Decline ---
                    if (isSeller && offer.status == OfferStatus.pending)
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                              onPressed: () async {
                                await FirebaseFirestore.instance.collection('offers').doc(offer.offerId).update({'status': 'declined'});
                              },
                              child: const Text('Decline'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF008080), foregroundColor: Colors.white),
                              onPressed: () async {
                                await FirebaseFirestore.instance.collection('offers').doc(offer.offerId).update({'status': 'accepted'});
                              },
                              child: const Text('Accept Offer'),
                            ),
                          ),
                        ],
                      ),

                    // --- BUYER ACTION: When seller accepts, buyer can buy at discounted price! ---
                    if (!isSeller && offer.status == OfferStatus.accepted)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700, foregroundColor: Colors.white),
                          onPressed: () async {
                            // Fetch listing and launch checkout at the discounted offer price!
                            final listingDoc = await FirebaseFirestore.instance.collection('listings').doc(offer.listingId).get();
                            if (!listingDoc.exists || !context.mounted) return;

                            final rawListing = ListingModel.fromFirestore(listingDoc);
                            // Override listing price with agreed discounted price
                            final discountedListing = ListingModel(
                              id: rawListing.id,
                              sellerId: rawListing.sellerId,
                              title: rawListing.title,
                              description: rawListing.description,
                              category: rawListing.category,
                              subCategory: rawListing.subCategory,
                              size: rawListing.size,
                              brand: rawListing.brand,
                              condition: rawListing.condition,
                              price: offer.offeredPrice, // DISCOUNTED PRICE APPLIED!
                              imageUrls: rawListing.imageUrls,
                              shippingOptions: rawListing.shippingOptions,
                              createdAt: rawListing.createdAt,
                            );

                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => CheckoutScreen(listing: discountedListing)),
                            );
                          },
                          child: Text('Checkout at Offer Price (R${offer.offeredPrice.toStringAsFixed(2)})'),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// (Existing Orders List Code)
class _OrdersList extends StatelessWidget {
  final Query query;
  final bool isSellerView;
  const _OrdersList({required this.query, required this.isSellerView});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFF008080)));
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(isSellerView ? Icons.storefront_outlined : Icons.shopping_bag_outlined, size: 64, color: Colors.grey.shade400),
                const SizedBox(height: 12),
                Text(isSellerView ? 'No sales yet!' : 'No purchases yet!', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            return _OrderCard(
              orderId: doc.id,
              order: doc.data() as Map<String, dynamic>,
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

  @override
  Widget build(BuildContext context) {
    final status = order['status'] ?? 'paidEscrowHeld';
    final trackingNumber = order['trackingNumber'] as String?;
    final itemPrice = (order['itemPrice'] as num?)?.toDouble() ?? 0.0;
    final shippingFee = (order['shippingFee'] as num?)?.toDouble() ?? 0.0;
    final sellerEarnings = itemPrice + shippingFee;

    return Card(
      elevation: 0.5,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- 1. Order ID & Status Chip ---
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
                    color: status == 'disputed'
                        ? Colors.red.shade50
                        : status == 'completed'
                            ? Colors.green.shade50
                            : const Color(0xFF008080).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    status == 'disputed' ? 'DISPUTED (FROZEN)' : status.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: status == 'disputed'
                          ? Colors.red.shade700
                          : status == 'completed'
                              ? Colors.green.shade800
                              : const Color(0xFF008080),
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 16),

            // --- 2. Item Image & Details ---
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

            // --- 3. Delivery Details Card ---
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
                  Text(
                    'Deliver To: ${order['recipientName']} (${order['recipientPhone']})',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Destination: ${order['deliveryDetails']}',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                  ),
                  if (trackingNumber != null && trackingNumber.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Waybill/PIN: $trackingNumber',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF008080)),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),

            // --- 4. DISPUTE BANNER: When escrow is locked ---
            if (status == 'disputed')
              Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.lock, color: Colors.red.shade700, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Escrow Payout Frozen',
                            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red.shade900, fontSize: 13),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isSeller
                                ? 'The buyer reported an issue. Funds are held safely in escrow while our community team reviews the evidence.'
                                : 'You opened a dispute. Your money is locked safely in escrow while the issue is being resolved.',
                            style: TextStyle(fontSize: 12, color: Colors.red.shade800),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            // --- 5. SELLER ACTION: Add tracking and mark shipped ---
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
                  onPressed: () => _showAddTracking(context),
                ),
              ),

            // --- 6. BUYER ACTIONS: When parcel is shipped / in transit ---
            if (!isSeller && status == 'shipped')
              Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade700,
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.check_circle_outline, size: 18),
                      label: const Text('Item Received & All Good (Release Funds)'),
                      onPressed: () => _confirmReceipt(context, sellerEarnings),
                    ),
                  ),
                  const SizedBox(height: 6),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton.icon(
                      style: TextButton.styleFrom(foregroundColor: Colors.red.shade700),
                      icon: const Icon(Icons.report_problem_outlined, size: 16),
                      label: const Text('Something wrong with item? Report issue', style: TextStyle(fontSize: 12)),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => RaiseDisputeScreen(
                              orderId: orderId,
                              buyerId: order['buyerId'] ?? '',
                              sellerId: order['sellerId'] ?? '',
                              itemTitle: order['itemTitle'] ?? 'Item',
                              totalAmount: (order['totalAmount'] as num?)?.toDouble() ?? 0.0,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),

            // --- 7. COMPLETED BADGE ---
            if (status == 'completed')
              Container(
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.verified, size: 16, color: Colors.green.shade700),
                    const SizedBox(width: 4),
                    Text(
                      isSeller ? 'Escrow funds released to your wallet!' : 'Order completed & verified.',
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

  void _showAddTracking(BuildContext context) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Enter Courier Waybill / PIN'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(
            labelText: 'Tracking Code *',
            hintText: 'e.g. PUDO-123456 or PAXI-789',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF008080),
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              if (ctrl.text.trim().isEmpty) return;
              await FirebaseFirestore.instance
                  .collection('orders')
                  .doc(orderId)
                  .update({'status': 'shipped', 'trackingNumber': ctrl.text.trim()});

              await WhatsAppHelper.sendNotification(
                recipientUserId: order['buyerId'] ?? '',
                title: 'Parcel Shipped! 🚚',
                message: 'Your order "${order['itemTitle']}" is on the way via ${order['shippingMethod']}. Tracking/PIN: ${ctrl.text.trim()}',
                type: 'shipping',
                targetId: orderId,
              );

              if (context.mounted) Navigator.pop(ctx);
            },
            child: const Text('Confirm Shipped'),
          ),
        ],
      ),
    );
  }

  void _confirmReceipt(BuildContext context, double payout) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Receipt & Release Funds?'),
        content: Text('Confirming will release R${payout.toStringAsFixed(2)} directly to the seller.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Not Yet')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700, foregroundColor: Colors.white),
            onPressed: () async {
              final batch = FirebaseFirestore.instance.batch();
              batch.update(FirebaseFirestore.instance.collection('orders').doc(orderId), {'status': 'completed'});
              batch.set(
                FirebaseFirestore.instance.collection('wallets').doc(order['sellerId']),
                {'availableBalance': FieldValue.increment(payout)},
                SetOptions(merge: true),
              );
              await batch.commit();
              if (context.mounted) {
                Navigator.pop(ctx);
                _showReviewDialog(context); // <-- PROMPT REVIEW!
              }
            },
            child: const Text('Yes, Release Funds'),
          ),
        ],
      ),
    );
  }

  void _showReviewDialog(BuildContext context) {
    int rating = 5;
    final commentCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: const Text('Rate Your Experience ⭐', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('How was the item accuracy and communication with the seller?'),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return IconButton(
                    icon: Icon(
                      index < rating ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 32,
                    ),
                    onPressed: () => setDialogState(() => rating = index + 1),
                  );
                }),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: commentCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                  hintText: 'e.g. Loved the dress! Fast shipping and clean condition.',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Skip')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF008080), foregroundColor: Colors.white),
              onPressed: () async {
                final currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';
                final currentName = FirebaseAuth.instance.currentUser?.displayName ?? 'Community Buyer';

                await FirebaseFirestore.instance.collection('reviews').add({
                  'orderId': orderId,
                  'sellerId': order['sellerId'],
                  'buyerId': currentUid,
                  'buyerName': currentName,
                  'rating': rating,
                  'comment': commentCtrl.text.trim(),
                  'itemTitle': order['itemTitle'],
                  'createdAt': FieldValue.serverTimestamp(),
                });

                if (context.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Thank you for leaving a community review! 🎉')),
                  );
                }
              },
              child: const Text('Submit Review'),
            ),
          ],
        ),
      ),
    );
  }
}