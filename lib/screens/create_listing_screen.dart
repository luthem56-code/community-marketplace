import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../models/listing_model.dart';
import '../services/media_service.dart';

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

  // Form Fields
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _priceController = TextEditingController();
  final _brandController = TextEditingController();
  final _sizeController = TextEditingController();

  String _selectedCategory = 'Women';
  ItemCondition _selectedCondition = ItemCondition.good;

  // Preset South African Shipping Options (Standard Yaga defaults)
  final List<ShippingOption> _shippingOptions = [
    ShippingOption(method: 'Pudo Locker (The Courier Guy)', price: 60.00, isEnabled: true),
    ShippingOption(method: 'PAXI (PEP Stores to PEP)', price: 59.95, isEnabled: true),
    ShippingOption(method: 'PostNet-to-PostNet', price: 109.00, isEnabled: false),
    ShippingOption(method: 'Door-to-Door Courier', price: 100.00, isEnabled: false),
  ];

  final List<String> _categories = [
    'Women',
    'Men',
    'Kids & Babies',
    'Beauty & Care',
    'Accessories',
    'Home',
  ];

  Future<void> _pickImages() async {
    if (_selectedImages.length >= 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maximum 6 photos allowed')),
      );
      return;
    }

    final List<XFile> picked = await _picker.pickMultiImage(limit: 6 - _selectedImages.length);
    if (picked.isNotEmpty) {
      setState(() {
        _selectedImages.addAll(picked.map((x) => File(x.path)));
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
        const SnackBar(content: Text('Please add at least one photo.')),
      );
      return;
    }

    if (!_shippingOptions.any((opt) => opt.isEnabled)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enable at least one shipping method.')),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // 1. Upload & compress images
      final uploadedUrls = await _mediaService.uploadListingImages(
        images: _selectedImages,
        sellerId: user.uid,
      );

      // 2. Generate listing model
      final listingId = const Uuid().v4();
      final newListing = ListingModel(
        id: listingId,
        sellerId: user.uid,
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        category: _selectedCategory,
        subCategory: 'General',
        size: _sizeController.text.trim(),
        brand: _brandController.text.trim().isEmpty ? 'Unbranded' : _brandController.text.trim(),
        condition: _selectedCondition,
        price: double.parse(_priceController.text.trim()),
        imageUrls: uploadedUrls,
        shippingOptions: _shippingOptions.where((s) => s.isEnabled).toList(),
        createdAt: DateTime.now(),
      );

      // 3. Save to Cloud Firestore
      await FirebaseFirestore.instance
          .collection('listings')
          .doc(listingId)
          .set(newListing.toMap());

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
      appBar: AppBar(
        title: const Text('Sell an Item', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Uploading & processing images...'),
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
                    // --- Photo Uploader Grid ---
                    const Text('Photos (Up to 6)', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 100,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          GestureDetector(
                            onTap: _pickImages,
                            child: Container(
                              width: 100,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey.shade400),
                              ),
                              child: const Icon(Icons.add_a_photo, size: 32, color: Colors.black54),
                            ),
                          ),
                          ..._selectedImages.asMap().entries.map((entry) {
                            return Padding(
                              padding: const EdgeInsets.only(left: 8.0),
                              child: Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.file(
                                      entry.value,
                                      width: 100,
                                      height: 100,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  Positioned(
                                    top: 2,
                                    right: 2,
                                    child: GestureDetector(
                                      onTap: () => setState(() => _selectedImages.removeAt(entry.key)),
                                      child: const CircleAvatar(
                                        radius: 12,
                                        backgroundColor: Colors.black54,
                                        child: Icon(Icons.close, size: 14, color: Colors.white),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // --- Item Details ---
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Title *',
                        hintText: 'e.g. Vintage Denim Jacket',
                        border: OutlineInputBorder(),
                      ),
                      validator: (val) => val == null || val.isEmpty ? 'Please enter a title' : null,
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _descController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Description *',
                        hintText: 'Describe flaws, fit, material...',
                        border: OutlineInputBorder(),
                      ),
                      validator: (val) => val == null || val.isEmpty ? 'Please enter a description' : null,
                    ),
                    const SizedBox(height: 12),

                    // Category Dropdown
                    DropdownButtonFormField<String>(
                      value: _selectedCategory,
                      decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
                      items: _categories.map((cat) => DropdownMenuItem(value: cat, child: Text(cat))).toList(),
                      onChanged: (val) => setState(() => _selectedCategory = val!),
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _brandController,
                            decoration: const InputDecoration(labelText: 'Brand', hintText: 'Zara, Cotton On...', border: OutlineInputBorder()),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            controller: _sizeController,
                            decoration: const InputDecoration(labelText: 'Size *', hintText: 'M, 34, UK 6...', border: OutlineInputBorder()),
                            validator: (val) => val == null || val.isEmpty ? 'Enter size' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Condition Dropdown
                    DropdownButtonFormField<ItemCondition>(
                      value: _selectedCondition,
                      decoration: const InputDecoration(labelText: 'Condition', border: OutlineInputBorder()),
                      items: ItemCondition.values.map((cond) => DropdownMenuItem(value: cond, child: Text(cond.label))).toList(),
                      onChanged: (val) => setState(() => _selectedCondition = val!),
                    ),
                    const SizedBox(height: 12),

                    // Price (ZAR)
                    TextFormField(
                      controller: _priceController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        prefixText: 'R ',
                        labelText: 'Price (ZAR) *',
                        border: OutlineInputBorder(),
                      ),
                      validator: (val) {
                        if (val == null || val.isEmpty) return 'Enter a price';
                        if (double.tryParse(val) == null || double.parse(val) <= 0) return 'Invalid price';
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // --- South African Shipping Options ---
                    const Text('Delivery Options (Enable at least one)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 8),
                    ..._shippingOptions.asMap().entries.map((entry) {
                      final opt = entry.value;
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        child: SwitchListTile(
                          title: Text(opt.method),
                          subtitle: Text('Flat rate: R${opt.price.toStringAsFixed(2)}'),
                          value: opt.isEnabled,
                          onChanged: (bool enabled) {
                            setState(() {
                              _shippingOptions[entry.key] = ShippingOption(
                                method: opt.method,
                                price: opt.price,
                                isEnabled: enabled,
                              );
                            });
                          },
                        ),
                      );
                    }),
                    const SizedBox(height: 24),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: _submitListing,
                        child: const Text('Publish Item', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}