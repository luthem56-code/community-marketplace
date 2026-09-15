import 'package:community_marketplace/services/whatsapp_helper.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/dispute_model.dart';

class RaiseDisputeScreen extends StatefulWidget {
  final String orderId;
  final String buyerId;
  final String sellerId;
  final String itemTitle;
  final double totalAmount;

  const RaiseDisputeScreen({
    super.key,
    required this.orderId,
    required this.buyerId,
    required this.sellerId,
    required this.itemTitle,
    required this.totalAmount,
  });

  @override
  State<RaiseDisputeScreen> createState() => _RaiseDisputeScreenState();
}

class _RaiseDisputeScreenState extends State<RaiseDisputeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descController = TextEditingController();
  DisputeReason _selectedReason = DisputeReason.damaged;
  bool _isSubmitting = false;

  Future<void> _submitDispute() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final disputeId = const Uuid().v4();
      final firestore = FirebaseFirestore.instance;

      final dispute = DisputeModel(
        disputeId: disputeId,
        orderId: widget.orderId,
        buyerId: widget.buyerId,
        sellerId: widget.sellerId,
        reason: _selectedReason,
        description: _descController.text.trim(),
        status: 'under_review',
        createdAt: DateTime.now(),
      );

      // Atomic Batch:
      // 1. Create dispute record
      // 2. Set order status to 'disputed' to freeze escrow
      final batch = firestore.batch();

      final disputeRef = firestore.collection('disputes').doc(disputeId);
      batch.set(disputeRef, dispute.toMap());

      final orderRef = firestore.collection('orders').doc(widget.orderId);
      batch.update(orderRef, {'status': 'disputed'});

      await batch.commit();
      // Notify Admin of new dispute
      await WhatsAppHelper.sendNotification(
        recipientUserId: 'admin', // Or your admin user UID
        title: 'URGENT: New Dispute Opened ⚠️',
        message: 'Dispute logged on "${widget.itemTitle}" (R${widget.totalAmount.toStringAsFixed(0)}). Escrow is frozen.',
        type: 'dispute',
        targetId: widget.orderId,
      );

      if (!mounted) return;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: const Row(
            children: [
              Icon(Icons.shield_outlined, color: Colors.orange, size: 26),
              SizedBox(width: 8),
              Text('Escrow Funds Frozen'),
            ],
          ),
          content: Text(
            'Your dispute has been logged. Payout of R${widget.totalAmount.toStringAsFixed(2)} to the seller is now locked.\n\nOur community support team and the seller have been notified to review your claim.',
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF008080),
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pop(context); // Return to Orders screen
              },
              child: const Text('Understood'),
            ),
          ],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to submit dispute: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  void dispose() {
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Report an Issue', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isSubmitting
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF008080)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Trust Banner
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.amber.shade300),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.lock_clock, color: Colors.orange, size: 24),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Submitting this form immediately freezes the seller payout so your money remains protected in escrow.',
                              style: TextStyle(fontSize: 12, color: Colors.black87),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    Text(
                      'Item: ${widget.itemTitle}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    const SizedBox(height: 16),

                    // Reason Selector
                    const Text('What is wrong with the order? *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 8),
                    ...DisputeReason.values.map((reason) {
                      return Card(
                        margin: const EdgeInsets.only(bottom: 6),
                        elevation: 0.5,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(
                            color: _selectedReason == reason ? const Color(0xFF008080) : Colors.transparent,
                            width: 1.5,
                          ),
                        ),
                        child: RadioListTile<DisputeReason>(
                          activeColor: const Color(0xFF008080),
                          title: Text(reason.label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                          value: reason,
                          groupValue: _selectedReason,
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedReason = val);
                          },
                        ),
                      );
                    }),
                    const SizedBox(height: 16),

                    // Description
                    const Text('Describe the issue in detail *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _descController,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        hintText: 'Explain the flaw, missing item, or damage so our support team can verify...',
                        hintStyle: TextStyle(fontSize: 13),
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      validator: (val) => val == null || val.trim().length < 10
                          ? 'Please provide at least 10 characters explaining the issue'
                          : null,
                    ),
                    const SizedBox(height: 24),

                    // Freeze Escrow & Submit Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade700,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        icon: const Icon(Icons.warning_amber_rounded),
                        label: const Text(
                          'Freeze Escrow & Submit Dispute',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        onPressed: _submitDispute,
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}