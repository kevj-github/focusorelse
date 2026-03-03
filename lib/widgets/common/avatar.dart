import 'package:flutter/material.dart';
import '../../theme/colors.dart';

class AppAvatar extends StatelessWidget {
  const AppAvatar({super.key, this.imageUrl, this.radius = 18});

  final String? imageUrl;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.darkSurface,
      backgroundImage: imageUrl != null ? NetworkImage(imageUrl!) : null,
      child: imageUrl == null
          ? Icon(Icons.person, color: AppColors.textSecondaryDark, size: radius)
          : null,
    );
  }
}
