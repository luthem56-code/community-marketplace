import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notification_model.dart';
import 'orders_screen.dart';
import 'wallet_screen.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  IconData _getIcon(String type) {
    switch (type) {
      case 'offer':
        return Icons.local_offer_outlined;
      case 'order':
        return Icons.shopping_bag_outlined;
      case 'shipping':
        return Icons.local_shipping_outlined;
      case 'wallet':
        return Icons.account_balance_wallet_outlined;
      case 'chat':
        return Icons.chat_bubble_outline;
      default:
        return Icons.notifications_none_rounded;
    }
  }

  Color _getColor(String type) {
    switch (type) {
      case 'offer':
        return Colors.orange.shade700;
      case 'order':
        return const Color(0xFF008080);
      case 'shipping':
        return Colors.blue.shade700;
      case 'wallet':
        return Colors.green.shade700;
      default:
        return Colors.grey.shade700;
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        title: const Text('Activity & Notifications', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        automaticallyImplyLeading: false, // Prevents white screen on bottom tab!
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        actions: [
          TextButton(
            onPressed: () async {
              final batch = FirebaseFirestore.instance.batch();
              final unreadSnap = await FirebaseFirestore.instance
                  .collection('notifications')
                  .where('userId', isEqualTo: currentUserId)
                  .where('isRead', isEqualTo: false)
                  .get();

              for (var doc in unreadSnap.docs) {
                batch.update(doc.reference, {'isRead': true});
              }
              await batch.commit();
            },
            child: const Text('Mark all read', style: TextStyle(color: Color(0xFF008080), fontSize: 13)),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('notifications')
            .where('userId', isEqualTo: currentUserId)
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
                  Icon(Icons.notifications_off_outlined, size: 60, color: Colors.grey.shade400),
                  const SizedBox(height: 12),
                  const Text('No notifications yet', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 6),
                  Text('Offers, orders, and courier updates will appear here.', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final notification = NotificationModel.fromFirestore(docs[index]);
              final color = _getColor(notification.type);

              return Card(
                elevation: 0.5,
                margin: const EdgeInsets.only(bottom: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                color: notification.isRead ? Colors.white : const Color(0xFFF0FDF4),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: CircleAvatar(
                    backgroundColor: color.withOpacity(0.12),
                    child: Icon(_getIcon(notification.type), color: color, size: 20),
                  ),
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(notification.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      if (!notification.isRead)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(color: Color(0xFF008080), shape: BoxShape.circle),
                        ),
                    ],
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(notification.message, style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                  ),
                  onTap: () async {
                    // Mark this notification as read
                    await FirebaseFirestore.instance.collection('notifications').doc(notification.id).update({'isRead': true});

                    if (!context.mounted) return;

                    // Navigate to appropriate screen
                    if (notification.type == 'wallet') {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const WalletScreen()));
                    } else if (notification.type == 'order' || notification.type == 'offer' || notification.type == 'shipping') {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const OrdersScreen()));
                    }
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}