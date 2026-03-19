import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/models/warehouse.dart';
import '../../core/providers/warehouse_provider.dart';

/// Reusable warehouse selector — reads and writes [activeWarehouseProvider].
/// Tapping opens a bottom-sheet picker. Shows "All Warehouses" when null.
///
/// Place this anywhere a pincode dropdown was used. All instances share the
/// same global warehouse context.
class WarehouseDropdown extends ConsumerWidget {
  /// If false, the "All Warehouses" option is hidden in the picker.
  final bool showAllOption;

  const WarehouseDropdown({super.key, this.showAllOption = true});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final warehousesAsync = ref.watch(warehousesProvider);
    final selected = ref.watch(activeWarehouseProvider);
    final warehouses = warehousesAsync.asData?.value ?? [];
    final isLoading = warehousesAsync.isLoading;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'WAREHOUSE',
          style: AppTextStyles.label.copyWith(
            color: AppColors.textSecondary,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: isLoading
              ? null
              : () => _showPicker(context, ref, warehouses, selected),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.md,
              vertical: AppDimensions.sm + 2,
            ),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                if (isLoading)
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.5,
                      color: AppColors.primary,
                    ),
                  )
                else
                  Expanded(
                    child: Text(
                      selected?.displayName ?? 'All Warehouses',
                      style: AppTextStyles.captionMedium
                          .copyWith(color: AppColors.textSecondary),
                    ),
                  ),
                const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 18,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showPicker(
    BuildContext context,
    WidgetRef ref,
    List<Warehouse> warehouses,
    Warehouse? selected,
  ) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(AppDimensions.base),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppDimensions.base),
            Text('Select Warehouse', style: AppTextStyles.h3),
            const SizedBox(height: AppDimensions.xs),
            if (showAllOption)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('All Warehouses', style: AppTextStyles.body),
                trailing: selected == null
                    ? const Icon(Icons.check_circle_rounded,
                        color: AppColors.primary)
                    : const Icon(Icons.circle_outlined,
                        color: AppColors.border),
                onTap: () {
                  Navigator.pop(context);
                  ref.read(activeWarehouseProvider.notifier).select(null);
                },
              ),
            for (final wh in warehouses)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(wh.displayName, style: AppTextStyles.body),
                subtitle: Text(
                  wh.warehouseId,
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.textHint),
                ),
                trailing: selected?.warehouseId == wh.warehouseId
                    ? const Icon(Icons.check_circle_rounded,
                        color: AppColors.primary)
                    : const Icon(Icons.circle_outlined,
                        color: AppColors.border),
                onTap: () {
                  Navigator.pop(context);
                  ref.read(activeWarehouseProvider.notifier).select(wh);
                },
              ),
            const SizedBox(height: AppDimensions.base),
          ],
        ),
      ),
    );
  }
}
