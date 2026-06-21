import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:school_management_system/core/theme/app_colors.dart';
import 'package:school_management_system/core/theme/app_text_style.dart';
import 'package:school_management_system/features/auth/providers/auth_provider.dart';

// ── Place this file at:
// lib/features/shared/notifications/notifications_screen.dart
//
// Add to Firestore: collection 'notifications' with docs like:
//   { uid: 'user_uid', title: 'Fee Due', body: '...', type: 'finance',
//     isRead: false, createdAt: Timestamp }
//
// Update routes in app_router.dart:
//   GoRoute(path: 'notifications', builder: (_, __) => const NotificationsScreen()),

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = ref.watch(authProvider).user?.uid;
    final role = ref.watch(authProvider).role ?? 'student';

    final roleColor = role == 'admin'
        ? AppColors.adminColor
        : role == 'teacher'
            ? AppColors.teacherColor
            : AppColors.studentColor;

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
          TextButton(
            onPressed: uid == null
                ? null
                : () => _markAllRead(uid),
            child: Text('Mark all read',
                style: AppTextStyles.labelSmall
                    .copyWith(color: Colors.white70)),
          ),
        ],
      ),
      body: uid == null
          ? const Center(child: CircularProgressIndicator())
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('notifications')
                  .where('uid', isEqualTo: uid)
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snap.data?.docs ?? [];

                if (docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.notifications_none_rounded,
                            size: 72, color: AppColors.textHint),
                        const SizedBox(height: 20),
                        Text('No notifications yet',
                            style: AppTextStyles.bodyMediumBold
                                .copyWith(color: AppColors.textSecondary)),
                        const SizedBox(height: 8),
                        Text('You\'re all caught up!',
                            style: AppTextStyles.labelSmall
                                .copyWith(color: AppColors.textHint)),
                      ],
                    ),
                  );
                }

                // Group by date
                final Map<String, List<QueryDocumentSnapshot>> grouped = {};
                for (final doc in docs) {
                  final data = doc.data() as Map<String, dynamic>;
                  final ts = (data['createdAt'] as Timestamp?)?.toDate();
                  final label = ts != null ? _dateLabel(ts) : 'Earlier';
                  grouped.putIfAbsent(label, () => []).add(doc);
                }

                return ListView(
                  padding: const EdgeInsets.symmetric(
                      vertical: 12, horizontal: 0),
                  children: [
                    ...grouped.entries.expand((entry) => [
                          _DateHeader(label: entry.key),
                          ...entry.value.map((doc) {
                            final data =
                                doc.data() as Map<String, dynamic>;
                            return _NotifTile(
                              docId: doc.id,
                              title: data['title'] as String? ?? '',
                              body: data['body'] as String? ?? '',
                              type: data['type'] as String? ?? 'general',
                              isRead: data['isRead'] as bool? ?? false,
                              createdAt:
                                  (data['createdAt'] as Timestamp?)
                                      ?.toDate(),
                              roleColor: roleColor,
                            );
                          }),
                        ]),
                    const SizedBox(height: 32),
                  ],
                );
              },
            ),
    );
  }

  void _markAllRead(String uid) {
    FirebaseFirestore.instance
        .collection('notifications')
        .where('uid', isEqualTo: uid)
        .where('isRead', isEqualTo: false)
        .get()
        .then((snap) {
      final batch = FirebaseFirestore.instance.batch();
      for (final doc in snap.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      batch.commit();
    });
  }

  String _dateLabel(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final date = DateTime(dt.year, dt.month, dt.day);
    final diff = today.difference(date).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    return DateFormat('MMMM d, yyyy').format(dt);
  }
}

// ── Date header ───────────────────────────────────────────────────────────────
class _DateHeader extends StatelessWidget {
  final String label;
  const _DateHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Text(label,
          style: AppTextStyles.labelMedium
              .copyWith(fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
    );
  }
}

// ── Notification tile ─────────────────────────────────────────────────────────
class _NotifTile extends StatelessWidget {
  final String docId, title, body, type;
  final bool isRead;
  final DateTime? createdAt;
  final Color roleColor;

  const _NotifTile({
    required this.docId,
    required this.title,
    required this.body,
    required this.type,
    required this.isRead,
    required this.createdAt,
    required this.roleColor,
  });

  IconData get _icon {
    switch (type) {
      case 'exam':
        return Icons.quiz_rounded;
      case 'finance':
        return Icons.account_balance_wallet_rounded;
      case 'holiday':
        return Icons.beach_access_rounded;
      case 'attendance':
        return Icons.how_to_reg_rounded;
      case 'assignment':
        return Icons.assignment_rounded;
      case 'result':
        return Icons.bar_chart_rounded;
      default:
        return Icons.campaign_rounded;
    }
  }

  Color get _typeColor {
    switch (type) {
      case 'exam':
        return AppColors.primary;
      case 'finance':
        return AppColors.warning;
      case 'holiday':
        return AppColors.success;
      case 'attendance':
        return AppColors.teacherColor;
      case 'assignment':
        return AppColors.accent;
      case 'result':
        return AppColors.info;
      default:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (!isRead) {
          FirebaseFirestore.instance
              .collection('notifications')
              .doc(docId)
              .update({'isRead': true});
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isRead ? AppColors.cardBg : _typeColor.withOpacity(0.05),
          borderRadius: BorderRadius.circular(14),
          boxShadow: AppColors.cardShadow,
          border: isRead
              ? Border.all(color: AppColors.divider, width: 1)
              : Border.all(color: _typeColor.withOpacity(0.3), width: 1),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: _typeColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(_icon, color: _typeColor, size: 20),
            ),
            const SizedBox(width: 14),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: AppTextStyles.bodyMediumBold.copyWith(
                            color: isRead
                                ? AppColors.textPrimary
                                : AppColors.textPrimary,
                          ),
                        ),
                      ),
                      if (!isRead)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _typeColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    body,
                    style: AppTextStyles.labelSmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (createdAt != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      DateFormat('h:mm a').format(createdAt!),
                      style: AppTextStyles.labelTiny
                          .copyWith(color: AppColors.textHint),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Helper: send a notification (call from admin/teacher side) ────────────────
/// Usage:
///   await NotificationHelper.send(
///     uid: studentUid,
///     title: 'Exam Tomorrow',
///     body: 'Mathematics mid-term is scheduled for tomorrow at 9AM.',
///     type: 'exam',
///   );
class NotificationHelper {
  static Future<void> send({
    required String uid,
    required String title,
    required String body,
    String type = 'general',
  }) async {
    await FirebaseFirestore.instance.collection('notifications').add({
      'uid': uid,
      'title': title,
      'body': body,
      'type': type,
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Broadcast to all users with a given role
  static Future<void> broadcast({
    required String role,
    required String title,
    required String body,
    String type = 'general',
  }) async {
    final users = await FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: role)
        .get();

    final batch = FirebaseFirestore.instance.batch();
    for (final doc in users.docs) {
      final ref = FirebaseFirestore.instance.collection('notifications').doc();
      batch.set(ref, {
        'uid': doc.id,
        'title': title,
        'body': body,
        'type': type,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  }
}