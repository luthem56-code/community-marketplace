import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/listing_model.dart';
import 'listing_detail_screen.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'All';
  String _activeFilter = '';

  final List<Map<String, dynamic>> _mainCategories = [
    {
      'title': 'Women',
      'icon': Icons.woman_rounded,
      'color': Color(0xFFE91E63),
      'sub': ['Dresses', 'Tops & Tees', 'Jackets & Coats', 'Pants & Jeans', 'Skirts', 'Knitwear']
    },
    {
      'title': 'Men',
      'icon': Icons.man_rounded,
      'color': Color(0xFF2196F3),
      'sub': ['T-Shirts & Polos', 'Shirts', 'Hoodies & Sweaters', 'Jeans & Chinos', 'Jackets', 'Shorts']
    },
    {
      'title': 'Kids & Babies',
      'icon': Icons.child_care_rounded,
      'color': Color(0xFFFF9800),
      'sub': ['School Uniforms', 'Baby Wear (0-24m)', 'Girls Clothing', 'Boys Clothing', 'Kids Shoes']
    },
    {
      'title': 'Shoes & Sneakers',
      'icon': Icons.roller_skating_outlined,
      'color': Color(0xFF9C27B0),
      'sub': ['Sneakers', 'Boots', 'Heels', 'Sandals', 'Formal Shoes']
    },
    {
      'title': 'Accessories & Bags',
      'icon': Icons.watch_rounded,
      'color': Color(0xFF009688),
      'sub': ['Handbags & Totes', 'Jewellery', 'Belts & Hats', 'Sunglasses', 'Wallets']
    },
    {
      'title': 'Beauty & Care',
      'icon': Icons.spa_rounded,
      'color': Color(0xFF4CAF50),
      'sub': ['Skincare (Sealed)', 'Hair Care', 'Nail Care', 'Tools & Brushes']
    },
    {
      'title': 'Home & Living',
      'icon': Icons.chair_rounded,
      'color': Color(0xFF795548),
      'sub': ['Decor', 'Bedding & Cushions', 'Kitchenware', 'Books & Stationery']
    },
  ];

  final List<String> _trendingTags = [
    'Zara',
    'Denim Jacket',
    'Sneakers',
    'School Uniforms',
    'Cotton On',
    'Midi Dress',
    'Nike',
    'Winter Coat',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        title: const Text('Explore & Search', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        automaticallyImplyLeading: false, // Clean bottom tab (no back arrow)
      ),
      body: CustomScrollView(
        slivers: [
          // 1. Search Bar
          SliverToBoxAdapter(
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Container(
                height: 46,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: TextField(
                  controller: _searchController,
                  onSubmitted: (val) {
                    setState(() => _activeFilter = val.trim());
                  },
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search, color: Colors.black54),
                    suffixIcon: _activeFilter.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _activeFilter = '';
                                _selectedCategory = 'All';
                              });
                            },
                          )
                        : null,
                    hintText: 'Search items, brands, sizes...',
                    hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ),
          ),

          // 2. Trending Searches Rail
          SliverToBoxAdapter(
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Trending in Community', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: _trendingTags.map((tag) {
                      return ActionChip(
                        label: Text(tag, style: const TextStyle(fontSize: 11)),
                        backgroundColor: Colors.grey.shade100,
                        side: BorderSide(color: Colors.grey.shade300),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        onPressed: () {
                          _searchController.text = tag;
                          setState(() => _activeFilter = tag);
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),

          // 3. Category Tree or Search Results
          if (_activeFilter.isNotEmpty || _selectedCategory != 'All')
            // Shows filtered items if search/category active
            _buildFilteredResults()
          else
            // Shows Full Category Tree (Yaga-style expandable directory)
            _buildCategoryHierarchy(),
        ],
      ),
    );
  }

  // --- FULL CATEGORY HIERARCHY TREE ---
  Widget _buildCategoryHierarchy() {
    return SliverPadding(
      padding: const EdgeInsets.all(16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final cat = _mainCategories[index];
            final subCategories = cat['sub'] as List<String>;
            final color = cat['color'] as Color;

            return Card(
              elevation: 0.5,
              margin: const EdgeInsets.only(bottom: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              clipBehavior: Clip.antiAlias,
              child: ExpansionTile(
                leading: CircleAvatar(
                  backgroundColor: color.withOpacity(0.12),
                  child: Icon(cat['icon'] as IconData, color: color, size: 22),
                ),
                title: Text(
                  cat['title'] as String,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                subtitle: Text('${subCategories.length} sub-categories', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                children: [
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: subCategories.map((sub) {
                        return InkWell(
                          onTap: () {
                            setState(() {
                              _selectedCategory = cat['title'] as String;
                              _activeFilter = sub;
                              _searchController.text = sub;
                            });
                          },
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Text(sub, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            );
          },
          childCount: _mainCategories.length,
        ),
      ),
    );
  }

  // --- FILTERED RESULTS VIEW ---
  Widget _buildFilteredResults() {
    Query query = FirebaseFirestore.instance.collection('listings').where('status', isEqualTo: 'active');

    if (_selectedCategory != 'All') {
      query = query.where('category', isEqualTo: _selectedCategory);
    }

    return StreamBuilder<QuerySnapshot>(
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

        if (_activeFilter.isNotEmpty) {
          final q = _activeFilter.toLowerCase();
          docs = docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final title = (data['title'] ?? '').toString().toLowerCase();
            final brand = (data['brand'] ?? '').toString().toLowerCase();
            final desc = (data['description'] ?? '').toString().toLowerCase();
            return title.contains(q) || brand.contains(q) || desc.contains(q);
          }).toList();
        }

        if (docs.isEmpty) {
          return SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: Column(
                children: [
                  Icon(Icons.search_off, size: 54, color: Colors.grey.shade400),
                  const SizedBox(height: 12),
                  Text('No items found for "$_activeFilter"', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 4),
                  Text('Try another keyword or category.', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                ],
              ),
            ),
          );
        }

        return SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.64,
              crossAxisSpacing: 10,
              mainAxisSpacing: 12,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final item = ListingModel.fromFirestore(docs[index]);
                return InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => ListingDetailScreen(listing: item)),
                    );
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 2)),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: item.imageUrls.isNotEmpty
                              ? Image.network(item.imageUrls.first, fit: BoxFit.cover, width: double.infinity)
                              : Container(color: Colors.grey.shade200),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('R ${item.price.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF008080), fontSize: 15)),
                              Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              Text('${item.brand} • ${item.size}', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
              childCount: docs.length,
            ),
          ),
        );
      },
    );
  }
}