import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/procurement_provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/models/procurement_item.dart';
import '../../../widgets/procurement/procurement_item_tile.dart';
import '../../../widgets/common/admin_drawer.dart';
import '../../../widgets/common/pincode_dropdown.dart';

class ProcurementScreen extends ConsumerWidget {
  const ProcurementScreen({super.key});

  void _showDownloadSheet(BuildContext context, List<ProcurementItem> items) {
    final lines = items.map((item) {
      final qty = item.toProcure % 1 == 0
          ? item.toProcure.toInt().toString()
          : item.toProcure.toStringAsFixed(1);
      return '${item.name}: $qty ${item.unit}';
    }).join('\n');

    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _DownloadSheet(content: lines),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items         = ref.watch(filteredProcurementProvider);
    final allItems      = ref.watch(procurementProvider);
    final summary       = ref.watch(procurementSummaryProvider);
    final selectionType = ref.watch(procurementSelectionTypeProvider);
    final selectedPin   = ref.watch(procurementSelectedPincodeProvider);
    final notifier      = ref.read(procurementProvider.notifier);

    // unique pincodes from the full list
    final pincodes = allItems.map((i) => i.pincodeCode).toSet().toList()..sort();

    return Scaffold(
      backgroundColor: AppColors.background,
      drawer: const AdminDrawer(),
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 1,
        shadowColor: Colors.black12,
        titleSpacing: AppDimensions.base,
        toolbarHeight: 68,
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu_rounded),
            color: AppColors.textSecondary,
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Procurement', style: AppTextStyles.h2),
            Text(
              DateFormat('EEEE, d MMMM y').format(DateTime.now()),
              style: AppTextStyles.caption
                  .copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded),
            color: AppColors.textSecondary,
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.download_rounded),
            color: AppColors.textSecondary,
            tooltip: 'Download list',
            onPressed: () => _showDownloadSheet(context, items),
          ),
          const SizedBox(width: AppDimensions.xs),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Pincode dropdown ──────────────────────────────────────────
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
              selected: selectedPin,
              onChanged: (val) => ref
                  .read(procurementSelectedPincodeProvider.notifier)
                  .state = val,
              allLabel: 'All Godowns',
            ),
          ),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: AppDimensions.md),

          // ── Stats card ────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.base),
            child: _StatsCard(summary: summary),
          ),
          const SizedBox(height: AppDimensions.md),

          // ── Section header ────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.base),
            child: Row(
              children: [
                Text(
                  'PROCUREMENT ITEMS',
                  style: AppTextStyles.label.copyWith(
                    color: AppColors.textSecondary,
                    letterSpacing: 1.0,
                  ),
                ),
                const Spacer(),
                Text(
                  '${summary.procuredCount} procured',
                  style: AppTextStyles.captionMedium
                      .copyWith(color: AppColors.success),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppDimensions.xs),

          // ── Items list ────────────────────────────────────────────────
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => notifier.refresh(pincode: selectedPin),
              color: AppColors.primary,
              child: items.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: const [
                        SizedBox(height: 220),
                        Center(child: Text('No procurement items')),
                      ],
                    )
                  : ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.only(bottom: 80),
                      itemCount: items.length,
                      itemBuilder: (_, i) {
                        final item = items[i];
                        return ProcurementItemTile(
                          item: item,
                          onToggleCheck: () => notifier.toggleCheck(item.id),
                          onStatusChange: (s) => notifier.setStatus(item.id, s),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
      floatingActionButton: switch (selectionType) {
        ProcurementSelectionType.none => null,
        ProcurementSelectionType.procuredOnly =>
          FloatingActionButton.extended(
            onPressed: notifier.markSelectedUnprocured,
            backgroundColor: AppColors.error,
            foregroundColor: Colors.white,
            icon: const Icon(Icons.remove_circle_outline_rounded),
            label: const Text('Mark Unprocured'),
          ),
        ProcurementSelectionType.pendingOnly ||
        ProcurementSelectionType.mixed =>
          FloatingActionButton.extended(
            onPressed: notifier.markSelectedProcured,
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            icon: const Icon(Icons.check_circle_outline_rounded),
            label: const Text('Mark Selected Procured'),
          ),
      },
    );
  }
}

// ── Stats card ────────────────────────────────────────────────────────────────

class _StatsCard extends StatelessWidget {
  final ({
    double totalInStock,
    double totalNeeded,
    double totalToProcure,
    int itemCount,
    int orderCount,
    int procuredCount,
  }) summary;

  const _StatsCard({required this.summary});

  String _fmtKg(double v) =>
      '${v % 1 == 0 ? v.toInt() : v.toStringAsFixed(1)} kg';

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.base),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
      ),
      child: Column(
        children: [
          // Top row: kg metrics
          Row(
            children: [
              Expanded(
                child: _BigStat(
                  value: _fmtKg(summary.totalInStock),
                  label: 'In Stock',
                ),
              ),
              _VertDiv(),
              Expanded(
                child: _BigStat(
                  value: _fmtKg(summary.totalNeeded),
                  label: 'Needed Today',
                ),
              ),
              _VertDiv(),
              Expanded(
                child: _BigStat(
                  value: _fmtKg(summary.totalToProcure),
                  label: 'To Procure',
                ),
              ),
            ],
          ),
          Divider(
            color: Colors.white.withValues(alpha: 0.2),
            height: AppDimensions.base,
            thickness: 1,
          ),
          // Bottom row: count metrics
          Row(
            children: [
              Expanded(
                child: _SmallStat(
                  value: '${summary.itemCount}',
                  label: 'Items',
                ),
              ),
              _VertDiv(height: 24),
              Expanded(
                child: _SmallStat(
                  value: '${summary.orderCount}',
                  label: 'Orders',
                ),
              ),
              _VertDiv(height: 24),
              Expanded(
                child: _SmallStat(
                  value: '${summary.procuredCount}',
                  label: 'Procured',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BigStat extends StatelessWidget {
  final String value;
  final String label;
  const _BigStat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: AppTextStyles.h3.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            )),
        const SizedBox(height: 2),
        Text(label,
            style: AppTextStyles.label.copyWith(
              color: Colors.white.withValues(alpha: 0.7),
            )),
      ],
    );
  }
}

class _SmallStat extends StatelessWidget {
  final String value;
  final String label;
  const _SmallStat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: AppTextStyles.bodySemiBold.copyWith(color: Colors.white)),
        Text(label,
            style: AppTextStyles.label.copyWith(
              color: Colors.white.withValues(alpha: 0.7),
            )),
      ],
    );
  }
}

class _VertDiv extends StatelessWidget {
  final double height;
  const _VertDiv({this.height = 36});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: height,
      color: Colors.white.withValues(alpha: 0.25),
    );
  }
}

// ── Download sheet ────────────────────────────────────────────────────────────

class _DownloadSheet extends StatelessWidget {
  final String content;
  const _DownloadSheet({required this.content});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppDimensions.base),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: AppDimensions.base),
          Row(
            children: [
              Text("Today's Procurement List", style: AppTextStyles.h3),
              const Spacer(),
              TextButton.icon(
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: content));
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Copied to clipboard')),
                    );
                    Navigator.pop(context);
                  }
                },
                icon: const Icon(Icons.copy_rounded, size: 16),
                label: const Text('Copy'),
                style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.sm),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppDimensions.md),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            ),
            child: Text(content, style: AppTextStyles.body),
          ),
          const SizedBox(height: AppDimensions.base),
        ],
      ),
    );
  }
}
