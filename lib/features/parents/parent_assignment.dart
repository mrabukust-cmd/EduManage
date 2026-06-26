import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:school_management_system/core/theme/app_colors.dart';
import 'package:school_management_system/core/theme/app_text_style.dart';
import 'package:school_management_system/features/auth/providers/auth_provider.dart';

// Add route in app_router.dart under /parent/home:
//   GoRoute(path: 'assignments',
//       builder: (_, __) => const ParentAssignmentsScreen()),
//
// Add to parent home bottom nav or quick actions as needed.

class ParentAssignmentsScreen extends ConsumerWidget {
  const ParentAssignmentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = ref.watch(authProvider).user?.uid;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.accent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: Text("Children's Assignments",
            style: AppTextStyles.headingMedium.copyWith(color: Colors.white)),
      ),
      body: uid == null
          ? const Center(child: CircularProgressIndicator())
          : _MultiChildAssignmentsBody(parentUid: uid),
    );
  }
}

// ── Multi-child body ──────────────────────────────────────────────────────────
class _MultiChildAssignmentsBody extends StatefulWidget {
  final String parentUid;
  const _MultiChildAssignmentsBody({required this.parentUid});

  @override
  State<_MultiChildAssignmentsBody> createState() =>
      _MultiChildAssignmentsBodyState();
}

class _MultiChildAssignmentsBodyState
    extends State<_MultiChildAssignmentsBody> {
  List<Map<String, dynamic>> _children = [];
  bool _loading = true;
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

    // Single child → go straight to assignments
    if (_children.length == 1) {
      return _AssignmentsForChild(
        studentId: _children[0]['studentId'] as String,
        studentName: _children[0]['name'] as String,
        className: _children[0]['class'] as String,
      );
    }

    // Multiple children → selector cards + assignments list
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text('Select a child to view assignments',
            style: AppTextStyles.sectionTitle),
        const SizedBox(height: 12),

        // ── Child selector cards ──────────────────────────────
        ..._children.asMap().entries.map((entry) {
          final i = entry.key;
          final child = entry.value;
          final isSelected = _selectedIndex == i;

          return GestureDetector(
            onTap: () => setState(
                () => _selectedIndex = isSelected ? -1 : i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? const LinearGradient(
                        colors: [Color(0xFF7C3AED), Color(0xFFA78BFA)],
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
                        : AppColors.accent.withOpacity(0.12),
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
                            : AppColors.accent,
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

        // ── Assignments for selected child ────────────────────
        if (_selectedIndex >= 0 &&
            _selectedIndex < _children.length) ...[
          const SizedBox(height: 8),
          _AssignmentsForChild(
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

// ── Assignments list for one child ────────────────────────────────────────────
class _AssignmentsForChild extends StatelessWidget {
  final String studentId;
  final String studentName;
  final String className;

  const _AssignmentsForChild({
    required this.studentId,
    required this.studentName,
    required this.className,
  });

  @override
  Widget build(BuildContext context) {
    if (className.trim().isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppColors.cardShadow,
        ),
        child: Column(
          children: [
            const Icon(Icons.class_outlined,
                size: 48, color: AppColors.textHint),
            const SizedBox(height: 12),
            Text('$studentName has no class assigned yet.',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium
                    .copyWith(color: AppColors.textSecondary)),
          ],
        ),
      );
    }

    // No .orderBy('dueDate') — avoids Firestore dropping docs with null dueDate.
    // Sorting is done in Dart after the data arrives.
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('assignments')
          .where('className', isEqualTo: className.trim())
          .snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting &&
            !snap.hasData) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (snap.hasError) {
          return Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.cardBg,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text('Could not load assignments.',
                style: AppTextStyles.bodyMedium
                    .copyWith(color: AppColors.textSecondary)),
          );
        }

        final docs = snap.data?.docs ?? [];

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
                const Icon(Icons.assignment_turned_in_outlined,
                    size: 48, color: AppColors.textHint),
                const SizedBox(height: 12),
                Text('No assignments posted for $studentName yet.',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodyMedium
                        .copyWith(color: AppColors.textSecondary)),
              ],
            ),
          );
        }

        // Sort by dueDate ascending; nulls go last
        final sorted = List.of(docs)
          ..sort((a, b) {
            final aTs =
                (a.data() as Map<String, dynamic>)['dueDate']
                    as Timestamp?;
            final bTs =
                (b.data() as Map<String, dynamic>)['dueDate']
                    as Timestamp?;
            if (aTs == null && bTs == null) return 0;
            if (aTs == null) return 1;
            if (bTs == null) return -1;
            return aTs.compareTo(bTs);
          });

        // Split into upcoming and overdue
        final now = DateTime.now();
        final overdue = sorted.where((doc) {
          final dueDate = ((doc.data() as Map<String, dynamic>)['dueDate']
                  as Timestamp?)
              ?.toDate();
          return dueDate != null && dueDate.isBefore(now);
        }).toList();
        final upcoming = sorted.where((doc) {
          final dueDate = ((doc.data() as Map<String, dynamic>)['dueDate']
                  as Timestamp?)
              ?.toDate();
          return dueDate == null || !dueDate.isBefore(now);
        }).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Summary chip
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.accent.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: AppColors.accent.withOpacity(0.25)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.assignment_rounded,
                      color: AppColors.accent, size: 18),
                  const SizedBox(width: 10),
                  Text(
                    '${sorted.length} assignment${sorted.length == 1 ? '' : 's'}'
                    ' for $studentName',
                    style: AppTextStyles.labelSmall
                        .copyWith(color: AppColors.accent),
                  ),
                  if (overdue.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.danger.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${overdue.length} overdue',
                        style: AppTextStyles.labelTiny.copyWith(
                          color: AppColors.danger,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Overdue section
            if (overdue.isNotEmpty) ...[
              _SectionHeader(
                  label: 'Overdue', color: AppColors.danger),
              const SizedBox(height: 8),
              ...overdue.map((doc) => _AssignmentCard(
                    data: doc.data() as Map<String, dynamic>,
                    isOverdue: true,
                  )),
              const SizedBox(height: 16),
            ],

            // Upcoming section
            if (upcoming.isNotEmpty) ...[
              _SectionHeader(
                  label: 'Upcoming',
                  color: AppColors.accent),
              const SizedBox(height: 8),
              ...upcoming.map((doc) => _AssignmentCard(
                    data: doc.data() as Map<String, dynamic>,
                    isOverdue: false,
                  )),
            ],
            const SizedBox(height: 20),
          ],
        );
      },
    );
  }
}

// ── Section header ─────────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String label;
  final Color color;
  const _SectionHeader({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 16,
          decoration: BoxDecoration(
              color: color, borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 10),
        Text(label,
            style: AppTextStyles.sectionTitle.copyWith(color: color)),
      ],
    );
  }
}

// ── Assignment card ────────────────────────────────────────────────────────────
class _AssignmentCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final bool isOverdue;

  const _AssignmentCard({required this.data, required this.isOverdue});

  @override
  Widget build(BuildContext context) {
    final subject = data['subject'] as String? ?? '';
    final title = data['title'] as String? ?? '';
    final description = data['description'] as String? ?? '';
    final dueDate = (data['dueDate'] as Timestamp?)?.toDate();

    final Color accentColor =
        isOverdue ? AppColors.danger : AppColors.accent;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppColors.cardShadow,
        border: isOverdue
            ? Border.all(color: AppColors.danger.withOpacity(0.4))
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Subject badge
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  subject,
                  style: AppTextStyles.labelTiny.copyWith(
                    color: accentColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Spacer(),
              // Due date
              if (dueDate != null)
                Row(
                  children: [
                    Icon(
                      isOverdue
                          ? Icons.warning_amber_rounded
                          : Icons.calendar_today_rounded,
                      size: 14,
                      color: isOverdue
                          ? AppColors.danger
                          : AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isOverdue
                          ? 'Was due ${DateFormat('MMM d').format(dueDate)}'
                          : 'Due ${DateFormat('MMM d').format(dueDate)}',
                      style: AppTextStyles.labelTiny.copyWith(
                        color: isOverdue
                            ? AppColors.danger
                            : AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                )
              else
                Text('No due date',
                    style: AppTextStyles.labelTiny
                        .copyWith(color: AppColors.textHint)),
            ],
          ),
          const SizedBox(height: 10),
          Text(title, style: AppTextStyles.bodyMediumBold),
          if (description.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              description,
              style: AppTextStyles.labelSmall,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          // Days remaining / overdue indicator
          if (dueDate != null) ...[
            const SizedBox(height: 10),
            _DueBadge(dueDate: dueDate, isOverdue: isOverdue),
          ],
        ],
      ),
    );
  }
}

// ── Due badge ──────────────────────────────────────────────────────────────────
class _DueBadge extends StatelessWidget {
  final DateTime dueDate;
  final bool isOverdue;

  const _DueBadge({required this.dueDate, required this.isOverdue});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final diff = dueDate.difference(now);
    final String label;

    if (isOverdue) {
      final days = now.difference(dueDate).inDays;
      label = days == 0
          ? 'Due today'
          : '$days day${days == 1 ? '' : 's'} overdue';
    } else {
      final days = diff.inDays;
      if (days == 0) {
        label = 'Due today!';
      } else if (days == 1) {
        label = 'Due tomorrow';
      } else {
        label = '$days days remaining';
      }
    }

    final color = isOverdue
        ? AppColors.danger
        : diff.inDays <= 2
            ? AppColors.warning
            : AppColors.success;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration:
                BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTextStyles.labelTiny
                .copyWith(color: color, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}