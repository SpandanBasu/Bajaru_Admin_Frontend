import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/admin_api_client.dart';
import '../../../core/models/batch_order.dart';
import '../../../core/services/admin_packing_service.dart';

// ── Service provider ──────────────────────────────────────────────────────────

final _packingServiceProvider = Provider<AdminPackingService>(
    (ref) => AdminPackingService(ref.watch(adminApiClientProvider)));

// ── Filters ───────────────────────────────────────────────────────────────────

final ordersTabProvider = StateProvider<OrderPackStatus>(
    (_) => OrderPackStatus.toPack);

final ordersSelectedPincodeProvider = StateProvider<String?>((_) => null);

// ── Orders notifier ───────────────────────────────────────────────────────────

class OrdersNotifier extends StateNotifier<List<BatchOrder>> {
  OrdersNotifier(this._service) : super([]) {
    refresh();
  }

  final AdminPackingService _service;

  Future<void> refresh({String? pincode}) async {
    try {
      state = await _service.getPackingOrders(pincode: pincode);
    } catch (_) {}
  }

  void toggleExpand(String id) {
    state = [
      for (final o in state)
        if (o.id == id) o.copyWith(isExpanded: !o.isExpanded) else o,
    ];
  }

  void toggleItem(String orderId, String itemId) async {
    // Optimistic update
    state = [
      for (final o in state)
        if (o.id == orderId)
          o.copyWith(items: [
            for (final item in o.items)
              if (item.id == itemId)
                item.copyWith(isChecked: !item.isChecked)
              else
                item,
          ])
        else
          o,
    ];
    try {
      final updated = await _service.toggleItem(orderId, itemId);
      _replaceOrder(updated);
    } catch (_) {}
  }

  void completeOrder(String id) => setStatus(id, OrderPackStatus.ready);

  void setStatus(String id, OrderPackStatus status) async {
    state = [
      for (final o in state)
        if (o.id == id)
          o.copyWith(
            status: status,
            clearIssueMessage: status != OrderPackStatus.issues,
          )
        else
          o,
    ];
    try {
      final updated =
          await _service.updateStatus(id, status.name.toUpperCase());
      _replaceOrder(updated);
    } catch (_) {}
  }

  void markIssue(String id, String message) async {
    state = [
      for (final o in state)
        if (o.id == id)
          o.copyWith(status: OrderPackStatus.issues, issueMessage: message.trim())
        else
          o,
    ];
    try {
      final updated = await _service.markIssue(id, message);
      _replaceOrder(updated);
    } catch (_) {}
  }

  void _replaceOrder(BatchOrder updated) {
    state = [
      for (final o in state)
        if (o.id == updated.id)
          updated.copyWith(isExpanded: o.isExpanded)
        else
          o,
    ];
  }
}

final ordersProvider =
    StateNotifierProvider<OrdersNotifier, List<BatchOrder>>((ref) {
  final notifier = OrdersNotifier(ref.read(_packingServiceProvider));
  ref.listen<String?>(ordersSelectedPincodeProvider, (_, pincode) {
    notifier.refresh(pincode: pincode);
  });
  return notifier;
});

// ── Derived providers (unchanged public API for UI) ───────────────────────────

final filteredOrdersProvider = Provider((ref) {
  final orders  = ref.watch(ordersProvider);
  final tab     = ref.watch(ordersTabProvider);
  final pincode = ref.watch(ordersSelectedPincodeProvider);

  var base = pincode == null
      ? orders
      : orders.where((o) => o.pincode == pincode).toList();

  if (tab == OrderPackStatus.toPack) {
    return base
        .where((o) =>
            o.status == OrderPackStatus.toPack ||
            o.status == OrderPackStatus.packing)
        .toList();
  }
  return base.where((o) => o.status == tab).toList();
});

final ordersTabCountProvider = Provider((ref) {
  final orders  = ref.watch(ordersProvider);
  final pincode = ref.watch(ordersSelectedPincodeProvider);

  final base = pincode == null
      ? orders
      : orders.where((o) => o.pincode == pincode).toList();

  return (
    toPack: base
        .where((o) =>
            o.status == OrderPackStatus.toPack ||
            o.status == OrderPackStatus.packing)
        .length,
    ready:  base.where((o) => o.status == OrderPackStatus.ready).length,
    issues: base.where((o) => o.status == OrderPackStatus.issues).length,
  );
});
