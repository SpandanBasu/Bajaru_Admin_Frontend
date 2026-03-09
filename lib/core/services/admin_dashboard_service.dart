import '../api/admin_api_client.dart';
import '../api/admin_api_endpoints.dart';
import '../models/dashboard_stats.dart';

class AdminDashboardService {
  const AdminDashboardService(this._client);
  final AdminApiClient _client;

  Future<DashboardStats> getStats({String? date}) async {
    final data = await _client.get(
      AdminApiEndpoints.dashboardStats,
      queryParameters: date != null ? {'date': date} : null,
    );
    return DashboardStats.fromJson(data);
  }
}
