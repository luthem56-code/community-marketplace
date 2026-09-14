import 'package:flutter/material.dart';

class DeliveryInfoSheet {
  static void show(BuildContext context, String courierKey) {
    final Map<String, dynamic> info = _getDeliveryGuide(courierKey);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                ),
              ),

              // Title & Icon
              Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: const Color(0xFFE6F2F2),
                    child: Icon(info['icon'] as IconData, color: const Color(0xFF008080), size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          info['title'] as String,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        Text(
                          info['tagline'] as String,
                          style: const TextStyle(color: Color(0xFF008080), fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 12),

              // Safety & Escrow Badge
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.teal.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF008080).withOpacity(0.3)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.shield_outlined, color: Color(0xFF008080), size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        info['safety'] as String,
                        style: const TextStyle(fontSize: 12, color: Color(0xFF004D40), height: 1.3),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // How it works for the Seller
              const Text('HOW IT WORKS FOR THE SELLER', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
              const SizedBox(height: 6),
              ...((info['sellerSteps'] as List<String>).map((step) => _stepItem(step))),
              const SizedBox(height: 14),

              // How it works for the Buyer
              const Text('HOW IT WORKS FOR THE BUYER', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
              const SizedBox(height: 6),
              ...((info['buyerSteps'] as List<String>).map((step) => _stepItem(step))),
              const SizedBox(height: 20),

              // Close Button
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF008080),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Got It', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _stepItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle, size: 14, color: Color(0xFF008080)),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13, height: 1.3))),
        ],
      ),
    );
  }

  static Map<String, dynamic> _getDeliveryGuide(String key) {
    final lower = key.toLowerCase();

    // 1. LOCAL COMMUNITY PICKUP
    if (lower.contains('pickup') || lower.contains('seller') || lower.contains('meetup')) {
      return {
        'title': 'Local Community Pickup / Meetup',
        'tagline': 'R 0.00 Delivery Fee • 100% Escrow Protected',
        'icon': Icons.handshake_outlined,
        'safety': 'Safe Escrow: The buyer pays upfront into escrow. The seller never leaves home empty-handed. At the meetup, the buyer inspects the item and taps "Item Received" on their phone to release the funds on the spot!',
        'sellerSteps': [
          'Wait until the order is paid and confirmed in your Sales tab.',
          'Message the buyer in the app to agree on a safe, public PMB location (e.g. Church car park, Midlands Mall, Cascades, or complex gate).',
          'Hand over the item and watch the buyer confirm receipt on their phone to release your payout instantly.',
        ],
        'buyerSteps': [
          'Pay securely into escrow at checkout (R0 delivery fee).',
          'Chat with the neighbor/seller to arrange a convenient meetup time.',
          'Inspect the item in person. Once satisfied, tap "Item Received & All Good" on your order card to release the seller\'s money.',
        ],
      };
    }

    // 2. THE COURIER GUY / PUDO LOCKER
    if (lower.contains('courier guy') || lower.contains('pudo') || lower.contains('locker')) {
      return {
        'title': 'The Courier Guy (Pudo Locker)',
        'tagline': 'Smart Lockers & Kiosks across South Africa',
        'icon': Icons.lock_clock_outlined,
        'safety': 'Protected by 24/7 monitored smart lockers. Real-time pin verification ensures only the recipient can open the locker door.',
        'sellerSteps': [
          'Package the item securely in a box or flyer bag.',
          'Drop the parcel off at your nearest Pudo smart locker or Courier Guy kiosk using your drop-off PIN.',
          'Enter the tracking number into your app orders tab.',
        ],
        'buyerSteps': [
          'Choose your nearest Pudo locker location at checkout.',
          'Receive an SMS with a one-time OTP collection code when the parcel lands.',
          'Go to the locker within 48 hours, enter your OTP on screen, and the locker pops open!',
        ],
      };
    }

    // 3. PAXI SPEED SERVICE (PEP STORES)
    if (lower.contains('paxi') || lower.contains('pep')) {
      return {
        'title': 'PAXI Speed Service (PEP Stores)',
        'tagline': 'Counter-to-Counter across 2,800+ PEP Stores',
        'icon': Icons.storefront_outlined,
        'safety': 'Tracked from counter to counter. Parcels can only be released upon presenting the secret SMS PIN and matching South African ID.',
        'sellerSteps': [
          'Take your packed parcel to any PEP, PEP Home, or ShoeCity counter.',
          'Give the counter clerk the buyer\'s PEP store name/code and cell number.',
          'Take a photo of the PAXI bag barcode and enter the tracking code in the app.',
        ],
        'buyerSteps': [
          'Provide your local PEP store branch code and cellphone number at checkout.',
          'PAXI will send an SMS with your collection PIN once it arrives (usually 7-9 business days).',
          'Collect your parcel at the PEP counter with your ID and SMS PIN.',
        ],
      };
    }

    // 4. PARGO STORE-TO-STORE
    if (lower.contains('pargo')) {
      return {
        'title': 'Pargo Store-to-Store Pick-up',
        'tagline': 'Pick up at Clicks, FreshStop, and local stores',
        'icon': Icons.local_convenience_store_outlined,
        'safety': 'Parcels are locked safely behind partner store counters and released only with an ID and unique Pargo collection code.',
        'sellerSteps': [
          'Package the item and affix the Pargo waybill.',
          'Drop it off at any Pargo Pick-up Point (e.g. FreshStop, Clicks).',
        ],
        'buyerSteps': [
          'Select your closest Pargo point at checkout.',
          'Collect your package within 8 days of receiving the arrival SMS.',
        ],
      };
    }

    // 5. POSTNET-TO-POSTNET
    if (lower.contains('postnet')) {
      return {
        'title': 'PostNet-to-PostNet Counter',
        'tagline': 'Fast 2-3 Business Days Across 400+ Branches',
        'icon': Icons.local_post_office_outlined,
        'safety': 'Full signature and ID verification required upon counter collection.',
        'sellerSteps': [
          'Drop parcel off at your nearest PostNet branch.',
          'Pay the R109 fee (already funded by buyer at checkout) and enter the waybill in the app.',
        ],
        'buyerSteps': [
          'Receive an SMS from PostNet when the parcel arrives at your chosen branch.',
          'Collect with your ID and tracking number.',
        ],
      };
    }

    // Default: Door-to-Door Courier
    return {
      'title': 'Standard Courier (Door-to-Door)',
      'tagline': 'Delivered directly to your home or office address',
      'icon': Icons.local_shipping_outlined,
      'safety': 'Direct tracking from pickup to delivery with proof of delivery signature.',
      'sellerSteps': [
        'The courier driver picks up the parcel directly from your home address.',
      ],
      'buyerSteps': [
        'The parcel is delivered right to your front door or workplace.',
      ],
    };
  }
}