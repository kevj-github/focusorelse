import 'package:flutter/material.dart';

import '../models/pact_model.dart';
import '../theme/colors.dart';

class PactStatusTheme {
  static bool isFailed(PactModel pact) {
    return pact.status == PactStatus.failed || pact.isOverdue;
  }

  static bool isCompleted(PactModel pact) {
    return pact.status == PactStatus.completed;
  }

  static bool isOngoing(PactModel pact) {
    if (isCompleted(pact) || isFailed(pact)) {
      return false;
    }
    return true;
  }

  static Color colorForPact(PactModel pact) {
    if (isCompleted(pact)) {
      return AppColors.success;
    }
    if (isFailed(pact)) {
      return AppColors.error;
    }
    return AppColors.accent;
  }

  static String labelForPact(PactModel pact) {
    if (isCompleted(pact)) {
      return 'Completed';
    }
    if (isFailed(pact)) {
      return 'Failed';
    }
    return 'Ongoing';
  }
}
