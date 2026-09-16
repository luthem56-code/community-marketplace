import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/admin_service.dart';
import '../services/whatsapp_helper.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final uid = user?.uid ?? '';

    // Route Guard: Real-time verification of admin privileges
    return StreamBuilder<DocumentSnapshot>(
      stream: uid.isNotEmpty
          ? FirebaseFirestore.instance.collection('users').doc(uid).snapshots()
          : null,
      builder: (context, snapshot) {
        bool isAdmin = false;

        if (user?.email != null &&
            AdminService.adminEmails.contains(user!.email!.trim().toLowerCase())) {
          isAdmin = true;
        }

        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>?;
          if (data?['role'] == 'admin') {
            isAdmin = true;
          }
        }

        // ACCESS DENIED for non-admins
        if (!isAdmin) {
          return Scaffold(
            backgroundColor: Colors.white,
            appBar: AppBar(title: const Text('Access Restricted'), elevation: 0.5),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.gpp_bad_rounded, size: 72, color: Colors.red),
                    const SizedBox(height: 16),
                    const Text('Admin Access Required', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(
                      'This command center is strictly restricted to platform administrators.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF008080), foregroundColor: Colors.white),
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Return to Market'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        // 5 TABS: Overview, Disputes, EFT Payouts, Listings, Users & Comms
        return DefaultTabController(
          length: 5,
          child: Scaffold(
            backgroundColor: const Color(0xFFF4F6F8),
            appBar: AppBar(
              backgroundColor: const Color(0xFF1E293B), // Dark navy theme
              foregroundColor: Colors.white,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              title: const Row(
                children: [
                  Icon(Icons.admin_panel_settings, color: Colors.amber, size: 24),
                  SizedBox(width: 8),
                  Text('Admin Command Center', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                ],
              ),
              bottom: const TabBar(
                isScrollable: true,
                indicatorColor: Colors.amber,
                indicatorWeight: 3,
                labelColor: Colors.amber,
                unselectedLabelColor: Colors.white70,
                tabs: [
                  Tab(icon: Icon(Icons.dashboard_outlined, size: 18), text: 'Overview'),
                  Tab(icon: Icon(Icons.warning_amber_rounded, size: 18), text: 'Disputes'),
                  Tab(icon: Icon(Icons.account_balance_outlined, size: 18), text: 'EFT Payouts'),
                  Tab(icon: Icon(Icons.inventory_2_outlined, size: 18), text: 'Listings'),
                  Tab(icon: Icon(Icons.people_outline, size: 18), text: 'Users & Comms'),
                ],
              ),
            ),
            body: const TabBarView(
              children: [
                _AdminOverviewTab(),
                _AdminDisputesTab(),
                _AdminPayoutsTab(),
                _AdminListingsTab(),
                _AdminUsersAndCommsTab(), // NEW!
              ],
            ),
          ),
        );
      },
    );
  }
}

// ==========================================
// 1. OVERVIEW & METRICS TAB
// ==========================================
class _AdminOverviewTab extends StatelessWidget {
  const _AdminOverviewTab();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Live Financial Overview', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('orders').snapshots(),
            builder: (context, snapshot) {
              double totalRevenue = 0.0;
              double activeEscrow = 0.0;
              int completedOrders = 0;
              int activeDisputes = 0;

              if (snapshot.hasData) {
                for (var doc in snapshot.data!.docs) {
                  final data = doc.data() as Map<String, dynamic>;
                  final status = data['status'] ?? '';
                  final protectionFee = (data['buyerProtectionFee'] as num?)?.toDouble() ?? 0.0;
                  final totalAmount = (data['totalAmount'] as num?)?.toDouble() ?? 0.0;

                  if (status == 'paidEscrowHeld' || status == 'shipped' || status == 'completed') {
                    totalRevenue += protectionFee;
                  }
                  if (status == 'paidEscrowHeld' || status == 'shipped' || status == 'disputed') {
                    activeEscrow += totalAmount;
                  }
                  if (status == 'completed') completedOrders++;
                  if (status == 'disputed') activeDisputes++;
                }
              }

              return Column(
                children: [
                  Row(
                    children: [
                      _metricCard('Platform Revenue', 'R ${totalRevenue.toStringAsFixed(2)}', 'Buyer Protection Fees', Colors.green.shade800, Icons.payments_outlined),
                      const SizedBox(width: 12),
                      _metricCard('Escrow Vault', 'R ${activeEscrow.toStringAsFixed(2)}', 'Locked pending delivery', const Color(0xFF008080), Icons.lock_clock_outlined),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _metricCard('Orders Completed', '$completedOrders', 'Delivered successfully', Colors.blue.shade800, Icons.verified_outlined),
                      const SizedBox(width: 12),
                      _metricCard('Open Disputes', '$activeDisputes', 'Requires mediation', activeDisputes > 0 ? Colors.red.shade700 : Colors.grey.shade700, Icons.gavel_outlined),
                    ],
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.amber.shade300),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.shield_outlined, color: Colors.amber, size: 22),
                    SizedBox(width: 8),
                    Text('Platform Mediator Responsibilities', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  ],
                ),
                SizedBox(height: 8),
                Text(
                  '1. Review open disputes within 24 hours to prevent buyer frustration.\n'
                  '2. Process bank EFT payouts daily using your business banking portal.\n'
                  '3. Use the "Users & Comms" tab to broadcast community updates or message members directly.',
                  style: TextStyle(fontSize: 12, height: 1.4, color: Colors.black87),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Widget _metricCard(String title, String value, String subtitle, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: TextStyle(color: Colors.grey.shade600, fontSize: 11, fontWeight: FontWeight.bold)),
                Icon(icon, color: color, size: 20),
              ],
            ),
            const SizedBox(height: 8),
            Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: color)),
            const SizedBox(height: 4),
            Text(subtitle, style: TextStyle(color: Colors.grey.shade500, fontSize: 10), maxLines: 1),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 2. DISPUTES MEDIATION TAB
// ==========================================
class _AdminDisputesTab extends StatelessWidget {
  const _AdminDisputesTab();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('orders').where('status', isEqualTo: 'disputed').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFF008080)));
        }

        final disputedOrders = snapshot.data?.docs ?? [];
        if (disputedOrders.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.verified_user_outlined, size: 64, color: Colors.green.shade400),
                const SizedBox(height: 12),
                const Text('Zero Open Disputes! 🎉', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Text('All community orders are running smoothly.', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: disputedOrders.length,
          itemBuilder: (context, index) {
            final orderDoc = disputedOrders[index];
            final order = orderDoc.data() as Map<String, dynamic>;
            final orderId = orderDoc.id;
            final itemPrice = (order['itemPrice'] as num?)?.toDouble() ?? 0.0;
            final shippingFee = (order['shippingFee'] as num?)?.toDouble() ?? 0.0;
            final sellerEarnings = itemPrice + shippingFee;
            final totalAmount = (order['totalAmount'] as num?)?.toDouble() ?? 0.0;

            return Card(
              elevation: 1,
              margin: const EdgeInsets.only(bottom: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('DISPUTE ON ORDER #${orderId.substring(0, 8).toUpperCase()}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.red)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(4)),
                          child: const Text('ESCROW FROZEN', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 10)),
                        ),
                      ],
                    ),
                    const Divider(height: 18),
                    Text(order['itemTitle'] ?? 'Item', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 4),
                    Text('Held in Escrow: R ${totalAmount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF008080))),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(8)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Buyer: ${order['recipientName']} • Phone: ${order['recipientPhone']}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                          Text('Method: ${order['shippingMethod']}', style: TextStyle(fontSize: 11, color: Colors.grey.shade700)),
                          Text('Drop Point/Address: ${order['deliveryDetails']}', style: TextStyle(fontSize: 11, color: Colors.grey.shade700)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(foregroundColor: Colors.red.shade700, side: BorderSide(color: Colors.red.shade300)),
                            icon: const Icon(Icons.undo, size: 16),
                            label: const Text('Refund Buyer', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            onPressed: () async {
                              await FirebaseFirestore.instance.collection('orders').doc(orderId).update({'status': 'cancelled_refunded'});
                              await WhatsAppHelper.sendNotification(
                                recipientUserId: order['buyerId'] ?? '',
                                title: 'Dispute Approved: Refund Issued ↩️',
                                message: 'Your dispute was approved. A refund of R${totalAmount.toStringAsFixed(2)} has been processed.',
                                type: 'order',
                                targetId: orderId,
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700, foregroundColor: Colors.white),
                            icon: const Icon(Icons.check_circle_outline, size: 16),
                            label: const Text('Release to Seller', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            onPressed: () async {
                              final batch = FirebaseFirestore.instance.batch();
                              batch.update(FirebaseFirestore.instance.collection('orders').doc(orderId), {'status': 'completed'});
                              batch.set(
                                FirebaseFirestore.instance.collection('wallets').doc(order['sellerId']),
                                {'availableBalance': FieldValue.increment(sellerEarnings)},
                                SetOptions(merge: true),
                              );
                              await batch.commit();

                              await WhatsAppHelper.sendNotification(
                                recipientUserId: order['sellerId'] ?? '',
                                title: 'Dispute Resolved: Funds Released! 💰',
                                message: 'R${sellerEarnings.toStringAsFixed(2)} was released to your wallet.',
                                type: 'wallet',
                                targetId: orderId,
                              );
                            },
                          ),
                        ),
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

// ==========================================
// 3. EFT BANK PAYOUTS TAB
// ==========================================
class _AdminPayoutsTab extends StatelessWidget {
  const _AdminPayoutsTab();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('payout_requests').orderBy('createdAt', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFF008080)));
        }

        final payouts = snapshot.data?.docs ?? [];
        if (payouts.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.savings_outlined, size: 60, color: Colors.grey.shade400),
                const SizedBox(height: 12),
                const Text('No Payout Requests', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: payouts.length,
          itemBuilder: (context, index) {
            final pDoc = payouts[index];
            final p = pDoc.data() as Map<String, dynamic>;
            final payoutId = pDoc.id;
            final amount = (p['amount'] as num?)?.toDouble() ?? 0.0;
            final status = p['status'] ?? 'pending';
            final isPending = status == 'pending';

            return Card(
              elevation: 0.5,
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('R ${amount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Color(0xFF008080))),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(color: isPending ? Colors.orange.shade50 : Colors.green.shade50, borderRadius: BorderRadius.circular(4)),
                          child: Text(status.toUpperCase(), style: TextStyle(color: isPending ? Colors.orange.shade900 : Colors.green.shade800, fontWeight: FontWeight.bold, fontSize: 10)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(8)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Bank: ${p['bankName']} (Branch: ${p['branchCode']})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          Text('Account Holder: ${p['accountHolder']}', style: TextStyle(fontSize: 12, color: Colors.grey.shade800)),
                          Text('Account Number: ${p['accountNumber']}', style: TextStyle(fontSize: 12, color: Colors.grey.shade800, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    if (isPending) ...[
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF008080), foregroundColor: Colors.white),
                          icon: const Icon(Icons.check, size: 16),
                          label: const Text('Mark as Paid via EFT'),
                          onPressed: () async {
                            await FirebaseFirestore.instance.collection('payout_requests').doc(payoutId).update({'status': 'completed'});
                            await WhatsAppHelper.sendNotification(
                              recipientUserId: p['userId'] ?? '',
                              title: 'EFT Payout Processed! 💸',
                              message: 'Your withdrawal of R${amount.toStringAsFixed(2)} to ${p['bankName']} has been paid via EFT.',
                              type: 'wallet',
                              targetId: payoutId,
                            );
                          },
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
    );
  }
}

// ==========================================
// 4. LISTINGS MODERATION TAB
// ==========================================
class _AdminListingsTab extends StatelessWidget {
  const _AdminListingsTab();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('listings').where('status', isEqualTo: 'active').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFF008080)));
        }

        final listings = snapshot.data?.docs ?? [];
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: listings.length,
          itemBuilder: (context, index) {
            final doc = listings[index];
            final item = doc.data() as Map<String, dynamic>;
            final listingId = doc.id;
            final imageUrls = List<String>.from(item['imageUrls'] ?? []);

            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: imageUrls.isNotEmpty
                      ? Image.network(imageUrls.first, width: 50, height: 50, fit: BoxFit.cover)
                      : Container(width: 50, height: 50, color: Colors.grey.shade200),
                ),
                title: Text(item['title'] ?? 'Item', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), maxLines: 1),
                subtitle: Text('R ${item['price']} • Category: ${item['category']}', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_forever, color: Colors.red),
                  onPressed: () async => await FirebaseFirestore.instance.collection('listings').doc(listingId).delete(),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// ==========================================
// 5. USERS & DIRECT/BROADCAST COMMS TAB (NEW!)
// ==========================================
class _AdminUsersAndCommsTab extends StatefulWidget {
  const _AdminUsersAndCommsTab();

  @override
  State<_AdminUsersAndCommsTab> createState() => _AdminUsersAndCommsTabState();
}

class _AdminUsersAndCommsTabState extends State<_AdminUsersAndCommsTab> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';

  void _showBroadcastDialog(BuildContext context) {
    String audience = 'All Users'; // 'All Users', 'Sellers Only', 'Buyers Only'
    final titleCtrl = TextEditingController();
    final msgCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          title: const Row(
            children: [
              Icon(Icons.campaign, color: Color(0xFF008080), size: 26),
              SizedBox(width: 8),
              Text('Mass Announcement 📢', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Select Target Audience:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: audience,
                  decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
                  items: const [
                    DropdownMenuItem(value: 'All Users', child: Text('🌐 All Community Members')),
                    DropdownMenuItem(value: 'Sellers Only', child: Text('🏪 Sellers Only (Wardrobe Owners)')),
                    DropdownMenuItem(value: 'Buyers Only', child: Text('🛒 Buyers Only')),
                  ],
                  onChanged: (val) {
                    if (val != null) setDialogState(() => audience = val);
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(labelText: 'Announcement Title *', hintText: 'e.g. Free Pudo Weekend Promo!', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: msgCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Message Body *', hintText: 'Write the message that appears on their phones...', border: OutlineInputBorder()),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF008080), foregroundColor: Colors.white),
              onPressed: () async {
                final title = titleCtrl.text.trim();
                final body = msgCtrl.text.trim();
                if (title.isEmpty || body.isEmpty) return;

                Navigator.pop(ctx);

                // Fetch target users
                Query q = FirebaseFirestore.instance.collection('users');
                final snap = await q.get();

                final batch = FirebaseFirestore.instance.batch();
                for (var doc in snap.docs) {
                  final notifRef = FirebaseFirestore.instance.collection('notifications').doc();
                  batch.set(notifRef, {
                    'id': notifRef.id,
                    'userId': doc.id,
                    'title': '📢 $title',
                    'message': body,
                    'type': 'general',
                    'isRead': false,
                    'createdAt': FieldValue.serverTimestamp(),
                  });
                }
                await batch.commit();

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(backgroundColor: const Color(0xFF008080), content: Text('Announcement broadcasted to ${snap.docs.length} users! 🎉')),
                  );
                }
              },
              child: const Text('Send Broadcast'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDirectMessageDialog(BuildContext context, String targetUserId, String targetUserName) {
    final titleCtrl = TextEditingController(text: 'Message from Admin Support');
    final msgCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Message $targetUserName', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Title', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: msgCtrl, maxLines: 3, decoration: const InputDecoration(labelText: 'Message *', border: OutlineInputBorder())),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF008080), foregroundColor: Colors.white),
            onPressed: () async {
              final msg = msgCtrl.text.trim();
              if (msg.isEmpty) return;
              Navigator.pop(ctx);

              await WhatsAppHelper.sendNotification(
                recipientUserId: targetUserId,
                title: titleCtrl.text.trim(),
                message: msg,
                type: 'general',
              );

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Direct notification sent to $targetUserName!')),
                );
              }
            },
            child: const Text('Send Message'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Top Action Bar: Broadcast Button & Search
        Container(
          color: Colors.white,
          padding: const EdgeInsets.all(14),
          child: Column(
            children: [
              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.amber.shade700, foregroundColor: Colors.white),
                  icon: const Icon(Icons.campaign, size: 20),
                  label: const Text('Send Mass Announcement to Users', style: TextStyle(fontWeight: FontWeight.bold)),
                  onPressed: () => _showBroadcastDialog(context),
                ),
              ),
              const SizedBox(height: 10),
              Container(
                height: 42,
                decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade300)),
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search, size: 20, color: Colors.grey),
                    hintText: 'Search user by name, phone, email, or suburb...',
                    hintStyle: TextStyle(fontSize: 12, color: Colors.grey),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),

        // Stream of All Platform Users
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('users').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: Color(0xFF008080)));
              }

              var users = snapshot.data?.docs ?? [];

              if (_query.isNotEmpty) {
                users = users.where((d) {
                  final data = d.data() as Map<String, dynamic>;
                  final name = (data['displayName'] ?? '').toString().toLowerCase();
                  final email = (data['email'] ?? '').toString().toLowerCase();
                  final phone = (data['phone'] ?? '').toString().toLowerCase();
                  final suburb = (data['suburb'] ?? '').toString().toLowerCase();
                  return name.contains(_query) || email.contains(_query) || phone.contains(_query) || suburb.contains(_query);
                }).toList();
              }

              if (users.isEmpty) {
                return const Center(child: Text('No users found.'));
              }

              return ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: users.length,
                itemBuilder: (context, index) {
                  final doc = users[index];
                  final u = doc.data() as Map<String, dynamic>;
                  final userId = doc.id;
                  final name = u['displayName'] ?? 'Community Member';
                  final email = u['email'] ?? 'No email';
                  final rawPhone = u['phone'] ?? '';
                  final suburb = u['suburb'] ?? 'Pietermaritzburg';
                  final role = u['role'] ?? 'member';

                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: role == 'admin' ? Colors.amber : const Color(0xFF008080),
                                child: Text(name.isNotEmpty ? name[0].toUpperCase() : 'U', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                        if (role == 'admin') ...[
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(color: Colors.amber.shade100, borderRadius: BorderRadius.circular(4)),
                                            child: const Text('ADMIN 👑', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.brown)),
                                          ),
                                        ],
                                      ],
                                    ),
                                    Text('$email • $suburb', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                                    if (rawPhone.isNotEmpty)
                                      Text('Cell: $rawPhone', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF008080))),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          const Divider(height: 1),
                          const SizedBox(height: 8),

                          // 3 Direct Action Buttons for each user
                          Row(
                            children: [
                              // 1. Phone Call
                              Expanded(
                                child: OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.blue.shade800,
                                    side: BorderSide(color: Colors.blue.shade200),
                                    padding: const EdgeInsets.symmetric(vertical: 6),
                                  ),
                                  icon: const Icon(Icons.phone, size: 14),
                                  label: const Text('Call', style: TextStyle(fontSize: 11)),
                                  onPressed: rawPhone.isEmpty
                                      ? null
                                      : () async {
                                          final cleanPhone = rawPhone.replaceAll(RegExp(r'[^0-9]'), '');
                                          final uri = Uri.parse('tel:$cleanPhone');
                                          await launchUrl(uri);
                                        },
                                ),
                              ),
                              const SizedBox(width: 6),

                              // 2. WhatsApp
                              Expanded(
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green.shade700,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(vertical: 6),
                                  ),
                                  icon: const Icon(Icons.chat, size: 14),
                                  label: const Text('WhatsApp', style: TextStyle(fontSize: 11)),
                                  onPressed: rawPhone.isEmpty
                                      ? null
                                      : () async {
                                          String cleanPhone = rawPhone.replaceAll(RegExp(r'[^0-9]'), '');
                                          if (cleanPhone.startsWith('0')) cleanPhone = '27${cleanPhone.substring(1)}';
                                          final uri = Uri.parse('https://wa.me/$cleanPhone?text=Hi%20$name,%20this%20is%20Community%20Market%20Admin');
                                          await launchUrl(uri, mode: LaunchMode.externalApplication);
                                        },
                                ),
                              ),
                              const SizedBox(width: 6),

                              // 3. In-App Notification
                              Expanded(
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF008080),
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(vertical: 6),
                                  ),
                                  icon: const Icon(Icons.notifications_active, size: 14),
                                  label: const Text('In-App', style: TextStyle(fontSize: 11)),
                                  onPressed: () => _showDirectMessageDialog(context, userId, name),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}