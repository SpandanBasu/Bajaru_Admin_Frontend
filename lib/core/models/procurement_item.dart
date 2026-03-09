enum ProcurementStatus { done, pending, urgent }

extension ProcurementStatusLabel on ProcurementStatus {
  String get label {
    switch (this) {
      case ProcurementStatus.done:    return 'Done';
      case ProcurementStatus.pending: return 'Pending';
      case ProcurementStatus.urgent:  return 'Urgent';
    }
  }
}

class ProcurementItem {
  final String id;
  final String name;
  final String unit;          // e.g. "kg", "bun"
  final int orderCount;
  final double inStock;       // currently in godown
  final double neededToday;   // total required by orders
  final String pincodeCode;   // which godown/zone
  final ProcurementStatus status;
  final bool isChecked;

  const ProcurementItem({
    required this.id,
    required this.name,
    required this.unit,
    required this.orderCount,
    required this.inStock,
    required this.neededToday,
    required this.pincodeCode,
    required this.status,
    this.isChecked = false,
  });

  /// How much still needs to be bought = neededToday − inStock (min 0)
  double get toProcure => (neededToday - inStock).clamp(0.0, double.infinity);

  factory ProcurementItem.fromJson(Map<String, dynamic> json) {
    final statusStr = json['status'] as String? ?? 'PENDING';
    final status = switch (statusStr) {
      'DONE'   => ProcurementStatus.done,
      'URGENT' => ProcurementStatus.urgent,
      _        => ProcurementStatus.pending,
    };
    return ProcurementItem(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      unit: json['unit'] as String? ?? 'unit',
      orderCount: (json['orderCount'] as num?)?.toInt() ?? 0,
      inStock: (json['inStock'] as num?)?.toDouble() ?? 0,
      neededToday: (json['neededToday'] as num?)?.toDouble() ?? 0,
      pincodeCode: json['pincode'] as String? ?? '',
      status: status,
    );
  }

  ProcurementItem copyWith({
    ProcurementStatus? status,
    bool? isChecked,
  }) {
    return ProcurementItem(
      id:           id,
      name:         name,
      unit:         unit,
      orderCount:   orderCount,
      inStock:      inStock,
      neededToday:  neededToday,
      pincodeCode:  pincodeCode,
      status:       status    ?? this.status,
      isChecked:    isChecked ?? this.isChecked,
    );
  }
}
