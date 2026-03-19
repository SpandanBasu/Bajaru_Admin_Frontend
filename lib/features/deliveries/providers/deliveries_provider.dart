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

enum DeliveryFilterStatus { all, pending, outForDelivery, delivered, rejected }
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

class DeliveriesNotifier extends StateNotifier<DeliveriesState> {
  DeliveriesNotifier(this._service) : super(const DeliveriesState()) {
    refresh();
  }

  final AdminDeliveriesService _service;
  String? _warehouseId;
  DateTime? _deliveryDate;

  Future<void> refresh({String? warehouseId, DateTime? deliveryDate}) async {
    _warehouseId = warehouseId;
    _deliveryDate = deliveryDate;
    try {
      final result = await _service.getDeliveries(
        warehouseId: warehouseId,
        deliveryDate: deliveryDate,
        page: 0,
      );
      state = DeliveriesState(
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
      final result = await _service.getDeliveries(
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
}

final deliveriesProvider =
    StateNotifierProvider<DeliveriesNotifier, DeliveriesState>((ref) {
  final notifier = DeliveriesNotifier(ref.read(_deliveriesServiceProvider));

  void _reload() {
    final warehouse = ref.read(activeWarehouseProvider);
    final date      = ref.read(deliverySelectedDateProvider);
    notifier.refresh(warehouseId: warehouse?.warehouseId, deliveryDate: date);
  }

  ref.listen<Warehouse?>(activeWarehouseProvider, (_, __) => _reload());
  ref.listen<DateTime?>(deliverySelectedDateProvider, (_, __) => _reload());
  return notifier;
});

// ── Derived providers ─────────────────────────────────────────────────────────

final _allDeliveriesProvider =
    Provider<List<DeliveryOrder>>((ref) => ref.watch(deliveriesProvider).orders);

final filteredDeliveriesProvider = Provider<List<DeliveryOrder>>((ref) {
  final orders        = ref.watch(_allDeliveriesProvider);
  final filter        = ref.watch(deliveryFilterProvider);
  final orderIdQuery  = ref.watch(deliveryOrderIdQueryProvider).trim().toLowerCase();
  final riderQuery    = ref.watch(deliveryRiderQueryProvider).trim().toLowerCase();
  final paymentFilter = ref.watch(deliveryPaymentFilterProvider);
  final sortBy        = ref.watch(deliverySortByProvider);

  var result = orders;

  result = switch (filter) {
    DeliveryFilterStatus.all            => result,
    DeliveryFilterStatus.pending        => result.where((o) => o.status == DeliveryStatus.pending).toList(),
    DeliveryFilterStatus.outForDelivery => result.where((o) => o.status == DeliveryStatus.outForDelivery).toList(),
    DeliveryFilterStatus.delivered      => result.where((o) => o.status == DeliveryStatus.delivered).toList(),
    DeliveryFilterStatus.rejected       => result.where((o) => o.status == DeliveryStatus.rejected).toList(),
  };

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
        DeliveryStatus.delivered      => 3,
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
  final orders = ref.watch(_allDeliveriesProvider);
  return (
    all:            orders.length,
    pending:        orders.where((o) => o.status == DeliveryStatus.pending).length,
    outForDelivery: orders.where((o) => o.status == DeliveryStatus.outForDelivery).length,
    delivered:      orders.where((o) => o.status == DeliveryStatus.delivered).length,
    rejected:       orders.where((o) => o.status == DeliveryStatus.rejected).length,
  );
});

// ── Order detail ──────────────────────────────────────────────────────────────

final orderDetailProvider =
    FutureProvider.family<DeliveryOrder, String>((ref, orderId) async {
  final service = ref.read(_deliveriesServiceProvider);
  return service.getDetail(orderId);
});
