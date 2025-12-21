/// Package model for the new subscription system
class Package {
  final String id;
  final String name;
  final int days;
  final double price;
  final List<String> features;
  final int orderIndex;

  Package({
    required this.id,
    required this.name,
    required this.days,
    required this.price,
    required this.features,
    required this.orderIndex,
  });

  factory Package.fromMap(String id, Map<String, dynamic> map) {
    return Package(
      id: id,
      name: map['name'] ?? '',
      days: (map['days'] ?? 0) as int,
      price: (map['price'] ?? 0.0).toDouble(),
      features: List<String>.from(map['features'] ?? []),
      orderIndex: (map['orderIndex'] ?? 0) as int,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'days': days,
      'price': price,
      'features': features,
      'orderIndex': orderIndex,
    };
  }
}
