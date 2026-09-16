import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/offer_model.dart';
import '../models/listing_model.dart';
import 'checkout_screen.dart';

class BuyerOffersScreen extends StatelessWidget {
  const BuyerOffersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        title: const Text('My Sent Offers', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('offers')
            .where('buyerId', isEqualTo: uid)
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
                  Icon(Icons.local_offer_outlined, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 12),
                  const Text('No offers sent yet', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 6),
                  Text('When you make price offers on items, track them here.', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final offer = OfferModel.fromFirestore(docs[index]);

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                child: Padding(
                  padding: const EdgeInsets.all(14),
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
                                Text('Listed: R${offer.originalPrice.toStringAsFixed(0)}', style: TextStyle(color: Colors.grey.shade600, fontSize: 12, decoration: TextDecoration.lineThrough)),
                                Text('Your Offer: R${offer.offeredPrice.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF008080), fontSize: 15)),
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
                      if (offer.status == OfferStatus.accepted) ...[
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700, foregroundColor: Colors.white),
                            onPressed: () async {
                              final doc = await FirebaseFirestore.instance.collection('listings').doc(offer.listingId).get();
                              if (!doc.exists || !context.mounted) return;
                              final raw = ListingModel.fromFirestore(doc);
                              final discounted = ListingModel(
                                id: raw.id,
                                sellerId: raw.sellerId,
                                title: raw.title,
                                description: raw.description,
                                category: raw.category,
                                subCategory: raw.subCategory,
                                size: raw.size,
                                brand: raw.brand,
                                condition: raw.condition,
                                price: offer.offeredPrice,
                                imageUrls: raw.imageUrls,
                                shippingOptions: raw.shippingOptions,
                                createdAt: raw.createdAt,
                              );
                              Navigator.push(context, MaterialPageRoute(builder: (_) => CheckoutScreen(listing: discounted)));
                            },
                            child: Text('Checkout at Offer Price (R${offer.offeredPrice.toStringAsFixed(2)})'),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}