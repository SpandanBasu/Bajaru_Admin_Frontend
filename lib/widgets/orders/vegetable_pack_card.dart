import 'package:flutter/material.dart';
import '../../core/models/batch_order.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/constants/app_dimensions.dart';

/// Displays one product group in the "Pack by Vegetable" view.
/// Shows the product name, packed/total count, and an expandable list of
/// individual packets (one per order) with their quantity × unit and a checkbox.
class VegetablePackCard extends StatelessWidget {
  final VegetablePackGroup group;
  final VoidCallback onToggleExpand;
  final void Function(String orderId, String itemId) onTogglePacket;

  const VegetablePackCard({
    super.key,
    required this.group,
    required this.onToggleExpand,
    required this.onTogglePacket,
  });

  @override
  Widget build(BuildContext context) {
    final checked = group.checkedCount;
    final total = group.totalUnits;
    final progress = total == 0 ? 0.0 : checked / total;

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
                  // Green dot when fully packed
                  Container(
                    width: 10,
                    height: 10,
                    margin: const EdgeInsets.only(right: AppDimensions.sm),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: group.allChecked
                          ? AppColors.success
                          : AppColors.border,
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          group.productName,
                          style: AppTextStyles.bodySemiBold,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$total packet${total == 1 ? '' : 's'}',
                          style: AppTextStyles.caption
                              .copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  // Packed count badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppDimensions.sm, vertical: 3),
                    decoration: BoxDecoration(
                      color: group.allChecked
                          ? AppColors.success.withValues(alpha: 0.12)
                          : AppColors.primaryLight,
                      borderRadius:
                          BorderRadius.circular(AppDimensions.radiusFull),
                    ),
                    child: Text(
                      '$checked/$total',
                      style: AppTextStyles.captionMedium.copyWith(
                        color: group.allChecked
                            ? AppColors.success
                            : AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppDimensions.sm),
                  Icon(
                    group.isExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: AppColors.textHint,
                  ),
                ],
              ),
            ),
          ),

          // Progress bar (always visible)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppDimensions.base),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: AppColors.border,
                color: AppColors.success,
                minHeight: 4,
              ),
            ),
          ),

          // Expanded packet list
          if (group.isExpanded) ...[
            const SizedBox(height: AppDimensions.xs),
            const Divider(height: 1, color: AppColors.border),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppDimensions.base,
                AppDimensions.sm,
                AppDimensions.base,
                AppDimensions.sm,
              ),
              child: Column(
                children: [
                  for (final packet in group.packets)
                    _PacketRow(
                      packet: packet,
                      onToggle: () =>
                          onTogglePacket(packet.orderId, packet.itemId),
                    ),
                ],
              ),
            ),
          ] else
            const SizedBox(height: AppDimensions.sm),
        ],
      ),
    );
  }
}

class _PacketRow extends StatelessWidget {
  final VegetablePacket packet;
  final VoidCallback onToggle;

  const _PacketRow({required this.packet, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    final qtyStr = packet.quantity.toString();
    final quantityDisplay = '$qtyStr × ${packet.unitWeight}';

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
                color: packet.isChecked ? AppColors.success : Colors.transparent,
                border: Border.all(
                  color:
                      packet.isChecked ? AppColors.success : AppColors.border,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(4),
              ),
              child: packet.isChecked
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
                packet.orderDisplayId,
                style: AppTextStyles.body.copyWith(
                  decoration:
                      packet.isChecked ? TextDecoration.lineThrough : null,
                  color: packet.isChecked
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
