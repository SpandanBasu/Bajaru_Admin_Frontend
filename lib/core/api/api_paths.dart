/// Every backend path the admin app calls, in one place.
///
/// Paths start with `/` so Dio’s `baseUrl + path` works when
/// [ApiConfig.baseUrl] is e.g. `http://host:8080/api/v1` (no trailing slash).
abstract final class ApiPaths {
  ApiPaths._();

  // ── Auth (public; no JWT) ───────────────────────────────────────────────

  static const String sendOtp = '/auth/sms/otp';
  static const String verifyOtp = '/auth/sms/verify';
  static const String truecallerLogin = '/auth/truecaller';
  static const String refreshToken = '/auth/refresh';

  // ── Admin — dashboard ─────────────────────────────────────────────────────

  static const String dashboardStats = '/admin/dashboard/stats';

  // ── Admin — packing ───────────────────────────────────────────────────────

  static const String packingOrders = '/admin/packing/orders';
  static const String packingVegetableView = '/admin/packing/vegetable-view';
  static String packingOrderStatus(String orderId) =>
      '/admin/packing/orders/$orderId/status';
  static String packingToggleItem(String orderId, String itemId) =>
      '/admin/packing/orders/$orderId/items/$itemId/toggle';
  static String packingIssue(String orderId) =>
      '/admin/packing/orders/$orderId/issue';

  // ── Admin — procurement ───────────────────────────────────────────────────

  static const String procurementItems = '/admin/procurement/items';
  static String procurementItemStatus(String productId, String warehouseId) =>
      '/admin/procurement/items/$productId/$warehouseId/status';

  // ── Admin — riders ────────────────────────────────────────────────────────

  static const String riders = '/admin/riders';
  static String riderDetails(String riderId) =>
      '/admin/riders/$riderId/details';
  static String riderOnlineStatus(String riderId) =>
      '/admin/riders/$riderId/online-status';
  static const String routeBatches = '/admin/riders/route-batches';
  static String routeBatchAssign(String batchId) =>
      '/admin/riders/route-batches/$batchId/assign';

  // ── Admin — deliveries ────────────────────────────────────────────────────

  static const String deliveries = '/admin/deliveries';
  static String deliveryDetail(String orderId) =>
      '/admin/deliveries/$orderId';

  // ── Admin — catalog / zones ───────────────────────────────────────────────

  static const String serviceAreas = '/zones/service-areas';
  static const String adminWarehouses = '/admin/warehouses';

  // Product catalogue (MongoDB documents, via admin handler)
  static const String catalogProducts = '/admin/inventory/products';
  static String catalogProduct(String productId) =>
      '/admin/inventory/products/$productId';

  // Per-warehouse inventory (PostgreSQL, via inventory handler)
  static String productInventory(String productId) =>
      '/inventory/admin/$productId';
  /// Bulk fetch for catalog: one POST replaces N GET [productInventory] calls.
  static const String inventoryByProducts = '/inventory/admin/by-products';
  static const String inventoryUpsert = '/inventory/admin/upsert';
  static String inventoryToggle(String productId, String warehouseId) =>
      '/inventory/admin/$productId/$warehouseId/toggle';

  // ── Admin — access control ────────────────────────────────────────────────

  static const String accessCheckSuperAdmin = '/admin/access/check-super-admin';

  static const String accessAdmins = '/admin/access/admins';
  static String accessAdminsRemove(String phoneNumber) =>
      '/admin/access/admins/$phoneNumber';

  static const String accessRiders = '/admin/access/riders';
  static String accessRidersRemove(String phoneNumber) =>
      '/admin/access/riders/$phoneNumber';

  // ── Admin — customer support ──────────────────────────────────────────────

  static const String csSearch = '/admin/customers/search';
  static String csCustomer(String userId) => '/admin/customers/$userId';
  static String csCustomerOrders(String userId) =>
      '/admin/customers/$userId/orders';
  static String csCustomerTransactions(String userId) =>
      '/admin/customers/$userId/transactions';
  static String csRefund(String userId) =>
      '/admin/customers/$userId/refund';
}
