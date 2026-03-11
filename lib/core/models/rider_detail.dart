/// Detail data for the rider details screen.
/// Fetched from GET /api/admin/riders/{riderId}/details.
class RiderDetail {
  final DateTime? shiftStartedAt;

  // ── Activity ──────────────────────────────────────────────────────────────
  final int assigned;
  final int delivered;
  final int rejected;
  final int cancelled;

  // ── Cash (COD only) ───────────────────────────────────────────────────────
  final double codTotal;
  final int codOrderCount;
  final double codCollectedCash;
  final int codCollectedCashCount;
  final double codCollectedUpi;
  final int codCollectedUpiCount;

  // ── Earnings ──────────────────────────────────────────────────────────────
  final double earningsDelivery;
  final double earningsWait;
  final double earningsTotal;
  final int earningsDeliveryCount;

  const RiderDetail({
    this.shiftStartedAt,
    required this.assigned,
    required this.delivered,
    required this.rejected,
    required this.cancelled,
    required this.codTotal,
    required this.codOrderCount,
    required this.codCollectedCash,
    required this.codCollectedCashCount,
    required this.codCollectedUpi,
    required this.codCollectedUpiCount,
    required this.earningsDelivery,
    required this.earningsWait,
    required this.earningsTotal,
    required this.earningsDeliveryCount,
  });

  factory RiderDetail.fromJson(Map<String, dynamic> json) => RiderDetail(
        shiftStartedAt: json['shiftStartedAt'] != null
            ? DateTime.parse(json['shiftStartedAt'] as String).toLocal()
            : null,
        assigned: (json['assigned'] as num?)?.toInt() ?? 0,
        delivered: (json['delivered'] as num?)?.toInt() ?? 0,
        rejected: (json['rejected'] as num?)?.toInt() ?? 0,
        cancelled: (json['cancelled'] as num?)?.toInt() ?? 0,
        codTotal: (json['codTotal'] as num?)?.toDouble() ?? 0.0,
        codOrderCount: (json['codOrderCount'] as num?)?.toInt() ?? 0,
        codCollectedCash: (json['codCollectedCash'] as num?)?.toDouble() ?? 0.0,
        codCollectedCashCount: (json['codCollectedCashCount'] as num?)?.toInt() ?? 0,
        codCollectedUpi: (json['codCollectedUpi'] as num?)?.toDouble() ?? 0.0,
        codCollectedUpiCount: (json['codCollectedUpiCount'] as num?)?.toInt() ?? 0,
        earningsDelivery: (json['earningsDelivery'] as num?)?.toDouble() ?? 0.0,
        earningsWait: (json['earningsWait'] as num?)?.toDouble() ?? 0.0,
        earningsTotal: (json['earningsTotal'] as num?)?.toDouble() ?? 0.0,
        earningsDeliveryCount: (json['earningsDeliveryCount'] as num?)?.toInt() ?? 0,
      );

  double get totalCollected => codCollectedCash + codCollectedUpi;
  double get codPending => codTotal - totalCollected;
}
