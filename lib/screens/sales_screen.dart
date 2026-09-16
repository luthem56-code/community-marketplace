import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'orders_screen.dart';

class SalesScreen extends StatelessWidget {
  const SalesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        title: const Text('My Sales (To Ship)', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        automaticallyImplyLeading: false,
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black),
                onPressed: () => Navigator.pop(context),
              )
            : null,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('orders')
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
                  Icon(Icons.storefront_outlined, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 12),
                  const Text('No sales yet', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 4),
                  Text('When neighbors buy your clothes, orders appear here.', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final orderData = docs[index].data() as Map<String, dynamic>;
              return _SellerOrderCard(
                orderId: docs[index].id,
                order: orderData,
              );
            },
          );
        },
      ),
    );
  }
}

class _SellerOrderCard extends StatelessWidget {
  const _SellerOrderCard({required this.orderId, required this.order});

  final String orderId;
  final Map<String, dynamic> order;

  @override
  Widget build(BuildContext context) {
    final itemName = order['itemName'] ?? order['productName'] ?? 'Order';
    final status = order['status'] ?? 'Pending';
    final amount = order['amount'] ?? order['totalPrice'];

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: Color(0xFFE0F2F1),
          child: Icon(Icons.shopping_bag_outlined, color: Color(0xFF008080)),
        ),
        title: Text('$itemName', style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('Order $orderId\nStatus: $status'),
        isThreeLine: true,
        trailing: amount == null
            ? null
            : Text('\$$amount', style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }
}