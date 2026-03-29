import 'package:flutter/foundation.dart';
import '../api/admin_api_client.dart';
import '../api/api_paths.dart';
import '../models/allowed_user.dart';

/// Service for the app-access whitelist endpoints.
/// Manages which phones can log in to the Admin and Rider apps.
class AdminAccessService {
  const AdminAccessService(this._client);

  final AdminApiClient _client;

  // ── Admins ────────────────────────────────────────────────────────────────

  Future<List<AllowedUserEntry>> listAdmins() async {
    final list = await _client.getList(ApiPaths.accessAdmins);
    return list
        .cast<Map<String, dynamic>>()
        .map(AllowedUserEntry.fromJson)
        .toList();
  }

  /// Returns whether the currently logged-in admin is a super admin.
  Future<bool> checkIsSuperAdmin() async {
    final data = await _client.get(ApiPaths.accessCheckSuperAdmin);
    return data['isSuperAdmin'] as bool? ?? false;
  }

  Future<AllowedUserEntry> addAdmin(
    String phoneNumber,
    String name, {
    bool isSuperAdmin = false,
  }) async {
    final data = await _client.post(
      ApiPaths.accessAdmins,
      {'phoneNumber': phoneNumber, 'name': name, 'isSuperAdmin': isSuperAdmin},
    );
    return AllowedUserEntry.fromJson(data);
  }

  Future<void> removeAdmin(String phoneNumber) async {
    try {
      await _client.delete(ApiPaths.accessAdminsRemove(phoneNumber));
    } catch (e) {
      debugPrint('[Access] removeAdmin($phoneNumber) failed: $e');
      rethrow;
    }
  }

  // ── Riders ────────────────────────────────────────────────────────────────

  Future<List<AllowedUserEntry>> listRiders() async {
    final list = await _client.getList(ApiPaths.accessRiders);
    return list
        .cast<Map<String, dynamic>>()
        .map(AllowedUserEntry.fromJson)
        .toList();
  }

  Future<AllowedUserEntry> addRider(
      String phoneNumber, String name, String warehouseId) async {
    final data = await _client.post(
      ApiPaths.accessRiders,
      {'phoneNumber': phoneNumber, 'name': name, 'warehouseId': warehouseId},
    );
    return AllowedUserEntry.fromJson(data);
  }

  Future<void> removeRider(String phoneNumber) async {
    try {
      await _client.delete(ApiPaths.accessRidersRemove(phoneNumber));
    } catch (e) {
      debugPrint('[Access] removeRider($phoneNumber) failed: $e');
      rethrow;
    }
  }
}
