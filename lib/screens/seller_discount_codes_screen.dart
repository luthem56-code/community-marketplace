import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SellerDiscountCodesScreen extends StatefulWidget {
  const SellerDiscountCodesScreen({super.key});

  @override
  State<SellerDiscountCodesScreen> createState() => _SellerDiscountCodesScreenState();
}

class _SellerDiscountCodesScreenState extends State<SellerDiscountCodesScreen> {
  void _showCreateCodeDialog(BuildContext context, String uid) {
    final codeCtrl = TextEditingController();
    final discountCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Create Shop Discount Code'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: codeCtrl,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(labelText: 'Code Name *', hintText: 'e.g. SARAH15', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: discountCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Discount Percentage (%) *', hintText: 'e.g. 15', suffixText: '%', border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF008080), foregroundColor: Colors.white),
            onPressed: () async {
              final code = codeCtrl.text.trim().toUpperCase();
              final percent = int.tryParse(discountCtrl.text.trim()) ?? 0;
              if (code.isEmpty || percent <= 0 || percent > 90) return;

              await FirebaseFirestore.instance.collection('discount_codes').add({
                'code': code,
                'sellerId': uid,
                'discountPercent': percent,
                'isActive': true,
                'createdAt': FieldValue.serverTimestamp(),
              });

              if (context.mounted) Navigator.pop(ctx);
            },
            child: const Text('Create Code'),
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
        title: const Text('Shop Discount Codes', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('discount_codes')
            .where('sellerId', isEqualTo: uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF008080)));
          }

          final codes = snapshot.data?.docs ?? [];

          if (codes.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.discount_outlined, size: 60, color: Colors.grey),
                  const SizedBox(height: 12),
                  const Text('No discount codes created yet', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 6),
                  Text('Create codes to share on WhatsApp and boost shop sales.', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: codes.length,
            itemBuilder: (context, index) {
              final c = codes[index].data() as Map<String, dynamic>;
              final id = codes[index].id;

              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFE6F2F2),
                    child: Icon(Icons.discount, color: Color(0xFF008080)),
                  ),
                  title: Text(c['code'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1.1)),
                  subtitle: Text('${c['discountPercent']}% off all items in your shop'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () async => await FirebaseFirestore.instance.collection('discount_codes').doc(id).delete(),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF008080),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('New Code'),
        onPressed: () => _showCreateCodeDialog(context, uid),
      ),
    );
  }
}