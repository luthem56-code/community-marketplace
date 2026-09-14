import 'package:flutter/material.dart';
import '../models/listing_model.dart';
import 'checkout_screen.dart';
import 'seller_shop_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/offer_model.dart';

class ListingDetailScreen extends StatefulWidget {
  final ListingModel listing;

  const ListingDetailScreen({super.key, required this.listing});

  @override
  State<ListingDetailScreen> createState() => _ListingDetailScreenState();
}

class _ListingDetailScreenState extends State<ListingDetailScreen> {
  int _currentImageIndex = 0;

  @override
  Widget build(BuildContext context) {
    final item = widget.listing;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined, color: Colors.black),
            onPressed: () {
              // Share item link
            },
          ),
          IconButton(
            icon: const Icon(Icons.favorite_border, color: Colors.black),
            onPressed: () {
              // Add to wishlist/likes
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- 1. Image Slider ---
            Stack(
              children: [
                SizedBox(
                  height: 380,
                  width: double.infinity,
                  child: item.imageUrls.isNotEmpty
                      ? PageView.builder(
                          itemCount: item.imageUrls.length,
                          onPageChanged: (index) {
                            setState(() => _currentImageIndex = index);
                          },
                          itemBuilder: (context, index) {
                            return Image.network(
                              item.imageUrls[index],
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                color: Colors.grey.shade200,
                                child: const Icon(Icons.broken_image, size: 60),
                              ),
                            );
                          },
                        )
                      : Container(
                          color: Colors.grey.shade200,
                          child: const Icon(Icons.image, size: 60),
                        ),
                ),
                // Indicator dots
                if (item.imageUrls.length > 1)
                  Positioned(
                    bottom: 12,
                    left: 0,
                    right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        item.imageUrls.length,
                        (index) => Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _currentImageIndex == index
                                ? const Color(0xFF008080)
                                : Colors.white.withOpacity(0.7),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            // --- 2. Title & Price Section ---
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'R ${item.price.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF008080),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Item specs tags (Size, Brand, Condition)
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _specBadge(Icons.straighten, 'Size: ${item.size}'),
                      _specBadge(Icons.sell_outlined, 'Brand: ${item.brand}'),
                      _specBadge(Icons.verified_outlined, item.condition.label),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Divider(),

                  // --- 3. Description ---
                  const Text(
                    'Description',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item.description,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade800,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Divider(),

                  // --- 4. Delivery Methods ---
                  const Text(
                    'Available Delivery Options',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  ...item.shippingOptions.map(
                    (opt) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Row(
                        children: [
                          const Icon(Icons.local_shipping_outlined, size: 18, color: Color(0xFF008080)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(opt.method, style: const TextStyle(fontSize: 14)),
                          ),
                          Text(
                            'R ${opt.price.toStringAsFixed(2)}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // --- Seller Profile Card (Yaga-style) ---
                  InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SellerShopScreen(
                            sellerId: item.sellerId,
                            shopName: 'Neighbor Closet',
                          ),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        children: [
                          const CircleAvatar(
                            radius: 22,
                            backgroundColor: Color(0xFF008080),
                            child: Icon(Icons.person, color: Colors.white, size: 24),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Neighbor Closet',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                                SizedBox(height: 2),
                                Row(
                                  children: [
                                    Icon(Icons.verified, size: 12, color: Color(0xFF008080)),
                                    SizedBox(width: 3),
                                    Text(
                                      'Verified Resident • 5.0 ⭐ (14 sales)',
                                      style: TextStyle(fontSize: 11, color: Colors.black54),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right, color: Colors.black45),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // --- 5. Buyer Protection Box (Yaga trust guarantee) ---
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE6F2F2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF008080).withOpacity(0.3)),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.shield_outlined, color: Color(0xFF008080), size: 24),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Community Buyer Protection',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF008080),
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Money is held securely in escrow. Funds are only released to the seller after you receive and confirm your item.',
                                style: TextStyle(fontSize: 12, color: Colors.black87),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ],
        ),
      ),

      // --- 6. Bottom Sticky Action Bar ---
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              // "Make an Offer" button
              Expanded(
                flex: 2,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: Color(0xFF008080), width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () {
                    _showMakeOfferDialog(context, item);
                  },
                  child: const Text(
                    'Make Offer',
                    style: TextStyle(
                      color: Color(0xFF008080),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // "Buy Now" button
              Expanded(
                flex: 3,
                // Find the "Buy Now" button inside listing_detail_screen.dart:
child: ElevatedButton(
  style: ElevatedButton.styleFrom(
    backgroundColor: const Color(0xFF008080),
    foregroundColor: Colors.white,
    padding: const EdgeInsets.symmetric(vertical: 14),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
  ),
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CheckoutScreen(listing: item),
      ),
    );
  },
  child: const Text(
    'Buy Now',
    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
  ),
),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _specBadge(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey.shade700),
          const SizedBox(width: 5),
          Text(
            text,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade800, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  void _showMakeOfferDialog(BuildContext context, ListingModel item) {
    final offerController = TextEditingController();
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to make an offer.')),
      );
      return;
    }

    if (currentUser.uid == item.sellerId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You cannot make an offer on your own listing!')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          left: 20,
          right: 20,
          top: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Make an Offer',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              'Listed price: R ${item.price.toStringAsFixed(0)}. Realistic offers (within 20-30%) are most likely to be accepted.',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: offerController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              autofocus: true,
              decoration: const InputDecoration(
                prefixText: 'R ',
                labelText: 'Your Offer (ZAR) *',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF008080),
                  foregroundColor: Colors.white,
                ),
                onPressed: () async {
                  final offeredAmount = double.tryParse(offerController.text.trim()) ?? 0.0;

                  // Minimum offer threshold: at least 40% of listed price
                  if (offeredAmount < (item.price * 0.4) || offeredAmount >= item.price) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Offer must be between R${(item.price * 0.4).toStringAsFixed(0)} and R${(item.price - 1).toStringAsFixed(0)}',
                        ),
                      ),
                    );
                    return;
                  }

                  Navigator.pop(ctx);

                  final offerId = const Uuid().v4();
                  final newOffer = OfferModel(
                    offerId: offerId,
                    listingId: item.id,
                    itemTitle: item.title,
                    itemImageUrl: item.imageUrls.isNotEmpty ? item.imageUrls.first : '',
                    originalPrice: item.price,
                    offeredPrice: offeredAmount,
                    buyerId: currentUser.uid,
                    sellerId: item.sellerId,
                    status: OfferStatus.pending,
                    createdAt: DateTime.now(),
                  );

                  await FirebaseFirestore.instance
                      .collection('offers')
                      .doc(offerId)
                      .set(newOffer.toMap());

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: const Color(0xFF008080),
                        content: Text('Offer of R${offeredAmount.toStringAsFixed(2)} submitted to seller! 🎉'),
                      ),
                    );
                  }
                },
                child: const Text('Send Offer', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}