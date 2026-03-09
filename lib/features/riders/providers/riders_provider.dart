import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import '../../../core/api/admin_api_client.dart';
import '../../../core/models/delivery_order.dart';
import '../../../core/models/rider.dart';
import '../../../core/models/route_batch.dart';
import '../../../core/services/admin_riders_service.dart';

// ── Service provider ──────────────────────────────────────────────────────────

final _ridersServiceProvider = Provider<AdminRidersService>(
    (ref) => AdminRidersService(ref.watch(adminApiClientProvider)));

final ridersErrorProvider = StateProvider<String?>((_) => null);
final routeBatchesErrorProvider = StateProvider<String?>((_) => null);

// ── Riders notifier ───────────────────────────────────────────────────────────

class RidersNotifier extends StateNotifier<List<Rider>> {
  RidersNotifier(this._service, this._setError) : super([]) {
    refresh();
  }

  final AdminRidersService _service;
  final void Function(String?) _setError;

  Future<void> refresh() async {
    try {
      state = await _service.getRiders();
      _setError(null);
    } catch (e) {
      _setError('Failed to load riders');
      if (kDebugMode) {
        debugPrint('[RidersNotifier] refresh failed: $e');
      }
    }
  }

  void toggleOnline(String id) async {
    final rider = state.firstWhere(
        (r) => r.id == id,
        orElse: () => Rider(id: id, name: ''));
    final newOnline = !rider.isOnline;

    // Optimistic
    state = [
      for (final r in state)
        if (r.id == id) r.copyWith(isOnline: newOnline) else r,
    ];

    try {
      final updated = await _service.setOnlineStatus(id, online: newOnline);
      state = [
        for (final r in state)
          if (r.id == id) updated else r,
      ];
    } catch (_) {
      // Revert on error
      state = [
        for (final r in state)
          if (r.id == id) r.copyWith(isOnline: !newOnline) else r,
      ];
    }
  }
}

final ridersProvider =
    StateNotifierProvider<RidersNotifier, List<Rider>>(
  (ref) => RidersNotifier(
    ref.read(_ridersServiceProvider),
    (msg) => ref.read(ridersErrorProvider.notifier).state = msg,
  ),
);

final onlineRidersProvider = Provider((ref) {
  return ref.watch(ridersProvider).where((r) => r.isOnline).toList();
});

// ── Route Batches notifier ────────────────────────────────────────────────────

class RouteBatchesNotifier extends StateNotifier<List<RouteBatch>> {
  RouteBatchesNotifier(this._service, this._setError) : super([]) {
    refresh();
  }

  final AdminRidersService _service;
  final void Function(String?) _setError;

  Future<void> refresh() async {
    try {
      state = await _service.getRouteBatches();
      _setError(null);
    } catch (e) {
      _setError('Failed to load route batches');
      if (kDebugMode) {
        debugPrint('[RouteBatchesNotifier] refresh failed: $e');
      }
    }
  }

  void assignRider(String batchId, Rider rider) async {
    // Optimistic
    state = [
      for (final b in state)
        if (b.id == batchId)
          b.copyWith(status: RouteBatchStatus.assigned, assignedRider: rider)
        else
          b,
    ];
    try {
      final updated = await _service.assignRider(batchId, rider.id);
      state = [
        for (final b in state)
          if (b.id == batchId) updated else b,
      ];
    } catch (_) {}
  }

  void unassign(String batchId) async {
    state = [
      for (final b in state)
        if (b.id == batchId)
          RouteBatch(
            id: b.id,
            name: b.name,
            orderCount: b.orderCount,
            estimatedHours: b.estimatedHours,
            status: RouteBatchStatus.unassigned,
            completedDeliveries: b.completedDeliveries,
          )
        else
          b,
    ];
    try {
      final updated = await _service.unassignRider(batchId);
      state = [
        for (final b in state)
          if (b.id == batchId) updated else b,
      ];
    } catch (_) {}
  }
}

final routeBatchesProvider =
    StateNotifierProvider<RouteBatchesNotifier, List<RouteBatch>>(
  (ref) => RouteBatchesNotifier(
    ref.read(_ridersServiceProvider),
    (msg) => ref.read(routeBatchesErrorProvider.notifier).state = msg,
  ),
);

final activeDeliveriesProvider = FutureProvider<List<DeliveryOrder>>((ref) async {
  return ref.read(_ridersServiceProvider).getActiveDeliveries();
});

// ── Shift timer (local UI state only) ────────────────────────────────────────

final shiftElapsedSecondsProvider = StateProvider<int>((_) => 0);

// ── Rider Batch (orders grouped by rider) ─────────────────────────────────────

class RiderBatch {
  final Rider rider;
  final List<DeliveryOrder> orders;

  /// True when [rider] came from [ridersProvider] (API) and carries
  /// authoritative [Rider.deliveredToday] / [Rider.totalAssigned] totals.
  final bool isApiRider;

  const RiderBatch({
    required this.rider,
    required this.orders,
    this.isApiRider = false,
  });

  /// Unique pincodes covered by this rider's active orders, sorted.
  List<String> get pincodes => orders
      .map((o) => o.pincodeCode)
      .where((p) => p.isNotEmpty)
      .toSet()
      .toList()
    ..sort();

  // ── Live counts from active order list (outForDelivery only) ──────────────

  int get outForDelivery =>
      orders.where((o) => o.status == DeliveryStatus.outForDelivery).length;

  int get pending =>
      orders.where((o) => o.status == DeliveryStatus.pending).length;

  // ── All-day totals ─────────────────────────────────────────────────────────
  // activeDeliveriesProvider only fetches outForDelivery orders, so delivered
  // orders are absent from [orders]. Use the API rider's persisted counters
  // (deliveredToday / totalAssigned) whenever the rider is known to the API.

  /// Total deliveries completed today (all-day, not just current batch).
  int get effectiveDelivered =>
      isApiRider ? rider.deliveredToday : 0;

  /// Total orders assigned to this rider today (delivered + still active).
  int get effectiveTotalAssigned =>
      isApiRider ? rider.totalAssigned : orders.length;

  bool get isCompleted =>
      effectiveTotalAssigned > 0 &&
      effectiveDelivered >= effectiveTotalAssigned;

  bool get isActive => outForDelivery > 0;

  double get progressFraction => effectiveTotalAssigned == 0
      ? 0.0
      : effectiveDelivered / effectiveTotalAssigned;

  /// Average delivery time in minutes across delivered orders in current batch.
  int? get avgDeliveryMinutes {
    final mins = orders
        .where((o) => o.deliveryMinutes != null)
        .map((o) => o.deliveryMinutes!)
        .toList();
    if (mins.isEmpty) return null;
    return (mins.reduce((a, b) => a + b) / mins.length).round();
  }
}

/// Pincode filter for the Riders screen.
final ridersSelectedPincodeProvider = StateProvider<String?>((ref) => null);

/// Orders from [activeDeliveriesProvider] grouped by rider, filtered by pincode.
final riderBatchesProvider = Provider<List<RiderBatch>>((ref) {
  final ordersAsync = ref.watch(activeDeliveriesProvider);
  final allOrders = ordersAsync.asData?.value ?? const <DeliveryOrder>[];
  final apiRiders = ref.watch(ridersProvider);
  final selectedPincode = ref.watch(ridersSelectedPincodeProvider);

  final orders = selectedPincode == null
      ? allOrders
      : allOrders.where((o) => o.pincodeCode == selectedPincode).toList();

  // Group by a stable key: uid:userId → name:riderName
  final Map<String, List<DeliveryOrder>> grouped = {};
  for (final order in orders) {
    final rId = (order.riderId ?? '').trim();
    final rName = (order.riderName ?? '').trim();
    if (rId.isEmpty && rName.isEmpty) continue;
    final key =
        rId.isNotEmpty ? 'uid:$rId' : 'name:${rName.toLowerCase()}';
    grouped.putIfAbsent(key, () => []).add(order);
  }

  // Build lookup maps from API riders for merging
  final byUserId = {
    for (final r in apiRiders)
      if ((r.userId ?? '').isNotEmpty) r.userId!: r,
  };
  final byName = {
    for (final r in apiRiders) r.name.trim().toLowerCase(): r,
  };

  final batches = grouped.entries.map((entry) {
    final key = entry.key;
    final batchOrders = entry.value;
    final firstOrder = batchOrders.first;

    final apiRider = key.startsWith('uid:')
        ? byUserId[key.substring(4)]
        : byName[key.substring(5)];

    final rider = apiRider ??
        Rider(
          id: key,
          userId: (firstOrder.riderId ?? '').isNotEmpty
              ? firstOrder.riderId
              : null,
          name: firstOrder.riderName ?? '',
          isOnline: true,
        );

    return RiderBatch(rider: rider, orders: batchOrders, isApiRider: apiRider != null);
  }).toList();

  // Sort: active on-route first, then pending, then completed
  batches.sort((a, b) {
    int priority(RiderBatch b) =>
        b.isCompleted ? 2 : (b.isActive ? 0 : 1);
    return priority(a).compareTo(priority(b));
  });

  return batches;
});
