import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:school_management_system/core/theme/app_colors.dart';
import 'package:school_management_system/core/theme/app_text_style.dart';
import 'package:school_management_system/features/auth/providers/auth_provider.dart';

// ── Route: /parent/home/fees
// Add to app_router.dart under /parent/home routes:
//   GoRoute(path: 'fees', builder: (_, __) => const ParentFeeScreen()),
// Add to parent home quick actions grid:
//   _QuickCard(icon: Icons.receipt_long_rounded, label: 'Fees', color: AppColors.warning,
//              onTap: () => context.push('/parent/home/fees')),

class ParentFeeScreen extends ConsumerWidget {
  const ParentFeeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = ref.watch(authProvider).user?.uid;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.warning,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: Text(
          "Fee Records",
          style: AppTextStyles.headingMedium.copyWith(color: Colors.white),
        ),
      ),
      body: uid == null
          ? const Center(child: CircularProgressIndicator())
          : _ParentFeeBody(parentUid: uid),
    );
  }
}

// ── Body: loads linked children then shows their fees ────────────────────────

class _ParentFeeBody extends StatefulWidget {
  final String parentUid;
  const _ParentFeeBody({required this.parentUid});

  @override
  State<_ParentFeeBody> createState() => _ParentFeeBodyState();
}

class _ParentFeeBodyState extends State<_ParentFeeBody> {
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
        final sDoc = await FirebaseFirestore.instance
            .collection('students')
            .doc(studentId)
            .get();
        if (sDoc.exists) {
          children.add({
            'studentId': studentId,
            'name': sDoc.data()?['name'] as String? ?? 'Student',
            'class': sDoc.data()?['class'] as String? ?? '',
            'rollNo': sDoc.data()?['rollNo'] as String? ?? '',
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
    if (_loading) return const Center(child: CircularProgressIndicator());

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

    // Single child → go straight to fee detail
    if (_children.length == 1) {
      return _FeeDetailForChild(
        studentId: _children[0]['studentId'] as String,
        studentName: _children[0]['name'] as String,
        className: _children[0]['class'] as String,
        rollNo: _children[0]['rollNo'] as String,
      );
    }

    // Multiple children → selector + detail
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text('Select a child', style: AppTextStyles.sectionTitle),
        const SizedBox(height: 12),
        ..._children.asMap().entries.map((entry) {
          final i = entry.key;
          final child = entry.value;
          final isSelected = _selectedIndex == i;

          return GestureDetector(
            onTap: () =>
                setState(() => _selectedIndex = isSelected ? -1 : i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? const LinearGradient(
                        colors: [Color(0xFFE67E22), Color(0xFFF59E0B)],
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
                        : AppColors.warning.withOpacity(0.12),
                    child: Text(
                      (child['name'] as String).isNotEmpty
                          ? (child['name'] as String)[0].toUpperCase()
                          : 'S',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                        color: isSelected ? Colors.white : AppColors.warning,
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
                    color: isSelected ? Colors.white : AppColors.textSecondary,
                  ),
                ],
              ),
            ),
          );
        }),

        if (_selectedIndex >= 0 && _selectedIndex < _children.length) ...[
          const SizedBox(height: 8),
          _FeeDetailForChild(
            studentId: _children[_selectedIndex]['studentId'] as String,
            studentName: _children[_selectedIndex]['name'] as String,
            className: _children[_selectedIndex]['class'] as String,
            rollNo: _children[_selectedIndex]['rollNo'] as String,
          ),
        ],
      ],
    );
  }
}

// ── Fee detail for one child ──────────────────────────────────────────────────

class _FeeDetailForChild extends StatefulWidget {
  final String studentId;
  final String studentName;
  final String className;
  final String rollNo;

  const _FeeDetailForChild({
    required this.studentId,
    required this.studentName,
    required this.className,
    required this.rollNo,
  });

  @override
  State<_FeeDetailForChild> createState() => _FeeDetailForChildState();
}

class _FeeDetailForChildState extends State<_FeeDetailForChild> {
  String _filter = 'All'; // All | paid | pending | overdue

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('fees')
          .where('studentId', isEqualTo: widget.studentId)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting && !snap.hasData) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final allDocs = snap.data?.docs ?? [];

        // Calculate summary totals
        double totalPaid = 0, totalPending = 0, totalOverdue = 0;
        int paidCount = 0, pendingCount = 0, overdueCount = 0;

        for (final doc in allDocs) {
          final data = doc.data() as Map<String, dynamic>;
          final amount = (data['amount'] as num?)?.toDouble() ?? 0;
          final status = data['status'] as String? ?? 'pending';
          switch (status) {
            case 'paid':
              totalPaid += amount;
              paidCount++;
              break;
            case 'pending':
              totalPending += amount;
              pendingCount++;
              break;
            case 'overdue':
              totalOverdue += amount;
              overdueCount++;
              break;
          }
        }

        // Apply filter
        final filtered = _filter == 'All'
            ? allDocs
            : allDocs.where((d) {
                final data = d.data() as Map<String, dynamic>;
                return (data['status'] as String? ?? '') == _filter;
              }).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Summary cards ───────────────────────────────────
            _FeeSummaryRow(
              totalPaid: totalPaid,
              totalPending: totalPending,
              totalOverdue: totalOverdue,
              paidCount: paidCount,
              pendingCount: pendingCount,
              overdueCount: overdueCount,
            ),
            const SizedBox(height: 20),

            // ── Alert if overdue ─────────────────────────────────
            if (overdueCount > 0) ...[
              Container(
                padding: const EdgeInsets.all(14),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.danger.withOpacity(0.07),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: AppColors.danger.withOpacity(0.35)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded,
                        color: AppColors.danger, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '$overdueCount overdue fee${overdueCount == 1 ? '' : 's'} '
                        'totalling Rs. ${NumberFormat('#,##0').format(totalOverdue)}. '
                        'Please contact the school office.',
                        style: AppTextStyles.labelSmall
                            .copyWith(color: AppColors.danger),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // ── Filter chips ─────────────────────────────────────
            SizedBox(
              height: 34,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: ['All', 'paid', 'pending', 'overdue']
                    .map((s) {
                  final isSel = _filter == s;
                  final color = _statusColor(s);
                  return GestureDetector(
                    onTap: () => setState(() => _filter = s),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSel ? color.withOpacity(0.12) : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: isSel ? color : AppColors.divider),
                      ),
                      child: Text(
                        s == 'All' ? 'All' : _capitalize(s),
                        style: AppTextStyles.labelSmall.copyWith(
                          color: isSel ? color : AppColors.textSecondary,
                          fontWeight:
                              isSel ? FontWeight.w700 : FontWeight.w400,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),

            // ── Fee list ──────────────────────────────────────────
            if (filtered.isEmpty)
              Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: AppColors.cardBg,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: AppColors.cardShadow,
                ),
                child: Column(
                  children: [
                    const Icon(Icons.receipt_long_outlined,
                        size: 48, color: AppColors.textHint),
                    const SizedBox(height: 12),
                    Text(
                      _filter == 'All'
                          ? 'No fee records yet.'
                          : 'No ${_capitalize(_filter)} fees.',
                      style: AppTextStyles.bodyMedium
                          .copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              )
            else
              ...filtered.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return _FeeCard(
                  data: data,
                  studentName: widget.studentName,
                );
              }),

            const SizedBox(height: 20),

            // ── Info note ─────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.info.withOpacity(0.07),
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: AppColors.info.withOpacity(0.25)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline_rounded,
                      color: AppColors.info, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'To pay fees, please visit the school finance office '
                      'or use the school\'s official bank account. '
                      'Bring this record as reference.',
                      style: AppTextStyles.labelSmall
                          .copyWith(color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        );
      },
    );
  }
}

// ── Summary row ───────────────────────────────────────────────────────────────

class _FeeSummaryRow extends StatelessWidget {
  final double totalPaid, totalPending, totalOverdue;
  final int paidCount, pendingCount, overdueCount;

  const _FeeSummaryRow({
    required this.totalPaid,
    required this.totalPending,
    required this.totalOverdue,
    required this.paidCount,
    required this.pendingCount,
    required this.overdueCount,
  });

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##0');
    return Column(
      children: [
        // Total paid — full-width hero card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF22C55E), Color(0xFF16A34A)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: AppColors.cardShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Total Paid',
                  style: AppTextStyles.labelMedium
                      .copyWith(color: Colors.white70)),
              const SizedBox(height: 8),
              Text('Rs. ${fmt.format(totalPaid)}',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  )),
              const SizedBox(height: 4),
              Text('$paidCount payment${paidCount == 1 ? '' : 's'} received',
                  style: AppTextStyles.labelSmall
                      .copyWith(color: Colors.white70)),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _SummaryCard(
                label: 'Pending',
                amount: totalPending,
                count: pendingCount,
                color: AppColors.warning,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SummaryCard(
                label: 'Overdue',
                amount: totalOverdue,
                count: overdueCount,
                color: AppColors.danger,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final double amount;
  final int count;
  final Color color;

  const _SummaryCard({
    required this.label,
    required this.amount,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: AppTextStyles.labelSmall.copyWith(color: color)),
          const SizedBox(height: 8),
          Text(
            'Rs. ${NumberFormat('#,##0').format(amount)}',
            style: AppTextStyles.bodyMediumBold,
          ),
          const SizedBox(height: 4),
          Text('$count record${count == 1 ? '' : 's'}',
              style: AppTextStyles.labelTiny),
        ],
      ),
    );
  }
}

// ── Fee card ──────────────────────────────────────────────────────────────────

class _FeeCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final String studentName;

  const _FeeCard({required this.data, required this.studentName});

  @override
  Widget build(BuildContext context) {
    final status = data['status'] as String? ?? 'pending';
    final color = _statusColor(status);
    final amount = (data['amount'] as num?)?.toDouble() ?? 0;
    final month = data['month'] as String? ?? '';
    final year = data['year'] as int? ?? DateTime.now().year;
    final feeType = data['feeType'] as String? ?? data['feeType'] ?? 'Tuition';
    final dueDate = (data['dueDate'] as Timestamp?)?.toDate();
    final paidAt = (data['paidAt'] as Timestamp?)?.toDate();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppColors.cardShadow,
        border: Border(left: BorderSide(color: color, width: 4)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Fee type badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    feeType,
                    style: AppTextStyles.labelTiny.copyWith(
                        color: color, fontWeight: FontWeight.w700),
                  ),
                ),
                const Spacer(),
                // Status badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _capitalize(status),
                    style: AppTextStyles.labelTiny.copyWith(
                        color: color, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        studentName,
                        style: AppTextStyles.bodyMediumBold,
                      ),
                      if (month.isNotEmpty || year != 0) ...[
                        const SizedBox(height: 3),
                        Text(
                          '$month $year',
                          style: AppTextStyles.labelSmall,
                        ),
                      ],
                      if (dueDate != null && status != 'paid') ...[
                        const SizedBox(height: 3),
                        Text(
                          'Due: ${DateFormat('MMM d, yyyy').format(dueDate)}',
                          style: AppTextStyles.labelTiny.copyWith(
                            color: status == 'overdue'
                                ? AppColors.danger
                                : AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                      if (paidAt != null && status == 'paid') ...[
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            const Icon(Icons.check_circle_outline_rounded,
                                size: 13, color: AppColors.success),
                            const SizedBox(width: 4),
                            Text(
                              'Paid ${DateFormat('MMM d, yyyy').format(paidAt)}',
                              style: AppTextStyles.labelTiny.copyWith(
                                  color: AppColors.success),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                Text(
                  'Rs. ${NumberFormat('#,##0').format(amount)}',
                  style: AppTextStyles.headingMedium.copyWith(
                    color: status == 'paid'
                        ? AppColors.success
                        : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

Color _statusColor(String status) {
  switch (status) {
    case 'paid':
      return AppColors.success;
    case 'overdue':
      return AppColors.danger;
    default:
      return AppColors.warning;
  }
}

String _capitalize(String s) =>
    s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';