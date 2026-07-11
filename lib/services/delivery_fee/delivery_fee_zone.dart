/// نطاق مسافة واحد لتحديد رسوم التوصيل
class DeliveryFeeZone {
  final double from;
  final double to;
  final double fee;

  const DeliveryFeeZone({
    required this.from,
    required this.to,
    required this.fee,
  });

  factory DeliveryFeeZone.fromMap(Map<String, dynamic> map) {
    return DeliveryFeeZone(
      from: (map['from'] ?? 0).toDouble(),
      to: (map['to'] ?? 0).toDouble(),
      fee: (map['fee'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'from': from,
      'to': to,
      'fee': fee,
    };
  }

  DeliveryFeeZone copyWith({
    double? from,
    double? to,
    double? fee,
  }) {
    return DeliveryFeeZone(
      from: from ?? this.from,
      to: to ?? this.to,
      fee: fee ?? this.fee,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DeliveryFeeZone &&
        other.from == from &&
        other.to == to &&
        other.fee == fee;
  }

  @override
  int get hashCode => Object.hash(from, to, fee);

  @override
  String toString() {
    return 'DeliveryFeeZone(from: $from, to: $to, fee: $fee)';
  }
}
