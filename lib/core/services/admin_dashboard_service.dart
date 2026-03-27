import '../api/admin_api_client.dart';
import '../api/api_paths.dart';
import '../models/dashboard_stats.dart';

class AdminDashboardService {
  const AdminDashboardService(this._client);
  final AdminApiClient _client;

  Future<DashboardStats> getStats({String? date}) async {
    final data = await _client.get(
      ApiPaths.dashboardStats,
      queryParameters: date != null ? {'date': date} : null,
    );
    return DashboardStats.fromJson(data);
  }
}
