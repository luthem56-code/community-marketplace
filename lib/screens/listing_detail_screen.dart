import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../models/listing_model.dart';
import '../models/offer_model.dart';
import 'checkout_screen.dart';
import 'chat_screen.dart';
import 'seller_shop_screen.dart';
import 'how_it_works_screen.dart';
import 'auth_screen.dart';
import '../services/whatsapp_helper.dart';

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
    final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

    // 1. Stream 1: Check if THIS buyer has an ACCEPTED offer
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('offers')
          .where('listingId', isEqualTo: item.id)
          .where('buyerId', isEqualTo: currentUserId)
          .where('status', isEqualTo: 'accepted')
          .snapshots(),
      builder: (context, offerSnapshot) {
        double effectivePrice = item.price;
        bool hasAcceptedOffer = false;

        if (offerSnapshot.hasData && offerSnapshot.data!.docs.isNotEmpty) {
          final offerData = offerSnapshot.data!.docs.first.data() as Map<String, dynamic>;
          effectivePrice = (offerData['offeredPrice'] as num?)?.toDouble() ?? item.price;
          hasAcceptedOffer = true;
        }

        final activeListing = ListingModel(
          id: item.id,
          sellerId: item.sellerId,
          title: item.title,
          description: item.description,
          category: item.category,
          subCategory: item.subCategory,
          size: item.size,
          brand: item.brand,
          condition: item.condition,
          price: effectivePrice,
          imageUrls: item.imageUrls,
          shippingOptions: item.shippingOptions,
          createdAt: item.createdAt,
        );

        // 2. Stream 2: Check if SELLER is in HOLIDAY MODE
        return StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance.collection('users').doc(item.sellerId).snapshots(),
          builder: (context, sellerSnap) {
            bool isSellerOnHoliday = false;
            if (sellerSnap.hasData && sellerSnap.data!.exists) {
              final data = sellerSnap.data!.data() as Map<String, dynamic>?;
              isSellerOnHoliday = data?['isHolidayMode'] ?? false;
            }

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
                    tooltip: 'Share Item',
                    onPressed: () => _showShareSheet(context, item),
                  ),
                ],
              ),
              body: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- HOLIDAY MODE BANNER (TOP OF LISTING) ---
                    if (isSellerOnHoliday)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        color: Colors.amber.shade100,
                        child: const Row(
                          children: [
                            Icon(Icons.beach_access, color: Colors.orange, size: 22),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                '🌴 Seller is currently on Holiday. Purchases and offers are temporarily paused.',
                                style: TextStyle(color: Color(0xFF78350F), fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Photo Carousel
                    Stack(
                      children: [
                        SizedBox(
                          height: 380,
                          width: double.infinity,
                          child: item.imageUrls.isNotEmpty
                              ? PageView.builder(
                                  itemCount: item.imageUrls.length,
                                  onPageChanged: (index) => setState(() => _currentImageIndex = index),
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
                              : Container(color: Colors.grey.shade200, child: const Icon(Icons.image, size: 60)),
                        ),
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
                                    color: _currentImageIndex == index ? const Color(0xFF008080) : Colors.white.withOpacity(0.7),
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),

                    // Title & Price Section
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (hasAcceptedOffer)
                            Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.green.shade300),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.local_offer, color: Colors.green.shade800, size: 18),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Special Offer Accepted! You save R${(item.price - effectivePrice).toStringAsFixed(0)}',
                                      style: TextStyle(color: Colors.green.shade900, fontWeight: FontWeight.bold, fontSize: 13),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                'R ${effectivePrice.toStringAsFixed(0)}',
                                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Color(0xFF008080)),
                              ),
                              if (hasAcceptedOffer) ...[
                                const SizedBox(width: 10),
                                Text(
                                  'R ${item.price.toStringAsFixed(0)}',
                                  style: TextStyle(fontSize: 18, color: Colors.grey.shade500, decoration: TextDecoration.lineThrough, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(item.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 14),

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

                          const Text('Description', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Text(item.description, style: TextStyle(fontSize: 14, color: Colors.grey.shade800, height: 1.4)),
                          const SizedBox(height: 20),
                          const Divider(),

                          const Text('Available Delivery Options', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 10),
                          ...item.shippingOptions.map(
                            (opt) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4.0),
                              child: Row(
                                children: [
                                  const Icon(Icons.local_shipping_outlined, size: 18, color: Color(0xFF008080)),
                                  const SizedBox(width: 8),
                                  Expanded(child: Text(opt.method, style: const TextStyle(fontSize: 14))),
                                  Text(
                                    opt.price == 0 ? 'FREE' : 'R ${opt.price.toStringAsFixed(2)}',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: opt.price == 0 ? Colors.green.shade800 : Colors.black87),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Seller Shop Card
                          InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => SellerShopScreen(sellerId: item.sellerId, shopName: 'Neighbor Closet'),
                                ),
                              );
                            },
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey.shade200)),
                              child: const Row(
                                children: [
                                  CircleAvatar(radius: 22, backgroundColor: Color(0xFF008080), child: Icon(Icons.person, color: Colors.white, size: 24)),
                                  SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Neighbor Closet', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                        SizedBox(height: 2),
                                        Text('Verified Resident • 5.0 ⭐', style: TextStyle(fontSize: 11, color: Colors.black54)),
                                      ],
                                    ),
                                  ),
                                  Icon(Icons.chevron_right, color: Colors.black45),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Buyer Protection Guarantee
                          InkWell(
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HowItWorksScreen())),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(color: const Color(0xFFE6F2F2), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFF008080).withOpacity(0.3))),
                              child: const Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(Icons.shield_outlined, color: Color(0xFF008080), size: 24),
                                  SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Community Buyer Protection', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF008080))),
                                        SizedBox(height: 2),
                                        Text('Money is held securely in escrow until you confirm delivery.', style: TextStyle(fontSize: 12, color: Colors.black87)),
                                      ],
                                    ),
                                  ),
                                  Icon(Icons.chevron_right, size: 18, color: Color(0xFF008080)),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 30),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // --- BOTTOM BAR: DISABLED IF SELLER IS ON HOLIDAY ---
              bottomNavigationBar: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, -3)),
                  ],
                ),
                child: SafeArea(
                  child: Row(
                    children: [
                      // In-App Chat (Always enabled so buyer can ask questions)
                      IconButton(
                        style: IconButton.styleFrom(
                          side: BorderSide(color: Colors.grey.shade300),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.all(12),
                        ),
                        icon: const Icon(Icons.chat_bubble_outline, color: Color(0xFF008080)),
                        tooltip: 'In-App Chat',
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ChatScreen(
                                listing: item,
                                otherUserId: item.sellerId,
                                otherUserName: 'Seller Closet',
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 6),

                      // WhatsApp Ping
                      IconButton(
                        style: IconButton.styleFrom(
                          backgroundColor: const Color(0xFFE8F5E9),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.all(12),
                        ),
                        icon: const Icon(Icons.chat, color: Colors.green),
                        tooltip: 'Chat on WhatsApp',
                        onPressed: () {
                          WhatsAppHelper.openChat(
                            context: context,
                            rawPhone: '0821234567',
                            itemTitle: item.title,
                            itemPrice: effectivePrice,
                          );
                        },
                      ),
                      const SizedBox(width: 8),

                      // Make Offer Button (Disabled if on holiday)
                      if (!hasAcceptedOffer)
                        Expanded(
                          flex: 2,
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              side: BorderSide(color: isSellerOnHoliday ? Colors.grey : const Color(0xFF008080), width: 1.5),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            onPressed: isSellerOnHoliday
                                ? null
                                : () async {
                                    final user = FirebaseAuth.instance.currentUser;
                                    if (user == null || user.isAnonymous) {
                                      final loggedIn = await Navigator.push<bool>(
                                        context,
                                        MaterialPageRoute(builder: (_) => const AuthScreen()),
                                      );
                                      if (loggedIn != true || !mounted) return;
                                    }
                                    _showMakeOfferDialog(context, item);
                                  },
                            child: Text('Make Offer', style: TextStyle(color: isSellerOnHoliday ? Colors.grey : const Color(0xFF008080), fontWeight: FontWeight.bold)),
                          ),
                        ),
                      if (hasAcceptedOffer) const SizedBox(width: 4),

                      // Buy Now Button (Disabled if on holiday)
                      Expanded(
                        flex: hasAcceptedOffer ? 5 : 3,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isSellerOnHoliday
                                ? Colors.grey.shade400
                                : (hasAcceptedOffer ? Colors.green.shade700 : const Color(0xFF008080)),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: isSellerOnHoliday
                              ? null // PAUSED!
                              : () async {
                                  final user = FirebaseAuth.instance.currentUser;
                                  if (user == null || user.isAnonymous) {
                                    final loggedIn = await Navigator.push<bool>(
                                      context,
                                      MaterialPageRoute(builder: (_) => const AuthScreen()),
                                    );
                                    if (loggedIn != true || !mounted) return;
                                  }

                                  if (!mounted) return;
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => CheckoutScreen(listing: activeListing),
                                    ),
                                  );
                                },
                          child: Text(
                            isSellerOnHoliday
                                ? 'Seller on Holiday 🌴'
                                : (hasAcceptedOffer ? 'Buy at Offer: R${effectivePrice.toStringAsFixed(0)}' : 'Buy Now'),
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
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
          Text(text, style: TextStyle(fontSize: 12, color: Colors.grey.shade800, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  void _showMakeOfferDialog(BuildContext context, ListingModel item) {
    final offerController = TextEditingController();
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please log in first.')));
      return;
    }

    if (currentUser.uid == item.sellerId) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('You cannot make an offer on your own listing!')));
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom + 20, left: 20, right: 20, top: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Make an Offer', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text('Listed price: R ${item.price.toStringAsFixed(0)}. Reasonable offers are more likely to be accepted.', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
            const SizedBox(height: 16),
            TextField(
              controller: offerController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              autofocus: true,
              decoration: const InputDecoration(prefixText: 'R ', labelText: 'Your Offer (ZAR) *', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF008080), foregroundColor: Colors.white),
                onPressed: () async {
                  final offeredAmount = double.tryParse(offerController.text.trim()) ?? 0.0;
                  if (offeredAmount <= 0 || offeredAmount >= item.price) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Offer must be lower than R${item.price.toStringAsFixed(0)}')));
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

                  await FirebaseFirestore.instance.collection('offers').doc(offerId).set(newOffer.toMap());

                  await WhatsAppHelper.sendNotification(
                    recipientUserId: item.sellerId,
                    title: 'New Offer Received! 🏷️',
                    message: 'Someone made an offer of R${offeredAmount.toStringAsFixed(0)} on "${item.title}". Tap to review.',
                    type: 'offer',
                    targetId: offerId,
                  );

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(backgroundColor: const Color(0xFF008080), content: Text('Offer of R${offeredAmount.toStringAsFixed(2)} sent to seller! 🎉')),
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

  void _showShareSheet(BuildContext context, ListingModel item) {
    final shareText = 'Check out "${item.title}" on PMB Community Market for only R${item.price.toStringAsFixed(0)}! 👗👕\n\n100% Escrow Protected with Local PMB Collection & Pudo delivery.';
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Share this Listing', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ListTile(
              leading: const CircleAvatar(backgroundColor: Color(0xFFE6F2F2), child: Icon(Icons.link, color: Color(0xFF008080))),
              title: const Text('Copy Link', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              subtitle: const Text('Copy listing details to clipboard'),
              onTap: () {
                Clipboard.setData(ClipboardData(text: shareText));
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(backgroundColor: Color(0xFF008080), content: Text('Link copied! 📋')));
              },
            ),
            ListTile(
              leading: const CircleAvatar(backgroundColor: Color(0xFFE8F5E9), child: Icon(Icons.chat, color: Colors.green)),
              title: const Text('Share on WhatsApp', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              subtitle: const Text('Send to community & church groups'),
              onTap: () {
                Clipboard.setData(ClipboardData(text: shareText));
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(backgroundColor: Colors.green, content: Text('Text copied! Paste it in your WhatsApp chat.')));
              },
            ),
          ],
        ),
      ),
    );
  }
}