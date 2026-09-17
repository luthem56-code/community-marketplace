import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/offer_model.dart';
import '../services/whatsapp_helper.dart';
import '../services/sound_service.dart';

class SellerOffersScreen extends StatelessWidget {
  const SellerOffersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        title: const Text('Offers Received (Seller)', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
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
            .where('sellerId', isEqualTo: uid)
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
                  const Text('No offers received yet', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 6),
                  Text('When community buyers negotiate on your items, review them here.', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final offer = OfferModel.fromFirestore(docs[index]);
              final isPending = offer.status == OfferStatus.pending;

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
                                Text('Listed Price: R${offer.originalPrice.toStringAsFixed(0)}', style: TextStyle(color: Colors.grey.shade600, fontSize: 12, decoration: TextDecoration.lineThrough)),
                                Text('Buyer Offered: R${offer.offeredPrice.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF008080), fontSize: 15)),
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
                      if (isPending) ...[
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(foregroundColor: Colors.red, side: const BorderSide(color: Colors.red)),
                                onPressed: () async {
                                  await FirebaseFirestore.instance.collection('offers').doc(offer.offerId).update({'status': 'declined'});
                                  SoundService.playChime();
                                  await WhatsAppHelper.sendNotification(
                                    recipientUserId: offer.buyerId,
                                    title: 'Offer Declined',
                                    message: 'The seller was unable to accept your offer of R${offer.offeredPrice.toStringAsFixed(0)} on "${offer.itemTitle}".',
                                    type: 'offer',
                                  );
                                },
                                child: const Text('Decline'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF008080), foregroundColor: Colors.white),
                                onPressed: () async {
                                  await FirebaseFirestore.instance.collection('offers').doc(offer.offerId).update({'status': 'accepted'});
                                  SoundService.playSuccess();
                                  await WhatsAppHelper.sendNotification(
                                    recipientUserId: offer.buyerId,
                                    title: 'Offer Accepted! 🎉',
                                    message: 'The seller accepted your offer of R${offer.offeredPrice.toStringAsFixed(0)} on "${offer.itemTitle}". Open app to checkout.',
                                    type: 'offer',
                                    targetId: offer.listingId,
                                  );
                                },
                                child: const Text('Accept Offer'),
                              ),
                            ),
                          ],
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