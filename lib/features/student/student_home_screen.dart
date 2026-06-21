import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:school_management_system/core/theme/app_colors.dart';
import 'package:school_management_system/core/theme/app_text_style.dart';
import 'package:school_management_system/features/auth/providers/auth_provider.dart';

class StudentHomeScreen extends ConsumerWidget {
  const StudentHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final uid = user?.uid;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: _StudentHeader(userName: user?.displayName ?? 'Student', uid: uid),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),

            // ── Attendance Summary (real data) ────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _AttendanceCard(uid: uid),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),

            // ── Today's Schedule (real data, filtered to student's class) ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Today's Schedule", style: AppTextStyles.sectionTitle),
                    TextButton(onPressed: () => context.push('/student/home/timetable'), child: const Text('Full Timetable')),
                  ],
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 12)),
            SliverToBoxAdapter(child: _TodaysSchedule(uid: uid)),

            const SliverToBoxAdapter(child: SizedBox(height: 24)),

            // ── Pending Assignments (real data) ───────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Pending Assignments', style: AppTextStyles.sectionTitle),
                    TextButton(onPressed: () => context.push('/student/home/assignments'), child: const Text('See All')),
                  ],
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 12)),
            SliverToBoxAdapter(child: _PendingAssignments(uid: uid)),
            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
      bottomNavigationBar: const _StudentBottomNav(currentIndex: 0),
    );
  }
}

// ── Header ───────────────────────────────────────────────────────────────────
class _StudentHeader extends StatelessWidget {
  final String userName;
  final String? uid;
  const _StudentHeader({required this.userName, required this.uid});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF7C3AED), Color(0xFF9F67FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Hello,', style: AppTextStyles.labelMedium.copyWith(color: Colors.white70)),
                const SizedBox(height: 4),
                Text(userName, style: AppTextStyles.headingLarge.copyWith(color: Colors.white)),
                const SizedBox(height: 4),
                if (uid != null)
                  StreamBuilder<DocumentSnapshot>(
                    stream: FirebaseFirestore.instance.collection('students').doc(uid).snapshots(),
                    builder: (context, snap) {
                      final data = snap.data?.data() as Map<String, dynamic>?;
                      final className = data?['class'] as String? ?? '';
                      final section = data?['section'] as String? ?? '';
                      final label = [className, section].where((s) => s.isNotEmpty).join(' – ');
                      return Text(label.isEmpty ? 'Class not assigned yet' : label,
                          style: AppTextStyles.labelMedium.copyWith(color: Colors.white60));
                    },
                  ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => context.push('/student/notifications'),
            icon: const Icon(Icons.notifications_rounded, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 4),
          const CircleAvatar(
            radius: 22,
            backgroundColor: Colors.white24,
            child: Icon(Icons.person_rounded, color: Colors.white, size: 24),
          ),
        ],
      ),
    );
  }
}

// ── Attendance Card (real data from `attendance` collection) ─────────────────
class _AttendanceCard extends StatelessWidget {
  final String? uid;
  const _AttendanceCard({required this.uid});

  @override
  Widget build(BuildContext context) {
    if (uid == null) return const SizedBox.shrink();

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('attendance')
          .where('studentId', isEqualTo: uid)
          .snapshots(),
      builder: (context, snap) {
        final docs = snap.data?.docs ?? [];
        int present = 0, absent = 0, leave = 0;
        for (final doc in docs) {
          final data = doc.data() as Map<String, dynamic>;
          final status = data['status'] as String? ?? 'absent';
          if (status == 'present') present++;
          else if (status == 'leave') leave++;
          else absent++;
        }
        final total = docs.length;
        final pct = total > 0 ? present / total : 0.0;

        return Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.cardBg,
            borderRadius: BorderRadius.circular(18),
            boxShadow: AppColors.cardShadow,
          ),
          child: Row(
            children: [
              SizedBox(
                width: 72,
                height: 72,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: total == 0 ? 0 : pct,
                      strokeWidth: 7,
                      backgroundColor: AppColors.studentColor.withOpacity(0.15),
                      valueColor: const AlwaysStoppedAnimation(AppColors.studentColor),
                    ),
                    Text(total == 0 ? '--' : '${(pct * 100).round()}%', style: AppTextStyles.statValue.copyWith(fontSize: 14)),
                  ],
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Attendance', style: AppTextStyles.bodyMediumBold),
                    const SizedBox(height: 6),
                    _AttRow(label: 'Present', value: '$present days', color: Colors.green),
                    _AttRow(label: 'Absent', value: '$absent days', color: Colors.redAccent),
                    _AttRow(label: 'Leave', value: '$leave days', color: Colors.orange),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _AttRow extends StatelessWidget {
  final String label, value;
  final Color color;
  const _AttRow({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text('$label: ', style: AppTextStyles.labelSmall),
          Text(value, style: AppTextStyles.labelSmall.copyWith(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        ],
      ),
    );
  }
}

// ── Today's Schedule (real data from `timetable` collection) ─────────────────
class _TodaysSchedule extends StatelessWidget {
  final String? uid;
  const _TodaysSchedule({required this.uid});

  static const _weekdayNames = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

  @override
  Widget build(BuildContext context) {
    if (uid == null) return const SizedBox.shrink();
    final today = _weekdayNames[DateTime.now().weekday - 1];

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('students').doc(uid).snapshots(),
      builder: (context, studentSnap) {
        final className = (studentSnap.data?.data() as Map<String, dynamic>?)?['class'] as String?;
        if (className == null || className.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text('No class assigned yet — your schedule will show once admin assigns you a class.',
                style: AppTextStyles.labelSmall.copyWith(color: AppColors.textHint)),
          );
        }

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('timetable')
              .where('day', isEqualTo: today)
              .where('className', isEqualTo: className)
              .orderBy('period')
              .snapshots(),
          builder: (context, snap) {
            final docs = snap.data?.docs ?? [];
            if (snap.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: SizedBox(height: 40, child: Center(child: CircularProgressIndicator(strokeWidth: 2))),
              );
            }
            if (docs.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text('No classes scheduled for today.', style: AppTextStyles.labelSmall.copyWith(color: AppColors.textHint)),
              );
            }
            final now = TimeOfDay.now();
            return Column(
              children: docs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final time = data['time'] as String? ?? '';
                final isNow = _isCurrentPeriod(time, now);
                return _ScheduleItem(
                  time: time,
                  subject: data['subject'] as String? ?? '',
                  teacher: data['teacher'] as String? ?? '',
                  room: data['room'] as String? ?? '',
                  isNow: isNow,
                );
              }).toList(),
            );
          },
        );
      },
    );
  }

  bool _isCurrentPeriod(String timeRange, TimeOfDay now) {
    try {
      final parts = timeRange.split('–');
      if (parts.length < 2) return false;
      final start = _parseTime(parts[0].trim());
      final end = _parseTime(parts[1].trim());
      if (start == null || end == null) return false;
      final nowMins = now.hour * 60 + now.minute;
      return nowMins >= (start.hour * 60 + start.minute) && nowMins <= (end.hour * 60 + end.minute);
    } catch (_) {
      return false;
    }
  }

  TimeOfDay? _parseTime(String s) {
    final parts = s.split(':');
    if (parts.length < 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return null;
    return TimeOfDay(hour: h, minute: m);
  }
}

class _ScheduleItem extends StatelessWidget {
  final String time, subject, teacher, room;
  final bool isNow;
  const _ScheduleItem({required this.time, required this.subject, required this.teacher, required this.room, required this.isNow});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isNow ? AppColors.studentColor : AppColors.cardBg,
        borderRadius: BorderRadius.circular(14),
        boxShadow: AppColors.cardShadow,
      ),
      child: Row(
        children: [
          Text(time, style: AppTextStyles.labelSmall.copyWith(color: isNow ? Colors.white70 : AppColors.textSecondary, fontWeight: FontWeight.w600)),
          const SizedBox(width: 16),
          Container(width: 2, height: 40, color: isNow ? Colors.white30 : AppColors.divider),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(subject, style: AppTextStyles.bodyMediumBold.copyWith(color: isNow ? Colors.white : AppColors.textPrimary)),
                const SizedBox(height: 2),
                Text('$teacher · $room', style: AppTextStyles.labelSmall.copyWith(color: isNow ? Colors.white70 : AppColors.textSecondary)),
              ],
            ),
          ),
          if (isNow)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(20)),
              child: Text('Now', style: AppTextStyles.labelTiny.copyWith(color: Colors.white)),
            ),
        ],
      ),
    );
  }
}

// ── Pending Assignments (real data from `assignments` collection) ────────────
class _PendingAssignments extends StatelessWidget {
  final String? uid;
  const _PendingAssignments({required this.uid});

  @override
  Widget build(BuildContext context) {
    if (uid == null) return const SizedBox.shrink();

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('students').doc(uid).snapshots(),
      builder: (context, studentSnap) {
        final className = (studentSnap.data?.data() as Map<String, dynamic>?)?['class'] as String?;
        if (className == null || className.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text('No class assigned yet.', style: AppTextStyles.labelSmall.copyWith(color: AppColors.textHint)),
          );
        }

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('assignments')
              .where('className', isEqualTo: className)
              .orderBy('dueDate')
              .limit(5)
              .snapshots(),
          builder: (context, snap) {
            final docs = snap.data?.docs ?? [];
            if (docs.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text('No pending assignments. You\'re all caught up!', style: AppTextStyles.labelSmall.copyWith(color: AppColors.textHint)),
              );
            }
            return Column(
              children: docs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final dueDate = (data['dueDate'] as Timestamp?)?.toDate();
                final isUrgent = dueDate != null && dueDate.difference(DateTime.now()).inDays <= 2;
                return _AssignmentItem(
                  subject: data['subject'] as String? ?? '',
                  title: data['title'] as String? ?? '',
                  dueDate: dueDate != null ? DateFormat('MMM d').format(dueDate) : '-',
                  isUrgent: isUrgent,
                );
              }).toList(),
            );
          },
        );
      },
    );
  }
}

class _AssignmentItem extends StatelessWidget {
  final String subject, title, dueDate;
  final bool isUrgent;
  const _AssignmentItem({required this.subject, required this.title, required this.dueDate, required this.isUrgent});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: isUrgent ? Border.all(color: Colors.redAccent.withOpacity(0.4)) : null,
        boxShadow: AppColors.cardShadow,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: AppColors.studentColor.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(Icons.assignment_rounded, color: AppColors.studentColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(subject, style: AppTextStyles.labelTiny.copyWith(color: AppColors.studentColor, fontWeight: FontWeight.w600)),
                Text(title, style: AppTextStyles.bodyMediumBold),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('Due', style: AppTextStyles.labelTiny),
              Text(dueDate, style: AppTextStyles.labelSmall.copyWith(color: isUrgent ? Colors.redAccent : AppColors.textSecondary, fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Bottom Nav ────────────────────────────────────────────────────────────────
class _StudentBottomNav extends StatelessWidget {
  final int currentIndex;
  const _StudentBottomNav({required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: AppColors.studentColor,
      unselectedItemColor: AppColors.textSecondary,
      backgroundColor: AppColors.cardBg,
      elevation: 12,
      onTap: (i) {
        switch (i) {
          case 0: context.go('/student/home'); break;
          case 1: context.go('/student/home/timetable'); break;
          case 2: context.go('/student/home/assignments'); break;
          case 3: context.go('/student/home/results'); break;
          case 4: context.go('/student/home/profile'); break;
        }
      },
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.schedule_rounded), label: 'Schedule'),
        BottomNavigationBarItem(icon: Icon(Icons.assignment_rounded), label: 'Assignments'),
        BottomNavigationBarItem(icon: Icon(Icons.bar_chart_rounded), label: 'Results'),
        BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'Profile'),
      ],
    );
  }
}