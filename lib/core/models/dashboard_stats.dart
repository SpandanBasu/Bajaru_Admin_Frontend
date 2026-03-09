enum DeliveryPhase {
  orderAccumulation,
  procurement,
  packing,
  dispatch,
}

extension DeliveryPhaseLabel on DeliveryPhase {
  String get label {
    switch (this) {
      case DeliveryPhase.orderAccumulation: return 'ORDER ACCUMULATION';
      case DeliveryPhase.procurement:       return 'PROCUREMENT';
      case DeliveryPhase.packing:           return 'PACKING';
      case DeliveryPhase.dispatch:          return 'DISPATCH';
    }
  }
}

class DashboardStats {
  final int totalOrders;
  final double totalRevenue;
  final int pendingItems;
  final int availableRiders;
  final DeliveryPhase phase;
  final int procurementItemCount;
  final List<CompletedDelivery> completedDeliveries;

  const DashboardStats({
    required this.totalOrders,
    required this.totalRevenue,
    required this.pendingItems,
    required this.availableRiders,
    required this.phase,
    required this.procurementItemCount,
    required this.completedDeliveries,
  });

  factory DashboardStats.empty() => const DashboardStats(
        totalOrders: 0, totalRevenue: 0, pendingItems: 0,
        availableRiders: 0, phase: DeliveryPhase.orderAccumulation,
        procurementItemCount: 0, completedDeliveries: [],
      );

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    final phase = _parsePhase(json['currentPhase'] as String? ?? 'dispatch');
    final rawDeliveries = json['recentDeliveries'] as List? ?? [];
    return DashboardStats(
      totalOrders: (json['totalOrders'] as num?)?.toInt() ?? 0,
      totalRevenue: (json['totalRevenue'] as num?)?.toDouble() ?? 0,
      pendingItems: (json['pendingItems'] as num?)?.toInt() ?? 0,
      availableRiders: (json['availableRiders'] as num?)?.toInt() ?? 0,
      phase: phase,
      procurementItemCount: 0,
      completedDeliveries: rawDeliveries
          .cast<Map<String, dynamic>>()
          .map(CompletedDelivery.fromJson)
          .toList(),
    );
  }

  static DeliveryPhase _parsePhase(String raw) => switch (raw) {
        'orderAccumulation' => DeliveryPhase.orderAccumulation,
        'procurement'       => DeliveryPhase.procurement,
        'packing'           => DeliveryPhase.packing,
        _                   => DeliveryPhase.dispatch,
      };
}

class CompletedDelivery {
  final String orderId;
  final String customerName;
  final String address;
  final double amount;
  final DateTime completedAt;

  CompletedDelivery({
    required this.orderId,
    required this.customerName,
    required this.address,
    required this.amount,
    required this.completedAt,
  });

  factory CompletedDelivery.fromJson(Map<String, dynamic> json) {
    return CompletedDelivery(
      orderId: json['orderId'] as String? ?? '',
      customerName: json['customerName'] as String? ?? '',
      address: json['address'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : DateTime.now(),
    );
  }
}
