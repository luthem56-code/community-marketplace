class ShippingOption {
  final String id; // e.g. 'pudo_locker', 'paxi_pep', 'postnet', 'custom_courier'
  final String name; // e.g. 'Pudo Locker to Locker'
  final double price; // e.g. 60.0
  final bool isEnabled;

  ShippingOption({
    required this.id,
    required this.name,
    required this.price,
    this.isEnabled = false,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'price': price,
        'isEnabled': isEnabled,
      };

  factory ShippingOption.fromMap(Map<String, dynamic> map) => ShippingOption(
        id: map['id'] ?? '',
        name: map['name'] ?? '',
        price: (map['price'] as num?)?.toDouble() ?? 0.0,
        isEnabled: map['isEnabled'] ?? false,
      );
}