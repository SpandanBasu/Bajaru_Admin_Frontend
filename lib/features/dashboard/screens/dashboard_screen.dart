import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/dashboard_provider.dart';
import '../../../core/providers/nav_provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../widgets/common/admin_app_bar.dart';
import '../../../widgets/common/admin_drawer.dart';
import '../../../widgets/common/stat_card.dart';
import '../../../widgets/common/warehouse_dropdown.dart';
import '../../../widgets/common/section_header.dart';
import '../../../widgets/dashboard/phase_badge.dart';
import '../../../widgets/dashboard/completed_delivery_tile.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  Future<void> _pickDate(BuildContext context, WidgetRef ref) async {
    final current = ref.read(dashboardSelectedDateProvider);
    final today = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(today.year, today.month - 3, 1),
      lastDate: today,
      helpText: 'Select date to view',
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.light(
            primary: AppColors.primary,
            onPrimary: Colors.white,
            surface: AppColors.surface,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      ref.read(dashboardSelectedDateProvider.notifier).state = DateTime(
        picked.year,
        picked.month,
        picked.day,
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats       = ref.watch(dashboardStatsProvider);
    final selectedDate = ref.watch(dashboardSelectedDateProvider);
    final isToday     = _isToday(selectedDate);
    final fmt = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 0,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      drawer: const AdminDrawer(),
      appBar: AdminAppBar(
        title: 'Bajaru Admin',
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
            color: AppColors.textSecondary,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {},
        child: ListView(
          padding: const EdgeInsets.all(AppDimensions.base),
          children: [
            // Warehouse selector
            const WarehouseDropdown(),
            const SizedBox(height: AppDimensions.md),

            // Phase badge + tappable date selector
            Row(
              children: [
                PhaseBadge(phase: stats.phase),
                const Spacer(),
                GestureDetector(
                  onTap: () => _pickDate(context, ref),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.md,
                      vertical: AppDimensions.xs + 1,
                    ),
                    decoration: BoxDecoration(
                      color: isToday
                          ? AppColors.surface
                          : AppColors.warningLight,
                      borderRadius:
                          BorderRadius.circular(AppDimensions.radiusFull),
                      border: Border.all(
                        color: isToday
                            ? AppColors.border
                            : AppColors.warning,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.calendar_today_rounded,
                          size: 13,
                          color: isToday
                              ? AppColors.textSecondary
                              : AppColors.warning,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          isToday
                              ? 'Today'
                              : DateFormat('d MMM yyyy').format(selectedDate),
                          style: AppTextStyles.captionMedium.copyWith(
                            color: isToday
                                ? AppColors.textSecondary
                                : AppColors.warning,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.expand_more_rounded,
                          size: 15,
                          color: isToday
                              ? AppColors.textSecondary
                              : AppColors.warning,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // Past-date banner
            if (!isToday) ...[
              const SizedBox(height: AppDimensions.sm),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.md,
                  vertical: AppDimensions.sm,
                ),
                decoration: BoxDecoration(
                  color: AppColors.warningLight,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                  border: Border.all(color: AppColors.warning),
                ),
                child: Row(
                  children: [
                    Icon(Icons.history_rounded,
                        size: 16, color: AppColors.warning),
                    const SizedBox(width: AppDimensions.sm),
                    Expanded(
                      child: Text(
                        'Viewing history for ${DateFormat('EEEE, d MMMM yyyy').format(selectedDate)}',
                        style: AppTextStyles.caption
                            .copyWith(color: AppColors.warning),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        final now = DateTime.now();
                        ref
                            .read(dashboardSelectedDateProvider.notifier)
                            .state = DateTime(now.year, now.month, now.day);
                      },
                      child: Text(
                        'Back to Today',
                        style: AppTextStyles.captionMedium.copyWith(
                          color: AppColors.warning,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: AppDimensions.base),

            // Stats grid
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: AppDimensions.md,
              mainAxisSpacing: AppDimensions.md,
              childAspectRatio: 1.15,
              children: [
                StatCard(
                  label: 'Total Orders',
                  value: '${stats.totalOrders}',
                  icon: Icons.receipt_long_rounded,
                  iconColor: AppColors.primary,
                  iconBg: AppColors.primaryLight,
                ),
                StatCard(
                  label: 'Revenue',
                  value: fmt.format(stats.totalRevenue),
                  icon: Icons.currency_rupee_rounded,
                  iconColor: AppColors.success,
                  iconBg: AppColors.successLight,
                ),
                StatCard(
                  label: 'Pending Items',
                  value: '${stats.pendingItems}',
                  icon: Icons.pending_actions_rounded,
                  iconColor: AppColors.warning,
                  iconBg: AppColors.warningLight,
                ),
                StatCard(
                  label: 'Available Riders',
                  value: '${stats.availableRiders}',
                  icon: Icons.directions_bike_rounded,
                  iconColor: const Color(0xFF9C27B0),
                  iconBg: const Color(0xFFF3E5F5),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.xl),

            // Action card — only show for today
            if (isToday) ...[
              GestureDetector(
                onTap: () => ref.read(navIndexProvider.notifier).state = 1,
                child: Container(
                  padding: const EdgeInsets.all(AppDimensions.base),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primary,
                        AppColors.primary.withValues(alpha: 0.8),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius:
                        BorderRadius.circular(AppDimensions.radiusLg),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.shopping_basket_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                      const SizedBox(width: AppDimensions.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Procurement List Ready',
                              style: AppTextStyles.bodySemiBold
                                  .copyWith(color: Colors.white),
                            ),
                            Text(
                              '${stats.procurementItemCount} items to procure today',
                              style: AppTextStyles.caption
                                  .copyWith(color: Colors.white70),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppDimensions.xl),
            ],

            // Deliveries section — show top 3 on dashboard, See All goes to Deliveries tab
            SectionHeader(
              title: isToday ? 'Recent Deliveries' : 'Completed Deliveries',
              actionLabel: 'See All',
              onAction: () => ref.read(navIndexProvider.notifier).state = 4,
            ),
            const SizedBox(height: AppDimensions.md),
            for (final d in stats.completedDeliveries.take(3)) ...[
              CompletedDeliveryTile(delivery: d),
              const SizedBox(height: AppDimensions.sm),
            ],
            const SizedBox(height: AppDimensions.base),
          ],
        ),
      ),
    );
  }
}
