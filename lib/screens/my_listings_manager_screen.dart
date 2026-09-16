import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/listing_model.dart';
import 'listing_detail_screen.dart';
import 'create_listing_screen.dart';

class MyListingsManagerScreen extends StatefulWidget {
  const MyListingsManagerScreen({super.key});

  @override
  State<MyListingsManagerScreen> createState() => _MyListingsManagerScreenState();
}

class _MyListingsManagerScreenState extends State<MyListingsManagerScreen> with SingleTickerProviderStateMixin {
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

  void _editPriceDialog(BuildContext context, String listingId, double currentPrice) {
    final priceCtrl = TextEditingController(text: currentPrice.toStringAsFixed(0));
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Listing Price'),
        content: TextField(
          controller: priceCtrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(prefixText: 'R ', labelText: 'New Price (ZAR) *', border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF008080), foregroundColor: Colors.white),
            onPressed: () async {
              final newP = double.tryParse(priceCtrl.text.trim());
              if (newP != null && newP > 0) {
                await FirebaseFirestore.instance.collection('listings').doc(listingId).update({'price': newP});
                if (context.mounted) Navigator.pop(ctx);
              }
            },
            child: const Text('Update Price'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        title: const Text('My Shop Listings', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF008080),
          indicatorColor: const Color(0xFF008080),
          tabs: const [
            Tab(text: 'Active Listings'),
            Tab(text: 'Sold / Archived'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildListings(uid, 'active'),
          _buildListings(uid, 'sold'),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF008080),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_a_photo),
        label: const Text('Add Item'),
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateListingScreen())),
      ),
    );
  }

  Widget _buildListings(String uid, String status) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('listings')
          .where('sellerId', isEqualTo: uid)
          .where('status', isEqualTo: status)
          .snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFF008080)));
        }

        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(status == 'active' ? Icons.checkroom_outlined : Icons.inventory_2_outlined, size: 60, color: Colors.grey.shade400),
                const SizedBox(height: 12),
                Text(status == 'active' ? 'Your shop has no active listings' : 'No sold items yet', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 80),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final item = ListingModel.fromFirestore(docs[index]);

            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: item.imageUrls.isNotEmpty
                          ? Image.network(item.imageUrls.first, width: 70, height: 70, fit: BoxFit.cover)
                          : Container(width: 70, height: 70, color: Colors.grey.shade200),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), maxLines: 1),
                          Text('R ${item.price.toStringAsFixed(0)} • ${item.brand}', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF008080))),
                          Text('Size: ${item.size}', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                        ],
                      ),
                    ),
                    PopupMenuButton<String>(
                      onSelected: (val) async {
                        if (val == 'view') {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => ListingDetailScreen(listing: item)));
                        } else if (val == 'price') {
                          _editPriceDialog(context, item.id, item.price);
                        } else if (val == 'mark_sold') {
                          await FirebaseFirestore.instance.collection('listings').doc(item.id).update({'status': 'sold'});
                        } else if (val == 'delete') {
                          await FirebaseFirestore.instance.collection('listings').doc(item.id).delete();
                        }
                      },
                      itemBuilder: (_) => [
                        const PopupMenuItem(value: 'view', child: Text('👁️ View Listing')),
                        if (status == 'active') const PopupMenuItem(value: 'price', child: Text('🏷️ Edit Price')),
                        if (status == 'active') const PopupMenuItem(value: 'mark_sold', child: Text('✅ Mark as Sold')),
                        const PopupMenuItem(value: 'delete', child: Text('🗑️ Delete Item', style: TextStyle(color: Colors.red))),
                      ],
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