import 'package:community_marketplace/services/whatsapp_helper.dart';
import 'package:community_marketplace/widgets/drop_point_map_picker.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../widgets/delivery_info_sheet.dart';
import '../models/listing_model.dart';
import '../models/order_model.dart';

class CheckoutScreen extends StatefulWidget {
  final ListingModel listing;

  const CheckoutScreen({super.key, required this.listing});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();

  late ShippingOption _selectedShipping;
  bool _isProcessing = false;

  // Platform Fee Formula: 5% of item price + R15 flat
 String? _appliedPromoCode;
  int _discountPercentage = 0;
  final TextEditingController _promoCtrl = TextEditingController();

  double get _discountAmount => (widget.listing.price * (_discountPercentage / 100));
  double get _effectiveItemPrice => widget.listing.price - _discountAmount;
  double get _buyerProtectionFee => (_effectiveItemPrice * 0.05) + 15.0;
  double get _totalAmount => _effectiveItemPrice + _selectedShipping.price + _buyerProtectionFee;

  @override
  void initState() {
    super.initState();
    // Default to the first enabled courier method
    _selectedShipping = widget.listing.shippingOptions.firstWhere(
      (opt) => opt.isEnabled,
      orElse: () => ShippingOption(method: 'Standard Courier', price: 60.0, isEnabled: true),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _processOrder() async {
    if (!_formKey.currentState!.validate()) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to complete purchase.')),
      );
      return;
    }

    // A seller cannot buy their own item
    if (user.uid == widget.listing.sellerId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You cannot purchase your own listing!')),
      );
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final orderId = const Uuid().v4();
      final firestore = FirebaseFirestore.instance;

      final order = OrderModel(
        orderId: orderId,
        listingId: widget.listing.id,
        itemTitle: widget.listing.title,
        itemImageUrl: widget.listing.imageUrls.isNotEmpty ? widget.listing.imageUrls.first : '',
        buyerId: user.uid,
        sellerId: widget.listing.sellerId,
        itemPrice: widget.listing.price,
        shippingFee: _selectedShipping.price,
        buyerProtectionFee: _buyerProtectionFee,
        totalAmount: _totalAmount,
        shippingMethod: _selectedShipping.method,
        recipientName: _nameController.text.trim(),
        recipientPhone: _phoneController.text.trim(),
        deliveryDetails: _addressController.text.trim(),
        status: OrderStatus.paidEscrowHeld, // Simulating successful payment
        createdAt: DateTime.now(),
      );

      // Atomic batch: Create order document & mark listing as 'sold'
      final batch = firestore.batch();

      final orderRef = firestore.collection('orders').doc(orderId);
      batch.set(orderRef, order.toMap());

      final listingRef = firestore.collection('listings').doc(widget.listing.id);
      batch.update(listingRef, {'status': 'sold'});

      await batch.commit();
      // Send in-app notification to the seller
      await WhatsAppHelper.sendNotification(
        recipientUserId: widget.listing.sellerId,
        title: 'Item Sold! 📦',
        message: 'Your item "${widget.listing.title}" was purchased for R${widget.listing.price.toStringAsFixed(0)}. Payout held in escrow.',
        type: 'order',
        targetId: orderId,
      );

      if (!mounted) return;

      // Show Order Success Dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: Color(0xFF008080), size: 28),
              SizedBox(width: 8),
              Text('Order Confirmed!'),
            ],
          ),
          content: Text(
            'Your payment of R${_totalAmount.toStringAsFixed(2)} is held safely in escrow.\n\nThe seller has been notified to pack and ship your parcel via ${_selectedShipping.method}.',
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF008080),
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.pop(ctx); // Close dialog
                Navigator.pop(context); // Close checkout
                Navigator.pop(context); // Back to feed
              },
              child: const Text('Back to Home'),
            ),
          ],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to place order: $e')),
      );
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.listing;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Checkout', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isProcessing
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Color(0xFF008080)),
                  SizedBox(height: 16),
                  Text('Securing funds in escrow & placing order...'),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- 1. Item Summary Card ---
                    Card(
                      elevation: 0.5,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: item.imageUrls.isNotEmpty
                                  ? Image.network(
                                      item.imageUrls.first,
                                      width: 70,
                                      height: 70,
                                      fit: BoxFit.cover,
                                    )
                                  : Container(width: 70, height: 70, color: Colors.grey.shade200),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.title,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${item.brand} • Size: ${item.size}',
                                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'R ${item.price.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w900,
                                      color: Color(0xFF008080),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // --- 2. Delivery Selection ---
                    // Inside CheckoutScreen: Delivery Selection
                    const Text('Select Delivery Method', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 8),
                    ...item.shippingOptions.where((opt) => opt.isEnabled).map((opt) {
                      return Card(
                        elevation: 0.5,
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(
                            color: _selectedShipping.method == opt.method
                                ? const Color(0xFF008080)
                                : Colors.transparent,
                            width: 1.5,
                          ),
                        ),
                        child: RadioListTile<ShippingOption>(
                          activeColor: const Color(0xFF008080),
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(opt.method, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                              ),
                              // --- YAGA (?) INFO BUTTON ---
                              IconButton(
                                icon: const Icon(Icons.help_outline, size: 18, color: Color(0xFF008080)),
                                tooltip: 'How this courier works',
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: () {
                                  DeliveryInfoSheet.show(context, opt.method);
                                },
                              ),
                            ],
                          ),
                          subtitle: Text(
                            opt.price == 0 ? 'FREE (R 0.00)' : 'R ${opt.price.toStringAsFixed(2)}',
                            style: TextStyle(
                              color: opt.price == 0 ? Colors.green.shade800 : Colors.black87,
                              fontWeight: opt.price == 0 ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                          value: opt,
                          groupValue: _selectedShipping,
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedShipping = val);
                          },
                        ),
                      );
                    }),

                    // --- 3. Delivery Details Form ---
                    const Text('Delivery & Recipient Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Recipient Full Name *',
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      validator: (val) => val == null || val.isEmpty ? 'Name required' : null,
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'SA Cellphone Number (for Courier SMS / OTP) *',
                        hintText: 'e.g. 082 123 4567',
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      validator: (val) {
                        if (val == null || val.isEmpty) return 'Phone number required for courier pin';
                        if (val.replaceAll(' ', '').length < 10) return 'Enter a valid 10-digit number';
                        return null;
                      },
                    ),
                    // --- 3. Delivery & Recipient Details ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Delivery & Recipient Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Recipient Full Name *',
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      validator: (val) => val == null || val.isEmpty ? 'Name required' : null,
                    ),
                    const SizedBox(height: 10),

                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'SA Cellphone Number (for Courier SMS / OTP) *',
                        hintText: 'e.g. 082 123 4567',
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      validator: (val) {
                        if (val == null || val.isEmpty) return 'Phone number required for courier pin';
                        if (val.replaceAll(' ', '').length < 10) return 'Enter a valid 10-digit number';
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),
                    // --- FIND ON MAP BUTTON ---
                        TextButton.icon(
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFF008080),
                            backgroundColor: const Color(0xFFE6F2F2),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                          ),
                          icon: const Icon(Icons.pin_drop, size: 16),
                          label: const Text('Find on Map', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          onPressed: () async {
                            final selectedAddress = await showModalBottomSheet<String>(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (_) => DropPointMapPicker(
                                initialCourierType: _selectedShipping.method,
                              ),
                            );

                            if (selectedAddress != null && selectedAddress.isNotEmpty) {
                              setState(() {
                                _addressController.text = selectedAddress;
                              });
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    backgroundColor: const Color(0xFF008080),
                                    content: Text('📍 Pinned & Auto-filled: $selectedAddress'),
                                  ),
                                );
                              }
                            }
                          },
                        ),
                    // Address / Drop-point input with Auto-fill indicator
                    TextFormField(
                      controller: _addressController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: _selectedShipping.method.contains('Pudo')
                            ? 'Pudo Locker Location / Address *'
                            : _selectedShipping.method.contains('PAXI')
                                ? 'PEP Store Branch Name / Code *'
                                : 'Delivery Address *',
                        hintText: 'Tap "Find on Map" above or type manually...',
                        border: const OutlineInputBorder(),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      validator: (val) => val == null || val.isEmpty ? 'Delivery location details required' : null,
                    ),
                    const SizedBox(height: 24),
                    const SizedBox(height: 10),
                    // Promo Code Box
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _promoCtrl,
                            textCapitalization: TextCapitalization.characters,
                            decoration: const InputDecoration(
                              labelText: 'Shop Promo Code',
                              hintText: 'e.g. SARAH15',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF008080), foregroundColor: Colors.white),
                          onPressed: () async {
                            final code = _promoCtrl.text.trim().toUpperCase();
                            if (code.isEmpty) return;

                            final snap = await FirebaseFirestore.instance
                                .collection('discount_codes')
                                .where('sellerId', isEqualTo: widget.listing.sellerId)
                                .where('code', isEqualTo: code)
                                .where('isActive', isEqualTo: true)
                                .get();

                            if (snap.docs.isNotEmpty) {
                              final percent = snap.docs.first.data()['discountPercent'] as int;
                              setState(() {
                                _appliedPromoCode = code;
                                _discountPercentage = percent;
                              });
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(backgroundColor: Colors.green, content: Text('$percent% Discount Applied! 🎉')),
                                );
                              }
                            } else {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Invalid code for this shop')),
                                );
                              }
                            }
                          },
                          child: const Text('Apply'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // --- 4. Order Price Breakdown ---
                    const Text('Price Breakdown', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Column(
                        children: [
                          _priceRow('Item Subtotal', 'R ${item.price.toStringAsFixed(2)}'),
                          const SizedBox(height: 8),
                          _priceRow(_selectedShipping.method, 'R ${_selectedShipping.price.toStringAsFixed(2)}'),
                          const SizedBox(height: 8),
                          _priceRow(
                            'Buyer Protection Fee (5% + R15)',
                            'R ${_buyerProtectionFee.toStringAsFixed(2)}',
                            isMuted: true,
                          ),
                          const Divider(height: 20),
                          _priceRow(
                            'Total Payable',
                            'R ${_totalAmount.toStringAsFixed(2)}',
                            isTotal: true,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),

                    // --- 5. Pay Button ---
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF008080),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: _processOrder,
                        child: Text(
                          'Confirm & Pay R${_totalAmount.toStringAsFixed(2)}',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _priceRow(String label, String value, {bool isTotal = false, bool isMuted = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 16 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            color: isMuted ? Colors.grey.shade600 : Colors.black87,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isTotal ? 18 : 14,
            fontWeight: isTotal ? FontWeight.w900 : FontWeight.w600,
            color: isTotal ? const Color(0xFF008080) : Colors.black87,
          ),
        ),
      ],
    );
  }
}