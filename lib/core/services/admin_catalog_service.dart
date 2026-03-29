import '../api/admin_api_client.dart';
import '../api/api_paths.dart';
import '../models/catalog_product.dart';
import '../models/warehouse.dart';

/// Fetches warehouses and product catalog from the backend.
class AdminCatalogService {
  const AdminCatalogService(this._client);
  final AdminApiClient _client;

  /// Fetches all active warehouses for catalog warehouse selection.
  Future<List<Warehouse>> getWarehouses() async {
    final list = await _client.getList(ApiPaths.adminWarehouses);
    return list
        .map((e) => Warehouse.fromJson(e as Map<String, dynamic>))
        .where((w) => w.active)
        .toList();
  }

  /// Creates or updates stock, MRP and selling price for [productId] at [warehouseId].
  Future<void> updateInventory(
      String productId, String warehouseId, int quantity, double mrp, double sellingPrice) async {
    await _client.post(
      ApiPaths.inventoryUpsert,
      {
        'productId': productId,
        'warehouseId': warehouseId,
        'quantity': quantity,
        'mrp': mrp,
        'sellingPrice': sellingPrice,
      },
    );
  }

  /// Atomically toggles the availability of [productId] for [warehouseId].
  /// Returns the new active state: `true` = available, `false` = hidden from market.
  Future<bool> toggleInventoryAvailability(
      String productId, String warehouseId) async {
    final data = await _client.patch(
      ApiPaths.inventoryToggle(productId, warehouseId),
    );
    return data['active'] as bool? ?? false;
  }

  /// Fetches all inventory rows for [warehouseId], each merged with product
  /// metadata (name, images, category), using the single warehouse listing
  /// endpoint. Cursor pagination is handled internally — callers receive a
  /// flat list with no product IDs constructed or passed.
  Future<List<CatalogProduct>> getCatalogProductsByWarehouse(
      String warehouseId) async {
    final List<CatalogProduct> all = [];
    String cursor = '';
    const int pageSize = 100;

    while (true) {
      final data = await _client.get(
        ApiPaths.inventoryByWarehouse,
        queryParameters: {
          'warehouseId': warehouseId,
          if (cursor.isNotEmpty) 'cursor': cursor,
          'size': pageSize,
        },
      );
      final content = (data['content'] as List<dynamic>? ?? [])
          .map((e) => CatalogProduct.fromWarehouseItem(e as Map<String, dynamic>))
          .toList();
      all.addAll(content);
      final hasMore = data['hasMore'] as bool? ?? false;
      if (!hasMore) break;
      cursor = data['nextCursor'] as String? ?? '';
      if (cursor.isEmpty) break;
    }

    return all;
  }
}
