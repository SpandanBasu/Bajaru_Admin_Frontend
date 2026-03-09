import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/providers/nav_provider.dart';

class AdminDrawer extends ConsumerWidget {
  const AdminDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(navIndexProvider);

    void navigateTo(int index) {
      ref.read(navIndexProvider.notifier).state = index;
      Navigator.of(context).pop(); // close drawer
    }

    return Drawer(
      backgroundColor: AppColors.surface,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppDimensions.base,
                AppDimensions.base,
                AppDimensions.base,
                AppDimensions.md,
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius:
                          BorderRadius.circular(AppDimensions.radiusMd),
                    ),
                    child: const Icon(
                      Icons.storefront_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: AppDimensions.md),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Bajaru', style: AppTextStyles.h3),
                      Text(
                        'Admin Panel',
                        style: AppTextStyles.caption
                            .copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Divider(color: AppColors.border, height: 1),
            const SizedBox(height: AppDimensions.sm),

            // Nav items
            _DrawerItem(
              icon: Icons.dashboard_rounded,
              label: 'Home',
              selected: currentIndex == 0,
              onTap: () => navigateTo(0),
            ),
            _DrawerItem(
              icon: Icons.shopping_basket_rounded,
              label: 'Procurement',
              selected: currentIndex == 1,
              onTap: () => navigateTo(1),
            ),
            _DrawerItem(
              icon: Icons.receipt_long_rounded,
              label: 'Packing Orders',
              selected: currentIndex == 2,
              onTap: () => navigateTo(2),
            ),
            _DrawerItem(
              icon: Icons.directions_bike_rounded,
              label: 'Riders',
              selected: currentIndex == 3,
              onTap: () => navigateTo(3),
            ),
            _DrawerItem(
              icon: Icons.delivery_dining_rounded,
              label: 'Deliveries',
              selected: currentIndex == 4,
              onTap: () => navigateTo(4),
            ),
            _DrawerItem(
              icon: Icons.inventory_2_rounded,
              label: 'Catalog',
              selected: currentIndex == 5,
              onTap: () => navigateTo(5),
            ),

            const Spacer(),
            Divider(color: AppColors.border, height: 1),

            // Footer
            Padding(
              padding: const EdgeInsets.all(AppDimensions.base),
              child: Text(
                'Bajaru Admin v1.0',
                style:
                    AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.sm,
        vertical: 2,
      ),
      child: Material(
        color: selected ? AppColors.primaryLight : Colors.transparent,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.md,
              vertical: AppDimensions.sm + 2,
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 22,
                  color: selected ? AppColors.primary : AppColors.textSecondary,
                ),
                const SizedBox(width: AppDimensions.md),
                Text(
                  label,
                  style: AppTextStyles.bodySemiBold.copyWith(
                    color: selected ? AppColors.primary : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
