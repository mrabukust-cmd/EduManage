import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:school_management_system/core/theme/app_colors.dart';

/// Dropdown that lists every class name currently in the `classes`
/// collection, in place of a free-text field.
///
/// WHY THIS EXISTS: free-text Class fields on Add/Edit Student screens
/// let admins type "9A", "Grade 9A", "grade 9 a", etc. for what should be
/// the same class. Firestore `where('class', isEqualTo: ...)` is an exact
/// string match, so attendance/grades/timetable screens that filter by
/// class name then silently miss students whose `class` value doesn't
/// match byte-for-byte. This widget makes that typo class of bug
/// structurally impossible going forward: the admin can only pick a
/// name that already exists in `classes`.
///
/// If no classes exist yet, falls back to a plain text field so the
/// admin isn't blocked (e.g. very first class ever created) — but in
/// that case strongly prefer creating the class in Manage Classes first.
class ClassDropdownField extends StatelessWidget {
  final String? value;
  final ValueChanged<String?> onChanged;
  final String label;
  final bool isRequired;

  const ClassDropdownField({
    super.key,
    required this.value,
    required this.onChanged,
    this.label = 'Class',
    this.isRequired = true,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('classes')
          .orderBy('name')
          .snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting && !snap.hasData) {
          return _loadingField();
        }

        final names = (snap.data?.docs ?? [])
            .map((d) => (d.data() as Map<String, dynamic>)['name'] as String? ?? '')
            .where((n) => n.trim().isNotEmpty)
            .toSet() // de-dupe in case classes collection itself has dupes
            .toList()
          ..sort();

        if (names.isEmpty) {
          return _noClassesYetField(context);
        }

        // If the current value isn't in the list (e.g. legacy mismatched
        // data, or editing a student whose class was deleted), show it as
        // an extra disabled-look option so the field doesn't silently
        // clear what the student already has.
        final items = List<String>.from(names);
        if (value != null && value!.isNotEmpty && !items.contains(value)) {
          items.insert(0, value!);
        }

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
            DropdownButtonFormField<String>(
              initialValue: items.contains(value) ? value : null,
              decoration: _decor(),
              hint: Text(
                'Select a class',
                style: const TextStyle(fontFamily: 'Poppins', color: AppColors.textHint, fontSize: 14),
              ),
              items: items
                  .map((c) => DropdownMenuItem(
                        value: c,
                        child: Text(
                          c,
                          style: const TextStyle(fontFamily: 'Poppins', fontSize: 14),
                        ),
                      ))
                  .toList(),
              validator: isRequired
                  ? (v) => v == null || v.isEmpty ? 'Please select a class' : null
                  : null,
              onChanged: onChanged,
            ),
          ],
        );
      },
    );
  }

  Widget _loadingField() {
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

  Widget _noClassesYetField(BuildContext context) {
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
              const Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'No classes exist yet. Create one in Manage Classes first, then come back here.',
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

  InputDecoration _decor() {
    return InputDecoration(
      filled: true,
      fillColor: AppColors.background,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
    );
  }
}