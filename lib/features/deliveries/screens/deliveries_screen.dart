import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/deliveries_provider.dart';
import '../../../core/providers/warehouse_provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../widgets/common/admin_drawer.dart';
import '../../../widgets/common/warehouse_dropdown.dart';
import '../../../widgets/deliveries/delivery_order_card.dart';
import '../../../widgets/deliveries/delivery_filter_bottom_sheet.dart';
import 'order_detail_screen.dart';

class DeliveriesScreen extends ConsumerStatefulWidget {
  const DeliveriesScreen({super.key});

  @override
  ConsumerState<DeliveriesScreen> createState() => _DeliveriesScreenState();
}

class _DeliveriesScreenState extends ConsumerState<DeliveriesScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 200) {
      ref.read(deliveriesProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final deliveryState = ref.watch(deliveriesProvider);
    final filter        = ref.watch(deliveryFilterProvider);
    final counts        = ref.watch(deliveryCountsProvider);
    final orders        = ref.watch(filteredDeliveriesProvider);
    final selectedDate  = ref.watch(deliverySelectedDateProvider);
    final orderIdQuery  = ref.watch(deliveryOrderIdQueryProvider);
    final riderQuery    = ref.watch(deliveryRiderQueryProvider);
    final paymentFilter = ref.watch(deliveryPaymentFilterProvider);
    final sortBy        = ref.watch(deliverySortByProvider);

    final now = DateTime.now();
    final isToday = selectedDate == null ||
        (selectedDate.year == now.year &&
            selectedDate.month == now.month &&
            selectedDate.day == now.day);

    final hasExtraFilters = orderIdQuery.trim().isNotEmpty ||
        riderQuery.trim().isNotEmpty ||
        paymentFilter != DeliveryPaymentFilter.all ||
        sortBy != DeliverySortBy.none ||
        !isToday;

    final dateLabel = isToday
        ? 'Today'
        : DateFormat('d MMM yyyy').format(selectedDate!);

    return Scaffold(
      backgroundColor: AppColors.background,
      drawer: const AdminDrawer(),
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 1,
        shadowColor: Colors.black12,
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu_rounded),
            color: AppColors.textSecondary,
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
        titleSpacing: AppDimensions.base,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Deliveries', style: AppTextStyles.h2),
            Text(
              '$dateLabel  ·  ${counts.all} orders',
              style: AppTextStyles.caption
                  .copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
        toolbarHeight: 68,
        actions: [
          IconButton(
            icon: Icon(
              Icons.filter_alt_rounded,
              color: hasExtraFilters
                  ? AppColors.primary
                  : AppColors.textSecondary,
            ),
            onPressed: () => showDeliveryFilterBottomSheet(context),
          ),
          const SizedBox(width: AppDimensions.xs),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Status filter chips ────────────────────────────────────────
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.base,
              vertical: AppDimensions.sm + 2,
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _FilterChip(
                    label: 'All (${counts.all})',
                    selected: filter == DeliveryFilterStatus.all,
                    selectedBg: AppColors.primary,
                    selectedFg: Colors.white,
                    unselectedBg: AppColors.surface,
                    unselectedFg: AppColors.textSecondary,
                    borderColor: AppColors.primary,
                    onTap: () => ref
                        .read(deliveryFilterProvider.notifier)
                        .state = DeliveryFilterStatus.all,
                  ),
                  const SizedBox(width: AppDimensions.sm),
                  _FilterChip(
                    label: 'Pending (${counts.pending})',
                    selected: filter == DeliveryFilterStatus.pending,
                    selectedBg: AppColors.warningLight,
                    selectedFg: AppColors.warning,
                    unselectedBg: AppColors.warningLight,
                    unselectedFg: AppColors.warning,
                    borderColor: AppColors.warning,
                    onTap: () => ref
                        .read(deliveryFilterProvider.notifier)
                        .state = DeliveryFilterStatus.pending,
                  ),
                  const SizedBox(width: AppDimensions.sm),
                  _FilterChip(
                    label: 'Out (${counts.outForDelivery})',
                    selected: filter == DeliveryFilterStatus.outForDelivery,
                    selectedBg: AppColors.primaryLight,
                    selectedFg: AppColors.primary,
                    unselectedBg: AppColors.primaryLight,
                    unselectedFg: AppColors.primary,
                    borderColor: AppColors.primary,
                    onTap: () => ref
                        .read(deliveryFilterProvider.notifier)
                        .state = DeliveryFilterStatus.outForDelivery,
                  ),
                  const SizedBox(width: AppDimensions.sm),
                  _FilterChip(
                    label: 'Delivered (${counts.delivered})',
                    selected: filter == DeliveryFilterStatus.delivered,
                    selectedBg: AppColors.successLight,
                    selectedFg: AppColors.success,
                    unselectedBg: AppColors.successLight,
                    unselectedFg: AppColors.success,
                    borderColor: AppColors.success,
                    onTap: () => ref
                        .read(deliveryFilterProvider.notifier)
                        .state = DeliveryFilterStatus.delivered,
                  ),
                  if (counts.rejected > 0) ...[
                    const SizedBox(width: AppDimensions.sm),
                    _FilterChip(
                      label: 'Rejected (${counts.rejected})',
                      selected: filter == DeliveryFilterStatus.rejected,
                      selectedBg: AppColors.errorLight,
                      selectedFg: AppColors.error,
                      unselectedBg: AppColors.errorLight,
                      unselectedFg: AppColors.error,
                      borderColor: AppColors.error,
                      onTap: () => ref
                          .read(deliveryFilterProvider.notifier)
                          .state = DeliveryFilterStatus.rejected,
                    ),
                  ],
                ],
              ),
            ),
          ),

          // ── Warehouse dropdown ─────────────────────────────────────────
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.fromLTRB(
              AppDimensions.base,
              AppDimensions.sm,
              AppDimensions.base,
              AppDimensions.md,
            ),
            child: const WarehouseDropdown(),
          ),
          const Divider(height: 1, color: AppColors.border),

          // ── Orders list ────────────────────────────────────────────────
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => ref.read(deliveriesProvider.notifier).refresh(
                    warehouseId: ref.read(activeWarehouseProvider)?.warehouseId,
                    deliveryDate: selectedDate,
                  ),
              color: AppColors.primary,
              child: orders.isEmpty && !deliveryState.isLoadingMore
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.4,
                          child: Center(
                            child: Text(
                              'No orders found',
                              style: AppTextStyles.body.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  : ListView.separated(
                      controller: _scrollController,
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(AppDimensions.base),
                      itemCount:
                          orders.length + (deliveryState.isLoadingMore ? 1 : 0),
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: AppDimensions.sm),
                      itemBuilder: (_, i) {
                        if (i == orders.length) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(
                                vertical: AppDimensions.base),
                            child: Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    AppColors.primary),
                              ),
                            ),
                          );
                        }
                        final order = orders[i];
                        return DeliveryOrderCard(
                          order: order,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  OrderDetailScreen(orderId: order.id),
                            ),
                          ),
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

// ── Filter Chip ───────────────────────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color selectedBg;
  final Color selectedFg;
  final Color unselectedBg;
  final Color unselectedFg;
  final Color borderColor;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.selectedBg,
    required this.selectedFg,
    required this.unselectedBg,
    required this.unselectedFg,
    required this.borderColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bg = selected ? selectedBg : AppColors.surface;
    final fg = selected ? selectedFg : unselectedFg;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.base,
          vertical: AppDimensions.xs + 2,
        ),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
          border: Border.all(
            color: selected ? borderColor : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.captionMedium.copyWith(
            color: fg,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
