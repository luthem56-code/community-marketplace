import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'wallet_screen.dart';
import 'orders_screen.dart';
import 'wishlist_screen.dart';
import 'create_listing_screen.dart';
import 'seller_shop_screen.dart';
import 'help_center_screen.dart';
import 'auth_screen.dart';
import 'my_listings_manager_screen.dart';
import 'sales_screen.dart';
import 'purchases_screen.dart';
import 'buyer_offers_screen.dart';
import 'edit_profile_screen.dart';
import 'seller_discount_codes_screen.dart';
import 'admin_dashboard_screen.dart';
import '../services/admin_service.dart';
import 'seller_offers_screen.dart';
import '../widgets/user_avatar.dart';

class MyYagaDashboardScreen extends StatefulWidget {
  const MyYagaDashboardScreen({super.key});

  @override
  State<MyYagaDashboardScreen> createState() => _MyYagaDashboardScreenState();
}

class _MyYagaDashboardScreenState extends State<MyYagaDashboardScreen> {
  @override
  Widget build(BuildContext context) {
    // REAL-TIME AUTH LISTENER: Updates immediately when you log in or out!
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        final user = authSnapshot.data;
        final bool isLoggedIn = user != null && !user.isAnonymous;

        // --- 1. GUEST VIEW (PROMPT LOGIN) ---
        if (!isLoggedIn) {
          return Scaffold(
            backgroundColor: const Color(0xFFF9F9F9),
            appBar: AppBar(
              title: const Text('My Dashboard', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
              backgroundColor: Colors.white,
              elevation: 0.5,
              automaticallyImplyLeading: false,
            ),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.lock_outline, size: 70, color: Color(0xFF008080)),
                    const SizedBox(height: 16),
                    const Text('Sign In to Your Dashboard', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                    const SizedBox(height: 8),
                    Text(
                      'Log in or register to manage your wardrobe, track sales, view purchases, and withdraw wallet funds.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF008080), foregroundColor: Colors.white),
                        onPressed: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const AuthScreen()));
                        },
                        child: const Text('Sign In / Create Account', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        // --- 2. LOGGED IN VIEW (REAL USER) ---
        final currentUserId = user.uid;
        final displayName = (user.displayName != null && user.displayName!.isNotEmpty) ? user.displayName! : 'PMB Community Member';
        final email = user.email ?? 'Verified Resident';

        return Scaffold(
          backgroundColor: const Color(0xFFF8F9FA),
          appBar: AppBar(
            title: const Text('My Dashboard', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
            backgroundColor: Colors.white,
            elevation: 0.5,
            automaticallyImplyLeading: false,
            actions: [
              IconButton(
                icon: const Icon(Icons.help_outline, color: Colors.black),
                tooltip: 'Help Center',
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HelpCenterScreen())),
              ),
              IconButton(
                icon: const Icon(Icons.logout, color: Colors.red),
                tooltip: 'Log Out',
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                  if (context.mounted) {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const AuthScreen()),
                      (route) => false,
                    );
                  }
                },
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- ADMIN COMMAND BANNER (PROMINENT GOLDEN CARD IF ADMIN) ---
                StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance.collection('users').doc(currentUserId).snapshots(),
                  builder: (context, userSnap) {
                    bool isAdmin = false;

                    if (user.email != null && AdminService.adminEmails.contains(user.email!.trim().toLowerCase())) {
                      isAdmin = true;
                    }

                    if (userSnap.hasData && userSnap.data!.exists) {
                      final data = userSnap.data!.data() as Map<String, dynamic>?;
                      if (data?['role'] == 'admin') {
                        isAdmin = true;
                      }
                    }

                    if (!isAdmin) return const SizedBox.shrink();

                    return Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.amber.shade600, width: 1.5),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 8, offset: const Offset(0, 3)),
                        ],
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        leading: const CircleAvatar(
                          backgroundColor: Colors.amber,
                          child: Icon(Icons.admin_panel_settings, color: Color(0xFF1E293B), size: 22),
                        ),
                        title: const Text(
                          'ADMIN COMMAND CENTER 👑',
                          style: TextStyle(color: Colors.amber, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 0.8),
                        ),
                        subtitle: const Text(
                          'Manage escrow disputes, EFT payouts & moderation',
                          style: TextStyle(color: Colors.white70, fontSize: 11),
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios, color: Colors.amber, size: 14),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
                          );
                        },
                      ),
                    );
                  },
                ),

                // --- 1. USER PROFILE HEADER ---
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 32,
                        backgroundColor: const Color(0xFF008080),
                        child: UserAvatar(photoUrl: user.photoURL, name: displayName, radius: 32),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(displayName, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 2),
                            Text(email, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(color: const Color(0xFFE6F2F2), borderRadius: BorderRadius.circular(4)),
                                  child: const Row(
                                    children: [
                                      Icon(Icons.verified, size: 12, color: Color(0xFF008080)),
                                      SizedBox(width: 4),
                                      Text('Verified Resident', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF008080))),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Row(
                                  children: [
                                    Icon(Icons.star, size: 14, color: Colors.amber),
                                    SizedBox(width: 2),
                                    Text('5.0', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // --- 2. WALLET & ESCROW BALANCE CARD ---
                StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance.collection('wallets').doc(currentUserId).snapshots(),
                  builder: (context, snapshot) {
                    double balance = 0.0;
                    if (snapshot.hasData && snapshot.data!.exists) {
                      final data = snapshot.data!.data() as Map<String, dynamic>;
                      balance = (data['availableBalance'] as num?)?.toDouble() ?? 0.0;
                    }

                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF008080), Color(0xFF004D40)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(color: const Color(0xFF008080).withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 3)),
                        ],
                      ),
                      child: Row(
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.account_balance_wallet, color: Colors.white70, size: 16),
                                  SizedBox(width: 6),
                                  Text('My Wallet Balance', style: TextStyle(color: Colors.white70, fontSize: 12)),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'R ${balance.toStringAsFixed(2)}',
                                style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const Spacer(),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: const Color(0xFF008080),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WalletScreen())),
                            child: const Text('Withdraw EFT', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),

                // --- 3. SELLING MANAGEMENT (MY SHOP) ---
                const Text('SELLING (MY SHOP)', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.8)),
                const SizedBox(height: 8),

                Container(
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
                  child: Column(
                    children: [
                      // Holiday Mode Toggle
                      StreamBuilder<DocumentSnapshot>(
                        stream: FirebaseFirestore.instance.collection('users').doc(currentUserId).snapshots(),
                        builder: (context, snapshot) {
                          bool isHolidayMode = false;
                          if (snapshot.hasData && snapshot.data!.exists) {
                            isHolidayMode = (snapshot.data!.data() as Map<String, dynamic>?)?['isHolidayMode'] ?? false;
                          }

                          return SwitchListTile(
                            activeColor: const Color(0xFF008080),
                            secondary: const Icon(Icons.beach_access, color: Color(0xFF008080)),
                            title: const Text('Holiday Mode', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            subtitle: Text(
                              isHolidayMode ? 'Active: Sales are paused while you are away' : 'Turn on when away to pause sales',
                              style: TextStyle(fontSize: 11, color: isHolidayMode ? Colors.orange.shade800 : Colors.grey.shade600),
                            ),
                            value: isHolidayMode,
                            onChanged: (val) async {
                              await FirebaseFirestore.instance.collection('users').doc(currentUserId).update({'isHolidayMode': val});
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(val ? '🌴 Holiday mode enabled. Shop is paused.' : 'Welcome back! Shop is live.')),
                                );
                              }
                            },
                          );
                        },
                      ),
                      const Divider(height: 1),

                      _menuTile(
                        icon: Icons.inventory_2_outlined,
                        title: 'My Shop Listings',
                        subtitle: 'Manage active items, edit prices, mark sold',
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MyListingsManagerScreen())),
                      ),
                      const Divider(height: 1),
                      _menuTile(
                        icon: Icons.storefront_outlined,
                        title: 'My Public Shop / Wardrobe',
                        subtitle: 'View your storefront as community buyers see it',
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => SellerShopScreen(sellerId: currentUserId, shopName: displayName)));
                        },
                      ),
                      const Divider(height: 1),
                      _menuTile(
                        icon: Icons.add_box_outlined,
                        title: 'Add New Item',
                        subtitle: 'List clothes or items for free with 0% commission',
                        badge: '0% FEE',
                        badgeColor: Colors.green,
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateListingScreen())),
                      ),
                      const Divider(height: 1),
                      _menuTile(
                        icon: Icons.local_shipping_outlined,
                        title: 'My Sales (Orders to Ship)',
                        subtitle: 'Manage waybills, locker drop-offs & dispatch',
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SalesScreen())),
                      ),
                      const Divider(height: 1),
                      _menuTile(
                        icon: Icons.discount_outlined,
                        title: 'Shop Discount Codes',
                        subtitle: 'Create promo codes to share on WhatsApp',
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SellerDiscountCodesScreen())),
                      ),
                      _menuTile(
                    icon: Icons.local_offer,
                    title: 'Offers Received (Pending Approval)',
                    subtitle: 'Accept or decline price negotiations',
                    badge: 'OFFERS',
                    badgeColor: Colors.orange,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SellerOffersScreen())),
                  ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // --- 4. BUYING MANAGEMENT (MY SHOPPING) ---
                const Text('BUYING (MY SHOPPING)', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.8)),
                const SizedBox(height: 8),

                Container(
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
                  child: Column(
                    children: [
                      _menuTile(
                        icon: Icons.shopping_bag_outlined,
                        title: 'My Purchases',
                        subtitle: 'Track deliveries with 4-stage filters',
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PurchasesScreen())),
                      ),
                      const Divider(height: 1),
                      _menuTile(
                        icon: Icons.favorite_border,
                        title: 'Liked Items (Wishlist ❤️)',
                        subtitle: 'Items you have saved and favorited',
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WishlistScreen())),
                      ),
                      const Divider(height: 1),
                      _menuTile(
                        icon: Icons.local_offer_outlined,
                        title: 'My Sent Offers',
                        subtitle: 'Check negotiations sent to sellers',
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BuyerOffersScreen())),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // --- 5. LOGISTICS & SETTINGS ---
                const Text('ACCOUNT & SETTINGS', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.8)),
                const SizedBox(height: 8),

                Container(
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
                  child: Column(
                    children: [
                      _menuTile(
                        icon: Icons.edit_note_outlined,
                        title: 'Edit Profile & Shop Details',
                        subtitle: 'Change name, phone, bio, and upload photo',
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfileScreen())),
                      ),
                      const Divider(height: 1),
                      _menuTile(
                        icon: Icons.help_center_outlined,
                        title: 'Help Center & Guides',
                        subtitle: 'Escrow rules, dispute window, and prohibited items',
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HelpCenterScreen())),
                      ),
                      const Divider(height: 1),
                      _menuTile(
                        icon: Icons.logout,
                        title: 'Log Out',
                        titleColor: Colors.red,
                        iconColor: Colors.red,
                        onTap: () async {
                          await FirebaseAuth.instance.signOut();
                          if (context.mounted) {
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(builder: (_) => const AuthScreen()),
                              (route) => false,
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _menuTile({
    required IconData icon,
    required String title,
    String? subtitle,
    Color? iconColor,
    Color? titleColor,
    String? badge,
    Color? badgeColor,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        radius: 18,
        backgroundColor: (iconColor ?? const Color(0xFF008080)).withOpacity(0.1),
        child: Icon(icon, color: iconColor ?? const Color(0xFF008080), size: 20),
      ),
      title: Row(
        children: [
          Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: titleColor ?? Colors.black87)),
          if (badge != null) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: (badgeColor ?? Colors.green).withOpacity(0.15), borderRadius: BorderRadius.circular(4)),
              child: Text(badge, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: badgeColor ?? Colors.green)),
            ),
          ],
        ],
      ),
      subtitle: subtitle != null ? Text(subtitle, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)) : null,
      trailing: const Icon(Icons.chevron_right, size: 20, color: Colors.black38),
    );
  }
}