import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/customer_support_provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../widgets/common/admin_drawer.dart';
import '../../../widgets/customer_support/cs_search_bar.dart';
import '../../../widgets/customer_support/cs_results_table.dart';
import 'cs_customer_profile_screen.dart';

class CustomerSupportScreen extends ConsumerStatefulWidget {
  const CustomerSupportScreen({super.key});

  @override
  ConsumerState<CustomerSupportScreen> createState() =>
      _CustomerSupportScreenState();
}

class _CustomerSupportScreenState
    extends ConsumerState<CustomerSupportScreen> {
  final _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    // Clear query so stale results don't show on re-open
    Future.microtask(
        () => ref.read(csSearchQueryProvider.notifier).state = '');
    super.dispose();
  }

  void _onSearchChanged(String value) {
    // Debounce 400 ms — avoids an API call on every keystroke
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      ref.read(csSearchQueryProvider.notifier).state = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    final searchAsync = ref.watch(csSearchResultsProvider);
    final query = ref.watch(csSearchQueryProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      drawer: const AdminDrawer(),
      body: Column(
        children: [
          // ── White header ──────────────────────────────────────────────────
          Container(
            color: AppColors.surface,
            child: Column(
              children: [
                SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.base,
                      vertical: AppDimensions.xs,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Builder(
                          builder: (ctx) => IconButton(
                            icon: const Icon(Icons.menu_rounded),
                            color: AppColors.textSecondary,
                            onPressed: () => Scaffold.of(ctx).openDrawer(),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.notifications_outlined),
                          color: AppColors.textSecondary,
                          onPressed: () {},
                        ),
                      ],
                    ),
                  ),
                ),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(24, 4, 24, 12),
                  decoration: const BoxDecoration(
                    border:
                        Border(bottom: BorderSide(color: AppColors.border)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Customer Support',
                          style: AppTextStyles.h1.copyWith(fontSize: 22)),
                      const SizedBox(height: 2),
                      Text('Search & resolve customer issues',
                          style: AppTextStyles.caption
                              .copyWith(color: AppColors.textSecondary)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Search bar ────────────────────────────────────────────────────
          CsSearchBar(
            controller: _searchController,
            onChanged: _onSearchChanged,
          ),

          // ── Results ───────────────────────────────────────────────────────
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(csSearchResultsProvider);
                await ref.read(csSearchResultsProvider.future);
              },
              color: AppColors.primary,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(AppDimensions.base),
                children: [
                  if (query.trim().isEmpty)
                    const _EmptyPrompt()
                  else
                    searchAsync.when(
                      loading: () => const _SearchLoading(),
                      error: (e, _) => _SearchError(message: e.toString()),
                      data: (results) => results.isEmpty
                          ? const _NoResults()
                          : CsResultsTable(
                              results: results,
                              onViewTap: (customer) {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => CsCustomerProfileScreen(
                                      customerId: customer.id,
                                      customerName: customer.name,
                                    ),
                                  ),
                                );
                              },
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
}

// ─── State widgets ────────────────────────────────────────────────────────────

class _EmptyPrompt extends StatelessWidget {
  const _EmptyPrompt();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 56),
      child: Column(
        children: [
          Icon(Icons.manage_search_rounded,
              size: 52, color: AppColors.textHint),
          const SizedBox(height: AppDimensions.md),
          Text('Search for a customer',
              style: AppTextStyles.bodySemiBold
                  .copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: AppDimensions.xs),
          Text('Phone, Order ID (or last 4 digits), or name',
              style:
                  AppTextStyles.caption.copyWith(color: AppColors.textHint)),
        ],
      ),
    );
  }
}

class _SearchLoading extends StatelessWidget {
  const _SearchLoading();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 56),
      child: Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: AppColors.primary,
        ),
      ),
    );
  }
}

class _SearchError extends StatelessWidget {
  final String message;

  const _SearchError({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          Icon(Icons.cloud_off_rounded, size: 48, color: AppColors.textHint),
          const SizedBox(height: AppDimensions.md),
          Text('Search failed',
              style: AppTextStyles.bodySemiBold
                  .copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: AppDimensions.xs),
          Text(
            message,
            style: AppTextStyles.caption
                .copyWith(color: AppColors.textHint),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _NoResults extends StatelessWidget {
  const _NoResults();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 56),
      child: Column(
        children: [
          Icon(Icons.person_search_rounded,
              size: 52, color: AppColors.textHint),
          const SizedBox(height: AppDimensions.md),
          Text('No customers found',
              style: AppTextStyles.bodySemiBold
                  .copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: AppDimensions.xs),
          Text('Try a different phone number or name',
              style:
                  AppTextStyles.caption.copyWith(color: AppColors.textHint)),
        ],
      ),
    );
  }
}

