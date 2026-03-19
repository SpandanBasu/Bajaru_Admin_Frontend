import 'warehouse.dart';

enum ProductCategory { all, leafy, root, exotic }

extension ProductCategoryLabel on ProductCategory {
  String get label {
    switch (this) {
      case ProductCategory.all:    return 'All';
      case ProductCategory.leafy:  return 'Leafy';
      case ProductCategory.root:   return 'Root';
      case ProductCategory.exotic: return 'Exotic';
    }
  }
}

class CatalogProduct {
  final String id;
  final String name;
  final ProductCategory category;
  final String packageSize;
  final String? imageUrl;
  final bool isOutOfStock; // global supplier-level OOS — locks toggle off
  final Map<String, WarehouseProductData> warehouseData; // keyed by warehouseId

  const CatalogProduct({
    required this.id,
    required this.name,
    required this.category,
    required this.packageSize,
    this.imageUrl,
    this.isOutOfStock = false,
    required this.warehouseData,
  });

  WarehouseProductData? dataFor(String warehouseId) => warehouseData[warehouseId];

  /// From admin API ProductAdminDto.
  factory CatalogProduct.fromAdminJson(Map<String, dynamic> json) {
    final id = json['id'] as String? ?? '';
    final name = json['name'] as String? ?? '';
    final catStr = (json['category'] as String? ?? '').toLowerCase();
    final category = switch (catStr) {
      'leafy' => ProductCategory.leafy,
      'leafygreen' => ProductCategory.leafy,
      'root' => ProductCategory.root,
      'exotic' => ProductCategory.exotic,
      _ => ProductCategory.all,
    };
    final packageSize = json['unitWeight'] as String? ?? '—';
    final imageUrls = (json['imageUrls'] as List<dynamic>? ?? const [])
        .map((e) => e.toString())
        .where((e) => e.trim().isNotEmpty)
        .toList();
    final active = json['active'] as bool? ?? true;
    final invList = json['inventory'] as List<dynamic>? ?? [];
    final warehouseData = <String, WarehouseProductData>{};
    for (final inv in invList) {
      final m = inv as Map<String, dynamic>;
      final warehouseId = m['warehouseId'] as String? ?? '';
      if (warehouseId.isEmpty) continue;
      final invActive = m['active'] as bool? ?? true;
      final qty = (m['quantityAvailable'] as num?)?.toDouble() ?? 0;
      final mrp = (m['mrp'] as num?)?.toDouble() ?? 0;
      final price = (m['sellingPrice'] as num?)?.toDouble() ?? mrp;
      warehouseData[warehouseId] = WarehouseProductData(
        price: price,
        mrp: mrp,
        priceUnit: packageSize,
        stock: qty,
        // isAvailable = active toggle AND has stock
        isAvailable: invActive && qty > 0,
      );
    }
    return CatalogProduct(
      id: id,
      name: name,
      category: category,
      packageSize: packageSize,
      imageUrl: imageUrls.isNotEmpty ? imageUrls.first : null,
      isOutOfStock: !active,
      warehouseData: warehouseData,
    );
  }

  CatalogProduct copyWith({
    bool? isOutOfStock,
    Map<String, WarehouseProductData>? warehouseData,
  }) =>
      CatalogProduct(
        id: id,
        name: name,
        category: category,
        packageSize: packageSize,
        imageUrl: imageUrl,
        isOutOfStock: isOutOfStock ?? this.isOutOfStock,
        warehouseData: warehouseData ?? this.warehouseData,
      );
}
