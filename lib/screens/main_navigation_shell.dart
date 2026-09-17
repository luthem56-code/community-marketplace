import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'marketplace_feed_screen.dart';
import 'explore_screen.dart';
import 'create_listing_screen.dart';
import 'notifications_screen.dart';
import 'my_yaga_dashboard_screen.dart';
import 'auth_screen.dart';

class MainNavigationShell extends StatefulWidget {
  const MainNavigationShell({super.key});

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const MarketplaceFeedScreen(),     // Tab 0: Home / Discovery Feed
    const ExploreScreen(),             // Tab 1: Explore & Categories
    const SizedBox(),                  // Tab 2: Intercepted for Sell (+)
    const NotificationsScreen(),       // Tab 3: Activity & Notifications Hub
    const MyYagaDashboardScreen(),     // Tab 4: My Yaga (Personal Dashboard)
  ];

  @override
  Widget build(BuildContext context) {
    // REAL-TIME AUTH STREAM: Eliminates any delay in recognizing the logged-in user!
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnap) {
        final user = authSnap.data;
        final currentUserId = user?.uid ?? '';

        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) {
            if (didPop) return;
            if (_currentIndex != 0) {
              setState(() => _currentIndex = 0);
            }
          },
          child: Scaffold(
            body: IndexedStack(
              index: _currentIndex,
              children: _pages,
            ),
            bottomNavigationBar: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 10,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: BottomNavigationBar(
                currentIndex: _currentIndex,
                onTap: (index) async {
                  if (index == 2) {
                    if (user == null || user.isAnonymous) {
                      final loggedIn = await Navigator.push<bool>(
                        context,
                        MaterialPageRoute(builder: (_) => const AuthScreen()),
                      );
                      if (loggedIn != true) return;
                    }
                    if (!context.mounted) return;
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const CreateListingScreen()),
                    );
                    return;
                  }
                  setState(() => _currentIndex = index);
                },
                type: BottomNavigationBarType.fixed,
                backgroundColor: Colors.white,
                selectedItemColor: const Color(0xFF008080),
                unselectedItemColor: Colors.grey.shade500,
                selectedFontSize: 11,
                unselectedFontSize: 11,
                selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
                items: [
                  const BottomNavigationBarItem(
                    icon: Icon(Icons.storefront_outlined),
                    activeIcon: Icon(Icons.storefront),
                    label: 'Feed',
                  ),
                  const BottomNavigationBarItem(
                    icon: Icon(Icons.explore_outlined),
                    activeIcon: Icon(Icons.explore),
                    label: 'Explore',
                  ),
                  BottomNavigationBarItem(
                    icon: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Color(0xFF008080),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.add, color: Colors.white, size: 24),
                    ),
                    label: 'Sell',
                  ),
                  BottomNavigationBarItem(
                    icon: StreamBuilder<QuerySnapshot>(
                      stream: currentUserId.isNotEmpty
                          ? FirebaseFirestore.instance
                              .collection('notifications')
                              .where('userId', isEqualTo: currentUserId)
                              .where('isRead', isEqualTo: false)
                              .snapshots()
                          : null,
                      builder: (context, snap) {
                        final unreadCount = snap.data?.docs.length ?? 0;

                        return Stack(
                          clipBehavior: Clip.none,
                          children: [
                            const Icon(Icons.notifications_none_rounded),
                            if (unreadCount > 0)
                              Positioned(
                                top: -2,
                                right: -6,
                                child: Container(
                                  padding: const EdgeInsets.all(3),
                                  decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                                  constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
                                  alignment: Alignment.center,
                                  child: Text(
                                    '$unreadCount',
                                    style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                    activeIcon: const Icon(Icons.notifications),
                    label: 'Activity',
                  ),
                  const BottomNavigationBarItem(
                    icon: Icon(Icons.person_outline),
                    activeIcon: Icon(Icons.person),
                    label: 'My Yaga',
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}