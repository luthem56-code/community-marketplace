import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import 'auth_screen.dart';
import 'main_navigation_shell.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  final Map<String, String> _saBanks = {
    'Capitec Bank': '470010',
    'FNB (First National Bank)': '250655',
    'Standard Bank': '051001',
    'Nedbank': '198765',
    'ABSA Bank': '632005',
    'TymeBank': '678910',
    'Discovery Bank': '679000',
    'African Bank': '430000',
  };

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final bool isLoggedIn = user != null && !user.isAnonymous;

    // --- CASE 1: LOGGED OUT (Guards against empty ID crash) ---
    if (!isLoggedIn) {
      return Scaffold(
        backgroundColor: Colors.grey.shade50,
        appBar: AppBar(
          title: const Text('My Wallet', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
          backgroundColor: Colors.white,
          elevation: 0.5,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () {
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              } else {
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MainNavigationShell()));
              }
            },
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.account_balance_wallet_outlined, size: 64, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                const Text('Sign In to View Wallet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(
                  'Log in to view your available escrow balance and cash out directly to your South African bank account.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF008080),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  onPressed: () async {
                    final loggedIn = await Navigator.push<bool>(
                      context,
                      MaterialPageRoute(builder: (_) => const AuthScreen()),
                    );
                    if (loggedIn == true && mounted) setState(() {});
                  },
                  child: const Text('Sign In / Create Account', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // --- CASE 2: LOGGED IN (Safe user ID guaranteed) ---
    final currentUserId = user.uid;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('My Wallet', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MainNavigationShell()));
            }
          },
        ),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('wallets').doc(currentUserId).snapshots(),
        builder: (context, snapshot) {
          double availableBalance = 0.0;

          if (snapshot.hasData && snapshot.data!.exists) {
            final data = snapshot.data!.data() as Map<String, dynamic>;
            availableBalance = (data['availableBalance'] as num?)?.toDouble() ?? 0.0;
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Balance Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF008080), Color(0xFF004D40)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF008080).withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.account_balance_wallet, color: Colors.white70, size: 20),
                          SizedBox(width: 8),
                          Text('Available Balance', style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'R ${availableBalance.toStringAsFixed(2)}',
                        style: const TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 46,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF008080),
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          icon: const Icon(Icons.arrow_circle_up, size: 20),
                          label: const Text('Withdraw to SA Bank Account', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          onPressed: availableBalance > 0
                              ? () => _showWithdrawSheet(context, availableBalance, currentUserId)
                              : () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('No available funds to withdraw yet.')),
                                  );
                                },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // 2. Info Banner
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue, size: 22),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Payouts are processed directly via EFT to any registered South African bank account within 24-48 business hours.',
                          style: TextStyle(fontSize: 12, color: Colors.black87),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // 3. Withdrawal History
                const Text('Withdrawal History', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),

                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('payout_requests')
                      .where('userId', isEqualTo: currentUserId)
                      .snapshots(),
                  builder: (context, payoutSnap) {
                    if (payoutSnap.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator(color: Color(0xFF008080)));
                    }

                    final payouts = payoutSnap.data?.docs ?? [];

                    if (payouts.isEmpty) {
                      return Container(
                        padding: const EdgeInsets.all(32),
                        alignment: Alignment.center,
                        child: Column(
                          children: [
                            Icon(Icons.history, size: 48, color: Colors.grey.shade400),
                            const SizedBox(height: 8),
                            Text('No withdrawals yet', style: TextStyle(color: Colors.grey.shade600)),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: payouts.length,
                      itemBuilder: (context, index) {
                        final pData = payouts[index].data() as Map<String, dynamic>;
                        final amount = (pData['amount'] as num?)?.toDouble() ?? 0.0;
                        final status = pData['status'] ?? 'pending';

                        return Card(
                          elevation: 0.5,
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: const CircleAvatar(
                              backgroundColor: Color(0xFFE6F2F2),
                              child: Icon(Icons.outbox, color: Color(0xFF008080), size: 20),
                            ),
                            title: Text('Payout to ${pData['bankName']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            subtitle: Text('Acc: •••• ${pData['accountNumber'].toString().substring(pData['accountNumber'].toString().length > 4 ? pData['accountNumber'].toString().length - 4 : 0)}'),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text('- R ${amount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                Text(
                                  status.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: status == 'completed' ? Colors.green : Colors.orange.shade800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showWithdrawSheet(BuildContext context, double currentBalance, String userId) {
    String selectedBank = _saBanks.keys.first;
    final accountHolderCtrl = TextEditingController();
    final accountNumberCtrl = TextEditingController();
    final amountCtrl = TextEditingController(text: currentBalance.toStringAsFixed(2));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => StatefulBuilder(
        builder: (sheetContext, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 20,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Cash Out to Bank', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('Available balance: R${currentBalance.toStringAsFixed(2)}', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedBank,
                  decoration: const InputDecoration(labelText: 'South African Bank *', border: OutlineInputBorder()),
                  items: _saBanks.keys.map((bank) => DropdownMenuItem(value: bank, child: Text(bank))).toList(),
                  onChanged: (val) {
                    if (val != null) setModalState(() => selectedBank = val);
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: accountHolderCtrl,
                  decoration: const InputDecoration(labelText: 'Account Holder Full Name *', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: accountNumberCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Account Number *', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: amountCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(prefixText: 'R ', labelText: 'Withdrawal Amount (ZAR) *', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF008080), foregroundColor: Colors.white),
                    onPressed: () async {
                      final withdrawAmount = double.tryParse(amountCtrl.text.trim()) ?? 0.0;
                      if (accountHolderCtrl.text.trim().isEmpty || accountNumberCtrl.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all bank details')));
                        return;
                      }
                      if (withdrawAmount <= 0 || withdrawAmount > currentBalance) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid withdrawal amount')));
                        return;
                      }

                      Navigator.pop(ctx);
                      final firestore = FirebaseFirestore.instance;
                      final payoutId = const Uuid().v4();
                      final batch = firestore.batch();

                      final payoutRef = firestore.collection('payout_requests').doc(payoutId);
                      batch.set(payoutRef, {
                        'payoutId': payoutId,
                        'userId': userId,
                        'amount': withdrawAmount,
                        'bankName': selectedBank,
                        'branchCode': _saBanks[selectedBank],
                        'accountHolder': accountHolderCtrl.text.trim(),
                        'accountNumber': accountNumberCtrl.text.trim(),
                        'status': 'pending',
                        'createdAt': FieldValue.serverTimestamp(),
                      });

                      final walletRef = firestore.collection('wallets').doc(userId);
                      batch.update(walletRef, {'availableBalance': FieldValue.increment(-withdrawAmount)});
                      await batch.commit();

                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Withdrawal of R${withdrawAmount.toStringAsFixed(2)} submitted!')),
                        );
                      }
                    },
                    child: const Text('Confirm Cashout', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}