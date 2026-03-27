import 'package:flutter/foundation.dart';
import '../api/admin_api_client.dart';
import '../api/api_paths.dart';
import '../models/cs_customer.dart';

/// Service layer for all Customer Support API calls.
/// Falls back to local mock data when the backend endpoint is not yet live,
/// so the feature works end-to-end during development.
class AdminCustomerSupportService {
  const AdminCustomerSupportService(this._client);

  final AdminApiClient _client;

  // ── Search ────────────────────────────────────────────────────────────────

  /// Search customers by name, phone number, or order ID.
  Future<List<CustomerSummary>> searchCustomers(String query) async {
    try {
      final list = await _client.getList(
        ApiPaths.csSearch,
        queryParameters: {'q': query},
      );
      return list
          .cast<Map<String, dynamic>>()
          .map(CustomerSummary.fromJson)
          .toList();
    } catch (e) {
      debugPrint('[CS] searchCustomers failed ($e) — using mock fallback');
      return _mockSearch(query);
    }
  }

  // ── Profile ───────────────────────────────────────────────────────────────

  /// Fetch the full customer profile: basic info, orders, wallet & transactions.
  Future<CustomerDetail> getCustomerDetail(String userId) async {
    try {
      final data = await _client.get(ApiPaths.csCustomer(userId));
      return CustomerDetail.fromJson(data);
    } catch (e) {
      debugPrint('[CS] getCustomerDetail($userId) failed ($e) — using mock fallback');
      return _mockDetail(userId);
    }
  }

  // ── Paginated orders ──────────────────────────────────────────────────────

  /// Fetch a page of orders for a customer. page=1 is the second page (first 5 come in detail).
  Future<({List<SupportOrder> orders, bool hasMore})> getCustomerOrders(
      String userId, {
    int page = 1,
    int size = 100,
  }) async {
    try {
      final data = await _client.get(
        ApiPaths.csCustomerOrders(userId),
        queryParameters: {'page': page, 'size': size},
      );
      final rawItems = data['content'] as List? ?? [];
      final orders = rawItems
          .cast<Map<String, dynamic>>()
          .map(SupportOrder.fromJson)
          .toList();
      final hasMore = data['hasMore'] as bool? ?? false;
      return (orders: orders, hasMore: hasMore);
    } catch (e) {
      debugPrint('[CS] getCustomerOrders($userId, page=$page) failed ($e)');
      return (orders: <SupportOrder>[], hasMore: false);
    }
  }

  // ── Refund ────────────────────────────────────────────────────────────────

  /// Initiate a manual wallet or original-method refund.
  Future<void> initiateRefund({
    required String userId,
    required String orderId,
    required double amount,
    required String destination, // 'WALLET' | 'ORIGINAL'
  }) async {
    await _client.post(
      ApiPaths.csRefund(userId),
      {
        'orderId': orderId,
        'amount': amount,
        'destination': destination,
      },
    );
  }

  // ── Mock fallback data ────────────────────────────────────────────────────
  // Used when the backend CS endpoints are not yet deployed.
  // Remove once /api/admin/customers/* are live.

  static const _kMockSummaries = [
    CustomerSummary(
        id: 'usr-001',
        name: 'Amit Verma',
        phone: '98761 43210',
        totalOrders: 24),
    CustomerSummary(
        id: 'usr-002',
        name: 'Priya Sharma',
        phone: '87654 32109',
        totalOrders: 8),
    CustomerSummary(
        id: 'usr-003',
        name: 'Ravi Kumar',
        phone: '99887 76543',
        totalOrders: 3),
  ];

  List<CustomerSummary> _mockSearch(String query) {
    final q = query.toLowerCase().replaceAll(' ', '').replaceAll('#', '');
    // Try last 4 digits of order ID first
    if (q.length == 4) {
      for (final detail in _kMockDetails) {
        final match = detail.orderHistory.any((o) {
          final raw = o.orderId.replaceAll('#', '').toLowerCase();
          return raw.length >= 4 && raw.endsWith(q);
        });
        if (match) {
          final summary = _kMockSummaries
              .where((s) => s.id == detail.id)
              .toList();
          if (summary.isNotEmpty) return summary;
        }
      }
    }
    return _kMockSummaries.where((c) {
      return c.name.toLowerCase().contains(query.toLowerCase()) ||
          c.phone.replaceAll(' ', '').contains(q) ||
          c.id.contains(q);
    }).toList();
  }

  CustomerDetail _mockDetail(String userId) {
    return _kMockDetails.firstWhere(
      (d) => d.id == userId,
      orElse: () => _kMockDetails.first,
    );
  }

  static const _kMockDetails = [
    CustomerDetail(
      id: 'usr-001',
      name: 'Amit Verma',
      phone: '98761 43210',
      email: 'amit.verma@email.com',
      memberSince: '12 Jan 2024',
      totalOrders: 24,
      walletBalance: '₹350',
      addresses: [
        SavedAddress(isHome: true, address: '42, 2nd Cross, BTM Layout, 560001'),
        SavedAddress(isHome: false, address: '15, MG Road, Indiranagar, 560038'),
      ],
      orderHistory: [
        SupportOrder(
          orderId: '#ORD-1042',
          date: '8 Mar 2026, 10:30 AM',
          total: '₹780',
          status: SupportOrderStatus.pending,
          items: [
            SupportOrderItem(name: 'Tomatoes (2 kg)', price: '₹80'),
            SupportOrderItem(name: 'Onions (1 kg)', price: '₹40'),
            SupportOrderItem(name: 'Potatoes (3 kg)', price: '₹90'),
            SupportOrderItem(name: 'Capsicum (500 g)', price: '₹45'),
          ],
          deliverySlot: '9:00 - 10:00 AM',
          expectedDelivery: '9 Mar 2026',
        ),
        SupportOrder(
          orderId: '#ORD-1038',
          date: '5 Mar 2026, 2:15 PM',
          total: '₹450',
          status: SupportOrderStatus.confirmed,
          items: [],
        ),
        SupportOrder(
          orderId: '#ORD-1029',
          date: '28 Feb 2026, 6:00 PM',
          total: '₹320',
          status: SupportOrderStatus.cancelled,
          items: [
            SupportOrderItem(name: 'Broccoli (500 g)', price: '₹60'),
            SupportOrderItem(name: 'Spinach (1 bunch)', price: '₹30'),
            SupportOrderItem(name: 'Mushrooms (250 g)', price: '₹90'),
            SupportOrderItem(name: 'Carrots (1 kg)', price: '₹40'),
          ],
          deliverySlot: '5:00 - 6:00 PM',
          refundAmount: '₹320',
          refundDestination: 'Bajaru Wallet',
          refundDate: '1 Mar 2026',
        ),
        SupportOrder(
          orderId: '#ORD-1015',
          date: '20 Feb 2026, 11:00 AM',
          total: '₹560',
          status: SupportOrderStatus.delivered,
          items: [],
        ),
      ],
      transactions: [
        Transaction(
            date: '8 Mar',
            txnId: 'TXN-4821',
            type: TransactionType.credit,
            source: 'Online',
            amount: '₹780',
            status: TransactionStatus.success),
        Transaction(
            date: '5 Mar',
            txnId: 'TXN-4799',
            type: TransactionType.debit,
            source: 'COD',
            amount: '₹450',
            status: TransactionStatus.success),
        Transaction(
            date: '1 Mar',
            txnId: 'TXN-4756',
            type: TransactionType.credit,
            source: 'Wallet',
            amount: '₹50',
            status: TransactionStatus.success),
        Transaction(
            date: '28 Feb',
            txnId: 'TXN-4710',
            type: TransactionType.refund,
            source: 'Wallet',
            amount: '₹320',
            status: TransactionStatus.success),
        Transaction(
            date: '20 Feb',
            txnId: 'TXN-4688',
            type: TransactionType.credit,
            source: 'Online',
            amount: '₹560',
            status: TransactionStatus.failed),
      ],
    ),
    CustomerDetail(
      id: 'usr-002',
      name: 'Priya Sharma',
      phone: '87654 32109',
      email: 'priya.sharma@email.com',
      memberSince: '3 Mar 2025',
      totalOrders: 8,
      walletBalance: '₹120',
      addresses: [
        SavedAddress(isHome: true, address: '7, Park Street, Kolkata, 700001'),
      ],
      orderHistory: [],
      transactions: [],
    ),
    CustomerDetail(
      id: 'usr-003',
      name: 'Ravi Kumar',
      phone: '99887 76543',
      email: 'ravi.kumar@email.com',
      memberSince: '1 Feb 2026',
      totalOrders: 3,
      walletBalance: '₹50',
      addresses: [
        SavedAddress(isHome: true, address: '22, Civil Lines, Delhi, 110001'),
      ],
      orderHistory: [],
      transactions: [],
    ),
  ];
}
