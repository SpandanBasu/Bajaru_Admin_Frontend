import 'package:flutter/material.dart';
import '../../core/models/procurement_item.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/constants/app_dimensions.dart';
import '../common/status_badge.dart';

class ProcurementItemTile extends StatelessWidget {
  final ProcurementItem item;
  final VoidCallback onToggleCheck;
  final ValueChanged<ProcurementStatus> onStatusChange;

  const ProcurementItemTile({
    super.key,
    required this.item,
    required this.onToggleCheck,
    required this.onStatusChange,
  });

  BadgeVariant _badgeVariant(ProcurementStatus s) => switch (s) {
        ProcurementStatus.done    => BadgeVariant.success,
        ProcurementStatus.pending => BadgeVariant.warning,
        ProcurementStatus.urgent  => BadgeVariant.error,
      };

  @override
  Widget build(BuildContext context) {
    final isDone = item.status == ProcurementStatus.done;

    return InkWell(
      onTap: onToggleCheck,
      child: Container(
        margin: const EdgeInsets.symmetric(
          horizontal: AppDimensions.base,
          vertical: AppDimensions.xs,
        ),
        padding: const EdgeInsets.all(AppDimensions.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Row 1: checkbox + name + status badge ────────────────────
            Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: item.isChecked
                        ? AppColors.primary
                        : Colors.transparent,
                    border: Border.all(
                      color: item.isChecked
                          ? AppColors.primary
                          : AppColors.border,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: item.isChecked
                      ? const Icon(Icons.check_rounded,
                          color: Colors.white, size: 14)
                      : null,
                ),
                const SizedBox(width: AppDimensions.sm),
                Expanded(
                  child: Text(
                    item.name,
                    style: AppTextStyles.bodySemiBold.copyWith(
                      decoration: isDone ? TextDecoration.lineThrough : null,
                      color: isDone
                          ? AppColors.textSecondary
                          : AppColors.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: AppDimensions.sm),
                GestureDetector(
                  onTap: () => _showStatusMenu(context),
                  behavior: HitTestBehavior.opaque,
                  child: StatusBadge(
                    label: item.status.label,
                    variant: _badgeVariant(item.status),
                  ),
                ),
              ],
            ),

            // ── Row 2: order count ────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.only(
                left: 30, // aligns under name
                top: 2,
                bottom: AppDimensions.sm,
              ),
              child: Text(
                '${item.orderCount} orders  •  ${item.warehouseId}',
                style: AppTextStyles.caption
                    .copyWith(color: AppColors.textSecondary),
              ),
            ),

            // ── Row 3: needed today ───────────────────────────────────────
            _QtyBox(
              value: item.formatQuantity(item.neededToday),
              label: 'Needed Today',
              bg: AppColors.primaryLight,
              valueColor: AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }

  void _showStatusMenu(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _StatusPickerSheet(
        current: item.status,
        onSelect: (s) {
          Navigator.pop(context);
          onStatusChange(s);
        },
      ),
    );
  }
}

// ── Quantity box ──────────────────────────────────────────────────────────────

class _QtyBox extends StatelessWidget {
  final String value;
  final String label;
  final Color bg;
  final Color valueColor;

  const _QtyBox({
    required this.value,
    required this.label,
    required this.bg,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.sm,
        vertical: AppDimensions.xs + 2,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: AppTextStyles.captionMedium.copyWith(
              color: valueColor,
              fontWeight: FontWeight.w700,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            label,
            style: AppTextStyles.label.copyWith(
              color: valueColor.withValues(alpha: 0.7),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Status picker bottom sheet ────────────────────────────────────────────────

class _StatusPickerSheet extends StatelessWidget {
  final ProcurementStatus current;
  final ValueChanged<ProcurementStatus> onSelect;

  const _StatusPickerSheet({required this.current, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppDimensions.base),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: AppDimensions.base),
          Text('Change Status', style: AppTextStyles.h3),
          const SizedBox(height: AppDimensions.sm),
          for (final s in ProcurementStatus.values)
            ListTile(
              title: Text(s.label, style: AppTextStyles.body),
              trailing: s == current
                  ? const Icon(Icons.check_circle_rounded,
                      color: AppColors.primary)
                  : const Icon(Icons.circle_outlined, color: AppColors.border),
              onTap: () => onSelect(s),
            ),
          const SizedBox(height: AppDimensions.base),
        ],
      ),
    );
  }
}
