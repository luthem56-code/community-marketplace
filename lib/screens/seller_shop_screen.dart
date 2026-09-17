import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/listing_model.dart';
import '../widgets/user_avatar.dart';
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
            // Header with Real Avatar & Bio
            StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance.collection('users').doc(sellerId).snapshots(),
              builder: (context, userSnap) {
                String name = shopName ?? 'Neighbor Closet';
                String? photoUrl;
                String suburb = 'Pietermaritzburg';
                String bio = 'Welcome to my community wardrobe!';

                if (userSnap.hasData && userSnap.data!.exists) {
                  final data = userSnap.data!.data() as Map<String, dynamic>?;
                  name = data?['displayName'] ?? name;
                  photoUrl = data?['photoUrl'];
                  suburb = data?['suburb'] ?? suburb;
                  bio = data?['bio'] ?? bio;
                }

                return Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          UserAvatar(photoUrl: photoUrl, name: name, radius: 34),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.star, color: Colors.amber, size: 16),
                                    const SizedBox(width: 4),
                                    const Text('5.0', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                    const SizedBox(width: 6),
                                    Text('• $suburb', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
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
                      if (bio.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text(bio, style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                      ],
                      const SizedBox(height: 16),
                      // Bundle & Save Banner
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE6F2F2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFF008080).withOpacity(0.3)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.inventory_2_outlined, color: Color(0xFF008080), size: 22),
                            SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Bundle & Save on Courier!',
                                    style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF008080), fontSize: 13),
                                  ),
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
                );
              },
            ),
            const Divider(height: 1, thickness: 1),

            // Closet items header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  const Text('Wardrobe & Listings', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('listings')
                        .where('sellerId', isEqualTo: sellerId)
                        .where('status', isEqualTo: 'active')
                        .snapshots(),
                    builder: (context, snap) {
                      final count = snap.data?.docs.length ?? 0;
                      return Text('$count items available', style: TextStyle(color: Colors.grey.shade600, fontSize: 13));
                    },
                  ),
                ],
              ),
            ),

            // Active Listings Grid (Opaque HitTest ensures reliable taps!)
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
                        const Text('No active items in this closet right now.', style: TextStyle(color: Colors.black54, fontSize: 14)),
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
                    return GestureDetector(
                      behavior: HitTestBehavior.opaque, // Ensures reliable opening
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ListingDetailScreen(listing: item),
                          ),
                        );
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: item.imageUrls.isNotEmpty
                                  ? Image.network(item.imageUrls.first, fit: BoxFit.cover, width: double.infinity)
                                  : Container(color: Colors.grey.shade200),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'R ${item.price.toStringAsFixed(0)}',
                                    style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF008080), fontSize: 15),
                                  ),
                                  Text(
                                    item.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                                  ),
                                  Text(
                                    '${item.brand} • ${item.size}',
                                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                  ),
                                ],
                              ),
                            ),
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