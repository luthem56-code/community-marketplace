import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import '../constants/pmb_data.dart';
import '../models/business_model.dart';

class WhatsAppService {
  static Future<void> makePhoneCall(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    await launchUrl(uri);
  }

  static Future<void> openChat({required String rawPhone, required String businessName}) async {
    final phone = rawPhone.replaceAll(RegExp(r'[^0-9+]'), '');
    final message = Uri.encodeComponent('Hello $businessName');
    final uri = Uri.parse('https://wa.me/$phone?text=$message');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

class HomeDirectoryScreen extends StatefulWidget {
  const HomeDirectoryScreen({super.key});

  @override
  State<HomeDirectoryScreen> createState() => _HomeDirectoryScreenState();
}

class _HomeDirectoryScreenState extends State<HomeDirectoryScreen> {
  String _selectedSuburb = "All Suburbs";
  String _selectedCategory = "All Categories";
  String _searchQuery = "";
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 700;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF2563EB),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.location_city_rounded, size: 20, color: Colors.white),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("PMB Community Hub", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text("Pietermaritzburg Local Directory", style: TextStyle(fontSize: 11, color: Colors.white70)),
              ],
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 1. HERO BANNER & SEARCH BAR
            _buildHeroBanner(isMobile),

            // 2. FILTER CONTROLS (SUBURBS & CATEGORIES)
            _buildFiltersSection(isMobile),

            const SizedBox(height: 16),

            // 3. LIVE BUSINESS DIRECTORY GRID
            Padding(
              padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 32),
              child: _buildBusinessGrid(isMobile),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroBanner(bool isMobile) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 20 : 48,
        vertical: isMobile ? 28 : 42,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E293B), Color(0xFF1D4ED8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(40),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              "📍 PIETERMARITZBURG & MIDLANDS",
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            "Support Local Businesses in Maritzburg",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: isMobile ? 24 : 34,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "Discover verified trades, home bakers, automotive repairs, and local events across PMB.",
            style: TextStyle(color: Colors.white70, fontSize: isMobile ? 13 : 15),
          ),
          const SizedBox(height: 20),

          // Search Field
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(color: Colors.black.withAlpha(25), blurRadius: 10, offset: const Offset(0, 4)),
              ],
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val.trim()),
              decoration: InputDecoration(
                hintText: "Search plumbers, cakes, car service, tutors...",
                hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF2563EB)),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = "");
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltersSection(bool isMobile) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 32, vertical: 14),
      child: Column(
        children: [
          // Suburb Dropdown Picker
          Row(
            children: [
              const Icon(Icons.pin_drop_rounded, size: 18, color: Color(0xFF2563EB)),
              const SizedBox(width: 8),
              const Text("Filter Suburb:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedSuburb,
                      isExpanded: true,
                      items: PmbData.suburbs.map((suburb) {
                        return DropdownMenuItem(
                          value: suburb,
                          child: Text(suburb, style: const TextStyle(fontSize: 13)),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedSuburb = val);
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Category Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: PmbData.categories.map((cat) {
                final isSelected = _selectedCategory == cat;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: FilterChip(
                    label: Text(cat),
                    selected: isSelected,
                    selectedColor: const Color(0xFF2563EB),
                    backgroundColor: const Color(0xFFF1F5F9),
                    labelStyle: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected ? Colors.white : const Color(0xFF334155),
                    ),
                    checkmarkColor: Colors.white,
                    onSelected: (selected) {
                      setState(() => _selectedCategory = cat);
                    },
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBusinessGrid(bool isMobile) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('businesses').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(40),
              child: CircularProgressIndicator(color: Color(0xFF2563EB)),
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text("Error loading businesses: ${snapshot.error}"),
            ),
          );
        }

        final docs = snapshot.data?.docs ?? [];
        final businesses = docs.map((d) => BusinessModel.fromFirestore(d)).where((b) {
          final matchesSearch = b.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              b.description.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              b.category.toLowerCase().contains(_searchQuery.toLowerCase());

          final matchesSuburb = (_selectedSuburb == "All Suburbs") || (b.suburb == _selectedSuburb);
          final matchesCategory = (_selectedCategory == "All Categories") || (b.category == _selectedCategory);

          return matchesSearch && matchesSuburb && matchesCategory;
        }).toList();

        if (businesses.isEmpty) {
          return _buildEmptyState();
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            int crossAxisCount = 1;
            if (constraints.maxWidth > 1000) {
              crossAxisCount = 3;
            } else if (constraints.maxWidth > 650) {
              crossAxisCount = 2;
            }

            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                mainAxisExtent: 230,
              ),
              itemCount: businesses.length,
              itemBuilder: (context, index) {
                return _buildBusinessCard(businesses[index]);
              },
            );
          },
        );
      },
    );
  }

  Widget _buildBusinessCard(BusinessModel business) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.storefront_rounded, color: Color(0xFF2563EB), size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            business.name,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F172A)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (business.isVerified)
                          const Tooltip(
                            message: "PMB Verified Local Business",
                            child: Icon(Icons.verified_rounded, color: Color(0xFF2563EB), size: 16),
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "${business.category} • ${business.suburb}",
                      style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child: Text(
              business.description.isNotEmpty ? business.description : "Local community business operating in ${business.suburb}.",
              style: const TextStyle(fontSize: 12, color: Color(0xFF475569), height: 1.4),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const Divider(height: 16),
          Row(
            children: [
              // Rating
              Row(
                children: [
                  const Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 16),
                  const SizedBox(width: 4),
                  Text(
                    business.rating.toStringAsFixed(1),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ],
              ),
              const Spacer(),
              // Phone Call
              if (business.phone.isNotEmpty)
                IconButton(
                  tooltip: "Call Business",
                  icon: const Icon(Icons.phone_rounded, color: Color(0xFF64748B), size: 20),
                  onPressed: () => WhatsAppService.makePhoneCall(business.phone),
                ),
              // WhatsApp Chat Button
              ElevatedButton.icon(
                onPressed: () => WhatsAppService.openChat(
                  rawPhone: business.whatsapp.isNotEmpty ? business.whatsapp : business.phone,
                  businessName: business.name,
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF16A34A),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.chat_bubble_rounded, size: 14),
                label: const Text("WhatsApp", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          const Icon(Icons.store_mall_directory_outlined, size: 54, color: Color(0xFF94A3B8)),
          const SizedBox(height: 12),
          const Text(
            "No listings found",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E293B)),
          ),
          const SizedBox(height: 4),
          Text(
            "Try clearing your search query or selecting 'All Suburbs'.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}