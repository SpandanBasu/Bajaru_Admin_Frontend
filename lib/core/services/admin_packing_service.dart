import '../api/admin_api_client.dart';
import '../api/api_paths.dart';
import '../models/batch_order.dart';

class AdminPackingService {
  const AdminPackingService(this._client);
  final AdminApiClient _client;

  Future<PackingPageResult> getPackingOrders({
    String? warehouseId,
    DateTime? deliveryDate,
    int page = 0,
    int size = 100,
  }) async {
    final params = <String, dynamic>{'page': page, 'size': size};
    if (warehouseId != null) params['warehouseId'] = warehouseId;
    if (deliveryDate != null) {
      params['deliveryDate'] =
          '${deliveryDate.year}-${deliveryDate.month.toString().padLeft(2, '0')}-${deliveryDate.day.toString().padLeft(2, '0')}';
    }
    final data = await _client.get(
      ApiPaths.packingOrders,
      queryParameters: params,
    );
    return PackingPageResult.fromJson(data);
  }

  Future<BatchOrder> updateStatus(String orderId, String status) async {
    final data = await _client.patch(
      ApiPaths.packingOrderStatus(orderId),
      {'status': status},
    );
    return BatchOrder.fromJson(data);
  }

  Future<BatchOrder> toggleItem(String orderId, String itemId) async {
    final data = await _client.patch(
      ApiPaths.packingToggleItem(orderId, itemId),
    );
    return BatchOrder.fromJson(data);
  }

  Future<List<VegetablePackGroup>> getVegetableView({
    String? warehouseId,
    DateTime? deliveryDate,
  }) async {
    final params = <String, dynamic>{};
    if (warehouseId != null) params['warehouseId'] = warehouseId;
    if (deliveryDate != null) {
      params['deliveryDate'] =
          '${deliveryDate.year}-${deliveryDate.month.toString().padLeft(2, '0')}-${deliveryDate.day.toString().padLeft(2, '0')}';
    }
    final data = await _client.getList(
      ApiPaths.packingVegetableView,
      queryParameters: params,
    );
    return data
        .cast<Map<String, dynamic>>()
        .map(VegetablePackGroup.fromJson)
        .toList();
  }

  Future<BatchOrder> markIssue(String orderId, String message) async {
    final data = await _client.patch(
      ApiPaths.packingIssue(orderId),
      {'issueMessage': message},
    );
    return BatchOrder.fromJson(data);
  }
}

class PackingPageResult {
  final List<BatchOrder> orders;
  final bool hasMore;
  final int page;

  const PackingPageResult({
    required this.orders,
    required this.hasMore,
    required this.page,
  });

  factory PackingPageResult.fromJson(Map<String, dynamic> json) {
    final rawContent = json['content'] as List? ?? [];
    return PackingPageResult(
      orders: rawContent
          .cast<Map<String, dynamic>>()
          .map(BatchOrder.fromJson)
          .toList(),
      hasMore: json['hasMore'] as bool? ?? false,
      page: json['page'] as int? ?? 0,
    );
  }
}
