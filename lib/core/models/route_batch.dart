import 'rider.dart';

enum RouteBatchStatus { assigned, unassigned }

class RouteBatch {
  final String id;
  final String name;
  final int orderCount;
  final double estimatedHours;
  final RouteBatchStatus status;
  final Rider? assignedRider;
  final int completedDeliveries; // out of orderCount

  const RouteBatch({
    required this.id,
    required this.name,
    required this.orderCount,
    required this.estimatedHours,
    required this.status,
    this.assignedRider,
    this.completedDeliveries = 0,
  });

  bool get isFullyComplete => completedDeliveries >= orderCount;

  factory RouteBatch.fromJson(Map<String, dynamic> json) {
    final riderId   = json['assignedRiderId'] as String?;
    final riderName = json['assignedRiderName'] as String?;
    Rider? assignedRider;
    if (riderId != null && riderName != null) {
      assignedRider = Rider(id: riderId, name: riderName);
    }
    return RouteBatch(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      orderCount: (json['orderCount'] as num?)?.toInt() ?? 0,
      estimatedHours: (json['estimatedHours'] as num?)?.toDouble() ?? 0,
      status: json['status'] == 'ASSIGNED'
          ? RouteBatchStatus.assigned
          : RouteBatchStatus.unassigned,
      assignedRider: assignedRider,
      completedDeliveries: (json['completedDeliveries'] as num?)?.toInt() ?? 0,
    );
  }

  RouteBatch copyWith({
    RouteBatchStatus? status,
    Rider? assignedRider,
    int? completedDeliveries,
  }) {
    return RouteBatch(
      id:                   id,
      name:                 name,
      orderCount:           orderCount,
      estimatedHours:       estimatedHours,
      status:               status               ?? this.status,
      assignedRider:        assignedRider        ?? this.assignedRider,
      completedDeliveries:  completedDeliveries  ?? this.completedDeliveries,
    );
  }
}
