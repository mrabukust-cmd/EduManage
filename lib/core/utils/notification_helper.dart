import 'package:flutter/material.dart';
import 'package:school_management_system/core/theme/app_colors.dart';

/// Supported notification classifications across the school ecosystem.
enum NotificationCategory {
  academic,
  exam,
  fee,
  attendance,
  holiday,
  emergency,
  general,
}

/// Delivery and visual urgency levels.
enum NotificationPriority {
  low,
  normal,
  high,
  urgent,
}

/// Notification entity representing incoming push or in-app alerts.
class NotificationItem {
  final String id;
  final String title;
  final String body;
  final NotificationCategory category;
  final NotificationPriority priority;
  final bool isRead;
  final DateTime timestamp;
  final Map<String, dynamic>? data;

  const NotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.category,
    required this.priority,
    this.isRead = false,
    required this.timestamp,
    this.data,
  });

  NotificationItem copyWith({
    String? id,
    String? title,
    String? body,
    NotificationCategory? category,
    NotificationPriority? priority,
    bool? isRead,
    DateTime? timestamp,
    Map<String, dynamic>? data,
  }) {
    return NotificationItem(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      category: category ?? this.category,
      priority: priority ?? this.priority,
      isRead: isRead ?? this.isRead,
      timestamp: timestamp ?? this.timestamp,
      data: data ?? this.data,
    );
  }
}

/// Utility suite for classifying, prioritizing, and managing notifications & badges.
class NotificationHelper {
  NotificationHelper._();

  /// Infers notification category based on title, body content, and keywords.
  static NotificationCategory classifyCategory(String title, String body) {
    final combined = '$title $body'.toLowerCase();

    if (combined.contains('urgent') ||
        combined.contains('emergency') ||
        combined.contains('lockdown') ||
        combined.contains('evacuation')) {
      return NotificationCategory.emergency;
    }
    if (combined.contains('fee') ||
        combined.contains('dues') ||
        combined.contains('challan') ||
        combined.contains('payment') ||
        combined.contains('invoice')) {
      return NotificationCategory.fee;
    }
    if (combined.contains('exam') ||
        combined.contains('test') ||
        combined.contains('midterm') ||
        combined.contains('finals') ||
        combined.contains('datesheet')) {
      return NotificationCategory.exam;
    }
    if (combined.contains('absent') ||
        combined.contains('leave') ||
        combined.contains('attendance') ||
        combined.contains('present')) {
      return NotificationCategory.attendance;
    }
    if (combined.contains('holiday') ||
        combined.contains('vacation') ||
        combined.contains('off day') ||
        combined.contains('closed')) {
      return NotificationCategory.holiday;
    }
    if (combined.contains('syllabus') ||
        combined.contains('assignment') ||
        combined.contains('homework') ||
        combined.contains('grade')) {
      return NotificationCategory.academic;
    }

    return NotificationCategory.general;
  }

  /// Determines priority based on category and textual cues.
  static NotificationPriority inferPriority(String title, String body, NotificationCategory category) {
    if (category == NotificationCategory.emergency) {
      return NotificationPriority.urgent;
    }

    final combined = '$title $body'.toLowerCase();
    if (combined.contains('urgent') || combined.contains('immediate action') || combined.contains('last day')) {
      return NotificationPriority.urgent;
    }
    if (category == NotificationCategory.fee && (combined.contains('due') || combined.contains('overdue'))) {
      return NotificationPriority.high;
    }
    if (category == NotificationCategory.exam) {
      return NotificationPriority.high;
    }
    if (category == NotificationCategory.holiday) {
      return NotificationPriority.low;
    }

    return NotificationPriority.normal;
  }

  /// Counts unread notifications.
  static int countUnread(List<NotificationItem> items) {
    return items.where((item) => !item.isRead).length;
  }

  /// Formats notification count into compact badge string (e.g., "99+").
  static String formatBadgeCount(int count) {
    if (count <= 0) return '';
    if (count > 99) return '99+';
    return count.toString();
  }

  /// Groups items by category for filtered tab presentation.
  static Map<NotificationCategory, List<NotificationItem>> groupByCategory(List<NotificationItem> items) {
    final map = <NotificationCategory, List<NotificationItem>>{};
    for (final item in items) {
      map.putIfAbsent(item.category, () => []).add(item);
    }
    return map;
  }

  /// Returns theme-aligned accent color for notification categories.
  static Color getCategoryColor(NotificationCategory category) {
    switch (category) {
      case NotificationCategory.emergency:
        return AppColors.danger;
      case NotificationCategory.fee:
        return AppColors.warning;
      case NotificationCategory.exam:
        return AppColors.info;
      case NotificationCategory.attendance:
        return AppColors.accent;
      case NotificationCategory.academic:
        return AppColors.primary;
      case NotificationCategory.holiday:
        return AppColors.success;
      case NotificationCategory.general:
        return AppColors.textSecondary;
    }
  }

  /// Returns human-readable icon data for notification categories.
  static IconData getCategoryIcon(NotificationCategory category) {
    switch (category) {
      case NotificationCategory.emergency:
        return Icons.warning_amber_rounded;
      case NotificationCategory.fee:
        return Icons.account_balance_wallet_outlined;
      case NotificationCategory.exam:
        return Icons.assignment_outlined;
      case NotificationCategory.attendance:
        return Icons.fact_check_outlined;
      case NotificationCategory.academic:
        return Icons.school_outlined;
      case NotificationCategory.holiday:
        return Icons.beach_access_outlined;
      case NotificationCategory.general:
        return Icons.notifications_none_rounded;
    }
  }
}
