import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/orders_provider.dart';
import '../../../core/models/batch_order.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../widgets/common/admin_app_bar.dart';
import '../../../widgets/common/admin_drawer.dart';
import '../../../widgets/common/pincode_dropdown.dart';
import '../../../widgets/orders/order_card.dart';

class OrdersScreen extends ConsumerWidget {
  const OrdersScreen({super.key});

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
                if (!isValid) {
                  return;
                }
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
  Widget build(BuildContext context, WidgetRef ref) {
    final counts   = ref.watch(ordersTabCountProvider);
    final activeTab = ref.watch(ordersTabProvider);
    final filtered  = ref.watch(filteredOrdersProvider);
    final notifier  = ref.read(ordersProvider.notifier);
    final pincode   = ref.watch(ordersSelectedPincodeProvider);
    final allOrders = ref.watch(ordersProvider);
    final pincodes  = allOrders.map((o) => o.pincode).toSet().toList()..sort();

    return Scaffold(
      backgroundColor: AppColors.background,
      drawer: const AdminDrawer(),
      appBar: AdminAppBar(title: 'Packing Orders'),
      body: Column(
        children: [
          // Pincode dropdown
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.fromLTRB(
              AppDimensions.base,
              AppDimensions.sm,
              AppDimensions.base,
              AppDimensions.md,
            ),
            child: PincodeDropdown(
              pincodes: pincodes,
              selected: pincode,
              onChanged: (val) => ref
                  .read(ordersSelectedPincodeProvider.notifier)
                  .state = val,
            ),
          ),
          const Divider(height: 1, color: AppColors.border),

          // Tab bar
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

          // Orders list
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => notifier.refresh(pincode: pincode),
              color: AppColors.primary,
              child: filtered.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: const [
                        SizedBox(height: 220),
                        Center(child: Text('No orders in this category')),
                      ],
                    )
                  : ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(AppDimensions.base),
                      itemCount: filtered.length,
                      itemBuilder: (_, i) {
                        final order = filtered[i];
                        return OrderCard(
                          order: order,
                          onToggleExpand: () =>
                              notifier.toggleExpand(order.id),
                          onToggleItem: (itemId) =>
                              notifier.toggleItem(order.id, itemId),
                          onComplete: () => notifier.completeOrder(order.id),
                          onMarkAsIssue: () async {
                            final message = await _showIssueDialog(context);
                            if (message == null) {
                              return;
                            }
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
                color: selected ? AppColors.primary : Colors.transparent,
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
                  color: selected ? AppColors.primary : AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: selected ? AppColors.primary : AppColors.border,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                ),
                child: Text(
                  '$count',
                  style: AppTextStyles.label.copyWith(
                    color: selected ? Colors.white : AppColors.textSecondary,
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
