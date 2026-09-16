import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/listing_model.dart';
import 'listing_detail_screen.dart';
import 'wallet_screen.dart';
import 'create_listing_screen.dart';
import 'wishlist_screen.dart';
import 'sales_screen.dart';
import 'my_listings_manager_screen.dart';
import 'help_center_screen.dart';
import 'how_it_works_screen.dart';
import 'auth_screen.dart';
import 'admin_dashboard_screen.dart';
import '../services/admin_service.dart';

class MarketplaceFeedScreen extends StatefulWidget {
  const MarketplaceFeedScreen({super.key});

  @override
  State<MarketplaceFeedScreen> createState() => _MarketplaceFeedScreenState();
}

class _MarketplaceFeedScreenState extends State<MarketplaceFeedScreen> {
  String _selectedCategory = 'All';
  String _selectedBrand = '';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  final List<String> _popularBrands = [
    'All Brands',
    'Zara',
    'Cotton On',
    'Nike',
    'H&M',
    'Levi\'s',
    'Adidas',
    'Woolworths',
    'Country Road',
    'Foschini',
    'Mr Price',
  ];

  final List<Map<String, dynamic>> _categoryChips = [
    {'name': 'All', 'icon': Icons.grid_view_rounded},
    {'name': 'Women', 'icon': Icons.woman_rounded},
    {'name': 'Men', 'icon': Icons.man_rounded},
    {'name': 'Kids & Babies', 'icon': Icons.child_care_rounded},
    {'name': 'Beauty & Care', 'icon': Icons.spa_rounded},
    {'name': 'Accessories', 'icon': Icons.watch_rounded},
    {'name': 'Shoes', 'icon': Icons.roller_skating_outlined},
    {'name': 'Home', 'icon': Icons.chair_rounded},
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Query query = FirebaseFirestore.instance.collection('listings');

    if (_selectedCategory != 'All') {
      query = query.where('category', isEqualTo: _selectedCategory);
    } else {
      query = query.where('status', isEqualTo: 'active');
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      drawer: _buildMarketplaceDrawer(context),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu, color: Colors.black87),
            tooltip: 'Menu',
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
        title: const Text(
          'COMMUNITY MARKET',
          style: TextStyle(
            color: Color(0xFF008080),
            fontWeight: FontWeight.w900,
            letterSpacing: 1.1,
            fontSize: 17,
          ),
        ),
        actions: [
          // Yaga Top Right 1: Liked Items / Wishlist Heart
          IconButton(
            icon: const Icon(Icons.favorite_border, color: Colors.black87),
            tooltip: 'Liked Items',
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const WishlistScreen()));
            },
          ),
          // Yaga Top Right 2: My Wallet
          IconButton(
            icon: const Icon(Icons.account_balance_wallet_outlined, color: Colors.black87),
            tooltip: 'My Wallet',
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const WalletScreen()));
            },
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          // 1. Search Bar
          SliverToBoxAdapter(
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Container(
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search, color: Colors.black54, size: 20),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    hintText: 'Search Zara, dresses, shoes, jackets...',
                    hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
            ),
          ),

          // 2. Isolated Hero Promotional Carousel (Never flips or jitters the feed below!)
          const SliverToBoxAdapter(
            child: _HeroBannerCarousel(),
          ),

          // 3. Circular Category Tiles
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Explore Categories', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 80,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _categoryChips.length,
                      itemBuilder: (context, index) {
                        final cat = _categoryChips[index];
                        final isSelected = _selectedCategory == cat['name'];
                        return GestureDetector(
                          onTap: () => setState(() => _selectedCategory = cat['name']),
                          child: Padding(
                            padding: const EdgeInsets.only(right: 14),
                            child: Column(
                              children: [
                                CircleAvatar(
                                  radius: 25,
                                  backgroundColor: isSelected ? const Color(0xFF008080) : Colors.white,
                                  child: Icon(
                                    cat['icon'] as IconData,
                                    color: isSelected ? Colors.white : Colors.black87,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  cat['name'],
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                    color: isSelected ? const Color(0xFF008080) : Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 4. Popular Brands Horizontal Rail
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Popular Brands', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 36,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _popularBrands.length,
                      itemBuilder: (context, index) {
                        final brand = _popularBrands[index];
                        final isSelected = _selectedBrand == brand || (_selectedBrand.isEmpty && brand == 'All Brands');

                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(brand),
                            selected: isSelected,
                            selectedColor: const Color(0xFF008080),
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.white : Colors.black87,
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                            backgroundColor: Colors.white,
                            side: BorderSide(color: isSelected ? const Color(0xFF008080) : Colors.grey.shade300),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                            onSelected: (val) {
                              setState(() {
                                _selectedBrand = (brand == 'All Brands') ? '' : brand;
                              });
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 5. Section Header: Recently Added
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _selectedCategory == 'All' ? 'Recently Added' : 'Items in $_selectedCategory',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  if (_selectedBrand.isNotEmpty)
                    Text('Filtered by: $_selectedBrand', style: const TextStyle(fontSize: 12, color: Color(0xFF008080), fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),

          // 6. Realtime 2-Column Product Grid
          StreamBuilder<QuerySnapshot>(
            stream: query.snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(child: CircularProgressIndicator(color: Color(0xFF008080))),
                  ),
                );
              }

              var docs = snapshot.data?.docs ?? [];

              // Filter by brand
              if (_selectedBrand.isNotEmpty) {
                docs = docs.where((d) {
                  final brand = (d.data() as Map<String, dynamic>)['brand']?.toString().toLowerCase() ?? '';
                  return brand == _selectedBrand.toLowerCase();
                }).toList();
              }

              // Filter by search query
              if (_searchQuery.isNotEmpty) {
                docs = docs.where((d) {
                  final data = d.data() as Map<String, dynamic>;
                  final title = (data['title'] ?? '').toString().toLowerCase();
                  final brand = (data['brand'] ?? '').toString().toLowerCase();
                  final desc = (data['description'] ?? '').toString().toLowerCase();
                  return title.contains(_searchQuery) || brand.contains(_searchQuery) || desc.contains(_searchQuery);
                }).toList();
              }

              if (docs.isEmpty) {
                return SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: Column(
                      children: [
                        Icon(Icons.checkroom_outlined, size: 54, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        const Text('No listings found', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 4),
                        Text('Try resetting brand or category filters.', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                      ],
                    ),
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.64,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 12,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final listing = ListingModel.fromFirestore(docs[index]);
                      return _ProductCard(listing: listing);
                    },
                    childCount: docs.length,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // --- YAGA-STYLE SIDE BAR MENU ---
  Widget _buildMarketplaceDrawer(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final isLoggedIn = user != null && !user.isAnonymous;
    final uid = user?.uid ?? '';
    final name = user?.displayName ?? (isLoggedIn ? 'Community Member' : 'Guest Visitor');
    final email = user?.email ?? 'Sign in to start selling & buying';

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF008080), Color(0xFF004D40)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : 'G',
                style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF008080)),
              ),
            ),
            accountName: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            accountEmail: isLoggedIn
                ? StreamBuilder<DocumentSnapshot>(
                    stream: FirebaseFirestore.instance.collection('wallets').doc(uid).snapshots(),
                    builder: (context, snap) {
                      double balance = 0.0;
                      if (snap.hasData && snap.data!.exists) {
                        balance = ((snap.data!.data() as Map<String, dynamic>)['availableBalance'] as num?)?.toDouble() ?? 0.0;
                      }
                      return Text('Wallet: R ${balance.toStringAsFixed(2)} available', style: const TextStyle(color: Colors.white70));
                    },
                  )
                : Text(email, style: const TextStyle(color: Colors.white70)),
          ),

          if (!isLoggedIn)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF008080),
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.login),
                label: const Text('Sign In / Register', style: TextStyle(fontWeight: FontWeight.bold)),
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const AuthScreen()));
                },
              ),
            ),

          ListTile(
            leading: const Icon(Icons.storefront, color: Color(0xFF008080)),
            title: const Text('Browse Market'),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.add_circle_outline, color: Color(0xFF008080)),
            title: const Text('Sell an Item (0% Commission)'),
            onTap: () {
              Navigator.pop(context);
              if (!isLoggedIn) {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const AuthScreen()));
              } else {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateListingScreen()));
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.inventory_2_outlined, color: Color(0xFF008080)),
            title: const Text('My Shop Listings'),
            subtitle: const Text('Manage active wardrobe items & prices', style: TextStyle(fontSize: 11)),
            onTap: () {
              Navigator.pop(context);
              if (!isLoggedIn) {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const AuthScreen()));
              } else {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const MyListingsManagerScreen()));
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.local_shipping_outlined, color: Color(0xFF008080)),
            title: const Text('My Sales (To Ship)'),
            onTap: () {
              Navigator.pop(context);
              if (!isLoggedIn) {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const AuthScreen()));
              } else {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const SalesScreen()));
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.shopping_bag_outlined, color: Color(0xFF008080)),
            title: const Text('My Purchases (Bought)'),
            onTap: () {
              Navigator.pop(context);
              if (!isLoggedIn) {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const AuthScreen()));
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Purchases are currently unavailable.')),
                );
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.account_balance_wallet_outlined, color: Color(0xFF008080)),
            title: const Text('Wallet & Payouts (EFT)'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const WalletScreen()));
            },
          ),
          const Divider(),

          // --- ADMIN-ONLY ENTRY (COMPLETELY INVISIBLE TO NON-ADMINS) ---
          if (isLoggedIn)
            StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
              builder: (context, userSnap) {
                bool isAdmin = false;

                if (user?.email != null && AdminService.adminEmails.contains(user!.email!.trim().toLowerCase())) {
                  isAdmin = true;
                }

                if (userSnap.hasData && userSnap.data!.exists) {
                  final data = userSnap.data!.data() as Map<String, dynamic>?;
                  if (data?['role'] == 'admin') {
                    isAdmin = true;
                  }
                }

                if (!isAdmin) return const SizedBox.shrink();

                return Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.admin_panel_settings, color: Colors.amber),
                      title: const Text(
                        'Admin Command Center',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                      ),
                      subtitle: const Text('Disputes, payouts & moderation', style: TextStyle(fontSize: 11)),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminDashboardScreen()));
                      },
                    ),
                    const Divider(),
                  ],
                );
              },
            ),

          ListTile(
            leading: const Icon(Icons.help_center_outlined, color: Color(0xFF008080)),
            title: const Text('Help Center & Guides'),
            subtitle: const Text('Buying, selling, safety & terms', style: TextStyle(fontSize: 11)),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const HelpCenterScreen()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.shield_outlined, color: Colors.green),
            title: const Text('How Marketplace Works'),
            subtitle: const Text('6-step escrow protection guide', style: TextStyle(fontSize: 11)),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const HowItWorksScreen()));
            },
          ),
        ],
      ),
    );
  }
}

// --- ISOLATED HERO BANNER CAROUSEL ---
class _HeroBannerCarousel extends StatefulWidget {
  const _HeroBannerCarousel();

  @override
  State<_HeroBannerCarousel> createState() => _HeroBannerCarouselState();
}

class _HeroBannerCarouselState extends State<_HeroBannerCarousel> {
  final PageController _pageController = PageController();
  int _currentBannerIndex = 0;
  Timer? _carouselTimer;

  final List<Map<String, dynamic>> _heroBanners = [
    {
      'title': 'Sell Clothes for FREE',
      'subtitle': '0% seller commission. Turn your wardrobe into cash in 60s.',
      'tag': '0% COMMISSION',
      'colors': [Color(0xFF008080), Color(0xFF004D40)],
      'icon': Icons.sell_outlined,
    },
    {
      'title': '100% Escrow Protection',
      'subtitle': 'Shop with trust. Funds are released only after parcel delivery.',
      'tag': 'SAFE SHOPPING',
      'colors': [Color(0xFF1E3C72), Color(0xFF2A5298)],
      'icon': Icons.shield_outlined,
    },
    {
      'title': 'Free Local PMB Meetup',
      'subtitle': 'Collect from neighbors in Pietermaritzburg & save R60 on couriers.',
      'tag': 'PMB COMMUNITY',
      'colors': [Color(0xFF512DA8), Color(0xFF673AB7)],
      'icon': Icons.place_outlined,
    },
  ];

  @override
  void initState() {
    super.initState();
    _carouselTimer = Timer.periodic(const Duration(milliseconds: 4500), (timer) {
      if (_pageController.hasClients) {
        final nextPage = (_currentBannerIndex + 1) % _heroBanners.length;
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _carouselTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(
        children: [
          SizedBox(
            height: 140,
            child: PageView.builder(
              controller: _pageController,
              itemCount: _heroBanners.length,
              onPageChanged: (i) => setState(() => _currentBannerIndex = i),
              itemBuilder: (context, index) {
                final b = _heroBanners[index];
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: b['colors'] as List<Color>,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: (b['colors'][0] as Color).withOpacity(0.25),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                b['tag'],
                                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              b['title'],
                              style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              b['subtitle'],
                              maxLines: 2,
                              style: const TextStyle(color: Colors.white70, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      Icon(b['icon'] as IconData, size: 54, color: Colors.white.withOpacity(0.85)),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              _heroBanners.length,
              (i) => Container(
                width: _currentBannerIndex == i ? 18 : 6,
                height: 5,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  color: _currentBannerIndex == i ? const Color(0xFF008080) : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// --- PRODUCT CARD WITH LIVE TOTAL LIKES COUNTER ---
class _ProductCard extends StatelessWidget {
  final ListingModel listing;
  const _ProductCard({required this.listing});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final bool isLoggedIn = user != null && !user.isAnonymous;

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ListingDetailScreen(listing: listing)),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Item Image with Size Badge & Realtime Wishlist Heart + Live Counter
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: listing.imageUrls.isNotEmpty
                        ? Image.network(
                            listing.imageUrls.first,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(color: Colors.grey.shade200),
                          )
                        : Container(color: Colors.grey.shade200),
                  ),

                  // 1. Size Badge (Top Left)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        listing.size.toUpperCase(),
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),

                  // 2. Interactive Favorite Heart + Live Counter Badge (Top Right)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: StreamBuilder<DocumentSnapshot>(
                      stream: isLoggedIn
                          ? FirebaseFirestore.instance
                              .collection('users')
                              .doc(user.uid)
                              .collection('favorites')
                              .doc(listing.id)
                              .snapshots()
                          : null,
                      builder: (context, favSnap) {
                        final isFavorite = favSnap.hasData && favSnap.data!.exists;

                        return StreamBuilder<DocumentSnapshot>(
                          stream: FirebaseFirestore.instance.collection('listings').doc(listing.id).snapshots(),
                          builder: (context, listingSnap) {
                            int totalLikes = 0;
                            if (listingSnap.hasData && listingSnap.data!.exists) {
                              final data = listingSnap.data!.data() as Map<String, dynamic>?;
                              totalLikes = (data?['likesCount'] as num?)?.toInt() ?? 0;
                            }

                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.45),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: InkWell(
                                onTap: () async {
                                  if (!isLoggedIn) {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (_) => const AuthScreen()),
                                    );
                                    return;
                                  }

                                  final favDoc = FirebaseFirestore.instance
                                      .collection('users')
                                      .doc(user.uid)
                                      .collection('favorites')
                                      .doc(listing.id);

                                  final listingDoc = FirebaseFirestore.instance
                                      .collection('listings')
                                      .doc(listing.id);

                                  if (isFavorite) {
                                    await favDoc.delete();
                                    await listingDoc.update({'likesCount': FieldValue.increment(-1)});
                                  } else {
                                    await favDoc.set({
                                      'listingId': listing.id,
                                      'createdAt': FieldValue.serverTimestamp(),
                                    });
                                    await listingDoc.update({'likesCount': FieldValue.increment(1)});
                                  }
                                },
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      isFavorite ? Icons.favorite : Icons.favorite_border,
                                      color: isFavorite ? Colors.red : Colors.white,
                                      size: 15,
                                    ),
                                    if (totalLikes > 0) ...[
                                      const SizedBox(width: 4),
                                      Text(
                                        '$totalLikes',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            // Item Details
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'R ${listing.price.toStringAsFixed(0)}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF008080)),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    listing.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  Text(
                    listing.brand,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}