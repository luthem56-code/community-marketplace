import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/listing_model.dart';
import '../constants/yaga_categories.dart';
import '../widgets/user_avatar.dart';
import 'listing_detail_screen.dart';
import 'seller_shop_screen.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> with SingleTickerProviderStateMixin {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        title: const Text(
          'Explore',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        automaticallyImplyLeading: false,
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF008080),
          unselectedLabelColor: Colors.black54,
          indicatorColor: const Color(0xFF008080),
          indicatorWeight: 3,
          tabs: const [
            Tab(text: 'Explore Items'),
            Tab(text: 'Community Shops'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // 1. EXPLORE BY COMPLETE CATEGORIES (Tapping category loads live listings!)
          ListView.builder(
            padding: const EdgeInsets.all(14),
            itemCount: YagaCategories.all.length,
            itemBuilder: (context, index) {
              final cat = YagaCategories.all[index];
              final subList = cat['sub'] as List<String>;
              final color = cat['color'] as Color;

              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ExpansionTile(
                  leading: CircleAvatar(
                    backgroundColor: color.withOpacity(0.12),
                    child: Icon(cat['icon'] as IconData, color: color, size: 22),
                  ),
                  title: Text(
                    cat['title'] as String,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  subtitle: Text(
                    '${subList.length} sub-categories',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                  children: [
                    const Divider(height: 1),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: subList.map((sub) {
                          return ActionChip(
                            label: Text(sub, style: const TextStyle(fontSize: 12)),
                            backgroundColor: Colors.grey.shade100,
                            onPressed: () {
                              // Open Filtered Category Feed
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => Scaffold(
                                    backgroundColor: const Color(0xFFF9F9F9),
                                    appBar: AppBar(
                                      title: Text(
                                        sub,
                                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
                                      ),
                                      backgroundColor: Colors.white,
                                      elevation: 0.5,
                                      leading: IconButton(
                                        icon: const Icon(Icons.arrow_back, color: Colors.black),
                                        onPressed: () => Navigator.pop(context),
                                      ),
                                    ),
                                    body: StreamBuilder<QuerySnapshot>(
                                      stream: FirebaseFirestore.instance
                                          .collection('listings')
                                          .where('status', isEqualTo: 'active')
                                          .snapshots(),
                                      builder: (ctx, snap) {
                                        if (snap.connectionState == ConnectionState.waiting) {
                                          return const Center(
                                            child: CircularProgressIndicator(color: Color(0xFF008080)),
                                          );
                                        }

                                        final allListings = snap.data?.docs ?? [];
                                        final filtered = allListings.where((d) {
                                          final data = d.data() as Map<String, dynamic>;
                                          final title = (data['title'] ?? '').toString().toLowerCase();
                                          final desc = (data['description'] ?? '').toString().toLowerCase();
                                          final catName = (data['category'] ?? '').toString().toLowerCase();
                                          final target = sub.toLowerCase();
                                          return title.contains(target) ||
                                              desc.contains(target) ||
                                              catName.contains(target);
                                        }).toList();

                                        if (filtered.isEmpty) {
                                          return Center(
                                            child: Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Icon(Icons.search_off, size: 54, color: Colors.grey.shade400),
                                                const SizedBox(height: 12),
                                                Text(
                                                  'No items found in "$sub"',
                                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  'Be the first to list an item in this category!',
                                                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                                                ),
                                              ],
                                            ),
                                          );
                                        }

                                        return GridView.builder(
                                          padding: const EdgeInsets.all(12),
                                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                            crossAxisCount: 2,
                                            childAspectRatio: 0.64,
                                            crossAxisSpacing: 10,
                                            mainAxisSpacing: 12,
                                          ),
                                          itemCount: filtered.length,
                                          itemBuilder: (c, i) => _CategoryItemCard(
                                            listing: ListingModel.fromFirestore(filtered[i]),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          // 2. EXPLORE BY COMMUNITY SHOPS (YAGA-STYLE SELLER DISCOVERY)
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('users').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: Color(0xFF008080)));
              }

              final users = snapshot.data?.docs ?? [];

              if (users.isEmpty) {
                return const Center(
                  child: Text('No community shops found yet.', style: TextStyle(color: Colors.grey)),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(14),
                itemCount: users.length,
                itemBuilder: (context, index) {
                  final u = users[index].data() as Map<String, dynamic>;
                  final name = u['displayName'] ?? 'Neighbor Closet';
                  final suburb = u['suburb'] ?? 'Pietermaritzburg';

                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ListTile(
                      leading: UserAvatar(
                        photoUrl: u['photoUrl'],
                        name: name,
                        radius: 22,
                      ),
                      title: Text(
                        name,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      subtitle: Text(
                        '$suburb • ⭐ 5.0 Rating',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                      trailing: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE6F2F2),
                          foregroundColor: const Color(0xFF008080),
                          elevation: 0,
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => SellerShopScreen(
                                sellerId: users[index].id,
                                shopName: name,
                              ),
                            ),
                          );
                        },
                        child: const Text('Visit Shop', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

// Self-contained Category Item Card for Explore Page
class _CategoryItemCard extends StatelessWidget {
  final ListingModel listing;
  const _CategoryItemCard({required this.listing});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ListingDetailScreen(listing: listing)),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: listing.imageUrls.isNotEmpty
                        ? Image.network(
                            listing.imageUrls.first,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(color: Colors.grey.shade200),
                          )
                        : Container(color: Colors.grey.shade200),
                  ),
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        listing.size.toUpperCase(),
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'R ${listing.price.toStringAsFixed(0)}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF008080)),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    listing.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  Text(
                    listing.brand,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}