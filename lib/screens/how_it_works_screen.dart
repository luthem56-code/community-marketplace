import 'package:flutter/material.dart';
import 'create_listing_screen.dart';

class HowItWorksScreen extends StatelessWidget {
  const HowItWorksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        title: const Text('How It Works', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
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
            // --- 1. HERO HEADER ---
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 32),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF008080), Color(0xFF004D40)],
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
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'COMMUNITY ESCROW MARKETPLACE',
                      style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Your Marketplace for New & Preloved Fashion',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Clean out your closet & list what you no longer need — 100% free with 0% seller commission!',
                    style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.4),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF008080),
                      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      elevation: 0,
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const CreateListingScreen()),
                      );
                    },
                    child: const Text(
                      'Start Selling for Free',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),

            // --- 2. TRUST STATS CARDS ---
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              child: Row(
                children: [
                  _statCard('100% Free', 'Selling', Icons.monetization_on_outlined),
                  _dividerVertical(),
                  _statCard('Escrow', 'Protected', Icons.shield_outlined),
                  _dividerVertical(),
                  _statCard('R 0.00', 'Local PMB Pickup', Icons.handshake_outlined),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // --- 3. THE 6-STEP TRANSACTION LIFECYCLE ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'How the Marketplace Works',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Every step is protected by Community Escrow from listing to payout.',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),
                  const SizedBox(height: 16),

                  _stepCard(
                    number: '1',
                    title: 'Seller lists an item for sale',
                    desc: 'Snap up to 6 photos, choose category, size, and condition, and set your price. Listing takes under 60 seconds.',
                    icon: Icons.add_a_photo_outlined,
                  ),
                  _stepCard(
                    number: '2',
                    title: 'Buyer buys an item',
                    desc: 'The buyer finds an item they love, selects their preferred delivery method (Local PMB Pickup, Pudo, PAXI, or PostNet), and pays securely.',
                    icon: Icons.shopping_bag_outlined,
                  ),
                  _stepCard(
                    number: '3',
                    title: 'Payment is held securely in escrow',
                    desc: 'Funds are transferred to our secure escrow vault. The seller cannot withdraw until the buyer receives and verifies the parcel.',
                    icon: Icons.lock_clock_outlined,
                    highlight: true,
                  ),
                  _stepCard(
                    number: '4',
                    title: 'Seller ships the item',
                    desc: 'The seller drops off the parcel at their nearest Pudo locker, PEP store (PAXI), or meets locally in a safe public spot.',
                    icon: Icons.local_shipping_outlined,
                  ),
                  _stepCard(
                    number: '5',
                    title: 'Buyer receives item',
                    desc: 'Once the item arrives, the buyer inspects it. If everything matches the description, they click "Item received & All good".',
                    icon: Icons.check_circle_outline,
                  ),
                  _stepCard(
                    number: '6',
                    title: 'Seller receives payment',
                    desc: 'The escrow funds are released immediately into the seller\'s in-app Wallet. Sellers can withdraw directly to any South African bank account via EFT.',
                    icon: Icons.account_balance_wallet_outlined,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // --- 4. SELLING IS SIMPLE GUIDES ---
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Selling is Simple',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Pro tips to grow your wardrobe sales in the community.',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),
                  const SizedBox(height: 16),

                  _tipCard(
                    title: '1. Creating the Perfect Listing',
                    desc: 'Take photos in bright, natural daylight. Hang clothes nicely or do a clean flat-lay. Always photograph the brand and size label, and mention any minor flaws openly. Honest listings build loyal 5-star buyers!',
                    tag: 'Photo & Listing Tips',
                  ),
                  const SizedBox(height: 12),
                  _tipCard(
                    title: '2. Reaching Your First Sales',
                    desc: 'Don\'t just wait for people to stumble onto your closet. Tap the "Share" button on your listings to post directly into your PMB WhatsApp groups, church community chats, and social channels!',
                    tag: 'Marketing Like a Pro',
                  ),
                  const SizedBox(height: 12),
                  _tipCard(
                    title: '3. Offer Free Local Meetup & Bundling',
                    desc: 'Buyers hate paying courier fees on smaller items. Enable "Free Local PMB Meetup" and "Bundling" on your listings so neighbors can collect in person or buy 3 items for a single courier drop!',
                    tag: 'Conversion Booster',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // --- 5. BOTTOM CTA BANNER ---
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFE6F2F2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF008080).withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  const Text(
                    'Ready to turn your preloved clothes into cash?',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF004D40)),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Join your fellow community members selling wardrobe items safely today.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Colors.black87),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF008080),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const CreateListingScreen()),
                        );
                      },
                      child: const Text('List an Item Now (0% Fee)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  static Widget _statCard(String main, String sub, IconData icon) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFF008080), size: 24),
          const SizedBox(height: 6),
          Text(main, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Colors.black87)),
          Text(sub, style: TextStyle(color: Colors.grey.shade600, fontSize: 11), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  static Widget _dividerVertical() {
    return Container(
      width: 1,
      height: 36,
      color: Colors.grey.shade300,
    );
  }

  static Widget _stepCard({
    required String number,
    required String title,
    required String desc,
    required IconData icon,
    bool highlight = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: highlight ? const Color(0xFFEBF5F5) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: highlight ? const Color(0xFF008080).withOpacity(0.4) : Colors.grey.shade200,
          width: highlight ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: highlight ? const Color(0xFF008080) : Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              number,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: highlight ? Colors.white : Colors.black87,
              ),
            ),
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
                        title,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ),
                    Icon(icon, size: 18, color: const Color(0xFF008080)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  desc,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade700, height: 1.35),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Widget _tipCard({required String title, required String desc, required String tag}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFFE6F2F2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              tag,
              style: const TextStyle(color: Color(0xFF008080), fontSize: 10, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 4),
          Text(desc, style: TextStyle(color: Colors.grey.shade700, fontSize: 12, height: 1.4)),
        ],
      ),
    );
  }
}