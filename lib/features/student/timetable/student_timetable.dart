import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:school_management_system/core/theme/app_colors.dart';
import 'package:school_management_system/core/theme/app_text_style.dart';

/// Read-only timetable for students and parents.
/// No FAB, no delete button, no add-slot sheet.
class StudentTimetableScreen extends StatefulWidget {
  /// Pass a fixed class name to lock the view to one class (student use case).
  /// If null, a class picker is shown (parent browsing use case — not used yet).
  final String? fixedClassName;

  const StudentTimetableScreen({super.key, this.fixedClassName});

  @override
  State<StudentTimetableScreen> createState() => _StudentTimetableScreenState();
}

class _StudentTimetableScreenState extends State<StudentTimetableScreen> {
  String _selectedClass = '';
  String _selectedDay = 'Monday';

  final _days = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.fixedClassName != null && widget.fixedClassName!.isNotEmpty) {
      _selectedClass = widget.fixedClassName!;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.studentColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Timetable',
          style: AppTextStyles.headingMedium.copyWith(color: Colors.white),
        ),
      ),
      // No FAB — students cannot add slots
      body: Column(
        children: [
          // ── Class filter (hidden when class is fixed) ─────────────────
          if (widget.fixedClassName == null || widget.fixedClassName!.isEmpty)
            Container(
              color: AppColors.studentColor,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('classes')
                    .orderBy('name')
                    .snapshots(),
                builder: (context, snap) {
                  final names = snap.hasData
                      ? snap.data!.docs
                            .map(
                              (d) =>
                                  (d.data() as Map<String, dynamic>)['name']
                                      as String? ??
                                  '',
                            )
                            .where((n) => n.isNotEmpty)
                            .toSet()
                            .toList()
                      : <String>[];
                  if (names.isNotEmpty && _selectedClass.isEmpty) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) setState(() => _selectedClass = names.first);
                    });
                  }
                  return SizedBox(
                    height: 36,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: names.map((c) {
                        final isSel = _selectedClass == c;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedClass = c),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: isSel ? Colors.white : Colors.white24,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              c,
                              style: AppTextStyles.labelSmall.copyWith(
                                color: isSel
                                    ? AppColors.studentColor
                                    : Colors.white,
                                fontWeight: isSel
                                    ? FontWeight.w700
                                    : FontWeight.w400,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  );
                },
              ),
            )
          else
            // Show the fixed class name as a header strip
            Container(
              color: AppColors.studentColor,
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.class_rounded,
                        color: Colors.white, size: 18),
                    const SizedBox(width: 10),
                    Text(
                      widget.fixedClassName!,
                      style: AppTextStyles.bodyMediumBold
                          .copyWith(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),

          // ── Day tabs ───────────────────────────────────────────────────
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: _days.map((d) {
                final isSel = _selectedDay == d;
                return GestureDetector(
                  onTap: () => setState(() => _selectedDay = d),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: isSel
                          ? AppColors.studentColor
                          : AppColors.background,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSel
                            ? AppColors.studentColor
                            : AppColors.divider,
                      ),
                    ),
                    child: Text(
                      d,
                      style: AppTextStyles.labelSmall.copyWith(
                        color: isSel ? Colors.white : AppColors.textSecondary,
                        fontWeight:
                            isSel ? FontWeight.w700 : FontWeight.w400,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // ── Slots list (read-only — no delete button) ─────────────────
          Expanded(
            child: _selectedClass.isEmpty
                ? const Center(
                    child: Text(
                      'Loading your class…',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        color: AppColors.textSecondary,
                      ),
                    ),
                  )
                : StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('timetable')
                        .where('className', isEqualTo: _selectedClass)
                        .where('day', isEqualTo: _selectedDay)
                        .orderBy('startTime')
                        .snapshots(),
                    builder: (context, snap) {
                      if (snap.connectionState == ConnectionState.waiting) {
                        return const Center(
                            child: CircularProgressIndicator());
                      }
                      if (!snap.hasData || snap.data!.docs.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.event_note_rounded,
                                size: 64,
                                color: AppColors.textHint,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No classes on $_selectedDay.',
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        );
                      }

                      final now = TimeOfDay.now();
                      return ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
                        itemCount: snap.data!.docs.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 10),
                        itemBuilder: (context, i) {
                          final data = snap.data!.docs[i].data()
                              as Map<String, dynamic>;
                          final start = data['startTime'] as String? ?? '';
                          final end = data['endTime'] as String? ?? '';
                          final timeRange = start.isNotEmpty && end.isNotEmpty
                              ? '$start – $end'
                              : (data['time'] as String? ?? '');
                          final isNow =
                              _isCurrentPeriod('$start–$end', now);

                          return _ReadOnlySlotCard(
                            subject: data['subject'] as String? ?? '',
                            teacher: data['teacherName'] as String? ?? '',
                            room: data['room'] as String? ?? '',
                            start: start,
                            end: end,
                            isNow: isNow,
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
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

// ── Read-only slot card (no delete button) ────────────────────────────────────
class _ReadOnlySlotCard extends StatelessWidget {
  final String subject, teacher, room, start, end;
  final bool isNow;

  const _ReadOnlySlotCard({
    required this.subject,
    required this.teacher,
    required this.room,
    required this.start,
    required this.end,
    required this.isNow,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isNow ? AppColors.studentColor : AppColors.cardBg,
        borderRadius: BorderRadius.circular(14),
        boxShadow: AppColors.cardShadow,
      ),
      child: Row(
        children: [
          // Time column
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: isNow
                  ? Colors.white.withOpacity(0.2)
                  : AppColors.studentColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                Text(
                  start,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: isNow ? Colors.white : AppColors.studentColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  '–',
                  style: AppTextStyles.labelTiny.copyWith(
                    color: isNow ? Colors.white70 : AppColors.textHint,
                  ),
                ),
                Text(
                  end,
                  style: AppTextStyles.labelTiny.copyWith(
                    color: isNow ? Colors.white70 : AppColors.studentColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          // Subject + teacher + room
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  subject,
                  style: AppTextStyles.bodyMediumBold.copyWith(
                    color: isNow ? Colors.white : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  [teacher, room]
                      .where((s) => s.isNotEmpty)
                      .join(' · '),
                  style: AppTextStyles.labelSmall.copyWith(
                    color: isNow ? Colors.white70 : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          // "Now" badge
          if (isNow)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Now',
                style: AppTextStyles.labelTiny
                    .copyWith(color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }
}