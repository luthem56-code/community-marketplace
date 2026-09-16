import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/listing_model.dart';
import 'listing_detail_screen.dart';
import 'seller_shop_screen.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';

  final List<String> _categories = [
    'Women', 'Men', 'Kids & Babies', 'Shoes & Sneakers', 'Accessories & Bags', 'Beauty & Care', 'Home & Living'
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        title: const Text('Explore', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        automaticallyImplyLeading: false,
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF008080),
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
          // 1. EXPLORE BY ITEMS & CATEGORIES
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              ..._categories.map((c) => Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      title: Text(c, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {},
                    ),
                  )),
            ],
          ),

          // 2. EXPLORE BY COMMUNITY SHOPS (YAGA-STYLE SELLER DISCOVERY)
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('users').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: Color(0xFF008080)));
              }

              final users = snapshot.data?.docs ?? [];

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
                      leading: CircleAvatar(
                        backgroundColor: const Color(0xFF008080),
                        child: Text(name.isNotEmpty ? name[0].toUpperCase() : 'S', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                      title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      subtitle: Text('$suburb • ⭐ 5.0 Rating', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                      trailing: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE6F2F2), foregroundColor: const Color(0xFF008080), elevation: 0),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => SellerShopScreen(sellerId: users[index].id, shopName: name)),
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