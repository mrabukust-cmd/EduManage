import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:school_management_system/core/theme/app_colors.dart';
import 'package:school_management_system/core/theme/app_text_style.dart';
import 'package:school_management_system/features/auth/providers/auth_provider.dart';


class StudentHomeScreen extends ConsumerWidget {
  const StudentHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ── Header ──────────────────────────────────────────
            SliverToBoxAdapter(
              child: _StudentHeader(userName: user?.displayName ?? 'Student'),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 24)),

            // ── Attendance Summary ────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _AttendanceCard(),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 24)),

            // ── Today's Schedule ──────────────────────────────────
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
            SliverList(
              delegate: SliverChildListDelegate([
                _ScheduleItem(time: '08:00', subject: 'Mathematics', teacher: 'Mr. Khalid', room: 'Room 101', isNow: true),
                _ScheduleItem(time: '10:00', subject: 'Physics', teacher: 'Ms. Sana', room: 'Room 204', isNow: false),
                _ScheduleItem(time: '12:00', subject: 'English', teacher: 'Mr. Arif', room: 'Room 105', isNow: false),
                _ScheduleItem(time: '14:00', subject: 'Chemistry', teacher: 'Ms. Hina', room: 'Lab 2', isNow: false),
              ]),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 24)),

            // ── Pending Assignments ───────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Pending Assignments', style: AppTextStyles.sectionTitle),
                    TextButton(onPressed: () => context.push('/student/assignments'), child: const Text('See All')),
                  ],
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 12)),
            SliverList(
              delegate: SliverChildListDelegate([
                _AssignmentItem(subject: 'Mathematics', title: 'Chapter 5 – Exercises 1–20', dueDate: 'Jun 18', isUrgent: true),
                _AssignmentItem(subject: 'Physics', title: 'Lab Report – Motion', dueDate: 'Jun 20', isUrgent: false),
                _AssignmentItem(subject: 'English', title: 'Essay – My Future Career', dueDate: 'Jun 22', isUrgent: false),
                const SizedBox(height: 32),
              ]),
            ),
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
  const _StudentHeader({required this.userName});

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
                Text('Grade 9 – Section A', style: AppTextStyles.labelMedium.copyWith(color: Colors.white60)),
              ],
            ),
          ),
          IconButton(
            onPressed: () => context.push('/student/notifications'),
            icon: Stack(
              children: [
                const Icon(Icons.notifications_rounded, color: Colors.white, size: 28),
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),
          CircleAvatar(
            radius: 22,
            backgroundColor: Colors.white24,
            child: const Icon(Icons.person_rounded, color: Colors.white, size: 24),
          ),
        ],
      ),
    );
  }
}

// ── Attendance Card ──────────────────────────────────────────────────────────
class _AttendanceCard extends StatelessWidget {
  const _AttendanceCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(18),
        boxShadow: AppColors.cardShadow,
      ),
      child: Row(
        children: [
          // Circle progress
          SizedBox(
            width: 72,
            height: 72,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(value: 0.87, strokeWidth: 7, backgroundColor: AppColors.studentColor.withOpacity(0.15), valueColor: const AlwaysStoppedAnimation(AppColors.studentColor)),
                Text('87%', style: AppTextStyles.statValue.copyWith(fontSize: 14)),
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
                _AttRow(label: 'Present', value: '52 days', color: Colors.green),
                _AttRow(label: 'Absent', value: '8 days', color: Colors.redAccent),
                _AttRow(label: 'Leave', value: '0 days', color: Colors.orange),
              ],
            ),
          ),
        ],
      ),
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

// ── Schedule Item ─────────────────────────────────────────────────────────────
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

// ── Assignment Item ───────────────────────────────────────────────────────────
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