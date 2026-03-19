import 'package:flutter/material.dart';
import '../../core/models/cs_customer.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/constants/app_dimensions.dart';

/// Displays customer search results as a bordered table card.
class CsResultsTable extends StatelessWidget {
  final List<CustomerSummary> results;
  final ValueChanged<CustomerSummary> onViewTap;

  const CsResultsTable({
    super.key,
    required this.results,
    required this.onViewTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${results.length} result${results.length == 1 ? '' : 's'} found',
          style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: AppDimensions.sm),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
            border: Border.all(color: AppColors.border),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              // Table header row — rounded top corners to match container
              _TableHeader(),
              const Divider(height: 1, color: AppColors.border),
              // Data rows
              ...List.generate(results.length, (i) {
                final isLast = i == results.length - 1;
                return Column(
                  children: [
                    _CustomerRow(
                      customer: results[i],
                      onViewTap: () => onViewTap(results[i]),
                    ),
                    if (!isLast) const Divider(height: 1, color: AppColors.border),
                  ],
                );
              }),
            ],
          ),
        ),
      ],
    );
  }
}

class _TableHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.inputBg,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: const [
          _HeaderCell(label: 'Name', width: 72),
          _HeaderCell(label: 'Phone', width: 100),
          _HeaderCell(label: 'Orders', width: 56),
          Expanded(child: SizedBox()),
        ],
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  final String label;
  final double width;

  const _HeaderCell({required this.label, required this.width});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Text(
        label,
        style: AppTextStyles.label.copyWith(
          color: AppColors.textHint,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _CustomerRow extends StatelessWidget {
  final CustomerSummary customer;
  final VoidCallback onViewTap;

  const _CustomerRow({required this.customer, required this.onViewTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 72,
            child: Text(
              customer.name,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
              maxLines: 2,
              softWrap: true,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(
            width: 100,
            child: Text(
              customer.phone,
              style: AppTextStyles.caption,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(
            width: 56,
            child: Text(
              '${customer.totalOrders}',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: _ViewButton(onTap: onViewTap),
            ),
          ),
        ],
      ),
    );
  }
}

class _ViewButton extends StatelessWidget {
  final VoidCallback onTap;

  const _ViewButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
        ),
        child: Text(
          'View',
          style: AppTextStyles.label.copyWith(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
