import '../api/admin_api_client.dart';
import '../api/admin_api_endpoints.dart';
import '../models/delivery_order.dart';

class AdminDeliveriesService {
  const AdminDeliveriesService(this._client);
  final AdminApiClient _client;

  Future<DeliveryPageResult> getDeliveries({
    String? status,
    String? warehouseId,
    DateTime? deliveryDate,
    int page = 0,
    int size = 50,
  }) async {
    final date = deliveryDate ?? DateTime.now();
    final dateStr =
        '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
    final data = await _client.get(
      AdminApiEndpoints.deliveries,
      queryParameters: {
        if (status != null) 'status': status,
        if (warehouseId != null) 'warehouseId': warehouseId,
        'deliveryDate': dateStr,
        'page': page,
        'size': size,
      },
    );
    return DeliveryPageResult.fromJson(data);
  }

  Future<DeliveryOrder> getDetail(String orderId) async {
    final data =
        await _client.get(AdminApiEndpoints.deliveryDetail(orderId));
    return DeliveryOrder.fromJson(data);
  }
}

class DeliveryPageResult {
  final List<DeliveryOrder> orders;
  final bool hasMore;
  final int page;

  const DeliveryPageResult({
    required this.orders,
    required this.hasMore,
    required this.page,
  });

  factory DeliveryPageResult.fromJson(Map<String, dynamic> json) {
    final rawContent = json['content'] as List? ?? [];
    return DeliveryPageResult(
      orders: rawContent
          .cast<Map<String, dynamic>>()
          .map(DeliveryOrder.fromJson)
          .toList(),
      hasMore: json['hasMore'] as bool? ?? false,
      page: json['page'] as int? ?? 0,
    );
  }
}
