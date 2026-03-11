import '../api/admin_api_client.dart';
import '../api/admin_api_endpoints.dart';
import '../models/catalog_product.dart';
import '../models/pincode.dart';

/// Fetches serviceable pincodes and product catalog from the backend.
class AdminCatalogService {
  const AdminCatalogService(this._client);
  final AdminApiClient _client;

  /// Fetches all serviceable pincodes (areas where delivery is available).
  Future<List<Pincode>> getServiceAreas() async {
    final list = await _client.getList(
      AdminApiEndpoints.serviceAreas,
    );
    return list
        .map((e) => Pincode.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Updates stock quantity and selling price for [productId] at [pincode].
  /// Preserves the existing MRP — only sellingPrice and quantity are changed.
  Future<void> updateInventory(
      String productId, String pincode, int quantity, double mrp, double sellingPrice) async {
    await _client.put(
      AdminApiEndpoints.productInventory(productId),
      {
        'entries': [
          {
            'pincode': pincode,
            'quantityAvailable': quantity,
            'mrp': mrp,
            'sellingPrice': sellingPrice,
          }
        ]
      },
    );
  }

  /// Toggles the availability of [productId] for [pincode].
  /// Returns the new active state: `true` = available, `false` = hidden from market.
  Future<bool> toggleInventoryAvailability(
      String productId, String pincode) async {
    final data = await _client.patch(
      AdminApiEndpoints.inventoryToggle(productId, pincode),
    );
    return data['active'] as bool? ?? false;
  }

  /// Fetches all products with their inventory per pincode.
  /// Returns CatalogProducts; filter by selected pincode in the UI.
  Future<List<CatalogProduct>> getCatalogProducts() async {
    final List<Map<String, dynamic>> all = [];
    int page = 0;
    const size = 100;

    while (true) {
      final data = await _client.get(
        AdminApiEndpoints.catalogProducts,
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

    return all.map((m) => CatalogProduct.fromAdminJson(m)).toList();
  }
}
