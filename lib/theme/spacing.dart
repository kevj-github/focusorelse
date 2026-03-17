import 'package:flutter/material.dart';

/// Consistent spacing system for layouts
class AppSpacing {
  // Base spacing units
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 24.0;
  static const double xxl = 32.0;
  static const double xxxl = 48.0;

  // Common insets
  static const EdgeInsets paddingXs = EdgeInsets.all(xs);
  static const EdgeInsets paddingSm = EdgeInsets.all(sm);
  static const EdgeInsets paddingMd = EdgeInsets.all(md);
  static const EdgeInsets paddingLg = EdgeInsets.all(lg);
  static const EdgeInsets paddingXl = EdgeInsets.all(xl);

  // Horizontal insets
  static const EdgeInsets paddingHorizontalSm = EdgeInsets.symmetric(
    horizontal: sm,
  );
  static const EdgeInsets paddingHorizontalMd = EdgeInsets.symmetric(
    horizontal: md,
  );
  static const EdgeInsets paddingHorizontalLg = EdgeInsets.symmetric(
    horizontal: lg,
  );
  static const EdgeInsets paddingHorizontalXl = EdgeInsets.symmetric(
    horizontal: xl,
  );

  // Vertical insets
  static const EdgeInsets paddingVerticalSm = EdgeInsets.symmetric(
    vertical: sm,
  );
  static const EdgeInsets paddingVerticalMd = EdgeInsets.symmetric(
    vertical: md,
  );
  static const EdgeInsets paddingVerticalLg = EdgeInsets.symmetric(
    vertical: lg,
  );
  static const EdgeInsets paddingVerticalXl = EdgeInsets.symmetric(
    vertical: xl,
  );
}

/// Elevation and shadow system for modern depth
class AppElevation {
  // Border radius values
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 12.0;
  static const double radiusLarge = 16.0;
  static const double radiusXl = 20.0;
  static const double radiusCircle = 999.0;

  // Common border radius for specific components
  static const BorderRadius inputRadius = BorderRadius.all(
    Radius.circular(radiusSmall),
  );
  static const BorderRadius cardRadius = BorderRadius.all(
    Radius.circular(radiusMedium),
  );
  static const BorderRadius buttonRadius = BorderRadius.all(
    Radius.circular(radiusXl),
  );
  static const BorderRadius roundedRadius = BorderRadius.all(
    Radius.circular(radiusLarge),
  );

  // Shadow definitions
  static const List<BoxShadow> shadowNone = [];

  static const List<BoxShadow> shadowSmall = [
    BoxShadow(color: Color(0x0D000000), blurRadius: 4, offset: Offset(0, 2)),
  ];

  static const List<BoxShadow> shadowMedium = [
    BoxShadow(color: Color(0x14000000), blurRadius: 8, offset: Offset(0, 4)),
  ];

  static const List<BoxShadow> shadowLarge = [
    BoxShadow(color: Color(0x1A000000), blurRadius: 16, offset: Offset(0, 8)),
  ];

  static const List<BoxShadow> shadowXl = [
    BoxShadow(color: Color(0x24000000), blurRadius: 24, offset: Offset(0, 12)),
  ];
}
