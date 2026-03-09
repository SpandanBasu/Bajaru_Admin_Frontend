class Pincode {
  final String code;
  final String area;
  const Pincode({required this.code, required this.area});

  /// From API: { pincode, city, area }
  factory Pincode.fromJson(Map<String, dynamic> json) {
    final code = json['pincode'] as String? ?? '';
    final area = json['area'] as String? ?? json['city'] as String? ?? code;
    return Pincode(code: code, area: area);
  }
}

class PincodeProductData {
  final double price;
  final String priceUnit;
  final double stock;
  final bool isAvailable;

  const PincodeProductData({
    required this.price,
    required this.priceUnit,
    required this.stock,
    required this.isAvailable,
  });

  PincodeProductData copyWith({
    double? price,
    String? priceUnit,
    double? stock,
    bool? isAvailable,
  }) =>
      PincodeProductData(
        price: price ?? this.price,
        priceUnit: priceUnit ?? this.priceUnit,
        stock: stock ?? this.stock,
        isAvailable: isAvailable ?? this.isAvailable,
      );
}
