import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/procurement_provider.dart';
import '../../../core/providers/warehouse_provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/models/procurement_item.dart';
import '../../../core/models/warehouse.dart';
import '../../../widgets/procurement/procurement_item_tile.dart';
import '../../../widgets/common/admin_drawer.dart';

class ProcurementScreen extends ConsumerWidget {
  const ProcurementScreen({super.key});

  Future<void> _showDateFilterSheet(
      BuildContext context, WidgetRef ref, DateTime current) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 1),
      helpText: 'Filter by Delivery Date',
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: ColorScheme.light(
            primary: AppColors.primary,
            onPrimary: Colors.white,
            surface: AppColors.surface,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      ref.read(procurementSelectedDateProvider.notifier).state = DateTime(
        picked.year,
        picked.month,
        picked.day,
      );
    }
  }

  void _showWarehousePicker(
    BuildContext context,
    WidgetRef ref,
    Warehouse? selected,
    AsyncValue<List<Warehouse>> warehousesAsync,
  ) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(AppDimensions.base),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
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
              data: (warehouses) => Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final w in warehouses)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        width: 40, height: 40,
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
                child: Text('Failed to load warehouses',
                    style: AppTextStyles.body.copyWith(color: AppColors.error)),
              ),
            ),
            const SizedBox(height: AppDimensions.sm),
          ],
        ),
      ),
    );
  }

  void _showDownloadSheet(BuildContext context, List<ProcurementItem> items,
      DateTime selectedDate, Warehouse? selectedWarehouse) {
    final dateLabel =
        DateFormat('EEEE, d MMMM yyyy').format(selectedDate);
    final warehouseLabel = selectedWarehouse != null
        ? '🏭 ${selectedWarehouse.displayName} (${selectedWarehouse.warehouseId})\n'
        : '';
    final lines = '📦 Procurement — $dateLabel\n'
        '$warehouseLabel\n'
        '${items.map((item) => '${item.name}: ${item.formatQuantity(item.neededToday)}').join('\n')}';

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _DownloadSheet(content: lines),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items             = ref.watch(filteredProcurementProvider);
    final summary           = ref.watch(procurementSummaryProvider);
    final chipCounts        = ref.watch(procurementChipCountsProvider);
    final statusFilter      = ref.watch(procurementStatusFilterProvider);
    final selectionType     = ref.watch(procurementSelectionTypeProvider);
    final selectedWarehouse = ref.watch(activeWarehouseProvider);
    final selectedDate      = ref.watch(procurementSelectedDateProvider);
    final warehousesAsync   = ref.watch(catalogWarehousesProvider);
    final notifier          = ref.read(procurementProvider.notifier);

    // Fallback: auto-select first warehouse if global state is still null
    // (e.g., warehouses finished loading before activeWarehouseProvider was created).
    final availableWarehouses = warehousesAsync.asData?.value ?? const <Warehouse>[];
    if (selectedWarehouse == null && availableWarehouses.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (ref.read(activeWarehouseProvider) == null) {
          ref.read(activeWarehouseProvider.notifier).select(availableWarehouses.first);
        }
      });
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      drawer: const AdminDrawer(),
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 1,
        shadowColor: Colors.black12,
        titleSpacing: AppDimensions.base,
        toolbarHeight: 68,
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu_rounded),
            color: AppColors.textSecondary,
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Procurement', style: AppTextStyles.h2),
            Text(
              DateFormat('EEEE, d MMMM y').format(selectedDate),
              style: AppTextStyles.caption
                  .copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today_rounded),
            color: AppColors.primary,
            tooltip: 'Delivery date',
            onPressed: () => _showDateFilterSheet(context, ref, selectedDate),
          ),
          IconButton(
            icon: const Icon(Icons.download_rounded),
            color: AppColors.textSecondary,
            tooltip: 'Download list',
            onPressed: () => _showDownloadSheet(context, items, selectedDate, selectedWarehouse),
          ),
          const SizedBox(width: AppDimensions.xs),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Warehouse selector ────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppDimensions.base,
              AppDimensions.md,
              AppDimensions.base,
              AppDimensions.sm,
            ),
            child: GestureDetector(
              onTap: () => _showWarehousePicker(context, ref, selectedWarehouse, warehousesAsync),
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
                    Icon(Icons.warehouse_rounded, size: 16, color: AppColors.primary),
                    const SizedBox(width: AppDimensions.sm),
                    Expanded(
                      child: selectedWarehouse != null
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  selectedWarehouse.displayName,
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                Text(
                                  '${selectedWarehouse.city}  •  ${selectedWarehouse.warehouseId}',
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
          const SizedBox(height: AppDimensions.md),

          // ── Active delivery date chip (X resets to today) ─────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppDimensions.base, 0, AppDimensions.base, AppDimensions.sm),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.sm, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius:
                        BorderRadius.circular(AppDimensions.radiusFull),
                    border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.event_rounded,
                          size: 13, color: AppColors.primary),
                      const SizedBox(width: 4),
                      Text(
                        DateFormat('d MMM yyyy').format(selectedDate),
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: () {
                          final n = DateTime.now();
                          ref.read(procurementSelectedDateProvider.notifier).state =
                              DateTime(n.year, n.month, n.day);
                        },
                        child: Icon(Icons.close_rounded,
                            size: 13, color: AppColors.primary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Stats card ────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.base),
            child: _StatsCard(summary: summary),
          ),
          const SizedBox(height: AppDimensions.md),

          // ── Status filter chips ───────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppDimensions.base),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _StatusChip(
                    label: 'All (${chipCounts.all})',
                    selected: statusFilter == ProcurementStatusFilter.all,
                    color: AppColors.primary,
                    onTap: () => ref
                        .read(procurementStatusFilterProvider.notifier)
                        .state = ProcurementStatusFilter.all,
                  ),
                  const SizedBox(width: AppDimensions.sm),
                  _StatusChip(
                    label: 'Pending (${chipCounts.pending})',
                    selected: statusFilter == ProcurementStatusFilter.pending,
                    color: AppColors.warning,
                    onTap: () => ref
                        .read(procurementStatusFilterProvider.notifier)
                        .state = ProcurementStatusFilter.pending,
                  ),
                  const SizedBox(width: AppDimensions.sm),
                  _StatusChip(
                    label: 'Done (${chipCounts.done})',
                    selected: statusFilter == ProcurementStatusFilter.done,
                    color: AppColors.success,
                    onTap: () => ref
                        .read(procurementStatusFilterProvider.notifier)
                        .state = ProcurementStatusFilter.done,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppDimensions.md),

          // ── Section header ────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.base),
            child: Row(
              children: [
                Text(
                  'PROCUREMENT ITEMS',
                  style: AppTextStyles.label.copyWith(
                    color: AppColors.textSecondary,
                    letterSpacing: 1.0,
                  ),
                ),
                const Spacer(),
                Text(
                  '${summary.procuredCount} procured',
                  style: AppTextStyles.captionMedium
                      .copyWith(color: AppColors.success),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppDimensions.xs),

          // ── Items list ────────────────────────────────────────────────
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => notifier.refresh(
                  warehouseId: selectedWarehouse?.warehouseId,
                  deliveryDate: selectedDate),
              color: AppColors.primary,
              child: items.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: const [
                        SizedBox(height: 220),
                        Center(child: Text('No procurement items')),
                      ],
                    )
                  : ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.only(bottom: 80),
                      itemCount: items.length,
                      itemBuilder: (_, i) {
                        final item = items[i];
                        return ProcurementItemTile(
                          item: item,
                          onToggleCheck: () => notifier.toggleCheck(item.id),
                          onStatusChange: (s) => notifier.setStatus(item.id, s),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
      floatingActionButton: switch (selectionType) {
        ProcurementSelectionType.none => null,
        ProcurementSelectionType.procuredOnly =>
          FloatingActionButton.extended(
            onPressed: notifier.markSelectedUnprocured,
            backgroundColor: AppColors.error,
            foregroundColor: Colors.white,
            icon: const Icon(Icons.remove_circle_outline_rounded),
            label: const Text('Mark Unprocured'),
          ),
        ProcurementSelectionType.pendingOnly ||
        ProcurementSelectionType.mixed =>
          FloatingActionButton.extended(
            onPressed: notifier.markSelectedProcured,
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            icon: const Icon(Icons.check_circle_outline_rounded),
            label: const Text('Mark Selected Procured'),
          ),
      },
    );
  }
}

// ── Stats card ────────────────────────────────────────────────────────────────

class _StatsCard extends StatelessWidget {
  final ({
    double totalNeeded,
    int itemCount,
    int orderCount,
    int procuredCount,
  }) summary;

  const _StatsCard({required this.summary});

  String _fmtNumber(double v) =>
      v % 1 == 0 ? v.toInt().toString() : v.toStringAsFixed(1);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.base),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
      ),
      child: Column(
        children: [
          // Top row: needed today (full width)
          _BigStat(
            value: _fmtNumber(summary.totalNeeded),
            label: 'Needed Today',
          ),
          Divider(
            color: Colors.white.withValues(alpha: 0.2),
            height: AppDimensions.base,
            thickness: 1,
          ),
          // Bottom row: count metrics
          Row(
            children: [
              Expanded(
                child: _SmallStat(
                  value: '${summary.itemCount}',
                  label: 'Items',
                ),
              ),
              _VertDiv(height: 24),
              Expanded(
                child: _SmallStat(
                  value: '${summary.orderCount}',
                  label: 'Orders',
                ),
              ),
              _VertDiv(height: 24),
              Expanded(
                child: _SmallStat(
                  value: '${summary.procuredCount}',
                  label: 'Procured',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BigStat extends StatelessWidget {
  final String value;
  final String label;
  const _BigStat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: AppTextStyles.h3.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            )),
        const SizedBox(height: 2),
        Text(label,
            style: AppTextStyles.label.copyWith(
              color: Colors.white.withValues(alpha: 0.7),
            )),
      ],
    );
  }
}

class _SmallStat extends StatelessWidget {
  final String value;
  final String label;
  const _SmallStat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: AppTextStyles.bodySemiBold.copyWith(color: Colors.white)),
        Text(label,
            style: AppTextStyles.label.copyWith(
              color: Colors.white.withValues(alpha: 0.7),
            )),
      ],
    );
  }
}

class _VertDiv extends StatelessWidget {
  final double height;
  const _VertDiv({this.height = 36});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: height,
      color: Colors.white.withValues(alpha: 0.25),
    );
  }
}

// ── Status filter chip ────────────────────────────────────────────────────────

class _StatusChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _StatusChip({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.base,
          vertical: AppDimensions.xs + 2,
        ),
        decoration: BoxDecoration(
          color: selected ? color : AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
          border: Border.all(
            color: selected ? color : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.captionMedium.copyWith(
            color: selected ? Colors.white : AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

// ── Download sheet ────────────────────────────────────────────────────────────

class _DownloadSheet extends StatelessWidget {
  final String content;
  const _DownloadSheet({required this.content});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      expand: false,
      builder: (_, scrollController) => Padding(
        padding: const EdgeInsets.all(AppDimensions.base),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppDimensions.base),
            Row(
              children: [
                Text("Today's Procurement List", style: AppTextStyles.h3),
                const Spacer(),
                TextButton.icon(
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: content));
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Copied to clipboard')),
                      );
                      Navigator.pop(context);
                    }
                  },
                  icon: const Icon(Icons.copy_rounded, size: 16),
                  label: const Text('Copy'),
                  style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.sm),
            Expanded(
              child: SingleChildScrollView(
                controller: scrollController,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppDimensions.md),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                  ),
                  child: Text(content, style: AppTextStyles.body),
                ),
              ),
            ),
            const SizedBox(height: AppDimensions.base),
          ],
        ),
      ),
    );
  }
}
