import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/admin_api_client.dart';
import '../../../core/models/batch_order.dart';
import '../../../core/models/warehouse.dart';
import '../../../core/providers/warehouse_provider.dart';
import '../../../core/services/admin_packing_service.dart';

// ── Packing mode ──────────────────────────────────────────────────────────────

enum PackingMode { byOrder, byVegetable }

final packingModeProvider = StateProvider<PackingMode>((_) => PackingMode.byOrder);

// ── Service provider ──────────────────────────────────────────────────────────

final _packingServiceProvider = Provider<AdminPackingService>(
    (ref) => AdminPackingService(ref.watch(adminApiClientProvider)));

// ── Filters ───────────────────────────────────────────────────────────────────

final ordersTabProvider = StateProvider<OrderPackStatus>(
    (_) => OrderPackStatus.toPack);

/// Selected delivery date for packing orders. null means today (backend defaults to today).
final ordersSelectedDateProvider = StateProvider<DateTime?>((_) => null);

// ── Pagination state ──────────────────────────────────────────────────────────

class PackingState {
  final List<BatchOrder> orders;
  final bool isLoadingMore;
  final bool hasMore;
  final int nextPage;

  const PackingState({
    this.orders = const [],
    this.isLoadingMore = false,
    this.hasMore = true,
    this.nextPage = 0,
  });

  PackingState copyWith({
    List<BatchOrder>? orders,
    bool? isLoadingMore,
    bool? hasMore,
    int? nextPage,
  }) =>
      PackingState(
        orders: orders ?? this.orders,
        isLoadingMore: isLoadingMore ?? this.isLoadingMore,
        hasMore: hasMore ?? this.hasMore,
        nextPage: nextPage ?? this.nextPage,
      );
}

// ── Orders notifier ───────────────────────────────────────────────────────────

class OrdersNotifier extends StateNotifier<PackingState> {
  OrdersNotifier(this._service) : super(const PackingState()) {
    refresh();
  }

  final AdminPackingService _service;
  String? _warehouseId;
  DateTime? _deliveryDate;

  Future<void> refresh({String? warehouseId, DateTime? deliveryDate}) async {
    _warehouseId = warehouseId;
    _deliveryDate = deliveryDate;
    try {
      final result = await _service.getPackingOrders(
        warehouseId: warehouseId,
        deliveryDate: deliveryDate,
        page: 0,
      );
      state = PackingState(
        orders: result.orders,
        hasMore: result.hasMore,
        nextPage: 1,
      );
    } catch (_) {}
  }

  Future<void> loadMore() async {
    if (!state.hasMore || state.isLoadingMore) return;
    state = state.copyWith(isLoadingMore: true);
    try {
      final result = await _service.getPackingOrders(
        warehouseId: _warehouseId,
        deliveryDate: _deliveryDate,
        page: state.nextPage,
      );
      state = state.copyWith(
        orders: [...state.orders, ...result.orders],
        isLoadingMore: false,
        hasMore: result.hasMore,
        nextPage: state.nextPage + 1,
      );
    } catch (_) {
      state = state.copyWith(isLoadingMore: false);
    }
  }

  void toggleExpand(String id) {
    state = state.copyWith(orders: [
      for (final o in state.orders)
        if (o.id == id) o.copyWith(isExpanded: !o.isExpanded) else o,
    ]);
  }

  void toggleItem(String orderId, String itemId) async {
    // Optimistic update
    state = state.copyWith(orders: [
      for (final o in state.orders)
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
    ]);
    try {
      final updated = await _service.toggleItem(orderId, itemId);
      _replaceOrder(updated);
    } catch (_) {}
  }

  void completeOrder(String id) => setStatus(id, OrderPackStatus.ready);

  void setStatus(String id, OrderPackStatus status) async {
    state = state.copyWith(orders: [
      for (final o in state.orders)
        if (o.id == id)
          o.copyWith(
            status: status,
            clearIssueMessage: status != OrderPackStatus.issues,
          )
        else
          o,
    ]);
    try {
      final updated =
          await _service.updateStatus(id, status.name.toUpperCase());
      _replaceOrder(updated);
    } catch (_) {}
  }

  void markIssue(String id, String message) async {
    state = state.copyWith(orders: [
      for (final o in state.orders)
        if (o.id == id)
          o.copyWith(status: OrderPackStatus.issues, issueMessage: message.trim())
        else
          o,
    ]);
    try {
      final updated = await _service.markIssue(id, message);
      _replaceOrder(updated);
    } catch (_) {}
  }

  void _replaceOrder(BatchOrder updated) {
    state = state.copyWith(orders: [
      for (final o in state.orders)
        if (o.id == updated.id)
          updated.copyWith(isExpanded: o.isExpanded)
        else
          o,
    ]);
  }
}

final ordersProvider =
    StateNotifierProvider<OrdersNotifier, PackingState>((ref) {
  final notifier = OrdersNotifier(ref.read(_packingServiceProvider));

  void _reload() {
    final warehouse = ref.read(activeWarehouseProvider);
    final date = ref.read(ordersSelectedDateProvider);
    notifier.refresh(warehouseId: warehouse?.warehouseId, deliveryDate: date);
  }

  ref.listen<Warehouse?>(activeWarehouseProvider, (_, __) => _reload());
  ref.listen<DateTime?>(ordersSelectedDateProvider, (_, __) => _reload());
  // Refresh order data when switching back from vegetable mode so checked
  // state changes made in vegetable view are reflected immediately.
  ref.listen<PackingMode>(packingModeProvider, (prev, next) {
    if (prev == PackingMode.byVegetable && next == PackingMode.byOrder) {
      _reload();
    }
  });
  return notifier;
});

// ── Derived providers ─────────────────────────────────────────────────────────

final _allPackingOrdersProvider =
    Provider<List<BatchOrder>>((ref) => ref.watch(ordersProvider).orders);

final filteredOrdersProvider = Provider((ref) {
  final orders = ref.watch(_allPackingOrdersProvider);
  final tab = ref.watch(ordersTabProvider);

  if (tab == OrderPackStatus.toPack) {
    return orders
        .where((o) =>
            o.status == OrderPackStatus.toPack ||
            o.status == OrderPackStatus.packing)
        .toList();
  }
  return orders.where((o) => o.status == tab).toList();
});

final ordersTabCountProvider = Provider((ref) {
  final orders = ref.watch(_allPackingOrdersProvider);
  return (
    toPack: orders
        .where((o) =>
            o.status == OrderPackStatus.toPack ||
            o.status == OrderPackStatus.packing)
        .length,
    ready: orders.where((o) => o.status == OrderPackStatus.ready).length,
    issues: orders.where((o) => o.status == OrderPackStatus.issues).length,
  );
});

// ── Vegetable pack view ───────────────────────────────────────────────────────

class VegetablePackState {
  final List<VegetablePackGroup> groups;
  final bool isLoading;

  const VegetablePackState({
    this.groups = const [],
    this.isLoading = false,
  });

  VegetablePackState copyWith({
    List<VegetablePackGroup>? groups,
    bool? isLoading,
  }) =>
      VegetablePackState(
        groups: groups ?? this.groups,
        isLoading: isLoading ?? this.isLoading,
      );
}

class VegetablePackNotifier extends StateNotifier<VegetablePackState> {
  VegetablePackNotifier(this._service) : super(const VegetablePackState());

  final AdminPackingService _service;
  String? _warehouseId;
  DateTime? _deliveryDate;

  Future<void> refresh({String? warehouseId, DateTime? deliveryDate}) async {
    _warehouseId = warehouseId;
    _deliveryDate = deliveryDate;
    state = state.copyWith(isLoading: true);
    try {
      final groups = await _service.getVegetableView(
        warehouseId: warehouseId,
        deliveryDate: deliveryDate,
      );
      state = VegetablePackState(groups: groups);
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }

  void toggleExpand(String productId) {
    state = state.copyWith(groups: [
      for (final g in state.groups)
        if (g.productId == productId) g.copyWith(isExpanded: !g.isExpanded) else g,
    ]);
  }

  void togglePacket(String orderId, String itemId) async {
    // Optimistic update
    state = state.copyWith(groups: [
      for (final g in state.groups)
        g.copyWith(
          packets: [
            for (final p in g.packets)
              if (p.orderId == orderId && p.itemId == itemId)
                p.copyWith(isChecked: !p.isChecked)
              else
                p,
          ],
        ),
    ]);
    // Recompute allChecked for each group after optimistic update.
    state = state.copyWith(groups: [
      for (final g in state.groups)
        g.copyWith(
          allChecked: g.packets.isNotEmpty && g.packets.every((p) => p.isChecked),
        ),
    ]);
    try {
      await _service.toggleItem(orderId, itemId);
    } catch (_) {
      // Revert by re-fetching on error.
      await refresh(warehouseId: _warehouseId, deliveryDate: _deliveryDate);
    }
  }
}

final vegetablePackProvider =
    StateNotifierProvider<VegetablePackNotifier, VegetablePackState>((ref) {
  final notifier = VegetablePackNotifier(ref.read(_packingServiceProvider));

  void _reload() {
    final warehouse = ref.read(activeWarehouseProvider);
    final date = ref.read(ordersSelectedDateProvider);
    notifier.refresh(warehouseId: warehouse?.warehouseId, deliveryDate: date);
  }

  ref.listen<Warehouse?>(activeWarehouseProvider, (_, __) => _reload());
  ref.listen<DateTime?>(ordersSelectedDateProvider, (_, __) => _reload());
  ref.listen<PackingMode>(packingModeProvider, (_, next) {
    if (next == PackingMode.byVegetable) _reload();
  });
  return notifier;
});
