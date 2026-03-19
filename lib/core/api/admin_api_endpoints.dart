/// All backend endpoint paths for the admin app.
class AdminApiEndpoints {
  AdminApiEndpoints._();

  // ── Dashboard ──────────────────────────────────────────────────────────
  static const String dashboardStats = '/api/admin/dashboard/stats';

  // ── Packing ────────────────────────────────────────────────────────────
  static const String packingOrders = '/api/admin/packing/orders';
  static String packingOrderStatus(String orderId) =>
      '/api/admin/packing/orders/$orderId/status';
  static String packingToggleItem(String orderId, String itemId) =>
      '/api/admin/packing/orders/$orderId/items/$itemId/toggle';
  static String packingNewBagToggle(String orderId) =>
      '/api/admin/packing/orders/$orderId/new-bag-toggle';
  static String packingIssue(String orderId) =>
      '/api/admin/packing/orders/$orderId/issue';

  // ── Procurement ────────────────────────────────────────────────────────
  static const String procurementItems = '/api/admin/procurement/items';

  // ── Riders ─────────────────────────────────────────────────────────────
  static const String riders = '/api/admin/riders';
  static String riderDetails(String riderId) =>
      '/api/admin/riders/$riderId/details';
  static String riderOnlineStatus(String riderId) =>
      '/api/admin/riders/$riderId/online-status';
  static const String routeBatches = '/api/admin/riders/route-batches';
  static String routeBatchAssign(String batchId) =>
      '/api/admin/riders/route-batches/$batchId/assign';

  // ── Deliveries ─────────────────────────────────────────────────────────
  static const String deliveries = '/api/admin/deliveries';
  static String deliveryDetail(String orderId) =>
      '/api/admin/deliveries/$orderId';

  // ── Catalog (inventory management) ────────────────────────────────────
  static const String serviceAreas = '/api/zone/service-areas';
  static const String adminWarehouses = '/api/admin/warehouses';
  static const String catalogProducts =
      '/api/admin/inventory-management/products';
  static String catalogProduct(String productId) =>
      '/api/admin/inventory-management/products/$productId';
  static String productInventory(String productId) =>
      '/api/admin/inventory-management/products/$productId/inventory';

  /// PATCH — toggle active flag for a product+warehouseId inventory entry.
  static String inventoryToggle(String productId, String warehouseId) =>
      '/api/admin/inventory-management/products/$productId/inventory/$warehouseId/active';

  // ── Customer Support ────────────────────────────────────────────────────────

  /// GET  — search by name, phone, or order ID: ?q={query}
  static const String csSearch = '/api/admin/customers/search';

  /// GET  — full customer profile (user + orders + wallet + transactions)
  static String csCustomer(String userId) => '/api/admin/customers/$userId';

  /// GET  — paginated order history for a customer: ?page=1&size=5
  static String csCustomerOrders(String userId) =>
      '/api/admin/customers/$userId/orders';

  /// GET  — paginated transaction ledger for a customer
  static String csCustomerTransactions(String userId) =>
      '/api/admin/customers/$userId/transactions';

  /// POST — initiate a manual refund for a customer
  static String csRefund(String userId) =>
      '/api/admin/customers/$userId/refund';
}
