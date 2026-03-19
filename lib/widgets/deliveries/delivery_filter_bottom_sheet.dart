import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/constants/app_dimensions.dart';
import '../../features/deliveries/providers/deliveries_provider.dart';

/// Shows the filter bottom sheet. Call this instead of inlining showModalBottomSheet.
void showDeliveryFilterBottomSheet(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(AppDimensions.radiusXl),
      ),
    ),
    builder: (_) => const DeliveryFilterBottomSheet(),
  );
}

// ── Main bottom sheet widget ───────────────────────────────────────────────────

class DeliveryFilterBottomSheet extends ConsumerStatefulWidget {
  const DeliveryFilterBottomSheet({super.key});

  @override
  ConsumerState<DeliveryFilterBottomSheet> createState() =>
      _DeliveryFilterBottomSheetState();
}

class _DeliveryFilterBottomSheetState
    extends ConsumerState<DeliveryFilterBottomSheet> {
  late final TextEditingController _orderIdController;
  late final TextEditingController _riderController;
  late DeliveryPaymentFilter _payment;
  late DeliverySortBy _sort;
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _orderIdController = TextEditingController(
      text: ref.read(deliveryOrderIdQueryProvider),
    );
    _riderController = TextEditingController(
      text: ref.read(deliveryRiderQueryProvider),
    );
    _payment = ref.read(deliveryPaymentFilterProvider);
    _sort = ref.read(deliverySortByProvider);
    _selectedDate = ref.read(deliverySelectedDateProvider);
  }

  @override
  void dispose() {
    _orderIdController.dispose();
    _riderController.dispose();
    super.dispose();
  }

  // ── Actions ─────────────────────────────────────────────────────────────────

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 1),
      helpText: 'Select Delivery Date',
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: ColorScheme.light(
            primary: AppColors.primary,
            onPrimary: Colors.white,
            surface: AppColors.surface,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  void _apply() {
    ref.read(deliveryOrderIdQueryProvider.notifier).state =
        _orderIdController.text.trim();
    ref.read(deliveryRiderQueryProvider.notifier).state =
        _riderController.text.trim();
    ref.read(deliveryPaymentFilterProvider.notifier).state = _payment;
    ref.read(deliverySortByProvider.notifier).state = _sort;
    ref.read(deliverySelectedDateProvider.notifier).state = _selectedDate;
    Navigator.of(context).pop();
  }

  void _clear() {
    ref.read(deliveryOrderIdQueryProvider.notifier).state = '';
    ref.read(deliveryRiderQueryProvider.notifier).state = '';
    ref.read(deliveryPaymentFilterProvider.notifier).state =
        DeliveryPaymentFilter.all;
    ref.read(deliverySortByProvider.notifier).state = DeliverySortBy.none;
    ref.read(deliverySelectedDateProvider.notifier).state = null;
    Navigator.of(context).pop();
  }

  // ── Toggle helpers ───────────────────────────────────────────────────────────

  void _togglePayment(DeliveryPaymentFilter tapped) {
    setState(() {
      _payment = _payment == tapped ? DeliveryPaymentFilter.all : tapped;
    });
  }

  void _toggleSort(DeliverySortBy primary, DeliverySortBy secondary) {
    setState(() {
      if (_sort == primary) {
        _sort = secondary;
      } else if (_sort == secondary) {
        _sort = DeliverySortBy.none;
      } else {
        _sort = primary;
      }
    });
  }

  // ── Label helpers ────────────────────────────────────────────────────────────

  bool get _isDeliveryTimeActive =>
      _sort == DeliverySortBy.deliveryTimeNewest ||
      _sort == DeliverySortBy.deliveryTimeOldest;

  bool get _isPriceAmountActive =>
      _sort == DeliverySortBy.amountHighToLow ||
      _sort == DeliverySortBy.amountLowToHigh;

  String get _deliveryTimeSortLabel =>
      _sort == DeliverySortBy.deliveryTimeOldest
          ? 'Delivery Time ↑'
          : 'Delivery Time ↓';

  String get _priceAmountSortLabel => _sort == DeliverySortBy.amountLowToHigh
      ? 'Price Amount ↑'
      : 'Price Amount ↓';

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final isToday = _selectedDate == null ||
        (_selectedDate!.year == now.year &&
            _selectedDate!.month == now.month &&
            _selectedDate!.day == now.day);
    final dateLabel = _selectedDate != null
        ? DateFormat('EEE, d MMM yyyy').format(_selectedDate!)
        : 'Today (${DateFormat('d MMM').format(now)})';

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          const SizedBox(height: AppDimensions.md),
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
              ),
            ),
          ),

          // Scrollable filter content
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                AppDimensions.base,
                AppDimensions.base,
                AppDimensions.base,
                AppDimensions.base,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Filters', style: AppTextStyles.h2),
                  const SizedBox(height: AppDimensions.lg),

                  // ── DELIVERY DATE ────────────────────────────────────────────
                  Text('DELIVERY DATE', style: AppTextStyles.label),
                  const SizedBox(height: AppDimensions.sm),
                  GestureDetector(
                    onTap: _pickDate,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppDimensions.base,
                        vertical: AppDimensions.md,
                      ),
                      decoration: BoxDecoration(
                        color: isToday
                            ? AppColors.inputBg
                            : AppColors.primaryLight,
                        borderRadius:
                            BorderRadius.circular(AppDimensions.radiusMd),
                        border: Border.all(
                          color: isToday
                              ? AppColors.border
                              : AppColors.primary.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.event_rounded,
                            size: 18,
                            color: isToday
                                ? AppColors.textSecondary
                                : AppColors.primary,
                          ),
                          const SizedBox(width: AppDimensions.sm),
                          Expanded(
                            child: Text(
                              dateLabel,
                              style: AppTextStyles.body.copyWith(
                                color: isToday
                                    ? AppColors.textPrimary
                                    : AppColors.primary,
                                fontWeight: isToday
                                    ? FontWeight.normal
                                    : FontWeight.w600,
                              ),
                            ),
                          ),
                          if (_selectedDate != null)
                            GestureDetector(
                              onTap: () =>
                                  setState(() => _selectedDate = null),
                              child: Icon(
                                Icons.close_rounded,
                                size: 16,
                                color: AppColors.primary,
                              ),
                            )
                          else
                            Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: AppColors.textSecondary,
                              size: 20,
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppDimensions.base),

                  // ── ORDER ID ────────────────────────────────────────────────
                  Text('ORDER ID', style: AppTextStyles.label),
                  const SizedBox(height: AppDimensions.sm),
                  _FilterTextField(
                    controller: _orderIdController,
                    hint: 'Full ID or last 4 digits',
                  ),
                  const SizedBox(height: AppDimensions.base),

                  // ── RIDER ───────────────────────────────────────────────────
                  Text('RIDER', style: AppTextStyles.label),
                  const SizedBox(height: AppDimensions.sm),
                  _FilterTextField(
                    controller: _riderController,
                    hint: 'Select a rider',
                    suffixIcon: const Icon(
                      Icons.search_rounded,
                      color: AppColors.textSecondary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(height: AppDimensions.base),

                  // ── PAYMENT TYPE ────────────────────────────────────────────
                  Text('PAYMENT TYPE', style: AppTextStyles.label),
                  const SizedBox(height: AppDimensions.sm),
                  Row(
                    children: [
                      _FilterToggleChip(
                        label: 'COD',
                        selected: _payment == DeliveryPaymentFilter.cod,
                        onTap: () => _togglePayment(DeliveryPaymentFilter.cod),
                      ),
                      const SizedBox(width: AppDimensions.sm),
                      _FilterToggleChip(
                        label: 'Prepaid',
                        selected: _payment == DeliveryPaymentFilter.prepaid,
                        onTap: () =>
                            _togglePayment(DeliveryPaymentFilter.prepaid),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppDimensions.base),

                  // ── SORT BY ─────────────────────────────────────────────────
                  Text('SORT BY', style: AppTextStyles.label),
                  const SizedBox(height: AppDimensions.sm),
                  Row(
                    children: [
                      _FilterToggleChip(
                        label: _deliveryTimeSortLabel,
                        selected: _isDeliveryTimeActive,
                        onTap: () => _toggleSort(
                          DeliverySortBy.deliveryTimeNewest,
                          DeliverySortBy.deliveryTimeOldest,
                        ),
                      ),
                      const SizedBox(width: AppDimensions.sm),
                      _FilterToggleChip(
                        label: _priceAmountSortLabel,
                        selected: _isPriceAmountActive,
                        onTap: () => _toggleSort(
                          DeliverySortBy.amountHighToLow,
                          DeliverySortBy.amountLowToHigh,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: AppDimensions.sm),
                ],
              ),
            ),
          ),

          // ── Action buttons ──────────────────────────────────────────────────
          const Divider(height: 1, color: AppColors.border),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppDimensions.base,
              AppDimensions.md,
              AppDimensions.base,
              AppDimensions.base,
            ),
            child: Row(
              children: [
                Expanded(child: _ClearButton(onTap: _clear)),
                const SizedBox(width: AppDimensions.sm),
                Expanded(child: _ApplyButton(onTap: _apply)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Private sub-widgets ────────────────────────────────────────────────────────

class _FilterTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final Widget? suffixIcon;

  const _FilterTextField({
    required this.controller,
    required this.hint,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      style: AppTextStyles.body,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: AppTextStyles.body.copyWith(color: AppColors.textHint),
        filled: true,
        fillColor: AppColors.inputBg,
        suffixIcon: suffixIcon,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.base,
          vertical: AppDimensions.md,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
    );
  }
}

class _FilterToggleChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterToggleChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.base,
          vertical: AppDimensions.sm + 2,
        ),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.bodyMedium.copyWith(
            color: selected ? Colors.white : AppColors.textPrimary,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class _ClearButton extends StatelessWidget {
  final VoidCallback onTap;

  const _ClearButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.textPrimary,
        side: const BorderSide(color: AppColors.border),
        padding: const EdgeInsets.symmetric(vertical: AppDimensions.md),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        ),
      ),
      child: Text('Clear', style: AppTextStyles.bodyMedium),
    );
  }
}

class _ApplyButton extends StatelessWidget {
  final VoidCallback onTap;

  const _ApplyButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: AppDimensions.md),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        ),
      ),
      child: Text(
        'Apply',
        style: AppTextStyles.bodyMedium.copyWith(color: Colors.white),
      ),
    );
  }
}
