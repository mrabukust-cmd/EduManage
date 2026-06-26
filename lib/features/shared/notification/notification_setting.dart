import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:school_management_system/core/theme/app_colors.dart';
import 'package:school_management_system/core/theme/app_text_style.dart';
import 'package:school_management_system/features/auth/providers/auth_provider.dart';

// ── Place this file at:
// lib/features/shared/setting/notification_settings_screen.dart
//
// Add to app_router.dart:
//   GoRoute(path: '/settings/notifications',
//       builder: (_, __) => const NotificationSettingsScreen()),
//
// Preferences are stored on users/{uid}.notificationPrefs as a map, e.g.:
//   { general: true, exam: true, finance: true, attendance: true,
//     assignment: true, result: true }
// NotificationHelper / NotificationService can read these before sending
// in a future pass — this screen only manages the stored preference, it
// does not change anything about how NotificationsScreen reads the
// `notifications` collection (those records remain visible regardless;
// these toggles are the user's stated *preference* for future delivery).

class NotificationSettingsScreen extends ConsumerStatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  ConsumerState<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends ConsumerState<NotificationSettingsScreen> {
  bool _loading = true;
  bool _saving = false;

  // Master switch
  bool _pushEnabled = true;

  // Category toggles
  final Map<String, bool> _categories = {
    'general': true,
    'exam': true,
    'attendance': true,
    'assignment': true,
    'result': true,
    'finance': true,
    'holiday': true,
  };

  static const _categoryMeta = {
    'general': ('Announcements', Icons.campaign_rounded),
    'exam': ('Exams', Icons.quiz_rounded),
    'attendance': ('Attendance', Icons.how_to_reg_rounded),
    'assignment': ('Assignments', Icons.assignment_rounded),
    'result': ('Results & Grades', Icons.bar_chart_rounded),
    'finance': ('Fees & Payments', Icons.account_balance_wallet_rounded),
    'holiday': ('Holidays & Events', Icons.beach_access_rounded),
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final uid = ref.read(authProvider).user?.uid;
    if (uid == null) {
      setState(() => _loading = false);
      return;
    }
    try {
      final doc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final data = doc.data();
      final prefs = data?['notificationPrefs'] as Map<String, dynamic>?;
      if (prefs != null) {
        _pushEnabled = prefs['pushEnabled'] as bool? ?? true;
        for (final key in _categories.keys) {
          if (prefs.containsKey(key)) {
            _categories[key] = prefs[key] as bool? ?? true;
          }
        }
      }
    } catch (_) {
      // Non-fatal — default to everything-on if read fails.
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _persist() async {
    final uid = ref.read(authProvider).user?.uid;
    if (uid == null) return;
    setState(() => _saving = true);
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'notificationPrefs': {
          'pushEnabled': _pushEnabled,
          ..._categories,
        },
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not save preferences: $e'),
            backgroundColor: AppColors.danger,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Color get _roleColor {
    final role = ref.read(authProvider).role ?? 'student';
    return switch (role) {
      'admin' => AppColors.adminColor,
      'teacher' => AppColors.teacherColor,
      _ => AppColors.studentColor,
    };
  }

  @override
  Widget build(BuildContext context) {
    final roleColor = _roleColor;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: roleColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: Text('Notifications',
            style: AppTextStyles.headingMedium.copyWith(color: Colors.white)),
        actions: [
          if (_saving)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                ),
              ),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // ── Master toggle card ───────────────────────────
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.cardBg,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: AppColors.cardShadow,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: roleColor.withOpacity(0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.notifications_active_rounded,
                            color: roleColor, size: 22),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Push Notifications',
                                style: AppTextStyles.bodyMediumBold),
                            const SizedBox(height: 2),
                            Text(
                              'Receive alerts on this device',
                              style: AppTextStyles.labelSmall
                                  .copyWith(color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: _pushEnabled,
                        activeThumbColor: roleColor,
                        onChanged: (v) {
                          setState(() => _pushEnabled = v);
                          _persist();
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),
                Text('Notify me about', style: AppTextStyles.sectionTitle),
                const SizedBox(height: 12),

                // ── Category list ─────────────────────────────────
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.cardBg,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: AppColors.cardShadow,
                  ),
                  child: Opacity(
                    opacity: _pushEnabled ? 1 : 0.45,
                    child: Column(
                      children: _categoryMeta.entries.map((entry) {
                        final key = entry.key;
                        final label = entry.value.$1;
                        final icon = entry.value.$2;
                        final isLast = key == _categoryMeta.keys.last;
                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          decoration: isLast
                              ? null
                              : const BoxDecoration(
                                  border: Border(
                                    bottom: BorderSide(
                                        color: AppColors.divider, width: 0.5),
                                  ),
                                ),
                          child: Row(
                            children: [
                              Icon(icon,
                                  size: 18, color: AppColors.textSecondary),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Text(label,
                                    style: AppTextStyles.bodyMedium),
                              ),
                              Switch(
                                value: _categories[key] ?? true,
                                activeThumbColor: roleColor,
                                onChanged: _pushEnabled
                                    ? (v) {
                                        setState(() => _categories[key] = v);
                                        _persist();
                                      }
                                    : null,
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),

                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.info.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.info.withOpacity(0.25)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.info_outline_rounded,
                          color: AppColors.info, size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'In-app notifications are always shown in your '
                          'inbox regardless of these settings. These '
                          'toggles control device push alerts only.',
                          style: AppTextStyles.labelSmall
                              .copyWith(color: AppColors.textSecondary),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
    );
  }
}