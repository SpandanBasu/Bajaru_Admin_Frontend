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

  /// Fetches all products with their per-warehouse inventory embedded.
  /// Products come from MongoDB (admin handler); inventory from PostgreSQL (inventory handler).
  Future<List<CatalogProduct>> getCatalogProducts() async {
    final List<Map<String, dynamic>> all = [];
    int page = 0;
    const size = 100;

    while (true) {
      final data = await _client.get(
        ApiPaths.catalogProducts,
        queryParameters: {'page': page, 'size': size, 'active': true},
      );
      final content = data['content'] as List<dynamic>? ?? [];
      for (final item in content) {
        all.add(item as Map<String, dynamic>);
      }
      final totalPages = data['totalPages'] as int? ?? 1;
      if (page >= totalPages - 1) break;
      page++;
    }

    if (all.isEmpty) return [];

    final ids = all
        .map((p) => p['id'] as String? ?? '')
        .where((id) => id.isNotEmpty)
        .toList();

    // Single bulk request (avoids N parallel GETs → rate limit 429 on /inventory/admin/{id}).
    List<Map<String, dynamic>> bulkRows = [];
    try {
      final raw = await _client.postList(
        ApiPaths.inventoryByProducts,
        {'productIds': ids},
      );
      bulkRows = raw.cast<Map<String, dynamic>>();
    } catch (_) {
      // Old backend or network — show catalog without inventory rows.
    }

    final byProduct = <String, List<Map<String, dynamic>>>{};
    for (final row in bulkRows) {
      final pid = row['productId'] as String? ?? '';
      if (pid.isEmpty) continue;
      byProduct.putIfAbsent(pid, () => []).add(row);
    }

    return all.map((p) {
      final id = p['id'] as String? ?? '';
      final inv = id.isEmpty ? <Map<String, dynamic>>[] : (byProduct[id] ?? []);
      return CatalogProduct.fromAdminJson({...p, 'inventory': inv});
    }).toList();
  }
}
