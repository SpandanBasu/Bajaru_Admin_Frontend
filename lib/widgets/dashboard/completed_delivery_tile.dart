import 'package:flutter/material.dart';
import '../../core/models/dashboard_stats.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/constants/app_dimensions.dart';

class CompletedDeliveryTile extends StatelessWidget {
  final CompletedDelivery delivery;

  const CompletedDeliveryTile({super.key, required this.delivery});

  String _timeAgo() {
    final diff = DateTime.now().difference(delivery.completedAt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    return '${diff.inHours}h ago';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.successLight,
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            ),
            child: const Icon(Icons.check_rounded, color: AppColors.success, size: 20),
          ),
          const SizedBox(width: AppDimensions.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(delivery.customerName, style: AppTextStyles.bodySemiBold),
                const SizedBox(height: 2),
                Text(
                  '${delivery.orderId} • ${delivery.address}',
                  style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppDimensions.sm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('₹${delivery.amount.toStringAsFixed(0)}',
                  style: AppTextStyles.bodySemiBold.copyWith(color: AppColors.success)),
              Text(_timeAgo(),
                  style: AppTextStyles.caption.copyWith(color: AppColors.textHint)),
            ],
          ),
        ],
      ),
    );
  }
}
