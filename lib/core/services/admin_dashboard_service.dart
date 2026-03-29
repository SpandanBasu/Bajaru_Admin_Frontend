import '../api/admin_api_client.dart';
import '../api/api_paths.dart';
import '../models/dashboard_stats.dart';

class AdminDashboardService {
  const AdminDashboardService(this._client);
  final AdminApiClient _client;

  Future<DashboardStats> getStats({String? date, String? warehouseId}) async {
    final data = await _client.get(
      ApiPaths.dashboardStats,
      queryParameters: {
        if (date != null) 'date': date,
        if (warehouseId != null && warehouseId.isNotEmpty) 'warehouseId': warehouseId,
      },
    );
    return DashboardStats.fromJson(data);
  }
}
