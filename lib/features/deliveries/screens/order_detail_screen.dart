import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/models/delivery_order.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_dimensions.dart';
import '../providers/deliveries_provider.dart';

class OrderDetailScreen extends ConsumerStatefulWidget {
  final String orderId;

  const OrderDetailScreen({super.key, required this.orderId});

  @override
  ConsumerState<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends ConsumerState<OrderDetailScreen> {
  Future<void> _refresh() async {
    ref.invalidate(orderDetailProvider(widget.orderId));
    await ref.read(orderDetailProvider(widget.orderId).future);
  }

  @override
  Widget build(BuildContext context) {
    final orderAsync = ref.watch(orderDetailProvider(widget.orderId));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: orderAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        ),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.base),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline_rounded,
                    size: 48, color: AppColors.textHint),
                const SizedBox(height: AppDimensions.md),
                Text(
                  err.toString(),
                  textAlign: TextAlign.center,
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: AppDimensions.md),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Go back'),
                ),
              ],
            ),
          ),
        ),
        data: (order) => Column(
          children: [
            _NavBar(order: order),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _refresh,
                color: AppColors.primary,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(AppDimensions.base),
                  children: [
                    _CustomerInfoCard(order: order),
                    const SizedBox(height: AppDimensions.md),
                    _OrderSummaryCard(order: order),
                    const SizedBox(height: AppDimensions.md),
                    _PaymentDetailsCard(order: order),
                    const SizedBox(height: AppDimensions.md),
                    if (order.status != DeliveryStatus.pending)
                      _DeliveryDetailsCard(order: order),
                    const SizedBox(height: AppDimensions.base),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Nav Bar ───────────────────────────────────────────────────────────────────

class _NavBar extends StatelessWidget {
  final DeliveryOrder order;
  const _NavBar({required this.order});

  @override
  Widget build(BuildContext context) {
    final (badgeBg, badgeFg) = switch (order.status) {
      DeliveryStatus.delivered      => (AppColors.success, Colors.white),
      DeliveryStatus.outForDelivery => (AppColors.primaryLight, AppColors.primary),
      DeliveryStatus.pending        => (AppColors.warningLight, AppColors.warning),
      DeliveryStatus.rejected       => (AppColors.errorLight, AppColors.error),
      DeliveryStatus.cancelled      => (AppColors.textHint.withValues(alpha: 0.15), AppColors.textSecondary),
    };

    return Container(
      color: AppColors.surface,
      child: SafeArea(
        bottom: false,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.base,
            vertical: AppDimensions.md,
          ),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(bottom: BorderSide(color: AppColors.border)),
          ),
          child: Row(
            children: [
              // Back button
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(
                      AppDimensions.radiusFull,
                    ),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Icon(
                    Icons.arrow_back_rounded,
                    size: 16,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: AppDimensions.md),

              // Order ID (last 4 chars) + copy icon + date
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          order.id.length <= 4
                              ? order.id
                              : '#${order.id.substring(order.id.length - 4)}',
                          style: AppTextStyles.h3.copyWith(fontSize: 18),
                        ),
                        const SizedBox(width: 6),
                        GestureDetector(
                          onTap: () {
                            Clipboard.setData(ClipboardData(text: order.id));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Order ID copied'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          },
                          child: Icon(
                            Icons.copy_rounded,
                            size: 16,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      'Placed: ${order.date}  ·  ${order.time}',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    if (order.deliveryDate != null)
                      Text(
                        'Delivery: ${DateFormat('MMM d, yyyy').format(order.deliveryDate!)}',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // Status badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                ),
                child: Text(
                  order.status.label,
                  style: AppTextStyles.label.copyWith(
                    color: badgeFg,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Section Card Shell ────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget body;

  const _SectionCard({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.body,
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
          // Header
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.base,
              vertical: AppDimensions.sm + 2,
            ),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              children: [
                Icon(icon, size: 16, color: AppColors.primary),
                const SizedBox(width: AppDimensions.sm),
                Text(
                  title,
                  style: AppTextStyles.bodySemiBold.copyWith(fontSize: 13),
                ),
                if (subtitle != null) ...[
                  const SizedBox(width: AppDimensions.sm),
                  Text(
                    subtitle!,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textHint,
                    ),
                  ),
                ],
              ],
            ),
          ),
          // Body
          Padding(
            padding: const EdgeInsets.all(AppDimensions.base),
            child: body,
          ),
        ],
      ),
    );
  }
}

// ── Customer Info Card ────────────────────────────────────────────────────────

class _CustomerInfoCard extends StatelessWidget {
  final DeliveryOrder order;
  const _CustomerInfoCard({required this.order});

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      icon: Icons.person_rounded,
      title: 'Customer Details',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  order.customerName,
                  style: AppTextStyles.bodySemiBold.copyWith(fontSize: 15),
                ),
              ),
              _CallButton(phone: order.phone),
            ],
          ),
          const SizedBox(height: AppDimensions.sm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.location_on_outlined,
                size: 14,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: AppDimensions.xs + 2),
              Expanded(
                child: Text(
                  order.fullAddress.isNotEmpty
                      ? order.fullAddress
                      : '${order.area}${order.pincodeCode.isNotEmpty ? ', ${order.pincodeCode}' : ''}',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.md),
          // Open in Google Maps button
          GestureDetector(
            onTap: () => _openGoogleMaps(order),
            behavior: HitTestBehavior.opaque,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: AppDimensions.sm),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                border: Border.all(color: AppColors.primary),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.navigation_rounded,
                    size: 14,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: AppDimensions.sm),
                  Text(
                    'Open in Google Maps',
                    style: AppTextStyles.captionMedium.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Future<void> _openGoogleMaps(DeliveryOrder order) async {
    final Uri uri;
    if (order.addressLatitude != null && order.addressLongitude != null) {
      uri = Uri.https(
        'www.google.com',
        '/maps/search/',
        {'api': '1', 'query': '${order.addressLatitude},${order.addressLongitude}'},
      );
    } else {
      final query = order.fullAddress.isNotEmpty
          ? order.fullAddress
          : '${order.area}${order.pincodeCode.isNotEmpty ? ', ${order.pincodeCode}' : ''}'.trim();
      if (query.isEmpty) return;
      uri = Uri.https(
        'www.google.com',
        '/maps/search/',
        {'api': '1', 'query': query},
      );
    }
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }
}

// ── Order Summary Card ────────────────────────────────────────────────────────

class _OrderSummaryCard extends StatefulWidget {
  final DeliveryOrder order;
  const _OrderSummaryCard({required this.order});

  @override
  State<_OrderSummaryCard> createState() => _OrderSummaryCardState();
}

class _OrderSummaryCardState extends State<_OrderSummaryCard> {
  bool _expanded = false;

  String _itemLabel(DeliveryOrderItem item) {
    if (item.name.isEmpty) {
      return item.displayQuantity.isNotEmpty ? 'Item · ${item.displayQuantity}' : 'Item';
    }
    return item.displayQuantity.isNotEmpty
        ? '${item.name} · ${item.displayQuantity}'
        : item.name;
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.order.items;
    final hasMore = items.length > 3;
    final visibleItems = (_expanded || !hasMore) ? items : items.take(3).toList();
    final remainCount = items.length - 3;
    final remainPrice = items.skip(3).fold<int>(0, (s, i) => s + i.price);

    return _SectionCard(
      icon: Icons.shopping_bag_rounded,
      title: 'Order Summary',
      subtitle: '${widget.order.itemCount} items',
      body: Column(
        children: [
          for (final item in visibleItems) ...[
            _ItemRow(name: _itemLabel(item), value: '₹${item.price}'),
            const SizedBox(height: 6),
          ],

          // Collapsed: tappable "+X more" row
          if (!_expanded && hasMore) ...[
            GestureDetector(
              onTap: () => setState(() => _expanded = true),
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '+$remainCount more item${remainCount == 1 ? '' : 's'}',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                    Text(
                      '₹$remainPrice',
                      style: AppTextStyles.captionMedium
                          .copyWith(color: AppColors.primary),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.expand_more_rounded,
                        size: 16, color: AppColors.primary),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),
          ],

          // Expanded: "Show less" row
          if (_expanded && hasMore) ...[
            GestureDetector(
              onTap: () => setState(() => _expanded = false),
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Show less',
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.textHint),
                    ),
                    const SizedBox(width: 2),
                    const Icon(Icons.expand_less_rounded,
                        size: 16, color: AppColors.textHint),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),
          ],

          const Divider(color: AppColors.border, height: 16),
          Row(
            children: [
              Text(
                'Subtotal',
                style: AppTextStyles.bodySemiBold.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              Text(
                '₹${widget.order.amount}',
                style: AppTextStyles.bodySemiBold.copyWith(
                  fontSize: 16,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Payment Details Card ──────────────────────────────────────────────────────

class _PaymentDetailsCard extends StatelessWidget {
  final DeliveryOrder order;
  const _PaymentDetailsCard({required this.order});

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      icon: Icons.wallet_rounded,
      title: 'Payment Details',
      body: Column(
        children: [
          Row(
            children: [
              Text(
                'Payment Method',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: order.isCOD
                      ? AppColors.warningLight
                      : AppColors.successLight,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  order.isCOD ? 'Cash on Delivery' : 'Prepaid',
                  style: AppTextStyles.label.copyWith(
                    fontSize: 10,
                    color: order.isCOD ? AppColors.warning : AppColors.success,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.sm),
          _ItemRow(name: 'Order Amount', value: '₹${order.amount}'),
          const SizedBox(height: 6),
          _ItemRow(name: 'Delivery Fee', value: '₹${order.deliveryFee}'),
          if (order.bagCharge > 0) ...[
            const SizedBox(height: 6),
            _ItemRow(name: 'Bag Charge', value: '₹${order.bagCharge}'),
          ],
          if (order.couponDiscount > 0) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: Text(
                    order.couponCode != null
                        ? 'Coupon (${order.couponCode})'
                        : 'Coupon Discount',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.success,
                    ),
                  ),
                ),
                Text(
                  '- ₹${order.couponDiscount}',
                  style: AppTextStyles.captionMedium.copyWith(
                    color: AppColors.success,
                  ),
                ),
              ],
            ),
          ],
          const Divider(color: AppColors.border, height: 16),
          Row(
            children: [
              Text(
                order.status == DeliveryStatus.delivered
                    ? 'Amount Collected'
                    : 'Amount to be Collected',
                style: AppTextStyles.bodySemiBold.copyWith(
                  fontSize: 13,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              if (order.status == DeliveryStatus.delivered) ...[
                Icon(
                  Icons.check_circle_rounded,
                  size: 14,
                  color: AppColors.success,
                ),
                const SizedBox(width: 4),
              ],
              Text(
                '₹${order.finalTotal}',
                style: AppTextStyles.bodySemiBold.copyWith(
                  color: order.status == DeliveryStatus.delivered
                      ? AppColors.success
                      : AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Delivery Details Card ─────────────────────────────────────────────────────

class _DeliveryDetailsCard extends StatelessWidget {
  final DeliveryOrder order;
  const _DeliveryDetailsCard({required this.order});

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      icon: Icons.local_shipping_rounded,
      title: 'Delivery Details',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Rider row (first)
          if (order.riderName != null) ...[
            Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Rider Assigned',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      order.riderName!,
                      style: AppTextStyles.bodySemiBold.copyWith(fontSize: 13),
                    ),
                  ],
                ),
                const Spacer(),
                if (order.riderPhone != null)
                  _CallButton(phone: order.riderPhone!),
              ],
            ),
            const Divider(
              color: AppColors.border,
              height: AppDimensions.base + 4,
            ),
          ],

          // Rejection details (shown only for rejected orders)
          if (order.status == DeliveryStatus.rejected) ...[
            _RejectionBanner(order: order),
            const Divider(
              color: AppColors.border,
              height: AppDimensions.base + 4,
            ),
          ],

          // Three info boxes: Delivered At | Wait Time | Distance
          if (order.departedTime != null ||
              order.deliveredTime != null ||
              order.deliveryMinutes != null ||
              order.distanceKm != null) ...[
            Row(
              children: [
                Expanded(
                  child: _TimeStat(
                    label: order.status == DeliveryStatus.delivered
                        ? 'Delivered At'
                        : 'Departed',
                    value: (order.status == DeliveryStatus.delivered &&
                            order.deliveredTime != null)
                        ? order.deliveredTime!
                        : (order.departedTime ?? '-'),
                  ),
                ),
                const SizedBox(width: AppDimensions.sm),
                Expanded(
                  child: _TimeStat(
                    label: 'Wait Time',
                    value: order.deliveryMinutes != null
                        ? '${order.deliveryMinutes} min'
                        : '-',
                  ),
                ),
                const SizedBox(width: AppDimensions.sm),
                Expanded(
                  child: _TimeStat(
                    label: 'Distance',
                    value: order.distanceKm != null
                        ? '${order.distanceKm} km'
                        : '-',
                  ),
                ),
              ],
            ),
            const Divider(
              color: AppColors.border,
              height: AppDimensions.base + 4,
            ),
          ],

          // Proof of delivery
          if (order.status == DeliveryStatus.delivered) ...[
            Text(
              'PROOF OF DELIVERY',
              style: AppTextStyles.label.copyWith(
                color: AppColors.textSecondary,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: AppDimensions.sm),
            Container(
              width: double.infinity,
              height: 140,
              decoration: BoxDecoration(
                color: AppColors.neutralLight,
                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                border: Border.all(color: AppColors.border),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                child: (order.proofImageUrl != null &&
                        order.proofImageUrl!.trim().isNotEmpty)
                    ? Image.network(
                        order.proofImageUrl!.trim(),
                        fit: BoxFit.cover,
                        headers: const {
                          'Accept': 'image/*',
                          'User-Agent': 'BajaruAdmin/1.0',
                        },
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.primary,
                              ),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          if (kDebugMode) {
                            debugPrint(
                              '[OrderDetail] Proof image failed: url=${order.proofImageUrl} error=$error',
                            );
                          }
                          return _ProofImagePlaceholder(
                            label: 'Unable to load delivery photo',
                          );
                        },
                      )
                    : const _ProofImagePlaceholder(
                        label: 'Delivery photo not available',
                      ),
              ),
            ),
          ],

          // Customer rating
          if (order.customerRating != null) ...[
            const Divider(
              color: AppColors.border,
              height: AppDimensions.base + 4,
            ),
            Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Customer Rating',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      order.customerName,
                      style: AppTextStyles.captionMedium.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.warningLight,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.star_rounded,
                        size: 14,
                        color: AppColors.warning,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${order.customerRating!.toStringAsFixed(1)} / 5',
                        style: AppTextStyles.captionMedium.copyWith(
                          color: AppColors.warning,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ── Rejection Banner ──────────────────────────────────────────────────────────

class _RejectionBanner extends StatelessWidget {
  final DeliveryOrder order;
  const _RejectionBanner({required this.order});

  @override
  Widget build(BuildContext context) {
    final rejectedAt = order.rejectedAt;
    final reason = order.rejectionReason;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.md),
      decoration: BoxDecoration(
        color: AppColors.errorLight,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.cancel_outlined, size: 14, color: AppColors.error),
              const SizedBox(width: AppDimensions.xs + 2),
              Text(
                'ORDER REJECTED',
                style: AppTextStyles.label.copyWith(
                  color: AppColors.error,
                  letterSpacing: 0.8,
                ),
              ),
              if (rejectedAt != null) ...[
                const Spacer(),
                Text(
                  DateFormat('h:mm a').format(rejectedAt),
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
          if (reason != null && reason.isNotEmpty) ...[
            const SizedBox(height: AppDimensions.sm),
            Text(
              reason,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.error,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Time Stat Box ─────────────────────────────────────────────────────────────

class _TimeStat extends StatelessWidget {
  final String label;
  final String value;
  const _TimeStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.sm,
        vertical: AppDimensions.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            value,
            style: AppTextStyles.bodySemiBold.copyWith(
              fontSize: 13,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Shared: Item Row ──────────────────────────────────────────────────────────

class _ItemRow extends StatelessWidget {
  final String name;
  final String value;
  final bool muted;
  const _ItemRow({required this.name, required this.value, this.muted = false});

  @override
  Widget build(BuildContext context) {
    final color = muted ? AppColors.textHint : AppColors.textPrimary;
    return Row(
      children: [
        Expanded(
          child: Text(
            name,
            style: AppTextStyles.caption.copyWith(
              color: muted ? AppColors.textHint : AppColors.textSecondary,
              fontStyle: muted ? FontStyle.italic : FontStyle.normal,
            ),
          ),
        ),
        Text(value, style: AppTextStyles.captionMedium.copyWith(color: color)),
      ],
    );
  }
}

// ── Call Button ───────────────────────────────────────────────────────────────

class _CallButton extends StatelessWidget {
  final String phone;
  const _CallButton({required this.phone});

  Future<void> _launchCall() async {
    final uri = Uri.parse(
      'tel:${phone.replaceAll(RegExp(r'[\s\-\(\)]'), '')}',
    );
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      // No dialer available (e.g. some emulators)
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _launchCall,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.call_outlined, size: 13, color: AppColors.primary),
            const SizedBox(width: 4),
            Text(
              phone,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProofImagePlaceholder extends StatelessWidget {
  final String label;
  const _ProofImagePlaceholder({required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.image_outlined,
          size: 36,
          color: AppColors.textHint,
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: AppColors.textHint,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
