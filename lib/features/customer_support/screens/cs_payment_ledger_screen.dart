import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/customer_support_provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../widgets/customer_support/cs_nav_bar.dart';
import '../../../widgets/customer_support/cs_transaction_table.dart';
import '../../../widgets/customer_support/cs_initiate_refund_card.dart';

class CsPaymentLedgerScreen extends ConsumerWidget {
  final String customerId;
  final String customerName;

  const CsPaymentLedgerScreen({
    super.key,
    required this.customerId,
    required this.customerName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(csCustomerDetailProvider(customerId));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // ── Nav bar ───────────────────────────────────────────────────────
          CsNavBar(
            title: 'Payment & Transactions',
            subtitle: detailAsync.maybeWhen(
              data: (d) => d.name,
              orElse: () => customerName,
            ),
            onBack: () => Navigator.of(context).pop(),
          ),

          // ── Content ───────────────────────────────────────────────────────
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(csCustomerDetailProvider(customerId));
                await ref.read(csCustomerDetailProvider(customerId).future);
              },
              color: AppColors.primary,
              child: detailAsync.when(
                loading: () => SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: SizedBox(
                    height: MediaQuery.of(context).size.height - 150,
                    child: const Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
                error: (e, _) => SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: SizedBox(
                    height: MediaQuery.of(context).size.height - 150,
                    child: _LedgerError(
                      message: e.toString(),
                      onRetry: () =>
                          ref.invalidate(csCustomerDetailProvider(customerId)),
                    ),
                  ),
                ),
                data: (customer) => ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(AppDimensions.base),
                  children: [
                    CsTransactionTable(transactions: customer.transactions),
                    const SizedBox(height: AppDimensions.md),
                    CsInitiateRefundCard(
                      userId: customerId,
                      onRefundSubmitted: () =>
                          ref.invalidate(csCustomerDetailProvider(customerId)),
                    ),
                    const SizedBox(height: AppDimensions.base),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LedgerError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _LedgerError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_rounded, size: 48, color: AppColors.textHint),
            const SizedBox(height: AppDimensions.md),
            Text('Failed to load transactions',
                style: AppTextStyles.bodySemiBold
                    .copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: AppDimensions.xs),
            Text(message,
                style:
                    AppTextStyles.caption.copyWith(color: AppColors.textHint),
                textAlign: TextAlign.center),
            const SizedBox(height: AppDimensions.base),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
