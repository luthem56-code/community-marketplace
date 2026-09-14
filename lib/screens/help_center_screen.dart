import 'package:flutter/material.dart';
import 'how_it_works_screen.dart';

class HelpCenterScreen extends StatefulWidget {
  const HelpCenterScreen({super.key});

  @override
  State<HelpCenterScreen> createState() => _HelpCenterScreenState();
}

class _HelpCenterScreenState extends State<HelpCenterScreen> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  // All Promoted Articles from Yaga's Knowledge Base
  final List<Map<String, dynamic>> _articles = [
    {
      'title': 'How Marketplace works?',
      'category': 'General',
      'icon': Icons.lightbulb_outline,
      'isSpecialLink': true, // Links directly to our 6-step visual screen
      'snippet': 'Learn how escrow protects money, how couriers deliver, and how payouts work.',
      'content': '',
    },
    {
      'title': 'Prohibited items policy',
      'category': 'Terms & Conditions',
      'icon': Icons.block,
      'isSpecialLink': false,
      'snippet': 'Items you cannot sell: Counterfeits, used underwear, unsealed cosmetics...',
      'content':
          'To keep our community safe and compliant with South African consumer laws, the following items are strictly prohibited on the platform:\n\n'
          '• Replicas & Counterfeit Goods: Fake designer bags, clothing, or shoes.\n'
          '• Used Intimates: Used underwear, swimwear without hygienic liners.\n'
          '• Opened Cosmetics: Used perfumes, opened creams, or unsealed makeup due to health risks.\n'
          '• Medication & Supplements: Prescription drugs, vitamins, or medical devices.\n'
          '• Weapons & Hazardous Materials: Knives, pepper sprays, or flammable liquids.\n\n'
          'Listings violating these policies will be removed immediately.',
    },
    {
      'title': 'Returns & Refund policy',
      'category': 'Safety',
      'icon': Icons.assignment_return_outlined,
      'isSpecialLink': false,
      'snippet': 'The 48-hour inspection window and how escrow protects against defective goods.',
      'content':
          'Every transaction is protected by our 48-Hour Inspection Window:\n\n'
          '1. Delivery Confirmation: When your parcel is delivered or picked up, you have 48 hours to inspect the item.\n'
          '2. Raising a Dispute: If the item is torn, stained, fake, or not as described in the listing, tap "Something wrong with item? Report issue" on your order card.\n'
          '3. Escrow Freeze: This immediately freezes the seller payout.\n'
          '4. Resolutions: If a return is granted, the item is sent back and the buyer receives a 100% refund.\n\n'
          'Note: Sizing issues or changing your mind are not grounds for a dispute unless measurements were misrepresented by the seller.',
    },
    {
      'title': 'Buyer made an offer on my item — what\'s next?',
      'category': 'Selling',
      'icon': Icons.local_offer_outlined,
      'isSpecialLink': false,
      'snippet': 'How to accept, decline, or counter price negotiations.',
      'content':
          'When an interested buyer makes a price offer on your listing:\n\n'
          '1. You will receive a notification and see the offer in your "Orders & Offers" tab.\n'
          '2. You have three choices:\n'
          '   • Accept: Unlocks a 24-hour window for the buyer to purchase at the discounted price.\n'
          '   • Decline: The listing stays at its original price.\n'
          '   • Counter: Propose an in-between price that suits both of you.\n'
          '3. Accepting an offer does not lock the item exclusively — other buyers can still purchase it at full listed price until the offer is paid for.',
    },
    {
      'title': 'How to spot replica & counterfeit items?',
      'category': 'Safety',
      'icon': Icons.verified_outlined,
      'isSpecialLink': false,
      'snippet': 'Tips for checking authenticity before making high-value purchases.',
      'content':
          'Buying luxury or branded items (e.g. Nike, Zara, luxury bags)? Look out for:\n\n'
          '• Care Labels: Authentic items have clean, crisp font printing on the inner wash tag.\n'
          '• Stitching: High-end garments feature even, tight, double-stitching with zero loose threads.\n'
          '• Receipts & Proof of Purchase: Always ask the seller in the in-app chat if they still have the original store receipt or digital invoice.\n'
          '• If the price looks too good to be true, ask the seller for a video or close-up photo of the brand badge before checkout.',
    },
    {
      'title': 'How to leave feedback for a Seller or Buyer?',
      'category': 'General',
      'icon': Icons.star_border,
      'isSpecialLink': false,
      'snippet': 'Build community trust with honest star ratings and reviews.',
      'content':
          'Trust in Pietermaritzburg is built on feedback:\n\n'
          '• Once an order is completed ("Item Received"), both buyer and seller are invited to rate the transaction from 1 to 5 stars.\n'
          '• You can leave comments praising fast courier shipping, accurate descriptions, or friendly communication.\n'
          '• High-rated sellers earn the "Top Seller" badge and sell their clothes 3x faster!',
    },
    {
      'title': 'Terms and Conditions of User Agreement',
      'category': 'Terms & Conditions',
      'icon': Icons.gavel_outlined,
      'isSpecialLink': false,
      'snippet': 'User rights, escrow platform liability, and South African legal compliance.',
      'content':
          'TERMS & CONDITIONS SUMMARY (South Africa):\n\n'
          '1. Escrow Service: The platform holds funds in trust between buyer and seller. Funds belong to the buyer until delivery confirmation or dispute expiry.\n'
          '2. 0% Commission for Sellers: Standard wardrobe listings incur 0% commission. The platform is funded via the Buyer Protection Fee paid at checkout.\n'
          '3. Prohibited Transactions: Users may not trade outside the platform via direct bank transfer or WhatsApp cash drops. Off-platform deals void all escrow protections.\n'
          '4. Privacy & POPIA: Personal data, contact numbers, and delivery addresses are encrypted and shared solely for the purpose of waybill delivery.\n\n'
          'By using this platform, you agree to these fair-trade community standards.',
    },
  ];

  void _openArticleReader(Map<String, dynamic> article) {
    if (article['isSpecialLink'] == true) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const HowItWorksScreen()),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: const Color(0xFFE6F2F2),
                  child: Icon(article['icon'] as IconData, color: const Color(0xFF008080)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        article['category'] as String,
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF008080)),
                      ),
                      Text(
                        article['title'] as String,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  article['content'] as String,
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade800, height: 1.55),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF008080),
                  foregroundColor: Colors.white,
                ),
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Close Article', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _filterByCategory(String cat) {
    setState(() {
      _searchQuery = cat.toLowerCase();
      _searchController.text = cat;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredArticles = _articles.where((a) {
      final title = (a['title'] as String).toLowerCase();
      final snippet = (a['snippet'] as String).toLowerCase();
      final cat = (a['category'] as String).toLowerCase();
      return title.contains(_searchQuery) || snippet.contains(_searchQuery) || cat.contains(_searchQuery);
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        title: const Text('Help & Guides', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- 1. SEARCH HEADER ---
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'How can we help you?',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Search our guides for buying, selling, escrow safety, and courier delivery.',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    height: 46,
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
                        hintText: 'Search topics, e.g. "returns", "offer", "payout"...',
                        hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // --- 2. THE 5 MAIN CATEGORY BUTTONS (YAGA-STYLE) ---
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Browse by Topic', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _categoryCard('Selling', Icons.sell_outlined, () => _filterByCategory('Selling')),
                      const SizedBox(width: 10),
                      _categoryCard('Buying', Icons.shopping_bag_outlined, () => _filterByCategory('Buying')),
                      const SizedBox(width: 10),
                      _categoryCard('Safety', Icons.shield_outlined, () => _filterByCategory('Safety')),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _categoryCard('Technical Issues', Icons.build_outlined, () => _filterByCategory('Technical')),
                      const SizedBox(width: 10),
                      _categoryCard('Terms & Conditions', Icons.gavel_outlined, () => _filterByCategory('Terms')),
                    ],
                  ),
                ],
              ),
            ),

            // --- 3. PROMOTED ARTICLES LIST ---
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _searchQuery.isEmpty ? 'Promoted Articles' : 'Search Results (${filteredArticles.length})',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  if (_searchQuery.isNotEmpty)
                    GestureDetector(
                      onTap: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                      child: const Text('Reset', style: TextStyle(color: Color(0xFF008080), fontWeight: FontWeight.bold, fontSize: 13)),
                    ),
                ],
              ),
            ),

            if (filteredArticles.isEmpty)
              Padding(
                padding: const EdgeInsets.all(32),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.help_outline, size: 48, color: Colors.grey.shade400),
                      const SizedBox(height: 8),
                      Text('No articles found for "$_searchQuery"', style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text('Try searching "selling", "escrow", or "delivery".', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                    ],
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: filteredArticles.length,
                itemBuilder: (context, index) {
                  final a = filteredArticles[index];
                  return Card(
                    elevation: 0.5,
                    margin: const EdgeInsets.only(bottom: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      leading: CircleAvatar(
                        backgroundColor: const Color(0xFFE6F2F2),
                        child: Icon(a['icon'] as IconData, color: const Color(0xFF008080), size: 20),
                      ),
                      title: Text(
                        a['title'] as String,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      subtitle: Text(
                        a['snippet'] as String,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                      ),
                      trailing: const Icon(Icons.chevron_right, color: Colors.black45),
                      onTap: () => _openArticleReader(a),
                    ),
                  );
                },
              ),

            // --- 4. STILL NEED HELP? COMMUNITY CONTACT BANNER ---
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  const Icon(Icons.support_agent, size: 36, color: Color(0xFF008080)),
                  const SizedBox(height: 8),
                  const Text('Still need help?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 4),
                  Text(
                    'Our Pietermaritzburg community support team is always here to help you resolve orders or answer questions.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                  const SizedBox(height: 14),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF008080),
                      side: const BorderSide(color: Color(0xFF008080)),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    ),
                    icon: const Icon(Icons.chat_outlined, size: 18),
                    label: const Text('Contact Support Team', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          backgroundColor: Color(0xFF008080),
                          content: Text('Support inquiry initiated. A team member will respond shortly.'),
                        ),
                      );
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
  }

  Widget _categoryCard(String label, IconData icon, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Icon(icon, color: const Color(0xFF008080), size: 24),
              const SizedBox(height: 6),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}