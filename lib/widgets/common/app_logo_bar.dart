import 'package:flutter/material.dart';
import '../../theme/colors.dart';

class AppLogoBar extends StatelessWidget implements PreferredSizeWidget {
  final Key? notificationKey;
  final VoidCallback? onNotificationTap;
  final VoidCallback? onSettingsTap;

  const AppLogoBar({
    this.notificationKey,
    this.onNotificationTap,
    this.onSettingsTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final barColor = isDark
        ? AppColors.darkSurface.withValues(alpha: 0.9)
        : Colors.white.withValues(alpha: 0.94);

    return AppBar(
      backgroundColor: barColor,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleSpacing: 16,
      shape: Border(bottom: BorderSide(color: borderColor)),
      title: SizedBox(
        height: 34,
        child: Align(
          alignment: Alignment.centerLeft,
          child: Image.asset(
            'assets/images/full.png',
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
          ),
        ),
      ),
      actions: [
        IconButton(
          key: notificationKey,
          icon: Icon(Icons.notifications_outlined, color: onSurface),
          onPressed: onNotificationTap,
        ),
        IconButton(
          icon: Icon(Icons.settings_outlined, color: onSurface),
          onPressed: onSettingsTap,
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
