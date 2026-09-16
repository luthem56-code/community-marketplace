import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminService {
  // Put your login email here (case-insensitive):
  static const List<String> adminEmails = [
    'ntmkhizec@outlook.com'
  ];

  /// Checks if the current user is an authorized admin
  static Future<bool> isCurrentUserAdmin() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.isAnonymous) return false;

    // 1. Check email list
    if (user.email != null &&
        adminEmails.contains(user.email!.trim().toLowerCase())) {
      return true;
    }

    // 2. Check role == 'admin' in Firestore
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists) {
        final role = doc.data()?['role'];
        if (role == 'admin') return true;
      }
    } catch (_) {}

    return false;
  }
}