import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/admin_api_client.dart';
import '../../../core/models/procurement_item.dart';
import '../../../core/services/admin_procurement_service.dart';

// ── Service provider ──────────────────────────────────────────────────────────

final _procurementServiceProvider = Provider<AdminProcurementService>(
    (ref) => AdminProcurementService(ref.watch(adminApiClientProvider)));

// ── Filter ────────────────────────────────────────────────────────────────────

enum ProcurementSelectionType { none, pendingOnly, procuredOnly, mixed }

final procurementSelectedPincodeProvider = StateProvider<String?>((ref) => null);

// ── Notifier ──────────────────────────────────────────────────────────────────

class ProcurementNotifier extends StateNotifier<List<ProcurementItem>> {
  ProcurementNotifier(this._service) : super([]) {
    refresh();
  }

  final AdminProcurementService _service;

  Future<void> refresh({String? pincode}) async {
    try {
      final result = await _service.getItems(pincode: pincode);
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
    state = [
      for (final item in state)
        if (item.id == id) item.copyWith(status: status) else item,
    ];
  }

  /// Marks checked pending/urgent items as Done, unchecks all selected.
  void markSelectedProcured() {
    state = [
      for (final item in state)
        if (item.isChecked && item.status != ProcurementStatus.done)
          item.copyWith(status: ProcurementStatus.done, isChecked: false)
        else if (item.isChecked)
          item.copyWith(isChecked: false)
        else
          item,
    ];
  }

  /// Resets checked Done items back to Pending, unchecks all selected.
  void markSelectedUnprocured() {
    state = [
      for (final item in state)
        if (item.isChecked && item.status == ProcurementStatus.done)
          item.copyWith(status: ProcurementStatus.pending, isChecked: false)
        else if (item.isChecked)
          item.copyWith(isChecked: false)
        else
          item,
    ];
  }
}

final procurementProvider =
    StateNotifierProvider<ProcurementNotifier, List<ProcurementItem>>((ref) {
  final notifier = ProcurementNotifier(ref.read(_procurementServiceProvider));
  ref.listen<String?>(procurementSelectedPincodeProvider, (_, pincode) {
    notifier.refresh(pincode: pincode);
  });
  return notifier;
});

// ── Derived providers ─────────────────────────────────────────────────────────

final filteredProcurementProvider = Provider<List<ProcurementItem>>((ref) {
  final items   = ref.watch(procurementProvider);
  final pincode = ref.watch(procurementSelectedPincodeProvider);
  if (pincode == null) return items;
  return items.where((i) => i.pincodeCode == pincode).toList();
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

final procurementSummaryProvider = Provider((ref) {
  final items = ref.watch(filteredProcurementProvider);
  return (
    totalInStock:   items.fold<double>(0, (s, i) => s + i.inStock),
    totalNeeded:    items.fold<double>(0, (s, i) => s + i.neededToday),
    totalToProcure: items.fold<double>(0, (s, i) => s + i.toProcure),
    itemCount:      items.length,
    orderCount:     items.fold<int>(0, (s, i) => s + i.orderCount),
    procuredCount:  items.where((i) => i.status == ProcurementStatus.done).length,
  );
});
