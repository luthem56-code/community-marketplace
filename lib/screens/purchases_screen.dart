import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'orders_screen.dart';
import 'raise_dispute_screen.dart';

class PurchasesScreen extends StatefulWidget {
  const PurchasesScreen({super.key});

  @override
  State<PurchasesScreen> createState() => _PurchasesScreenState();
}

class _PurchasesScreenState extends State<PurchasesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        title: const Text('My Purchases', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: const Color(0xFF008080),
          unselectedLabelColor: Colors.black54,
          indicatorColor: const Color(0xFF008080),
          indicatorWeight: 3,
          tabs: const [
            Tab(text: 'ALL ORDERS'),
            Tab(text: 'PENDING ITEM'),
            Tab(text: 'COMPLETED'),
            Tab(text: 'CANCELLED'),
          ],
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .where('buyerId', isEqualTo: uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF008080)));
          }

          final allDocs = snapshot.data?.docs ?? [];

          return TabBarView(
            controller: _tabController,
            children: [
              // 1. ALL ORDERS
              _buildOrdersList(allDocs),

              // 2. PENDING ITEM (Paid / In Transit)
              _buildOrdersList(allDocs.where((d) {
                final status = (d.data() as Map<String, dynamic>)['status'] ?? '';
                return status == 'paidEscrowHeld' || status == 'shipped';
              }).toList(), emptyMsg: 'No pending deliveries'),

              // 3. COMPLETED
              _buildOrdersList(allDocs.where((d) {
                final status = (d.data() as Map<String, dynamic>)['status'] ?? '';
                return status == 'completed';
              }).toList(), emptyMsg: 'No completed purchases yet'),

              // 4. CANCELLED / DISPUTED
              _buildOrdersList(allDocs.where((d) {
                final status = (d.data() as Map<String, dynamic>)['status'] ?? '';
                return status == 'cancelled' || status == 'cancelled_refunded' || status == 'disputed';
              }).toList(), emptyMsg: 'No cancelled orders'),
            ],
          );
        },
      ),
    );
  }

  Widget _buildOrdersList(List<QueryDocumentSnapshot> docs, {String emptyMsg = 'No purchases found'}) {
    if (docs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shopping_bag_outlined, size: 60, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(emptyMsg, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 4),
            Text('Items you buy in the community will show here.', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: docs.length,
      itemBuilder: (context, index) {
        final orderData = docs[index].data() as Map<String, dynamic>;
        final orderId = docs[index].id;
        return _OrderCard(orderId: orderId, order: orderData, isSeller: false);
      },
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({
    required this.orderId,
    required this.order,
    required this.isSeller,
  });

  final String orderId;
  final Map<String, dynamic> order;
  final bool isSeller;

  @override
  Widget build(BuildContext context) {
    final title = order['title'] ?? order['itemTitle'] ?? 'Order #$orderId';
    final status = order['status'] ?? 'Unknown';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: const Icon(Icons.shopping_bag_outlined, color: Color(0xFF008080)),
        title: Text(title.toString(), style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('Status: ${status.toString().replaceAll('_', ' ')}'),
      ),
    );
  }
}