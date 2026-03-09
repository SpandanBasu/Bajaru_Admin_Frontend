import '../api/admin_api_client.dart';
import '../api/admin_api_endpoints.dart';
import '../models/delivery_order.dart';

class AdminDeliveriesService {
  const AdminDeliveriesService(this._client);
  final AdminApiClient _client;

  Future<List<DeliveryOrder>> getDeliveries({
    String? status,
    String? pincode,
  }) async {
    final list = await _client.getList(
      AdminApiEndpoints.deliveries,
      queryParameters: {
        if (status != null) 'status': status,
        if (pincode != null) 'pincode': pincode,
      },
    );
    return list
        .cast<Map<String, dynamic>>()
        .map(DeliveryOrder.fromJson)
        .toList();
  }

  Future<DeliveryOrder> getDetail(String orderId) async {
    final data =
        await _client.get(AdminApiEndpoints.deliveryDetail(orderId));
    return DeliveryOrder.fromJson(data);
  }
}
