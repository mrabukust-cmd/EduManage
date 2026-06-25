import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:school_management_system/core/theme/app_colors.dart';
import 'package:school_management_system/core/theme/app_text_style.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_text_field.dart';
import 'package:school_management_system/features/auth/providers/auth_provider.dart';

class GradesScreen extends ConsumerStatefulWidget {
  const GradesScreen({super.key});

  @override
  ConsumerState<GradesScreen> createState() => _GradesScreenState();
}

class _GradesScreenState extends ConsumerState<GradesScreen> {
  String? _selectedClass;

  @override
  Widget build(BuildContext context) {
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
                                context, docs[i].id, data['name'] ?? '', uid),
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

  void _showAddGradeSheet(
      BuildContext context, String studentId, String studentName, String? teacherId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardBg,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (sheetContext) => _AddGradeSheet(
        studentId: studentId,
        studentName: studentName,
        className: _selectedClass ?? '',
        teacherId: teacherId,
      ),
    );
  }
}

// ── Add Grade Sheet ────────────────────────────────────────────────────────────
class _AddGradeSheet extends StatefulWidget {
  final String studentId;
  final String studentName;
  final String className;
  final String? teacherId;

  const _AddGradeSheet({
    required this.studentId,
    required this.studentName,
    required this.className,
    required this.teacherId,
  });

  @override
  State<_AddGradeSheet> createState() => _AddGradeSheetState();
}

class _AddGradeSheetState extends State<_AddGradeSheet> {
  final _examCtrl = TextEditingController();
  final _marksCtrl = TextEditingController();
  final _totalCtrl = TextEditingController(text: '100');
  final _formKey = GlobalKey<FormState>();

  String? _selectedSubject;
  List<String> _teacherSubjects = [];
  bool _loadingSubjects = true;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadTeacherSubjects();
  }

  @override
  void dispose() {
    _examCtrl.dispose();
    _marksCtrl.dispose();
    _totalCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadTeacherSubjects() async {
    if (widget.teacherId == null) {
      if (mounted) setState(() => _loadingSubjects = false);
      return;
    }
    try {
      final doc = await FirebaseFirestore.instance
          .collection('teachers')
          .doc(widget.teacherId)
          .get();

      if (!doc.exists || !mounted) {
        setState(() => _loadingSubjects = false);
        return;
      }

      final data = doc.data()!;

      // Prefer 'subjects' array, fall back to single 'subject' string
      List<String> subjects = (data['subjects'] as List<dynamic>?)
              ?.map((e) => e.toString().trim())
              .where((s) => s.isNotEmpty)
              .toList() ??
          [];

      if (subjects.isEmpty) {
        final single = (data['subject'] as String? ?? '').trim();
        if (single.isNotEmpty) subjects = [single];
      }
      subjects.sort();

      if (mounted) {
        setState(() {
          _teacherSubjects = subjects;
          _loadingSubjects = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingSubjects = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
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
              Text('Add Grade — ${widget.studentName}',
                  style: AppTextStyles.headingMedium),
              const SizedBox(height: 16),

              // ── Subject dropdown ────────────────────────────────────
              _loadingSubjects
                  ? _LoadingField(label: 'Subject')
                  : _teacherSubjects.isEmpty
                      ? _WarningField(
                          label: 'Subject',
                          message:
                              'No subjects on your profile. Ask admin to update your profile.',
                        )
                      : _SubjectDropdown(
                          value: _selectedSubject,
                          subjects: _teacherSubjects,
                          onChanged: (v) => setState(() => _selectedSubject = v),
                        ),
              const SizedBox(height: 14),

              // ── Exam title ──────────────────────────────────────────
              CustomTextField(
                label: 'Exam Title',
                hint: 'e.g. Mid Term',
                controller: _examCtrl,
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 14),

              // ── Marks ───────────────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      label: 'Marks Obtained',
                      controller: _marksCtrl,
                      keyboardType: TextInputType.number,
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: CustomTextField(
                      label: 'Total Marks',
                      controller: _totalCtrl,
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
                isLoading: _loading,
                gradient: AppColors.primaryGradient,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedSubject == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a subject'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    final marks = double.tryParse(_marksCtrl.text.trim());
    final total = double.tryParse(_totalCtrl.text.trim());
    if (marks == null || total == null || total == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter valid numeric marks')),
      );
      return;
    }

    setState(() => _loading = true);
    await FirebaseFirestore.instance.collection('results').add({
      'studentId': widget.studentId,
      'studentName': widget.studentName,
      'className': widget.className,
      'subject': _selectedSubject,
      'examTitle': _examCtrl.text.trim(),
      'marksObtained': marks,
      'totalMarks': total,
      'percentage': (marks / total) * 100,
      'createdAt': FieldValue.serverTimestamp(),
    });
    if (mounted) Navigator.pop(context);
  }
}

// ── Subject dropdown widget ────────────────────────────────────────────────────
class _SubjectDropdown extends StatelessWidget {
  final String? value;
  final List<String> subjects;
  final ValueChanged<String?> onChanged;

  const _SubjectDropdown({
    required this.value,
    required this.subjects,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Subject',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          decoration: InputDecoration(
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
              borderSide: const BorderSide(color: AppColors.accent, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.danger),
            ),
          ),
          hint: const Text(
            'Select subject',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 14,
              color: AppColors.textHint,
            ),
          ),
          icon: const Icon(Icons.keyboard_arrow_down_rounded,
              color: AppColors.textSecondary),
          borderRadius: BorderRadius.circular(14),
          items: subjects
              .map((s) => DropdownMenuItem(
                    value: s,
                    child: Text(s,
                        style: const TextStyle(
                            fontFamily: 'Poppins', fontSize: 14)),
                  ))
              .toList(),
          onChanged: onChanged,
          validator: (v) => v == null ? 'Please select a subject' : null,
        ),
      ],
    );
  }
}

// ── Shared helper widgets ──────────────────────────────────────────────────────

class _LoadingField extends StatelessWidget {
  final String label;
  const _LoadingField({required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 54,
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.divider),
          ),
          alignment: Alignment.center,
          child: const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ],
    );
  }
}

class _WarningField extends StatelessWidget {
  final String label;
  final String message;
  const _WarningField({required this.label, required this.message});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.warning.withOpacity(0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.warning.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.warning_amber_rounded,
                  color: AppColors.warning, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Student grade row (unchanged) ─────────────────────────────────────────────
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