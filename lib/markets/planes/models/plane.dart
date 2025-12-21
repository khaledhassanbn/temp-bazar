class Plan {
  final int products;
  final Map<String, int> prices; // الأسعار لكل مدة
  final List<String> features; // المميزات

  Plan({required this.products, required this.prices, required this.features});
  factory Plan.fromMap(Map<String, dynamic> map) {
    final rawPrices = map['prices'] ?? {};
    final prices = <String, int>{};

    rawPrices.forEach((key, value) {
      if (value is int) {
        prices[key] = value;
      } else if (value is double) {
        prices[key] = value.toInt();
      } else if (value is String) {
        prices[key] = int.tryParse(value) ?? 0;
      }
    });

    return Plan(
      products: map['products'] ?? 0,
      prices: prices,
      features: List<String>.from(map['features'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {'products': products, 'prices': prices, 'features': features};
  }
}
