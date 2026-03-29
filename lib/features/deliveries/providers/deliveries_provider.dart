import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/admin_api_client.dart';
import '../../../core/models/delivery_order.dart';
import '../../../core/models/warehouse.dart';
import '../../../core/providers/warehouse_provider.dart';
import '../../../core/services/admin_deliveries_service.dart';

// ── Service provider ──────────────────────────────────────────────────────────

final _deliveriesServiceProvider = Provider<AdminDeliveriesService>(
    (ref) => AdminDeliveriesService(ref.watch(adminApiClientProvider)));

// ── Filters ───────────────────────────────────────────────────────────────────

enum DeliveryFilterStatus { all, pending, outForDelivery, delivered, rejected, cancelled }
enum DeliveryPaymentFilter { all, cod, prepaid }
enum DeliverySortBy {
  none,
  deliveryTimeNewest,
  deliveryTimeOldest,
  amountHighToLow,
  amountLowToHigh,
}

final deliveryFilterProvider =
    StateProvider<DeliveryFilterStatus>((ref) => DeliveryFilterStatus.all);

/// null = today (backend defaults to today when absent).
final deliverySelectedDateProvider = StateProvider<DateTime?>((ref) => null);

final deliveryOrderIdQueryProvider = StateProvider<String>((ref) => '');
final deliveryRiderQueryProvider = StateProvider<String>((ref) => '');
final deliveryPaymentFilterProvider =
    StateProvider<DeliveryPaymentFilter>((ref) => DeliveryPaymentFilter.all);
final deliverySortByProvider =
    StateProvider<DeliverySortBy>((ref) => DeliverySortBy.none);

// ── State ─────────────────────────────────────────────────────────────────────

class DeliveriesState {
  final List<DeliveryOrder> orders;
  final bool isLoadingMore;
  final bool hasMore;
  final int nextPage;

  const DeliveriesState({
    this.orders = const [],
    this.isLoadingMore = false,
    this.hasMore = true,
    this.nextPage = 0,
  });

  DeliveriesState copyWith({
    List<DeliveryOrder>? orders,
    bool? isLoadingMore,
    bool? hasMore,
    int? nextPage,
  }) =>
      DeliveriesState(
        orders: orders ?? this.orders,
        isLoadingMore: isLoadingMore ?? this.isLoadingMore,
        hasMore: hasMore ?? this.hasMore,
        nextPage: nextPage ?? this.nextPage,
      );
}

// ── Notifier ──────────────────────────────────────────────────────────────────

// Maps the UI filter enum to the status string the backend expects.
// Returning null means "all delivery-relevant statuses" (backend default).
String? _filterStatusParam(DeliveryFilterStatus f) => switch (f) {
      DeliveryFilterStatus.all            => null,
      DeliveryFilterStatus.pending        => 'pending',
      DeliveryFilterStatus.outForDelivery => 'outForDelivery',
      DeliveryFilterStatus.delivered      => 'delivered',
      DeliveryFilterStatus.rejected       => 'rejected',
      DeliveryFilterStatus.cancelled      => 'cancelled',
    };

class DeliveriesNotifier extends StateNotifier<DeliveriesState> {
  DeliveriesNotifier(this._service) : super(const DeliveriesState());

  final AdminDeliveriesService _service;
  String _warehouseId = '';
  DateTime? _deliveryDate;
  DeliveryFilterStatus _filterStatus = DeliveryFilterStatus.all;

  Future<void> refresh({
    required String warehouseId,
    DateTime? deliveryDate,
    DeliveryFilterStatus? filterStatus,
  }) async {
    _warehouseId  = warehouseId;
    _deliveryDate = deliveryDate;
    _filterStatus = filterStatus ?? _filterStatus;
    try {
      final result = await _service.getDeliveries(
        status:       _filterStatusParam(_filterStatus),
        warehouseId:  _warehouseId,
        deliveryDate: _deliveryDate,
        page: 0,
      );
      state = DeliveriesState(
        orders:   result.orders,
        hasMore:  result.hasMore,
        nextPage: 1,
      );
    } catch (_) {}
  }

  Future<void> loadMore() async {
    if (!state.hasMore || state.isLoadingMore) return;
    state = state.copyWith(isLoadingMore: true);
    try {
      final result = await _service.getDeliveries(
        status:       _filterStatusParam(_filterStatus),
        warehouseId:  _warehouseId,
        deliveryDate: _deliveryDate,
        page: state.nextPage,
      );
      state = state.copyWith(
        orders:   [...state.orders, ...result.orders],
        isLoadingMore: false,
        hasMore:  result.hasMore,
        nextPage: state.nextPage + 1,
      );
    } catch (_) {
      state = state.copyWith(isLoadingMore: false);
    }
  }
}

final deliveriesProvider =
    StateNotifierProvider<DeliveriesNotifier, DeliveriesState>((ref) {
  final notifier = DeliveriesNotifier(ref.read(_deliveriesServiceProvider));

  void _reload() {
    final warehouse = ref.read(activeWarehouseProvider);
    if (warehouse == null) return;
    final date         = ref.read(deliverySelectedDateProvider);
    final filterStatus = ref.read(deliveryFilterProvider);
    notifier.refresh(
      warehouseId:  warehouse.warehouseId,
      deliveryDate: date,
      filterStatus: filterStatus,
    );
  }

  ref.listen<Warehouse?>(activeWarehouseProvider, (_, __) => _reload(),
      fireImmediately: true);
  ref.listen<DateTime?>(deliverySelectedDateProvider, (_, __) => _reload());
  // Reload from backend when the status tab changes so pagination is correct.
  ref.listen<DeliveryFilterStatus>(deliveryFilterProvider, (_, __) => _reload());
  return notifier;
});

// ── All-orders notifier for counts (unaffected by status filter tab) ─────────

class _AllOrdersForCountsNotifier extends StateNotifier<List<DeliveryOrder>> {
  _AllOrdersForCountsNotifier(this._service) : super([]);

  final AdminDeliveriesService _service;

  Future<void> reload({required String warehouseId, DateTime? deliveryDate}) async {
    try {
      final result = await _service.getDeliveries(
        status: null,
        warehouseId: warehouseId,
        deliveryDate: deliveryDate,
        page: 0,
      );
      state = result.orders;
    } catch (_) {}
  }
}

final allOrdersForCountsProvider = StateNotifierProvider<
    _AllOrdersForCountsNotifier, List<DeliveryOrder>>((ref) {
  final notifier =
      _AllOrdersForCountsNotifier(ref.read(_deliveriesServiceProvider));

  void _reload() {
    final warehouse = ref.read(activeWarehouseProvider);
    if (warehouse == null) return;
    final date = ref.read(deliverySelectedDateProvider);
    notifier.reload(
      warehouseId: warehouse.warehouseId,
      deliveryDate: date,
    );
  }

  ref.listen<Warehouse?>(activeWarehouseProvider, (_, __) => _reload(),
      fireImmediately: true);
  ref.listen<DateTime?>(deliverySelectedDateProvider, (_, __) => _reload());
  return notifier;
});

// ── Derived providers ─────────────────────────────────────────────────────────

final filteredDeliveriesProvider = Provider<List<DeliveryOrder>>((ref) {
  final orders        = ref.watch(deliveriesProvider).orders;
  final orderIdQuery  = ref.watch(deliveryOrderIdQueryProvider).trim().toLowerCase();
  final riderQuery    = ref.watch(deliveryRiderQueryProvider).trim().toLowerCase();
  final paymentFilter = ref.watch(deliveryPaymentFilterProvider);
  final sortBy        = ref.watch(deliverySortByProvider);

  // Status filter is now applied server-side; only secondary filters remain here.
  var result = orders;

  if (orderIdQuery.isNotEmpty) {
    result = result.where((o) => o.id.toLowerCase().contains(orderIdQuery)).toList();
  }
  if (riderQuery.isNotEmpty) {
    result = result
        .where((o) => (o.riderName ?? '').toLowerCase().contains(riderQuery))
        .toList();
  }

  result = switch (paymentFilter) {
    DeliveryPaymentFilter.all     => result,
    DeliveryPaymentFilter.cod     => result.where((o) => o.isCOD).toList(),
    DeliveryPaymentFilter.prepaid => result.where((o) => !o.isCOD).toList(),
  };

  final sorted = [...result];
  DateTime placedOrEpoch(DeliveryOrder o) =>
      o.placedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
  int statusPriority(DeliveryStatus s) => switch (s) {
        DeliveryStatus.pending        => 0,
        DeliveryStatus.outForDelivery => 1,
        DeliveryStatus.rejected       => 2,
        DeliveryStatus.cancelled      => 3,
        DeliveryStatus.delivered      => 4,
      };
  switch (sortBy) {
    case DeliverySortBy.none:
      sorted.sort((a, b) {
        final pa = statusPriority(a.status);
        final pb = statusPriority(b.status);
        if (pa != pb) return pa.compareTo(pb);
        return placedOrEpoch(b).compareTo(placedOrEpoch(a));
      });
      break;
    case DeliverySortBy.deliveryTimeNewest:
      sorted.sort((a, b) => placedOrEpoch(b).compareTo(placedOrEpoch(a)));
      break;
    case DeliverySortBy.deliveryTimeOldest:
      sorted.sort((a, b) => placedOrEpoch(a).compareTo(placedOrEpoch(b)));
      break;
    case DeliverySortBy.amountHighToLow:
      sorted.sort((a, b) => b.total.compareTo(a.total));
      break;
    case DeliverySortBy.amountLowToHigh:
      sorted.sort((a, b) => a.total.compareTo(b.total));
      break;
  }
  return sorted;
});

final deliveryCountsProvider = Provider((ref) {
  final orders = ref.watch(allOrdersForCountsProvider);
  return (
    all:            orders.length,
    pending:        orders.where((o) => o.status == DeliveryStatus.pending).length,
    outForDelivery: orders.where((o) => o.status == DeliveryStatus.outForDelivery).length,
    delivered:      orders.where((o) => o.status == DeliveryStatus.delivered).length,
    rejected:       orders.where((o) => o.status == DeliveryStatus.rejected).length,
    cancelled:      orders.where((o) => o.status == DeliveryStatus.cancelled).length,
  );
});

// ── Order detail ──────────────────────────────────────────────────────────────

final orderDetailProvider =
    FutureProvider.autoDispose.family<DeliveryOrder, String>((ref, orderId) async {
  final service = ref.read(_deliveriesServiceProvider);
  return service.getDetail(orderId);
});
