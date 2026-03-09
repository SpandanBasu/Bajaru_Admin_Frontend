import 'package:flutter/material.dart';
import '../../core/models/rider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/constants/app_dimensions.dart';
import '../../features/riders/providers/riders_provider.dart';

class RiderBatchCard extends StatelessWidget {
  final RiderBatch batch;
  final VoidCallback? onTap;

  const RiderBatchCard({super.key, required this.batch, this.onTap});

  @override
  Widget build(BuildContext context) {
    final rider = batch.rider;

    // ── Status badge config ──────────────────────────────────────────────────
    final String statusLabel;
    final Color statusColor;
    final Color statusBg;

    if (batch.isCompleted) {
      statusLabel = 'Completed';
      statusColor = AppColors.success;
      statusBg = AppColors.successLight;
    } else if (batch.isActive) {
      statusLabel = 'On Route';
      statusColor = AppColors.primary;
      statusBg = AppColors.primaryLight;
    } else {
      statusLabel = 'Pending';
      statusColor = AppColors.warning;
      statusBg = AppColors.warningLight;
    }

    final pincodes = batch.pincodes;
    // Effective all-day totals (from API rider data when available)
    final totalAssigned = batch.effectiveTotalAssigned;
    final totalDelivered = batch.effectiveDelivered;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.base),
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header: avatar + name + status ───────────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _RiderAvatar(rider: rider),
                const SizedBox(width: AppDimensions.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(rider.name, style: AppTextStyles.bodySemiBold),
                      // ── Pincode pill bubbles ──────────────────────────────
                      if (pincodes.isNotEmpty) ...[
                        const SizedBox(height: AppDimensions.xs),
                        Wrap(
                          spacing: AppDimensions.xs,
                          runSpacing: AppDimensions.xs,
                          children: [
                            for (final pin in pincodes.take(4))
                              _PincodeBubble(label: pin),
                            if (pincodes.length > 4)
                              _PincodeBubble(
                                label: '+${pincodes.length - 4}',
                                isOverflow: true,
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: AppDimensions.sm),
                _StatusBadge(
                  label: statusLabel,
                  color: statusColor,
                  bg: statusBg,
                ),
              ],
            ),

            const SizedBox(height: AppDimensions.md),
            const Divider(height: 1, color: AppColors.border),
            const SizedBox(height: AppDimensions.md),

            // ── Stats row (all-day totals) ────────────────────────────────────
            Row(
              children: [
                _StatItem(
                  icon: Icons.inventory_2_outlined,
                  value: '$totalAssigned',
                  label: 'Assigned',
                ),
                _dividerDot,
                _StatItem(
                  icon: Icons.check_circle_outline_rounded,
                  value: '$totalDelivered/$totalAssigned',
                  label: 'Delivered',
                  iconColor: totalDelivered > 0
                      ? AppColors.success
                      : AppColors.textHint,
                ),
                if (batch.outForDelivery > 0) ...[
                  _dividerDot,
                  _StatItem(
                    icon: Icons.delivery_dining_rounded,
                    value: '${batch.outForDelivery}',
                    label: 'On Route',
                    iconColor: AppColors.primary,
                  ),
                ],
                if (batch.avgDeliveryMinutes != null) ...[
                  _dividerDot,
                  _StatItem(
                    icon: Icons.timer_outlined,
                    value: '~${batch.avgDeliveryMinutes}m',
                    label: 'Avg Time',
                  ),
                ],
              ],
            ),

            const SizedBox(height: AppDimensions.md),

            // ── Progress bar (delivered / total assigned) ─────────────────────
            ClipRRect(
              borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
              child: LinearProgressIndicator(
                value: batch.progressFraction,
                backgroundColor: AppColors.border,
                color: batch.isCompleted ? AppColors.success : AppColors.primary,
                minHeight: 6,
              ),
            ),

            const SizedBox(height: AppDimensions.xs),

            // ── Progress label + tap hint ─────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$totalDelivered of $totalAssigned delivered today',
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.textSecondary),
                ),
                if (onTap != null)
                  Row(
                    children: [
                      Text(
                        'View orders',
                        style: AppTextStyles.caption
                            .copyWith(color: AppColors.primary),
                      ),
                      const SizedBox(width: 2),
                      const Icon(Icons.chevron_right_rounded,
                          size: 14, color: AppColors.primary),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static const _dividerDot = Padding(
    padding: EdgeInsets.symmetric(horizontal: AppDimensions.sm),
    child: Text('·',
        style: TextStyle(color: AppColors.textHint, fontSize: 14)),
  );
}

// ── Sub-widgets ────────────────────────────────────────────────────────────────

class _PincodeBubble extends StatelessWidget {
  final String label;
  final bool isOverflow;

  const _PincodeBubble({required this.label, this.isOverflow = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: isOverflow ? AppColors.neutralLight : AppColors.primaryLight,
        borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
      ),
      child: Text(
        label,
        style: AppTextStyles.caption.copyWith(
          color: isOverflow ? AppColors.textSecondary : AppColors.primary,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _RiderAvatar extends StatelessWidget {
  final Rider rider;
  const _RiderAvatar({required this.rider});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        CircleAvatar(
          radius: 22,
          backgroundColor: rider.avatarColor,
          child: Text(
            rider.initials,
            style: AppTextStyles.bodySemiBold.copyWith(color: Colors.white),
          ),
        ),
        Positioned(
          right: 0,
          bottom: 0,
          child: Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: rider.isOnline ? AppColors.success : AppColors.textHint,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.surface, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final Color bg;
  const _StatusBadge(
      {required this.label, required this.color, required this.bg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.sm,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
      ),
      child: Text(
        label,
        style: AppTextStyles.captionBold.copyWith(color: color),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color? iconColor;

  const _StatItem({
    required this.icon,
    required this.value,
    required this.label,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon,
                size: 13,
                color: iconColor ?? AppColors.textSecondary),
            const SizedBox(width: 3),
            Text(value, style: AppTextStyles.captionBold.copyWith(color: AppColors.textPrimary)),
          ],
        ),
        const SizedBox(height: 1),
        Text(label,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textHint,
              fontSize: 10,
            )),
      ],
    );
  }
}
