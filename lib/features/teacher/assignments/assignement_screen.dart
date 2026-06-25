import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:school_management_system/core/theme/app_colors.dart';
import 'package:school_management_system/core/theme/app_text_style.dart';
import 'package:school_management_system/features/auth/providers/auth_provider.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_text_field.dart';

class AssignmentsScreen extends ConsumerStatefulWidget {
  const AssignmentsScreen({super.key});

  @override
  ConsumerState<AssignmentsScreen> createState() => _AssignmentsScreenState();
}

class _AssignmentsScreenState extends ConsumerState<AssignmentsScreen> {
  @override
  Widget build(BuildContext context) {
    final uid = ref.watch(authProvider).user?.uid;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.teacherColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: Text('Assignments',
            style: AppTextStyles.headingMedium.copyWith(color: Colors.white)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddSheet(context, uid),
        backgroundColor: AppColors.teacherColor,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: Text('New Assignment',
            style: AppTextStyles.bodyMediumBold.copyWith(color: Colors.white)),
      ),
      body: uid == null
          ? const Center(child: CircularProgressIndicator())
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('assignments')
                  .where('teacherId', isEqualTo: uid)
                  .orderBy('dueDate')
                  .snapshots(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snap.hasData || snap.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.assignment_outlined,
                            size: 64, color: AppColors.textHint),
                        const SizedBox(height: 16),
                        Text(
                          'No assignments yet.\nTap "New Assignment" to create one.',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.bodyMedium
                              .copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  );
                }

                final docs = snap.data!.docs;
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, i) {
                    final data = docs[i].data() as Map<String, dynamic>;
                    final dueDate = (data['dueDate'] as Timestamp?)?.toDate();
                    final overdue =
                        dueDate != null && dueDate.isBefore(DateTime.now());
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.cardBg,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: AppColors.cardShadow,
                        border: overdue
                            ? Border.all(color: AppColors.danger.withOpacity(0.4))
                            : null,
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.teacherColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.assignment_rounded,
                                color: AppColors.teacherColor),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(data['title'] ?? '',
                                    style: AppTextStyles.bodyMediumBold),
                                const SizedBox(height: 3),
                                Text(
                                  '${data['className'] ?? ''} · ${data['subject'] ?? ''}',
                                  style: AppTextStyles.labelSmall,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  dueDate != null
                                      ? 'Due ${DateFormat('MMM d, yyyy').format(dueDate)}'
                                      : 'No due date',
                                  style: AppTextStyles.labelTiny.copyWith(
                                    color: overdue
                                        ? AppColors.danger
                                        : AppColors.textSecondary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded,
                                color: AppColors.danger),
                            onPressed: () => FirebaseFirestore.instance
                                .collection('assignments')
                                .doc(docs[i].id)
                                .delete(),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
    );
  }

  void _showAddSheet(BuildContext context, String? teacherId) {
    if (teacherId == null) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardBg,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (sheetContext) => _AddAssignmentSheet(teacherId: teacherId),
    );
  }
}

// ── Add Assignment Sheet ───────────────────────────────────────────────────────
//
// Extracted to its own StatefulWidget so we can use setState freely and
// also run async Firestore lookups to populate the class/subject dropdowns.
class _AddAssignmentSheet extends StatefulWidget {
  final String teacherId;
  const _AddAssignmentSheet({required this.teacherId});

  @override
  State<_AddAssignmentSheet> createState() => _AddAssignmentSheetState();
}

class _AddAssignmentSheetState extends State<_AddAssignmentSheet> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  // Dropdown selections
  String? _selectedClass;
  String? _selectedSubject;

  // Data loaded from Firestore
  List<String> _assignedClasses = [];
  List<String> _teacherSubjects = [];
  bool _loadingTeacherData = true;

  DateTime? _dueDate;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadTeacherData();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  /// Loads the teacher's assigned classes and subjects from their Firestore doc.
  Future<void> _loadTeacherData() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('teachers')
          .doc(widget.teacherId)
          .get();

      if (!doc.exists || !mounted) return;

      final data = doc.data()!;

      // Classes: prefer 'classes' array, fall back to classTeacher lookup
      List<String> classes = (data['classes'] as List<dynamic>?)
              ?.map((e) => e.toString().trim())
              .where((s) => s.isNotEmpty)
              .toList() ??
          [];

      if (classes.isEmpty) {
        final name = data['name'] as String? ?? '';
        if (name.isNotEmpty) {
          final classSnap = await FirebaseFirestore.instance
              .collection('classes')
              .where('classTeacher', isEqualTo: name)
              .get();
          classes = classSnap.docs
              .map((d) => (d.data()['name'] as String? ?? '').trim())
              .where((s) => s.isNotEmpty)
              .toList();
        }
      }
      classes.sort();

      // Subjects: prefer 'subjects' array, fall back to single 'subject' string
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
          _assignedClasses = classes;
          _teacherSubjects = subjects;
          _loadingTeacherData = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingTeacherData = false);
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
              Text('New Assignment', style: AppTextStyles.headingMedium),
              const SizedBox(height: 16),

              // ── Title ──────────────────────────────────────────────
              CustomTextField(
                label: 'Title',
                controller: _titleCtrl,
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 14),

              // ── Description ────────────────────────────────────────
              CustomTextField(
                label: 'Description',
                controller: _descCtrl,
                maxLines: 3,
              ),
              const SizedBox(height: 14),

              // ── Class dropdown ─────────────────────────────────────
              _loadingTeacherData
                  ? _LoadingField(label: 'Class')
                  : _assignedClasses.isEmpty
                      ? _WarningField(
                          label: 'Class',
                          message:
                              'No classes assigned yet. Ask admin to assign you to a class.',
                        )
                      : _DropdownField<String>(
                          label: 'Class',
                          hint: 'Select class',
                          value: _selectedClass,
                          items: _assignedClasses
                              .map((c) => DropdownMenuItem(
                                    value: c,
                                    child: Text(c,
                                        style: const TextStyle(
                                            fontFamily: 'Poppins',
                                            fontSize: 14)),
                                  ))
                              .toList(),
                          validator: (v) =>
                              v == null ? 'Please select a class' : null,
                          onChanged: (v) =>
                              setState(() => _selectedClass = v),
                        ),
              const SizedBox(height: 14),

              // ── Subject dropdown ───────────────────────────────────
              _loadingTeacherData
                  ? _LoadingField(label: 'Subject')
                  : _teacherSubjects.isEmpty
                      ? _WarningField(
                          label: 'Subject',
                          message:
                              'No subjects on your profile. Ask admin to update your profile.',
                        )
                      : _DropdownField<String>(
                          label: 'Subject',
                          hint: 'Select subject',
                          value: _selectedSubject,
                          items: _teacherSubjects
                              .map((s) => DropdownMenuItem(
                                    value: s,
                                    child: Text(s,
                                        style: const TextStyle(
                                            fontFamily: 'Poppins',
                                            fontSize: 14)),
                                  ))
                              .toList(),
                          validator: (v) =>
                              v == null ? 'Please select a subject' : null,
                          onChanged: (v) =>
                              setState(() => _selectedSubject = v),
                        ),
              const SizedBox(height: 14),

              // ── Due date picker ────────────────────────────────────
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate:
                        DateTime.now().add(const Duration(days: 7)),
                    firstDate: DateTime.now(),
                    lastDate:
                        DateTime.now().add(const Duration(days: 365)),
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
                  child: Row(
                    children: [
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
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // ── Submit ─────────────────────────────────────────────
              CustomButton(
                label: 'Create Assignment',
                isLoading: _loading,
                gradient: AppColors.teacherGradient,
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
    if (_dueDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a due date')),
      );
      return;
    }
    setState(() => _loading = true);
    await FirebaseFirestore.instance.collection('assignments').add({
      'title': _titleCtrl.text.trim(),
      'description': _descCtrl.text.trim(),
      'className': _selectedClass,
      'subject': _selectedSubject,
      'teacherId': widget.teacherId,
      'dueDate': Timestamp.fromDate(_dueDate!),
      'createdAt': FieldValue.serverTimestamp(),
    });
    if (mounted) Navigator.pop(context);
  }
}

// ── Small helper widgets ───────────────────────────────────────────────────────

/// A styled dropdown that matches the app's text field look.
class _DropdownField<T> extends StatelessWidget {
  final String label;
  final String hint;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;
  final String? Function(T?)? validator;

  const _DropdownField({
    required this.label,
    required this.hint,
    required this.value,
    required this.items,
    required this.onChanged,
    this.validator,
  });

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
        DropdownButtonFormField<T>(
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
              borderSide:
                  const BorderSide(color: AppColors.teacherColor, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.danger),
            ),
          ),
          hint: Text(
            hint,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 14,
              color: AppColors.textHint,
            ),
          ),
          icon: const Icon(Icons.keyboard_arrow_down_rounded,
              color: AppColors.textSecondary),
          borderRadius: BorderRadius.circular(14),
          items: items,
          onChanged: onChanged,
          validator: validator,
        ),
      ],
    );
  }
}

/// Shown while teacher data is loading from Firestore.
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

/// Shown when a teacher has no classes or subjects on their profile.
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