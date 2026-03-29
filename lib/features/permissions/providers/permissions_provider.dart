import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/admin_api_client.dart';
import '../../../core/models/allowed_user.dart';
import '../../../core/services/admin_access_service.dart';

// ── Service provider ──────────────────────────────────────────────────────────

final _accessServiceProvider = Provider<AdminAccessService>((ref) {
  return AdminAccessService(ref.watch(adminApiClientProvider));
});

// ── Super admin check ─────────────────────────────────────────────────────────

/// Fetches whether the currently logged-in admin is a super admin.
/// Re-fetched on each session — result is cached for the life of the provider.
final isSuperAdminProvider = FutureProvider<bool>((ref) async {
  return ref.watch(_accessServiceProvider).checkIsSuperAdmin();
});

// ── Admins ────────────────────────────────────────────────────────────────────

class AllowedAdminsNotifier
    extends StateNotifier<AsyncValue<List<AllowedUserEntry>>> {
  AllowedAdminsNotifier(this._service) : super(const AsyncValue.loading()) {
    _load();
  }

  final AdminAccessService _service;

  Future<void> _load() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _service.listAdmins());
  }

  Future<void> refresh() => _load();

  /// Adds an entry optimistically and reverts on failure.
  Future<void> add(String phoneNumber, String name,
      {bool isSuperAdmin = false}) async {
    final entry = await _service.addAdmin(phoneNumber, name,
        isSuperAdmin: isSuperAdmin);
    state.whenData((list) {
      state = AsyncValue.data([...list, entry]);
    });
  }

  /// Removes an entry optimistically and reverts on failure.
  Future<void> remove(String phoneNumber) async {
    final prev = state;
    state.whenData((list) {
      state = AsyncValue.data(
        list.where((e) => e.phoneNumber != phoneNumber).toList(),
      );
    });
    try {
      await _service.removeAdmin(phoneNumber);
    } catch (_) {
      state = prev;
      rethrow;
    }
  }
}

final allowedAdminsProvider = StateNotifierProvider<AllowedAdminsNotifier,
    AsyncValue<List<AllowedUserEntry>>>((ref) {
  return AllowedAdminsNotifier(ref.watch(_accessServiceProvider));
});

// ── Riders ────────────────────────────────────────────────────────────────────

class AllowedRidersNotifier
    extends StateNotifier<AsyncValue<List<AllowedUserEntry>>> {
  AllowedRidersNotifier(this._service) : super(const AsyncValue.loading()) {
    _load();
  }

  final AdminAccessService _service;

  Future<void> _load() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _service.listRiders());
  }

  Future<void> refresh() => _load();

  Future<void> add(String phoneNumber, String name, String warehouseId) async {
    final entry = await _service.addRider(phoneNumber, name, warehouseId);
    state.whenData((list) {
      state = AsyncValue.data([...list, entry]);
    });
  }

  Future<void> remove(String phoneNumber) async {
    final prev = state;
    state.whenData((list) {
      state = AsyncValue.data(
        list.where((e) => e.phoneNumber != phoneNumber).toList(),
      );
    });
    try {
      await _service.removeRider(phoneNumber);
    } catch (_) {
      state = prev;
      rethrow;
    }
  }
}

final allowedRidersProvider = StateNotifierProvider<AllowedRidersNotifier,
    AsyncValue<List<AllowedUserEntry>>>((ref) {
  return AllowedRidersNotifier(ref.watch(_accessServiceProvider));
});
