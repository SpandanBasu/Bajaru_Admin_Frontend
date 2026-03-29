import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/admin_api_client.dart';
import '../../../core/models/catalog_product.dart';
import '../../../core/models/warehouse.dart';
import '../../../core/services/admin_catalog_service.dart';

// ── Service provider ──────────────────────────────────────────────────────────

final _catalogServiceProvider = Provider<AdminCatalogService>(
  (ref) => AdminCatalogService(ref.watch(adminApiClientProvider)),
);

// ── Warehouses (catalog inventory areas) ─────────────────────────────────────

final catalogWarehousesProvider = FutureProvider<List<Warehouse>>((ref) async {
  final service = ref.watch(_catalogServiceProvider);
  return service.getWarehouses();
});

// ── Search & filters ─────────────────────────────────────────────────────────

final catalogSearchProvider = StateProvider<String>((_) => '');
final catalogCategoryProvider = StateProvider<ProductCategory>((_) => ProductCategory.all);
final catalogOutOfStockOnlyProvider = StateProvider<bool>((_) => false);

// ── Catalog products (warehouse-driven, mutable for toggle/update) ────────────

class CatalogNotifier extends StateNotifier<AsyncValue<List<CatalogProduct>>> {
  // Start with empty data; load is triggered by warehouse selection.
  CatalogNotifier(this._service) : super(const AsyncValue.data([]));

  final AdminCatalogService _service;

  /// Fetches all inventory rows merged with product metadata for [warehouseId].
  /// Must be called whenever the selected warehouse changes.
  Future<void> loadForWarehouse(String warehouseId) async {
    state = const AsyncValue.loading();
    try {
      final products =
          await _service.getCatalogProductsByWarehouse(warehouseId);
      state = AsyncValue.data(products);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Optimistically flips the availability toggle in local state,
  /// then persists the change via the backend.
  /// Reverts to the original state if the API call fails.
  Future<void> toggleAvailability(String productId, String warehouseId) async {
    // Capture original state for rollback
    final originalState = state;

    // Optimistic local update
    state.whenData((products) {
      state = AsyncValue.data(products.map((p) {
        if (p.id != productId) return p;
        final data = p.warehouseData[warehouseId];
        if (data == null) return p;
        return p.copyWith(
          warehouseData: Map.from(p.warehouseData)
            ..[warehouseId] = data.copyWith(isAvailable: !data.isAvailable),
        );
      }).toList());
    });

    // Persist to backend; rollback on failure
    try {
      await _service.toggleInventoryAvailability(productId, warehouseId);
    } catch (_) {
      state = originalState;
      rethrow;
    }
  }

  Future<void> updateStockAndPrice(
    String productId,
    String warehouseId,
    double newStock,
    double newPrice,
    double newMrp,
  ) async {
    final originalState = state;

    // Optimistic local update
    state.whenData((products) {
      state = AsyncValue.data(products.map((p) {
        if (p.id != productId) return p;
        final data = p.warehouseData[warehouseId];
        if (data == null) return p;
        return p.copyWith(
          warehouseData: Map.from(p.warehouseData)
            ..[warehouseId] = data.copyWith(
              stock: newStock,
              price: newPrice,
              mrp: newMrp,
            ),
        );
      }).toList());
    });

    // Persist to backend; rollback on failure
    try {
      await _service.updateInventory(
        productId,
        warehouseId,
        newStock.round(),
        newMrp,
        newPrice,
      );
    } catch (_) {
      state = originalState;
      rethrow;
    }
  }
}

final catalogProvider =
    StateNotifierProvider<CatalogNotifier, AsyncValue<List<CatalogProduct>>>(
  (ref) => CatalogNotifier(ref.read(_catalogServiceProvider)),
);

// ── Filtered catalog ──────────────────────────────────────────────────────────
// Data is already scoped to the selected warehouse, so no warehouse filter needed.

final filteredCatalogProvider = Provider<List<CatalogProduct>>((ref) {
  final catalogState = ref.watch(catalogProvider);
  final query = ref.watch(catalogSearchProvider).toLowerCase();
  final category = ref.watch(catalogCategoryProvider);
  final oosOnly = ref.watch(catalogOutOfStockOnlyProvider);

  return catalogState.when(
    data: (products) {
      return products.where((p) {
        if (category != ProductCategory.all && p.category != category) return false;
        if (query.isNotEmpty && !p.name.toLowerCase().contains(query)) return false;
        // Data is already scoped to one warehouse; check if that entry is unavailable.
        if (oosOnly) return p.warehouseData.values.any((d) => !d.isAvailable);
        return true;
      }).toList();
    },
    loading: () => [],
    error: (_, __) => [],
  );
});
