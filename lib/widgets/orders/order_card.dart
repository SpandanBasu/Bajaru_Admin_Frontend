import 'package:flutter/material.dart';
import '../../core/models/batch_order.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/constants/app_dimensions.dart';
import '../common/status_badge.dart';

class OrderCard extends StatelessWidget {
  final BatchOrder order;
  final VoidCallback onToggleExpand;
  final ValueChanged<String> onToggleItem;
  final VoidCallback? onToggleNewBag;
  final VoidCallback onComplete;
  final VoidCallback? onMarkAsIssue;

  const OrderCard({
    super.key,
    required this.order,
    required this.onToggleExpand,
    required this.onToggleItem,
    this.onToggleNewBag,
    required this.onComplete,
    this.onMarkAsIssue,
  });

  BadgeVariant _badgeVariant(OrderPackStatus s) => switch (s) {
        OrderPackStatus.toPack  => BadgeVariant.info,
        OrderPackStatus.packing => BadgeVariant.warning,
        OrderPackStatus.ready   => BadgeVariant.success,
        OrderPackStatus.issues  => BadgeVariant.error,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          InkWell(
            onTap: onToggleExpand,
            borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
            child: Padding(
              padding: const EdgeInsets.all(AppDimensions.base),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(order.displayId, style: AppTextStyles.bodySemiBold),
                        const SizedBox(height: 2),
                        Text(
                          '${order.area} • ${order.pincode} • ${order.itemCount} items',
                          style: AppTextStyles.caption
                              .copyWith(color: AppColors.textSecondary),
                        ),
                        if (order.status == OrderPackStatus.issues &&
                            order.issueMessage != null &&
                            order.issueMessage!.trim().isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Issue: ${order.issueMessage}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.caption
                                .copyWith(color: AppColors.error),
                          ),
                        ],
                      ],
                    ),
                  ),
                  StatusBadge(
                    label: order.status.label,
                    variant: _badgeVariant(order.status),
                  ),
                  const SizedBox(width: AppDimensions.sm),
                  Icon(
                    order.isExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: AppColors.textHint,
                  ),
                ],
              ),
            ),
          ),

          // Expanded content
          if (order.isExpanded) ...[
            const Divider(height: 1, color: AppColors.border),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppDimensions.base),
              child: Column(
                children: [
                  // Progress bar
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: AppDimensions.sm),
                    child: Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: order.itemCount == 0
                                  ? 0
                                  : order.checkedCount / order.itemCount,
                              backgroundColor: AppColors.border,
                              color: AppColors.success,
                              minHeight: 6,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppDimensions.sm),
                        Text(
                          '${order.checkedCount}/${order.itemCount}',
                          style: AppTextStyles.captionMedium,
                        ),
                      ],
                    ),
                  ),
                  if (order.status == OrderPackStatus.issues &&
                      order.issueMessage != null &&
                      order.issueMessage!.trim().isNotEmpty) ...[
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: AppDimensions.sm),
                      padding: const EdgeInsets.all(AppDimensions.sm),
                      decoration: BoxDecoration(
                        color: AppColors.errorLight,
                        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                      ),
                      child: Text(
                        'Issue: ${order.issueMessage}',
                        style: AppTextStyles.caption
                            .copyWith(color: AppColors.error),
                      ),
                    ),
                  ],

                  // Items
                  for (final item in order.items)
                    _PackItemRow(
                      item: item,
                      onToggle: () => onToggleItem(item.id),
                    ),

                  // New bag row (when order needs bag charge)
                  if (order.needsNewBag) ...[
                    _NewBagRow(
                      bagCharge: order.bagCharge,
                      isChecked: order.newBagChecked,
                      onToggle: onToggleNewBag ?? () {},
                    ),
                  ],

                  const SizedBox(height: AppDimensions.md),

                  // Complete button
                  if (order.status != OrderPackStatus.ready)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: order.allChecked ? onComplete : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.success,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: AppColors.border,
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(AppDimensions.radiusMd),
                              ),
                              padding: const EdgeInsets.symmetric(
                                  vertical: AppDimensions.sm),
                            ),
                            child: Text(
                              order.allChecked
                                  ? 'Mark as Ready'
                                  : 'Check all items to complete',
                              style: AppTextStyles.bodySemiBold
                                  .copyWith(color: Colors.white),
                            ),
                          ),
                        ),
                        if (onMarkAsIssue != null &&
                            (order.status == OrderPackStatus.toPack ||
                                order.status == OrderPackStatus.packing)) ...[
                          const SizedBox(height: AppDimensions.sm),
                          TextButton.icon(
                            onPressed: onMarkAsIssue,
                            icon: Icon(
                              Icons.report_problem_outlined,
                              size: 16,
                              color: AppColors.error,
                            ),
                            label: Text(
                              'Mark as Issue',
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.error,
                              ),
                            ),
                            style: TextButton.styleFrom(
                              minimumSize: Size.zero,
                              padding: EdgeInsets.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                          ),
                        ],
                      ],
                    ),

                  const SizedBox(height: AppDimensions.md),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PackItemRow extends StatelessWidget {
  final PackItem item;
  final VoidCallback onToggle;

  const _PackItemRow({required this.item, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    final qtyStr =
        item.quantity % 1 == 0 ? item.quantity.toInt().toString() : item.quantity.toString();
    final quantityDisplay = '${qtyStr} x ${item.unit}';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppDimensions.xs),
      child: Row(
        children: [
          GestureDetector(
            onTap: onToggle,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: item.isChecked ? AppColors.success : Colors.transparent,
                border: Border.all(
                  color: item.isChecked ? AppColors.success : AppColors.border,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(4),
              ),
              child: item.isChecked
                  ? const Icon(Icons.check_rounded,
                      color: Colors.white, size: 12)
                  : null,
            ),
          ),
          const SizedBox(width: AppDimensions.md),
          Expanded(
            child: GestureDetector(
              onTap: onToggle,
              behavior: HitTestBehavior.opaque,
              child: Text(
                item.name,
                style: AppTextStyles.body.copyWith(
                  decoration:
                      item.isChecked ? TextDecoration.lineThrough : null,
                  color: item.isChecked
                      ? AppColors.textSecondary
                      : AppColors.textPrimary,
                ),
              ),
            ),
          ),
          Text(
            quantityDisplay,
            style: AppTextStyles.captionMedium
                .copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _NewBagRow extends StatelessWidget {
  final double bagCharge;
  final bool isChecked;
  final VoidCallback onToggle;

  const _NewBagRow({
    required this.bagCharge,
    required this.isChecked,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: AppDimensions.xs),
      padding: const EdgeInsets.all(AppDimensions.sm),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: onToggle,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: isChecked ? AppColors.success : Colors.transparent,
                border: Border.all(
                  color: isChecked ? AppColors.success : AppColors.error,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(4),
              ),
              child: isChecked
                  ? const Icon(Icons.check_rounded,
                      color: Colors.white, size: 12)
                  : null,
            ),
          ),
          const SizedBox(width: AppDimensions.md),
          Expanded(
            child: GestureDetector(
              onTap: onToggle,
              behavior: HitTestBehavior.opaque,
              child: Text(
                'New bag (₹${bagCharge.toStringAsFixed(0)} paid)',
                style: AppTextStyles.body.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.error,
                  decoration: isChecked ? TextDecoration.lineThrough : null,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
