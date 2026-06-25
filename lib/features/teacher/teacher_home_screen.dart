import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:school_management_system/core/theme/app_colors.dart';
import 'package:school_management_system/core/theme/app_text_style.dart';
import 'package:school_management_system/data/repositories/teacher_repo.dart';
import 'package:school_management_system/features/auth/providers/auth_provider.dart';

class TeacherHomeScreen extends ConsumerWidget {
  const TeacherHomeScreen({super.key});

  static const _weekdayNames = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final uid = user?.uid;
    final teacherName = user?.displayName ?? 'Teacher';
    final today = _weekdayNames[DateTime.now().weekday - 1];
    final dateLabel = DateFormat('EEEE, MMMM d').format(DateTime.now());

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: _TeacherHeader(
                userName: teacherName,
                dateLabel: dateLabel,
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),

            // ── Today's Classes (real data) ─────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Today's Classes", style: AppTextStyles.sectionTitle),
                    TextButton(
                      onPressed: () => context.push('/teacher/home/timetable'),
                      child: const Text('See All'),
                    ),
                  ],
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 12)),
            SliverToBoxAdapter(
              child: uid == null
                  ? const SizedBox.shrink()
                  : _TodaysClasses(
                      uid: uid,
                      teacherName: teacherName,
                      day: today,
                    ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 28)),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text('Quick Actions', style: AppTextStyles.sectionTitle),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 14)),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    _ActionTile(
                      icon: Icons.how_to_reg_rounded,
                      label: 'Attendance',
                      color: AppColors.teacherColor,
                      onTap: () => context.push('/teacher/home/attendance'),
                    ),
                    const SizedBox(width: 12),
                    _ActionTile(
                      icon: Icons.assignment_rounded,
                      label: 'Assignments',
                      color: AppColors.primary,
                      onTap: () => context.push('/teacher/home/assignments'),
                    ),
                    const SizedBox(width: 12),
                    _ActionTile(
                      icon: Icons.grade_rounded,
                      label: 'Grades',
                      color: AppColors.accent,
                      onTap: () => context.push('/teacher/home/grades'),
                    ),
                    const SizedBox(width: 12),
                    _ActionTile(
                      icon: Icons.chat_rounded,
                      label: 'Messages',
                      color: AppColors.warning,
                      onTap: () => context.push('/teacher/home/messages'),
                    ),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 28)),

            // ── Pending Tasks (real data: ungraded assignments + today's attendance) ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text('Pending Tasks', style: AppTextStyles.sectionTitle),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 14)),
            SliverToBoxAdapter(
              child: uid == null
                  ? const SizedBox.shrink()
                  : _PendingTasks(
                      uid: uid,
                      teacherName: teacherName,
                      day: today,
                    ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
      bottomNavigationBar: const _TeacherBottomNav(currentIndex: 0),
    );
  }
}

// ── Header ───────────────────────────────────────────────────────────────────
class _TeacherHeader extends StatelessWidget {
  final String userName;
  final String dateLabel;
  const _TeacherHeader({required this.userName, required this.dateLabel});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      decoration: const BoxDecoration(
        gradient: AppColors.teacherGradient,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome back,',
                style: AppTextStyles.labelMedium.copyWith(
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                userName,
                style: AppTextStyles.headingLarge.copyWith(color: Colors.white),
              ),
              const SizedBox(height: 4),
              Text(
                dateLabel,
                style: AppTextStyles.labelMedium.copyWith(
                  color: Colors.white60,
                ),
              ),
            ],
          ),
          const Stack(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: Colors.white24,
                child: Icon(
                  Icons.person_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Today's Classes (real data from `timetable`, filtered to teacher's classes) ──
class _TodaysClasses extends StatelessWidget {
  final String uid;
  final String teacherName;
  final String day;
  const _TodaysClasses({
    required this.uid,
    required this.teacherName,
    required this.day,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<String>>(
      stream: TeacherRepository.instance.watchAssignedClassNames(
        uid: uid,
        teacherName: teacherName,
      ),
      builder: (context, classesSnap) {
        final classNames = classesSnap.data ?? const <String>[];
        if (classNames.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'No classes assigned yet.',
              style: TextStyle(
                fontFamily: 'Poppins',
                color: AppColors.textSecondary,
              ),
            ),
          );
        }

        // No .orderBy() here — avoids composite index requirement
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('timetable')
              .where('day', isEqualTo: day)
              .where(
                'className',
                whereIn: classNames.length > 10
                    ? classNames.sublist(0, 10)
                    : classNames,
              )
              .snapshots(),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                height: 140,
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              );
            }

            if (!snap.hasData || snap.data!.docs.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'No classes scheduled for today.',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    color: AppColors.textSecondary,
                  ),
                ),
              );
            }

            final now = TimeOfDay.now();

            // Filter to only THIS teacher's slots, sort by startTime in Dart
            final myDocs =
                snap.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final slotTeacher = (data['teacherName'] as String? ?? '')
                      .trim()
                      .toLowerCase();
                  // Include slot if teacherName matches or is empty (unassigned)
                  return slotTeacher.isEmpty ||
                      slotTeacher == teacherName.trim().toLowerCase();
                }).toList()..sort((a, b) {
                  final aT =
                      (a.data() as Map<String, dynamic>)['startTime']
                          as String? ??
                      '';
                  final bT =
                      (b.data() as Map<String, dynamic>)['startTime']
                          as String? ??
                      '';
                  return aT.compareTo(bT);
                });

            if (myDocs.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'No classes scheduled for today.',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    color: AppColors.textSecondary,
                  ),
                ),
              );
            }

            return SizedBox(
              height: 140,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: myDocs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final start = data['startTime'] as String? ?? '';
                  final end = data['endTime'] as String? ?? '';
                  // Support both time formats: startTime+endTime or combined time field
                  final time = start.isNotEmpty && end.isNotEmpty
                      ? '$start–$end'
                      : (data['time'] as String? ?? '');
                  final isOngoing = _isCurrentPeriod(time, now);
                  return _ClassCard(
                    subject: data['subject'] as String? ?? '',
                    grade: data['className'] as String? ?? '',
                    time: time,
                    room: data['room'] as String? ?? '',
                    isOngoing: isOngoing,
                  );
                }).toList(),
              ),
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
      return nowMins >= (start.hour * 60 + start.minute) &&
          nowMins <= (end.hour * 60 + end.minute);
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

class _ClassCard extends StatelessWidget {
  final String subject, grade, time, room;
  final bool isOngoing;
  const _ClassCard({
    required this.subject,
    required this.grade,
    required this.time,
    required this.room,
    required this.isOngoing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180,
      margin: const EdgeInsets.only(right: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isOngoing ? AppColors.teacherColor : AppColors.cardBg,
        borderRadius: BorderRadius.circular(18),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isOngoing)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Ongoing',
                style: AppTextStyles.labelTiny.copyWith(color: Colors.white),
              ),
            ),
          const Spacer(),
          Text(
            subject,
            style: AppTextStyles.bodyMediumBold.copyWith(
              color: isOngoing ? Colors.white : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            grade,
            style: AppTextStyles.labelSmall.copyWith(
              color: isOngoing ? Colors.white70 : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            time,
            style: AppTextStyles.labelTiny.copyWith(
              color: isOngoing ? Colors.white60 : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Action Tile ──────────────────────────────────────────────────────────────
class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 26),
              const SizedBox(height: 6),
              Text(
                label,
                style: AppTextStyles.labelTiny.copyWith(color: color),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Pending Tasks (real: today's unmarked attendance + ungraded assignments) ──
class _PendingTasks extends StatelessWidget {
  final String uid;
  final String teacherName;
  final String day;
  const _PendingTasks({
    required this.uid,
    required this.teacherName,
    required this.day,
  });

  @override
  Widget build(BuildContext context) {
    final todayKey = DateFormat('yyyy-MM-dd').format(DateTime.now());

    return StreamBuilder<List<String>>(
      stream: TeacherRepository.instance.watchAssignedClassNames(
        uid: uid,
        teacherName: teacherName,
      ),
      builder: (context, classesSnap) {
        final classNames = classesSnap.data ?? const <String>[];

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('assignments')
              .where('teacherId', isEqualTo: uid)
              .orderBy('dueDate')
              .limit(5)
              .snapshots(),
          builder: (context, assignSnap) {
            final assignments = assignSnap.data?.docs ?? [];

            return StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('attendance')
                  .where('date', isEqualTo: todayKey)
                  .snapshots(),
              builder: (context, attSnap) {
                final markedClasses = (attSnap.data?.docs ?? [])
                    .map(
                      (d) =>
                          (d.data() as Map<String, dynamic>)['className']
                              as String?,
                    )
                    .whereType<String>()
                    .toSet();
                final unmarkedClasses = classNames
                    .where((c) => !markedClasses.contains(c))
                    .toList();

                final items = <Widget>[];

                for (final c in unmarkedClasses) {
                  items.add(
                    _TaskItem(
                      title: 'Mark attendance – $c',
                      subtitle: 'Not marked today',
                      icon: Icons.how_to_reg_rounded,
                      color: AppColors.teacherColor,
                      isDone: false,
                    ),
                  );
                }

                for (final doc in assignments) {
                  final data = doc.data() as Map<String, dynamic>;
                  final dueDate = (data['dueDate'] as Timestamp?)?.toDate();
                  items.add(
                    _TaskItem(
                      title:
                          '${data['title'] ?? 'Assignment'} – ${data['className'] ?? ''}',
                      subtitle: dueDate != null
                          ? 'Due ${DateFormat('MMM d').format(dueDate)}'
                          : 'No due date',
                      icon: Icons.assignment_rounded,
                      color: AppColors.primary,
                      isDone: false,
                    ),
                  );
                }

                if (items.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      'No pending tasks. You\'re all caught up!',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        color: AppColors.textSecondary,
                      ),
                    ),
                  );
                }

                return Column(children: items);
              },
            );
          },
        );
      },
    );
  }
}

class _TaskItem extends StatelessWidget {
  final String title, subtitle;
  final IconData icon;
  final Color color;
  final bool isDone;
  const _TaskItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.isDone,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(14),
        boxShadow: AppColors.cardShadow,
      ),
      child: Row(
        children: [
          Icon(
            isDone ? Icons.check_circle_rounded : icon,
            color: isDone ? AppColors.success : color,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.bodyMediumBold.copyWith(
                    decoration: isDone ? TextDecoration.lineThrough : null,
                  ),
                ),
                Text(subtitle, style: AppTextStyles.labelSmall),
              ],
            ),
          ),
          if (!isDone)
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textSecondary,
            ),
        ],
      ),
    );
  }
}

// ── Bottom Nav ───────────────────────────────────────────────────────────────
class _TeacherBottomNav extends StatelessWidget {
  final int currentIndex;
  const _TeacherBottomNav({required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: AppColors.teacherColor,
      unselectedItemColor: AppColors.textSecondary,
      backgroundColor: AppColors.cardBg,
      elevation: 12,
      onTap: (i) {
        switch (i) {
          case 0:
            context.go('/teacher/home');
            break;
          case 1:
            context.go('/teacher/home/classes');
            break;
          case 2:
            context.go('/teacher/home/attendance');
            break;
          case 3:
            context.go('/teacher/home/grades');
            break;
          case 4:
            context.go('/teacher/home/profile');
            break;
        }
      },
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Home'),
        BottomNavigationBarItem(
          icon: Icon(Icons.class_rounded),
          label: 'Classes',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.how_to_reg_rounded),
          label: 'Attendance',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.grade_rounded),
          label: 'Grades',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_rounded),
          label: 'Profile',
        ),
      ],
    );
  }
}
