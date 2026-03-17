import 'package:flutter/material.dart';

/// Reusable animation curves and durations for modern, smooth interactions
class AppAnimations {
  // Standard durations
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 500);

  // Cubic curves for natural motion
  static const Curve easeInOut = Curves.easeInOut;
  static const Curve easeOut = Curves.easeOut;
  static const Curve easeIn = Curves.easeIn;

  // Custom curves for modern feel
  static const Curve smoothOut = Curves.easeOutCubic;
  static const Curve smoothIn = Curves.easeInCubic;
  static const Curve bounce = Curves.elasticOut;

  /// Smooth fade in animation
  static Widget fadeIn(
    Widget child, {
    Duration duration = const Duration(milliseconds: 300),
    Curve curve = Curves.easeOut,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: duration,
      curve: curve,
      builder: (context, value, _) => Opacity(opacity: value, child: child),
    );
  }

  /// Scale up animation for entrance effects
  static Widget scaleIn(
    Widget child, {
    Duration duration = const Duration(milliseconds: 300),
    double beginScale = 0.9,
    Curve curve = Curves.easeOut,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: beginScale, end: 1),
      duration: duration,
      curve: curve,
      builder: (context, value, _) =>
          Transform.scale(scale: value, child: child),
    );
  }

  /// Slide in animation from the left
  static Widget slideInFromLeft(
    Widget child, {
    Duration duration = const Duration(milliseconds: 400),
    Curve curve = Curves.easeOut,
  }) {
    return TweenAnimationBuilder<Offset>(
      tween: Tween(begin: const Offset(-0.1, 0), end: Offset.zero),
      duration: duration,
      curve: curve,
      builder: (context, value, _) => Transform.translate(
        offset: Offset(value.dx * MediaQuery.of(context).size.width, 0),
        child: Opacity(opacity: 1 - (value.dx.abs() * 0.5), child: child),
      ),
    );
  }

  /// Slide in animation from the bottom
  static Widget slideInFromBottom(
    Widget child, {
    Duration duration = const Duration(milliseconds: 400),
    Curve curve = Curves.easeOut,
  }) {
    return TweenAnimationBuilder<Offset>(
      tween: Tween(begin: const Offset(0, 0.1), end: Offset.zero),
      duration: duration,
      curve: curve,
      builder: (context, value, _) => Transform.translate(
        offset: Offset(0, value.dy * MediaQuery.of(context).size.height),
        child: Opacity(opacity: 1 - (value.dy.abs() * 0.5), child: child),
      ),
    );
  }
}

/// Button tap animation mixin
mixin TapableAnimationMixin {
  @visibleForTesting
  static const Duration tapDuration = Duration(milliseconds: 100);

  /// Animated button press effect
  static Future<void> performTapAnimation(
    AnimationController controller,
    Future<void> Function() onTap,
  ) async {
    await controller.forward();
    await onTap();
    await controller.reverse();
  }
}

/// Smooth page transition
class SmoothPageRoute<T> extends PageRoute<T> {
  SmoothPageRoute({
    required this.builder,
    this.duration = const Duration(milliseconds: 400),
    super.settings,
  });

  final WidgetBuilder builder;
  final Duration duration;

  @override
  Color get barrierColor => Colors.transparent;

  @override
  String get barrierLabel => '';

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return builder(context);
  }

  @override
  bool get opaque => true;

  @override
  bool get maintainState => true;

  @override
  Duration get transitionDuration => duration;

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 1),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
      child: FadeTransition(opacity: animation, child: child),
    );
  }
}

/// Button press animation builder
class AnimatedButton extends StatefulWidget {
  const AnimatedButton({
    super.key,
    required this.child,
    required this.onPressed,
    this.scaleFactor = 0.95,
  });

  final Widget child;
  final VoidCallback onPressed;
  final double scaleFactor;

  @override
  State<AnimatedButton> createState() => _AnimatedButtonState();
}

class _AnimatedButtonState extends State<AnimatedButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1,
      end: widget.scaleFactor,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handlePress() async {
    await _controller.forward();
    widget.onPressed();
    await _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) => _handlePress(),
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(scale: _scaleAnimation, child: widget.child),
    );
  }
}
