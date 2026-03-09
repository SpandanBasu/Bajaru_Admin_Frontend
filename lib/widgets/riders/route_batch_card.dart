import 'package:flutter/material.dart';
import '../../core/models/route_batch.dart';
import '../../core/models/rider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/constants/app_dimensions.dart';

class RouteBatchCard extends StatelessWidget {
  final RouteBatch batch;
  final List<Rider> availableRiders;
  final ValueChanged<Rider> onAssign;
  final VoidCallback onUnassign;

  const RouteBatchCard({
    super.key,
    required this.batch,
    required this.availableRiders,
    required this.onAssign,
    required this.onUnassign,
  });

  @override
  Widget build(BuildContext context) {
    final isAssigned = batch.status == RouteBatchStatus.assigned;
    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.md),
      padding: const EdgeInsets.all(AppDimensions.base),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(batch.name, style: AppTextStyles.bodySemiBold),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.sm,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: isAssigned
                      ? AppColors.successLight
                      : AppColors.neutralLight,
                  borderRadius:
                      BorderRadius.circular(AppDimensions.radiusFull),
                ),
                child: Text(
                  isAssigned ? 'Assigned' : 'Unassigned',
                  style: AppTextStyles.captionBold.copyWith(
                    color: isAssigned
                        ? AppColors.success
                        : AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.xs),

          // Meta
          Text(
            '${batch.orderCount} orders • ${batch.estimatedHours}h est. • ${batch.completedDeliveries}/${batch.orderCount} delivered',
            style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
          ),

          // Progress
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppDimensions.sm),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: batch.orderCount == 0
                    ? 0
                    : batch.completedDeliveries / batch.orderCount,
                backgroundColor: AppColors.border,
                color: AppColors.primary,
                minHeight: 6,
              ),
            ),
          ),

          // Assign row
          if (isAssigned && batch.assignedRider != null) ...[
            Row(
              children: [
                _RiderAvatar(rider: batch.assignedRider!),
                const SizedBox(width: AppDimensions.sm),
                Expanded(
                  child: Text(batch.assignedRider!.name,
                      style: AppTextStyles.bodyMedium),
                ),
                TextButton(
                  onPressed: onUnassign,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.error,
                    padding: EdgeInsets.zero,
                  ),
                  child: const Text('Unassign'),
                ),
              ],
            ),
          ] else ...[
            _AssignDropdown(
              riders: availableRiders,
              onSelect: onAssign,
            ),
          ],
        ],
      ),
    );
  }
}

class _RiderAvatar extends StatelessWidget {
  final Rider rider;
  const _RiderAvatar({required this.rider});

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 16,
      backgroundColor: rider.avatarColor,
      child: Text(rider.initials,
          style: AppTextStyles.captionBold.copyWith(color: Colors.white)),
    );
  }
}

class _AssignDropdown extends StatefulWidget {
  final List<Rider> riders;
  final ValueChanged<Rider> onSelect;
  const _AssignDropdown({required this.riders, required this.onSelect});

  @override
  State<_AssignDropdown> createState() => _AssignDropdownState();
}

class _AssignDropdownState extends State<_AssignDropdown> {
  Rider? _selected;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: AppDimensions.sm),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<Rider>(
                value: _selected,
                hint: Text('Assign rider',
                    style: AppTextStyles.body
                        .copyWith(color: AppColors.textHint)),
                isExpanded: true,
                items: widget.riders.map((r) {
                  return DropdownMenuItem(
                    value: r,
                    child: Text(r.name, style: AppTextStyles.body),
                  );
                }).toList(),
                onChanged: (r) => setState(() => _selected = r),
              ),
            ),
          ),
        ),
        const SizedBox(width: AppDimensions.sm),
        ElevatedButton(
          onPressed: _selected != null
              ? () => widget.onSelect(_selected!)
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.base,
              vertical: AppDimensions.sm,
            ),
          ),
          child: const Text('Assign'),
        ),
      ],
    );
  }
}
