// lib/features/parents/parent_notifications_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:school_management_system/core/theme/app_colors.dart';
import 'package:school_management_system/core/theme/app_text_style.dart';
import 'package:school_management_system/features/auth/providers/auth_provider.dart';

class ParentNotificationsScreen extends ConsumerWidget {
  const ParentNotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = ref.watch(authProvider).user?.uid;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: Text('Notifications',
            style: AppTextStyles.headingMedium.copyWith(color: Colors.white)),
        actions: [
          // Mark all read button
          if (uid != null)
            TextButton(
              onPressed: () => _markAllRead(uid),
              child: Text('Mark all read',
                  style: AppTextStyles.labelSmall
                      .copyWith(color: Colors.white70)),
            ),
        ],
      ),
      body: uid == null
          ? const Center(child: CircularProgressIndicator())
          : _NotificationsList(uid: uid),
    );
  }

  Future<void> _markAllRead(String uid) async {
    final snap = await FirebaseFirestore.instance
        .collection('notifications')
        .where('uid', isEqualTo: uid)
        .where('isRead', isEqualTo: false)
        .get();

    final batch = FirebaseFirestore.instance.batch();
    for (final doc in snap.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }
}

class _NotificationsList extends StatelessWidget {
  final String uid;
  const _NotificationsList({required this.uid});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('notifications')
          .where('uid', isEqualTo: uid)
          .orderBy('createdAt', descending: true)
          .limit(50)
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
                    size: 64, color: AppColors.textHint),
                const SizedBox(height: 16),
                Text('No notifications yet.',
                    style: AppTextStyles.bodyMedium
                        .copyWith(color: AppColors.textSecondary)),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, i) {
            final data = docs[i].data() as Map<String, dynamic>;
            final isRead = data['isRead'] as bool? ?? false;
            final type = data['type'] as String? ?? 'general';
            final createdAt = (data['createdAt'] as Timestamp?)?.toDate();

            return GestureDetector(
              onTap: () {
                // Mark as read on tap
                if (!isRead) {
                  docs[i].reference.update({'isRead': true});
                }
              },
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isRead
                      ? AppColors.cardBg
                      : AppColors.primary.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: AppColors.cardShadow,
                  border: isRead
                      ? null
                      : Border.all(
                          color: AppColors.primary.withOpacity(0.2)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Icon
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: _typeColor(type).withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(_typeIcon(type),
                          color: _typeColor(type), size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  data['title'] as String? ?? '',
                                  style: AppTextStyles.bodyMediumBold
                                      .copyWith(
                                    fontWeight: isRead
                                        ? FontWeight.w500
                                        : FontWeight.w700,
                                  ),
                                ),
                              ),
                              if (!isRead)
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: AppColors.primary,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            data['body'] as String? ?? '',
                            style: AppTextStyles.labelSmall,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (createdAt != null) ...[
                            const SizedBox(height: 6),
                            Text(
                              _formatTime(createdAt),
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
          },
        );
      },
    );
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'finance': return AppColors.warning;
      case 'attendance': return AppColors.success;
      case 'result': return AppColors.primary;
      case 'assignment': return AppColors.accent;
      case 'notice': return AppColors.info;
      default: return AppColors.textSecondary;
    }
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'finance': return Icons.payment_rounded;
      case 'attendance': return Icons.how_to_reg_rounded;
      case 'result': return Icons.bar_chart_rounded;
      case 'assignment': return Icons.assignment_rounded;
      case 'notice': return Icons.campaign_rounded;
      default: return Icons.notifications_rounded;
    }
  }

  String _formatTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('MMM d, yyyy').format(dt);
  }
}