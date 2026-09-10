import 'package:intl/intl.dart';

/// Centralized date and time formatting and computation utility suite.
class DateTimeHelper {
  DateTimeHelper._();

  static final DateFormat _isoDateFormatter = DateFormat('yyyy-MM-dd');
  static final DateFormat _displayDateFormatter = DateFormat('MMM d, yyyy');
  static final DateFormat _displayTimeFormatter = DateFormat('h:mm a');
  static final DateFormat _fullDateTimeFormatter = DateFormat('MMM d, yyyy • h:mm a');
  static final DateFormat _monthYearFormatter = DateFormat('MMMM yyyy');

  /// Formats date to 'yyyy-MM-dd' (standard API format).
  static String formatIsoDate(DateTime? date) {
    if (date == null) return '';
    return _isoDateFormatter.format(date);
  }

  /// Formats date to 'MMM d, yyyy' (e.g. 'Oct 14, 2026').
  static String formatDisplayDate(DateTime? date) {
    if (date == null) return '';
    return _displayDateFormatter.format(date);
  }

  /// Formats time to 'h:mm a' (e.g. '10:30 AM').
  static String formatDisplayTime(DateTime? date) {
    if (date == null) return '';
    return _displayTimeFormatter.format(date);
  }

  /// Formats combined date and time (e.g. 'Oct 14, 2026 • 10:30 AM').
  static String formatFullDateTime(DateTime? date) {
    if (date == null) return '';
    return _fullDateTimeFormatter.format(date);
  }

  /// Formats month and year (e.g. 'October 2026').
  static String formatMonthYear(DateTime? date) {
    if (date == null) return '';
    return _monthYearFormatter.format(date);
  }

  /// Generates a human-friendly relative time string (e.g., 'Just now', '5m ago', '2h ago', 'Yesterday', etc.)
  static String timeAgo(DateTime? date, {DateTime? clock}) {
    if (date == null) return '';
    final now = clock ?? DateTime.now();
    final difference = now.difference(date);

    if (difference.isNegative) {
      return 'In the future';
    }

    if (difference.inSeconds < 45) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      final mins = difference.inMinutes;
      return '${mins}m ago';
    } else if (difference.inHours < 24) {
      final hours = difference.inHours;
      return '${hours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '${weeks}w ago';
    } else {
      return formatDisplayDate(date);
    }
  }

  /// Checks if two dates fall on the exact same calendar day.
  static bool isSameDay(DateTime? a, DateTime? b) {
    if (a == null || b == null) return false;
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  /// Checks if a given date is today.
  static bool isToday(DateTime? date, {DateTime? clock}) {
    if (date == null) return false;
    final now = clock ?? DateTime.now();
    return isSameDay(date, now);
  }

  /// Parses date string safely without throwing exceptions.
  static DateTime? safeParse(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    try {
      return DateTime.parse(raw.trim());
    } catch (_) {
      return null;
    }
  }

  /// Calculates remaining days until deadline, returning negative if overdue.
  static int daysUntil(DateTime? target, {DateTime? clock}) {
    if (target == null) return 0;
    final now = clock ?? DateTime.now();
    final targetDate = DateTime(target.year, target.month, target.day);
    final today = DateTime(now.year, now.month, now.day);
    return targetDate.difference(today).inDays;
  }
}
