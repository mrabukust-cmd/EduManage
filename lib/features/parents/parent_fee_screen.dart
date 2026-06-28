import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:school_management_system/core/theme/app_colors.dart';
import 'package:school_management_system/core/theme/app_text_style.dart';
import 'package:school_management_system/data/services/notification_helper.dart';
import 'package:school_management_system/features/auth/providers/auth_provider.dart';

// ── Route: /parent/home/fees
// Add to app_router.dart under /parent/home routes:
//   GoRoute(path: 'fees', builder: (_, __) => const ParentFeePaymentScreen()),
//
// Add to parent home quick actions grid:
//   _QuickCard(
//     icon: Icons.receipt_long_rounded,
//     label: 'Pay Fees',
//     color: AppColors.warning,
//     onTap: () => context.push('/parent/home/fees'),
//   ),
//
// Firestore fee document fields used/added:
//   - Existing: studentId, studentName, className, feeType, amount, status,
//               dueDate, createdAt, month, year
//   - New: paymentProof (map) containing:
//       transactionId: String
//       paidAmount: double
//       paymentDate: String (formatted)
//       paymentDateTimestamp: Timestamp
//       notes: String
//       submittedAt: Timestamp
//       submittedBy: String (parentUid)
//     status becomes 'pending_verification' after parent submits proof
//
// Admin fee screen reads 'pending_verification' status and shows a
// "Verify Payment" button. See admin_fee_payment_verification.dart

class ParentFeePaymentScreen extends ConsumerWidget {
  const ParentFeePaymentScreen({super.key});

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
          'Fee Payment',
          style: AppTextStyles.headingMedium.copyWith(color: Colors.white),
        ),
      ),
      body: uid == null
          ? const Center(child: CircularProgressIndicator())
          : _ParentFeeBody(parentUid: uid),
    );
  }
}

// ── Body ──────────────────────────────────────────────────────────────────────

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
                style:
                    AppTextStyles.labelSmall.copyWith(color: AppColors.textHint)),
          ],
        ),
      );
    }

    // Single child → go straight to fees
    if (_children.length == 1) {
      return _FeeListForChild(
        studentId: _children[0]['studentId'] as String,
        studentName: _children[0]['name'] as String,
        className: _children[0]['class'] as String,
        rollNo: _children[0]['rollNo'] as String,
        parentUid: widget.parentUid,
      );
    }

    // Multiple children → selector + fee list
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
                border: isSelected ? null : Border.all(color: AppColors.divider),
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
                        Text(child['name'] as String,
                            style: AppTextStyles.bodyMediumBold.copyWith(
                              color: isSelected
                                  ? Colors.white
                                  : AppColors.textPrimary,
                            )),
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
                    color:
                        isSelected ? Colors.white : AppColors.textSecondary,
                  ),
                ],
              ),
            ),
          );
        }),
        if (_selectedIndex >= 0 && _selectedIndex < _children.length) ...[
          const SizedBox(height: 8),
          _FeeListForChild(
            studentId: _children[_selectedIndex]['studentId'] as String,
            studentName: _children[_selectedIndex]['name'] as String,
            className: _children[_selectedIndex]['class'] as String,
            rollNo: _children[_selectedIndex]['rollNo'] as String,
            parentUid: widget.parentUid,
          ),
        ],
      ],
    );
  }
}

// ── Fee list for one child ────────────────────────────────────────────────────

class _FeeListForChild extends StatefulWidget {
  final String studentId;
  final String studentName;
  final String className;
  final String rollNo;
  final String parentUid;

  const _FeeListForChild({
    required this.studentId,
    required this.studentName,
    required this.className,
    required this.rollNo,
    required this.parentUid,
  });

  @override
  State<_FeeListForChild> createState() => _FeeListForChildState();
}

class _FeeListForChildState extends State<_FeeListForChild> {
  String _filter = 'All';

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

        // Summary totals
        double totalPaid = 0, totalPending = 0, totalOverdue = 0;
        int paidCount = 0, pendingCount = 0, overdueCount = 0,
            verifyingCount = 0;

        for (final doc in allDocs) {
          final data = doc.data() as Map<String, dynamic>;
          final amount = (data['amount'] as num?)?.toDouble() ?? 0;
          final status = data['status'] as String? ?? 'pending';
          switch (status) {
            case 'paid':
              totalPaid += amount;
              paidCount++;
              break;
            case 'pending_verification':
              totalPending += amount;
              verifyingCount++;
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

        // Filter
        final filtered = _filter == 'All'
            ? allDocs
            : allDocs.where((d) {
                final data = d.data() as Map<String, dynamic>;
                final status = data['status'] as String? ?? '';
                if (_filter == 'Unpaid') {
                  return status == 'pending' || status == 'overdue';
                }
                if (_filter == 'Verifying') {
                  return status == 'pending_verification';
                }
                if (_filter == 'Paid') return status == 'paid';
                return true;
              }).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Summary hero ──────────────────────────────────
            _SummaryHero(
              totalPaid: totalPaid,
              totalPending: totalPending,
              totalOverdue: totalOverdue,
              paidCount: paidCount,
              pendingCount: pendingCount,
              overdueCount: overdueCount,
              verifyingCount: verifyingCount,
            ),
            const SizedBox(height: 20),

            // ── Overdue alert ─────────────────────────────────
            if (overdueCount > 0) ...[
              Container(
                padding: const EdgeInsets.all(14),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.danger.withOpacity(0.07),
                  borderRadius: BorderRadius.circular(14),
                  border:
                      Border.all(color: AppColors.danger.withOpacity(0.35)),
                ),
                child: Row(children: [
                  const Icon(Icons.warning_amber_rounded,
                      color: AppColors.danger, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '$overdueCount overdue fee${overdueCount == 1 ? '' : 's'} '
                      'totalling Rs. ${NumberFormat('#,##0').format(totalOverdue)}. '
                      'Please pay immediately.',
                      style: AppTextStyles.labelSmall
                          .copyWith(color: AppColors.danger),
                    ),
                  ),
                ]),
              ),
            ],

            // ── Filter chips ──────────────────────────────────
            SizedBox(
              height: 34,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: ['All', 'Unpaid', 'Verifying', 'Paid'].map((s) {
                  final isSel = _filter == s;
                  final color = _filterColor(s);
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
                        s,
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

            // ── Fee list ──────────────────────────────────────
            if (filtered.isEmpty)
              Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: AppColors.cardBg,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: AppColors.cardShadow,
                ),
                child: Column(children: [
                  const Icon(Icons.receipt_long_outlined,
                      size: 48, color: AppColors.textHint),
                  const SizedBox(height: 12),
                  Text(
                    _filter == 'All'
                        ? 'No fee records yet.'
                        : 'No $_filter fees.',
                    style: AppTextStyles.bodyMedium
                        .copyWith(color: AppColors.textSecondary),
                  ),
                ]),
              )
            else
              ...filtered.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return _FeeCard(
                  docId: doc.id,
                  data: data,
                  studentName: widget.studentName,
                  parentUid: widget.parentUid,
                );
              }),

            const SizedBox(height: 20),

            // ── Add fee record (parent can also add) ──────────
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _showAddFeeSheet(context),
                icon: const Icon(Icons.add_rounded, color: AppColors.warning),
                label: Text('Add Fee Record',
                    style: AppTextStyles.bodyMediumBold
                        .copyWith(color: AppColors.warning)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(color: AppColors.warning, width: 1.5),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // ── Info note ─────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.info.withOpacity(0.07),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.info.withOpacity(0.25)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline_rounded,
                      color: AppColors.info, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'After submitting your payment proof, the admin will '
                      'verify and mark it as paid. Keep your transaction ID '
                      'safe until verification is complete.',
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

  Color _filterColor(String filter) {
    switch (filter) {
      case 'Unpaid':
        return AppColors.warning;
      case 'Verifying':
        return AppColors.info;
      case 'Paid':
        return AppColors.success;
      default:
        return AppColors.textSecondary;
    }
  }

  void _showAddFeeSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardBg,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _AddFeeSheet(
        studentId: widget.studentId,
        studentName: widget.studentName,
        className: widget.className,
        parentUid: widget.parentUid,
      ),
    );
  }
}

// ── Summary hero ──────────────────────────────────────────────────────────────

class _SummaryHero extends StatelessWidget {
  final double totalPaid, totalPending, totalOverdue;
  final int paidCount, pendingCount, overdueCount, verifyingCount;

  const _SummaryHero({
    required this.totalPaid,
    required this.totalPending,
    required this.totalOverdue,
    required this.paidCount,
    required this.pendingCount,
    required this.overdueCount,
    required this.verifyingCount,
  });

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##0');
    return Column(children: [
      // Hero paid card
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
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Total Paid',
              style:
                  AppTextStyles.labelMedium.copyWith(color: Colors.white70)),
          const SizedBox(height: 8),
          Text('Rs. ${fmt.format(totalPaid)}',
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              )),
          const SizedBox(height: 4),
          Text('$paidCount payment${paidCount == 1 ? '' : 's'} verified',
              style:
                  AppTextStyles.labelSmall.copyWith(color: Colors.white70)),
        ]),
      ),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(
          child: _MiniStat(
            label: 'Pending',
            amount: totalPending,
            count: pendingCount + verifyingCount,
            color: AppColors.warning,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _MiniStat(
            label: 'Overdue',
            amount: totalOverdue,
            count: overdueCount,
            color: AppColors.danger,
          ),
        ),
        if (verifyingCount > 0) ...[
          const SizedBox(width: 12),
          Expanded(
            child: _MiniStat(
              label: 'Verifying',
              amount: 0,
              count: verifyingCount,
              color: AppColors.info,
              showAmount: false,
            ),
          ),
        ],
      ]),
    ]);
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final double amount;
  final int count;
  final Color color;
  final bool showAmount;

  const _MiniStat({
    required this.label,
    required this.amount,
    required this.count,
    required this.color,
    this.showAmount = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(14),
          boxShadow: AppColors.cardShadow),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label,
            style: AppTextStyles.labelSmall.copyWith(color: color)),
        const SizedBox(height: 6),
        if (showAmount)
          Text(
            'Rs. ${NumberFormat('#,##0').format(amount)}',
            style: AppTextStyles.bodyMediumBold,
          ),
        Text('$count record${count == 1 ? '' : 's'}',
            style: AppTextStyles.labelTiny),
      ]),
    );
  }
}

// ── Fee card ──────────────────────────────────────────────────────────────────

class _FeeCard extends StatelessWidget {
  final String docId;
  final Map<String, dynamic> data;
  final String studentName;
  final String parentUid;

  const _FeeCard({
    required this.docId,
    required this.data,
    required this.studentName,
    required this.parentUid,
  });

  @override
  Widget build(BuildContext context) {
    final status = data['status'] as String? ?? 'pending';
    final color = _statusColor(status);
    final amount = (data['amount'] as num?)?.toDouble() ?? 0;
    final feeType = data['feeType'] as String? ?? 'Tuition';
    final month = data['month'] as String? ?? '';
    final year = data['year'] as int? ?? DateTime.now().year;
    final dueDate = (data['dueDate'] as Timestamp?)?.toDate();
    final proof = data['paymentProof'] as Map<String, dynamic>?;
    final isVerifying = status == 'pending_verification';
    final isPaid = status == 'paid';
    final canPay = status == 'pending' || status == 'overdue';

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
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Header row
          Row(children: [
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(feeType,
                  style: AppTextStyles.labelTiny
                      .copyWith(color: color, fontWeight: FontWeight.w700)),
            ),
            const Spacer(),
            _StatusBadge(status: status),
          ]),
          const SizedBox(height: 12),

          // Amount + details row
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Rs. ${NumberFormat('#,##0').format(amount)}',
                        style: AppTextStyles.headingMedium.copyWith(
                          color: isPaid
                              ? AppColors.success
                              : AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (month.isNotEmpty)
                        Text('$month $year',
                            style: AppTextStyles.labelSmall),
                      if (dueDate != null && !isPaid) ...[
                        const SizedBox(height: 2),
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
                    ]),
              ),
            ],
          ),

          // Payment proof summary (if submitted)
          if (isVerifying && proof != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.info.withOpacity(0.07),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.info.withOpacity(0.3)),
              ),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      const Icon(Icons.pending_rounded,
                          size: 14, color: AppColors.info),
                      const SizedBox(width: 6),
                      Text('Payment submitted — awaiting admin verification',
                          style: AppTextStyles.labelTiny.copyWith(
                              color: AppColors.info,
                              fontWeight: FontWeight.w600)),
                    ]),
                    const SizedBox(height: 8),
                    _ProofDetail(
                        label: 'Transaction ID',
                        value: proof['transactionId'] as String? ?? '—'),
                    _ProofDetail(
                        label: 'Amount Paid',
                        value:
                            'Rs. ${NumberFormat('#,##0').format((proof['paidAmount'] as num?)?.toDouble() ?? 0)}'),
                    _ProofDetail(
                        label: 'Payment Date',
                        value: proof['paymentDate'] as String? ?? '—'),
                    if ((proof['notes'] as String? ?? '').isNotEmpty)
                      _ProofDetail(
                          label: 'Notes',
                          value: proof['notes'] as String),
                  ]),
            ),
          ],

          if (isPaid) ...[
            const SizedBox(height: 10),
            Row(children: [
              const Icon(Icons.check_circle_rounded,
                  size: 14, color: AppColors.success),
              const SizedBox(width: 6),
              Text('Payment verified by admin',
                  style: AppTextStyles.labelTiny
                      .copyWith(color: AppColors.success)),
            ]),
          ],

          // Pay now button
          if (canPay) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _showPaymentSheet(context),
                icon:
                    const Icon(Icons.payment_rounded, size: 18),
                label: const Text('Submit Payment Proof'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  textStyle: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ]),
      ),
    );
  }

  void _showPaymentSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardBg,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _PaymentProofSheet(
        docId: docId,
        feeAmount: (data['amount'] as num?)?.toDouble() ?? 0,
        feeType: data['feeType'] as String? ?? 'Tuition',
        studentName: studentName,
        parentUid: parentUid,
      ),
    );
  }
}

class _ProofDetail extends StatelessWidget {
  final String label, value;
  const _ProofDetail({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(children: [
        Text('$label: ',
            style: AppTextStyles.labelTiny
                .copyWith(color: AppColors.textSecondary)),
        Expanded(
          child: Text(value,
              style: AppTextStyles.labelTiny.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary)),
        ),
      ]),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(status);
    final label = switch (status) {
      'paid' => 'Paid',
      'pending_verification' => 'Verifying',
      'overdue' => 'Overdue',
      _ => 'Pending',
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
          style: AppTextStyles.labelTiny
              .copyWith(color: color, fontWeight: FontWeight.w700)),
    );
  }
}

// ── Payment Proof Sheet ───────────────────────────────────────────────────────

class _PaymentProofSheet extends StatefulWidget {
  final String docId;
  final double feeAmount;
  final String feeType;
  final String studentName;
  final String parentUid;

  const _PaymentProofSheet({
    required this.docId,
    required this.feeAmount,
    required this.feeType,
    required this.studentName,
    required this.parentUid,
  });

  @override
  State<_PaymentProofSheet> createState() => _PaymentProofSheetState();
}

class _PaymentProofSheetState extends State<_PaymentProofSheet> {
  final _txnCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  DateTime? _paymentDate;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _amountCtrl.text = widget.feeAmount.toStringAsFixed(0);
    _paymentDate = DateTime.now();
  }

  @override
  void dispose() {
    _txnCtrl.dispose();
    _amountCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_paymentDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a payment date')),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final paidAmount =
          double.tryParse(_amountCtrl.text.trim()) ?? widget.feeAmount;

      await FirebaseFirestore.instance
          .collection('fees')
          .doc(widget.docId)
          .update({
        'status': 'pending_verification',
        'paymentProof': {
          'transactionId': _txnCtrl.text.trim(),
          'paidAmount': paidAmount,
          'paymentDate': DateFormat('MMM d, yyyy').format(_paymentDate!),
          'paymentDateTimestamp': Timestamp.fromDate(_paymentDate!),
          'notes': _notesCtrl.text.trim(),
          'submittedAt': FieldValue.serverTimestamp(),
          'submittedBy': widget.parentUid,
        },
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // ── Notify all admins ──────────────────────────────────────────────
       try {
    await AppNotifications.onFeePaymentSubmitted(
      studentName: widget.studentName,
      feeType: widget.feeType,
      paidAmount: paidAmount,
      transactionId: _txnCtrl.text.trim(),
      feeDocId: widget.docId,
    );
  } catch (_) { }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
                'Payment proof submitted! Admin will verify shortly.'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error: $e'),
              backgroundColor: AppColors.danger),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: AppColors.divider,
                      borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 20),

              // Header
              Row(children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.warning.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.payment_rounded,
                      color: AppColors.warning, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Submit Payment Proof',
                            style: AppTextStyles.headingMedium),
                        Text('${widget.feeType} — ${widget.studentName}',
                            style: AppTextStyles.labelSmall),
                      ]),
                ),
              ]),
              const SizedBox(height: 20),

              // Transaction ID
              _SheetLabel('Transaction / Reference ID *'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _txnCtrl,
                decoration: _inputDecor('e.g. TXN123456789'),
                validator: (v) => v == null || v.trim().isEmpty
                    ? 'Transaction ID is required'
                    : null,
              ),
              const SizedBox(height: 14),

              // Amount paid
              _SheetLabel('Amount Paid (Rs.) *'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _amountCtrl,
                keyboardType: TextInputType.number,
                decoration: _inputDecor('Amount in PKR'),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Required';
                  if (double.tryParse(v.trim()) == null) {
                    return 'Enter a valid amount';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),

              // Payment date
              _SheetLabel('Payment Date *'),
              const SizedBox(height: 8),
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _paymentDate ?? DateTime.now(),
                    firstDate: DateTime.now()
                        .subtract(const Duration(days: 90)),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) {
                    setState(() => _paymentDate = picked);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 16),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: Row(children: [
                    const Icon(Icons.calendar_today_rounded,
                        color: AppColors.textHint, size: 18),
                    const SizedBox(width: 10),
                    Text(
                      _paymentDate != null
                          ? DateFormat('MMM d, yyyy').format(_paymentDate!)
                          : 'Select payment date',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: _paymentDate != null
                            ? AppColors.textPrimary
                            : AppColors.textHint,
                      ),
                    ),
                  ]),
                ),
              ),
              const SizedBox(height: 14),

              // Notes
              _SheetLabel('Notes (optional)'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _notesCtrl,
                maxLines: 2,
                decoration:
                    _inputDecor('e.g. Paid via Meezan Bank transfer'),
              ),
              const SizedBox(height: 20),

              // Disclaimer
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.07),
                  borderRadius: BorderRadius.circular(10),
                  border:
                      Border.all(color: AppColors.warning.withOpacity(0.3)),
                ),
                child: Row(children: [
                  const Icon(Icons.info_outline_rounded,
                      size: 16, color: AppColors.warning),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Make sure your transaction ID is correct. '
                      'Admin will verify before marking as paid.',
                      style: AppTextStyles.labelTiny.copyWith(
                          color: AppColors.textSecondary),
                    ),
                  ),
                ]),
              ),
              const SizedBox(height: 20),

              // Submit
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.warning,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    textStyle: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  child: _loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Submit Payment Proof'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecor(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: AppTextStyles.labelMedium.copyWith(color: AppColors.textHint),
        filled: true,
        fillColor: AppColors.background,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.warning, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.danger),
        ),
      );
}

class _SheetLabel extends StatelessWidget {
  final String text;
  const _SheetLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: AppColors.textSecondary,
        ),
      );
}

// ── Add Fee Sheet (parent creates a fee record) ───────────────────────────────

class _AddFeeSheet extends StatefulWidget {
  final String studentId;
  final String studentName;
  final String className;
  final String parentUid;

  const _AddFeeSheet({
    required this.studentId,
    required this.studentName,
    required this.className,
    required this.parentUid,
  });

  @override
  State<_AddFeeSheet> createState() => _AddFeeSheetState();
}

class _AddFeeSheetState extends State<_AddFeeSheet> {
  final _amountCtrl = TextEditingController();
  final _typeCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  DateTime? _dueDate;
  bool _loading = false;

  static const _feeTypes = [
    'Tuition Fee',
    'Transport Fee',
    'Exam Fee',
    'Lab Fee',
    'Library Fee',
    'Sports Fee',
    'Other',
  ];

  String? _selectedType;

  @override
  void dispose() {
    _amountCtrl.dispose();
    _typeCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    try {
      final now = DateTime.now();
      await FirebaseFirestore.instance.collection('fees').add({
        'studentId': widget.studentId,
        'studentName': widget.studentName,
        'className': widget.className,
        'feeType': _selectedType ?? _typeCtrl.text.trim(),
        'amount':
            double.tryParse(_amountCtrl.text.trim()) ?? 0,
        'month': DateFormat('MMMM').format(now),
        'year': now.year,
        'status': 'pending',
        'dueDate': _dueDate != null
            ? Timestamp.fromDate(_dueDate!)
            : null,
        'notes': _notesCtrl.text.trim(),
        'createdBy': 'parent',
        'createdByUid': widget.parentUid,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Fee record added.'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: AppColors.divider,
                      borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 20),
              Text('Add Fee Record', style: AppTextStyles.headingMedium),
              Text('For: ${widget.studentName}',
                  style: AppTextStyles.labelSmall),
              const SizedBox(height: 20),

              // Fee type
              _SheetLabel('Fee Type *'),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedType,
                decoration: _addInputDecor('Select fee type'),
                items: _feeTypes
                    .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                    .toList(),
                onChanged: (v) => setState(() => _selectedType = v),
                validator: (v) =>
                    v == null ? 'Please select a fee type' : null,
              ),
              const SizedBox(height: 14),

              // Amount
              _SheetLabel('Amount (Rs.) *'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _amountCtrl,
                keyboardType: TextInputType.number,
                decoration: _addInputDecor('e.g. 5000'),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Required';
                  if (double.tryParse(v.trim()) == null) {
                    return 'Enter a valid amount';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),

              // Due date
              _SheetLabel('Due Date (optional)'),
              const SizedBox(height: 8),
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now()
                        .add(const Duration(days: 7)),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now()
                        .add(const Duration(days: 365)),
                  );
                  if (picked != null) setState(() => _dueDate = picked);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 16),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: Row(children: [
                    const Icon(Icons.calendar_today_rounded,
                        color: AppColors.textHint, size: 18),
                    const SizedBox(width: 10),
                    Text(
                      _dueDate != null
                          ? DateFormat('MMM d, yyyy').format(_dueDate!)
                          : 'Select due date',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: _dueDate != null
                            ? AppColors.textPrimary
                            : AppColors.textHint,
                      ),
                    ),
                  ]),
                ),
              ),
              const SizedBox(height: 14),

              // Notes
              _SheetLabel('Notes (optional)'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _notesCtrl,
                maxLines: 2,
                decoration: _addInputDecor('Any additional details'),
              ),
              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.warning,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    textStyle: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  child: _loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Save Fee Record'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _addInputDecor(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: AppTextStyles.labelMedium.copyWith(color: AppColors.textHint),
        filled: true,
        fillColor: AppColors.background,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.warning, width: 2),
        ),
      );
}

// ── Helpers ───────────────────────────────────────────────────────────────────

Color _statusColor(String status) {
  switch (status) {
    case 'paid':
      return AppColors.success;
    case 'pending_verification':
      return AppColors.info;
    case 'overdue':
      return AppColors.danger;
    default:
      return AppColors.warning;
  }
}