import 'package:flutter/material.dart';
import '../../core/models/rider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/constants/app_dimensions.dart';

class RiderTile extends StatelessWidget {
  final Rider rider;
  final VoidCallback? onToggleOnline;

  const RiderTile({super.key, required this.rider, this.onToggleOnline});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.base,
        vertical: AppDimensions.md,
      ),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: rider.avatarColor,
                child: Text(
                  rider.initials,
                  style: AppTextStyles.bodySemiBold
                      .copyWith(color: Colors.white),
                ),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: rider.isOnline ? AppColors.success : AppColors.textHint,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.surface, width: 2),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: AppDimensions.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(rider.name, style: AppTextStyles.bodySemiBold),
                const SizedBox(height: 2),
                Text(
                  rider.isOnline
                      ? '${rider.deliveredToday}/${rider.totalAssigned} delivered today'
                      : 'Offline',
                  style: AppTextStyles.caption.copyWith(
                    color: rider.isOnline
                        ? AppColors.textSecondary
                        : AppColors.textHint,
                  ),
                ),
              ],
            ),
          ),
          if (rider.isOnline)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.sm,
                vertical: 3,
              ),
              decoration: BoxDecoration(
                color: AppColors.successLight,
                borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
              ),
              child: Text('ONLINE',
                  style: AppTextStyles.label
                      .copyWith(color: AppColors.success)),
            ),
        ],
      ),
    );
  }
}
