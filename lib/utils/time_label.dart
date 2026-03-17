class TimeLabel {
  static const List<String> _months = <String>[
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  static String formatRelativeShort(DateTime? value, {DateTime? now}) {
    if (value == null) {
      return 'new';
    }

    final reference = now ?? DateTime.now();
    final diff = reference.difference(value);

    if (diff.isNegative) {
      return 'now';
    }

    if (diff.inSeconds < 45) {
      return 'now';
    }
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m';
    }
    if (diff.inHours < 24 && _isSameDay(reference, value)) {
      return '${diff.inHours}h';
    }

    final yesterday = DateTime(
      reference.year,
      reference.month,
      reference.day,
    ).subtract(const Duration(days: 1));
    final valueDay = DateTime(value.year, value.month, value.day);
    if (valueDay == yesterday) {
      return 'yesterday';
    }

    if (diff.inDays < 7) {
      return '${diff.inDays}d';
    }

    if (value.year == reference.year) {
      return '${_months[value.month - 1]} ${value.day}';
    }

    return '${_months[value.month - 1]} ${value.day}, ${value.year}';
  }

  static String formatMessageTime(DateTime value, {DateTime? now}) {
    final reference = now ?? DateTime.now();

    if (_isSameDay(reference, value)) {
      return _formatClock(value);
    }

    final yesterday = DateTime(
      reference.year,
      reference.month,
      reference.day,
    ).subtract(const Duration(days: 1));
    final valueDay = DateTime(value.year, value.month, value.day);
    if (valueDay == yesterday) {
      return 'Yesterday';
    }

    if (value.year == reference.year) {
      return '${_months[value.month - 1]} ${value.day}';
    }

    return '${_months[value.month - 1]} ${value.day}, ${value.year}';
  }

  static String _formatClock(DateTime value) {
    final hour24 = value.hour;
    final minute = value.minute.toString().padLeft(2, '0');
    final period = hour24 >= 12 ? 'PM' : 'AM';
    final hour12 = hour24 % 12 == 0 ? 12 : hour24 % 12;
    return '$hour12:$minute $period';
  }

  static bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
