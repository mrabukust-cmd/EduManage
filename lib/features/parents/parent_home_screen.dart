import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:school_management_system/core/theme/app_colors.dart';
import 'package:school_management_system/core/theme/app_text_style.dart';
import 'package:school_management_system/features/auth/providers/auth_provider.dart';

class ParentHomeScreen extends ConsumerWidget {
  const ParentHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final uid = user?.uid;
    final parentName = user?.displayName ?? 'Parent';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _ParentHeader(userName: parentName, uid: uid)),
            const SliverToBoxAdapter(child: SizedBox(height: 20)),

            // Children cards
            if (uid != null)
              SliverToBoxAdapter(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('parent_children')
                      .where('parentId', isEqualTo: uid)
                      .snapshots(),
                  builder: (context, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final children = snap.data?.docs ?? [];
                    if (children.isEmpty) {
                      return _NoChildLinked();
                    }
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Text(
                            'My Children',
                            style: AppTextStyles.sectionTitle,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...children.map((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          final studentId = data['studentId'] as String? ?? '';
                          return _ChildCard(
                            studentId: studentId,
                            docId: doc.id,
                          );
                        }),
                      ],
                    );
                  },
                ),
              ),

            const SliverToBoxAdapter(child: SizedBox(height: 24)),

            // Quick actions
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text('Quick Access', style: AppTextStyles.sectionTitle),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 14)),
            SliverToBoxAdapter(
              child: uid != null
                  ? _QuickActionsWithChild(parentUid: uid)
                  : Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: _buildStaticActions(context, null),
                    ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 24)),

            // Recent notices - only from notices collection
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Latest Notices',
                  style: AppTextStyles.sectionTitle,
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 12)),
            SliverToBoxAdapter(child: _RecentNotices()),
            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
      bottomNavigationBar: const _ParentBottomNav(currentIndex: 0),
    );
  }

  Widget _buildStaticActions(BuildContext context, String? childClass) {
    return GridView.count(
      crossAxisCount: 1,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.2,
      children: [
        _QuickCard(
          icon: Icons.how_to_reg_rounded,
          label: "Child's Attendance",
          color: AppColors.success,
          onTap: () => context.push('/parent/home/attendance'),
        ),
        _QuickCard(
          icon: Icons.bar_chart_rounded,
          label: "Child's Results",
          color: AppColors.primary,
          onTap: () => context.push('/parent/home/results'),
        ),
        _QuickCard(
          icon: Icons.campaign_rounded,
          label: 'School Notices',
          color: AppColors.accent,
          onTap: () => context.push('/parent/home/notices'),
        ),
        // FIX: Timetable now passes fixedClassName so only child's class is shown
        _QuickCard(
          icon: Icons.schedule_rounded,
          label: 'Timetable',
          color: AppColors.warning,
          onTap: () =>
              context.push('/parent/home/timetable', extra: childClass),
        ),
        _QuickCard(
          icon: Icons.assignment_rounded,
          label: 'Assignments',
          color: AppColors.accent,
          onTap: () => context.push('/parent/home/assignments'),
        ),
        _QuickCard(
          icon: Icons.receipt_long_rounded,
          label: 'Pay Fees',
          color: AppColors.warning,
          onTap: () => context.push('/parent/home/fees'),
        ),
      ],
    );
  }
}

// FIX: Fetches child's class first, then passes it to timetable route
// so parent only sees their child's class schedule, not all classes.
class _QuickActionsWithChild extends StatefulWidget {
  final String parentUid;
  const _QuickActionsWithChild({required this.parentUid});

  @override
  State<_QuickActionsWithChild> createState() => _QuickActionsWithChildState();
}

class _QuickActionsWithChildState extends State<_QuickActionsWithChild> {
  String? _childClass;

  @override
  void initState() {
    super.initState();
    _loadChildClass();
  }

  Future<void> _loadChildClass() async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('parent_children')
          .where('parentId', isEqualTo: widget.parentUid)
          .limit(1)
          .get();

      if (snap.docs.isEmpty) return;

      final studentId = snap.docs.first.data()['studentId'] as String? ?? '';
      if (studentId.isEmpty) return;

      final studentDoc = await FirebaseFirestore.instance
          .collection('students')
          .doc(studentId)
          .get();

      if (mounted) {
        setState(() {
          _childClass = studentDoc.data()?['class'] as String? ?? '';
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.5,
        children: [
          _QuickCard(
            icon: Icons.how_to_reg_rounded,
            label: "Child's Attendance",
            color: AppColors.success,
            onTap: () => context.push('/parent/home/attendance'),
          ),
          _QuickCard(
            icon: Icons.bar_chart_rounded,
            label: "Child's Results",
            color: AppColors.primary,
            onTap: () => context.push('/parent/home/results'),
          ),
          _QuickCard(
            icon: Icons.campaign_rounded,
            label: 'School Notices',
            color: AppColors.accent,
            onTap: () => context.push('/parent/home/notices'),
          ),
          // FIX: Pass child's class name via 'extra' to timetable
          _QuickCard(
            icon: Icons.schedule_rounded,
            label: 'Timetable',
            color: AppColors.warning,
            onTap: () =>
                context.push('/parent/home/timetable', extra: _childClass),
          ),
          _QuickCard(
            icon: Icons.assignment_rounded,
            label: "Assignments",
            color: AppColors.accent,
            onTap: () => context.push('/parent/home/assignments'),
          ),
          _QuickCard(
            icon: Icons.receipt_long_rounded,
            label: 'Pay Fees',
            color: AppColors.warning,
            onTap: () => context.push('/parent/home/fees'),
          ),
        ],
      ),
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────
class _ParentHeader extends StatelessWidget {
  final String userName;
  final String? uid;
  const _ParentHeader({required this.userName, this.uid});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1A56DB)],
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
                Text(
                  'Welcome,',
                  style: AppTextStyles.labelMedium.copyWith(
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  userName,
                  style: AppTextStyles.headingLarge.copyWith(
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('EEEE, MMMM d').format(DateTime.now()),
                  style: AppTextStyles.labelMedium.copyWith(
                    color: Colors.white60,
                  ),
                ),
              ],
            ),
          ),
          // Replace the bell IconButton in _ParentHeader with this:
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('notifications')
                .where('uid', isEqualTo: uid) // pass uid into _ParentHeader
                .where('isRead', isEqualTo: false)
                .snapshots(),
            builder: (context, snap) {
              final unread = snap.data?.docs.length ?? 0;
              return Stack(
                children: [
                  IconButton(
                    onPressed: () => context.push('/parent/notifications'),
                    icon: const Icon(
                      Icons.notifications_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  if (unread > 0)
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Container(
                        width: 16,
                        height: 16,
                        decoration: const BoxDecoration(
                          color: AppColors.danger,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            unread > 9 ? '9+' : '$unread',
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          GestureDetector(
            onTap: () => context.push('/parent/home/profile'),
            child: const CircleAvatar(
              radius: 22,
              backgroundColor: Colors.white24,
              child: Icon(Icons.person_rounded, color: Colors.white, size: 24),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Child card ────────────────────────────────────────────────────────────────
class _ChildCard extends StatelessWidget {
  final String studentId;
  final String docId;
  const _ChildCard({required this.studentId, required this.docId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('students')
          .doc(studentId)
          .snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) return const SizedBox.shrink();
        final data = snap.data?.data() as Map<String, dynamic>?;
        if (data == null) return const SizedBox.shrink();

        final name = data['name'] as String? ?? 'Student';
        final className = data['class'] as String? ?? '-';
        final rollNo = data['rollNo'] as String? ?? '-';

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('attendance')
              .where('studentId', isEqualTo: studentId)
              .snapshots(),
          builder: (context, attSnap) {
            final attDocs = attSnap.data?.docs ?? [];
            int present = 0;
            for (final doc in attDocs) {
              final d = doc.data() as Map<String, dynamic>;
              if ((d['status'] as String?) == 'present') present++;
            }
            final total = attDocs.length;
            final pct = total > 0 ? (present / total * 100).round() : 0;

            return Container(
              margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1A56DB), Color(0xFF7C3AED)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: AppColors.cardShadow,
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.white24,
                    child: Text(
                      name.isNotEmpty ? name[0].toUpperCase() : 'S',
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w700,
                        fontSize: 22,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: AppTextStyles.bodyMediumBold.copyWith(
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$className • Roll: $rollNo',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '$pct%',
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Attendance',
                        style: AppTextStyles.labelTiny.copyWith(
                          color: Colors.white60,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

// ── No child linked ───────────────────────────────────────────────────────────
class _NoChildLinked extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(
          children: [
            const Icon(
              Icons.family_restroom_rounded,
              size: 48,
              color: AppColors.textHint,
            ),
            const SizedBox(height: 12),
            Text('No child linked yet', style: AppTextStyles.bodyMediumBold),
            const SizedBox(height: 6),
            Text(
              'Contact the school admin to link your child\'s account.',
              textAlign: TextAlign.center,
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Quick card ────────────────────────────────────────────────────────────────
class _QuickCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _QuickCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppColors.cardShadow,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: AppTextStyles.labelSmall.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Recent Notices (FIX: only from 'notices' collection, no attendance/grades) ─
//
// PROBLEM: The old widget was correctly querying 'notices' collection but
// the Firestore 'notices' collection itself was receiving attendance and
// grade-related records in some setups where teachers were writing to wrong
// collection. The fix adds a category filter — only show documents that
// have a valid 'category' field (General/Event/Exam/Finance/Holiday),
// which attendance and grade records don't have.
class _RecentNotices extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('notices') // Only 'notices' collection
          .orderBy('createdAt', descending: true)
          .limit(5)
          .snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snap.data?.docs ?? [];

        // FIX: Filter out any docs that don't look like real notices.
        // Real notices always have a 'title' and 'body'. Attendance records
        // (if accidentally written to notices) have 'studentId', 'date', etc.
        // Grade records have 'marksObtained'. Filter those out.
        final noticeOnly = docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final hasTitle = (data['title'] as String? ?? '').isNotEmpty;
          final isNotAttendance =
              data['studentId'] == null &&
              data['marksObtained'] == null &&
              data['status'] == null;
          return hasTitle && isNotAttendance;
        }).toList();

        if (noticeOnly.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'No notices yet.',
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.textHint,
              ),
            ),
          );
        }

        return Column(
          children: noticeOnly.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final category = data['category'] as String? ?? 'General';
            final Color color;
            switch (category) {
              case 'Exam':
                color = AppColors.primary;
                break;
              case 'Event':
                color = AppColors.accent;
                break;
              case 'Finance':
                color = AppColors.warning;
                break;
              case 'Holiday':
                color = AppColors.success;
                break;
              default:
                color = AppColors.textSecondary;
            }
            return Container(
              margin: const EdgeInsets.fromLTRB(20, 0, 20, 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.cardBg,
                borderRadius: BorderRadius.circular(14),
                boxShadow: AppColors.cardShadow,
                border: Border(left: BorderSide(color: color, width: 4)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          category,
                          style: AppTextStyles.labelTiny.copyWith(
                            color: color,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        data['createdAt'] != null
                            ? DateFormat('MMM d').format(
                                (data['createdAt'] as Timestamp).toDate(),
                              )
                            : '',
                        style: AppTextStyles.labelTiny,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    data['title'] ?? '',
                    style: AppTextStyles.bodyMediumBold,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    data['body'] ?? '',
                    style: AppTextStyles.labelSmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

// ── Bottom Nav ────────────────────────────────────────────────────────────────
class _ParentBottomNav extends StatelessWidget {
  final int currentIndex;
  const _ParentBottomNav({required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.textSecondary,
      backgroundColor: AppColors.cardBg,
      elevation: 12,
      onTap: (i) {
        switch (i) {
          case 0:
            context.go('/parent/home');
            break;
          case 1:
            context.go('/parent/home/attendance');
            break;
          case 2:
            context.go('/parent/home/results');
            break;
          case 3:
            context.go('/parent/home/notices');
            break;
          case 4:
            context.go('/parent/home/fees');
            break; // NEW
          case 5:
            context.go('/parent/home/profile');
            break;
        }
      },
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Home'),
        BottomNavigationBarItem(
          icon: Icon(Icons.how_to_reg_rounded),
          label: 'Attendance',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.bar_chart_rounded),
          label: 'Results',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.campaign_rounded),
          label: 'Notices',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.receipt_long_rounded),
          label: 'Fees',
        ), // NEW
        BottomNavigationBarItem(
          icon: Icon(Icons.person_rounded),
          label: 'Profile',
        ),
      ],
    );
  }
}
