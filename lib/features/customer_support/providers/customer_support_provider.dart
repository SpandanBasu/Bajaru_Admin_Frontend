import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/admin_api_client.dart';
import '../../../core/models/cs_customer.dart';
import '../../../core/services/admin_customer_support_service.dart';

// ── Service provider ──────────────────────────────────────────────────────────

final _csServiceProvider = Provider<AdminCustomerSupportService>(
  (ref) => AdminCustomerSupportService(ref.watch(adminApiClientProvider)),
);

// ── Search ────────────────────────────────────────────────────────────────────

/// Raw text in the search field. Updated (debounced) by the screen widget.
final csSearchQueryProvider = StateProvider<String>((_) => '');

/// Live search results. Rebuilds whenever [csSearchQueryProvider] changes.
/// Returns empty list when query is blank; shows AsyncLoading while fetching.
final csSearchResultsProvider =
    FutureProvider<List<CustomerSummary>>((ref) async {
  final query = ref.watch(csSearchQueryProvider).trim();
  if (query.isEmpty) return [];
  return ref.read(_csServiceProvider).searchCustomers(query);
});

// ── Customer detail ───────────────────────────────────────────────────────────

/// Full customer profile fetched by user ID.
/// Uses FutureProvider.family so each customer ID gets its own cached future.
final csCustomerDetailProvider =
    FutureProvider.family<CustomerDetail, String>((ref, userId) async {
  return ref.read(_csServiceProvider).getCustomerDetail(userId);
});

/// Exposes the CS service so screens can call getCustomerOrders directly.
final csServiceProvider = Provider<AdminCustomerSupportService>(
  (ref) => AdminCustomerSupportService(ref.watch(adminApiClientProvider)),
);

// ── Refund action ─────────────────────────────────────────────────────────────

/// Tracks whether a refund submission is in progress (to disable the button).
final csRefundLoadingProvider = StateProvider<bool>((_) => false);

/// Call this to initiate a refund and invalidate the customer detail cache.
Future<void> submitRefund(
  Ref ref, {
  required String userId,
  required String orderId,
  required double amount,
  required String destination,
}) async {
  final service = ref.read(_csServiceProvider);
  await service.initiateRefund(
    userId: userId,
    orderId: orderId,
    amount: amount,
    destination: destination,
  );
  // Refresh customer detail so the new transaction appears immediately
  ref.invalidate(csCustomerDetailProvider(userId));
}
