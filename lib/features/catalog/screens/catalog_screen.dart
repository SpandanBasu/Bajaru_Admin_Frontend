import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/catalog_provider.dart';
import '../../../core/models/catalog_product.dart';
import '../../../core/models/warehouse.dart';
import '../../../core/providers/warehouse_provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../widgets/common/admin_app_bar.dart';
import '../../../widgets/common/admin_drawer.dart';
import '../../../widgets/catalog/catalog_product_tile.dart';
import '../../../widgets/catalog/catalog_edit_sheet.dart';

class CatalogScreen extends ConsumerWidget {
  const CatalogScreen({super.key});

  void _showWarehousePicker(BuildContext context, WidgetRef ref, Warehouse? selected) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Consumer(
        builder: (ctx, ref, _) {
          final warehousesAsync = ref.watch(catalogWarehousesProvider);
          return Padding(
            padding: const EdgeInsets.all(AppDimensions.base),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: AppDimensions.base),
                Text('Select Warehouse', style: AppTextStyles.h3),
                const SizedBox(height: AppDimensions.sm),
                warehousesAsync.when(
                  data: (warehouses) => warehouses.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.symmetric(vertical: AppDimensions.md),
                          child: Text(
                            'No warehouses found',
                            style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
                          ),
                        )
                      : Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            for (final w in warehouses)
                              ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryLight,
                                    borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                                  ),
                                  child: Icon(Icons.warehouse_rounded,
                                      color: AppColors.primary, size: 20),
                                ),
                                title: Text(w.displayName, style: AppTextStyles.bodyMedium),
                                subtitle: Text(
                                  '${w.city}  •  ${w.warehouseId}  •  ${w.servicePincodes.length} pincode${w.servicePincodes.length == 1 ? '' : 's'}',
                                  style: AppTextStyles.caption,
                                ),
                                trailing: selected?.warehouseId == w.warehouseId
                                    ? Icon(Icons.check_circle_rounded, color: AppColors.primary)
                                    : Icon(Icons.circle_outlined, color: AppColors.border),
                                onTap: () {
                                  ref.read(activeWarehouseProvider.notifier).select(w);
                                  Navigator.pop(context);
                                },
                              ),
                          ],
                        ),
                  loading: () => const Padding(
                    padding: EdgeInsets.symmetric(vertical: AppDimensions.md),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (_, __) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: AppDimensions.md),
                    child: Text(
                      'Failed to load warehouses',
                      style: AppTextStyles.body.copyWith(color: AppColors.error),
                    ),
                  ),
                ),
                const SizedBox(height: AppDimensions.sm),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showEditSheet(BuildContext context, WidgetRef ref, CatalogProduct product, Warehouse warehouse) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CatalogEditSheet(
        product: product,
        warehouse: warehouse,
        onSave: (newStock, newPrice, newMrp) {
          ref.read(catalogProvider.notifier)
              .updateStockAndPrice(product.id, warehouse.warehouseId, newStock, newPrice, newMrp)
              .catchError((_) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Failed to update stock and prices'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final products      = ref.watch(filteredCatalogProvider);
    final catalogState  = ref.watch(catalogProvider);
    final warehousesAsync = ref.watch(catalogWarehousesProvider);
    final category      = ref.watch(catalogCategoryProvider);
    final oosOnly       = ref.watch(catalogOutOfStockOnlyProvider);
    final warehouse     = ref.watch(activeWarehouseProvider);
    final notifier      = ref.read(catalogProvider.notifier);

    // Reload the catalog whenever the selected warehouse changes.
    ref.listen<Warehouse?>(activeWarehouseProvider, (previous, next) {
      if (next != null && next.warehouseId != previous?.warehouseId) {
        notifier.loadForWarehouse(next.warehouseId);
      }
    });

    // Auto-select first warehouse on first load.
    final availableWarehouses = warehousesAsync.asData?.value ?? const <Warehouse>[];
    if (warehouse == null && availableWarehouses.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (ref.read(activeWarehouseProvider) == null) {
          ref.read(activeWarehouseProvider.notifier).select(availableWarehouses.first);
        }
      });
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      drawer: const AdminDrawer(),
      appBar: AdminAppBar(
        title: 'Catalog',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            color: AppColors.primary,
            onPressed: (catalogState.isLoading || warehouse == null)
                ? null
                : () => notifier.loadForWarehouse(warehouse.warehouseId),
          ),
          IconButton(
            icon: const Icon(Icons.add_rounded),
            color: AppColors.primary,
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Warehouse selector ────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppDimensions.base,
              AppDimensions.md,
              AppDimensions.base,
              AppDimensions.xs,
            ),
            child: Text(
              'WAREHOUSE',
              style: AppTextStyles.label.copyWith(
                color: AppColors.textSecondary,
                letterSpacing: 1.0,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppDimensions.base,
              AppDimensions.xs,
              AppDimensions.base,
              AppDimensions.md,
            ),
            child: GestureDetector(
              onTap: () => _showWarehousePicker(context, ref, warehouse),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.md,
                  vertical: AppDimensions.md,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warehouse_rounded,
                        size: 16, color: AppColors.primary),
                    const SizedBox(width: AppDimensions.sm),
                    Expanded(
                      child: warehouse != null
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  warehouse.displayName,
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                Text(
                                  '${warehouse.city}  •  ${warehouse.warehouseId}',
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            )
                          : Text(
                              'Select Warehouse',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.textHint,
                              ),
                            ),
                    ),
                    Icon(Icons.keyboard_arrow_down_rounded,
                        color: AppColors.textSecondary),
                  ],
                ),
              ),
            ),
          ),

          // ── Pincode chips for selected warehouse ─────────────────────────
          if (warehouse != null && warehouse.servicePincodes.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppDimensions.base,
                0,
                AppDimensions.base,
                AppDimensions.md,
              ),
              child: Wrap(
                spacing: AppDimensions.xs,
                runSpacing: AppDimensions.xs,
                children: [
                  for (final pin in warehouse.servicePincodes)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppDimensions.sm,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.location_pin, size: 11, color: AppColors.primary),
                          const SizedBox(width: 3),
                          Text(
                            pin,
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),

          // ── Search bar ───────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppDimensions.base, 0,
              AppDimensions.base,
              AppDimensions.sm,
            ),
            child: TextField(
              onChanged: (v) =>
                  ref.read(catalogSearchProvider.notifier).state = v,
              decoration: InputDecoration(
                hintText: 'Search vegetables...',
                hintStyle: AppTextStyles.body.copyWith(color: AppColors.textHint),
                prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textHint),
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                  borderSide: BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                  borderSide: BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                  borderSide: BorderSide(color: AppColors.primary, width: 1.5),
                ),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),

          // ── Filter chips ─────────────────────────────────────────────────
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppDimensions.base),
            child: Row(
              children: [
                for (final cat in ProductCategory.values) ...[
                  _CatalogChip(
                    label: cat.label,
                    selected: category == cat && !oosOnly,
                    selectedBg: AppColors.primaryLight,
                    selectedBorder: AppColors.primary,
                    selectedLabel: AppColors.primary,
                    onTap: () {
                      ref.read(catalogCategoryProvider.notifier).state = cat;
                      ref.read(catalogOutOfStockOnlyProvider.notifier).state = false;
                    },
                  ),
                  const SizedBox(width: AppDimensions.sm),
                ],
                _CatalogChip(
                  label: 'Out of Stock',
                  selected: oosOnly,
                  selectedBg: AppColors.errorLight,
                  selectedBorder: AppColors.error,
                  selectedLabel: AppColors.error,
                  onTap: () => ref
                      .read(catalogOutOfStockOnlyProvider.notifier)
                      .state = !oosOnly,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppDimensions.sm),

          // ── Products list ─────────────────────────────────────────────────
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                await Future.wait([
                  if (warehouse != null)
                    notifier.loadForWarehouse(warehouse.warehouseId),
                  ref.refresh(catalogWarehousesProvider.future),
                ]);
              },
              color: AppColors.primary,
              child: catalogState.isLoading && catalogState.value == null
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: const [
                        SizedBox(height: 220),
                        Center(child: CircularProgressIndicator()),
                      ],
                    )
                  : catalogState.hasError && catalogState.value == null
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            SizedBox(
                              height: 220,
                              child: Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Failed to load catalog',
                                      style: AppTextStyles.body.copyWith(color: AppColors.error),
                                    ),
                                    const SizedBox(height: AppDimensions.sm),
                                    TextButton(
                                      onPressed: warehouse != null
                                          ? () => notifier.loadForWarehouse(warehouse.warehouseId)
                                          : null,
                                      child: const Text('Retry'),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        )
                      : products.isEmpty
                          ? ListView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              children: [
                                SizedBox(
                                  height: 220,
                                  child: Center(
                                    child: Text(
                                      warehouse == null
                                          ? 'Select a warehouse to view products'
                                          : 'No products found',
                                      style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : ListView.builder(
                              physics: const AlwaysScrollableScrollPhysics(),
                              itemCount: products.length,
                              itemBuilder: (_, i) {
                                final p = products[i];
                                final whData =
                                    warehouse != null ? p.dataFor(warehouse.warehouseId) : null;
                                return CatalogProductTile(
                                  product: p,
                                  warehouseData: whData,
                                  onToggleAvailability: (p.isOutOfStock || warehouse == null)
                                      ? null
                                      : () {
                                          notifier
                                              .toggleAvailability(p.id, warehouse.warehouseId)
                                              .catchError((_) {
                                            if (context.mounted) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(
                                                  content: Text('Failed to update availability'),
                                                  backgroundColor: Colors.red,
                                                ),
                                              );
                                            }
                                          });
                                        },
                                  onTap: warehouse != null
                                      ? () => _showEditSheet(context, ref, p, warehouse)
                                      : null,
                                );
                              },
                            ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CatalogChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color selectedBg;
  final Color selectedBorder;
  final Color selectedLabel;
  final VoidCallback onTap;

  const _CatalogChip({
    required this.label,
    required this.selected,
    required this.selectedBg,
    required this.selectedBorder,
    required this.selectedLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.md,
          vertical: AppDimensions.xs + 2,
        ),
        decoration: BoxDecoration(
          color: selected ? selectedBg : AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
          border: Border.all(
            color: selected ? selectedBorder : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.captionMedium.copyWith(
            color: selected ? selectedLabel : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
