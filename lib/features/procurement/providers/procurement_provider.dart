import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/admin_api_client.dart';
import '../../../core/models/procurement_item.dart';
import '../../../core/models/warehouse.dart';
import '../../../core/services/admin_procurement_service.dart';
import '../../../core/providers/warehouse_provider.dart';

export '../../catalog/providers/catalog_provider.dart' show catalogWarehousesProvider;

// ── Service provider ──────────────────────────────────────────────────────────

final _procurementServiceProvider = Provider<AdminProcurementService>(
    (ref) => AdminProcurementService(ref.watch(adminApiClientProvider)));

// ── Selected warehouse & date filters ─────────────────────────────────────────

/// Delivery date filter; defaults to today (date only, local).
final procurementSelectedDateProvider = StateProvider<DateTime>((ref) {
  final n = DateTime.now();
  return DateTime(n.year, n.month, n.day);
});

// ── Filters ───────────────────────────────────────────────────────────────────

enum ProcurementSelectionType { none, pendingOnly, procuredOnly, mixed }
enum ProcurementStatusFilter { all, pending, done }

final procurementStatusFilterProvider =
    StateProvider<ProcurementStatusFilter>((ref) => ProcurementStatusFilter.all);

// ── Notifier ──────────────────────────────────────────────────────────────────

class ProcurementNotifier extends StateNotifier<List<ProcurementItem>> {
  ProcurementNotifier(this._service) : super([]);

  final AdminProcurementService _service;
  DateTime _deliveryDate = DateTime.now();

  Future<void> refresh({String? warehouseId, DateTime? deliveryDate}) async {
    _deliveryDate = deliveryDate ?? DateTime.now();
    try {
      final result = await _service.getItems(
          warehouseId: warehouseId, deliveryDate: deliveryDate);
      state = result.items;
    } catch (_) {}
  }

  void toggleCheck(String id) {
    state = [
      for (final item in state)
        if (item.id == id) item.copyWith(isChecked: !item.isChecked) else item,
    ];
  }

  void setStatus(String id, ProcurementStatus status) {
    final item = state.firstWhere((i) => i.id == id);
    state = [
      for (final i in state)
        if (i.id == id) i.copyWith(status: status) else i,
    ];
    _persistStatus(item.productId, item.warehouseId, status);
  }

  /// Marks checked pending items as Done, unchecks all selected.
  void markSelectedProcured() {
    final toPersist = state
        .where((i) => i.isChecked && i.status != ProcurementStatus.done)
        .toList();
    state = [
      for (final item in state)
        if (item.isChecked && item.status != ProcurementStatus.done)
          item.copyWith(status: ProcurementStatus.done, isChecked: false)
        else if (item.isChecked)
          item.copyWith(isChecked: false)
        else
          item,
    ];
    for (final item in toPersist) {
      _persistStatus(item.productId, item.warehouseId, ProcurementStatus.done);
    }
  }

  /// Resets checked Done items back to Pending, unchecks all selected.
  void markSelectedUnprocured() {
    final toPersist = state
        .where((i) => i.isChecked && i.status == ProcurementStatus.done)
        .toList();
    state = [
      for (final item in state)
        if (item.isChecked && item.status == ProcurementStatus.done)
          item.copyWith(status: ProcurementStatus.pending, isChecked: false)
        else if (item.isChecked)
          item.copyWith(isChecked: false)
        else
          item,
    ];
    for (final item in toPersist) {
      _persistStatus(item.productId, item.warehouseId, ProcurementStatus.pending);
    }
  }

  void _persistStatus(
      String productId, String warehouseId, ProcurementStatus status) {
    _service.setItemStatus(
      productId:    productId,
      warehouseId:  warehouseId,
      deliveryDate: _deliveryDate,
      status:       status == ProcurementStatus.done ? 'DONE' : 'PENDING',
    );
  }
}

final procurementProvider =
    StateNotifierProvider<ProcurementNotifier, List<ProcurementItem>>((ref) {
  final notifier = ProcurementNotifier(ref.read(_procurementServiceProvider));

  void _reload() {
    final warehouse = ref.read(activeWarehouseProvider);
    final date      = ref.read(procurementSelectedDateProvider);
    notifier.refresh(warehouseId: warehouse?.warehouseId, deliveryDate: date);
  }

  ref.listen<Warehouse?>(activeWarehouseProvider, (_, __) => _reload());
  ref.listen<DateTime>(procurementSelectedDateProvider, (_, __) => _reload());
  _reload();
  return notifier;
});

// ── Derived providers ─────────────────────────────────────────────────────────

final filteredProcurementProvider = Provider<List<ProcurementItem>>((ref) {
  final all    = ref.watch(procurementProvider);
  final filter = ref.watch(procurementStatusFilterProvider);

  final filtered = switch (filter) {
    ProcurementStatusFilter.all     => all,
    ProcurementStatusFilter.pending => all.where((i) => i.status != ProcurementStatus.done).toList(),
    ProcurementStatusFilter.done    => all.where((i) => i.status == ProcurementStatus.done).toList(),
  };

  // Always sort pending first, done last.
  return [...filtered]..sort((a, b) {
    final aRank = a.status == ProcurementStatus.done ? 1 : 0;
    final bRank = b.status == ProcurementStatus.done ? 1 : 0;
    return aRank.compareTo(bRank);
  });
});

final procurementSelectionTypeProvider = Provider((ref) {
  final selected = ref.watch(filteredProcurementProvider).where((i) => i.isChecked);
  if (selected.isEmpty) return ProcurementSelectionType.none;
  final hasPending = selected.any((i) => i.status != ProcurementStatus.done);
  final hasDone    = selected.any((i) => i.status == ProcurementStatus.done);
  if (hasPending && hasDone) return ProcurementSelectionType.mixed;
  if (hasDone)               return ProcurementSelectionType.procuredOnly;
  return ProcurementSelectionType.pendingOnly;
});

// Chip label counts always reflect the full (unfiltered) list.
final procurementChipCountsProvider = Provider((ref) {
  final all = ref.watch(procurementProvider);
  return (
    all:     all.length,
    pending: all.where((i) => i.status != ProcurementStatus.done).length,
    done:    all.where((i) => i.status == ProcurementStatus.done).length,
  );
});

// Summary stats also from the full list so the card is always accurate.
final procurementSummaryProvider = Provider((ref) {
  final items = ref.watch(procurementProvider);
  return (
    totalNeeded:   items.fold<double>(0, (s, i) => s + i.neededToday),
    itemCount:     items.length,
    orderCount:    items.fold<int>(0, (s, i) => s + i.orderCount),
    procuredCount: items.where((i) => i.status == ProcurementStatus.done).length,
  );
});
