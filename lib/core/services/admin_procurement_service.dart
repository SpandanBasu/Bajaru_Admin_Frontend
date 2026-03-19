import '../api/admin_api_client.dart';
import '../api/admin_api_endpoints.dart';
import '../models/procurement_item.dart';

class AdminProcurementService {
  const AdminProcurementService(this._client);
  final AdminApiClient _client;

  /// Returns [ProcurementSummaryResult] — items list plus aggregated totals.
  Future<ProcurementSummaryResult> getItems({
    String? warehouseId,
    DateTime? deliveryDate,
  }) async {
    final params = <String, dynamic>{};
    if (warehouseId != null) params['warehouseId'] = warehouseId;
    if (deliveryDate != null) {
      params['deliveryDate'] =
          '${deliveryDate.year.toString().padLeft(4, '0')}-'
          '${deliveryDate.month.toString().padLeft(2, '0')}-'
          '${deliveryDate.day.toString().padLeft(2, '0')}';
    }
    final data = await _client.get(
      AdminApiEndpoints.procurementItems,
      queryParameters: params.isEmpty ? null : params,
    );
    return ProcurementSummaryResult.fromJson(data);
  }
}

class ProcurementSummaryResult {
  final double totalInStock;
  final double totalNeeded;
  final double totalToProcure;
  final int itemCount;
  final int orderCount;
  final List<ProcurementItem> items;

  const ProcurementSummaryResult({
    required this.totalInStock,
    required this.totalNeeded,
    required this.totalToProcure,
    required this.itemCount,
    required this.orderCount,
    required this.items,
  });

  factory ProcurementSummaryResult.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List? ?? [];
    return ProcurementSummaryResult(
      totalInStock: (json['totalInStock'] as num?)?.toDouble() ?? 0,
      totalNeeded: (json['totalNeeded'] as num?)?.toDouble() ?? 0,
      totalToProcure: (json['totalToProcure'] as num?)?.toDouble() ?? 0,
      itemCount: json['itemCount'] as int? ?? 0,
      orderCount: json['orderCount'] as int? ?? 0,
      items: rawItems
          .cast<Map<String, dynamic>>()
          .map(ProcurementItem.fromJson)
          .toList(),
    );
  }
}
