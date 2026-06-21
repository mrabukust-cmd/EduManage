import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:school_management_system/core/theme/app_colors.dart';
import 'package:school_management_system/core/theme/app_text_style.dart';

/// Single Timetable screen used by admin, teacher, and student.
///
/// Previously this app had TWO separate timetable implementations:
///   - lib/features/admin/timetable/timetable_screen.dart (admin-only,
///     class-filtered, had an "Add Slot" sheet)
///   - lib/features/shared/timetable/timetable_screen.dart (day-tabbed,
///     used by all three roles, also had an "Add Period" sheet)
/// They duplicated nearly identical Firestore queries against the same
/// `timetable` collection. This file merges them: day tabs + role theming
/// from the shared version, with full add/delete capability gated on
/// `role == 'admin'`, and an optional `filterClass` for teacher/student.
class TimetableScreen extends ConsumerStatefulWidget {
  /// Pass the class name to filter (e.g. 'Grade 9A') or null for all classes.
  final String? filterClass;

  /// 'admin' | 'teacher' | 'student' — drives theming and edit permissions.
  final String role;

  const TimetableScreen({
    super.key,
    this.filterClass,
    this.role = 'student',
  });

  @override
  ConsumerState<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends ConsumerState<TimetableScreen>
    with SingleTickerProviderStateMixin {
  static const _days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday'];

  late TabController _tabController;
  int _todayIndex = 0;

  bool get _isAdmin => widget.role == 'admin';

  Color get _roleColor {
    switch (widget.role) {
      case 'admin':
        return AppColors.adminColor;
      case 'teacher':
        return AppColors.teacherColor;
      default:
        return AppColors.studentColor;
    }
  }

  Gradient get _roleGradient {
    switch (widget.role) {
      case 'admin':
        return AppColors.adminGradient;
      case 'teacher':
        return AppColors.teacherGradient;
      default:
        return AppColors.studentGradient;
    }
  }

  @override
  void initState() {
    super.initState();
    final weekday = DateTime.now().weekday; // 1=Mon … 7=Sun
    _todayIndex = (weekday >= 1 && weekday <= 5) ? weekday - 1 : 0;
    _tabController =
        TabController(length: _days.length, vsync: this, initialIndex: _todayIndex);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: _roleColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: Text('Timetable', style: AppTextStyles.headingMedium.copyWith(color: Colors.white)),
        actions: _isAdmin
            ? [
                IconButton(
                  icon: const Icon(Icons.add_rounded, color: Colors.white),
                  onPressed: () => _showAddPeriodSheet(context),
                )
              ]
            : null,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white54,
          labelStyle: AppTextStyles.labelSmall.copyWith(fontWeight: FontWeight.w700, color: Colors.white),
          tabs: _days.map((d) => Tab(text: d.substring(0, 3))).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: _days
            .map((day) => _DayView(
                  day: day,
                  filterClass: widget.filterClass,
                  roleColor: _roleColor,
                  isAdmin: _isAdmin,
                ))
            .toList(),
      ),
    );
  }

  void _showAddPeriodSheet(BuildContext context) {
    final subjectCtrl = TextEditingController();
    final teacherCtrl = TextEditingController();
    final roomCtrl = TextEditingController();
    final timeCtrl = TextEditingController();
    final classCtrl = TextEditingController(text: widget.filterClass ?? '');
    String selectedDay = _days[_tabController.index];
    int period = 1;
    bool loading = false;
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardBg,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (sheetCtx) => StatefulBuilder(
        builder: (sheetCtx, setSheet) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(sheetCtx).viewInsets.bottom + 24,
          ),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(color: AppColors.divider, borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 20),
                Text('Add Period', style: AppTextStyles.headingMedium),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: selectedDay,
                        decoration: _inputDecor('Day'),
                        items: _days.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
                        onChanged: (v) => setSheet(() => selectedDay = v!),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        initialValue: period,
                        decoration: _inputDecor('Period'),
                        items: List.generate(8, (i) => i + 1)
                            .map((n) => DropdownMenuItem(value: n, child: Text('Period $n')))
                            .toList(),
                        onChanged: (v) => setSheet(() => period = v!),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _field(timeCtrl, 'Time', 'e.g. 08:00–09:00'),
                const SizedBox(height: 12),
                _field(subjectCtrl, 'Subject', 'e.g. Mathematics'),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _field(teacherCtrl, 'Teacher', 'Mr. Khalid')),
                    const SizedBox(width: 12),
                    Expanded(child: _field(roomCtrl, 'Room', 'Room 101')),
                  ],
                ),
                const SizedBox(height: 12),
                _field(classCtrl, 'Class', 'e.g. Grade 9A'),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: loading
                        ? null
                        : () async {
                            if (!formKey.currentState!.validate()) return;
                            setSheet(() => loading = true);
                            await FirebaseFirestore.instance.collection('timetable').add({
                              'day': selectedDay,
                              'period': period,
                              'time': timeCtrl.text.trim(),
                              'subject': subjectCtrl.text.trim(),
                              'teacher': teacherCtrl.text.trim(),
                              'room': roomCtrl.text.trim(),
                              'className': classCtrl.text.trim(),
                              'createdAt': FieldValue.serverTimestamp(),
                            });
                            if (sheetCtx.mounted) Navigator.pop(sheetCtx);
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _roleColor,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: loading
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Text('Save Period', style: AppTextStyles.bodyMediumBold.copyWith(color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String label, String hint) {
    return TextFormField(
      controller: ctrl,
      decoration: _inputDecor(label).copyWith(hintText: hint),
      validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
    );
  }

  InputDecoration _inputDecor(String label) => InputDecoration(
        labelText: label,
        filled: true,
        fillColor: AppColors.background,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.divider)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.divider)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      );
}

// ── Day view (one tab) ────────────────────────────────────────────────────────
class _DayView extends StatelessWidget {
  final String day;
  final String? filterClass;
  final Color roleColor;
  final bool isAdmin;

  const _DayView({
    required this.day,
    required this.filterClass,
    required this.roleColor,
    required this.isAdmin,
  });

  @override
  Widget build(BuildContext context) {
    Query<Map<String, dynamic>> query = FirebaseFirestore.instance
        .collection('timetable')
        .where('day', isEqualTo: day)
        .orderBy('period');

    if (filterClass != null && filterClass!.isNotEmpty) {
      query = query.where('className', isEqualTo: filterClass);
    }

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: query.snapshots(),
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
                const Icon(Icons.event_busy_rounded, size: 56, color: AppColors.textHint),
                const SizedBox(height: 16),
                Text('No classes on $day', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
                if (isAdmin) ...[
                  const SizedBox(height: 8),
                  Text('Tap + to add periods', style: AppTextStyles.labelSmall.copyWith(color: AppColors.textHint)),
                ],
              ],
            ),
          );
        }

        final now = TimeOfDay.now();

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, i) {
            final data = docs[i].data();
            final time = data['time'] as String? ?? '';
            final isNow = _isCurrentPeriod(time, now);

            return _PeriodCard(
              period: (data['period'] as int? ?? i + 1),
              time: time,
              subject: data['subject'] as String? ?? '',
              teacher: data['teacher'] as String? ?? '',
              room: data['room'] as String? ?? '',
              className: data['className'] as String? ?? '',
              isNow: isNow,
              roleColor: roleColor,
              isAdmin: isAdmin,
              docId: docs[i].id,
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
      final startMins = start.hour * 60 + start.minute;
      final endMins = end.hour * 60 + end.minute;
      return nowMins >= startMins && nowMins <= endMins;
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

// ── Period card ───────────────────────────────────────────────────────────────
class _PeriodCard extends StatelessWidget {
  final int period;
  final String time, subject, teacher, room, className, docId;
  final bool isNow, isAdmin;
  final Color roleColor;

  const _PeriodCard({
    required this.period,
    required this.time,
    required this.subject,
    required this.teacher,
    required this.room,
    required this.className,
    required this.isNow,
    required this.isAdmin,
    required this.roleColor,
    required this.docId,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isNow ? roleColor : AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppColors.cardShadow,
        border: isNow ? null : Border.all(color: AppColors.divider, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: isNow ? Colors.white24 : roleColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                '$period',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: isNow ? Colors.white : roleColor,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    subject,
                    style: AppTextStyles.bodyMediumBold.copyWith(color: isNow ? Colors.white : AppColors.textPrimary),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.person_outline_rounded, size: 13, color: isNow ? Colors.white70 : AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(teacher, style: AppTextStyles.labelSmall.copyWith(color: isNow ? Colors.white70 : AppColors.textSecondary)),
                      const SizedBox(width: 10),
                      Icon(Icons.room_outlined, size: 13, color: isNow ? Colors.white70 : AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(room, style: AppTextStyles.labelSmall.copyWith(color: isNow ? Colors.white70 : AppColors.textSecondary)),
                    ],
                  ),
                  if (className.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(className, style: AppTextStyles.labelTiny.copyWith(color: isNow ? Colors.white60 : AppColors.textHint)),
                  ],
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (isNow)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(20)),
                    child: Text('Now', style: AppTextStyles.labelTiny.copyWith(color: Colors.white)),
                  ),
                const SizedBox(height: 4),
                Text(
                  time,
                  style: AppTextStyles.labelTiny.copyWith(
                    color: isNow ? Colors.white70 : AppColors.textHint,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (isAdmin) ...[
                  const SizedBox(height: 4),
                  GestureDetector(
                    onTap: () => FirebaseFirestore.instance.collection('timetable').doc(docId).delete(),
                    child: Icon(Icons.delete_outline_rounded, size: 18, color: isNow ? Colors.white60 : AppColors.textHint),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}