import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/listing_model.dart';
import 'wallet_screen.dart';
import 'help_center_screen.dart';
import 'listing_detail_screen.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _deleteListing(String listingId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Listing?'),
        content: const Text('Are you sure you want to remove this item from your wardrobe?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseFirestore.instance.collection('listings').doc(listingId).delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Item deleted successfully')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final currentUserId = user?.uid ?? '';
    final displayName = user?.displayName ?? 'PMB Community Member';
    final email = user?.email ?? 'Verified Resident';

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'My Closet & Profile',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        // Inside AppBar actions of user_profile_screen.dart:
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline, color: Colors.black),
            tooltip: 'Help & Guides',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const HelpCenterScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.black),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Settings & Profile Editing coming soon!')),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // --- 1. User Credibility Header ---
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 34,
                        backgroundColor: const Color(0xFF008080),
                        child: Text(
                          displayName.isNotEmpty ? displayName[0].toUpperCase() : 'M',
                          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              displayName,
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              email,
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
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
                                  Icon(Icons.verified, size: 13, color: Color(0xFF008080)),
                                  SizedBox(width: 4),
                                  Text(
                                    'Verified PMB Member',
                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF008080)),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // --- 2. Compact Wallet Mini-Card ---
                  StreamBuilder<DocumentSnapshot>(
                    stream: FirebaseFirestore.instance.collection('wallets').doc(currentUserId).snapshots(),
                    builder: (context, snapshot) {
                      double balance = 0.0;
                      if (snapshot.hasData && snapshot.data!.exists) {
                        final data = snapshot.data!.data() as Map<String, dynamic>;
                        balance = (data['availableBalance'] as num?)?.toDouble() ?? 0.0;
                      }

                      return Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF008080), Color(0xFF005959)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Wallet Balance', style: TextStyle(color: Colors.white70, fontSize: 12)),
                                const SizedBox(height: 4),
                                Text(
                                  'R ${balance.toStringAsFixed(2)}',
                                  style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: const Color(0xFF008080),
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              ),
                              icon: const Icon(Icons.arrow_circle_up, size: 16),
                              label: const Text('Withdraw', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const WalletScreen()),
                                );
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            // --- 3. Wardrobe Tabs: Active vs Sold ---
            Container(
              color: Colors.white,
              child: TabBar(
                controller: _tabController,
                labelColor: const Color(0xFF008080),
                unselectedLabelColor: Colors.grey.shade600,
                indicatorColor: const Color(0xFF008080),
                indicatorWeight: 3,
                tabs: const [
                  Tab(text: 'Active Listings'),
                  Tab(text: 'Sold Items'),
                ],
              ),
            ),

            // --- 4. Listings Manager Grid ---
            SizedBox(
              height: 520,
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Tab A: Active Listings
                  _buildListingsStream(currentUserId, 'active'),

                  // Tab B: Sold Items
                  _buildListingsStream(currentUserId, 'sold'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListingsStream(String userId, String status) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('listings')
          .where('sellerId', isEqualTo: userId)
          .where('status', isEqualTo: status)
          .snapshots(),
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
                Icon(
                  status == 'active' ? Icons.checkroom_outlined : Icons.inventory_2_outlined,
                  size: 54,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 10),
                Text(
                  status == 'active' ? 'No active listings in your closet' : 'No sold items yet',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const SizedBox(height: 4),
                Text(
                  status == 'active' ? 'Tap (+) to list pre-loved clothes or items!' : 'Completed sales will appear here.',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
              ],
            ),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.all(12),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.62,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final item = ListingModel.fromFirestore(docs[index]);

            return Card(
              elevation: 0.5,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              clipBehavior: Clip.antiAlias,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image
                  Expanded(
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: item.imageUrls.isNotEmpty
                              ? Image.network(item.imageUrls.first, fit: BoxFit.cover)
                              : Container(color: Colors.grey.shade200),
                        ),
                        if (status == 'active')
                          Positioned(
                            top: 4,
                            right: 4,
                            child: CircleAvatar(
                              radius: 16,
                              backgroundColor: Colors.white.withOpacity(0.9),
                              child: IconButton(
                                icon: const Icon(Icons.delete_outline, size: 16, color: Colors.red),
                                onPressed: () => _deleteListing(item.id),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Item Details & View Button
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'R ${item.price.toStringAsFixed(0)}',
                          style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF008080), fontSize: 14),
                        ),
                        Text(
                          item.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                        const SizedBox(height: 6),
                        SizedBox(
                          width: double.infinity,
                          height: 30,
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              padding: EdgeInsets.zero,
                              side: const BorderSide(color: Color(0xFF008080)),
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => ListingDetailScreen(listing: item)),
                              );
                            },
                            child: const Text('View', style: TextStyle(fontSize: 11, color: Color(0xFF008080))),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}