import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:school_management_system/core/theme/app_colors.dart';
import 'package:school_management_system/core/theme/app_text_style.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_text_field.dart';

class GradesScreen extends ConsumerStatefulWidget {
  const GradesScreen({super.key});

  @override
  ConsumerState<GradesScreen> createState() => _GradesScreenState();
}

class _GradesScreenState extends ConsumerState<GradesScreen> {
  String? _selectedClass;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.accent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: Text('Grades',
            style: AppTextStyles.headingMedium.copyWith(color: Colors.white)),
      ),
      body: Column(
        children: [
          Container(
            color: AppColors.accent,
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('classes')
                  .orderBy('name')
                  .snapshots(),
              builder: (context, snap) {
                final classNames = snap.hasData
                    ? snap.data!.docs
                        .map((d) =>
                            (d.data() as Map<String, dynamic>)['name'] as String? ?? '')
                        .where((n) => n.isNotEmpty)
                        .toSet()
                        .toList()
                    : <String>[];
                if (classNames.isNotEmpty && _selectedClass == null) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) setState(() => _selectedClass = classNames.first);
                  });
                }

                if (classNames.isEmpty) {
                  return Text(
                    'No classes found. Ask admin to add classes first.',
                    style: AppTextStyles.labelMedium.copyWith(color: Colors.white70),
                  );
                }

                return SizedBox(
                  height: 36,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: classNames.map((c) {
                      final isSel = _selectedClass == c;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedClass = c),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSel ? Colors.white : Colors.white24,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            c,
                            style: AppTextStyles.labelSmall.copyWith(
                              color: isSel ? AppColors.accent : Colors.white,
                              fontWeight: isSel ? FontWeight.w700 : FontWeight.w400,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                );
              },
            ),
          ),
          Expanded(
            child: _selectedClass == null
                ? const SizedBox.shrink()
                : StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('students')
                        .where('class', isEqualTo: _selectedClass)
                        .orderBy('name')
                        .snapshots(),
                    builder: (context, snap) {
                      if (snap.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (!snap.hasData || snap.data!.docs.isEmpty) {
                        return Center(
                          child: Text(
                            'No students in $_selectedClass yet.',
                            style: AppTextStyles.bodyMedium
                                .copyWith(color: AppColors.textSecondary),
                          ),
                        );
                      }

                      final docs = snap.data!.docs;
                      return ListView.separated(
                        padding: const EdgeInsets.all(20),
                        itemCount: docs.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, i) {
                          final data = docs[i].data() as Map<String, dynamic>;
                          return _StudentGradeRow(
                            name: data['name'] ?? '',
                            rollNo: data['rollNo'] ?? '-',
                            onAddGrade: () => _showAddGradeSheet(
                                context, docs[i].id, data['name'] ?? ''),
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

  void _showAddGradeSheet(BuildContext context, String studentId, String studentName) {
    final subjectCtrl = TextEditingController();
    final examCtrl = TextEditingController();
    final marksCtrl = TextEditingController();
    final totalCtrl = TextEditingController(text: '100');
    final formKey = GlobalKey<FormState>();
    bool loading = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardBg,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheetState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 20,
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
                    decoration: BoxDecoration(
                      color: AppColors.divider,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text('Add Grade — $studentName', style: AppTextStyles.headingMedium),
                const SizedBox(height: 16),
                CustomTextField(
                  label: 'Subject',
                  controller: subjectCtrl,
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 14),
                CustomTextField(
                  label: 'Exam Title',
                  hint: 'e.g. Mid Term',
                  controller: examCtrl,
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: CustomTextField(
                        label: 'Marks Obtained',
                        controller: marksCtrl,
                        keyboardType: TextInputType.number,
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? 'Required' : null,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: CustomTextField(
                        label: 'Total Marks',
                        controller: totalCtrl,
                        keyboardType: TextInputType.number,
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? 'Required' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                CustomButton(
                  label: 'Save Grade',
                  isLoading: loading,
                  gradient: AppColors.primaryGradient,
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;
                    final marks = double.tryParse(marksCtrl.text.trim());
                    final total = double.tryParse(totalCtrl.text.trim());
                    if (marks == null || total == null || total == 0) {
                      ScaffoldMessenger.of(sheetContext).showSnackBar(
                        const SnackBar(content: Text('Enter valid numeric marks')),
                      );
                      return;
                    }
                    setSheetState(() => loading = true);
                    await FirebaseFirestore.instance.collection('results').add({
                      'studentId': studentId,
                      'studentName': studentName,
                      'className': _selectedClass,
                      'subject': subjectCtrl.text.trim(),
                      'examTitle': examCtrl.text.trim(),
                      'marksObtained': marks,
                      'totalMarks': total,
                      'percentage': (marks / total) * 100,
                      'createdAt': FieldValue.serverTimestamp(),
                    });
                    if (sheetContext.mounted) Navigator.pop(sheetContext);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StudentGradeRow extends StatelessWidget {
  final String name, rollNo;
  final VoidCallback onAddGrade;
  const _StudentGradeRow({
    required this.name,
    required this.rollNo,
    required this.onAddGrade,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(14),
        boxShadow: AppColors.cardShadow,
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.accent.withOpacity(0.12),
            child: Text(rollNo,
                style: AppTextStyles.labelSmall
                    .copyWith(color: AppColors.accent, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(name, style: AppTextStyles.bodyMediumBold)),
          TextButton.icon(
            onPressed: onAddGrade,
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Grade'),
            style: TextButton.styleFrom(foregroundColor: AppColors.accent),
          ),
        ],
      ),
    );
  }
}