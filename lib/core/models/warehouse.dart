/// Warehouse model — used by catalog inventory management.
/// Replaces Pincode as the inventory grouping key.
class Warehouse {
  final String warehouseId;
  final String displayName;
  final String city;
  final List<String> servicePincodes;
  final bool active;

  const Warehouse({
    required this.warehouseId,
    required this.displayName,
    required this.city,
    required this.servicePincodes,
    required this.active,
  });

  /// From admin API WarehouseResponse.
  factory Warehouse.fromJson(Map<String, dynamic> json) {
    return Warehouse(
      warehouseId: json['warehouseId'] as String? ?? '',
      displayName: json['displayName'] as String? ?? '',
      city: json['city'] as String? ?? '',
      servicePincodes: (json['servicePincodes'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      active: json['active'] as bool? ?? true,
    );
  }
}

/// Inventory data for a product at a specific warehouse.
class WarehouseProductData {
  final double price;
  final double mrp;
  final String priceUnit;
  final double stock;
  final bool isAvailable;

  const WarehouseProductData({
    required this.price,
    required this.mrp,
    required this.priceUnit,
    required this.stock,
    required this.isAvailable,
  });

  WarehouseProductData copyWith({
    double? price,
    double? mrp,
    String? priceUnit,
    double? stock,
    bool? isAvailable,
  }) =>
      WarehouseProductData(
        price: price ?? this.price,
        mrp: mrp ?? this.mrp,
        priceUnit: priceUnit ?? this.priceUnit,
        stock: stock ?? this.stock,
        isAvailable: isAvailable ?? this.isAvailable,
      );
}
