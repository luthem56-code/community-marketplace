import 'package:flutter/material.dart';

class DropPoint {
  final String id;
  final String name;
  final String type; // 'pudo', 'paxi', 'postnet', 'meetup'
  final String address;
  final String province; // All 9 SA Provinces
  final String suburb;
  final String details;

  const DropPoint({
    required this.id,
    required this.name,
    required this.type,
    required this.address,
    required this.province,
    required this.suburb,
    required this.details,
  });
}

class DropPointMapPicker extends StatefulWidget {
  final String initialCourierType;

  const DropPointMapPicker({super.key, required this.initialCourierType});

  @override
  State<DropPointMapPicker> createState() => _DropPointMapPickerState();
}

class _DropPointMapPickerState extends State<DropPointMapPicker> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  late String _activeType;
  String _selectedProvince = 'All Provinces';
  DropPoint? _selectedPoint;

  final List<String> _saProvinces = [
    'All Provinces',
    'Gauteng (GP)',
    'KwaZulu-Natal (KZN)',
    'Western Cape (WC)',
    'Eastern Cape (EC)',
    'Free State (FS)',
    'Limpopo (LP)',
    'Mpumalanga (MP)',
    'North West (NW)',
    'Northern Cape (NC)',
  ];

  // Verified Nationwide Pickup & Drop-Off Points across all 9 Provinces
  final List<DropPoint> _allPoints = const [
    // --- KWAZULU-NATAL (KZN) ---
    DropPoint(
      id: 'kzn_pudo_midlands',
      name: 'Pudo Locker - Liberty Midlands Mall',
      type: 'pudo',
      province: 'KwaZulu-Natal (KZN)',
      address: 'Sanctuary Road, Woodlands, PMB',
      suburb: 'Pietermaritzburg',
      details: '24/7 Smart Locker near Woolworths entrance',
    ),
    DropPoint(
      id: 'kzn_pudo_cascades',
      name: 'Pudo Locker - Cascades Lifestyle Centre',
      type: 'pudo',
      province: 'KwaZulu-Natal (KZN)',
      address: '23 McCarthy Drive, Montrose, PMB',
      suburb: 'Pietermaritzburg',
      details: '24/7 Smart Locker outside Checkers',
    ),
    DropPoint(
      id: 'kzn_paxi_midlands',
      name: 'PAXI PEP - Midlands Mall (Branch #4512)',
      type: 'paxi',
      province: 'KwaZulu-Natal (KZN)',
      address: 'Shop 42, Midlands Mall, PMB',
      suburb: 'Pietermaritzburg',
      details: 'PEP Store Counter - Collect with SMS PIN & ID',
    ),
    DropPoint(
      id: 'kzn_pudo_gateway',
      name: 'Pudo Locker - Gateway Theatre of Shopping',
      type: 'pudo',
      province: 'KwaZulu-Natal (KZN)',
      address: '1 Palm Blvd, Umhlanga Ridge, Durban',
      suburb: 'Durban',
      details: '24/7 Smart Locker near entrance 3',
    ),

    // --- GAUTENG (GP) ---
    DropPoint(
      id: 'gp_pudo_mall_africa',
      name: 'Pudo Locker - Mall of Africa',
      type: 'pudo',
      province: 'Gauteng (GP)',
      address: 'Magwa Cres, Midrand, Johannesburg',
      suburb: 'Johannesburg',
      details: '24/7 Smart Locker at lower level parking',
    ),
    DropPoint(
      id: 'gp_paxi_sandton',
      name: 'PAXI PEP - Sandton City (Branch #2201)',
      type: 'paxi',
      province: 'Gauteng (GP)',
      address: 'Rivonia Rd, Sandhurst, Sandton',
      suburb: 'Johannesburg',
      details: 'PEP Counter - SMS PIN & ID Required',
    ),
    DropPoint(
      id: 'gp_pudo_menlyn',
      name: 'Pudo Locker - Menlyn Park Shopping Centre',
      type: 'pudo',
      province: 'Gauteng (GP)',
      address: 'Atterbury Rd, Menlyn, Pretoria',
      suburb: 'Pretoria',
      details: '24/7 Smart Locker near Woolworths Court',
    ),

    // --- WESTERN CAPE (WC) ---
    DropPoint(
      id: 'wc_pudo_canal_walk',
      name: 'Pudo Locker - Canal Walk Shopping Centre',
      type: 'pudo',
      province: 'Western Cape (WC)',
      address: 'Century Blvd, Century City, Cape Town',
      suburb: 'Cape Town',
      details: '24/7 Smart Locker outside Entrance 1',
    ),
    DropPoint(
      id: 'wc_paxi_tygervalley',
      name: 'PAXI PEP - Tygervalley Mall (Branch #3312)',
      type: 'paxi',
      province: 'Western Cape (WC)',
      address: 'Bill Bezuidenhout Ave, Bellville',
      suburb: 'Cape Town',
      details: 'PEP Counter collection with PIN',
    ),

    // --- EASTERN CAPE (EC) ---
    DropPoint(
      id: 'ec_pudo_walmer',
      name: 'Pudo Locker - Walmer Park Shopping Centre',
      type: 'pudo',
      province: 'Eastern Cape (EC)',
      address: 'Main Rd, Walmer, Gqeberha (Port Elizabeth)',
      suburb: 'Gqeberha',
      details: '24/7 Smart Locker on parking deck',
    ),
    DropPoint(
      id: 'ec_paxi_vincent',
      name: 'PAXI PEP - Vincent Park (Branch #1882)',
      type: 'paxi',
      province: 'Eastern Cape (EC)',
      address: 'Devereux Ave, Vincent, East London',
      suburb: 'East London',
      details: 'PEP Counter collection',
    ),

    // --- FREE STATE (FS) ---
    DropPoint(
      id: 'fs_pudo_mimosa',
      name: 'Pudo Locker - Mimosa Mall',
      type: 'pudo',
      province: 'Free State (FS)',
      address: 'Kellner St, Brandwag, Bloemfontein',
      suburb: 'Bloemfontein',
      details: '24/7 Smart Locker near Pick n Pay',
    ),

    // --- LIMPOPO (LP) ---
    DropPoint(
      id: 'lp_pudo_mall_north',
      name: 'Pudo Locker - Mall of the North',
      type: 'pudo',
      province: 'Limpopo (LP)',
      address: 'R81 & N1 Interchange, Bendor, Polokwane',
      suburb: 'Polokwane',
      details: '24/7 Smart Locker near entrance 2',
    ),

    // --- MPUMALANGA (MP) ---
    DropPoint(
      id: 'mp_pudo_ilanga',
      name: 'Pudo Locker - iLangha Mall',
      type: 'pudo',
      province: 'Mpumalanga (MP)',
      address: 'Bitterbessie St, West Acres, Mbombela (Nelspruit)',
      suburb: 'Mbombela',
      details: '24/7 Smart Locker at forecourt',
    ),

    // --- NORTH WEST (NW) ---
    DropPoint(
      id: 'nw_pudo_waterfall',
      name: 'Pudo Locker - Waterfall Mall',
      type: 'pudo',
      province: 'North West (NW)',
      address: '1 Augrabies Ave, Cashan, Rustenburg',
      suburb: 'Rustenburg',
      details: '24/7 Smart Locker at Shell Garage',
    ),

    // --- NORTHERN CAPE (NC) ---
    DropPoint(
      id: 'nc_pudo_diamond',
      name: 'Pudo Locker - Diamond Pavilion Mall',
      type: 'pudo',
      province: 'Northern Cape (NC)',
      address: 'Oliver Rd, Monument Heights, Kimberley',
      suburb: 'Kimberley',
      details: '24/7 Smart Locker outside Checkers',
    ),

    // --- SAFE COMMUNITY MEETUP POINTS (R0 FREE) ---
    DropPoint(
      id: 'pmb_meetup_central',
      name: 'PMB Central Community Meeting Point',
      type: 'meetup',
      province: 'KwaZulu-Natal (KZN)',
      address: 'Public Safe Zone, Church / Shopping Precinct',
      suburb: 'Pietermaritzburg',
      details: 'Free In-Person Meetup • 100% Escrow Protected',
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
      final matchesProvince = _selectedProvince == 'All Provinces' || p.province == _selectedProvince;
      final q = _searchQuery.toLowerCase();
      final matchesQuery = _searchQuery.isEmpty ||
          p.name.toLowerCase().contains(q) ||
          p.address.toLowerCase().contains(q) ||
          p.suburb.toLowerCase().contains(q) ||
          p.province.toLowerCase().contains(q);
      return matchesType && matchesProvince && matchesQuery;
    }).toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            child: Row(
              children: [
                const CircleAvatar(
                  backgroundColor: Color(0xFFE6F2F2),
                  child: Icon(Icons.location_on, color: Color(0xFF008080)),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Select Drop-off / Pickup Point', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text('All 9 South African Provinces Supported', style: TextStyle(color: Color(0xFF008080), fontSize: 11, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
              ],
            ),
          ),
          const Divider(height: 1),

          // Search + Province Selector Row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Container(
                    height: 42,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (v) => setState(() => _searchQuery = v.trim()),
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.search, size: 18, color: Colors.black54),
                        hintText: 'Search city, mall, suburb...',
                        hintStyle: TextStyle(fontSize: 12),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: Container(
                    height: 42,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: _selectedProvince,
                        style: const TextStyle(fontSize: 11, color: Colors.black, fontWeight: FontWeight.bold),
                        items: _saProvinces.map((p) => DropdownMenuItem(value: p, child: Text(p, overflow: TextOverflow.ellipsis))).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedProvince = val);
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Courier Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                _chip('all', 'All Couriers'),
                _chip('pudo', 'Pudo Smart Lockers'),
                _chip('paxi', 'PEP PAXI Counters'),
                _chip('meetup', 'Community Meetup (R0)'),
              ],
            ),
          ),

          // List of Filtered Points
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.location_off_outlined, size: 48, color: Colors.grey.shade400),
                        const SizedBox(height: 8),
                        Text('No drop-off points found in $_selectedProvince', style: const TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        const Text('Try selecting "All Provinces" or clearing search terms.', style: TextStyle(color: Colors.grey, fontSize: 12)),
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
                        color: isSelected ? const Color(0xFFE6F2F2) : Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: BorderSide(color: isSelected ? const Color(0xFF008080) : Colors.grey.shade200, width: isSelected ? 2 : 1),
                        ),
                        child: ListTile(
                          onTap: () => setState(() => _selectedPoint = point),
                          leading: CircleAvatar(
                            backgroundColor: _color(point.type).withOpacity(0.12),
                            child: Icon(_icon(point.type), color: _color(point.type), size: 20),
                          ),
                          title: Text(point.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          subtitle: Text('${point.address}\n${point.province}', style: TextStyle(color: Colors.grey.shade700, fontSize: 11)),
                          trailing: Radio<String>(
                            value: point.id,
                            groupValue: _selectedPoint?.id,
                            activeColor: const Color(0xFF008080),
                            onChanged: (_) => setState(() => _selectedPoint = point),
                          ),
                        ),
                      );
                    },
                  ),
          ),

          // Confirm Button
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF008080), foregroundColor: Colors.white),
                icon: const Icon(Icons.check_circle_outline),
                label: Text(_selectedPoint != null ? 'Use Location: ${_selectedPoint!.suburb}' : 'Select a Point Above'),
                onPressed: _selectedPoint == null
                    ? null
                    : () {
                        Navigator.pop(context, '${_selectedPoint!.name}, ${_selectedPoint!.address}');
                      },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String type, String label) {
    final isSelected = _activeType == type;
    return Padding(
      padding: const EdgeInsets.only(right: 6.0),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        selectedColor: const Color(0xFF008080),
        labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black87, fontSize: 11, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
        onSelected: (v) {
          if (v) setState(() => _activeType = type);
        },
      ),
    );
  }

  IconData _icon(String type) => type == 'pudo' ? Icons.lock_clock_outlined : (type == 'paxi' ? Icons.storefront_outlined : Icons.handshake_outlined);
  Color _color(String type) => type == 'pudo' ? Colors.blue.shade700 : (type == 'paxi' ? Colors.orange.shade700 : const Color(0xFF008080));

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