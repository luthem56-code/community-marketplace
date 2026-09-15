import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminService {
  // Put your admin email(s) here so you always have access:
  static const List<String> adminEmails = [
    'ntmkhizec@outlook.com', // <-- Put your email here!
  ];

  /// Checks if the current user is an authorized admin
  static Future<bool> isCurrentUserAdmin() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.isAnonymous) return false;

    // 1. Check if email is in the admin email list
    if (user.email != null && adminEmails.contains(user.email!.trim().toLowerCase())) {
      return true;
    }

    // 2. Check role field in Firestore: users/{uid} -> role == 'admin'
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