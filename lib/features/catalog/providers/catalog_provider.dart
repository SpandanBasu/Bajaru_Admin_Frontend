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

// ── Selected warehouse ────────────────────────────────────────────────────────

final selectedWarehouseProvider = StateProvider<Warehouse?>((ref) => null);

// ── Search & filters ─────────────────────────────────────────────────────────

final catalogSearchProvider = StateProvider<String>((_) => '');
final catalogCategoryProvider = StateProvider<ProductCategory>((_) => ProductCategory.all);
final catalogOutOfStockOnlyProvider = StateProvider<bool>((_) => false);

// ── Catalog products (fetched from API, mutable for toggle/update) ─────────────

class CatalogNotifier extends StateNotifier<AsyncValue<List<CatalogProduct>>> {
  CatalogNotifier(this._service) : super(const AsyncValue.loading()) {
    load();
  }

  final AdminCatalogService _service;

  Future<void> load() async {
    state = const AsyncValue.loading();
    try {
      final products = await _service.getCatalogProducts();
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

// ── Filtered catalog (only products with inventory at selected warehouse) ─────

final filteredCatalogProvider = Provider<List<CatalogProduct>>((ref) {
  final catalogState = ref.watch(catalogProvider);
  final query = ref.watch(catalogSearchProvider).toLowerCase();
  final category = ref.watch(catalogCategoryProvider);
  final oosOnly = ref.watch(catalogOutOfStockOnlyProvider);
  final warehouse = ref.watch(selectedWarehouseProvider);

  return catalogState.when(
    data: (products) {
      return products.where((p) {
        // When warehouse selected: only show products with inventory at that warehouse
        if (warehouse != null && !p.warehouseData.containsKey(warehouse.warehouseId)) {
          return false;
        }
        if (category != ProductCategory.all && p.category != category) return false;
        if (query.isNotEmpty && !p.name.toLowerCase().contains(query)) return false;
        if (oosOnly) {
          if (p.isOutOfStock) return true;
          if (warehouse != null) {
            return !(p.dataFor(warehouse.warehouseId)?.isAvailable ?? true);
          }
          return false;
        }
        return true;
      }).toList();
    },
    loading: () => [],
    error: (_, __) => [],
  );
});
