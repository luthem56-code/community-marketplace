import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class WhatsAppHelper {
  /// Opens WhatsApp with a clean, pre-filled message
  static Future<void> openChat({
    required BuildContext context,
    required String rawPhone,
    required String itemTitle,
    required double itemPrice,
  }) async {
    // 1. Clean South African phone numbers into international format (e.g. 0821234567 -> 27821234567)
    String phone = rawPhone.replaceAll(RegExp(r'[^0-9]'), '');
    if (phone.startsWith('0')) {
      phone = '27${phone.substring(1)}';
    }

    if (phone.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seller did not provide a valid WhatsApp number.')),
      );
      return;
    }

    // 2. Pre-filled text with escrow safety reminder
    final message = Uri.encodeComponent(
      'Hi! I saw your "$itemTitle" on PMB Community Market listed for R${itemPrice.toStringAsFixed(0)}.\n\nIs it still available? 😊',
    );

    final url = Uri.parse('https://wa.me/$phone?text=$message');

    try {
      final launched = await launchUrl(url, mode: LaunchMode.externalApplication);
      if (!launched) {
        await launchUrl(url, mode: LaunchMode.platformDefault);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open WhatsApp on this device.')),
        );
      }
    }
  }

  /// Sends an in-app notification document to Firestore
  static Future<void> sendNotification({
    required String recipientUserId,
    required String title,
    required String message,
    required String type,
    String? targetId,
  }) async {
    try {
      await FirebaseFirestore.instance.collection('notifications').add({
        'userId': recipientUserId,
        'title': title,
        'message': message,
        'type': type,
        'targetId': targetId,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Notification error: $e');
    }
  }
}