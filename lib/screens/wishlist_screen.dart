import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/listing_model.dart';
import 'listing_detail_screen.dart';
import 'auth_screen.dart';

class WishlistScreen extends StatelessWidget {
  const WishlistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final bool isLoggedIn = user != null && !user.isAnonymous;

    if (!isLoggedIn) {
      return Scaffold(
        backgroundColor: const Color(0xFFF9F9F9),
        appBar: AppBar(
          title: const Text('Liked Items', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
          backgroundColor: Colors.white,
          elevation: 0.5,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.favorite_border, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                const Text('Sign In to View Liked Items', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(
                  'Heart items you love to save them here and track price drops.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF008080), foregroundColor: Colors.white),
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AuthScreen())),
                  child: const Text('Sign In / Register'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        title: const Text('Liked Items ❤️', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('favorites')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF008080)));
          }

          final favoriteDocs = snapshot.data?.docs ?? [];

          if (favoriteDocs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.favorite_border, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 12),
                  const Text('No liked items yet', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 6),
                  Text('Tap the heart icon on any item to save it here.', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                ],
              ),
            );
          }

          final favoriteListingIds = favoriteDocs.map((d) => d.id).toList();

          // Fetch active listings for favorited IDs
          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('listings')
                .where(FieldPath.documentId, whereIn: favoriteListingIds.take(10).toList())
                .snapshots(),
            builder: (context, listingsSnap) {
              if (listingsSnap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: Color(0xFF008080)));
              }

              final listings = listingsSnap.data?.docs ?? [];

              return GridView.builder(
                padding: const EdgeInsets.all(14),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.64,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 12,
                ),
                itemCount: listings.length,
                itemBuilder: (context, index) {
                  final item = ListingModel.fromFirestore(listings[index]);

                  return InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => ListingDetailScreen(listing: item)),
                      );
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 2)),
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
                                  child: item.imageUrls.isNotEmpty
                                      ? Image.network(item.imageUrls.first, fit: BoxFit.cover)
                                      : Container(color: Colors.grey.shade200),
                                ),
                                Positioned(
                                  top: 4,
                                  right: 4,
                                  child: CircleAvatar(
                                    radius: 16,
                                    backgroundColor: Colors.white.withOpacity(0.9),
                                    child: IconButton(
                                      icon: const Icon(Icons.favorite, size: 16, color: Colors.red),
                                      onPressed: () async {
                                        await FirebaseFirestore.instance
                                            .collection('users')
                                            .doc(user.uid)
                                            .collection('favorites')
                                            .doc(item.id)
                                            .delete();
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('R ${item.price.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF008080), fontSize: 14)),
                                Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                Text('${item.brand} • ${item.size}', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
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
          );
        },
      ),
    );
  }
}