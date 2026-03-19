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
  /// Display type: "kg" | "g" | "pcs" | "pkt" | "L"
  final String unit;
  /// Full pack size e.g. "500g", "1 kg", "1 bunch" — for "X x unitWeight" display
  final String unitWeight;
  final int orderCount;
  final double inStock;       // raw: kg for weight items, count for pcs
  final double neededToday;   // raw: kg for weight items, count for pcs
  final String warehouseId;   // which warehouse
  final ProcurementStatus status;
  final bool isChecked;

  const ProcurementItem({
    required this.id,
    required this.name,
    required this.unit,
    required this.unitWeight,
    required this.orderCount,
    required this.inStock,
    required this.neededToday,
    required this.warehouseId,
    required this.status,
    this.isChecked = false,
  });

  /// How much still needs to be bought = neededToday − inStock (min 0)
  double get toProcure => (neededToday - inStock).clamp(0.0, double.infinity);

  /// Format raw quantity for display: "72 kg", "0.25 kg", "8 pcs"
  String formatQuantity(double qty) {
    String qtyStr;
    if (qty % 1 == 0) {
      qtyStr = qty.toInt().toString();
    } else {
      // Use up to 2 decimal places, trimming trailing zeros (e.g. 0.25 → "0.25", 0.50 → "0.5")
      qtyStr = qty.toStringAsFixed(2).replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
    }
    return '$qtyStr $unit';
  }

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
      unitWeight: json['unitWeight'] as String? ?? '1 unit',
      orderCount: (json['orderCount'] as num?)?.toInt() ?? 0,
      inStock: (json['inStock'] as num?)?.toDouble() ?? 0,
      neededToday: (json['neededToday'] as num?)?.toDouble() ?? 0,
      warehouseId: json['warehouseId'] as String? ?? '',
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
      unitWeight:   unitWeight,
      orderCount:   orderCount,
      inStock:      inStock,
      neededToday:  neededToday,
      warehouseId:  warehouseId,
      status:       status    ?? this.status,
      isChecked:    isChecked ?? this.isChecked,
    );
  }
}
