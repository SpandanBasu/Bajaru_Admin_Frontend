import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/customer_support_provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/models/cs_customer.dart';
import '../../../widgets/customer_support/cs_nav_bar.dart';
import '../../../widgets/customer_support/cs_profile_card.dart';
import '../../../widgets/customer_support/cs_order_card.dart';
import '../../deliveries/screens/order_detail_screen.dart';
import 'cs_payment_ledger_screen.dart';

class CsCustomerProfileScreen extends ConsumerStatefulWidget {
  final String customerId;
  final String customerName;

  const CsCustomerProfileScreen({
    super.key,
    required this.customerId,
    required this.customerName,
  });

  @override
  ConsumerState<CsCustomerProfileScreen> createState() =>
      _CsCustomerProfileScreenState();
}

class _CsCustomerProfileScreenState
    extends ConsumerState<CsCustomerProfileScreen> {
  final _scrollController = ScrollController();

  // Orders loaded beyond the first page embedded in detail response.
  final List<SupportOrder> _extraOrders = [];
  bool _hasMore = false;
  bool _isLoadingMore = false;
  int _nextPage = 1;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  void _initFromDetail(CustomerDetail customer) {
    // Only initialise once (when _nextPage is still 1 and _extraOrders empty).
    if (_nextPage == 1 && _extraOrders.isEmpty) {
      _hasMore = customer.hasMoreOrders;
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore) return;
    setState(() => _isLoadingMore = true);
    final result = await ref.read(csServiceProvider).getCustomerOrders(
          widget.customerId,
          page: _nextPage,
        );
    if (mounted) {
      setState(() {
        _extraOrders.addAll(result.orders);
        _hasMore = result.hasMore;
        _nextPage++;
        _isLoadingMore = false;
      });
    }
  }

  void _openOrderDetail(String orderId) {
    final rawId = orderId.replaceAll('#', '').trim();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => OrderDetailScreen(orderId: rawId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(csCustomerDetailProvider(widget.customerId));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          CsNavBar(
            title: detailAsync.maybeWhen(
              data: (d) => d.name,
              orElse: () => widget.customerName,
            ),
            subtitle: 'Customer Profile',
            onBack: () => Navigator.of(context).pop(),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                setState(() {
                  _extraOrders.clear();
                  _nextPage = 1;
                  _hasMore = false;
                });
                ref.invalidate(csCustomerDetailProvider(widget.customerId));
                await ref
                    .read(csCustomerDetailProvider(widget.customerId).future);
              },
              color: AppColors.primary,
              child: detailAsync.when(
                loading: () => SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: SizedBox(
                    height: MediaQuery.of(context).size.height - 150,
                    child: const _ProfileLoading(),
                  ),
                ),
                error: (e, _) => SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: SizedBox(
                    height: MediaQuery.of(context).size.height - 150,
                    child: _ProfileError(
                      message: e.toString(),
                      onRetry: () => ref.invalidate(
                          csCustomerDetailProvider(widget.customerId)),
                    ),
                  ),
                ),
                data: (customer) {
                  _initFromDetail(customer);
                  final allOrders = [
                    ...customer.orderHistory,
                    ..._extraOrders,
                  ];
                  return ListView(
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(AppDimensions.base),
                    children: [
                      CsProfileCard(
                        customer: customer,
                        onPaymentTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => CsPaymentLedgerScreen(
                              customerId: widget.customerId,
                              customerName: customer.name,
                            ),
                          ),
                        ),
                      ),
                      if (allOrders.isNotEmpty) ...[
                        const SizedBox(height: AppDimensions.base),
                        Text(
                          'ORDER HISTORY',
                          style: AppTextStyles.label.copyWith(
                            color: AppColors.textHint,
                            letterSpacing: 1,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: AppDimensions.sm),
                        ...allOrders.map((order) => Padding(
                              padding: const EdgeInsets.only(
                                  bottom: AppDimensions.sm),
                              child: CsOrderCard(
                                order: order,
                                initiallyExpanded: false,
                                onSeeDetails: () =>
                                    _openOrderDetail(order.orderId),
                              ),
                            )),
                        if (_isLoadingMore) ...[
                          const SizedBox(height: AppDimensions.sm),
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                  vertical: AppDimensions.base),
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ],
                      const SizedBox(height: AppDimensions.base),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Loading / error states ────────────────────────────────────────────────────

class _ProfileLoading extends StatelessWidget {
  const _ProfileLoading();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
    );
  }
}

class _ProfileError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ProfileError({required this.message, required this.onRetry});

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
            Text('Failed to load profile',
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
