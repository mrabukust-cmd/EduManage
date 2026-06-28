// ── STEP 1: Replace this file at:
// lib/features/teacher/notifications/teacher_notifications_screen.dart
//
// STEP 2: In teacher_home_screen.dart, change the Messages _ActionTile:
//
//   _ActionTile(
//     icon: Icons.notifications_rounded,
//     label: 'Notifications',
//     color: AppColors.warning,
//     onTap: () => context.push('/teacher/home/notifications'),
//   ),
//
// STEP 3: In app_router.dart under /teacher/home routes, replace:
//   GoRoute(path: 'messages', builder: (_, __) => const Scaffold(...))
// with:
//   GoRoute(path: 'notifications', builder: (_, __) => const TeacherNotificationsScreen()),
//
// STEP 4: Add import to app_router.dart:
//   import 'package:school_management_system/features/teacher/notifications/teacher_notifications_screen.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:school_management_system/core/theme/app_colors.dart';
import 'package:school_management_system/core/theme/app_text_style.dart';
import 'package:school_management_system/features/auth/providers/auth_provider.dart';

class TeacherNotificationsScreen extends ConsumerStatefulWidget {
  const TeacherNotificationsScreen({super.key});

  @override
  ConsumerState<TeacherNotificationsScreen> createState() =>
      _TeacherNotificationsScreenState();
}

class _TeacherNotificationsScreenState
    extends ConsumerState<TeacherNotificationsScreen> {
  String _filter = 'all'; // all | unread | read

  @override
  Widget build(BuildContext context) {
    final uid = ref.watch(authProvider).user?.uid;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.teacherColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Notifications',
          style: AppTextStyles.headingMedium.copyWith(color: Colors.white),
        ),
        actions: [
          // Mark all read button
          if (uid != null)
            TextButton(
              onPressed: () => _markAllRead(uid),
              child: Text(
                'Mark all read',
                style: AppTextStyles.labelSmall
                    .copyWith(color: Colors.white70),
              ),
            ),
        ],
      ),
      body: uid == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // ── Filter chips ────────────────────────────────
                Container(
                  color: AppColors.teacherColor,
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                  child: SizedBox(
                    height: 34,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _FilterChip(
                          label: 'All',
                          selected: _filter == 'all',
                          onTap: () => setState(() => _filter = 'all'),
                        ),
                        const SizedBox(width: 8),
                        _FilterChip(
                          label: 'Unread',
                          selected: _filter == 'unread',
                          onTap: () => setState(() => _filter = 'unread'),
                        ),
                        const SizedBox(width: 8),
                        _FilterChip(
                          label: 'Read',
                          selected: _filter == 'read',
                          onTap: () => setState(() => _filter = 'read'),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Notification list ───────────────────────────
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('notifications')
                        .where('uid', isEqualTo: uid)
                        .orderBy('createdAt', descending: true)
                        .snapshots(),
                    builder: (context, snap) {
                      if (snap.connectionState == ConnectionState.waiting &&
                          !snap.hasData) {
                        return const Center(
                            child: CircularProgressIndicator());
                      }

                      var docs = snap.data?.docs ?? [];

                      // Apply filter
                      if (_filter == 'unread') {
                        docs = docs.where((d) {
                          final data = d.data() as Map<String, dynamic>;
                          return !(data['isRead'] as bool? ?? false);
                        }).toList();
                      } else if (_filter == 'read') {
                        docs = docs.where((d) {
                          final data = d.data() as Map<String, dynamic>;
                          return data['isRead'] as bool? ?? false;
                        }).toList();
                      }

                      // Count unread
                      final unreadCount = (snap.data?.docs ?? [])
                          .where((d) {
                            final data = d.data() as Map<String, dynamic>;
                            return !(data['isRead'] as bool? ?? false);
                          })
                          .length;

                      if (docs.isEmpty) {
                        return _EmptyState(filter: _filter);
                      }

                      // Group by date
                      final Map<String, List<QueryDocumentSnapshot>> grouped =
                          {};
                      for (final doc in docs) {
                        final data = doc.data() as Map<String, dynamic>;
                        final ts =
                            (data['createdAt'] as Timestamp?)?.toDate();
                        final label =
                            ts != null ? _dateLabel(ts) : 'Earlier';
                        grouped.putIfAbsent(label, () => []).add(doc);
                      }

                      return ListView(
                        padding: const EdgeInsets.only(top: 8, bottom: 32),
                        children: [
                          // Unread count banner
                          if (unreadCount > 0 && _filter != 'read')
                            Container(
                              margin:
                                  const EdgeInsets.fromLTRB(16, 8, 16, 8),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: AppColors.teacherColor
                                    .withOpacity(0.08),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: AppColors.teacherColor
                                        .withOpacity(0.3)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                      Icons.notifications_active_rounded,
                                      color: AppColors.teacherColor,
                                      size: 16),
                                  const SizedBox(width: 8),
                                  Text(
                                    '$unreadCount unread notification${unreadCount == 1 ? '' : 's'}',
                                    style: AppTextStyles.labelSmall.copyWith(
                                        color: AppColors.teacherColor,
                                        fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ),

                          ...grouped.entries.expand((entry) => [
                                _DateHeader(label: entry.key),
                                ...entry.value.map((doc) {
                                  final data =
                                      doc.data() as Map<String, dynamic>;
                                  return _NotifTile(
                                    docId: doc.id,
                                    title:
                                        data['title'] as String? ?? '',
                                    body: data['body'] as String? ?? '',
                                    type:
                                        data['type'] as String? ?? 'general',
                                    isRead:
                                        data['isRead'] as bool? ?? false,
                                    createdAt: (data['createdAt']
                                            as Timestamp?)
                                        ?.toDate(),
                                  );
                                }),
                              ]),
                        ],
                      );
                    },
                  ),
                ),
              ],
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

// ── Filter chip ───────────────────────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.white24,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: AppTextStyles.labelSmall.copyWith(
            color: selected ? AppColors.teacherColor : Colors.white,
            fontWeight:
                selected ? FontWeight.w700 : FontWeight.w400,
          ),
        ),
      ),
    );
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
      child: Text(
        label,
        style: AppTextStyles.labelMedium
            .copyWith(fontWeight: FontWeight.w700, color: AppColors.textSecondary),
      ),
    );
  }
}

// ── Notification tile ─────────────────────────────────────────────────────────

class _NotifTile extends StatelessWidget {
  final String docId, title, body, type;
  final bool isRead;
  final DateTime? createdAt;

  const _NotifTile({
    required this.docId,
    required this.title,
    required this.body,
    required this.type,
    required this.isRead,
    required this.createdAt,
  });

  IconData get _icon {
    switch (type) {
      case 'exam': return Icons.quiz_rounded;
      case 'finance': return Icons.account_balance_wallet_rounded;
      case 'holiday': return Icons.beach_access_rounded;
      case 'attendance': return Icons.how_to_reg_rounded;
      case 'assignment': return Icons.assignment_rounded;
      case 'result': return Icons.bar_chart_rounded;
      case 'approval': return Icons.check_circle_outline_rounded;
      case 'registration': return Icons.person_add_rounded;
      default: return Icons.campaign_rounded;
    }
  }

  Color get _typeColor {
    switch (type) {
      case 'exam': return AppColors.primary;
      case 'finance': return AppColors.warning;
      case 'holiday': return AppColors.success;
      case 'attendance': return AppColors.teacherColor;
      case 'assignment': return AppColors.accent;
      case 'result': return AppColors.info;
      case 'approval': return AppColors.success;
      case 'registration': return AppColors.adminColor;
      default: return AppColors.textSecondary;
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
          color: isRead
              ? AppColors.cardBg
              : _typeColor.withOpacity(0.05),
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
            const SizedBox(width: 12),

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
                          style: AppTextStyles.bodyMediumBold,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final String filter;
  const _EmptyState({required this.filter});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.notifications_none_rounded,
              size: 72, color: AppColors.textHint),
          const SizedBox(height: 20),
          Text(
            filter == 'unread'
                ? 'No unread notifications'
                : filter == 'read'
                    ? 'No read notifications'
                    : 'No notifications yet',
            style: AppTextStyles.bodyMediumBold
                .copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          Text(
            filter == 'all' ? "You're all caught up!" : '',
            style: AppTextStyles.labelSmall.copyWith(color: AppColors.textHint),
          ),
        ],
      ),
    );
  }
}