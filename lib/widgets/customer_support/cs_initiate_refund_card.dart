import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/services/admin_customer_support_service.dart';
import '../../core/api/admin_api_client.dart';

enum _RefundDestination { wallet, original }

/// Initiate Refund form card — connected to real backend.
/// Calls [AdminCustomerSupportService.initiateRefund] and notifies
/// the parent via [onRefundSubmitted] so it can invalidate the cache.
class CsInitiateRefundCard extends ConsumerStatefulWidget {
  final String userId;
  final VoidCallback? onRefundSubmitted;

  const CsInitiateRefundCard({
    super.key,
    required this.userId,
    this.onRefundSubmitted,
  });

  @override
  ConsumerState<CsInitiateRefundCard> createState() =>
      _CsInitiateRefundCardState();
}

class _CsInitiateRefundCardState extends ConsumerState<CsInitiateRefundCard> {
  final _orderIdCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  _RefundDestination _destination = _RefundDestination.wallet;
  bool _loading = false;
  String? _successMessage;
  String? _errorMessage;

  @override
  void dispose() {
    _orderIdCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final orderId = _orderIdCtrl.text.trim();
    final amountStr = _amountCtrl.text.trim();

    if (orderId.isEmpty || amountStr.isEmpty) {
      setState(() => _errorMessage = 'Please fill in Order ID and amount.');
      return;
    }

    final amount = double.tryParse(amountStr.replaceAll(',', ''));
    if (amount == null || amount <= 0) {
      setState(() => _errorMessage = 'Enter a valid refund amount.');
      return;
    }

    setState(() {
      _loading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final service = AdminCustomerSupportService(
        ref.read(adminApiClientProvider),
      );
      await service.initiateRefund(
        userId: widget.userId,
        orderId: orderId.replaceAll('#', ''),
        amount: amount,
        destination: _destination == _RefundDestination.wallet
            ? 'WALLET'
            : 'ORIGINAL',
      );
      setState(() => _successMessage = 'Refund of ₹${amount.toInt()} processed successfully.');
      _orderIdCtrl.clear();
      _amountCtrl.clear();
      widget.onRefundSubmitted?.call();
    } catch (e) {
      setState(() => _errorMessage = 'Refund failed: ${e.toString()}');
    } finally {
      setState(() => _loading = false);
    }
  }

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
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              children: [
                Icon(Icons.undo_rounded, size: 16, color: AppColors.primary),
                const SizedBox(width: AppDimensions.sm),
                Text(
                  'Initiate Refund',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),

          // Form
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Order ID
                _FieldLabel('ORDER ID'),
                const SizedBox(height: 6),
                _TextInputBox(
                  controller: _orderIdCtrl,
                  hint: 'e.g. #ORD-1042',
                ),
                const SizedBox(height: 14),

                // Amount
                _FieldLabel('REFUND AMOUNT'),
                const SizedBox(height: 6),
                _AmountInputBox(controller: _amountCtrl),
                const SizedBox(height: 14),

                // Destination
                _FieldLabel('REFUND DESTINATION'),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _DestinationOption(
                        icon: Icons.account_balance_wallet_rounded,
                        label: 'Wallet',
                        selected:
                            _destination == _RefundDestination.wallet,
                        onTap: () => setState(
                            () => _destination = _RefundDestination.wallet),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _DestinationOption(
                        icon: Icons.credit_card_rounded,
                        label: 'Original Method',
                        selected:
                            _destination == _RefundDestination.original,
                        onTap: () => setState(
                            () => _destination = _RefundDestination.original),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Feedback messages
                if (_successMessage != null) ...[
                  _FeedbackBanner(
                    message: _successMessage!,
                    isError: false,
                  ),
                  const SizedBox(height: 10),
                ],
                if (_errorMessage != null) ...[
                  _FeedbackBanner(
                    message: _errorMessage!,
                    isError: true,
                  ),
                  const SizedBox(height: 10),
                ],

                // Submit button
                GestureDetector(
                  onTap: _loading ? null : _submit,
                  child: Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: _loading
                          ? AppColors.primary.withValues(alpha: 0.6)
                          : AppColors.primary,
                      borderRadius:
                          BorderRadius.circular(AppDimensions.radiusMd),
                    ),
                    child: _loading
                        ? const Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.undo_rounded,
                                  size: 16, color: Colors.white),
                              const SizedBox(width: AppDimensions.sm),
                              Text(
                                'Process Refund',
                                style: AppTextStyles.bodySemiBold
                                    .copyWith(color: Colors.white),
                              ),
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

// ─── Internal form widgets ────────────────────────────────────────────────────

class _FieldLabel extends StatelessWidget {
  final String text;

  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTextStyles.label.copyWith(
        color: AppColors.textHint,
        fontSize: 10,
        letterSpacing: 0.5,
      ),
    );
  }
}

class _TextInputBox extends StatelessWidget {
  final TextEditingController controller;
  final String hint;

  const _TextInputBox({required this.controller, required this.hint});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: AppColors.inputBg,
        borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
        border: Border.all(color: AppColors.border),
      ),
      child: TextField(
        controller: controller,
        style: AppTextStyles.body.copyWith(fontSize: 13),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: AppTextStyles.body
              .copyWith(color: AppColors.textHint, fontSize: 13),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          isDense: true,
        ),
      ),
    );
  }
}

class _AmountInputBox extends StatelessWidget {
  final TextEditingController controller;

  const _AmountInputBox({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: AppColors.inputBg,
        borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              '₹',
              style: AppTextStyles.bodySemiBold
                  .copyWith(color: AppColors.textSecondary),
            ),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              style: AppTextStyles.body.copyWith(fontSize: 13),
              decoration: InputDecoration(
                hintText: '0.00',
                hintStyle: AppTextStyles.body
                    .copyWith(color: AppColors.textHint, fontSize: 13),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                isDense: true,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DestinationOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _DestinationOption({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryLight : AppColors.inputBg,
          borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
            width: selected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 14,
              color: selected ? AppColors.primary : AppColors.textSecondary,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: AppTextStyles.caption.copyWith(
                  color:
                      selected ? AppColors.primary : AppColors.textSecondary,
                  fontWeight:
                      selected ? FontWeight.w600 : FontWeight.w400,
                  fontSize: 12,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeedbackBanner extends StatelessWidget {
  final String message;
  final bool isError;

  const _FeedbackBanner({required this.message, required this.isError});

  @override
  Widget build(BuildContext context) {
    final bg = isError ? AppColors.errorLight : AppColors.successLight;
    final fg = isError ? AppColors.error : AppColors.success;
    final icon =
        isError ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
        border: Border.all(color: fg),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style:
                  AppTextStyles.caption.copyWith(color: fg, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
