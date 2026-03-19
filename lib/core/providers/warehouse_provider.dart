import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/warehouse.dart';
import '../../features/catalog/providers/catalog_provider.dart'
    show catalogWarehousesProvider;

/// Single source of truth for the active warehouses list.
/// References the same provider as [catalogWarehousesProvider] so both share
/// the same cache — no duplicate API calls.
final warehousesProvider = catalogWarehousesProvider;

// ── Active warehouse (global context shared by all screens) ───────────────────

class ActiveWarehouseNotifier extends StateNotifier<Warehouse?> {
  ActiveWarehouseNotifier() : super(null);
  void select(Warehouse? warehouse) => state = warehouse;
}

/// The globally selected warehouse.
/// Defaults to the first active warehouse once the list loads.
/// null = "All Warehouses" (no warehouse filter).
final activeWarehouseProvider =
    StateNotifierProvider<ActiveWarehouseNotifier, Warehouse?>(
  (ref) {
    final notifier = ActiveWarehouseNotifier();
    // Auto-select first warehouse when list loads (only if nothing selected yet)
    ref.listen<AsyncValue<List<Warehouse>>>(warehousesProvider, (_, next) {
      next.whenData((warehouses) {
        if (notifier.state == null && warehouses.isNotEmpty) {
          notifier.select(warehouses.first);
        }
      });
    });
    return notifier;
  },
);
