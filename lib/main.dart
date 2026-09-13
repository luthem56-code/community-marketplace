import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // If you already have firebase_options.dart in your lib folder, 
    // uncomment the line below and import it:
    // await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

    await Firebase.initializeApp();
    debugPrint("✅ Firebase Initialized successfully!");
  } catch (e, stackTrace) {
    debugPrint("❌ Firebase initialization failed: $e");
    debugPrint(stackTrace.toString());
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
          seedColor: const Color(0xFF008080), // Modern teal theme like Yaga
        ),
        useMaterial3: true,
      ),
      // Set the home screen to your new CreateListingScreen
      home: const CreateListingScreen(),
    );
  }
}

class CreateListingScreen extends StatelessWidget {
  const CreateListingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Listing')),
      body: const Center(child: Text('Create a listing')),
    );
  }
}