import '../api/admin_api_client.dart';
import '../api/admin_api_endpoints.dart';
import '../models/delivery_order.dart';
import '../models/rider.dart';
import '../models/route_batch.dart';

class AdminRidersService {
  const AdminRidersService(this._client);
  final AdminApiClient _client;

  Future<List<Rider>> getRiders() async {
    final list = await _client.getList(AdminApiEndpoints.riders);
    return list.cast<Map<String, dynamic>>().map(Rider.fromJson).toList();
  }

  Future<Rider> setOnlineStatus(String riderId, {required bool online}) async {
    final data = await _client.patch(
      AdminApiEndpoints.riderOnlineStatus(riderId),
      {'online': online},
    );
    return Rider.fromJson(data);
  }

  Future<List<RouteBatch>> getRouteBatches() async {
    final list = await _client.getList(AdminApiEndpoints.routeBatches);
    return list
        .cast<Map<String, dynamic>>()
        .map(RouteBatch.fromJson)
        .toList();
  }

  Future<List<DeliveryOrder>> getActiveDeliveries() async {
    final list = await _client.getList(
      AdminApiEndpoints.deliveries,
      queryParameters: const {'status': 'outForDelivery'},
    );
    return list
        .cast<Map<String, dynamic>>()
        .map(DeliveryOrder.fromJson)
        .toList();
  }

  Future<RouteBatch> createRouteBatch({
    required String name,
    double? estimatedHours,
    List<String>? orderIds,
  }) async {
    final data = await _client.post(AdminApiEndpoints.routeBatches, {
      'name': name,
      if (estimatedHours != null) 'estimatedHours': estimatedHours,
      if (orderIds != null) 'orderIds': orderIds,
    });
    return RouteBatch.fromJson(data);
  }

  Future<RouteBatch> assignRider(String batchId, String riderId) async {
    final data = await _client.patch(
      AdminApiEndpoints.routeBatchAssign(batchId),
      {'riderId': riderId},
    );
    return RouteBatch.fromJson(data);
  }

  Future<RouteBatch> unassignRider(String batchId) async {
    final data = await _client.delete(
      AdminApiEndpoints.routeBatchAssign(batchId),
    );
    return RouteBatch.fromJson(data);
  }
}
