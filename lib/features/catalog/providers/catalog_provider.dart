import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/admin_api_client.dart';
import '../../../core/models/catalog_product.dart';
import '../../../core/models/pincode.dart';
import '../../../core/services/admin_catalog_service.dart';

// ── Service provider ──────────────────────────────────────────────────────────

final _catalogServiceProvider = Provider<AdminCatalogService>(
  (ref) => AdminCatalogService(ref.watch(adminApiClientProvider)),
);

// ── Pincodes (serviceable delivery areas) ─────────────────────────────────────

final catalogPincodesProvider = FutureProvider<List<Pincode>>((ref) async {
  final service = ref.watch(_catalogServiceProvider);
  return service.getServiceAreas();
});

// ── Selected pincode ─────────────────────────────────────────────────────────

final selectedPincodeProvider = StateProvider<Pincode?>((ref) => null);

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
  Future<void> toggleAvailability(String productId, String pincodeCode) async {
    // Capture original state for rollback
    final originalState = state;

    // Optimistic local update
    state.whenData((products) {
      state = AsyncValue.data(products.map((p) {
        if (p.id != productId) return p;
        final data = p.pincodeData[pincodeCode];
        if (data == null) return p;
        return p.copyWith(
          pincodeData: Map.from(p.pincodeData)
            ..[pincodeCode] = data.copyWith(isAvailable: !data.isAvailable),
        );
      }).toList());
    });

    // Persist to backend; rollback on failure
    try {
      await _service.toggleInventoryAvailability(productId, pincodeCode);
    } catch (_) {
      state = originalState;
      rethrow;
    }
  }

  Future<void> updateStockAndPrice(
    String productId,
    String pincodeCode,
    double newStock,
    double newPrice,
    double newMrp,
  ) async {
    final originalState = state;

    // Optimistic local update
    state.whenData((products) {
      state = AsyncValue.data(products.map((p) {
        if (p.id != productId) return p;
        final data = p.pincodeData[pincodeCode];
        if (data == null) return p;
        return p.copyWith(
          pincodeData: Map.from(p.pincodeData)
            ..[pincodeCode] = data.copyWith(
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
        pincodeCode,
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

// ── Filtered catalog (only products with inventory at selected pincode) ───────

final filteredCatalogProvider = Provider<List<CatalogProduct>>((ref) {
  final catalogState = ref.watch(catalogProvider);
  final query = ref.watch(catalogSearchProvider).toLowerCase();
  final category = ref.watch(catalogCategoryProvider);
  final oosOnly = ref.watch(catalogOutOfStockOnlyProvider);
  final pincode = ref.watch(selectedPincodeProvider);

  return catalogState.when(
    data: (products) {
      return products.where((p) {
        // When pincode selected: only show products that have inventory at that pincode
        if (pincode != null && !p.pincodeData.containsKey(pincode.code)) {
          return false;
        }
        if (category != ProductCategory.all && p.category != category) return false;
        if (query.isNotEmpty && !p.name.toLowerCase().contains(query)) return false;
        if (oosOnly) {
          if (p.isOutOfStock) return true;
          if (pincode != null) {
            return !(p.dataFor(pincode.code)?.isAvailable ?? true);
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
