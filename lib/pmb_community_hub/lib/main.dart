import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // NOTE: When running Flutter Web, replace with your Firebase Web Options
  // Generated using `flutterfire configure` or from the Firebase Console Web App settings
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "YOUR_FIREBASE_API_KEY",
      authDomain: "your-project.firebaseapp.com",
      projectId: "your-project-id",
      storageBucket: "your-project.appspot.com",
      messagingSenderId: "123456789",
      appId: "1:123456789:web:abcdef123456",
    ),
  );

  runApp(const PmbCommunityApp());
}

class PmbCommunityApp extends StatelessWidget {
  const PmbCommunityApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PMB Community Hub',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Inter',
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2563EB)),
        useMaterial3: true,
      ),
      home: const HomeDirectoryScreen(),
    );
  }
}

class HomeDirectoryScreen extends StatelessWidget {
  const HomeDirectoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('PMB Community Hub')),
      body: const Center(
        child: Text('Welcome to the PMB Community Hub'),
      ),
    );
  }
}