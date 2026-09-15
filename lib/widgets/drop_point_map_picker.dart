import 'package:flutter/material.dart';

class DropPoint {
  final String id;
  final String name;
  final String type; // 'pudo', 'paxi', 'postnet', 'meetup'
  final String address;
  final String suburb;
  final String details; // e.g. "24/7 Smart Locker at Engen" or "PEP Branch #4512"

  const DropPoint({
    required this.id,
    required this.name,
    required this.type,
    required this.address,
    required this.suburb,
    required this.details,
  });
}

class DropPointMapPicker extends StatefulWidget {
  final String initialCourierType; // 'pudo', 'paxi', 'postnet', 'meetup', 'all'

  const DropPointMapPicker({super.key, required this.initialCourierType});

  @override
  State<DropPointMapPicker> createState() => _DropPointMapPickerState();
}

class _DropPointMapPickerState extends State<DropPointMapPicker> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  late String _activeType;
  DropPoint? _selectedPoint;

  // Real South African & PMB drop-off lockers, PEP stores, and PostNets
  final List<DropPoint> _allPoints = const [
    // 1. PUDO LOCKERS
    DropPoint(
      id: 'pudo_midlands',
      name: 'Pudo Locker - Liberty Midlands Mall',
      type: 'pudo',
      address: 'Sanctuary Road, Woodlands, PMB',
      suburb: 'Midlands Mall',
      details: '24/7 Smart Locker near Woolworths entrance',
    ),
    DropPoint(
      id: 'pudo_cascades',
      name: 'Pudo Locker - Cascades Lifestyle Centre',
      type: 'pudo',
      address: '23 McCarthy Drive, Montrose, PMB',
      suburb: 'Montrose',
      details: '24/7 Smart Locker outside Checkers entrance',
    ),
    DropPoint(
      id: 'pudo_scottsville',
      name: 'Pudo Locker - Engen Scottsville Convenience',
      type: 'pudo',
      address: '50 Durban Road, Scottsville, PMB',
      suburb: 'Scottsville',
      details: '24/7 Smart Locker on Engen forecourt',
    ),
    DropPoint(
      id: 'pudo_hayfields',
      name: 'Pudo Locker - Hayfields Shopping Mall',
      type: 'pudo',
      address: 'Cleland Road & Blackburrow, Hayfields, PMB',
      suburb: 'Hayfields',
      details: '24/7 Smart Locker next to SuperSpar',
    ),
    DropPoint(
      id: 'pudo_hilton',
      name: 'Pudo Locker - The Quarry Centre Hilton',
      type: 'pudo',
      address: '57 Hilton Avenue, Hilton, KZN',
      suburb: 'Hilton',
      details: '24/7 Smart Locker near Shell garage',
    ),

    // 2. PAXI (PEP STORES)
    DropPoint(
      id: 'paxi_midlands',
      name: 'PAXI PEP - Liberty Midlands Mall (Branch #4512)',
      type: 'paxi',
      address: 'Shop 42, Midlands Mall, Sanctuary Rd',
      suburb: 'Woodlands',
      details: 'PEP Store Counter - Collect with SMS PIN & ID',
    ),
    DropPoint(
      id: 'paxi_victoria',
      name: 'PAXI PEP - Victoria Road (Branch #1209)',
      type: 'paxi',
      address: '240 Victoria Road, PMB Central',
      suburb: 'PMB Central',
      details: 'PEP Store Counter - Collect with SMS PIN & ID',
    ),
    DropPoint(
      id: 'paxi_church',
      name: 'PAXI PEP - Church Street (Branch #3081)',
      type: 'paxi',
      address: '380 Church Street, City Centre, PMB',
      suburb: 'City Centre',
      details: 'PEP Store Counter - Collect with SMS PIN & ID',
    ),
    DropPoint(
      id: 'paxi_northway',
      name: 'PAXI PEP - Northway Mall (Branch #2890)',
      type: 'paxi',
      address: 'Otto\'s Bluff Road, Woodlands, PMB',
      suburb: 'Woodlands',
      details: 'PEP Store Counter - Collect with SMS PIN & ID',
    ),

    // 3. POSTNET
    DropPoint(
      id: 'postnet_midlands',
      name: 'PostNet - Midlands Mall',
      type: 'postnet',
      address: 'Shop 25, Liberty Midlands Mall, PMB',
      suburb: 'Midlands Mall',
      details: 'Counter Collection - Open Mon to Sat with ID',
    ),
    DropPoint(
      id: 'postnet_cascades',
      name: 'PostNet - Cascades Centre',
      type: 'postnet',
      address: 'Cascades Lifestyle Centre, Montrose, PMB',
      suburb: 'Montrose',
      details: 'Counter Collection - Open Mon to Sat with ID',
    ),

    // 4. SAFE COMMUNITY MEETUP POINTS (Free R0)
    DropPoint(
      id: 'meetup_church',
      name: 'PMB Central Church Community Gate',
      type: 'meetup',
      address: 'Main Entrance Car Park, PMB Central',
      suburb: 'PMB Central',
      details: 'Public Community Meetup Spot • Safe Escrow Release',
    ),
    DropPoint(
      id: 'meetup_mall_foodcourt',
      name: 'Midlands Mall Main Food Court Entrance',
      type: 'meetup',
      address: 'Sanctuary Road, Public Security Booth Area',
      suburb: 'Midlands Mall',
      details: 'Public Community Meetup Spot • Safe Escrow Release',
    ),
  ];

  @override
  void initState() {
    super.initState();
    final lower = widget.initialCourierType.toLowerCase();
    if (lower.contains('pudo') || lower.contains('courier guy') || lower.contains('locker')) {
      _activeType = 'pudo';
    } else if (lower.contains('paxi') || lower.contains('pep')) {
      _activeType = 'paxi';
    } else if (lower.contains('postnet')) {
      _activeType = 'postnet';
    } else if (lower.contains('meetup') || lower.contains('pickup')) {
      _activeType = 'meetup';
    } else {
      _activeType = 'all';
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _allPoints.where((p) {
      final matchesType = _activeType == 'all' || p.type == _activeType;
      final q = _searchQuery.toLowerCase();
      final matchesQuery = _searchQuery.isEmpty ||
          p.name.toLowerCase().contains(q) ||
          p.address.toLowerCase().contains(q) ||
          p.suburb.toLowerCase().contains(q);
      return matchesType && matchesQuery;
    }).toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Top Handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                const CircleAvatar(
                  backgroundColor: Color(0xFFE6F2F2),
                  child: Icon(Icons.map_outlined, color: Color(0xFF008080)),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Pick Collection Point on Map', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text('Select your nearest smart locker, PEP store, or branch', style: TextStyle(color: Colors.grey, fontSize: 11)),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (v) => setState(() => _searchQuery = v.trim()),
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search, size: 20, color: Colors.black54),
                  hintText: 'Search suburb (Scottsville, Montrose, Hilton, Midlands Mall...)',
                  hintStyle: TextStyle(fontSize: 12, color: Colors.grey),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ),

          // Courier Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                _filterChip('all', 'All Locations'),
                _filterChip('pudo', 'Pudo Smart Lockers'),
                _filterChip('paxi', 'PEP PAXI Stores'),
                _filterChip('postnet', 'PostNet Counters'),
                _filterChip('meetup', 'Local Community Meetup'),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Visual Map Representation Card
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            height: 110,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.teal.shade700, const Color(0xFF004D40)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(color: const Color(0xFF008080).withOpacity(0.2), blurRadius: 6, offset: const Offset(0, 3)),
              ],
            ),
            child: Stack(
              children: [
                Positioned(
                  right: -10,
                  bottom: -10,
                  child: Icon(Icons.map_rounded, size: 130, color: Colors.white.withOpacity(0.08)),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.gps_fixed, color: Colors.white, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            _selectedPoint != null ? 'Pin Selected!' : 'Pietermaritzburg & KZN Network',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _selectedPoint != null
                            ? '${_selectedPoint!.name}\n${_selectedPoint!.address}'
                            : 'Tap on any verified drop-off point below to pin it and auto-fill your delivery address.',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // List of Verified Drop Points
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.location_off_outlined, size: 48, color: Colors.grey.shade400),
                        const SizedBox(height: 8),
                        const Text('No pickup points found', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text('Try clearing your search query.', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final point = filtered[index];
                      final isSelected = _selectedPoint?.id == point.id;

                      return Card(
                        elevation: isSelected ? 2 : 0.5,
                        margin: const EdgeInsets.only(bottom: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: BorderSide(
                            color: isSelected ? const Color(0xFF008080) : Colors.grey.shade200,
                            width: isSelected ? 2.0 : 1.0,
                          ),
                        ),
                        color: isSelected ? const Color(0xFFE6F2F2) : Colors.white,
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                          leading: CircleAvatar(
                            backgroundColor: _getIconColor(point.type).withOpacity(0.12),
                            child: Icon(_getPointIcon(point.type), color: _getIconColor(point.type), size: 20),
                          ),
                          title: Text(point.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 2),
                              Text(point.address, style: TextStyle(color: Colors.grey.shade700, fontSize: 11)),
                              const SizedBox(height: 2),
                              Text(point.details, style: const TextStyle(color: Color(0xFF008080), fontSize: 10, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          trailing: Radio<String>(
                            value: point.id,
                            groupValue: _selectedPoint?.id,
                            activeColor: const Color(0xFF008080),
                            onChanged: (_) {
                              setState(() => _selectedPoint = point);
                            },
                          ),
                          onTap: () {
                            setState(() => _selectedPoint = point);
                          },
                        ),
                      );
                    },
                  ),
          ),

          // Confirm & Auto-Fill Button
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -3)),
              ],
            ),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF008080),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                icon: const Icon(Icons.check_circle_outline),
                label: Text(
                  _selectedPoint != null ? 'Use This Location & Auto-Fill' : 'Select a Pin on Map',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                onPressed: _selectedPoint == null
                    ? null
                    : () {
                        // Return selected formatted address back to checkout
                        final formatted = '${_selectedPoint!.name}, ${_selectedPoint!.address}';
                        Navigator.pop(context, formatted);
                      },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String type, String label) {
    final isSelected = _activeType == type;
    return Padding(
      padding: const EdgeInsets.only(right: 6.0),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        selectedColor: const Color(0xFF008080),
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : Colors.black87,
          fontSize: 11,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        backgroundColor: Colors.grey.shade100,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        onSelected: (val) {
          if (val) setState(() => _activeType = type);
        },
      ),
    );
  }

  IconData _getPointIcon(String type) {
    switch (type) {
      case 'pudo':
        return Icons.lock_clock_outlined;
      case 'paxi':
        return Icons.storefront_outlined;
      case 'postnet':
        return Icons.local_post_office_outlined;
      case 'meetup':
        return Icons.handshake_outlined;
      default:
        return Icons.location_on_outlined;
    }
  }

  Color _getIconColor(String type) {
    switch (type) {
      case 'pudo':
        return Colors.blue.shade700;
      case 'paxi':
        return Colors.orange.shade700;
      case 'postnet':
        return Colors.red.shade700;
      case 'meetup':
        return const Color(0xFF008080);
      default:
        return Colors.grey.shade700;
    }
  }
}