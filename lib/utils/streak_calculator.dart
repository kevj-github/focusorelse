import '../models/pact_model.dart';

class StreakStats {
  const StreakStats({required this.current, required this.longest});

  final int current;
  final int longest;
}

class StreakCalculator {
  static StreakStats fromPacts(List<PactModel> pacts) {
    final completionDays = _completionDaysWithEvidence(pacts);
    if (completionDays.isEmpty) {
      return const StreakStats(current: 0, longest: 0);
    }

    final sortedDays = completionDays.toList()..sort((a, b) => a.compareTo(b));
    final longest = _longestStreak(sortedDays);
    final current = _currentStreak(sortedDays);

    return StreakStats(current: current, longest: longest);
  }

  static Set<DateTime> _completionDaysWithEvidence(List<PactModel> pacts) {
    final days = <DateTime>{};

    for (final pact in pacts) {
      if (pact.status != PactStatus.completed) {
        continue;
      }

      final isAiVerified =
          pact.verificationType == VerificationType.aiVerify &&
          pact.verificationResult == true;
      final hasEvidence = (pact.evidenceUrl ?? '').trim().isNotEmpty;
      if (!hasEvidence && !isAiVerified) {
        continue;
      }

      final sourceTime = pact.evidenceSubmittedAt ?? pact.completedAt;
      if (sourceTime == null) {
        continue;
      }

      final local = sourceTime.toLocal();
      days.add(DateTime(local.year, local.month, local.day));
    }

    return days;
  }

  static int _currentStreak(List<DateTime> sortedDays) {
    final completionDays = sortedDays.toSet();
    final now = DateTime.now().toLocal();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    DateTime? anchor;
    if (completionDays.contains(today)) {
      anchor = today;
    } else if (completionDays.contains(yesterday)) {
      anchor = yesterday;
    } else {
      return 0;
    }

    var streak = 0;
    var cursor = anchor;
    while (completionDays.contains(cursor)) {
      streak += 1;
      cursor = cursor.subtract(const Duration(days: 1));
    }

    return streak;
  }

  static int _longestStreak(List<DateTime> sortedDays) {
    var longest = 0;
    var current = 0;
    DateTime? previous;

    for (final day in sortedDays) {
      if (previous != null && day.difference(previous).inDays == 1) {
        current += 1;
      } else {
        current = 1;
      }

      if (current > longest) {
        longest = current;
      }
      previous = day;
    }

    return longest;
  }
}
