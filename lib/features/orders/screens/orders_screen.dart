import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/orders_provider.dart';
import '../../../core/models/batch_order.dart';
import '../../../core/providers/warehouse_provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../widgets/common/admin_app_bar.dart';
import '../../../widgets/common/admin_drawer.dart';
import '../../../widgets/common/warehouse_dropdown.dart';
import '../../../widgets/orders/order_card.dart';
import '../../../widgets/orders/vegetable_pack_card.dart';

class OrdersScreen extends ConsumerStatefulWidget {
  const OrdersScreen({super.key});

  @override
  ConsumerState<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends ConsumerState<OrdersScreen> {
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
      ref.read(ordersProvider.notifier).loadMore();
    }
  }

  Future<String?> _showIssueDialog(BuildContext context) async {
    final formKey = GlobalKey<FormState>();
    String issueMessage = '';
    return showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: const Text('Mark as Issue'),
          content: Form(
            key: formKey,
            child: TextFormField(
              autofocus: true,
              maxLines: 1,
              textInputAction: TextInputAction.done,
              onChanged: (value) => issueMessage = value,
              decoration: const InputDecoration(
                labelText: "What's the issue?",
                hintText: 'Describe the issue',
                isDense: true,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Issue message is required';
                }
                return null;
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final isValid = formKey.currentState?.validate() ?? false;
                if (!isValid) return;
                Navigator.of(dialogContext).pop(issueMessage.trim());
              },
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final packingState = ref.watch(ordersProvider);
    final counts = ref.watch(ordersTabCountProvider);
    final activeTab = ref.watch(ordersTabProvider);
    final filtered = ref.watch(filteredOrdersProvider);
    final notifier = ref.read(ordersProvider.notifier);
    final selectedDate = ref.watch(ordersSelectedDateProvider);
    final activeWarehouse = ref.watch(activeWarehouseProvider);
    final packingMode = ref.watch(packingModeProvider);
    final vegState = ref.watch(vegetablePackProvider);
    final vegNotifier = ref.read(vegetablePackProvider.notifier);

    final now = DateTime.now();
    final isToday = selectedDate == null ||
        (selectedDate.year == now.year &&
            selectedDate.month == now.month &&
            selectedDate.day == now.day);
    final dateLabel = isToday
        ? 'Today, ${DateFormat('d MMM').format(now)}'
        : DateFormat('EEE, d MMM').format(selectedDate!);

    return Scaffold(
      backgroundColor: AppColors.background,
      drawer: const AdminDrawer(),
      appBar: AdminAppBar(title: 'Packing Orders'),
      body: Column(
        children: [
          // Warehouse dropdown + date picker + mode toggle
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.fromLTRB(
              AppDimensions.base,
              AppDimensions.sm,
              AppDimensions.base,
              AppDimensions.sm,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const WarehouseDropdown(),
                const SizedBox(height: AppDimensions.sm),
                _DatePickerRow(
                  dateLabel: dateLabel,
                  isToday: isToday,
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate ?? now,
                      firstDate: DateTime(2024),
                      lastDate: DateTime(2027),
                      builder: (ctx, child) => Theme(
                        data: Theme.of(ctx).copyWith(
                          colorScheme: Theme.of(ctx)
                              .colorScheme
                              .copyWith(primary: AppColors.primary),
                        ),
                        child: child!,
                      ),
                    );
                    if (picked != null) {
                      ref.read(ordersSelectedDateProvider.notifier).state =
                          picked;
                    }
                  },
                  onClear: isToday
                      ? null
                      : () => ref
                          .read(ordersSelectedDateProvider.notifier)
                          .state = null,
                ),
                const SizedBox(height: AppDimensions.sm),
                _ModeToggle(
                  mode: packingMode,
                  onChanged: (m) =>
                      ref.read(packingModeProvider.notifier).state = m,
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),

          // Tab bar — only visible in by-order mode
          if (packingMode == PackingMode.byOrder)
            Container(
              color: AppColors.surface,
              child: Row(
                children: [
                  _Tab(
                    label: 'To Pack',
                    count: counts.toPack,
                    selected: activeTab == OrderPackStatus.toPack,
                    onTap: () => ref
                        .read(ordersTabProvider.notifier)
                        .state = OrderPackStatus.toPack,
                  ),
                  _Tab(
                    label: 'Ready',
                    count: counts.ready,
                    selected: activeTab == OrderPackStatus.ready,
                    onTap: () => ref
                        .read(ordersTabProvider.notifier)
                        .state = OrderPackStatus.ready,
                  ),
                  _Tab(
                    label: 'Issues',
                    count: counts.issues,
                    selected: activeTab == OrderPackStatus.issues,
                    onTap: () => ref
                        .read(ordersTabProvider.notifier)
                        .state = OrderPackStatus.issues,
                  ),
                ],
              ),
            ),

          // Content: order list or vegetable view
          Expanded(
            child: packingMode == PackingMode.byVegetable
                ? _VegetablePackList(
                    state: vegState,
                    onRefresh: () => vegNotifier.refresh(
                      warehouseId: activeWarehouse?.warehouseId,
                      deliveryDate: selectedDate,
                    ),
                    onToggleExpand: vegNotifier.toggleExpand,
                    onTogglePacket: vegNotifier.togglePacket,
                  )
                : RefreshIndicator(
                    onRefresh: () => notifier.refresh(
                      warehouseId: activeWarehouse?.warehouseId,
                      deliveryDate: selectedDate,
                    ),
                    color: AppColors.primary,
                    child: filtered.isEmpty && !packingState.isLoadingMore
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: const [
                              SizedBox(height: 220),
                              Center(child: Text('No orders in this category')),
                            ],
                          )
                        : ListView.builder(
                            controller: _scrollController,
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.all(AppDimensions.base),
                            itemCount: filtered.length +
                                (packingState.isLoadingMore ? 1 : 0),
                            itemBuilder: (_, i) {
                              if (i == filtered.length) {
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
                              final order = filtered[i];
                              return OrderCard(
                                order: order,
                                onToggleExpand: () =>
                                    notifier.toggleExpand(order.id),
                                onToggleItem: (itemId) =>
                                    notifier.toggleItem(order.id, itemId),
                                onComplete: () =>
                                    notifier.completeOrder(order.id),
                                onMarkAsIssue: () async {
                                  final message =
                                      await _showIssueDialog(context);
                                  if (message == null) return;
                                  notifier.markIssue(order.id, message);
                                },
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

// ── Mode toggle ───────────────────────────────────────────────────────────────

class _ModeToggle extends StatelessWidget {
  final PackingMode mode;
  final ValueChanged<PackingMode> onChanged;

  const _ModeToggle({required this.mode, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ModeChip(
            icon: Icons.receipt_long_rounded,
            label: 'By Order',
            selected: mode == PackingMode.byOrder,
            onTap: () => onChanged(PackingMode.byOrder),
            isFirst: true,
          ),
          _ModeChip(
            icon: Icons.spa_rounded,
            label: 'By Veggie',
            selected: mode == PackingMode.byVegetable,
            onTap: () => onChanged(PackingMode.byVegetable),
            isFirst: false,
          ),
        ],
      ),
    );
  }
}

class _ModeChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool isFirst;

  const _ModeChip({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    required this.isFirst,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.horizontal(
            left: isFirst
                ? const Radius.circular(AppDimensions.radiusSm - 1)
                : Radius.zero,
            right: !isFirst
                ? const Radius.circular(AppDimensions.radiusSm - 1)
                : Radius.zero,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 13,
              color: selected ? Colors.white : AppColors.textSecondary,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: AppTextStyles.label.copyWith(
                color: selected ? Colors.white : AppColors.textSecondary,
                fontWeight:
                    selected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Vegetable pack list ───────────────────────────────────────────────────────

class _VegetablePackList extends StatelessWidget {
  final VegetablePackState state;
  final Future<void> Function() onRefresh;
  final ValueChanged<String> onToggleExpand;
  final void Function(String orderId, String itemId) onTogglePacket;

  const _VegetablePackList({
    required this.state,
    required this.onRefresh,
    required this.onToggleExpand,
    required this.onTogglePacket,
  });

  @override
  Widget build(BuildContext context) {
    if (state.isLoading) {
      return const Center(
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      color: AppColors.primary,
      child: state.groups.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [
                SizedBox(height: 220),
                Center(child: Text('No items to pack')),
              ],
            )
          : ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(AppDimensions.base),
              itemCount: state.groups.length,
              itemBuilder: (_, i) {
                final group = state.groups[i];
                return VegetablePackCard(
                  group: group,
                  onToggleExpand: () => onToggleExpand(group.productId),
                  onTogglePacket: onTogglePacket,
                );
              },
            ),
    );
  }
}

// ── Date picker row ───────────────────────────────────────────────────────────

class _DatePickerRow extends StatelessWidget {
  final String dateLabel;
  final bool isToday;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  const _DatePickerRow({
    required this.dateLabel,
    required this.isToday,
    required this.onTap,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isToday ? AppColors.background : AppColors.primaryLight,
          borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
          border: Border.all(
            color: isToday ? AppColors.border : AppColors.primary,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.calendar_today_rounded,
              size: 14,
              color: isToday ? AppColors.textSecondary : AppColors.primary,
            ),
            const SizedBox(width: 6),
            Text(
              dateLabel,
              style: AppTextStyles.caption.copyWith(
                color: isToday
                    ? AppColors.textSecondary
                    : AppColors.primary,
                fontWeight:
                    isToday ? FontWeight.normal : FontWeight.w600,
              ),
            ),
            if (onClear != null) ...[
              const SizedBox(width: 6),
              GestureDetector(
                onTap: onClear,
                child: Icon(Icons.close_rounded,
                    size: 14, color: AppColors.primary),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Tab widget ────────────────────────────────────────────────────────────────

class _Tab extends StatelessWidget {
  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  const _Tab({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: AppDimensions.md),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color:
                    selected ? AppColors.primary : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: AppTextStyles.bodySemiBold.copyWith(
                  color: selected
                      ? AppColors.primary
                      : AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: 4),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: selected ? AppColors.primary : AppColors.border,
                  borderRadius:
                      BorderRadius.circular(AppDimensions.radiusFull),
                ),
                child: Text(
                  '$count',
                  style: AppTextStyles.label.copyWith(
                    color: selected
                        ? Colors.white
                        : AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
