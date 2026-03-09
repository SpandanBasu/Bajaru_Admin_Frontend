import 'package:flutter/material.dart';
import '../../core/models/delivery_order.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/constants/app_dimensions.dart';

class DeliveryOrderCard extends StatelessWidget {
  final DeliveryOrder order;
  final VoidCallback onTap;

  const DeliveryOrderCard({
    super.key,
    required this.order,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDelivered = order.status == DeliveryStatus.delivered;
    final isOut       = order.status == DeliveryStatus.outForDelivery;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.md),
        decoration: BoxDecoration(
          color: isDelivered ? AppColors.successLight : AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          border: Border.all(
            color: isDelivered ? AppColors.success : AppColors.border,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Row 1: Order ID (last 4 chars) + Status Badge ─────────────────
            Row(
              children: [
                Text(
                  order.id.length <= 4
                      ? order.id
                      : '#${order.id.substring(order.id.length - 4)}',
                  style: AppTextStyles.bodySemiBold
                      .copyWith(color: AppColors.textPrimary),
                ),
                const Spacer(),
                _StatusBadge(status: order.status),
              ],
            ),
            const SizedBox(height: AppDimensions.xs + 2),

            // ── Row 2: Customer name + area ──────────────────────────────
            Row(
              children: [
                Icon(Icons.person_outline_rounded,
                    size: 14, color: AppColors.textSecondary),
                const SizedBox(width: AppDimensions.xs + 2),
                Text(
                  order.customerName,
                  style: AppTextStyles.captionMedium
                      .copyWith(color: AppColors.textPrimary),
                ),
                Text(
                  '  ·  ',
                  style:
                      AppTextStyles.caption.copyWith(color: AppColors.textHint),
                ),
                Expanded(
                  child: Text(
                    order.area,
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.textSecondary),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.sm),

            // ── Row 3: Item count + Amount + COD tag + Time/Rider ────────
            Row(
              children: [
                _MetaChip(
                  icon: Icons.shopping_bag_outlined,
                  text: '${order.itemCount} items',
                ),
                const SizedBox(width: AppDimensions.md),
                _MetaChip(
                  icon: Icons.currency_rupee_rounded,
                  text: '₹${order.total}',
                ),
                const SizedBox(width: AppDimensions.md),
                _PaymentTag(isCOD: order.isCOD),
                const Spacer(),
                // Delivered: show time with green timer icon
                // Out for delivery: show rider name
                // Pending: show plain time
                if (isDelivered) ...[
                  Icon(Icons.timer_outlined,
                      size: 12, color: AppColors.success),
                  const SizedBox(width: 3),
                  Text(
                    order.time,
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.success, fontWeight: FontWeight.w500),
                  ),
                ] else if (isOut && order.riderName != null) ...[
                  Icon(Icons.directions_bike_rounded,
                      size: 12, color: AppColors.primary),
                  const SizedBox(width: 3),
                  Text(
                    order.riderName!,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ] else ...[
                  Text(
                    order.time,
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.textHint),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Status Badge ──────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final DeliveryStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (bg, fg, solid) = switch (status) {
      DeliveryStatus.pending        => (AppColors.warningLight, AppColors.warning, false),
      DeliveryStatus.outForDelivery => (AppColors.primaryLight,  AppColors.primary, false),
      DeliveryStatus.delivered      => (AppColors.success,       Colors.white,       true),
      DeliveryStatus.rejected       => (AppColors.errorLight,    AppColors.error,    false),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
      ),
      child: Text(
        status.label,
        style: AppTextStyles.label.copyWith(color: fg, fontSize: 10),
      ),
    );
  }
}

// ── Small meta chip (icon + text) ─────────────────────────────────────────────

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String text;
  const _MetaChip({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: AppColors.textSecondary),
        const SizedBox(width: 3),
        Text(text,
            style:
                AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
      ],
    );
  }
}

// ── COD / Prepaid tag ─────────────────────────────────────────────────────────

class _PaymentTag extends StatelessWidget {
  final bool isCOD;
  const _PaymentTag({required this.isCOD});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isCOD ? AppColors.warningLight : AppColors.successLight,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        isCOD ? 'COD' : 'Prepaid',
        style: AppTextStyles.label.copyWith(
          fontSize: 10,
          color: isCOD ? AppColors.warning : AppColors.success,
        ),
      ),
    );
  }
}
