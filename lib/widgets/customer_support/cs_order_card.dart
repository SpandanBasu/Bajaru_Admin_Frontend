import 'package:flutter/material.dart';
import '../../core/models/cs_customer.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/constants/app_dimensions.dart';
import '../common/status_badge.dart';

/// Expandable order card used in the Customer Profile screen.
/// Border color reflects order status when expanded.
class CsOrderCard extends StatefulWidget {
  final SupportOrder order;
  final bool initiallyExpanded;
  final VoidCallback? onSeeDetails;

  const CsOrderCard({
    super.key,
    required this.order,
    this.initiallyExpanded = false,
    this.onSeeDetails,
  });

  @override
  State<CsOrderCard> createState() => _CsOrderCardState();
}

class _CsOrderCardState extends State<CsOrderCard> {
  late bool _expanded;

  @override
  void initState() {
    super.initState();
    _expanded = widget.initiallyExpanded;
  }

  Color get _borderColor {
    if (!_expanded) return AppColors.border;
    return switch (widget.order.status) {
      SupportOrderStatus.pending => AppColors.warning,
      SupportOrderStatus.cancelled => AppColors.error,
      SupportOrderStatus.delivered => AppColors.success,
      SupportOrderStatus.confirmed => AppColors.primary,
    };
  }

  Color get _chevronColor => switch (widget.order.status) {
        SupportOrderStatus.cancelled => AppColors.error,
        _ => AppColors.primary,
      };

  BadgeVariant get _badgeVariant => switch (widget.order.status) {
        SupportOrderStatus.pending => BadgeVariant.warning,
        SupportOrderStatus.confirmed => BadgeVariant.info,
        SupportOrderStatus.delivered => BadgeVariant.success,
        SupportOrderStatus.cancelled => BadgeVariant.error,
      };

  String get _badgeLabel => switch (widget.order.status) {
        SupportOrderStatus.pending => 'Pending',
        SupportOrderStatus.confirmed => 'Confirmed',
        SupportOrderStatus.delivered => 'Delivered',
        SupportOrderStatus.cancelled => 'Cancelled',
      };

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(color: _borderColor, width: 1.5),
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        children: [
          _OrderHeader(
            order: widget.order,
            expanded: _expanded,
            badgeLabel: _badgeLabel,
            badgeVariant: _badgeVariant,
            chevronColor: _chevronColor,
            onTap: () => setState(() => _expanded = !_expanded),
          ),
          if (_expanded) ...[
            const Divider(height: 1, color: AppColors.border),
            _OrderBody(order: widget.order, onSeeDetails: widget.onSeeDetails),
          ],
        ],
      ),
    );
  }
}

// ─── Header ──────────────────────────────────────────────────────────────────

class _OrderHeader extends StatelessWidget {
  final SupportOrder order;
  final bool expanded;
  final String badgeLabel;
  final BadgeVariant badgeVariant;
  final Color chevronColor;
  final VoidCallback onTap;

  const _OrderHeader({
    required this.order,
    required this.expanded,
    required this.badgeLabel,
    required this.badgeVariant,
    required this.chevronColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      order.orderIdDisplay,
                      style: AppTextStyles.bodySemiBold.copyWith(fontSize: 14),
                    ),
                    if (!expanded) ...[
                      const SizedBox(width: AppDimensions.sm),
                      StatusBadge(label: badgeLabel, variant: badgeVariant),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  order.date,
                  style:
                      AppTextStyles.caption.copyWith(fontSize: 11),
                ),
              ],
            ),
            Row(
              children: [
                Text(
                  order.total,
                  style: AppTextStyles.h3
                      .copyWith(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const SizedBox(width: AppDimensions.sm),
                Icon(
                  expanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  size: 18,
                  color: expanded ? chevronColor : AppColors.textHint,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Body ─────────────────────────────────────────────────────────────────────

class _OrderBody extends StatelessWidget {
  final SupportOrder order;
  final VoidCallback? onSeeDetails;

  const _OrderBody({required this.order, this.onSeeDetails});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Items list
          if (order.items.isNotEmpty) ...[
            Text(
              'ITEMS',
              style: AppTextStyles.label
                  .copyWith(color: AppColors.textHint, letterSpacing: 0.5),
            ),
            const SizedBox(height: 6),
            ...order.items.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: _ItemRow(item: item),
                )),
            const SizedBox(height: 4),
            const Divider(color: AppColors.border),
          ],
          // Delivery slot
          if (order.deliverySlot != null) ...[
            _LabelValueRow(label: 'Delivery Slot', value: order.deliverySlot!),
            const SizedBox(height: 4),
            const Divider(color: AppColors.border),
          ],
          // Total
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total',
                  style: AppTextStyles.bodySemiBold
                      .copyWith(fontWeight: FontWeight.w700)),
              Text(order.total,
                  style:
                      AppTextStyles.h3.copyWith(fontSize: 16)),
            ],
          ),
          // ── Cancelled: refund box + manual refund button (hidden for COD) ───
          if (order.status == SupportOrderStatus.cancelled) ...[
            const SizedBox(height: AppDimensions.sm),
            const Divider(color: AppColors.border),
            const SizedBox(height: AppDimensions.sm),
            _RefundStatusBox(order: order),
            if (!order.isCodNoRefund) ...[
              const SizedBox(height: AppDimensions.sm),
              _CsActionButton(
                icon: Icons.undo_rounded,
                label: 'Initiate Manual Refund',
                bgColor: AppColors.error,
                fgColor: Colors.white,
                onTap: () {},
              ),
            ],
          ],
          // ── Pending: cancel + reschedule + expected delivery ──────────────
          if (order.status == SupportOrderStatus.pending) ...[
            const SizedBox(height: AppDimensions.sm),
            Row(
              children: [
                Expanded(
                  child: _CsActionButton(
                    icon: Icons.cancel_outlined,
                    label: 'Cancel',
                    bgColor: AppColors.errorLight,
                    fgColor: AppColors.error,
                    borderColor: AppColors.error,
                    onTap: () {},
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _CsActionButton(
                    icon: Icons.schedule_rounded,
                    label: 'Reschedule',
                    bgColor: AppColors.primaryLight,
                    fgColor: AppColors.primary,
                    borderColor: AppColors.primary,
                    onTap: () {},
                  ),
                ),
              ],
            ),
            if (order.expectedDelivery != null) ...[
              const SizedBox(height: AppDimensions.sm),
              _LabelValueRow(
                  label: 'Expected Delivery', value: order.expectedDelivery!),
            ],
          ],
          // ── See Full Details ───────────────────────────────────────────────
          if (onSeeDetails != null) ...[
            const SizedBox(height: AppDimensions.sm),
            const Divider(color: AppColors.border),
            const SizedBox(height: AppDimensions.xs),
            GestureDetector(
              onTap: onSeeDetails,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.open_in_new_rounded,
                      size: 13, color: AppColors.primary),
                  const SizedBox(width: 5),
                  Text(
                    'See Full Details',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Reusable sub-widgets ─────────────────────────────────────────────────────

class _ItemRow extends StatelessWidget {
  final SupportOrderItem item;

  const _ItemRow({required this.item});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(item.name,
            style:
                AppTextStyles.caption.copyWith(color: AppColors.textPrimary)),
        Text(item.price,
            style: AppTextStyles.caption.copyWith(
                color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _LabelValueRow extends StatelessWidget {
  final String label;
  final String value;

  const _LabelValueRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTextStyles.caption),
        Text(value,
            style: AppTextStyles.caption.copyWith(
                color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _RefundStatusBox extends StatelessWidget {
  final SupportOrder order;

  const _RefundStatusBox({required this.order});

  @override
  Widget build(BuildContext context) {
    final isCodNoRefund = order.isCodNoRefund;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isCodNoRefund
            ? AppColors.surface
            : AppColors.errorLight,
        borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
        border: Border.all(
          color: isCodNoRefund ? AppColors.border : AppColors.error,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Refund Status',
                style: AppTextStyles.caption.copyWith(
                    color: isCodNoRefund
                        ? AppColors.textSecondary
                        : AppColors.error,
                    fontWeight: FontWeight.w600),
              ),
              if (!isCodNoRefund)
                Icon(Icons.info_outline_rounded,
                    size: 14, color: AppColors.error),
            ],
          ),
          if (isCodNoRefund) ...[
            const SizedBox(height: 6),
            Text(
              'Refund Not Required (COD)',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ] else ...[
            if (order.refundAmount != null) ...[
              const SizedBox(height: 6),
              _RefundDetailRow(
                  label: 'Refund Amount', value: order.refundAmount!),
            ],
            if (order.refundDestination != null)
              _RefundDetailRow(
                  label: 'Destination', value: order.refundDestination!),
            if (order.refundDate != null)
              _RefundDetailRow(
                  label: 'Processed On', value: order.refundDate!),
          ],
        ],
      ),
    );
  }
}

class _RefundDetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _RefundDetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style:
                  AppTextStyles.caption.copyWith(color: AppColors.error)),
          Text(value,
              style: AppTextStyles.caption.copyWith(
                  color: AppColors.error, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

/// Generic action button used in order cards (cancel, reschedule, refund).
class _CsActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color bgColor;
  final Color fgColor;
  final Color? borderColor;
  final VoidCallback onTap;

  const _CsActionButton({
    required this.icon,
    required this.label,
    required this.bgColor,
    required this.fgColor,
    this.borderColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 36,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
          border:
              borderColor != null ? Border.all(color: borderColor!) : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: fgColor),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTextStyles.caption.copyWith(
                color: fgColor,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
