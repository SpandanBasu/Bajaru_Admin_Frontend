import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/models/catalog_product.dart';
import '../../core/models/pincode.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/constants/app_dimensions.dart';

class CatalogEditSheet extends StatefulWidget {
  final CatalogProduct product;
  final Pincode pincode;
  final void Function(double newStock, double newPrice, double newMrp) onSave;

  const CatalogEditSheet({
    super.key,
    required this.product,
    required this.pincode,
    required this.onSave,
  });

  @override
  State<CatalogEditSheet> createState() => _CatalogEditSheetState();
}

class _CatalogEditSheetState extends State<CatalogEditSheet> {
  late final TextEditingController _stockCtrl;
  late final TextEditingController _priceCtrl;
  late final TextEditingController _mrpCtrl;

  PincodeProductData? get _data => widget.product.dataFor(widget.pincode.code);

  Color get _catColor => switch (widget.product.category) {
        ProductCategory.leafy  => AppColors.success,
        ProductCategory.root   => AppColors.warning,
        ProductCategory.exotic => const Color(0xFF9C27B0),
        ProductCategory.all    => AppColors.textSecondary,
      };

  IconData get _catIcon => switch (widget.product.category) {
        ProductCategory.leafy  => Icons.eco_rounded,
        ProductCategory.root   => Icons.grass_rounded,
        ProductCategory.exotic => Icons.star_rounded,
        ProductCategory.all    => Icons.grid_view_rounded,
      };

  @override
  void initState() {
    super.initState();
    final data = _data;
    _stockCtrl = TextEditingController(
      text: data != null
          ? (data.stock % 1 == 0
              ? data.stock.toInt().toString()
              : data.stock.toString())
          : '',
    );
    _priceCtrl = TextEditingController(
      text: data?.price.toStringAsFixed(0) ?? '',
    );
    _mrpCtrl = TextEditingController(
      text: data?.mrp.toStringAsFixed(0) ?? '',
    );
  }

  @override
  void dispose() {
    _stockCtrl.dispose();
    _priceCtrl.dispose();
    _mrpCtrl.dispose();
    super.dispose();
  }

  void _save() {
    final newStock = double.tryParse(_stockCtrl.text.trim());
    final newPrice = double.tryParse(_priceCtrl.text.trim());
    final newMrp = double.tryParse(_mrpCtrl.text.trim());
    if (newStock == null || newPrice == null || newMrp == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter valid stock and price values')),
      );
      return;
    }
    widget.onSave(newStock, newPrice, newMrp);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final data       = _data;
    final isInStock  = !widget.product.isOutOfStock && (data?.isAvailable ?? false);
    final priceUnit  = data?.priceUnit ?? '';
    final currentStock = data != null
        ? (data.stock % 1 == 0
            ? '${data.stock.toInt()} kg'
            : '${data.stock} kg')
        : '—';
    final currentSellingPrice = data != null
        ? '₹${data.price.toStringAsFixed(0)}/$priceUnit'
        : '—';
    final currentMrp = data != null
        ? '₹${data.mrp.toStringAsFixed(0)}/$priceUnit'
        : '—';

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: AppDimensions.base,
        right: AppDimensions.base,
        top: AppDimensions.base,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppDimensions.base,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppDimensions.base),

            // ── Product header ────────────────────────────────────────────
            Row(
              children: [
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(
                    color: _catColor.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: widget.product.imageUrl != null
                      ? ClipOval(
                          child: Image.network(
                            widget.product.imageUrl!,
                            fit: BoxFit.cover,
                            width: 48,
                            height: 48,
                            errorBuilder: (_, __, ___) =>
                                Icon(_catIcon, color: _catColor, size: 24),
                          ),
                        )
                      : Icon(_catIcon, color: _catColor, size: 24),
                ),
                const SizedBox(width: AppDimensions.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.product.name, style: AppTextStyles.h3),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text(
                            '${widget.product.category.label} Greens',
                            style: AppTextStyles.caption
                                .copyWith(color: AppColors.textSecondary),
                          ),
                          const SizedBox(width: 6),
                          Text('•', style: AppTextStyles.caption
                              .copyWith(color: AppColors.textSecondary)),
                          const SizedBox(width: 6),
                          Container(
                            width: 8, height: 8,
                            decoration: BoxDecoration(
                              color: isInStock ? AppColors.success : AppColors.error,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isInStock ? 'In Stock' : 'Out of Stock',
                            style: AppTextStyles.caption.copyWith(
                              color: isInStock ? AppColors.success : AppColors.error,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.xl),

            // ── Packet Size (read-only) ───────────────────────────────────
            Text('Packet Size',
                style: AppTextStyles.captionMedium
                    .copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: AppDimensions.xs),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.md,
                vertical: AppDimensions.md,
              ),
              decoration: BoxDecoration(
                color: AppColors.inputBg,
                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                border: Border.all(color: AppColors.border),
              ),
              child: Text(widget.product.packageSize, style: AppTextStyles.body),
            ),
            const SizedBox(height: AppDimensions.xl),

            // ── Update Stock ──────────────────────────────────────────────
            Text(
              'UPDATE STOCK',
              style: AppTextStyles.label.copyWith(
                color: AppColors.textSecondary,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: AppDimensions.sm),
            Row(
              children: [
                Expanded(
                  child: _ReadonlyField(label: currentStock),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppDimensions.sm),
                  child: Icon(Icons.arrow_forward_rounded,
                      color: AppColors.textSecondary, size: 18),
                ),
                Expanded(
                  child: _EditableField(
                    controller: _stockCtrl,
                    suffix: 'kg',
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.xl),

            // ── Update Selling Price ───────────────────────────────────────
            Text(
              'SELLING PRICE (what customer pays)',
              style: AppTextStyles.label.copyWith(
                color: AppColors.textSecondary,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: AppDimensions.sm),
            Row(
              children: [
                Expanded(
                  child: _ReadonlyField(label: currentSellingPrice),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppDimensions.sm),
                  child: Icon(Icons.arrow_forward_rounded,
                      color: AppColors.textSecondary, size: 18),
                ),
                Expanded(
                  child: _EditableField(
                    controller: _priceCtrl,
                    prefix: '₹',
                    suffix: priceUnit,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.xl),

            // ── Update MRP ─────────────────────────────────────────────────
            Text(
              'MRP (Maximum Retail Price — for displaying savings)',
              style: AppTextStyles.label.copyWith(
                color: AppColors.textSecondary,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: AppDimensions.sm),
            Row(
              children: [
                Expanded(
                  child: _ReadonlyField(label: currentMrp),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppDimensions.sm),
                  child: Icon(Icons.arrow_forward_rounded,
                      color: AppColors.textSecondary, size: 18),
                ),
                Expanded(
                  child: _EditableField(
                    controller: _mrpCtrl,
                    prefix: '₹',
                    suffix: priceUnit,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.sm),
            Text(
              'Prices will apply to all new orders placed after this.',
              style: AppTextStyles.caption.copyWith(color: AppColors.textHint),
            ),
            const SizedBox(height: AppDimensions.xl),

            // ── Save button ───────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.check_rounded),
                label: const Text('Update Stock & Prices'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: AppDimensions.md),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                  ),
                  textStyle: AppTextStyles.bodySemiBold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReadonlyField extends StatelessWidget {
  final String label;
  const _ReadonlyField({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.md,
        vertical: AppDimensions.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.inputBg,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        label,
        style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
      ),
    );
  }
}

class _EditableField extends StatelessWidget {
  final TextEditingController controller;
  final String? prefix;
  final String? suffix;
  final TextInputType keyboardType;
  final List<TextInputFormatter> inputFormatters;

  const _EditableField({
    required this.controller,
    this.prefix,
    this.suffix,
    required this.keyboardType,
    required this.inputFormatters,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      style: AppTextStyles.body,
      decoration: InputDecoration(
        prefixText: prefix,
        suffixText: suffix,
        prefixStyle: AppTextStyles.body,
        suffixStyle: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          borderSide: BorderSide(color: AppColors.primary, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          borderSide: BorderSide(color: AppColors.primary, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          borderSide: BorderSide(color: AppColors.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.md,
          vertical: AppDimensions.md,
        ),
      ),
    );
  }
}
