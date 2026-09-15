import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/main_navigation_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Safety: If any widget crashes, show the red error box on screen instead of a blank white screen!
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Text(
            'App Error:\n\n${details.exceptionAsString()}',
            style: const TextStyle(color: Colors.red, fontSize: 13, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  };

  try {
    await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyDBx8pp3lY_O33LX75EqjrqIoT7XVBF4BM",
      appId: "1:793038055925:web:b1b40249b87ad25b9958bc",
      messagingSenderId: "793038055925",
      projectId: "community-marketplace-59527",
      storageBucket: "community-marketplace-59527.firebasestorage.app",
    ),
  );
    debugPrint("✅ Firebase initialized successfully!");
  } catch (e) {
    debugPrint("❌ Firebase init error: $e");
  }

  runApp(const CommunityMarketplaceApp());
}

class CommunityMarketplaceApp extends StatelessWidget {
  const CommunityMarketplaceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PMB Community Marketplace',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF008080),
        ),
        useMaterial3: true,
      ),
      home: const MainNavigationShell(),
    );
  }
}