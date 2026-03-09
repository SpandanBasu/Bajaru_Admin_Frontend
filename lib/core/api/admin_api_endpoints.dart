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
  static String packingIssue(String orderId) =>
      '/api/admin/packing/orders/$orderId/issue';

  // ── Procurement ────────────────────────────────────────────────────────
  static const String procurementItems = '/api/admin/procurement/items';

  // ── Riders ─────────────────────────────────────────────────────────────
  static const String riders = '/api/admin/riders';
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
  static const String catalogProducts =
      '/api/admin/inventory-management/products';
  static String catalogProduct(String productId) =>
      '/api/admin/inventory-management/products/$productId';
  static String productInventory(String productId) =>
      '/api/admin/inventory-management/products/$productId/inventory';
}
