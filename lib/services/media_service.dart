import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

class MediaService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final _uuid = const Uuid();

  /// Compresses an image file before upload
  Future<File?> compressImage(File file) async {
    final tempDir = Directory.systemTemp;
    final targetPath = p.join(
      tempDir.path,
      '${_uuid.v4()}_compressed.jpg',
    );

    final XFile? result = await FlutterImageCompress.compressAndGetFile(
      file.absolute.path,
      targetPath,
      quality: 75, // 75% quality offers great visual fidelity at small file size
      minWidth: 1080,
      minHeight: 1080,
    );

    return result != null ? File(result.path) : null;
  }

  /// Uploads compressed images to Firebase Storage under `listings/{sellerId}/`
  Future<List<String>> uploadListingImages({
    required List<File> images,
    required String sellerId,
  }) async {
    List<String> downloadUrls = [];

    for (File rawImage in images) {
      final compressedFile = await compressImage(rawImage) ?? rawImage;
      final fileName = '${_uuid.v4()}.jpg';
      final ref = _storage.ref().child('listings').child(sellerId).child(fileName);

      final uploadTask = await ref.putFile(
        compressedFile,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      final url = await uploadTask.ref.getDownloadURL();
      downloadUrls.add(url);
    }

    return downloadUrls;
  }
}