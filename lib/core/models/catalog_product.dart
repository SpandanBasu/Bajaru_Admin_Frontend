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

  /// From the new single-call warehouse listing endpoint.
  /// Parses one item from GET /inventory/admin/by-warehouse response content[].
  /// Each item is already a merged inventory + product metadata row for one warehouse.
  factory CatalogProduct.fromWarehouseItem(Map<String, dynamic> json) {
    final productId = json['productId'] as String? ?? '';
    final name = json['name'] as String? ?? '';
    final warehouseId = json['warehouseId'] as String? ?? '';
    final catStr = (json['category'] as String? ?? '').toLowerCase();
    final category = switch (catStr) {
      'leafy' || 'leafygreen' => ProductCategory.leafy,
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
    final qty = (json['quantityAvailable'] as num?)?.toDouble() ?? 0;
    final mrp = (json['mrp'] as num?)?.toDouble() ?? 0;
    final sellingPrice = (json['sellingPrice'] as num?)?.toDouble() ?? mrp;
    final warehouseData = warehouseId.isNotEmpty
        ? {
            warehouseId: WarehouseProductData(
              price: sellingPrice,
              mrp: mrp,
              priceUnit: packageSize,
              stock: qty,
              isAvailable: active && qty > 0,
            ),
          }
        : <String, WarehouseProductData>{};
    return CatalogProduct(
      id: productId,
      name: name,
      category: category,
      packageSize: packageSize,
      imageUrl: imageUrls.isNotEmpty ? imageUrls.first : null,
      isOutOfStock: false, // inventory-level active flag; admin can always re-enable
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
