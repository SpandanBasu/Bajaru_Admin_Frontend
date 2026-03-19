// Customer Support data models
import 'package:intl/intl.dart';

enum SupportOrderStatus { pending, confirmed, delivered, cancelled }

enum TransactionType { credit, debit, refund }

enum TransactionStatus { success, failed, pending }

// ─── Customer Summary (search result row) ─────────────────────────────────────

class CustomerSummary {
  final String id;
  final String name;
  final String phone;
  final int totalOrders;

  const CustomerSummary({
    required this.id,
    required this.name,
    required this.phone,
    required this.totalOrders,
  });

  factory CustomerSummary.fromJson(Map<String, dynamic> json) =>
      CustomerSummary(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        phone: _formatPhone(
            json['phone'] as String? ?? json['phoneNumber'] as String? ?? ''),
        totalOrders: (json['totalOrders'] as num?)?.toInt() ?? 0,
      );

  /// Converts +91XXXXXXXXXX → XXXXX XXXXX for display.
  static String _formatPhone(String raw) {
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    final n10 = digits.length >= 10
        ? digits.substring(digits.length - 10)
        : digits;
    return n10.length == 10
        ? '${n10.substring(0, 5)} ${n10.substring(5)}'
        : raw;
  }
}

// ─── Saved Address ────────────────────────────────────────────────────────────

class SavedAddress {
  final bool isHome;
  final String address;

  const SavedAddress({required this.isHome, required this.address});

  factory SavedAddress.fromJson(Map<String, dynamic> json) {
    final type = (json['addressType'] as String? ??
            json['type'] as String? ??
            json['label'] as String? ??
            'HOME')
        .toUpperCase();
    // Backend AdminAddressDto sends: label, address (complete string), isDefault
    final addressStr = json['address'] as String?;
    final address = addressStr != null && addressStr.isNotEmpty
        ? addressStr
        : _build(json);
    return SavedAddress(
      isHome: type == 'HOME',
      address: address,
    );
  }

  static String _build(Map<String, dynamic> j) {
    final parts = [
      j['houseNumber'] as String?,
      j['floor'] as String?,
      j['landmark'] as String?,
      j['gpsAddress'] as String?,
      if (j['pincode'] != null) j['pincode'] as String?,
    ].whereType<String>().where((s) => s.isNotEmpty);
    return parts.isEmpty ? (j['completeAddress'] as String? ?? '') : parts.join(', ');
  }
}

// ─── Order item ───────────────────────────────────────────────────────────────

class SupportOrderItem {
  final String name;
  final String price;

  const SupportOrderItem({required this.name, required this.price});

  factory SupportOrderItem.fromJson(Map<String, dynamic> json) {
    final unit = (json['unitWeight'] as String? ?? '').trim();
    final displayName = unit.isNotEmpty
        ? '${json['name'] as String? ?? ''} ($unit)'
        : json['name'] as String? ?? '';
    return SupportOrderItem(
      name: displayName,
      price: '₹${(json['price'] as num?)?.toInt() ?? 0}',
    );
  }
}

// ─── Support Order ────────────────────────────────────────────────────────────

class SupportOrder {
  final String orderId;
  final String date;
  final String total;
  final SupportOrderStatus status;
  final List<SupportOrderItem> items;
  final String? deliverySlot;
  final String? expectedDelivery;
  final String? refundAmount;
  final String? refundDestination;
  final String? refundDate;
  /** Payment type from backend, e.g. "COD", "PHONE_PE", "WALLET" */
  final String? paymentMethod;

  const SupportOrder({
    required this.orderId,
    required this.date,
    required this.total,
    required this.status,
    required this.items,
    this.deliverySlot,
    this.expectedDelivery,
    this.refundAmount,
    this.refundDestination,
    this.refundDate,
    this.paymentMethod,
  });

  /// Compact display format matching Deliveries page: #ofb5 (last 4 chars) or raw if ≤4.
  String get orderIdDisplay {
    final raw = orderId.replaceAll('#', '').trim();
    if (raw.isEmpty) return orderId;
    if (raw.length <= 4) return raw;
    return '#${raw.substring(raw.length - 4)}';
  }

  /// True if this order was COD and therefore needs no refund when cancelled.
  bool get isCodNoRefund =>
      status == SupportOrderStatus.cancelled &&
      (paymentMethod?.toUpperCase() == 'COD');

  factory SupportOrder.fromJson(Map<String, dynamic> json) {
    final statusStr =
        (json['status'] as String? ?? 'CONFIRMED').toUpperCase();
    final status = switch (statusStr) {
      'PENDING' => SupportOrderStatus.pending,
      'CONFIRMED' => SupportOrderStatus.confirmed,
      'DELIVERED' => SupportOrderStatus.delivered,
      'CANCELLED' || 'CANCELED' => SupportOrderStatus.cancelled,
      _ => SupportOrderStatus.confirmed,
    };

    final placedAt = json['placedAt'] != null
        ? DateTime.parse(json['placedAt'] as String).toLocal()
        : DateTime.now();

    final rawItems = json['items'] as List? ?? [];
    final items = rawItems
        .cast<Map<String, dynamic>>()
        .map(SupportOrderItem.fromJson)
        .toList();

    final totalAmt = (json['finalTotal'] as num?)?.toInt() ??
        (json['total'] as num?)?.toInt() ??
        0;

    String? expectedDelivery;
    if (json['expectedDelivery'] != null) {
      try {
        final d = DateTime.parse(json['expectedDelivery'] as String).toLocal();
        expectedDelivery = DateFormat('d MMM yyyy').format(d);
      } catch (_) {}
    }

    return SupportOrder(
      orderId: '#${(json['orderId'] as String? ?? json['id'] as String? ?? '').toString().replaceAll('#', '')}',
      date: DateFormat('d MMM yyyy, h:mm a').format(placedAt),
      total: '₹$totalAmt',
      status: status,
      items: items,
      deliverySlot: json['deliverySlot'] as String?,
      expectedDelivery: expectedDelivery,
      refundAmount: json['refundAmount'] != null
          ? '₹${(json['refundAmount'] as num).toInt()}'
          : null,
      refundDestination:
          json['refundDestination'] as String? ?? json['refundDest'] as String?,
      refundDate: json['refundDate'] as String? ?? json['processedOn'] as String?,
      paymentMethod: json['paymentMethod'] as String?,
    );
  }
}

// ─── Transaction ──────────────────────────────────────────────────────────────

class Transaction {
  final String date;
  final String txnId;
  final TransactionType type;
  final String source;
  final String amount;
  final TransactionStatus status;

  const Transaction({
    required this.date,
    required this.txnId,
    required this.type,
    required this.source,
    required this.amount,
    required this.status,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    final typeStr =
        (json['type'] as String? ?? 'CREDIT').toUpperCase();
    final type = switch (typeStr) {
      'CREDIT' => TransactionType.credit,
      'DEBIT' => TransactionType.debit,
      'REFUND' => TransactionType.refund,
      _ => TransactionType.credit,
    };

    final statusStr =
        (json['status'] as String? ?? 'SUCCESS').toUpperCase();
    final txnStatus = switch (statusStr) {
      'SUCCESS' => TransactionStatus.success,
      'FAILED' || 'FAILURE' => TransactionStatus.failed,
      _ => TransactionStatus.pending,
    };

    final createdAt = json['createdAt'] != null
        ? DateTime.parse(json['createdAt'] as String).toLocal()
        : DateTime.now();

    return Transaction(
      date: DateFormat('d MMM').format(createdAt),
      txnId: json['id'] as String? ?? json['txnId'] as String? ?? '',
      type: type,
      source: json['paymentMethod'] as String? ??
          json['source'] as String? ??
          '',
      amount: '₹${(json['amount'] as num?)?.toInt() ?? 0}',
      status: txnStatus,
    );
  }
}

// ─── Customer Detail (full profile) ──────────────────────────────────────────

class CustomerDetail {
  final String id;
  final String name;
  final String phone;
  final String email;
  final String memberSince;
  final int totalOrders;
  final String walletBalance;
  final List<SavedAddress> addresses;
  final List<SupportOrder> orderHistory;
  final bool hasMoreOrders;
  final List<Transaction> transactions;

  const CustomerDetail({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    required this.memberSince,
    required this.totalOrders,
    required this.walletBalance,
    required this.addresses,
    required this.orderHistory,
    this.hasMoreOrders = false,
    required this.transactions,
  });

  factory CustomerDetail.fromJson(Map<String, dynamic> json) {
    final phone = json['phone'] as String? ??
        json['phoneNumber'] as String? ??
        '';

    final addresses = (json['addresses'] as List? ?? json['savedAddresses'] as List? ?? [])
        .cast<Map<String, dynamic>>()
        .map(SavedAddress.fromJson)
        .toList();

    final orders =
        (json['orderHistory'] as List? ?? json['orders'] as List? ?? [])
            .cast<Map<String, dynamic>>()
            .map(SupportOrder.fromJson)
            .toList();

    final txns = (json['transactions'] as List? ?? [])
        .cast<Map<String, dynamic>>()
        .map(Transaction.fromJson)
        .toList();

    final balance = json['walletBalance'];
    final walletBalance =
        balance != null ? '₹${(balance as num).toInt()}' : '₹0';

    return CustomerDetail(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      phone: CustomerSummary._formatPhone(phone),
      email: json['email'] as String? ?? '',
      memberSince: _formatDate(json['createdAt'] as String?),
      totalOrders: (json['totalOrders'] as num?)?.toInt() ?? orders.length,
      walletBalance: walletBalance,
      addresses: addresses,
      orderHistory: orders,
      hasMoreOrders: json['hasMoreOrders'] as bool? ?? false,
      transactions: txns,
    );
  }

  static String _formatDate(String? iso) {
    if (iso == null || iso.isEmpty) return '';
    try {
      return DateFormat('d MMM yyyy').format(DateTime.parse(iso).toLocal());
    } catch (_) {
      return iso;
    }
  }
}
