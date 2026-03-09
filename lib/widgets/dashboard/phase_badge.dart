import 'package:flutter/material.dart';
import '../../core/models/dashboard_stats.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/constants/app_dimensions.dart';

class PhaseBadge extends StatelessWidget {
  final DeliveryPhase phase;

  const PhaseBadge({super.key, required this.phase});

  String get _label => switch (phase) {
        DeliveryPhase.orderAccumulation => 'ORDER ACCUMULATION',
        DeliveryPhase.procurement       => 'PROCUREMENT',
        DeliveryPhase.packing           => 'PACKING',
        DeliveryPhase.dispatch          => 'DISPATCH',
      };

  Color get _color => switch (phase) {
        DeliveryPhase.orderAccumulation => AppColors.primary,
        DeliveryPhase.procurement       => AppColors.warning,
        DeliveryPhase.packing           => const Color(0xFF9C27B0),
        DeliveryPhase.dispatch          => AppColors.success,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.base,
        vertical: AppDimensions.xs,
      ),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
        border: Border.all(color: _color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: _color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            _label,
            style: AppTextStyles.captionBold.copyWith(color: _color),
          ),
        ],
      ),
    );
  }
}
