import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/admin_api_client.dart';
import '../../../core/models/dashboard_stats.dart';
import '../../../core/models/warehouse.dart';
import '../../../core/providers/warehouse_provider.dart';
import '../../../core/services/admin_dashboard_service.dart';

// ── Service provider ──────────────────────────────────────────────────────────

final _dashboardServiceProvider = Provider<AdminDashboardService>(
    (ref) => AdminDashboardService(ref.watch(adminApiClientProvider)));

// ── Selected date (defaults to today) ────────────────────────────────────────

final dashboardSelectedDateProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
});

// ── Live stats notifier ───────────────────────────────────────────────────────

class DashboardNotifier extends StateNotifier<DashboardStats> {
  DashboardNotifier(this._service) : super(DashboardStats.empty());

  final AdminDashboardService _service;

  Future<void> refreshForDate(DateTime date, {String? warehouseId}) async {
    try {
      final dateStr =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      state = await _service.getStats(date: dateStr, warehouseId: warehouseId);
    } catch (_) {
      // Keep previous state on error — app stays usable with stale data.
    }
  }

  void advancePhase() {
    final phases = DeliveryPhase.values;
    final next   = phases[(state.phase.index + 1) % phases.length];
    state = DashboardStats(
      totalOrders: state.totalOrders,
      totalRevenue: state.totalRevenue,
      pendingItems: state.pendingItems,
      availableRiders: state.availableRiders,
      phase: next,
      procurementItemCount: state.procurementItemCount,
      completedDeliveries: state.completedDeliveries,
    );
  }
}

final dashboardProvider =
    StateNotifierProvider<DashboardNotifier, DashboardStats>((ref) {
  final notifier = DashboardNotifier(ref.read(_dashboardServiceProvider));

  void _reload() {
    final date      = ref.read(dashboardSelectedDateProvider);
    final warehouse = ref.read(activeWarehouseProvider);
    notifier.refreshForDate(date, warehouseId: warehouse?.warehouseId);
  }

  ref.listen<DateTime>(dashboardSelectedDateProvider, (_, __) => _reload());
  ref.listen<Warehouse?>(activeWarehouseProvider,     (_, __) => _reload());
  _reload(); // initial load
  return notifier;
});

// ── Unified stats — live data for all dates ───────────────────────────────────

final dashboardStatsProvider = Provider<DashboardStats>((ref) {
  return ref.watch(dashboardProvider);
});
