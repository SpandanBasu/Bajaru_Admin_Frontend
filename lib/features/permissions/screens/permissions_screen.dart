import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/models/allowed_user.dart';
import '../../../core/models/warehouse.dart';
import '../../../core/providers/warehouse_provider.dart';
import '../../../widgets/common/admin_drawer.dart';
import '../providers/permissions_provider.dart';

class PermissionsScreen extends ConsumerStatefulWidget {
  const PermissionsScreen({super.key});

  @override
  ConsumerState<PermissionsScreen> createState() => _PermissionsScreenState();
}

class _PermissionsScreenState extends ConsumerState<PermissionsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Resolve super-admin status once at the shell level so both tabs share it.
    final superAdminAsync = ref.watch(isSuperAdminProvider);
    final isSuperAdmin = superAdminAsync.valueOrNull ?? false;

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
                  padding: const EdgeInsets.fromLTRB(24, 4, 24, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text('Permissions',
                              style: AppTextStyles.h1.copyWith(fontSize: 22)),
                          if (isSuperAdmin) ...[
                            const SizedBox(width: AppDimensions.sm),
                            _SuperAdminBadge(),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isSuperAdmin
                            ? 'Manage who can access Admin & Rider apps'
                            : 'Manage who can access the Rider app',
                        style: AppTextStyles.caption
                            .copyWith(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: AppDimensions.md),
                    ],
                  ),
                ),
                // ── Tab bar ──────────────────────────────────────────────────
                Container(
                  decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: AppColors.border)),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    labelStyle: AppTextStyles.bodySemiBold,
                    unselectedLabelStyle: AppTextStyles.body
                        .copyWith(color: AppColors.textSecondary),
                    labelColor: AppColors.primary,
                    unselectedLabelColor: AppColors.textSecondary,
                    indicatorColor: AppColors.primary,
                    indicatorWeight: 2.5,
                    tabs: const [
                      Tab(
                        icon: Icon(Icons.admin_panel_settings_rounded,
                            size: 18),
                        text: 'Admins',
                        iconMargin: EdgeInsets.only(bottom: 2),
                      ),
                      Tab(
                        icon: Icon(Icons.directions_bike_rounded, size: 18),
                        text: 'Riders',
                        iconMargin: EdgeInsets.only(bottom: 2),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Tab views ─────────────────────────────────────────────────────
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _AccessTab(
                  type: _AccessType.admin,
                  canWrite: isSuperAdmin,
                ),
                _AccessTab(
                  type: _AccessType.rider,
                  canWrite: true, // all admins can manage riders
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Super admin badge ─────────────────────────────────────────────────────────

class _SuperAdminBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
        border: Border.all(color: AppColors.warning.withAlpha(80)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star_rounded,
              size: 12, color: AppColors.warning),
          const SizedBox(width: 4),
          Text(
            'Super Admin',
            style: AppTextStyles.captionBold
                .copyWith(color: AppColors.warning, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

// ── Access type enum ──────────────────────────────────────────────────────────

enum _AccessType { admin, rider }

// ── Per-tab widget ────────────────────────────────────────────────────────────

class _AccessTab extends ConsumerStatefulWidget {
  const _AccessTab({required this.type, required this.canWrite});

  final _AccessType type;
  /// Whether the current user is allowed to add/remove entries in this tab.
  final bool canWrite;

  @override
  ConsumerState<_AccessTab> createState() => _AccessTabState();
}

class _AccessTabState extends ConsumerState<_AccessTab> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool get _isAdmin => widget.type == _AccessType.admin;

  AsyncValue<List<AllowedUserEntry>> get _state => _isAdmin
      ? ref.watch(allowedAdminsProvider)
      : ref.watch(allowedRidersProvider);

  Future<void> _refresh() {
    if (_isAdmin) {
      return ref.read(allowedAdminsProvider.notifier).refresh();
    }
    return ref.read(allowedRidersProvider.notifier).refresh();
  }

  Future<void> _add(String phone, String name,
      {bool isSuperAdmin = false, String warehouseId = ''}) {
    if (_isAdmin) {
      return ref
          .read(allowedAdminsProvider.notifier)
          .add(phone, name, isSuperAdmin: isSuperAdmin);
    }
    return ref
        .read(allowedRidersProvider.notifier)
        .add(phone, name, warehouseId);
  }

  Future<void> _remove(String phone) {
    if (_isAdmin) {
      return ref.read(allowedAdminsProvider.notifier).remove(phone);
    }
    return ref.read(allowedRidersProvider.notifier).remove(phone);
  }

  List<AllowedUserEntry> _filtered(List<AllowedUserEntry> list) {
    final q = _searchQuery.toLowerCase().trim();
    if (q.isEmpty) return list;
    return list
        .where((e) =>
            e.name.toLowerCase().contains(q) || e.phoneNumber.contains(q))
        .toList();
  }

  void _showAddDialog() {
    showDialog(
      context: context,
      builder: (ctx) => _AddEntryDialog(
        type: widget.type,
        onAdd: (phone, name,
            {bool isSuperAdmin = false, String warehouseId = ''}) async {
          try {
            await _add(phone, name,
                isSuperAdmin: isSuperAdmin, warehouseId: warehouseId);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                      '${_isAdmin ? 'Admin' : 'Rider'} added successfully.'),
                  backgroundColor: AppColors.success,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          } catch (e) {
            if (mounted) {
              final msg = e.toString().contains('409') ||
                      e.toString().toLowerCase().contains('already')
                  ? 'This phone number is already registered.'
                  : 'Failed to add. Please try again.';
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(msg),
                  backgroundColor: AppColors.error,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          }
        },
      ),
    );
  }

  void _confirmRemove(AllowedUserEntry entry) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        ),
        title: Text(
          'Remove ${_isAdmin ? 'Admin' : 'Rider'}',
          style: AppTextStyles.h3,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Remove access for:',
                style: AppTextStyles.caption
                    .copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: AppDimensions.xs),
            Row(
              children: [
                Text(entry.name, style: AppTextStyles.bodySemiBold),
                if (entry.isSuperAdmin) ...[
                  const SizedBox(width: AppDimensions.sm),
                  _SuperAdminBadge(),
                ],
              ],
            ),
            Text(entry.phoneNumber,
                style: AppTextStyles.caption
                    .copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: AppDimensions.md),
            Container(
              padding: const EdgeInsets.all(AppDimensions.md),
              decoration: BoxDecoration(
                color: AppColors.errorLight,
                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded,
                      size: 16, color: AppColors.error),
                  const SizedBox(width: AppDimensions.sm),
                  Expanded(
                    child: Text(
                      'This person will no longer be able to log in.',
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.error),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel',
                style: AppTextStyles.bodySemiBold
                    .copyWith(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              ),
            ),
            onPressed: () async {
              Navigator.of(context).pop();
              try {
                await _remove(entry.phoneNumber);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${entry.name} removed successfully.'),
                      backgroundColor: AppColors.success,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              } catch (_) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content:
                          Text('Failed to remove. Please try again.'),
                      backgroundColor: AppColors.error,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Column(
          children: [
            // ── Read-only banner for non-super-admins on Admins tab ──────────
            if (_isAdmin && !widget.canWrite)
              Container(
                width: double.infinity,
                color: AppColors.warningLight,
                padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.base,
                    vertical: AppDimensions.sm),
                child: Row(
                  children: [
                    const Icon(Icons.lock_outline_rounded,
                        size: 16, color: AppColors.warning),
                    const SizedBox(width: AppDimensions.sm),
                    Expanded(
                      child: Text(
                        'Only super admins can add or remove other admins.',
                        style: AppTextStyles.caption
                            .copyWith(color: AppColors.warning),
                      ),
                    ),
                  ],
                ),
              ),

            // ── Search bar ──────────────────────────────────────────────────
            Container(
              color: AppColors.surface,
              padding: const EdgeInsets.fromLTRB(
                AppDimensions.base,
                AppDimensions.sm,
                AppDimensions.base,
                AppDimensions.sm,
              ),
              child: Container(
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.inputBg,
                  borderRadius:
                      BorderRadius.circular(AppDimensions.radiusMd),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    const Padding(
                      padding: EdgeInsets.symmetric(
                          horizontal: AppDimensions.md),
                      child: Icon(Icons.search_rounded,
                          size: 20, color: AppColors.textHint),
                    ),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        style: AppTextStyles.body,
                        decoration: InputDecoration(
                          hintText: 'Search by name or phone…',
                          hintStyle: AppTextStyles.body
                              .copyWith(color: AppColors.textHint),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                          isDense: true,
                        ),
                        onChanged: (v) =>
                            setState(() => _searchQuery = v),
                      ),
                    ),
                    if (_searchQuery.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.close_rounded,
                            size: 18, color: AppColors.textHint),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      ),
                  ],
                ),
              ),
            ),
            const Divider(height: 1, color: AppColors.border),

            // ── List ────────────────────────────────────────────────────────
            Expanded(
              child: _state.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primary,
                  ),
                ),
                error: (e, _) => _ErrorState(onRetry: _refresh),
                data: (list) {
                  final filtered = _filtered(list);
                  return RefreshIndicator(
                    onRefresh: _refresh,
                    color: AppColors.primary,
                    child: filtered.isEmpty
                        ? _EmptyState(
                            isSearch: _searchQuery.isNotEmpty,
                            type: widget.type,
                            canWrite: widget.canWrite,
                            onAdd: _showAddDialog,
                          )
                        : ListView(
                            padding: const EdgeInsets.all(AppDimensions.base),
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: [
                              _CountBadge(
                                  count: filtered.length,
                                  type: widget.type),
                              const SizedBox(height: AppDimensions.md),
                              _EntryList(
                                entries: filtered,
                                canWrite: widget.canWrite,
                                showWarehouse: !_isAdmin,
                                onRemove: _confirmRemove,
                              ),
                              const SizedBox(height: 80),
                            ],
                          ),
                  );
                },
              ),
            ),
          ],
        ),

        // ── FAB — only shown when current user has write permission ─────────
        if (widget.canWrite)
          Positioned(
            right: AppDimensions.base,
            bottom: AppDimensions.base,
            child: FloatingActionButton.extended(
              heroTag: _isAdmin ? 'fab_admin' : 'fab_rider',
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 3,
              icon: const Icon(Icons.person_add_rounded, size: 20),
              label: Text(
                'Add ${_isAdmin ? 'Admin' : 'Rider'}',
                style: AppTextStyles.bodySemiBold
                    .copyWith(color: Colors.white),
              ),
              onPressed: _showAddDialog,
            ),
          ),
      ],
    );
  }
}

// ── Count badge ───────────────────────────────────────────────────────────────

class _CountBadge extends StatelessWidget {
  const _CountBadge({required this.count, required this.type});

  final int count;
  final _AccessType type;

  @override
  Widget build(BuildContext context) {
    final isAdmin = type == _AccessType.admin;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.md, vertical: AppDimensions.xs),
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            borderRadius:
                BorderRadius.circular(AppDimensions.radiusFull),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isAdmin
                    ? Icons.admin_panel_settings_rounded
                    : Icons.directions_bike_rounded,
                size: 14,
                color: AppColors.primary,
              ),
              const SizedBox(width: 6),
              Text(
                '$count ${isAdmin ? 'admin' : 'rider'}${count == 1 ? '' : 's'}',
                style: AppTextStyles.captionBold
                    .copyWith(color: AppColors.primary),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Entry list ────────────────────────────────────────────────────────────────

class _EntryList extends StatelessWidget {
  const _EntryList({
    required this.entries,
    required this.canWrite,
    required this.showWarehouse,
    required this.onRemove,
  });

  final List<AllowedUserEntry> entries;
  final bool canWrite;
  final bool showWarehouse;
  final void Function(AllowedUserEntry) onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Table header
          Container(
            color: AppColors.inputBg,
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.base,
              vertical: AppDimensions.sm + 2,
            ),
            child: Row(
              children: [
                Expanded(
                    flex: 3,
                    child: Text('NAME & PHONE', style: AppTextStyles.label)),
                if (showWarehouse)
                  Expanded(
                      flex: 2,
                      child:
                          Text('WAREHOUSE', style: AppTextStyles.label)),
                Expanded(
                    flex: 2,
                    child: Text('ADDED ON', style: AppTextStyles.label)),
                SizedBox(width: canWrite ? 40 : 0),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),
          for (int i = 0; i < entries.length; i++) ...[
            _EntryRow(
                entry: entries[i],
                canWrite: canWrite,
                showWarehouse: showWarehouse,
                onRemove: onRemove),
            if (i < entries.length - 1)
              const Divider(height: 1, color: AppColors.border),
          ],
        ],
      ),
    );
  }
}

// ── Single row ────────────────────────────────────────────────────────────────

class _EntryRow extends StatelessWidget {
  const _EntryRow({
    required this.entry,
    required this.canWrite,
    required this.showWarehouse,
    required this.onRemove,
  });

  final AllowedUserEntry entry;
  final bool canWrite;
  final bool showWarehouse;
  final void Function(AllowedUserEntry) onRemove;

  @override
  Widget build(BuildContext context) {
    final initials = entry.name
        .trim()
        .split(' ')
        .where((w) => w.isNotEmpty)
        .take(2)
        .map((w) => w[0].toUpperCase())
        .join();

    final avatarColor = AppColors.avatarColors[
        entry.name.codeUnitAt(0) % AppColors.avatarColors.length];

    final addedDate = _formatDate(entry.createdAt);

    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.base, vertical: AppDimensions.md),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: avatarColor.withAlpha(30),
              borderRadius:
                  BorderRadius.circular(AppDimensions.radiusFull),
              border: Border.all(color: avatarColor.withAlpha(60)),
            ),
            child: Center(
              child: Text(
                initials,
                style: AppTextStyles.captionBold
                    .copyWith(color: avatarColor, fontSize: 13),
              ),
            ),
          ),
          const SizedBox(width: AppDimensions.md),

          // Name + phone + optional super admin badge
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(entry.name,
                          style: AppTextStyles.bodySemiBold,
                          overflow: TextOverflow.ellipsis),
                    ),
                    if (entry.isSuperAdmin) ...[
                      const SizedBox(width: 6),
                      _SuperAdminBadge(),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  entry.phoneNumber,
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),

          // Warehouse — only shown for rider rows
          if (showWarehouse)
            Expanded(
              flex: 2,
              child: Text(
                entry.warehouseId ?? '—',
                style: AppTextStyles.caption
                    .copyWith(color: AppColors.textSecondary),
                overflow: TextOverflow.ellipsis,
              ),
            ),

          // Date
          Expanded(
            flex: 2,
            child: Text(
              addedDate,
              style: AppTextStyles.caption
                  .copyWith(color: AppColors.textSecondary),
            ),
          ),

          // Remove button — hidden for read-only viewers
          if (canWrite)
            IconButton(
              icon: const Icon(Icons.remove_circle_outline_rounded,
                  size: 20, color: AppColors.error),
              tooltip: 'Remove access',
              onPressed: () => onRemove(entry),
            )
          else
            const SizedBox(width: 0),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }
}

// ── Empty / error states ──────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.isSearch,
    required this.type,
    required this.canWrite,
    required this.onAdd,
  });

  final bool isSearch;
  final _AccessType type;
  final bool canWrite;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final isAdmin = type == _AccessType.admin;
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 64),
          child: Column(
            children: [
              Icon(
                isSearch
                    ? Icons.search_off_rounded
                    : Icons.lock_person_rounded,
                size: 52,
                color: AppColors.textHint,
              ),
              const SizedBox(height: AppDimensions.md),
              Text(
                isSearch
                    ? 'No results found'
                    : 'No ${isAdmin ? 'admins' : 'riders'} yet',
                style: AppTextStyles.bodySemiBold
                    .copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppDimensions.xs),
              Text(
                isSearch
                    ? 'Try a different name or phone number'
                    : canWrite
                        ? 'Tap the button below to add the first ${isAdmin ? 'admin' : 'rider'}'
                        : 'No ${isAdmin ? 'admins' : 'riders'} have been added yet',
                style: AppTextStyles.caption
                    .copyWith(color: AppColors.textHint),
                textAlign: TextAlign.center,
              ),
              if (!isSearch && canWrite) ...[
                const SizedBox(height: AppDimensions.xl),
                OutlinedButton.icon(
                  onPressed: onAdd,
                  icon: const Icon(Icons.person_add_rounded, size: 18),
                  label: Text(
                    'Add ${isAdmin ? 'Admin' : 'Rider'}',
                    style: AppTextStyles.bodySemiBold
                        .copyWith(color: AppColors.primary),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppDimensions.radiusMd),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppDimensions.xl,
                        vertical: AppDimensions.md),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded,
                size: 48, color: AppColors.textHint),
            const SizedBox(height: AppDimensions.md),
            Text('Failed to load',
                style: AppTextStyles.bodySemiBold
                    .copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: AppDimensions.xs),
            Text('Check your connection and try again',
                style:
                    AppTextStyles.caption.copyWith(color: AppColors.textHint)),
            const SizedBox(height: AppDimensions.lg),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Retry'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(AppDimensions.radiusMd),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Add entry dialog ──────────────────────────────────────────────────────────

class _AddEntryDialog extends ConsumerStatefulWidget {
  const _AddEntryDialog({required this.type, required this.onAdd});

  final _AccessType type;
  final Future<void> Function(String phone, String name,
      {bool isSuperAdmin, String warehouseId}) onAdd;

  @override
  ConsumerState<_AddEntryDialog> createState() => _AddEntryDialogState();
}

class _AddEntryDialogState extends ConsumerState<_AddEntryDialog> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _nameController = TextEditingController();
  bool _isSuperAdmin = false;
  bool _loading = false;
  Warehouse? _selectedWarehouse;

  bool get _isAdmin => widget.type == _AccessType.admin;

  @override
  void dispose() {
    _phoneController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_isAdmin && _selectedWarehouse == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a warehouse'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      await widget.onAdd(
        _phoneController.text.trim(),
        _nameController.text.trim(),
        isSuperAdmin: _isSuperAdmin,
        warehouseId: _selectedWarehouse?.warehouseId ?? '',
      );
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
      ),
      title: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            ),
            child: Icon(
              _isAdmin
                  ? Icons.admin_panel_settings_rounded
                  : Icons.directions_bike_rounded,
              color: AppColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: AppDimensions.md),
          Text('Add ${_isAdmin ? 'Admin' : 'Rider'}',
              style: AppTextStyles.h3),
        ],
      ),
      content: SingleChildScrollView(
        child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Phone Number', style: AppTextStyles.label),
            const SizedBox(height: AppDimensions.xs),
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(10),
              ],
              style: AppTextStyles.body,
              decoration: _inputDecoration('10-digit mobile number'),
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Phone number is required';
                }
                if (v.trim().length != 10) {
                  return 'Enter a valid 10-digit number';
                }
                return null;
              },
            ),
            const SizedBox(height: AppDimensions.md),
            Text('Full Name', style: AppTextStyles.label),
            const SizedBox(height: AppDimensions.xs),
            TextFormField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              style: AppTextStyles.body,
              decoration: _inputDecoration('e.g. Rahul Sharma'),
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Name is required';
                }
                return null;
              },
            ),

            // Warehouse dropdown — only shown when adding a rider
            if (!_isAdmin) ...[
              const SizedBox(height: AppDimensions.md),
              Text('Warehouse', style: AppTextStyles.label),
              const SizedBox(height: AppDimensions.xs),
              _WarehousePickerField(
                selected: _selectedWarehouse,
                onChanged: (wh) => setState(() => _selectedWarehouse = wh),
              ),
            ],

            // Super admin toggle — only shown when adding an admin
            if (_isAdmin) ...[
              const SizedBox(height: AppDimensions.md),
              Container(
                decoration: BoxDecoration(
                  color: _isSuperAdmin
                      ? const Color(0xFFFFF3E0)
                      : AppColors.inputBg,
                  borderRadius:
                      BorderRadius.circular(AppDimensions.radiusMd),
                  border: Border.all(
                    color: _isSuperAdmin
                        ? AppColors.warning.withAlpha(80)
                        : AppColors.border,
                  ),
                ),
                child: SwitchListTile(
                  dense: true,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.md),
                  title: Text('Super Admin',
                      style: AppTextStyles.bodySemiBold),
                  subtitle: Text(
                    'Can add & remove other admins',
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.textSecondary),
                  ),
                  secondary: Icon(
                    Icons.star_rounded,
                    color:
                        _isSuperAdmin ? AppColors.warning : AppColors.textHint,
                    size: 20,
                  ),
                  activeColor: AppColors.warning,
                  value: _isSuperAdmin,
                  onChanged: (v) => setState(() => _isSuperAdmin = v),
                ),
              ),
            ],
          ],
        ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _loading ? null : () => Navigator.of(context).pop(),
          child: Text('Cancel',
              style: AppTextStyles.bodySemiBold
                  .copyWith(color: AppColors.textSecondary)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            ),
          ),
          onPressed: _loading ? null : _submit,
          child: _loading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
              : Text('Add ${_isAdmin ? 'Admin' : 'Rider'}'),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: AppTextStyles.body.copyWith(color: AppColors.textHint),
        filled: true,
        fillColor: AppColors.inputBg,
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
        contentPadding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.md, vertical: AppDimensions.sm + 2),
      );
}

// ── Warehouse picker field ────────────────────────────────────────────────────

class _WarehousePickerField extends ConsumerWidget {
  const _WarehousePickerField({
    required this.selected,
    required this.onChanged,
  });

  final Warehouse? selected;
  final ValueChanged<Warehouse?> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final warehousesAsync = ref.watch(warehousesProvider);
    final warehouses = warehousesAsync.asData?.value ?? [];
    final isLoading = warehousesAsync.isLoading;

    return GestureDetector(
      onTap: isLoading
          ? null
          : () => _showPicker(context, warehouses),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.md,
          vertical: AppDimensions.sm + 2,
        ),
        decoration: BoxDecoration(
          color: AppColors.inputBg,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          border: Border.all(
            color: selected == null ? AppColors.error : AppColors.border,
          ),
        ),
        child: Row(
          children: [
            if (isLoading)
              const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                    strokeWidth: 1.5, color: AppColors.primary),
              )
            else
              Expanded(
                child: Text(
                  selected?.displayName ?? 'Select a warehouse…',
                  style: AppTextStyles.body.copyWith(
                    color: selected == null
                        ? AppColors.textHint
                        : AppColors.textPrimary,
                  ),
                ),
              ),
            const Icon(Icons.keyboard_arrow_down_rounded,
                size: 18, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }

  void _showPicker(BuildContext context, List<Warehouse> warehouses) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(AppDimensions.base),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppDimensions.base),
            Text('Select Warehouse', style: AppTextStyles.h3),
            const SizedBox(height: AppDimensions.xs),
            for (final wh in warehouses)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(wh.displayName, style: AppTextStyles.body),
                subtitle: Text(
                  wh.warehouseId,
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.textHint),
                ),
                trailing: selected?.warehouseId == wh.warehouseId
                    ? const Icon(Icons.check_circle_rounded,
                        color: AppColors.primary)
                    : const Icon(Icons.circle_outlined,
                        color: AppColors.border),
                onTap: () {
                  Navigator.pop(context);
                  onChanged(wh);
                },
              ),
            const SizedBox(height: AppDimensions.base),
          ],
        ),
      ),
    );
  }
}
