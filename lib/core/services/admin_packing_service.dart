import '../api/admin_api_client.dart';
import '../api/admin_api_endpoints.dart';
import '../models/batch_order.dart';

class AdminPackingService {
  const AdminPackingService(this._client);
  final AdminApiClient _client;

  Future<List<BatchOrder>> getPackingOrders({String? pincode}) async {
    final list = await _client.getList(
      AdminApiEndpoints.packingOrders,
      queryParameters: pincode != null ? {'pincode': pincode} : null,
    );
    return list
        .cast<Map<String, dynamic>>()
        .map(BatchOrder.fromJson)
        .toList();
  }

  Future<BatchOrder> updateStatus(String orderId, String status) async {
    final data = await _client.patch(
      AdminApiEndpoints.packingOrderStatus(orderId),
      {'status': status},
    );
    return BatchOrder.fromJson(data);
  }

  Future<BatchOrder> toggleItem(String orderId, String itemId) async {
    final data = await _client.patch(
      AdminApiEndpoints.packingToggleItem(orderId, itemId),
    );
    return BatchOrder.fromJson(data);
  }

  Future<BatchOrder> markIssue(String orderId, String message) async {
    final data = await _client.patch(
      AdminApiEndpoints.packingIssue(orderId),
      {'issueMessage': message},
    );
    return BatchOrder.fromJson(data);
  }
}
