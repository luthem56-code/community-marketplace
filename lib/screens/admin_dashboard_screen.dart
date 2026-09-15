import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/whatsapp_helper.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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

        // 1. Check if email is in the admin email list
        if (user?.email != null &&
            AdminService.adminEmails.contains(user!.email!.trim().toLowerCase())) {
          isAdmin = true;
        }

        // 2. Check if Firestore role field == 'admin'
        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>?;
          if (data?['role'] == 'admin') {
            isAdmin = true;
          }
        }

        // --- ACCESS DENIED SCREEN (For unauthorized users & guests) ---
        if (!isAdmin) {
          return Scaffold(
            backgroundColor: Colors.white,
            appBar: AppBar(
              title: const Text('Access Restricted'),
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              elevation: 0.5,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.gpp_bad_rounded, size: 72, color: Colors.red),
                    const SizedBox(height: 16),
                    const Text(
                      'Admin Access Required',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'This command center is strictly restricted to platform administrators.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF008080),
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Return to Market'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        // --- AUTHORIZED ADMIN: Renders full command center ---
        return DefaultTabController(
          length: 4,
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
                  Text(
                    'Admin Command Center',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                  ),
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
                ],
              ),
            ),
            body: const TabBarView(
              children: [
                _AdminOverviewTab(),
                _AdminDisputesTab(),
                _AdminPayoutsTab(),
                _AdminListingsTab(),
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

          // Stream calculating live platform earnings and active escrow
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('orders').snapshots(),
            builder: (context, snapshot) {
              double totalRevenue = 0.0; // Buyer protection fees
              double activeEscrow = 0.0;
              int completedOrders = 0;
              int activeDisputes = 0;

              if (snapshot.hasData) {
                for (var doc in snapshot.data!.docs) {
                  final data = doc.data() as Map<String, dynamic>;
                  final status = data['status'] ?? '';
                  final protectionFee = (data['buyerProtectionFee'] as num?)?.toDouble() ?? 0.0;
                  final totalAmount = (data['totalAmount'] as num?)?.toDouble() ?? 0.0;

                  // Earned Revenue from completed or paid orders
                  if (status == 'paidEscrowHeld' || status == 'shipped' || status == 'completed') {
                    totalRevenue += protectionFee;
                  }

                  // Active funds locked in Escrow
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
                      _metricCard(
                        'Platform Revenue',
                        'R ${totalRevenue.toStringAsFixed(2)}',
                        'From Buyer Protection Fees',
                        Colors.green.shade800,
                        Icons.payments_outlined,
                      ),
                      const SizedBox(width: 12),
                      _metricCard(
                        'Escrow Vault',
                        'R ${activeEscrow.toStringAsFixed(2)}',
                        'Locked pending delivery',
                        const Color(0xFF008080),
                        Icons.lock_clock_outlined,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _metricCard(
                        'Orders Completed',
                        '$completedOrders',
                        'Delivered successfully',
                        Colors.blue.shade800,
                        Icons.verified_outlined,
                      ),
                      const SizedBox(width: 12),
                      _metricCard(
                        'Open Disputes',
                        '$activeDisputes',
                        'Requires mediation',
                        activeDisputes > 0 ? Colors.red.shade700 : Colors.grey.shade700,
                        Icons.gavel_outlined,
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),

          // Admin Action Guide
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
                  '3. Take down counterfeit or prohibited clothing listings immediately.',
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
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 6, offset: const Offset(0, 2)),
          ],
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
// 2. DISPUTES MEDIATION TAB (ESCROW OVERRIDE)
// ==========================================
class _AdminDisputesTab extends StatelessWidget {
  const _AdminDisputesTab();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .where('status', isEqualTo: 'disputed')
          .snapshots(),
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
                        Text('DISPUTE ON ORDER #${orderId.substring(0, 8).toUpperCase()}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.red)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(4)),
                          child: const Text('ESCROW FROZEN',
                              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 10)),
                        ),
                      ],
                    ),
                    const Divider(height: 18),

                    // Item info
                    Text(order['itemTitle'] ?? 'Item', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 4),
                    Text('Held in Escrow: R ${totalAmount.toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF008080))),
                    const SizedBox(height: 12),

                    // Contact Cards
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(8)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Buyer: ${order['recipientName']} • Phone: ${order['recipientPhone']}',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 2),
                          Text('Method: ${order['shippingMethod']}', style: TextStyle(fontSize: 11, color: Colors.grey.shade700)),
                          Text('Drop Point/Address: ${order['deliveryDetails']}', style: TextStyle(fontSize: 11, color: Colors.grey.shade700)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ADMIN MEDIATION OVERRIDE BUTTONS
                    Row(
                      children: [
                        // Action A: Force Refund Buyer
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red.shade700,
                              side: BorderSide(color: Colors.red.shade300),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                            icon: const Icon(Icons.undo, size: 16),
                            label: const Text('Refund Buyer', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            onPressed: () => _resolveRefundBuyer(context, orderId, order, totalAmount),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Action B: Force Release to Seller
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green.shade700,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                            icon: const Icon(Icons.check_circle_outline, size: 16),
                            label: const Text('Release to Seller', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            onPressed: () => _resolveReleaseToSeller(context, orderId, order, sellerEarnings),
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

  // Admin resolves dispute by issuing refund to buyer
  void _resolveRefundBuyer(BuildContext context, String orderId, Map<String, dynamic> order, double amount) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Buyer Refund?'),
        content: Text(
          'This will cancel order #$orderId and refund R${amount.toStringAsFixed(2)} to the buyer.\n\nBoth buyer and seller will receive notification.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Issue Refund'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final firestore = FirebaseFirestore.instance;
      await firestore.collection('orders').doc(orderId).update({
        'status': 'cancelled_refunded',
        'resolvedAt': FieldValue.serverTimestamp(),
      });

      // Notify Buyer
      await WhatsAppHelper.sendNotification(
        recipientUserId: order['buyerId'] ?? '',
        title: 'Dispute Resolved: Refund Issued ↩️',
        message: 'Your dispute on "${order['itemTitle']}" was approved. A refund of R${amount.toStringAsFixed(2)} has been processed.',
        type: 'order',
        targetId: orderId,
      );

      // Notify Seller
      await WhatsAppHelper.sendNotification(
        recipientUserId: order['sellerId'] ?? '',
        title: 'Dispute Resolved: Order Cancelled',
        message: 'The dispute on "${order['itemTitle']}" was resolved with a buyer refund. Contact support if you need assistance.',
        type: 'order',
        targetId: orderId,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(backgroundColor: Colors.red, content: Text('Dispute resolved: Buyer refunded.')),
        );
      }
    }
  }

  // Admin resolves dispute by force-releasing funds to seller
  void _resolveReleaseToSeller(BuildContext context, String orderId, Map<String, dynamic> order, double payout) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Release Escrow to Seller?'),
        content: Text(
          'This will mark order #$orderId as completed and credit R${payout.toStringAsFixed(2)} to the seller\'s wallet balance.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Release Funds'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final firestore = FirebaseFirestore.instance;
      final batch = firestore.batch();

      batch.update(firestore.collection('orders').doc(orderId), {
        'status': 'completed',
        'resolvedAt': FieldValue.serverTimestamp(),
      });

      batch.set(
        firestore.collection('wallets').doc(order['sellerId']),
        {'availableBalance': FieldValue.increment(payout)},
        SetOptions(merge: true),
      );

      await batch.commit();

      // Notify Seller
      await WhatsAppHelper.sendNotification(
        recipientUserId: order['sellerId'] ?? '',
        title: 'Dispute Resolved: Funds Released! 💰',
        message: 'Admin mediated the dispute on "${order['itemTitle']}". R${payout.toStringAsFixed(2)} has been credited to your wallet!',
        type: 'wallet',
        targetId: orderId,
      );

      // Notify Buyer
      await WhatsAppHelper.sendNotification(
        recipientUserId: order['buyerId'] ?? '',
        title: 'Dispute Closed',
        message: 'The dispute on "${order['itemTitle']}" was reviewed and concluded. Order is marked completed.',
        type: 'order',
        targetId: orderId,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(backgroundColor: Colors.green, content: Text('Dispute resolved: Funds released to seller wallet!')),
        );
      }
    }
  }
}

// ==========================================
// 3. EFT BANK PAYOUTS TAB (CASHOUT APPROVALS)
// ==========================================
class _AdminPayoutsTab extends StatelessWidget {
  const _AdminPayoutsTab();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('payout_requests')
          .orderBy('createdAt', descending: true)
          .snapshots(),
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
                const SizedBox(height: 4),
                Text('Withdrawal requests from sellers will appear here.', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
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
                        Text(
                          'R ${amount.toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Color(0xFF008080)),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: isPending ? Colors.orange.shade50 : Colors.green.shade50,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            status.toUpperCase(),
                            style: TextStyle(
                              color: isPending ? Colors.orange.shade900 : Colors.green.shade800,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Bank Account Details for EFT
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(8)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Bank: ${p['bankName']} (Branch: ${p['branchCode']})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          const SizedBox(height: 2),
                          Text('Account Holder: ${p['accountHolder']}', style: TextStyle(fontSize: 12, color: Colors.grey.shade800)),
                          Text('Account Number: ${p['accountNumber']}', style: TextStyle(fontSize: 12, color: Colors.grey.shade800, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Mark as Processed Button
                    if (isPending)
                      SizedBox(
                        width: double.infinity,
                        height: 40,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF008080),
                            foregroundColor: Colors.white,
                          ),
                          icon: const Icon(Icons.check, size: 16),
                          label: const Text('Mark as Paid via EFT', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          onPressed: () async {
                            await FirebaseFirestore.instance.collection('payout_requests').doc(payoutId).update({
                              'status': 'completed',
                              'processedAt': FieldValue.serverTimestamp(),
                            });

                            // Notify Seller
                            await WhatsAppHelper.sendNotification(
                              recipientUserId: p['userId'] ?? '',
                              title: 'EFT Payout Sent! 💸',
                              message: 'Your withdrawal of R${amount.toStringAsFixed(2)} to ${p['bankName']} has been processed via EFT.',
                              type: 'wallet',
                              targetId: payoutId,
                            );

                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Payout of R${amount.toStringAsFixed(2)} marked as completed!')),
                              );
                            }
                          },
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
  }
}

// ==========================================
// 4. LISTING MODERATION TAB (TAKEDOWNS)
// ==========================================
class _AdminListingsTab extends StatelessWidget {
  const _AdminListingsTab();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('listings')
          .where('status', isEqualTo: 'active')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFF008080)));
        }

        final listings = snapshot.data?.docs ?? [];

        if (listings.isEmpty) {
          return const Center(child: Text('No active listings to moderate.'));
        }

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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
                  tooltip: 'Take Down Prohibited Listing',
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Take Down Listing?'),
                        content: Text('Remove "${item['title']}" for violating prohibited items or community standards?'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                            onPressed: () => Navigator.pop(ctx, true),
                            child: const Text('Remove Listing'),
                          ),
                        ],
                      ),
                    );

                    if (confirm == true) {
                      await FirebaseFirestore.instance.collection('listings').doc(listingId).delete();

                      // Notify Seller of takedown
                      await WhatsAppHelper.sendNotification(
                        recipientUserId: item['sellerId'] ?? '',
                        title: 'Listing Removed by Moderator ⚠️',
                        message: 'Your listing "${item['title']}" was removed for violating community guidelines.',
                        type: 'general',
                      );

                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Listing taken down successfully.')),
                        );
                      }
                    }
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }
}