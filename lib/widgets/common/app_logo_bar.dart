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
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return AppBar(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      elevation: 0,
      titleSpacing: 24, // <-- nudges the logo right (default is ~16)
      title: Image.asset('assets/images/full.png', height: 32),
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