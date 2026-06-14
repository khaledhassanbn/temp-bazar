class PriceListItem {
  final String serviceName;
  final double price;

  const PriceListItem({required this.serviceName, required this.price});

  factory PriceListItem.fromMap(Map<String, dynamic> map) {
    return PriceListItem(
      serviceName: (map['serviceName'] ?? '').toString(),
      price: (map['price'] is num) ? (map['price'] as num).toDouble() : 0,
    );
  }

  Map<String, dynamic> toMap() => {
        'serviceName': serviceName,
        'price': price,
      };
}
