import 'package:flutter/material.dart';

class AppAnimations {
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration medium = Duration(milliseconds: 250);
  static const Duration slow = Duration(milliseconds: 400);

  static const Curve standardCurve = Curves.easeInOut;
  static const Curve emphasizedCurve = Curves.easeOutCubic;
}
