import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:school_management_system/core/theme/app_colors.dart';
import 'package:school_management_system/core/theme/app_text_style.dart';
import 'package:school_management_system/features/auth/providers/auth_provider.dart';

class ParentAttendanceScreen extends ConsumerWidget {
  const ParentAttendanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = ref.watch(authProvider).user?.uid;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.success,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: Text("Children's Attendance",
            style: AppTextStyles.headingMedium.copyWith(color: Colors.white)),
      ),
      body: uid == null
          ? const Center(child: CircularProgressIndicator())
          : _MultiChildAttendanceBody(parentUid: uid),
    );
  }
}

// ── Multi-child body ──────────────────────────────────────────────────────────
class _MultiChildAttendanceBody extends StatefulWidget {
  final String parentUid;
  const _MultiChildAttendanceBody({required this.parentUid});

  @override
  State<_MultiChildAttendanceBody> createState() =>
      _MultiChildAttendanceBodyState();
}

class _MultiChildAttendanceBodyState
    extends State<_MultiChildAttendanceBody> {
  List<Map<String, dynamic>> _children = [];
  bool _loading = true;

  // Which child is currently expanded/selected (-1 = none)
  int _selectedIndex = -1;

  @override
  void initState() {
    super.initState();
    _loadChildren();
  }

  Future<void> _loadChildren() async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('parent_children')
          .where('parentId', isEqualTo: widget.parentUid)
          .get();

      final children = <Map<String, dynamic>>[];

      for (final doc in snap.docs) {
        final studentId = doc.data()['studentId'] as String? ?? '';
        if (studentId.isEmpty) continue;

        final studentDoc = await FirebaseFirestore.instance
            .collection('students')
            .doc(studentId)
            .get();

        if (studentDoc.exists) {
          children.add({
            'studentId': studentId,
            'name': studentDoc.data()?['name'] as String? ?? 'Student',
            'class': studentDoc.data()?['class'] as String? ?? '',
            'rollNo': studentDoc.data()?['rollNo'] as String? ?? '',
          });
        }
      }

      if (mounted) {
        setState(() {
          _children = children;
          // Auto-select first child if only one
          _selectedIndex = children.length == 1 ? 0 : -1;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_children.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.family_restroom_rounded,
                size: 64, color: AppColors.textHint),
            const SizedBox(height: 16),
            Text('No children linked to your account.',
                style: AppTextStyles.bodyMedium
                    .copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            Text('Contact the school admin to link your child.',
                style: AppTextStyles.labelSmall
                    .copyWith(color: AppColors.textHint)),
          ],
        ),
      );
    }

    // Single child → go straight to detail view
    if (_children.length == 1) {
      return _AttendanceDetail(
        studentId: _children[0]['studentId'] as String,
        studentName: _children[0]['name'] as String,
        className: _children[0]['class'] as String,
      );
    }

    // Multiple children → show selector cards + detail below
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text('Select a child to view attendance',
            style: AppTextStyles.sectionTitle),
        const SizedBox(height: 12),

        // ── Child selector cards ──────────────────────────────
        ..._children.asMap().entries.map((entry) {
          final i = entry.key;
          final child = entry.value;
          final isSelected = _selectedIndex == i;

          return GestureDetector(
            onTap: () => setState(() =>
                _selectedIndex = isSelected ? -1 : i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? const LinearGradient(
                        colors: [AppColors.success, Color(0xFF16A34A)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: isSelected ? null : AppColors.cardBg,
                borderRadius: BorderRadius.circular(16),
                boxShadow: AppColors.cardShadow,
                border: isSelected
                    ? null
                    : Border.all(color: AppColors.divider),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: isSelected
                        ? Colors.white24
                        : AppColors.success.withOpacity(0.12),
                    child: Text(
                      (child['name'] as String).isNotEmpty
                          ? (child['name'] as String)[0].toUpperCase()
                          : 'S',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                        color: isSelected
                            ? Colors.white
                            : AppColors.success,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          child['name'] as String,
                          style: AppTextStyles.bodyMediumBold.copyWith(
                            color: isSelected
                                ? Colors.white
                                : AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${child['class']}  •  Roll: ${child['rollNo']}',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: isSelected
                                ? Colors.white70
                                : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    isSelected
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: isSelected
                        ? Colors.white
                        : AppColors.textSecondary,
                  ),
                ],
              ),
            ),
          );
        }),

        // ── Detail section for selected child ─────────────────
        if (_selectedIndex >= 0 &&
            _selectedIndex < _children.length) ...[
          const SizedBox(height: 8),
          _AttendanceDetail(
            studentId:
                _children[_selectedIndex]['studentId'] as String,
            studentName:
                _children[_selectedIndex]['name'] as String,
            className:
                _children[_selectedIndex]['class'] as String,
          ),
        ],
      ],
    );
  }
}

// ── Attendance detail for one child ──────────────────────────────────────────
class _AttendanceDetail extends StatelessWidget {
  final String studentId;
  final String studentName;
  final String className;

  const _AttendanceDetail({
    required this.studentId,
    required this.studentName,
    required this.className,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('attendance')
          .where('studentId', isEqualTo: studentId)
          .snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting &&
            !snap.hasData) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        // Sort descending by date in Dart — avoids composite index
        final docs = List.of(snap.data?.docs ?? [])
          ..sort((a, b) {
            final aDate =
                (a.data() as Map<String, dynamic>)['date'] as String? ??
                    '';
            final bDate =
                (b.data() as Map<String, dynamic>)['date'] as String? ??
                    '';
            return bDate.compareTo(aDate);
          });

        if (docs.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.cardBg,
              borderRadius: BorderRadius.circular(16),
              boxShadow: AppColors.cardShadow,
            ),
            child: Column(
              children: [
                const Icon(Icons.event_note_rounded,
                    size: 48, color: AppColors.textHint),
                const SizedBox(height: 12),
                Text('No attendance records yet for $studentName.',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodyMedium
                        .copyWith(color: AppColors.textSecondary)),
              ],
            ),
          );
        }

        int present = 0, absent = 0, late = 0;
        for (final doc in docs) {
          final data = doc.data() as Map<String, dynamic>;
          final status = data['status'] as String? ?? 'absent';
          if (status == 'present') present++;
          else if (status == 'absent') absent++;
          else if (status == 'late') late++;
        }
        final total = docs.length;
        final pct = total > 0 ? (present / total) : 0.0;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Summary card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.cardBg,
                borderRadius: BorderRadius.circular(18),
                boxShadow: AppColors.cardShadow,
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      SizedBox(
                        width: 80,
                        height: 80,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            CircularProgressIndicator(
                              value: pct,
                              strokeWidth: 8,
                              backgroundColor: AppColors.divider,
                              valueColor: AlwaysStoppedAnimation(
                                pct >= 0.85
                                    ? AppColors.success
                                    : pct >= 0.70
                                        ? AppColors.warning
                                        : AppColors.danger,
                              ),
                            ),
                            Text('${(pct * 100).round()}%',
                                style: AppTextStyles.statValue
                                    .copyWith(fontSize: 14)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Attendance Overview',
                                style: AppTextStyles.bodyMediumBold),
                            const SizedBox(height: 10),
                            _StatRow(
                                label: 'Present',
                                value: '$present days',
                                color: AppColors.success),
                            _StatRow(
                                label: 'Absent',
                                value: '$absent days',
                                color: AppColors.danger),
                            _StatRow(
                                label: 'Late',
                                value: '$late days',
                                color: AppColors.warning),
                            _StatRow(
                                label: 'Total',
                                value: '$total days',
                                color: AppColors.textSecondary),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (pct < 0.75) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.danger.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: AppColors.danger.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.warning_amber_rounded,
                              color: AppColors.danger, size: 18),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              "$studentName's attendance is below 75%. "
                              "Please ensure regular attendance.",
                              style: AppTextStyles.labelSmall
                                  .copyWith(color: AppColors.danger),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text('Attendance History',
                style: AppTextStyles.sectionTitle),
            const SizedBox(height: 12),

            // History list
            ...docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final status = data['status'] as String? ?? 'absent';
              final dateStr = data['date'] as String? ?? '';

              final Color color;
              final IconData icon;
              switch (status) {
                case 'present':
                  color = AppColors.success;
                  icon = Icons.check_circle_outline_rounded;
                  break;
                case 'late':
                  color = AppColors.warning;
                  icon = Icons.access_time_rounded;
                  break;
                default:
                  color = AppColors.danger;
                  icon = Icons.cancel_outlined;
              }

              String dayLabel = dateStr;
              String weekday = '';
              try {
                final dt = DateTime.parse(dateStr);
                dayLabel = DateFormat('d MMM yyyy').format(dt);
                weekday = DateFormat('EEEE').format(dt);
              } catch (_) {}

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.cardBg,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: AppColors.cardShadow,
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          shape: BoxShape.circle),
                      child: Icon(icon, color: color, size: 20),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(weekday,
                              style: AppTextStyles.bodyMediumBold),
                          Text(dayLabel,
                              style: AppTextStyles.labelSmall),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        status[0].toUpperCase() + status.substring(1),
                        style: AppTextStyles.labelTiny.copyWith(
                            color: color,
                            fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 20),
          ],
        );
      },
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label, value;
  final Color color;
  const _StatRow(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Container(
              width: 8,
              height: 8,
              decoration:
                  BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text('$label: ', style: AppTextStyles.labelSmall),
          Text(value,
              style: AppTextStyles.labelSmall.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary)),
        ],
      ),
    );
  }
}