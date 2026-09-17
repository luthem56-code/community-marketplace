import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../models/listing_model.dart';
import '../services/media_service.dart';
import '../constants/yaga_categories.dart';
import '../widgets/delivery_info_sheet.dart';

class CreateListingScreen extends StatefulWidget {
  const CreateListingScreen({super.key});

  @override
  State<CreateListingScreen> createState() => _CreateListingScreenState();
}

class _CreateListingScreenState extends State<CreateListingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _mediaService = MediaService();
  final _picker = ImagePicker();

  final List<File> _selectedImages = [];
  bool _isLoading = false;

  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _priceController = TextEditingController();
  final _brandController = TextEditingController();
  final _sizeController = TextEditingController();

  String _selectedCategory = 'Women';
  String _selectedSubCategory = 'Dresses';
  ItemCondition _selectedCondition = ItemCondition.good;
  bool _allowBundling = true;

  // Courier Guy (Pudo)
  bool _enableCourierGuy = true;
  double _courierGuyPrice = 64.0;
  String _courierGuySize = 'Small (600x410x80 mm)';

  // Pargo
  bool _enablePargo = false;
  double _pargoPrice = 59.0;
  String _pargoSize = 'Small parcel (up to 5kg)';

  // PAXI
  bool _enablePaxi = true;
  double _paxiPrice = 49.0;
  String _paxiSize = 'Standard parcel (450x370 mm)';

  // Other Couriers
  bool _enablePostNet = false;
  bool _enablePickup = true;

  final List<String> _photoSlotNames = [
    'Cover photo *',
    'Different angle',
    'Brand/Size Label',
    'Detail / Flaw',
    'Extra photo',
    'Extra photo',
  ];

  List<String> get _categories =>
      YagaCategories.all.map((c) => c['title'] as String).toList();

  List<String> get _currentSubCategories {
    final cat = YagaCategories.all.firstWhere(
      (c) => c['title'] == _selectedCategory,
      orElse: () => YagaCategories.all.first,
    );
    return List<String>.from(cat['sub'] as List);
  }

  Future<void> _pickImageForSlot(int slotIndex) async {
    final XFile? picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        if (slotIndex < _selectedImages.length) {
          _selectedImages[slotIndex] = File(picked.path);
        } else {
          _selectedImages.add(File(picked.path));
        }
      });
    }
  }

  Future<void> _submitListing() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in first.')),
      );
      return;
    }

    if (_selectedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least a cover photo.')),
      );
      return;
    }

    if (!_enableCourierGuy &&
        !_enablePargo &&
        !_enablePaxi &&
        !_enablePostNet &&
        !_enablePickup) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enable at least one delivery option.')),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final uploadedUrls = await _mediaService.uploadListingImages(
        images: _selectedImages,
        sellerId: user.uid,
      );

      final List<ShippingOption> activeShipping = [];

      if (_enableCourierGuy) {
        activeShipping.add(ShippingOption(
          method: 'The Courier Guy Locker ($_courierGuySize)',
          price: _courierGuyPrice,
          isEnabled: true,
        ));
      }
      if (_enablePargo) {
        activeShipping.add(ShippingOption(
          method: 'Pargo Store-to-Store ($_pargoSize)',
          price: _pargoPrice,
          isEnabled: true,
        ));
      }
      if (_enablePaxi) {
        activeShipping.add(ShippingOption(
          method: 'PAXI Speed Service ($_paxiSize)',
          price: _paxiPrice,
          isEnabled: true,
        ));
      }
      if (_enablePostNet) {
        activeShipping.add(ShippingOption(method: 'PostNet-to-PostNet', price: 109.0, isEnabled: true));
      }
      if (_enablePickup) {
        activeShipping.add(ShippingOption(method: 'Pick up from Seller (Local PMB Collection)', price: 0.0, isEnabled: true));
      }

      final listingId = const Uuid().v4();
      final newListing = ListingModel(
        id: listingId,
        sellerId: user.uid,
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        category: _selectedCategory,
        subCategory: _selectedSubCategory, // Saved to Firestore!
        size: _sizeController.text.trim(),
        brand: _brandController.text.trim().isEmpty ? 'Unbranded' : _brandController.text.trim(),
        condition: _selectedCondition,
        price: double.parse(_priceController.text.trim()),
        imageUrls: uploadedUrls,
        shippingOptions: activeShipping,
        createdAt: DateTime.now(),
      );

      await FirebaseFirestore.instance.collection('listings').doc(listingId).set({
        ...newListing.toMap(),
        'allowBundling': _allowBundling,
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Item listed successfully! 🎉')),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error uploading listing: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _priceController.dispose();
    _brandController.dispose();
    _sizeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        title: const Text('Sell an Item', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Color(0xFF008080)),
                  SizedBox(height: 16),
                  Text('Publishing listing to marketplace...'),
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
                    const Text('Upload photos', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    const Text('First photo is your cover picture. Add up to 6 photos.', style: TextStyle(color: Colors.black54, fontSize: 12)),
                    const SizedBox(height: 12),

                    SizedBox(
                      height: 110,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: 6,
                        itemBuilder: (context, index) {
                          final hasImage = index < _selectedImages.length;
                          return Padding(
                            padding: const EdgeInsets.only(right: 10),
                            child: GestureDetector(
                              onTap: () => _pickImageForSlot(index),
                              child: Container(
                                width: 95,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: index == 0 ? const Color(0xFF008080) : Colors.grey.shade300,
                                    width: index == 0 ? 1.5 : 1.0,
                                  ),
                                ),
                                child: hasImage
                                    ? Stack(
                                        fit: StackFit.expand,
                                        children: [
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(7),
                                            child: Image.file(_selectedImages[index], fit: BoxFit.cover),
                                          ),
                                          Positioned(
                                            top: 2,
                                            right: 2,
                                            child: GestureDetector(
                                              onTap: () => setState(() => _selectedImages.removeAt(index)),
                                              child: const CircleAvatar(
                                                radius: 10,
                                                backgroundColor: Colors.black54,
                                                child: Icon(Icons.close, size: 12, color: Colors.white),
                                              ),
                                            ),
                                          ),
                                        ],
                                      )
                                    : Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            index == 0 ? Icons.add_a_photo : Icons.add_photo_alternate_outlined,
                                            color: index == 0 ? const Color(0xFF008080) : Colors.grey.shade400,
                                            size: 26,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            _photoSlotNames[index],
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: index == 0 ? const Color(0xFF008080) : Colors.grey.shade600,
                                              fontWeight: index == 0 ? FontWeight.bold : FontWeight.normal,
                                            ),
                                          ),
                                        ],
                                      ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 10),

                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE6F2F2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.lightbulb_outline, color: Color(0xFF008080), size: 18),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Sell better with our photo tips: Use bright natural daylight, show the brand/size label, and capture flaws clearly.',
                              style: TextStyle(fontSize: 11, color: Color(0xFF004D40)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    const Text('Item details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Title *',
                        hintText: 'e.g. Vintage Denim Jacket',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(),
                      ),
                      validator: (val) => val == null || val.isEmpty ? 'Title required' : null,
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _descController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Description *',
                        hintText: 'Describe flaws, fit, material, measurements...',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(),
                      ),
                      validator: (val) => val == null || val.isEmpty ? 'Description required' : null,
                    ),
                    const SizedBox(height: 12),

                    // 1. MAIN CATEGORY DROPDOWN
                    DropdownButtonFormField<String>(
                      value: _selectedCategory,
                      decoration: const InputDecoration(labelText: 'Category *', filled: true, fillColor: Colors.white, border: OutlineInputBorder()),
                      items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                      onChanged: (v) {
                        if (v != null) {
                          setState(() {
                            _selectedCategory = v;
                            _selectedSubCategory = _currentSubCategories.first;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 12),

                    // 2. DYNAMIC SUB-CATEGORY DROPDOWN (Matches YAGA exactly!)
                    DropdownButtonFormField<String>(
                      value: _currentSubCategories.contains(_selectedSubCategory)
                          ? _selectedSubCategory
                          : _currentSubCategories.first,
                      decoration: const InputDecoration(labelText: 'Sub-Category *', filled: true, fillColor: Colors.white, border: OutlineInputBorder()),
                      items: _currentSubCategories.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                      onChanged: (v) {
                        if (v != null) setState(() => _selectedSubCategory = v);
                      },
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _brandController,
                            decoration: const InputDecoration(labelText: 'Brand', hintText: 'Zara, Cotton On...', filled: true, fillColor: Colors.white, border: OutlineInputBorder()),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            controller: _sizeController,
                            decoration: const InputDecoration(labelText: 'Size *', hintText: 'M, 34, UK 6...', filled: true, fillColor: Colors.white, border: OutlineInputBorder()),
                            validator: (val) => val == null || val.isEmpty ? 'Size required' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    DropdownButtonFormField<ItemCondition>(
                      value: _selectedCondition,
                      decoration: const InputDecoration(labelText: 'Condition *', filled: true, fillColor: Colors.white, border: OutlineInputBorder()),
                      items: ItemCondition.values.map((c) => DropdownMenuItem(value: c, child: Text(c.label))).toList(),
                      onChanged: (v) => setState(() => _selectedCondition = v!),
                    ),
                    const SizedBox(height: 28),

                    // Delivery Matrix
                    const Text('Delivery', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(
                      'Select as many as you like. Shops with multiple options sell faster. The Buyer covers delivery.',
                      style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
                    ),
                    const SizedBox(height: 16),

                    // 1. The Courier Guy Locker & Kiosk (Pudo)
                    _courierCard(
                      title: 'The Courier Guy Locker & Kiosk',
                      subtitle: 'We will provide you with the deposit PIN code once you are ready to ship.',
                      isEnabled: _enableCourierGuy,
                      onToggle: (v) => setState(() => _enableCourierGuy = v),
                      body: Column(
                        children: [
                          _sizeRadio(
                            label: 'Extra-Small (600x170x80 mm)',
                            price: 53.0,
                            groupVal: _courierGuyPrice,
                            onSelect: (p) => setState(() {
                              _courierGuyPrice = p;
                              _courierGuySize = 'Extra-Small (600x170x80 mm)';
                            }),
                          ),
                          _sizeRadio(
                            label: 'Small (600x410x80 mm)',
                            price: 64.0,
                            groupVal: _courierGuyPrice,
                            onSelect: (p) => setState(() {
                              _courierGuyPrice = p;
                              _courierGuySize = 'Small (600x410x80 mm)';
                            }),
                          ),
                          _sizeRadio(
                            label: 'Medium (600x410x190 mm)',
                            price: 74.0,
                            groupVal: _courierGuyPrice,
                            onSelect: (p) => setState(() {
                              _courierGuyPrice = p;
                              _courierGuySize = 'Medium (600x410x190 mm)';
                            }),
                          ),
                          _sizeRadio(
                            label: 'Large (600x410x410 mm)',
                            price: 94.0,
                            groupVal: _courierGuyPrice,
                            onSelect: (p) => setState(() {
                              _courierGuyPrice = p;
                              _courierGuySize = 'Large (600x410x410 mm)';
                            }),
                          ),
                          _sizeRadio(
                            label: 'Extra-Large (600x410x690 mm)',
                            price: 149.0,
                            groupVal: _courierGuyPrice,
                            onSelect: (p) => setState(() {
                              _courierGuyPrice = p;
                              _courierGuySize = 'Extra-Large (600x410x690 mm)';
                            }),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // 2. Pargo Store-to-Store
                    _courierCard(
                      title: 'Pargo Store-to-Store',
                      subtitle: 'We will provide you with the necessary Pargo PIN. Drop off at any Pargo Point.',
                      isEnabled: _enablePargo,
                      onToggle: (v) => setState(() => _enablePargo = v),
                      body: Column(
                        children: [
                          _sizeRadio(
                            label: 'Extra-Small parcel (up to 2kg)',
                            price: 49.0,
                            groupVal: _pargoPrice,
                            onSelect: (p) => setState(() {
                              _pargoPrice = p;
                              _pargoSize = 'Extra-Small parcel (up to 2kg)';
                            }),
                          ),
                          _sizeRadio(
                            label: 'Small parcel (up to 5kg)',
                            price: 59.0,
                            groupVal: _pargoPrice,
                            onSelect: (p) => setState(() {
                              _pargoPrice = p;
                              _pargoSize = 'Small parcel (up to 5kg)';
                            }),
                          ),
                          _sizeRadio(
                            label: 'Medium parcel (up to 10kg)',
                            price: 69.0,
                            groupVal: _pargoPrice,
                            onSelect: (p) => setState(() {
                              _pargoPrice = p;
                              _pargoSize = 'Medium parcel (up to 10kg)';
                            }),
                          ),
                          _sizeRadio(
                            label: 'Large parcel (up to 15kg)',
                            price: 89.0,
                            groupVal: _pargoPrice,
                            onSelect: (p) => setState(() {
                              _pargoPrice = p;
                              _pargoSize = 'Large parcel (up to 15kg)';
                            }),
                          ),
                          _sizeRadio(
                            label: 'Extra-Large parcel (up to 20kg)',
                            price: 99.0,
                            groupVal: _pargoPrice,
                            onSelect: (p) => setState(() {
                              _pargoPrice = p;
                              _pargoSize = 'Extra-Large parcel (up to 20kg)';
                            }),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // 3. PAXI Speed Service
                    _courierCard(
                      title: 'Paxi Speed Service',
                      subtitle: 'We will provide you with the PAXI token and bag voucher to ship at PEP.',
                      isEnabled: _enablePaxi,
                      onToggle: (v) => setState(() => _enablePaxi = v),
                      body: Column(
                        children: [
                          _sizeRadio(
                            label: 'Standard parcel (450x370 mm)',
                            price: 49.0,
                            groupVal: _paxiPrice,
                            onSelect: (p) => setState(() {
                              _paxiPrice = p;
                              _paxiSize = 'Standard parcel (450x370 mm)';
                            }),
                          ),
                          _sizeRadio(
                            label: 'Large parcel (640x510 mm)',
                            price: 60.0,
                            groupVal: _paxiPrice,
                            onSelect: (p) => setState(() {
                              _paxiPrice = p;
                              _paxiSize = 'Large parcel (640x510 mm)';
                            }),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // 4. PostNet & Pickup
                    Card(
                      elevation: 0.5,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      child: Column(
                        children: [
                          SwitchListTile(
                            activeColor: const Color(0xFF008080),
                            title: const Text('PostNet-to-PostNet', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            subtitle: const Text('Flat rate: R 109.00'),
                            value: _enablePostNet,
                            onChanged: (v) => setState(() => _enablePostNet = v),
                          ),
                          const Divider(height: 1),
                          SwitchListTile(
                            activeColor: const Color(0xFF008080),
                            title: const Text('Pick up from Seller (Free Collection)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            subtitle: const Text('Local PMB / community meetup (R 0.00)'),
                            value: _enablePickup,
                            onChanged: (v) => setState(() => _enablePickup = v),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    Card(
                      elevation: 0.5,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      child: SwitchListTile(
                        activeColor: const Color(0xFF008080),
                        title: const Text('Bundling', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        subtitle: const Text('Allow buyers to bundle multiple items from your shop to pay only 1 delivery fee.'),
                        value: _allowBundling,
                        onChanged: (v) => setState(() => _allowBundling = v),
                      ),
                    ),
                    const SizedBox(height: 24),

                    const Text('Price', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    const Text(
                      'This is the amount you will receive. Selling is 100% free with 0% commission.',
                      style: TextStyle(color: Color(0xFF008080), fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _priceController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        prefixText: 'R ',
                        labelText: 'Item price (ZAR) *',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(),
                      ),
                      validator: (val) {
                        if (val == null || val.isEmpty) return 'Enter a price';
                        if (double.tryParse(val) == null || double.parse(val) <= 0) return 'Invalid price';
                        return null;
                      },
                    ),
                    const SizedBox(height: 30),

                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF008080),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: _submitListing,
                        child: const Text('Publish Item', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _courierCard({
    required String title,
    required String subtitle,
    required bool isEnabled,
    required ValueChanged<bool> onToggle,
    required Widget body,
  }) {
    return Card(
      elevation: 0.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: isEnabled ? const Color(0xFF008080).withOpacity(0.4) : Colors.transparent),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SwitchListTile(
            activeColor: const Color(0xFF008080),
            title: Row(
              children: [
                Expanded(
                  child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                ),
                IconButton(
                  icon: const Icon(Icons.help_outline, size: 18, color: Color(0xFF008080)),
                  tooltip: 'How this courier works',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => DeliveryInfoSheet.show(context, title),
                ),
              ],
            ),
            subtitle: Text(subtitle, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
            value: isEnabled,
            onChanged: onToggle,
          ),
          if (isEnabled) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: body,
            ),
          ],
        ],
      ),
    );
  }

  Widget _sizeRadio({
    required String label,
    required double price,
    required double groupVal,
    required ValueChanged<double> onSelect,
  }) {
    final isSelected = groupVal == price;
    return InkWell(
      onTap: () => onSelect(price),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Row(
          children: [
            Radio<double>(
              value: price,
              groupValue: groupVal,
              activeColor: const Color(0xFF008080),
              onChanged: (v) {
                if (v != null) onSelect(v);
              },
            ),
            Expanded(
              child: Text(label, style: TextStyle(fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
            ),
            Text(
              '+ R ${price.toStringAsFixed(0)}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF008080)),
            ),
          ],
        ),
      ),
    );
  }
}