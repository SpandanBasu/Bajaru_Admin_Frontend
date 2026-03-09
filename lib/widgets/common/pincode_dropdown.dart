import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/constants/app_dimensions.dart';

/// Reusable pincode section: "PINCODE" label + tappable dropdown row.
/// Tapping opens a bottom-sheet picker.
class PincodeDropdown extends StatelessWidget {
  final List<String> pincodes;
  final String? selected; // null = All
  final ValueChanged<String?> onChanged;
  final String allLabel;

  const PincodeDropdown({
    super.key,
    required this.pincodes,
    required this.selected,
    required this.onChanged,
    this.allLabel = 'All Pincodes',
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'PINCODE',
          style: AppTextStyles.label.copyWith(
            color: AppColors.textSecondary,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: () => _showPicker(context),
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
                Expanded(
                  child: Text(
                    selected ?? allLabel,
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

  void _showPicker(BuildContext context) {
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
            Text('Select Pincode', style: AppTextStyles.h3),
            const SizedBox(height: AppDimensions.xs),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(allLabel, style: AppTextStyles.body),
              trailing: selected == null
                  ? const Icon(Icons.check_circle_rounded,
                      color: AppColors.primary)
                  : const Icon(Icons.circle_outlined,
                      color: AppColors.border),
              onTap: () {
                Navigator.pop(context);
                onChanged(null);
              },
            ),
            for (final code in pincodes)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(code, style: AppTextStyles.body),
                trailing: selected == code
                    ? const Icon(Icons.check_circle_rounded,
                        color: AppColors.primary)
                    : const Icon(Icons.circle_outlined,
                        color: AppColors.border),
                onTap: () {
                  Navigator.pop(context);
                  onChanged(code);
                },
              ),
            const SizedBox(height: AppDimensions.base),
          ],
        ),
      ),
    );
  }
}
