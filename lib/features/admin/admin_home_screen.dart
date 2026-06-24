import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:school_management_system/core/theme/app_colors.dart';
import 'package:school_management_system/core/theme/app_text_style.dart';
import 'package:school_management_system/features/auth/providers/auth_provider.dart';

// ── Activity event model ───────────────────────────────────────────────────────
class ActivityEvent {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final DateTime? time;
  final String? route;

  const ActivityEvent({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    this.time,
    this.route,
  });
}

DateTime? _tsToDate(dynamic v) {
  if (v is Timestamp) return v.toDate();
  return null;
}

String _fmtTime(DateTime dt) {
  final diff = DateTime.now().difference(dt);
  if (diff.inMinutes < 1) return 'just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  return DateFormat('MMM d').format(dt);
}

// ── Screen ─────────────────────────────────────────────────────────────────────
class AdminHomeScreen extends ConsumerWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: _AdminHeader(userName: user?.displayName ?? 'Admin'),
            ),

            // Stats
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: _StatsRow(),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 20)),

            // Pending banner
            SliverToBoxAdapter(child: _PendingApprovalsBanner()),

            // Quick Actions label
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                child: Text('Quick Actions', style: AppTextStyles.sectionTitle),
              ),
            ),

            // Quick Actions — stretched full width
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _QuickActionsGrid(),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 24)),

            // Recent Activity label
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Recent Activity', style: AppTextStyles.sectionTitle),
                    TextButton(
                      onPressed: () => context.push('/admin/home/history'),
                      child: const Text('See all'),
                    ),
                  ],
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 8)),

            SliverToBoxAdapter(child: _RecentActivityFeed(limit: 8)),

            const SliverToBoxAdapter(child: SizedBox(height: 40)),
          ],
        ),
      ),
      bottomNavigationBar: const _AdminBottomNav(currentIndex: 0),
    );
  }
}

// ── Header ─────────────────────────────────────────────────────────────────────
class _AdminHeader extends StatelessWidget {
  final String userName;
  const _AdminHeader({required this.userName});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      decoration: const BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Good Morning,',
                      style: AppTextStyles.labelMedium
                          .copyWith(color: Colors.white70)),
                  const SizedBox(height: 4),
                  Text(userName,
                      style: AppTextStyles.headingLarge
                          .copyWith(color: Colors.white)),
                ],
              ),
              CircleAvatar(
                radius: 24,
                backgroundColor: Colors.white24,
                child: const Icon(Icons.admin_panel_settings_rounded,
                    color: Colors.white, size: 26),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white24),
            ),
            child: Row(children: [
              const Icon(Icons.search_rounded, color: Colors.white70, size: 20),
              const SizedBox(width: 10),
              Text('Search students, teachers...',
                  style: AppTextStyles.bodyMedium.copyWith(color: Colors.white60)),
            ]),
          ),
        ],
      ),
    );
  }
}

// ── Stats Row ──────────────────────────────────────────────────────────────────
class _StatsRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Expanded(
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('students').snapshots(),
          builder: (_, s) => _StatCard(
              label: 'Students',
              value: s.data?.docs.length.toString() ?? '...',
              icon: Icons.school_rounded,
              color: AppColors.studentColor),
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('teachers').snapshots(),
          builder: (_, s) => _StatCard(
              label: 'Teachers',
              value: s.data?.docs.length.toString() ?? '...',
              icon: Icons.person_rounded,
              color: AppColors.teacherColor),
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('classes').snapshots(),
          builder: (_, s) => _StatCard(
              label: 'Classes',
              value: s.data?.docs.length.toString() ?? '...',
              icon: Icons.class_rounded,
              color: AppColors.adminColor),
        ),
      ),
    ]);
  }
}

class _StatCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _StatCard(
      {required this.label,
      required this.value,
      required this.icon,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppColors.cardShadow),
      child: Column(children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration:
              BoxDecoration(color: color.withOpacity(0.12), shape: BoxShape.circle),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 8),
        Text(value, style: AppTextStyles.statValue),
        const SizedBox(height: 2),
        Text(label,
            style: AppTextStyles.labelSmall, textAlign: TextAlign.center),
      ]),
    );
  }
}

// ── Pending Banner ─────────────────────────────────────────────────────────────
class _PendingApprovalsBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('approved', isEqualTo: false)
          .snapshots(),
      builder: (context, snap) {
        final count = snap.data?.docs.length ?? 0;
        if (count == 0) return const SizedBox.shrink();
        return GestureDetector(
          onTap: () => context.push('/admin/home/approvals'),
          child: Container(
            margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.warning.withOpacity(0.10),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.warning.withOpacity(0.4)),
            ),
            child: Row(children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                    color: AppColors.warning.withOpacity(0.18),
                    shape: BoxShape.circle),
                child: const Icon(Icons.hourglass_top_rounded,
                    color: AppColors.warning, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$count pending approval${count == 1 ? '' : 's'}',
                        style: AppTextStyles.bodyMediumBold
                            .copyWith(color: AppColors.warning),
                      ),
                      Text('Tap to review registrations',
                          style: AppTextStyles.labelSmall),
                    ]),
              ),
              const Icon(Icons.chevron_right_rounded,
                  color: AppColors.warning, size: 18),
            ]),
          ),
        );
      },
    );
  }
}

// ── Quick Actions — responsive stretched grid ──────────────────────────────────
//
// Uses LayoutBuilder so every card fills its cell perfectly on any screen width.
// We show 3 columns. Each cell is square (aspectRatio 1.0) giving the icon room
// to breathe without truncating the label.
class _QuickActionsGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('approved', isEqualTo: false)
          .snapshots(),
      builder: (context, pendingSnap) {
        final pendingCount = pendingSnap.data?.docs.length ?? 0;

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('classes').snapshots(),
          builder: (context, classSnap) {
            final hasClasses = (classSnap.data?.docs.length ?? 0) > 0;

            final actions = <_QA>[
              _QA('Add Student', Icons.person_add_rounded, AppColors.studentColor, null),
              _QA('Add Teacher', Icons.person_add_alt_1_rounded, AppColors.teacherColor, null),
              _QA('Manage Classes', Icons.class_rounded, AppColors.adminColor, null),
              _QA('Timetable', Icons.calendar_month_rounded, AppColors.primary, null),
              _QA('Fees', Icons.attach_money_rounded, AppColors.warning, null),
              _QA('Notices', Icons.announcement_rounded, AppColors.accent, null),
              _QA(
                'Approvals',
                Icons.fact_check_rounded,
                pendingCount > 0 ? AppColors.danger : AppColors.success,
                pendingCount > 0 ? '$pendingCount' : null,
              ),
              _QA('Reports', Icons.bar_chart_rounded, AppColors.primary, null),
              _QA('Fix Classes', Icons.merge_type_rounded, AppColors.danger, null),
              _QA(
                'Setup Classes',
                Icons.auto_fix_high_rounded,
                hasClasses ? AppColors.textSecondary : AppColors.warning,
                hasClasses ? null : '!',
              ),
              _QA('History', Icons.history_rounded, AppColors.info, null),
              _QA('Students', Icons.people_rounded, AppColors.studentColor, null),
            ];

            const cols = 3;
            const spacing = 12.0;

            return LayoutBuilder(builder: (context, constraints) {
              final cellW =
                  (constraints.maxWidth - spacing * (cols - 1)) / cols;

              // Build rows of 3
              final rows = <Widget>[];
              for (var i = 0; i < actions.length; i += cols) {
                final rowItems = actions.sublist(
                    i, (i + cols).clamp(0, actions.length));

                // Pad last row if needed so all cells are same width
                while (rowItems.length < cols) {
                  rowItems.add(const _QA('', Icons.circle, Colors.transparent, null));
                }

                rows.add(Row(
                  children: rowItems.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final a = entry.value;
                    return [
                      if (idx > 0) const SizedBox(width: spacing),
                      SizedBox(
                        width: cellW,
                        height: cellW, // square cell
                        child: a.label.isEmpty
                            ? const SizedBox.shrink()
                            : Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  _QACard(
                                    qa: a,
                                    onTap: () =>
                                        _handleAction(context, a.label),
                                  ),
                                  if (a.badge != null)
                                    Positioned(
                                      top: -4,
                                      right: -4,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppColors.danger,
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        child: Text(
                                          a.badge!,
                                          style: const TextStyle(
                                            fontFamily: 'Poppins',
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                      ),
                    ];
                  }).expand((x) => x).toList(),
                ));

                if (i + cols < actions.length) {
                  rows.add(const SizedBox(height: spacing));
                }
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: rows,
              );
            });
          },
        );
      },
    );
  }

  void _handleAction(BuildContext context, String label) {
    const routes = {
      'Add Student': '/admin/home/students/add',
      'Add Teacher': '/admin/home/teachers/add',
      'Manage Classes': '/admin/home/classes',
      'Timetable': '/admin/home/timetable',
      'Fees': '/admin/home/fees',
      'Notices': '/admin/home/notices',
      'Approvals': '/admin/home/approvals',
      'Reports': '/admin/home/reports',
      'Fix Classes': '/admin/home/fix-class-names',
      'Setup Classes': '/admin/home/seed-classes',
      'History': '/admin/home/history',
      'Students': '/admin/home/students',
    };
    final route = routes[label];
    if (route != null) context.push(route);
  }
}

class _QA {
  final String label;
  final IconData icon;
  final Color color;
  final String? badge;
  const _QA(this.label, this.icon, this.color, this.badge);
}

class _QACard extends StatelessWidget {
  final _QA qa;
  final VoidCallback onTap;
  const _QACard({required this.qa, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        // Fill the parent SizedBox entirely
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppColors.cardShadow,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(
                color: qa.color.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(qa.icon, color: qa.color, size: 24),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Text(
                qa.label,
                style: AppTextStyles.labelSmall,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Recent Activity Feed ───────────────────────────────────────────────────────
class _RecentActivityFeed extends StatefulWidget {
  final int limit;
  const _RecentActivityFeed({this.limit = 8});

  @override
  State<_RecentActivityFeed> createState() => _RecentActivityFeedState();
}

class _RecentActivityFeedState extends State<_RecentActivityFeed> {
  List<QueryDocumentSnapshot> _students = [];
  List<QueryDocumentSnapshot> _teachers = [];
  List<QueryDocumentSnapshot> _notices = [];
  List<QueryDocumentSnapshot> _fees = [];
  List<QueryDocumentSnapshot> _attendance = [];
  List<QueryDocumentSnapshot> _assignments = [];
  List<QueryDocumentSnapshot> _results = [];
  List<QueryDocumentSnapshot> _pending = [];

  @override
  Widget build(BuildContext context) {
    final db = FirebaseFirestore.instance;
    final lim = widget.limit * 3;

    return StreamBuilder<QuerySnapshot>(
      stream: db.collection('students').orderBy('createdAt', descending: true).limit(lim).snapshots(),
      builder: (context, s) {
        if (s.hasData) _students = s.data!.docs;
        return StreamBuilder<QuerySnapshot>(
          stream: db.collection('teachers').orderBy('createdAt', descending: true).limit(lim).snapshots(),
          builder: (context, s) {
            if (s.hasData) _teachers = s.data!.docs;
            return StreamBuilder<QuerySnapshot>(
              stream: db.collection('notices').orderBy('createdAt', descending: true).limit(lim).snapshots(),
              builder: (context, s) {
                if (s.hasData) _notices = s.data!.docs;
                return StreamBuilder<QuerySnapshot>(
                  stream: db.collection('fees').orderBy('createdAt', descending: true).limit(lim).snapshots(),
                  builder: (context, s) {
                    if (s.hasData) _fees = s.data!.docs;
                    return StreamBuilder<QuerySnapshot>(
                      stream: db.collection('attendance').orderBy('createdAt', descending: true).limit(lim).snapshots(),
                      builder: (context, s) {
                        if (s.hasData) _attendance = s.data!.docs;
                        return StreamBuilder<QuerySnapshot>(
                          stream: db.collection('assignments').orderBy('createdAt', descending: true).limit(lim).snapshots(),
                          builder: (context, s) {
                            if (s.hasData) _assignments = s.data!.docs;
                            return StreamBuilder<QuerySnapshot>(
                              stream: db.collection('results').orderBy('createdAt', descending: true).limit(lim).snapshots(),
                              builder: (context, s) {
                                if (s.hasData) _results = s.data!.docs;
                                return StreamBuilder<QuerySnapshot>(
                                  stream: db.collection('users').where('approved', isEqualTo: false).orderBy('createdAt', descending: true).limit(lim).snapshots(),
                                  builder: (context, s) {
                                    if (s.hasData) _pending = s.data!.docs;
                                    final events = _build();
                                    if (events.isEmpty) return _empty();
                                    return Column(
                                      children: events
                                          .take(widget.limit)
                                          .map((e) => _ActivityTile(event: e))
                                          .toList(),
                                    );
                                  },
                                );
                              },
                            );
                          },
                        );
                      },
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  List<ActivityEvent> _build() {
    final List<ActivityEvent> ev = [];

    for (final doc in _students) {
      final d = doc.data() as Map<String, dynamic>;
      ev.add(ActivityEvent(
        title: 'New student: ${d['name'] ?? 'Unknown'}',
        subtitle: 'Class ${d['class'] ?? '-'} · Roll ${d['rollNo'] ?? '-'}',
        icon: Icons.person_add_rounded,
        color: AppColors.studentColor,
        time: _tsToDate(d['createdAt']),
        route: '/admin/home/students',
      ));
    }
    for (final doc in _teachers) {
      final d = doc.data() as Map<String, dynamic>;
      ev.add(ActivityEvent(
        title: 'New teacher: ${d['name'] ?? 'Unknown'}',
        subtitle: 'Subject: ${d['subject'] ?? '-'}',
        icon: Icons.person_add_alt_1_rounded,
        color: AppColors.teacherColor,
        time: _tsToDate(d['createdAt']),
        route: '/admin/home/teachers',
      ));
    }
    for (final doc in _notices) {
      final d = doc.data() as Map<String, dynamic>;
      ev.add(ActivityEvent(
        title: 'Notice: ${d['title'] ?? 'Untitled'}',
        subtitle: d['category'] ?? 'General',
        icon: Icons.campaign_rounded,
        color: AppColors.accent,
        time: _tsToDate(d['createdAt']),
        route: '/admin/home/notices',
      ));
    }
    for (final doc in _fees) {
      final d = doc.data() as Map<String, dynamic>;
      final st = d['status'] as String? ?? 'pending';
      ev.add(ActivityEvent(
        title: 'Fee ${st == 'paid' ? 'paid' : 'added'}: ${d['studentName'] ?? ''}',
        subtitle: 'Rs. ${(d['amount'] as num?)?.toStringAsFixed(0) ?? '0'} · $st',
        icon: Icons.attach_money_rounded,
        color: st == 'paid' ? AppColors.success : AppColors.warning,
        time: _tsToDate(d['createdAt']),
        route: '/admin/home/fees',
      ));
    }
    for (final doc in _attendance) {
      final d = doc.data() as Map<String, dynamic>;
      ev.add(ActivityEvent(
        title: 'Attendance: ${d['className'] ?? ''}',
        subtitle: '${d['studentName'] ?? ''} · ${d['status'] ?? ''} · ${d['date'] ?? ''}',
        icon: Icons.how_to_reg_rounded,
        color: AppColors.teacherColor,
        time: _tsToDate(d['createdAt'] ?? d['timestamp']),
      ));
    }
    for (final doc in _assignments) {
      final d = doc.data() as Map<String, dynamic>;
      ev.add(ActivityEvent(
        title: 'Assignment: ${d['title'] ?? 'Untitled'}',
        subtitle: '${d['className'] ?? ''} · ${d['subject'] ?? ''}',
        icon: Icons.assignment_rounded,
        color: AppColors.primary,
        time: _tsToDate(d['createdAt']),
      ));
    }
    for (final doc in _results) {
      final d = doc.data() as Map<String, dynamic>;
      ev.add(ActivityEvent(
        title: 'Result: ${d['studentName'] ?? ''}',
        subtitle:
            '${d['subject'] ?? ''} · ${d['examTitle'] ?? ''} · ${(d['percentage'] as num?)?.toStringAsFixed(0) ?? '0'}%',
        icon: Icons.bar_chart_rounded,
        color: AppColors.info,
        time: _tsToDate(d['createdAt']),
      ));
    }
    for (final doc in _pending) {
      final d = doc.data() as Map<String, dynamic>;
      final role = d['role'] as String? ?? 'user';
      ev.add(ActivityEvent(
        title: '${d['name'] ?? 'Unknown'} awaiting approval',
        subtitle: '${role[0].toUpperCase()}${role.substring(1)} registration',
        icon: Icons.hourglass_top_rounded,
        color: AppColors.warning,
        time: _tsToDate(d['createdAt']),
        route: '/admin/home/approvals',
      ));
    }

    ev.sort((a, b) {
      if (a.time == null && b.time == null) return 0;
      if (a.time == null) return 1;
      if (b.time == null) return -1;
      return b.time!.compareTo(a.time!);
    });
    return ev;
  }

  Widget _empty() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(14),
          boxShadow: AppColors.cardShadow),
      child: Column(children: [
        const Icon(Icons.history_rounded, size: 36, color: AppColors.textHint),
        const SizedBox(height: 10),
        Text('No activity yet',
            style: AppTextStyles.labelSmall
                .copyWith(color: AppColors.textSecondary)),
      ]),
    );
  }
}

class _ActivityTile extends StatelessWidget {
  final ActivityEvent event;
  const _ActivityTile({required this.event});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: event.route != null ? () => context.push(event.route!) : null,
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
            color: AppColors.cardBg,
            borderRadius: BorderRadius.circular(14),
            boxShadow: AppColors.cardShadow),
        child: Row(children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
                color: event.color.withOpacity(0.12), shape: BoxShape.circle),
            child: Icon(event.icon, color: event.color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(event.title,
                  style: AppTextStyles.bodyMediumBold,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
              const SizedBox(height: 2),
              Text(event.subtitle,
                  style: AppTextStyles.labelSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ]),
          ),
          if (event.time != null) ...[
            const SizedBox(width: 8),
            Text(_fmtTime(event.time!),
                style: AppTextStyles.labelTiny.copyWith(color: AppColors.textHint)),
          ],
          if (event.route != null)
            const Icon(Icons.chevron_right_rounded,
                size: 16, color: AppColors.textHint),
        ]),
      ),
    );
  }
}

// ── Activity History Screen ────────────────────────────────────────────────────
class AdminActivityHistoryScreen extends StatelessWidget {
  const AdminActivityHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.adminColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: Text('Activity History',
            style: AppTextStyles.headingMedium.copyWith(color: Colors.white)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(top: 16, bottom: 48),
        child: _RecentActivityFeed(limit: 60),
      ),
    );
  }
}

// ── Bottom Nav ─────────────────────────────────────────────────────────────────
class _AdminBottomNav extends StatelessWidget {
  final int currentIndex;
  const _AdminBottomNav({required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.textSecondary,
      backgroundColor: AppColors.cardBg,
      elevation: 12,
      selectedLabelStyle: AppTextStyles.navLabel,
      unselectedLabelStyle: AppTextStyles.navLabel,
      onTap: (i) {
        switch (i) {
          case 0: context.go('/admin/home'); break;
          case 1: context.go('/admin/home/students'); break;
          case 2: context.go('/admin/home/teachers'); break;
          case 3: context.go('/admin/home/reports'); break;
          case 4: context.go('/admin/home/settings'); break;
        }
      },
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.school_rounded), label: 'Students'),
        BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'Teachers'),
        BottomNavigationBarItem(icon: Icon(Icons.bar_chart_rounded), label: 'Reports'),
        BottomNavigationBarItem(icon: Icon(Icons.settings_rounded), label: 'Settings'),
      ],
    );
  }
}


