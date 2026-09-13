import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:uuid/uuid.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final Uuid _uuid = const Uuid();

  /// Compresses an image and uploads it to Firebase Storage under `listings/{sellerId}/`
  Future<String> compressAndUploadImage({
    required File file,
    required String sellerId,
  }) async {
    final String imageId = _uuid.v4();
    final String path = 'listings/$sellerId/$imageId.jpg';

    // Compress image to JPEG under ~150KB
    final Uint8List? compressedData = await FlutterImageCompress.compressWithFile(
      file.absolute.path,
      minWidth: 1024,
      minHeight: 1024,
      quality: 75,
      format: CompressFormat.jpeg,
    );

    if (compressedData == null) {
      throw Exception('Failed to compress image');
    }

    final ref = _storage.ref().child(path);
    final metadata = SettableMetadata(contentType: 'image/jpeg');

    final uploadTask = await ref.putData(compressedData, metadata);
    return await uploadTask.ref.getDownloadURL();
  }
}