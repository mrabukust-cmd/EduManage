import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:school_management_system/core/theme/app_colors.dart';
import 'package:school_management_system/core/theme/app_text_style.dart';
import 'package:school_management_system/core/widgets/custom_button.dart';
import 'package:school_management_system/core/widgets/custom_text_field.dart';
import 'package:school_management_system/core/constants/app_subjects.dart';

class TimetableScreen extends StatefulWidget {
  const TimetableScreen({super.key});

  @override
  State<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends State<TimetableScreen> {
  String _selectedClass = '';
  String _selectedDay = 'Monday';
  final _days = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Timetable',
          style: AppTextStyles.headingMedium.copyWith(color: Colors.white),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddSlotSheet(context),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Add Slot',
          style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600),
        ),
      ),
      body: Column(
        children: [
          // ── Class filter ──────────────────────────────────────────────
          Container(
            color: AppColors.primary,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('classes')
                  .orderBy('name')
                  .snapshots(),
              builder: (context, snap) {
                final names = snap.hasData
                    ? snap.data!.docs
                          .map(
                            (d) =>
                                (d.data() as Map<String, dynamic>)['name']
                                    as String? ??
                                '',
                          )
                          .where((n) => n.isNotEmpty)
                          .toSet()
                          .toList()
                    : <String>[];
                if (names.isNotEmpty && _selectedClass.isEmpty) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) setState(() => _selectedClass = names.first);
                  });
                }
                return SizedBox(
                  height: 36,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: names.map((c) {
                      final isSel = _selectedClass == c;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedClass = c),
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
                            c,
                            style: AppTextStyles.labelSmall.copyWith(
                              color: isSel ? AppColors.primary : Colors.white,
                              fontWeight: isSel
                                  ? FontWeight.w700
                                  : FontWeight.w400,
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

          // ── Day tabs ──────────────────────────────────────────────────
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: _days.map((d) {
                final isSel = _selectedDay == d;
                return GestureDetector(
                  onTap: () => setState(() => _selectedDay = d),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: isSel ? AppColors.primary : AppColors.background,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSel ? AppColors.primary : AppColors.divider,
                      ),
                    ),
                    child: Text(
                      d,
                      style: AppTextStyles.labelSmall.copyWith(
                        color: isSel ? Colors.white : AppColors.textSecondary,
                        fontWeight: isSel ? FontWeight.w700 : FontWeight.w400,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // ── Slots list ────────────────────────────────────────────────
          Expanded(
            child: _selectedClass.isEmpty
                ? const SizedBox.shrink()
                : StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('timetable')
                        .where('className', isEqualTo: _selectedClass)
                        .where('day', isEqualTo: _selectedDay)
                        .orderBy('startTime')
                        .snapshots(),
                    builder: (context, snap) {
                      if (snap.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (!snap.hasData || snap.data!.docs.isEmpty) {
                        return Center(
                          child: Text(
                            'No classes on $_selectedDay for $_selectedClass.',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.textSecondary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        );
                      }
                      return ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                        itemCount: snap.data!.docs.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, i) {
                          final data =
                              snap.data!.docs[i].data() as Map<String, dynamic>;
                          return _SlotCard(
                            docId: snap.data!.docs[i].id,
                            subject: data['subject'] ?? '',
                            teacher: data['teacherName'] ?? '',
                            room: data['room'] ?? '',
                            start: data['startTime'] ?? '',
                            end: data['endTime'] ?? '',
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

  void _showAddSlotSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) => _AddSlotSheet(
        selectedClass: _selectedClass,
        selectedDay: _selectedDay,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Add Slot bottom sheet — extracted to its own StatefulWidget so we can
// use setState freely without the outer screen's StatefulBuilder pattern.
// ─────────────────────────────────────────────────────────────────────────────
class _AddSlotSheet extends StatefulWidget {
  final String selectedClass;
  final String selectedDay;

  const _AddSlotSheet({required this.selectedClass, required this.selectedDay});

  @override
  State<_AddSlotSheet> createState() => _AddSlotSheetState();
}

class _AddSlotSheetState extends State<_AddSlotSheet> {
  final _formKey = GlobalKey<FormState>();
  final _roomCtrl = TextEditingController();
  final _startCtrl = TextEditingController();
  final _endCtrl = TextEditingController();

  String? _selectedSubject;
  String? _selectedTeacherName;
  bool _loading = false;

  /// Teachers fetched from Firestore that teach [_selectedSubject].
  List<Map<String, dynamic>> _matchingTeachers = [];
  bool _loadingTeachers = false;

  @override
  void dispose() {
    _roomCtrl.dispose();
    _startCtrl.dispose();
    _endCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadTeachersForSubject(String subject) async {
    setState(() {
      _loadingTeachers = true;
      _selectedTeacherName = null;
      _matchingTeachers = [];
    });

    try {
      // Query teachers by `subjects` array field (new format)
      var snap = await FirebaseFirestore.instance
          .collection('teachers')
          .where('subjects', arrayContains: subject)
          .get();

      // Fallback: legacy single `subject` string field
      if (snap.docs.isEmpty) {
        snap = await FirebaseFirestore.instance
            .collection('teachers')
            .where('subject', isEqualTo: subject)
            .get();
      }

      final teachers = snap.docs
          .map(
            (d) => {
              'uid': d.id,
              'name': (d.data()['name'] as String?) ?? 'Unknown',
            },
          )
          .toList();

      setState(() {
        _matchingTeachers = teachers;
        _loadingTeachers = false;
      });
    } catch (_) {
      setState(() => _loadingTeachers = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedSubject == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a subject.'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    setState(() => _loading = true);

    await FirebaseFirestore.instance.collection('timetable').add({
      'className': widget.selectedClass,
      'day': widget.selectedDay,
      'subject': _selectedSubject,
      'teacherName': _selectedTeacherName ?? '',
      'startTime': _startCtrl.text.trim(),
      'endTime': _endCtrl.text.trim(),
      'room': _roomCtrl.text.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    });

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    // Subject list depends on which class is selected
    final subjects = AppSubjects.subjectsForClassName(widget.selectedClass);

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
              // ── Handle ──────────────────────────────────────────────
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
              Text('Add Time Slot', style: AppTextStyles.headingMedium),
              Text(
                '${widget.selectedClass} · ${widget.selectedDay}',
                style: AppTextStyles.labelMedium,
              ),
              const SizedBox(height: 16),

              // ── Subject dropdown ─────────────────────────────────────
              _SheetLabel('Subject'),
              const SizedBox(height: 8),
              _StyledDropdown<String>(
                hint: 'Select subject',
                value: _selectedSubject,
                items: subjects
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (v) {
                  setState(() => _selectedSubject = v);
                  if (v != null) _loadTeachersForSubject(v);
                },
                validator: (v) => v == null ? 'Please select a subject' : null,
              ),
              const SizedBox(height: 12),

              // ── Teacher dropdown (loaded from Firestore) ─────────────
              _SheetLabel('Teacher'),
              const SizedBox(height: 8),
              if (_selectedSubject == null)
                _DisabledDropdownHint('Select a subject first')
              else if (_loadingTeachers)
                _LoadingDropdownIndicator()
              else if (_matchingTeachers.isEmpty)
                _NoTeachersHint(subject: _selectedSubject!)
              else
                _StyledDropdown<String>(
                  hint: 'Select teacher',
                  value: _selectedTeacherName,
                  items: _matchingTeachers
                      .map(
                        (t) => DropdownMenuItem(
                          value: t['name'] as String,
                          child: Text(t['name'] as String),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setState(() => _selectedTeacherName = v),
                ),
              const SizedBox(height: 12),

              // ── Start / End time ─────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      label: 'Start time',
                      hint: '08:00',
                      controller: _startCtrl,
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: CustomTextField(
                      label: 'End time',
                      hint: '09:00',
                      controller: _endCtrl,
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Required' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // ── Room ─────────────────────────────────────────────────
              CustomTextField(
                label: 'Room',
                hint: 'Room 101',
                controller: _roomCtrl,
              ),
              const SizedBox(height: 20),

              CustomButton(
                label: 'Save Slot',
                isLoading: _loading,
                gradient: AppColors.primaryGradient,
                onPressed: _save,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Small helpers used only inside the bottom sheet
// ─────────────────────────────────────────────────────────────────────────────

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

/// A styled dropdown container matching the app's text-field look.
class _StyledDropdown<T> extends StatelessWidget {
  final T? value;
  final String hint;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;
  final String? Function(T?)? validator;

  const _StyledDropdown({
    required this.value,
    required this.hint,
    required this.items,
    required this.onChanged,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      value: value,
      decoration: InputDecoration(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        filled: true,
        fillColor: AppColors.background,
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
          borderSide: BorderSide(color: AppColors.primary, width: 1.5),
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
      icon: const Icon(
        Icons.keyboard_arrow_down_rounded,
        color: AppColors.textSecondary,
      ),
      borderRadius: BorderRadius.circular(14),
      items: items,
      onChanged: onChanged,
      validator: validator,
    );
  }
}

class _DisabledDropdownHint extends StatelessWidget {
  final String message;
  const _DisabledDropdownHint(this.message);

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppColors.divider),
    ),
    child: Text(
      message,
      style: const TextStyle(
        fontFamily: 'Poppins',
        fontSize: 14,
        color: AppColors.textHint,
      ),
    ),
  );
}

class _LoadingDropdownIndicator extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    height: 50,
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppColors.divider),
    ),
    alignment: Alignment.center,
    child: const SizedBox(
      width: 18,
      height: 18,
      child: CircularProgressIndicator(strokeWidth: 2),
    ),
  );
}

class _NoTeachersHint extends StatelessWidget {
  final String subject;
  const _NoTeachersHint({required this.subject});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: AppColors.warning.withOpacity(0.08),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppColors.warning.withOpacity(0.3)),
    ),
    child: Row(
      children: [
        const Icon(
          Icons.warning_amber_rounded,
          color: AppColors.warning,
          size: 18,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'No teachers assigned to $subject yet. '
            'Add teachers with this subject first.',
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Slot card (unchanged)
// ─────────────────────────────────────────────────────────────────────────────
class _SlotCard extends StatelessWidget {
  final String docId, subject, teacher, room, start, end;
  const _SlotCard({
    required this.docId,
    required this.subject,
    required this.teacher,
    required this.room,
    required this.start,
    required this.end,
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                Text(
                  start,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text('–', style: AppTextStyles.labelTiny),
                Text(
                  end,
                  style: AppTextStyles.labelTiny.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(subject, style: AppTextStyles.bodyMediumBold),
                const SizedBox(height: 3),
                Text('$teacher · $room', style: AppTextStyles.labelSmall),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.delete_outline_rounded,
              color: AppColors.danger,
              size: 20,
            ),
            onPressed: () => FirebaseFirestore.instance
                .collection('timetable')
                .doc(docId)
                .delete(),
          ),
        ],
      ),
    );
  }
}
