import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/models/rider.dart';
import '../../../core/models/rider_detail.dart';
import '../../deliveries/providers/deliveries_provider.dart';
import '../../../core/providers/nav_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/riders_provider.dart';

// ── Screen ─────────────────────────────────────────────────────────────────────

class RiderDetailsScreen extends ConsumerStatefulWidget {
  final Rider rider;

  const RiderDetailsScreen({super.key, required this.rider});

  @override
  ConsumerState<RiderDetailsScreen> createState() => _RiderDetailsScreenState();
}

class _RiderDetailsScreenState extends ConsumerState<RiderDetailsScreen> {
  int _selectedShiftTab = 0;

  @override
  Widget build(BuildContext context) {
    final rider = widget.rider;
    final detailAsync = ref.watch(riderDetailProvider(rider.id));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(rider),
      body: detailAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline_rounded, color: AppColors.error, size: 40),
              const SizedBox(height: AppDimensions.sm),
              Text('Failed to load rider details',
                  style: AppTextStyles.bodyMedium),
              const SizedBox(height: AppDimensions.sm),
              TextButton(
                onPressed: () =>
                    ref.invalidate(riderDetailProvider(rider.id)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (detail) => Column(
          children: [
            Expanded(
              child: RefreshIndicator(
                onRefresh: () =>
                    ref.refresh(riderDetailProvider(rider.id).future),
                color: AppColors.primary,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(
                    AppDimensions.base,
                    AppDimensions.base,
                    AppDimensions.base,
                    AppDimensions.base,
                  ),
                  children: [
                  _ProfileCard(rider: rider),
                  const SizedBox(height: AppDimensions.xl),
                  _sectionLabel('TODAY\'S SHIFT'),
                  const SizedBox(height: AppDimensions.sm),
                  _ShiftCard(
                    detail: detail,
                    isOnline: rider.isOnline,
                    selectedTab: _selectedShiftTab,
                    onTabChanged: (i) => setState(() => _selectedShiftTab = i),
                  ),
                  const SizedBox(height: AppDimensions.xl),
                  _sectionLabel('TODAY\'S ACTIVITY'),
                  const SizedBox(height: AppDimensions.sm),
                  _ActivityGrid(detail: detail),
                  const SizedBox(height: AppDimensions.xl),
                  _sectionLabel('CASH COLLECTION'),
                  const SizedBox(height: AppDimensions.sm),
                  _CashCollectionCard(detail: detail),
                  const SizedBox(height: AppDimensions.xl),
                  _sectionLabel('TODAY\'S EARNINGS'),
                  const SizedBox(height: AppDimensions.sm),
                  _EarningsCard(detail: detail),
                  const SizedBox(height: AppDimensions.base),
                ],
              ),
            ),
          ),
            _ViewAllDeliveriesButton(riderName: rider.name),
          ],
        ),
      ),
    );
  }

  AppBar _buildAppBar(Rider rider) {
    return AppBar(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 1,
      shadowColor: Colors.black12,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded),
        color: AppColors.textPrimary,
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Rider Details', style: AppTextStyles.h3),
          const SizedBox(height: 2),
          Row(
            children: [
              Text(
                'Today\'s Shift',
                style: AppTextStyles.caption
                    .copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(width: AppDimensions.xs),
              _StatusPill(
                label: rider.isOnline ? 'Active' : 'Offline',
                color: rider.isOnline ? AppColors.success : AppColors.textMuted,
                bgColor: rider.isOnline
                    ? AppColors.successLight
                    : AppColors.neutralLight,
              ),
            ],
          ),
        ],
      ),
      toolbarHeight: 68,
    );
  }

  Widget _sectionLabel(String text) => Text(
        text,
        style: AppTextStyles.label.copyWith(
          color: AppColors.textSecondary,
          letterSpacing: 0.8,
        ),
      );
}

// ── Profile Card ──────────────────────────────────────────────────────────────

class _ProfileCard extends StatelessWidget {
  final Rider rider;
  const _ProfileCard({required this.rider});

  @override
  Widget build(BuildContext context) {
    final phone = rider.phoneNumber ?? '—';

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar + name row
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: rider.avatarColor,
                child: Text(
                  rider.initials,
                  style: AppTextStyles.h3.copyWith(
                    color: Colors.white,
                    fontSize: 18,
                  ),
                ),
              ),
              const SizedBox(width: AppDimensions.base),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(rider.name, style: AppTextStyles.h3),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Icon(Icons.verified_user_rounded,
                            size: 13, color: AppColors.textMuted),
                        const SizedBox(width: 4),
                        Text(
                          rider.isOnline ? 'On Duty' : 'Off Duty',
                          style: AppTextStyles.caption,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.md),

          // Phone + Call row
          Row(
            children: [
              Expanded(
                child: _OutlinedChip(
                  icon: Icons.phone_rounded,
                  label: phone,
                  iconColor: AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: AppDimensions.sm),
              SizedBox(
                height: 36,
                child: ElevatedButton.icon(
                  onPressed: phone == '—'
                      ? null
                      : () => launchUrl(Uri.parse('tel:$phone')),
                  icon: const Icon(Icons.call_rounded, size: 16),
                  label: const Text('Call'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.md,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppDimensions.radiusFull),
                    ),
                    textStyle: AppTextStyles.captionBold
                        .copyWith(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.sm),

          // Locate Rider button
          SizedBox(
            width: double.infinity,
            height: 42,
            child: OutlinedButton.icon(
              onPressed: () {},
              icon: Icon(Icons.location_on_rounded,
                  size: 18, color: AppColors.primary),
              label: Text(
                'Locate Rider',
                style: AppTextStyles.bodyMedium
                    .copyWith(color: AppColors.primary),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                    color: AppColors.primary.withValues(alpha: 0.4)),
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(AppDimensions.radiusMd),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Shift Card ────────────────────────────────────────────────────────────────

class _ShiftCard extends StatelessWidget {
  final RiderDetail detail;
  final bool isOnline;
  final int selectedTab;
  final ValueChanged<int> onTabChanged;

  const _ShiftCard({
    required this.detail,
    required this.isOnline,
    required this.selectedTab,
    required this.onTabChanged,
  });

  @override
  Widget build(BuildContext context) {
    final startedAt = detail.shiftStartedAt;
    final String startTimeStr;
    final String startStatusStr;
    final String checkOffStr;
    final String checkOffStatusStr;
    final String durationStr;
    final String durationStatusStr;

    if (isOnline && startedAt != null) {
      startTimeStr = _fmtTime(startedAt);
      startStatusStr = 'On Time';
      checkOffStr = 'Pending';
      checkOffStatusStr = 'Pending';
      final elapsed = DateTime.now().difference(startedAt);
      durationStr = _fmtDuration(elapsed);
      durationStatusStr = 'Ongoing';
    } else if (!isOnline && startedAt != null) {
      startTimeStr = _fmtTime(startedAt);
      startStatusStr = 'Recorded';
      checkOffStr = 'Done';
      checkOffStatusStr = 'Completed';
      durationStr = '—';
      durationStatusStr = 'Ended';
    } else {
      startTimeStr = '—';
      startStatusStr = 'Not started';
      checkOffStr = '—';
      checkOffStatusStr = '—';
      durationStr = '—';
      durationStatusStr = 'Off Duty';
    }

    return _Card(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          // Tab selector
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppDimensions.base,
              AppDimensions.md,
              AppDimensions.base,
              0,
            ),
            child: _SegmentedTabs(
              tabs: const ['Morning Shift', 'On Duty'],
              selected: selectedTab,
              onChanged: onTabChanged,
            ),
          ),
          const SizedBox(height: AppDimensions.base),

          // Stats row
          IntrinsicHeight(
            child: Row(
              children: [
                Expanded(
                  child: _ShiftStat(
                    label: 'Start Time',
                    value: startTimeStr,
                    subLabel: startStatusStr,
                    subColor: AppColors.success,
                  ),
                ),
                VerticalDivider(
                    width: 1, color: AppColors.border, thickness: 1),
                Expanded(
                  child: _ShiftStat(
                    label: 'Check-off',
                    value: checkOffStr,
                    subLabel: checkOffStatusStr,
                    subColor: AppColors.warning,
                  ),
                ),
                VerticalDivider(
                    width: 1, color: AppColors.border, thickness: 1),
                Expanded(
                  child: _ShiftStat(
                    label: 'Duration',
                    value: durationStr,
                    subLabel: durationStatusStr,
                    subColor: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppDimensions.base),
        ],
      ),
    );
  }

  static String _fmtTime(DateTime dt) {
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final m = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour < 12 ? 'AM' : 'PM';
    return '$h:$m $period';
  }

  static String _fmtDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    if (h > 0) return '${h}h ${m}m';
    return '${m}m';
  }
}

class _ShiftStat extends StatelessWidget {
  final String label;
  final String value;
  final String subLabel;
  final Color subColor;

  const _ShiftStat({
    required this.label,
    required this.value,
    required this.subLabel,
    required this.subColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.sm,
        vertical: AppDimensions.sm,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: AppTextStyles.bodySemiBold.copyWith(fontSize: 15),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(label,
              style: AppTextStyles.caption, textAlign: TextAlign.center),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.sm,
              vertical: 2,
            ),
            decoration: BoxDecoration(
              color: subColor.withValues(alpha: 0.1),
              borderRadius:
                  BorderRadius.circular(AppDimensions.radiusFull),
            ),
            child: Text(
              subLabel,
              style: AppTextStyles.label.copyWith(
                color: subColor,
                letterSpacing: 0,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Activity Grid ─────────────────────────────────────────────────────────────

class _ActivityGrid extends StatelessWidget {
  final RiderDetail detail;
  const _ActivityGrid({required this.detail});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _ActivityCard(
                label: 'Assigned',
                count: detail.assigned,
                color: AppColors.primary,
                bgColor: AppColors.primaryLight,
                icon: Icons.assignment_rounded,
              ),
            ),
            const SizedBox(width: AppDimensions.sm),
            Expanded(
              child: _ActivityCard(
                label: 'Delivered',
                count: detail.delivered,
                color: AppColors.success,
                bgColor: AppColors.successLight,
                icon: Icons.check_circle_rounded,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.sm),
        Row(
          children: [
            Expanded(
              child: _ActivityCard(
                label: 'Rejected',
                count: detail.rejected,
                color: AppColors.error,
                bgColor: AppColors.errorLight,
                icon: Icons.cancel_rounded,
              ),
            ),
            const SizedBox(width: AppDimensions.sm),
            Expanded(
              child: _ActivityCard(
                label: 'Cancelled',
                count: detail.cancelled,
                color: AppColors.warning,
                bgColor: AppColors.warningLight,
                icon: Icons.remove_circle_rounded,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ActivityCard extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  final Color bgColor;
  final IconData icon;

  const _ActivityCard({
    required this.label,
    required this.count,
    required this.color,
    required this.bgColor,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.base),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: AppDimensions.sm),
          Text(
            '$count',
            style: AppTextStyles.statValue.copyWith(
              color: color,
              fontSize: 28,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: color.withValues(alpha: 0.75),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Earnings Card ─────────────────────────────────────────────────────────────

class _EarningsCard extends StatelessWidget {
  final RiderDetail detail;
  const _EarningsCard({required this.detail});

  @override
  Widget build(BuildContext context) {
    final hasEarnings = detail.earningsTotal > 0;

    return _Card(
      child: Column(
        children: [
          // Header
          Row(
            children: [
              Text('Today\'s Earnings', style: AppTextStyles.bodySemiBold),
              const Spacer(),
              Text(
                '₹${detail.earningsTotal.toStringAsFixed(0)}',
                style: AppTextStyles.h3.copyWith(
                  color: hasEarnings ? AppColors.primary : AppColors.textMuted,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.md),
          const Divider(color: AppColors.divider, height: 1),
          const SizedBox(height: AppDimensions.md),

          // Delivery earnings row
          _EarningsRow(
            icon: Icons.delivery_dining_rounded,
            iconColor: AppColors.primary,
            label: 'Delivery Pay',
            sublabel: detail.earningsDeliveryCount > 0
                ? '${detail.earningsDeliveryCount} deliveries'
                : 'No deliveries yet',
            amount: detail.earningsDelivery,
          ),
          const SizedBox(height: AppDimensions.md),

          // Wait time earnings row
          _EarningsRow(
            icon: Icons.timer_outlined,
            iconColor: AppColors.warning,
            label: 'Wait Time Bonus',
            sublabel: 'Customer wait allowance',
            amount: detail.earningsWait,
          ),
        ],
      ),
    );
  }
}

class _EarningsRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String sublabel;
  final double amount;

  const _EarningsRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.sublabel,
    required this.amount,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
          ),
          child: Icon(icon, size: 18, color: iconColor),
        ),
        const SizedBox(width: AppDimensions.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppTextStyles.bodyMedium),
              Text(sublabel, style: AppTextStyles.caption),
            ],
          ),
        ),
        Text(
          '₹${amount.toStringAsFixed(0)}',
          style: AppTextStyles.bodySemiBold.copyWith(
            color: amount > 0 ? AppColors.textPrimary : AppColors.textMuted,
          ),
        ),
      ],
    );
  }
}

// ── Cash Collection Card ──────────────────────────────────────────────────────

class _CashCollectionCard extends StatelessWidget {
  final RiderDetail detail;
  const _CashCollectionCard({required this.detail});

  @override
  Widget build(BuildContext context) {
    final totalCollected = detail.totalCollected;

    return _Card(
      child: Column(
        children: [
          // Summary header — total collected so far
          Row(
            children: [
              Text('Cash Summary', style: AppTextStyles.bodySemiBold),
              const Spacer(),
              Text(
                '₹${_fmt(totalCollected)}',
                style: AppTextStyles.h3.copyWith(
                  color: AppColors.success,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.md),
          const Divider(color: AppColors.divider, height: 1),
          const SizedBox(height: AppDimensions.md),

          // Total to collect (all COD orders)
          _CashRow(
            icon: Icons.receipt_long_rounded,
            iconColor: AppColors.textSecondary,
            label: 'Total to Collect',
            sublabel: '${detail.codOrderCount} COD orders',
            amount: detail.codTotal,
            amountColor: AppColors.textPrimary,
          ),
          const SizedBox(height: AppDimensions.md),

          // Collected via UPI / QR
          _CashRow(
            icon: Icons.qr_code_scanner_rounded,
            iconColor: AppColors.primary,
            label: 'Collected Online (QR)',
            sublabel: detail.codCollectedUpiCount > 0
                ? '${detail.codCollectedUpiCount} orders · UPI'
                : 'UPI / QR',
            amount: detail.codCollectedUpi,
            amountColor: AppColors.primary,
          ),
          const SizedBox(height: AppDimensions.md),

          // Collected in cash
          _CashRow(
            icon: Icons.payments_rounded,
            iconColor: AppColors.warning,
            label: 'Collected in Cash',
            sublabel: detail.codCollectedCashCount > 0
                ? '${detail.codCollectedCashCount} orders · COD'
                : 'COD',
            amount: detail.codCollectedCash,
            amountColor: AppColors.warning,
          ),

          if (detail.codPending > 0) ...[
            const SizedBox(height: AppDimensions.md),
            _CashRow(
              icon: Icons.hourglass_empty_rounded,
              iconColor: AppColors.error,
              label: 'Pending Collection',
              sublabel: 'Not yet delivered',
              amount: detail.codPending,
              amountColor: AppColors.error,
            ),
          ],
        ],
      ),
    );
  }

  static String _fmt(double v) {
    if (v >= 1000) {
      return '${(v / 1000).toStringAsFixed(v % 1000 == 0 ? 0 : 1)}K';
    }
    return v.toStringAsFixed(0);
  }
}

class _CashRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String sublabel;
  final double amount;
  final Color amountColor;

  const _CashRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.sublabel,
    required this.amount,
    required this.amountColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
          ),
          child: Icon(icon, size: 18, color: iconColor),
        ),
        const SizedBox(width: AppDimensions.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppTextStyles.bodyMedium),
              Text(sublabel, style: AppTextStyles.caption),
            ],
          ),
        ),
        Text(
          '₹${amount.toStringAsFixed(0)}',
          style: AppTextStyles.bodySemiBold.copyWith(color: amountColor),
        ),
      ],
    );
  }
}

// ── View All Deliveries Button ────────────────────────────────────────────────

class _ViewAllDeliveriesButton extends ConsumerWidget {
  final String riderName;
  const _ViewAllDeliveriesButton({required this.riderName});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      color: AppColors.surface,
      padding: EdgeInsets.fromLTRB(
        AppDimensions.base,
        AppDimensions.sm,
        AppDimensions.base,
        AppDimensions.sm + MediaQuery.of(context).padding.bottom,
      ),
      child: SizedBox(
        width: double.infinity,
        height: 46,
        child: ElevatedButton.icon(
          onPressed: () => _viewDeliveries(ref, context),
          icon: const Icon(Icons.list_alt_rounded, size: 18),
          label: const Text('View All Deliveries'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(AppDimensions.radiusMd),
            ),
            textStyle: AppTextStyles.bodySemiBold
                .copyWith(color: Colors.white),
          ),
        ),
      ),
    );
  }

  void _viewDeliveries(WidgetRef ref, BuildContext context) {
    ref.read(deliveryFilterProvider.notifier).state = DeliveryFilterStatus.all;
    ref.read(deliverySelectedPincodeProvider.notifier).state = null;
    ref.read(deliveryOrderIdQueryProvider.notifier).state = '';
    ref.read(deliveryPaymentFilterProvider.notifier).state =
        DeliveryPaymentFilter.all;
    ref.read(deliverySortByProvider.notifier).state = DeliverySortBy.none;
    ref.read(deliveryRiderQueryProvider.notifier).state = riderName;
    ref.read(navIndexProvider.notifier).state = 4;
    Navigator.of(context).popUntil((route) => route.isFirst);
  }
}

// ── Shared helper widgets ─────────────────────────────────────────────────────

class _Card extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;

  const _Card({required this.child, this.padding});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding ??
          const EdgeInsets.all(AppDimensions.base),
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
      child: child,
    );
  }
}

class _OutlinedChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color iconColor;

  const _OutlinedChip({
    required this.icon,
    required this.label,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.sm),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: iconColor),
          const SizedBox(width: AppDimensions.xs),
          Flexible(
            child: Text(
              label,
              style: AppTextStyles.caption
                  .copyWith(color: AppColors.textSecondary),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _SegmentedTabs extends StatelessWidget {
  final List<String> tabs;
  final int selected;
  final ValueChanged<int> onChanged;

  const _SegmentedTabs({
    required this.tabs,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
      ),
      child: Row(
        children: List.generate(tabs.length, (i) {
          final isActive = i == selected;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: isActive ? AppColors.surface : Colors.transparent,
                  borderRadius:
                      BorderRadius.circular(AppDimensions.radiusSm),
                  boxShadow: isActive
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: Text(
                    tabs[i],
                    style: isActive
                        ? AppTextStyles.captionBold.copyWith(
                            color: AppColors.textPrimary,
                          )
                        : AppTextStyles.caption,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String label;
  final Color color;
  final Color bgColor;

  const _StatusPill({
    required this.label,
    required this.color,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTextStyles.label
                .copyWith(color: color, letterSpacing: 0),
          ),
        ],
      ),
    );
  }
}
