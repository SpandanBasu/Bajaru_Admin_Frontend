import 'package:flutter/material.dart';
import '../../core/models/catalog_product.dart';
import '../../core/models/pincode.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/constants/app_dimensions.dart';

class CatalogProductTile extends StatelessWidget {
  final CatalogProduct product;
  final PincodeProductData? pincodeData;
  final VoidCallback? onToggleAvailability; // null = locked (OOS or no pincode)
  final VoidCallback? onTap;

  const CatalogProductTile({
    super.key,
    required this.product,
    required this.pincodeData,
    required this.onToggleAvailability,
    required this.onTap,
  });

  Color _categoryColor(ProductCategory c) => switch (c) {
        ProductCategory.leafy  => AppColors.success,
        ProductCategory.root   => AppColors.warning,
        ProductCategory.exotic => const Color(0xFF9C27B0),
        ProductCategory.all    => AppColors.textSecondary,
      };

  IconData _categoryIcon(ProductCategory c) => switch (c) {
        ProductCategory.leafy  => Icons.eco_rounded,
        ProductCategory.root   => Icons.grass_rounded,
        ProductCategory.exotic => Icons.star_rounded,
        ProductCategory.all    => Icons.grid_view_rounded,
      };

  @override
  Widget build(BuildContext context) {
    final catColor   = _categoryColor(product.category);
    final isActive   = !product.isOutOfStock && (pincodeData?.isAvailable ?? false);
    final stockQty   = pincodeData?.stock;
    final price      = pincodeData?.price;
    final priceUnit  = pincodeData?.priceUnit;

    final stockText  = stockQty != null
        ? (stockQty % 1 == 0 ? '${stockQty.toInt()} kg' : '$stockQty kg')
        : '— kg';
    final priceText  = (price != null && priceUnit != null)
        ? '₹${price.toStringAsFixed(0)}/$priceUnit'
        : '—';

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.base,
          vertical: AppDimensions.md,
        ),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border(bottom: BorderSide(color: AppColors.border)),
        ),
        child: Row(
          children: [
            // ── Circular category icon ────────────────────────────────────
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: catColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: product.imageUrl != null
                  ? ClipOval(
                      child: Image.network(
                        product.imageUrl!,
                        fit: BoxFit.cover,
                        width: 44,
                        height: 44,
                        errorBuilder: (_, __, ___) => Icon(
                          _categoryIcon(product.category),
                          color: catColor,
                          size: 22,
                        ),
                      ),
                    )
                  : Icon(_categoryIcon(product.category), color: catColor, size: 22),
            ),
            const SizedBox(width: AppDimensions.md),

            // ── Product info ──────────────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name
                  Text(
                    product.name,
                    style: AppTextStyles.bodySemiBold,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  // Category • Price [• Out of Stock]
                  Row(
                    children: [
                      Text(
                        '${product.category.label} • $priceText',
                        style: AppTextStyles.caption
                            .copyWith(color: AppColors.textSecondary),
                      ),
                      if (product.isOutOfStock) ...[
                        const SizedBox(width: 6),
                        Text(
                          '• Out of Stock',
                          style: AppTextStyles.caption
                              .copyWith(color: AppColors.error),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  // Stock qty • package size
                  Row(
                    children: [
                      Text(
                        stockText,
                        style: AppTextStyles.captionMedium.copyWith(
                          color: product.isOutOfStock
                              ? AppColors.textHint
                              : AppColors.primary,
                        ),
                      ),
                      Text(
                        '  •  ${product.packageSize}',
                        style: AppTextStyles.caption
                            .copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppDimensions.sm),

            // ── Availability toggle ───────────────────────────────────────
            GestureDetector(
              onTap: onToggleAvailability,
              behavior: HitTestBehavior.opaque,
              child: IgnorePointer(
                child: Switch(
                  value: isActive,
                  onChanged: onToggleAvailability != null ? (_) {} : null,
                  activeColor: Colors.white,
                  activeTrackColor: AppColors.success,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
