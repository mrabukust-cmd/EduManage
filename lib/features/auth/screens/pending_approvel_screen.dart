import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:school_management_system/core/theme/app_colors.dart';
import 'package:school_management_system/core/theme/app_text_style.dart';
import 'package:school_management_system/core/widgets/custom_button.dart';
import 'package:school_management_system/data/repositories/auth_repository.dart';

/// Admin screen: review every pending student / teacher / parent
/// registration, approve or reject it, and — for parents — pick which
/// student(s) they should be linked to before approving.
class PendingApprovalsScreen extends StatefulWidget {
  const PendingApprovalsScreen({super.key});

  @override
  State<PendingApprovalsScreen> createState() => _PendingApprovalsScreenState();
}

class _PendingApprovalsScreenState extends State<PendingApprovalsScreen> {
  final _repo = AuthRepository.instance;
  String _roleFilter = 'all'; // all | student | teacher | parent

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
        title: Text('Pending Approvals',
            style: AppTextStyles.headingMedium.copyWith(color: Colors.white)),
      ),
      body: Column(
        children: [
          // ── Role filter chips ────────────────────────────────
          Container(
            color: AppColors.adminColor,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: SizedBox(
              height: 36,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: ['all', 'student', 'teacher', 'parent'].map((r) {
                  final isSel = _roleFilter == r;
                  return GestureDetector(
                    onTap: () => setState(() => _roleFilter = r),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSel ? Colors.white : Colors.white24,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        r == 'all' ? 'All' : '${r[0].toUpperCase()}${r.substring(1)}s',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: isSel ? AppColors.adminColor : Colors.white,
                          fontWeight: isSel ? FontWeight.w700 : FontWeight.w400,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // ── List ─────────────────────────────────────────────
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _repo.watchPendingUsers(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting && !snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snap.hasError) {
                  return Center(
                    child: Text('Failed to load pending users',
                        style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
                  );
                }

                var users = snap.data ?? [];
                if (_roleFilter != 'all') {
                  users = users.where((u) => u['role'] == _roleFilter).toList();
                }

                if (users.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.task_alt_rounded, size: 64, color: AppColors.textHint),
                        const SizedBox(height: 16),
                        Text('No pending approvals',
                            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: users.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, i) => _PendingUserCard(
                    user: users[i],
                    onApprove: (studentId) async {
                      await _repo.approveUser (
                        users[i]['uid'] as String,
                        studentId: studentId,
                      );
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${users[i]['name'] ?? 'User'} approved'),
                            backgroundColor: AppColors.success,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        );
                      }
                    },
                    onReject: () async {
                      await _repo.rejectUser(users[i]['uid'] as String);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${users[i]['name'] ?? 'User'} rejected'),
                            backgroundColor: AppColors.danger,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        );
                      }
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── Pending user card ─────────────────────────────────────────────────────────
class _PendingUserCard extends StatefulWidget {
  final Map<String, dynamic> user;
  final Future<void> Function(String? studentId) onApprove;
  final Future<void> Function() onReject;

  const _PendingUserCard({
    required this.user,
    required this.onApprove,
    required this.onReject,
  });

  @override
  State<_PendingUserCard> createState() => _PendingUserCardState();
}

class _PendingUserCardState extends State<_PendingUserCard> {
  String? _selectedStudentId;
  bool _loading = false;

  Color _roleColor(String role) {
    switch (role) {
      case 'teacher':
        return AppColors.teacherColor;
      case 'parent':
        return AppColors.accent;
      default:
        return AppColors.studentColor;
    }
  }

  IconData _roleIcon(String role) {
    switch (role) {
      case 'teacher':
        return Icons.cast_for_education_rounded;
      case 'parent':
        return Icons.family_restroom_rounded;
      default:
        return Icons.menu_book_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final role = widget.user['role'] as String? ?? 'student';
    final name = widget.user['name'] as String? ?? 'Unknown';
    final email = widget.user['email'] as String? ?? '';
    final color = _roleColor(role);
    final isParent = role == 'parent';

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
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: color.withOpacity(0.12),
                child: Icon(_roleIcon(role), color: color, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: AppTextStyles.bodyMediumBold),
                    const SizedBox(height: 2),
                    Text(email, style: AppTextStyles.labelSmall),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  role[0].toUpperCase() + role.substring(1),
                  style: AppTextStyles.labelTiny.copyWith(color: color, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),

          // ── Parent-only: pick which student to link ─────────
          if (isParent) ...[
            const SizedBox(height: 14),
            Text('Link to student', style: AppTextStyles.labelSmall.copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: 6),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('students').orderBy('name').snapshots(),
              builder: (context, snap) {
                final docs = snap.data?.docs ?? [];
                if (snap.connectionState == ConnectionState.waiting) {
                  return const SizedBox(
                    height: 44,
                    child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                  );
                }
                if (docs.isEmpty) {
                  return Text('No students available to link yet.',
                      style: AppTextStyles.labelSmall.copyWith(color: AppColors.textHint));
                }
                return DropdownButtonFormField<String>(
                  initialValue: _selectedStudentId,
                  decoration: InputDecoration(
                    hintText: 'Select a student (optional)',
                    filled: true,
                    fillColor: AppColors.background,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.divider),
                    ),
                  ),
                  items: docs.map((d) {
                    final data = d.data() as Map<String, dynamic>;
                    final label = '${data['name'] ?? 'Unknown'} — ${data['class'] ?? '-'}';
                    return DropdownMenuItem(value: d.id, child: Text(label));
                  }).toList(),
                  onChanged: (v) => setState(() => _selectedStudentId = v),
                );
              },
            ),
          ],

          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: CustomOutlineButton(
                  label: 'Reject',
                  borderColor: AppColors.danger,
                  textColor: AppColors.danger,
                  height: 44,
                  onPressed: _loading
                      ? null
                      : () async {
                          setState(() => _loading = true);
                          await widget.onReject();
                          if (mounted) setState(() => _loading = false);
                        },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CustomButton(
                  label: 'Approve',
                  height: 44,
                  isLoading: _loading,
                  backgroundColor: color,
                  onPressed: () async {
                    setState(() => _loading = true);
                    await widget.onApprove(_selectedStudentId);
                    if (mounted) setState(() => _loading = false);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}