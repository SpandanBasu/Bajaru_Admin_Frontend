import 'package:flutter/material.dart';
import '../../core/models/cs_customer.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/constants/app_dimensions.dart';

/// White card displaying customer basic details, metrics, addresses,
/// and a link to the Payment & Transactions screen.
class CsProfileCard extends StatelessWidget {
  final CustomerDetail customer;
  final VoidCallback onPaymentTap;

  const CsProfileCard({
    super.key,
    required this.customer,
    required this.onPaymentTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CsCardSectionHeader(
            icon: Icons.person_rounded,
            label: 'Basic Details',
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name + Phone
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        customer.name,
                        style: AppTextStyles.bodyLarge
                            .copyWith(fontWeight: FontWeight.w600),
                      ),
                    ),
                    Row(
                      children: [
                        Icon(Icons.phone_rounded,
                            size: 14, color: AppColors.primary),
                        const SizedBox(width: 6),
                        Text(
                          customer.phone,
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _InfoRow(label: 'Email', value: customer.email),
                const SizedBox(height: 6),
                _InfoRow(label: 'Member Since', value: customer.memberSince),
                const SizedBox(height: 10),
                const Divider(color: AppColors.border),
                const SizedBox(height: 8),
                // Metrics
                Row(
                  children: [
                    Expanded(
                      child: _MetricBox(
                        label: 'TOTAL ORDERS',
                        value: '${customer.totalOrders}',
                        valueColor: AppColors.primary,
                        bgColor: AppColors.primaryLight,
                      ),
                    ),
                    const SizedBox(width: AppDimensions.md),
                    Expanded(
                      child: _MetricBox(
                        label: 'WALLET BALANCE',
                        value: customer.walletBalance,
                        valueColor: AppColors.success,
                        bgColor: AppColors.successLight,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Divider(color: AppColors.border),
                const SizedBox(height: 8),
                Text(
                  'SAVED ADDRESSES',
                  style: AppTextStyles.label.copyWith(
                    color: AppColors.textHint,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                ...customer.addresses.map((a) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: _AddressRow(address: a),
                    )),
                const SizedBox(height: AppDimensions.sm),
                // Payment & Transactions button
                GestureDetector(
                  onTap: onPaymentTap,
                  child: Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius:
                          BorderRadius.circular(AppDimensions.radiusSm),
                      border: Border.all(color: AppColors.primary),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.account_balance_wallet_rounded,
                            size: 16, color: AppColors.primary),
                        const SizedBox(width: AppDimensions.sm),
                        Text(
                          'Payment & Transactions',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(width: AppDimensions.sm),
                        Icon(Icons.arrow_forward_rounded,
                            size: 16, color: AppColors.primary),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Internal sub-widgets ─────────────────────────────────────────────────────

/// Reusable section header strip used in CS cards (icon + label + bottom border).
class _CsCardSectionHeader extends StatelessWidget {
  final IconData icon;
  final String label;

  const _CsCardSectionHeader({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(width: AppDimensions.sm),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTextStyles.caption),
        Text(
          value,
          style: AppTextStyles.caption.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _MetricBox extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;
  final Color bgColor;

  const _MetricBox({
    required this.label,
    required this.value,
    required this.valueColor,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyles.label.copyWith(
              color: AppColors.textSecondary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTextStyles.statValue.copyWith(
              color: valueColor,
              fontSize: 22,
            ),
          ),
        ],
      ),
    );
  }
}

class _AddressRow extends StatelessWidget {
  final SavedAddress address;

  const _AddressRow({required this.address});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          address.isHome ? Icons.home_rounded : Icons.business_rounded,
          size: 14,
          color: AppColors.textSecondary,
        ),
        const SizedBox(width: AppDimensions.sm),
        Expanded(
          child: Text(
            address.address,
            style:
                AppTextStyles.caption.copyWith(color: AppColors.textPrimary),
          ),
        ),
      ],
    );
  }
}
