import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/constants/app_dimensions.dart';

class AdminAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final bool showBack;

  const AdminAppBar({
    super.key,
    required this.title,
    this.actions,
    this.showBack = false,
  });

  @override
  Size get preferredSize => const Size.fromHeight(60);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 1,
      shadowColor: Colors.black12,
      automaticallyImplyLeading: showBack,
      leading: showBack
          ? null
          : Builder(
              builder: (ctx) => IconButton(
                icon: const Icon(Icons.menu_rounded),
                color: AppColors.textSecondary,
                onPressed: () => Scaffold.of(ctx).openDrawer(),
              ),
            ),
      titleSpacing: AppDimensions.base,
      title: Text(title, style: AppTextStyles.h2),
      actions: actions != null
          ? [...actions!, const SizedBox(width: AppDimensions.sm)]
          : null,
    );
  }
}
