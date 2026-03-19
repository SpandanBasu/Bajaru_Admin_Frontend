import 'package:flutter/material.dart';
import '../../core/models/cs_customer.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/constants/app_dimensions.dart';

/// Transaction ledger card — white card with header + tabular rows.
class CsTransactionTable extends StatelessWidget {
  final List<Transaction> transactions;

  const CsTransactionTable({super.key, required this.transactions});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card header
          _LedgerHeader(),
          // Column labels
          _TableColumnHeader(),
          const Divider(height: 1, color: AppColors.border),
          // Data rows
          if (transactions.isEmpty)
            Padding(
              padding: const EdgeInsets.all(AppDimensions.base),
              child: Center(
                child: Text(
                  'No transactions found',
                  style: AppTextStyles.caption,
                ),
              ),
            )
          else
            ...List.generate(transactions.length, (i) {
              final isLast = i == transactions.length - 1;
              return Column(
                children: [
                  _TransactionRow(txn: transactions[i]),
                  if (!isLast) const Divider(height: 1, color: AppColors.border),
                ],
              );
            }),
        ],
      ),
    );
  }
}

class _LedgerHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Icon(Icons.receipt_long_rounded, size: 16, color: AppColors.primary),
          const SizedBox(width: AppDimensions.sm),
          Text(
            'Transaction Ledger',
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

class _TableColumnHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.inputBg,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: const [
          _ColLabel(label: 'Date', width: 52),
          _ColLabel(label: 'Txn ID', width: 66),
          _ColLabel(label: 'Type', width: 52),
          _ColLabel(label: 'Source', width: 54),
          _ColLabel(label: 'Amount', width: 54),
          Expanded(child: _ColLabel(label: 'Status')),
        ],
      ),
    );
  }
}

class _ColLabel extends StatelessWidget {
  final String label;
  final double? width;

  const _ColLabel({required this.label, this.width});

  @override
  Widget build(BuildContext context) {
    final text = Text(
      label,
      style: AppTextStyles.label.copyWith(
        color: AppColors.textHint,
        fontSize: 9,
        letterSpacing: 0.5,
      ),
      overflow: TextOverflow.ellipsis,
    );
    return width != null ? SizedBox(width: width, child: text) : text;
  }
}

class _TransactionRow extends StatelessWidget {
  final Transaction txn;

  const _TransactionRow({required this.txn});

  (String, Color, Color) get _typeStyle => switch (txn.type) {
        TransactionType.credit => (
          'Credit',
          AppColors.success,
          AppColors.successLight,
        ),
        TransactionType.debit => (
          'Debit',
          AppColors.error,
          AppColors.errorLight,
        ),
        TransactionType.refund => (
          'Refund',
          AppColors.primary,
          AppColors.primaryLight,
        ),
      };

  Color get _statusColor => switch (txn.status) {
        TransactionStatus.success => AppColors.success,
        TransactionStatus.failed => AppColors.error,
        TransactionStatus.pending => AppColors.warning,
      };

  String get _statusLabel => switch (txn.status) {
        TransactionStatus.success => 'Success',
        TransactionStatus.failed => 'Failed',
        TransactionStatus.pending => 'Pending',
      };

  @override
  Widget build(BuildContext context) {
    final (typeLabel, typeColor, typeBg) = _typeStyle;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          SizedBox(
            width: 52,
            child: Text(
              txn.date,
              style: AppTextStyles.caption
                  .copyWith(color: AppColors.textPrimary, fontSize: 11),
            ),
          ),
          SizedBox(
            width: 66,
            child: Text(
              txn.txnId,
              style: AppTextStyles.caption.copyWith(fontSize: 11),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Type badge
          SizedBox(
            width: 52,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: typeBg,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                typeLabel,
                style: AppTextStyles.label.copyWith(
                  color: typeColor,
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          SizedBox(
            width: 54,
            child: Text(
              txn.source,
              style: AppTextStyles.caption.copyWith(fontSize: 11),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(
            width: 54,
            child: Text(
              txn.amount,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
            ),
          ),
          Expanded(
            child: Text(
              _statusLabel,
              style: AppTextStyles.captionBold
                  .copyWith(color: _statusColor, fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }
}
