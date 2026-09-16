import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _suburbController = TextEditingController();
  final _bioController = TextEditingController();

  Uint8List? _selectedAvatarBytes;
  String? _currentPhotoUrl;
  bool _isLoading = false;
  bool _isFetchingData = true;

  @override
  void initState() {
    super.initState();
    _loadCurrentProfile();
  }

  Future<void> _loadCurrentProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) setState(() => _isFetchingData = false);
      return;
    }

    _nameController.text = user.displayName ?? '';
    _currentPhotoUrl = user.photoURL;

    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        _phoneController.text = data['phone'] ?? '';
        _suburbController.text = data['suburb'] ?? 'Pietermaritzburg';
        _bioController.text = data['bio'] ?? '';
        if (data['photoUrl'] != null && (data['photoUrl'] as String).isNotEmpty) {
          _currentPhotoUrl = data['photoUrl'];
        }
      }
    } catch (e) {
      debugPrint('Error loading profile: $e');
    } finally {
      if (mounted) setState(() => _isFetchingData = false);
    }
  }

  Future<void> _pickAvatar() async {
    final ImagePicker picker = ImagePicker();
    final XFile? picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 512,
      maxHeight: 512,
    );

    if (picked != null) {
      final Uint8List bytes = await picked.readAsBytes();
      setState(() {
        _selectedAvatarBytes = bytes;
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      String? photoUrl = _currentPhotoUrl;

      // 1. If user picked a new avatar, upload bytes to Firebase Storage
      if (_selectedAvatarBytes != null) {
        final ref = FirebaseStorage.instance
            .ref()
            .child('avatars')
            .child('${user.uid}.jpg');

        final uploadTask = ref.putData(
          _selectedAvatarBytes!,
          SettableMetadata(contentType: 'image/jpeg'),
        );

        final snapshot = await uploadTask;
        photoUrl = await snapshot.ref.getDownloadURL();
      }

      // 2. Update Firebase Auth Profile
      await user.updateDisplayName(_nameController.text.trim());
      if (photoUrl != null) {
        await user.updatePhotoURL(photoUrl);
      }

      // 3. Update Firestore Document: users/{uid}
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'displayName': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'suburb': _suburbController.text.trim(),
        'bio': _bioController.text.trim(),
        'photoUrl': photoUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Color(0xFF008080),
            content: Text('Profile and shop details updated successfully! 🎉'),
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: Colors.red.shade800, content: Text('Error saving profile: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _suburbController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        title: const Text('Edit Profile & Shop', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isFetchingData
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF008080)))
          : _isLoading
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: Color(0xFF008080)),
                      SizedBox(height: 16),
                      Text('Saving profile & uploading photo...'),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // --- 1. AVATAR PICKER (WEB & MOBILE COMPATIBLE) ---
                        Center(
                          child: Stack(
                            children: [
                              Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: const Color(0xFF008080),
                                  border: Border.all(color: Colors.white, width: 3),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: ClipOval(
                                  child: _selectedAvatarBytes != null
                                      ? Image.memory(_selectedAvatarBytes!, fit: BoxFit.cover)
                                      : (_currentPhotoUrl != null && _currentPhotoUrl!.isNotEmpty)
                                          ? Image.network(
                                              _currentPhotoUrl!,
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, __, ___) => const Icon(Icons.person, size: 54, color: Colors.white),
                                            )
                                          : Center(
                                              child: Text(
                                                _nameController.text.isNotEmpty
                                                    ? _nameController.text[0].toUpperCase()
                                                    : 'U',
                                                style: const TextStyle(fontSize: 38, fontWeight: FontWeight.bold, color: Colors.white),
                                              ),
                                            ),
                                ),
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: GestureDetector(
                                  onTap: _pickAvatar,
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF008080),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.camera_alt, size: 18, color: Colors.white),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Center(
                          child: Text(
                            'Tap camera to change photo',
                            style: TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // --- 2. FORM FIELDS ---
                        TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'Shop / Display Name *',
                            hintText: 'e.g. Sarah\'s Wardrobe',
                            prefixIcon: Icon(Icons.storefront_outlined, size: 20),
                            border: OutlineInputBorder(),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          validator: (val) => val == null || val.trim().isEmpty ? 'Name is required' : null,
                        ),
                        const SizedBox(height: 14),

                        TextFormField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            labelText: 'Cellphone Number (for courier waybills & OTPs) *',
                            hintText: 'e.g. 082 123 4567',
                            prefixIcon: Icon(Icons.phone_outlined, size: 20),
                            border: OutlineInputBorder(),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) return 'Cellphone number is required';
                            if (val.replaceAll(' ', '').length < 10) return 'Enter a valid 10-digit cellphone number';
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),

                        TextFormField(
                          controller: _suburbController,
                          decoration: const InputDecoration(
                            labelText: 'Location / Suburb *',
                            hintText: 'e.g. Scottsville, PMB',
                            prefixIcon: Icon(Icons.location_on_outlined, size: 20),
                            border: OutlineInputBorder(),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          validator: (val) => val == null || val.trim().isEmpty ? 'Location is required' : null,
                        ),
                        const SizedBox(height: 14),

                        TextFormField(
                          controller: _bioController,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            labelText: 'Shop Bio',
                            hintText: 'Describe what you sell, clothing sizes, packaging speed, or bundle deals...',
                            border: OutlineInputBorder(),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 26),

                        // --- 3. SAVE BUTTON ---
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF008080),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            onPressed: _saveProfile,
                            child: const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          ),
                        ),
                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                ),
    );
  }
}