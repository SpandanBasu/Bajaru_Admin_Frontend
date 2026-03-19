import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/riders_provider.dart';
import '../../deliveries/providers/deliveries_provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/providers/nav_provider.dart';
import '../../../widgets/common/admin_drawer.dart';
import '../../../widgets/common/section_header.dart';
import '../../../widgets/common/warehouse_dropdown.dart';
import '../../../widgets/riders/shift_timer_card.dart';
import '../../../widgets/riders/rider_batch_card.dart';
import '../../../widgets/riders/rider_tile.dart';
import './rider_details_screen.dart';

class RidersScreen extends ConsumerWidget {
  const RidersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final batches = ref.watch(riderBatchesProvider);
    final allRiders = ref.watch(ridersProvider);
    final activeDeliveriesAsync = ref.watch(activeDeliveriesProvider);
    final ridersError = ref.watch(ridersErrorProvider);
    final onlineCount = allRiders.where((r) => r.isOnline).length;

    // On-duty count: distinct riders who are either online OR have an active batch.
    // Use a key set to avoid double-counting riders present in both lists.
    final onDutyKeys = <String>{
      for (final r in allRiders.where((r) => r.isOnline)) r.userId ?? r.id,
      for (final b in batches) b.rider.userId ?? b.rider.id,
    };
    final onDutyCount = onDutyKeys.length;

    return Scaffold(
      backgroundColor: AppColors.background,
      drawer: const AdminDrawer(),
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 1,
        shadowColor: Colors.black12,
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu_rounded),
            color: AppColors.textSecondary,
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
        titleSpacing: AppDimensions.base,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Rider Dispatch', style: AppTextStyles.h2),
            Text(
              'Morning Shift  ·  $onDutyCount on duty',
              style: AppTextStyles.caption
                  .copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
        toolbarHeight: 68,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 14,
              horizontal: AppDimensions.xs,
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.sm,
              ),
              decoration: BoxDecoration(
                color: AppColors.successLight,
                borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: AppColors.success,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '$onlineCount Online',
                    style: AppTextStyles.captionBold
                        .copyWith(color: AppColors.success),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: AppDimensions.xs),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Warehouse filter (sticky) ──────────────────────────────────
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.fromLTRB(
              AppDimensions.base,
              AppDimensions.sm,
              AppDimensions.base,
              AppDimensions.md,
            ),
            child: const WarehouseDropdown(),
          ),
          const Divider(height: 1, color: AppColors.border),

          // ── Main scrollable content ───────────────────────────────────────
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                await Future.wait([
                  ref.read(ridersProvider.notifier).refresh(),
                  ref.refresh(activeDeliveriesProvider.future),
                ]);
              },
              color: AppColors.primary,
              child: ListView(
                padding: const EdgeInsets.all(AppDimensions.base),
                children: [
                  // Error banner
                  if (ridersError != null) ...[
                    _ErrorBanner(message: ridersError),
                    const SizedBox(height: AppDimensions.sm),
                  ],

                  // Shift timer card
                  const ShiftTimerCard(),
                  const SizedBox(height: AppDimensions.xl),

                  // ── Rider Batches ─────────────────────────────────────────
                  SectionHeader(title: 'Rider Batches'),
                  const SizedBox(height: AppDimensions.sm),
                  activeDeliveriesAsync.when(
                    loading: () => const Padding(
                      padding: EdgeInsets.symmetric(
                        vertical: AppDimensions.xl,
                      ),
                      child: Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                    error: (_, __) => const _EmptyCard(
                      message: 'Unable to load active deliveries',
                    ),
                    data: (_) => batches.isEmpty
                        ? const _EmptyCard(
                            message: 'No riders with assigned orders',
                          )
                        : Column(
                            children: [
                              for (final batch in batches) ...[
                                RiderBatchCard(
                                  batch: batch,
                                  onTap: () => _openRiderDeliveries(
                                    ref,
                                    batch.rider.name,
                                  ),
                                ),
                                const SizedBox(height: AppDimensions.sm),
                              ],
                            ],
                          ),
                  ),
                  const SizedBox(height: AppDimensions.xl),

                  // ── Clocked-In Riders ─────────────────────────────────────
                  SectionHeader(title: 'Clocked-In Riders'),
                  const SizedBox(height: AppDimensions.sm),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius:
                          BorderRadius.circular(AppDimensions.radiusLg),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: allRiders.isEmpty
                        ? Padding(
                            padding:
                                const EdgeInsets.all(AppDimensions.base),
                            child: Text(
                              'No riders clocked in',
                              style: AppTextStyles.body.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          )
                        : Column(
                            children: [
                              for (final rider in allRiders)
                                RiderTile(
                                  rider: rider,
                                  onToggleOnline: () => ref
                                      .read(ridersProvider.notifier)
                                      .toggleOnline(rider.id),
                                  onTap: () => Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          RiderDetailsScreen(rider: rider),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                  ),
                  const SizedBox(height: AppDimensions.base),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Pre-filters deliveries by rider name and switches to the Deliveries tab.
  void _openRiderDeliveries(WidgetRef ref, String riderName) {
    ref.read(deliveryFilterProvider.notifier).state = DeliveryFilterStatus.all;
    ref.read(deliveryOrderIdQueryProvider.notifier).state = '';
    ref.read(deliveryPaymentFilterProvider.notifier).state =
        DeliveryPaymentFilter.all;
    ref.read(deliverySortByProvider.notifier).state = DeliverySortBy.none;
    ref.read(deliveryRiderQueryProvider.notifier).state = riderName;
    ref.read(navIndexProvider.notifier).state = 4;
  }
}

// ── Local helper widgets ───────────────────────────────────────────────────────

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.sm),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
      ),
      child: Text(
        message,
        style: AppTextStyles.caption.copyWith(color: AppColors.error),
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  final String message;
  const _EmptyCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.base),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
      ),
      child: Text(
        message,
        style:
            AppTextStyles.body.copyWith(color: AppColors.textSecondary),
      ),
    );
  }
}
