import 'package:community_marketplace/widgets/user_avatar.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/listing_model.dart';
import 'listing_detail_screen.dart';

class SellerShopScreen extends StatelessWidget {
  final String sellerId;
  final String? shopName;

  const SellerShopScreen({
    super.key,
    required this.sellerId,
    this.shopName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          shopName ?? 'Community Closet',
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black, fontSize: 16),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined, color: Colors.black),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // --- 1. Seller Header & Credibility Box ---
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 34,
                        backgroundColor: const Color(0xFF008080),
                        child: Text(
                          (shopName != null && shopName!.isNotEmpty)
                              ? shopName![0].toUpperCase()
                              : 'S',
                          style: const TextStyle(fontSize: 26, color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              shopName ?? 'Neighbor Closet',
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.star, color: Colors.amber, size: 16),
                                const SizedBox(width: 4),
                                const Text(
                                  '5.0',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '(14 sales)',
                                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE6F2F2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.verified, size: 12, color: Color(0xFF008080)),
                                  SizedBox(width: 4),
                                  Text(
                                    'Verified Community Resident',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF008080),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // --- 2. Yaga-style "Bundle & Save" Banner ---
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [const Color(0xFF008080).withOpacity(0.08), Colors.teal.shade50],
                      ),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF008080).withOpacity(0.2)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.inventory_2_outlined, color: Color(0xFF008080), size: 24),
                        SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Bundle & Save on Courier!',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF008080),
                                  fontSize: 13,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Buy 2 or more items from this member and pay only one single delivery fee.',
                                style: TextStyle(fontSize: 11, color: Colors.black87),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, thickness: 1),

            // --- 3. Seller's Active Closet Grid ---
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  const Text(
                    'Wardrobe & Listings',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('listings')
                        .where('sellerId', isEqualTo: sellerId)
                        .where('status', isEqualTo: 'active')
                        .snapshots(),
                    builder: (context, snap) {
                      final count = snap.data?.docs.length ?? 0;
                      return Text(
                        '$count items available',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                      );
                    },
                  ),
                ],
              ),
            ),

            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('listings')
                  .where('sellerId', isEqualTo: sellerId)
                  .where('status', isEqualTo: 'active')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Center(child: CircularProgressIndicator(color: Color(0xFF008080))),
                  );
                }

                final docs = snapshot.data?.docs ?? [];

                if (docs.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(40),
                    child: Column(
                      children: [
                        Icon(Icons.checkroom_outlined, size: 50, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        const Text(
                          'No other active items in this closet right now.',
                          style: TextStyle(color: Colors.black54, fontSize: 14),
                        ),
                      ],
                    ),
                  );
                }

                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(12),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.65,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final item = ListingModel.fromFirestore(docs[index]);
                    // Seller Shop Card with REAL Profile Photo!
                          return InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => SellerShopScreen(
                                    sellerId: item.sellerId,
                                    shopName: shopName,
                                  ),
                                ),
                              );
                            },
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey.shade200)),
                              child: Row(
                                children: [
                                  UserAvatar(
                                    photoUrl: null,
                                    name: shopName ?? 'Neighbor Closet',
                                    radius: 22,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          shopName ?? 'Neighbor Closet',
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                        ),
                                        const SizedBox(height: 2),
                                        const Text('Verified Resident • ⭐ 5.0 Rating', style: TextStyle(fontSize: 11, color: Colors.black54)),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.chevron_right, color: Colors.black45),
                                ],
                              ),
                            ),
                          );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}