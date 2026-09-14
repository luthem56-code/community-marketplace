import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'screens/main_navigation_shell.dart';

// Import our screens
import 'screens/marketplace_feed_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyDBx8pp3lY_O33LX75EqjrqIoT7XVBF4BM",
      appId: "1:793038055925:web:b1b40249b87ad25b9958bc",
      messagingSenderId: "793038055925",
      projectId: "community-marketplace-59527",
      storageBucket: "community-marketplace-59527.firebasestorage.app",
    ),
  );

  if (FirebaseAuth.instance.currentUser == null) {
    await FirebaseAuth.instance.signInAnonymously();
  }

  runApp(const CommunityMarketplaceApp());
}

class CommunityMarketplaceApp extends StatelessWidget {
  const CommunityMarketplaceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Community Marketplace',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF008080), // Yaga-style teal
        ),
        useMaterial3: true,
      ),
      // Point home to the Marketplace Feed
      home: const MainNavigationShell(),
    );
  }
}