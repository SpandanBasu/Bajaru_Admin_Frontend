import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/constants/app_dimensions.dart';

enum BadgeVariant { success, warning, error, info, neutral }

class StatusBadge extends StatelessWidget {
  final String label;
  final BadgeVariant variant;

  const StatusBadge({super.key, required this.label, required this.variant});

  Color get _bg {
    return switch (variant) {
      BadgeVariant.success => AppColors.successLight,
      BadgeVariant.warning => AppColors.warningLight,
      BadgeVariant.error   => AppColors.errorLight,
      BadgeVariant.info    => AppColors.primaryLight,
      BadgeVariant.neutral => AppColors.neutralLight,
    };
  }

  Color get _fg {
    return switch (variant) {
      BadgeVariant.success => AppColors.success,
      BadgeVariant.warning => AppColors.warning,
      BadgeVariant.error   => AppColors.error,
      BadgeVariant.info    => AppColors.primary,
      BadgeVariant.neutral => AppColors.textSecondary,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.sm,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
      ),
      child: Text(label, style: AppTextStyles.captionBold.copyWith(color: _fg)),
    );
  }
}
