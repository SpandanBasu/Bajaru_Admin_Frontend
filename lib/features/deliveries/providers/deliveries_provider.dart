import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/admin_api_client.dart';
import '../../../core/models/delivery_order.dart';
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

final deliverySelectedPincodeProvider = StateProvider<String?>((ref) => null);
final deliveryOrderIdQueryProvider = StateProvider<String>((ref) => '');
final deliveryRiderQueryProvider = StateProvider<String>((ref) => '');
final deliveryPaymentFilterProvider =
    StateProvider<DeliveryPaymentFilter>((ref) => DeliveryPaymentFilter.all);
final deliverySortByProvider =
    StateProvider<DeliverySortBy>((ref) => DeliverySortBy.none);

// ── Deliveries notifier ───────────────────────────────────────────────────────

class DeliveriesNotifier extends StateNotifier<List<DeliveryOrder>> {
  DeliveriesNotifier(this._service) : super([]) {
    refresh();
  }

  final AdminDeliveriesService _service;

  Future<void> refresh({String? pincode}) async {
    try {
      state = await _service.getDeliveries(pincode: pincode);
    } catch (_) {}
  }
}

final deliveriesProvider =
    StateNotifierProvider<DeliveriesNotifier, List<DeliveryOrder>>((ref) {
  final notifier =
      DeliveriesNotifier(ref.read(_deliveriesServiceProvider));
  ref.listen<String?>(deliverySelectedPincodeProvider, (_, pincode) {
    notifier.refresh(pincode: pincode);
  });
  return notifier;
});

// ── Derived providers (same public API for UI — no changes needed) ─────────────

final _allDeliveriesProvider =
    Provider<List<DeliveryOrder>>((ref) => ref.watch(deliveriesProvider));

final filteredDeliveriesProvider = Provider<List<DeliveryOrder>>((ref) {
  final orders = ref.watch(_allDeliveriesProvider);
  final filter = ref.watch(deliveryFilterProvider);
  final pincode = ref.watch(deliverySelectedPincodeProvider);
  final orderIdQuery = ref.watch(deliveryOrderIdQueryProvider).trim().toLowerCase();
  final riderQuery = ref.watch(deliveryRiderQueryProvider).trim().toLowerCase();
  final paymentFilter = ref.watch(deliveryPaymentFilterProvider);
  final sortBy = ref.watch(deliverySortByProvider);

  var result = pincode == null
      ? orders
      : orders.where((o) => o.pincodeCode == pincode).toList();

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
    DeliveryPaymentFilter.all => result,
    DeliveryPaymentFilter.cod => result.where((o) => o.isCOD).toList(),
    DeliveryPaymentFilter.prepaid => result.where((o) => !o.isCOD).toList(),
  };

  final sorted = [...result];
  DateTime placedOrEpoch(DeliveryOrder o) =>
      o.placedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
  int statusPriority(DeliveryStatus s) => switch (s) {
        DeliveryStatus.pending        => 0,
        DeliveryStatus.outForDelivery => 1,
        DeliveryStatus.rejected      => 2,
        DeliveryStatus.delivered     => 3,
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

// ── Order detail (fetches full data: address, items) ──────────────────────────

final orderDetailProvider =
    FutureProvider.family<DeliveryOrder, String>((ref, orderId) async {
  final service = ref.read(_deliveriesServiceProvider);
  return service.getDetail(orderId);
});
