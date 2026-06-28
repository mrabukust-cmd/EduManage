// lib/features/admin/fees/fee_verification_screen.dart
//
// SETUP:
// 1. Add route in app_router.dart under /admin/home:
//      GoRoute(
//        path: 'fee-verification',
//        builder: (_, __) => const FeeVerificationScreen(),
//      ),
//
// 2. Add "Verify Fees" quick action in admin_home_screen.dart _QuickActionsGrid:
//      _QA('Verify Fees', Icons.verified_rounded, AppColors.warning, null),
//    And in _handleAction:
//      'Verify Fees': '/admin/home/fee-verification',
//
// 3. This screen reads fees with status == 'pending_verification'
//    and lets admin approve (→ 'paid') or reject (→ 'pending').

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:school_management_system/core/theme/app_colors.dart';
import 'package:school_management_system/core/theme/app_text_style.dart';
import 'package:school_management_system/data/services/notification_helper.dart';

class FeeVerificationScreen extends StatefulWidget {
  const FeeVerificationScreen({super.key});

  @override
  State<FeeVerificationScreen> createState() => _FeeVerificationScreenState();
}

class _FeeVerificationScreenState extends State<FeeVerificationScreen> {
  String _filter = 'Pending'; // Pending | Verified | Rejected | All

  @override
  Widget build(BuildContext context) {
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
          'Fee Verification',
          style: AppTextStyles.headingMedium.copyWith(color: Colors.white),
        ),
      ),
      body: Column(
        children: [
          // Filter bar
          Container(
            color: AppColors.warning,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: SizedBox(
              height: 36,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: ['Pending', 'Verified', 'Rejected', 'All'].map((s) {
                  final isSel = _filter == s;
                  return GestureDetector(
                    onTap: () => setState(() => _filter = s),
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
                        s,
                        style: AppTextStyles.labelSmall.copyWith(
                          color: isSel ? AppColors.warning : Colors.white,
                          fontWeight: isSel ? FontWeight.w700 : FontWeight.w400,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // Summary stats for pending
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('fees')
                .where('status', isEqualTo: 'pending_verification')
                .snapshots(),
            builder: (context, snap) {
              final count = snap.data?.docs.length ?? 0;
              if (count == 0) return const SizedBox.shrink();
              double total = 0;
              for (final doc in snap.data!.docs) {
                final data = doc.data() as Map<String, dynamic>;
                final proof = data['paymentProof'] as Map<String, dynamic>?;
                total += (proof?['paidAmount'] as num?)?.toDouble() ?? 0;
              }
              return Container(
                margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.info.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.info.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.info.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.pending_rounded,
                        color: AppColors.info,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$count payment${count == 1 ? '' : 's'} awaiting verification',
                            style: AppTextStyles.bodyMediumBold.copyWith(
                              color: AppColors.info,
                            ),
                          ),
                          Text(
                            'Total: Rs. ${NumberFormat('#,##0').format(total)}',
                            style: AppTextStyles.labelSmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          // Fee list
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _buildStream(),
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
                        Icon(
                          _filter == 'Pending'
                              ? Icons.check_circle_outline_rounded
                              : Icons.receipt_long_outlined,
                          size: 64,
                          color: AppColors.textHint,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _filter == 'Pending'
                              ? 'No payments awaiting verification.'
                              : 'No $_filter records found.',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, i) {
                    final data = docs[i].data() as Map<String, dynamic>;
                    return _VerificationCard(
                      docId: docs[i].id,
                      data: data,
                      onApprove: () => _approve(context, docs[i].id, data),
                      onReject: () =>
                          _showRejectDialog(context, docs[i].id, data),
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

  Stream<QuerySnapshot> _buildStream() {
    final col = FirebaseFirestore.instance.collection('fees');
    switch (_filter) {
      case 'Pending':
        return col
            .where('status', isEqualTo: 'pending_verification')
            .orderBy('createdAt', descending: true)
            .snapshots();
      case 'Verified':
        return col
            .where('status', isEqualTo: 'paid')
            .orderBy('paidAt', descending: true)
            .snapshots();
      case 'Rejected':
        return col
            .where('status', isEqualTo: 'rejected')
            .orderBy('rejectedAt', descending: true)
            .snapshots();
      default:
        return col.orderBy('createdAt', descending: true).snapshots();
    }
  }

  Future<void> _approve(
    BuildContext context,
    String docId,
    Map<String, dynamic> data,
  ) async {
    final proof = data['paymentProof'] as Map<String, dynamic>?;
    final paidAmount = (proof?['paidAmount'] as num?)?.toDouble() ?? 0;
    final studentName = data['studentName'] as String? ?? '';
    final feeType = data['feeType'] as String? ?? 'Tuition';

    await FirebaseFirestore.instance.collection('fees').doc(docId).update({
      'status': 'paid',
      'paidAt': FieldValue.serverTimestamp(),
      'verifiedAt': FieldValue.serverTimestamp(),
      'verifiedAmount': paidAmount,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // Notify parent
    try {
      final parentUid = proof?['submittedBy'] as String?;
      if (parentUid != null && parentUid.isNotEmpty) {
        await AppNotifications.onFeePaymentVerified(
          parentUid: parentUid,
          studentName: studentName,
          feeType: feeType,
          paidAmount: paidAmount,
        );
      }
    } catch (_) {}

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '✅ Payment for $studentName verified and marked as Paid.',
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  void _showRejectDialog(
    BuildContext context,
    String docId,
    Map<String, dynamic> data,
  ) {
    final reasonCtrl = TextEditingController();
    final studentName = data['studentName'] as String? ?? '';
    final feeType = data['feeType'] as String? ?? 'Tuition';
    final proof = data['paymentProof'] as Map<String, dynamic>?;
    final parentUid = proof?['submittedBy'] as String?;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Reject Payment?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This will set the fee back to "pending" and notify the parent.',
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: reasonCtrl,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'Reason for rejection (optional)',
                filled: true,
                fillColor: AppColors.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.divider),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.divider),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () async {
              Navigator.pop(context);
              final reason = reasonCtrl.text.trim();

              await FirebaseFirestore.instance
                  .collection('fees')
                  .doc(docId)
                  .update({
                    'status': 'pending',
                    'rejectionReason': reason.isEmpty ? null : reason,
                    'rejectedAt': FieldValue.serverTimestamp(),
                    'paymentProof': FieldValue.delete(),
                    'updatedAt': FieldValue.serverTimestamp(),
                  });

              // Notify parent
              try {
                if (parentUid != null && parentUid.isNotEmpty) {
                  await AppNotifications.onFeePaymentRejected(
                    parentUid: parentUid,
                    studentName: studentName,
                    feeType: feeType,
                    reason: reason.isEmpty ? null : reason,
                  );
                }
              } catch (_) {}

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Payment for $studentName rejected. Parent notified.',
                    ),
                    backgroundColor: AppColors.danger,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                );
              }
            },
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }
}

// ── Verification Card ─────────────────────────────────────────────────────────

class _VerificationCard extends StatelessWidget {
  final String docId;
  final Map<String, dynamic> data;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _VerificationCard({
    required this.docId,
    required this.data,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final status = data['status'] as String? ?? 'pending';
    final studentName = data['studentName'] as String? ?? '';
    final className = data['className'] as String? ?? '';
    final feeType = data['feeType'] as String? ?? 'Tuition';
    final month = data['month'] as String? ?? '';
    final year = data['year'] as int? ?? DateTime.now().year;
    final proof = data['paymentProof'] as Map<String, dynamic>?;
    final txnId = proof?['transactionId'] as String? ?? '—';
    final paidAmount = (proof?['paidAmount'] as num?)?.toDouble() ?? 0;
    final originalAmount = (data['amount'] as num?)?.toDouble() ?? 0;
    final paymentDate = proof?['paymentDate'] as String? ?? '—';
    final notes = proof?['notes'] as String? ?? '';
    final submittedAt = (proof?['submittedAt'] as Timestamp?)?.toDate();
    final isPending = status == 'pending_verification';
    final isPaid = status == 'paid';
    final isRejected = status == 'rejected';

    final Color statusColor = isPaid
        ? AppColors.success
        : isRejected
        ? AppColors.danger
        : AppColors.info;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppColors.cardShadow,
        border: Border(left: BorderSide(color: statusColor, width: 4)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: statusColor.withOpacity(0.12),
                  child: Text(
                    studentName.isNotEmpty ? studentName[0].toUpperCase() : 'S',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w700,
                      color: statusColor,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(studentName, style: AppTextStyles.bodyMediumBold),
                      Text(
                        '$className · $feeType · $month $year',
                        style: AppTextStyles.labelSmall,
                      ),
                    ],
                  ),
                ),
                _StatusBadge(status: status),
              ],
            ),

            const SizedBox(height: 14),
            const Divider(height: 1, color: AppColors.divider),
            const SizedBox(height: 14),

            // Amount comparison
            Row(
              children: [
                Expanded(
                  child: _InfoTile(
                    label: 'Fee Amount',
                    value:
                        'Rs. ${NumberFormat('#,##0').format(originalAmount)}',
                    icon: Icons.receipt_outlined,
                    color: AppColors.textSecondary,
                  ),
                ),
                Container(width: 1, height: 40, color: AppColors.divider),
                Expanded(
                  child: _InfoTile(
                    label: 'Amount Paid',
                    value: 'Rs. ${NumberFormat('#,##0').format(paidAmount)}',
                    icon: Icons.payments_rounded,
                    color: paidAmount >= originalAmount
                        ? AppColors.success
                        : AppColors.warning,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Payment details
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.divider),
              ),
              child: Column(
                children: [
                  _DetailRow(
                    label: 'Transaction ID',
                    value: txnId,
                    isBold: true,
                  ),
                  const SizedBox(height: 6),
                  _DetailRow(label: 'Payment Date', value: paymentDate),
                  if (notes.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    _DetailRow(label: 'Notes', value: notes),
                  ],
                  if (submittedAt != null) ...[
                    const SizedBox(height: 6),
                    _DetailRow(
                      label: 'Submitted',
                      value: DateFormat(
                        'MMM d, yyyy · hh:mm a',
                      ).format(submittedAt),
                    ),
                  ],
                ],
              ),
            ),

            // Amount mismatch warning
            if (paidAmount < originalAmount && isPending) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.warning.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      color: AppColors.warning,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Paid amount is less than fee amount by '
                        'Rs. ${NumberFormat('#,##0').format(originalAmount - paidAmount)}.',
                        style: AppTextStyles.labelTiny.copyWith(
                          color: AppColors.warning,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Action buttons (only for pending)
            if (isPending) ...[
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onReject,
                      icon: const Icon(
                        Icons.close_rounded,
                        size: 16,
                        color: AppColors.danger,
                      ),
                      label: Text(
                        'Reject',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.danger,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.danger),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: onApprove,
                      icon: const Icon(
                        Icons.check_rounded,
                        size: 16,
                        color: Colors.white,
                      ),
                      label: Text(
                        'Approve & Mark Paid',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      'paid' => ('Verified', AppColors.success),
      'rejected' => ('Rejected', AppColors.danger),
      'pending_verification' => ('Pending', AppColors.info),
      _ => ('Unknown', AppColors.textSecondary),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: AppTextStyles.labelTiny.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _InfoTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(label, style: AppTextStyles.labelTiny),
        const SizedBox(height: 2),
        Text(
          value,
          style: AppTextStyles.labelSmall.copyWith(
            color: color,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label, value;
  final bool isBold;
  const _DetailRow({
    required this.label,
    required this.value,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: AppTextStyles.labelTiny.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: AppTextStyles.labelTiny.copyWith(
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}
