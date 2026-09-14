import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';

class MediaService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final _uuid = const Uuid();

  /// Compresses the image directly to memory bytes
  Future<Uint8List> _getImageBytes(File file) async {
    try {
      final Uint8List? compressed = await FlutterImageCompress.compressWithFile(
        file.absolute.path,
        quality: 75,
        minWidth: 1080,
        minHeight: 1080,
      );

      if (compressed != null) {
        return compressed;
      }
    } catch (e) {
      debugPrint('Compression skipped, using original bytes: $e');
    }

    // Fallback: read raw file bytes directly if compression encounters an issue
    return await file.readAsBytes();
  }

  /// Uploads listing images directly to Firebase Storage
  Future<List<String>> uploadListingImages({
    required List<File> images,
    required String sellerId,
  }) async {
    List<String> downloadUrls = [];

    for (File rawImage in images) {
      // 1. Get compressed bytes
      final Uint8List fileBytes = await _getImageBytes(rawImage);
      final fileName = '${_uuid.v4()}.jpg';

      // 2. Reference in Firebase Storage
      final Reference ref = _storage.ref().child('listings').child(sellerId).child(fileName);

      // 3. Upload bytes directly
      final UploadTask uploadTask = ref.putData(
        fileBytes,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      final TaskSnapshot snapshot = await uploadTask;

      // 4. Retrieve public download URL
      final String downloadUrl = await snapshot.ref.getDownloadURL();
      downloadUrls.add(downloadUrl);
    }

    return downloadUrls;
  }
}