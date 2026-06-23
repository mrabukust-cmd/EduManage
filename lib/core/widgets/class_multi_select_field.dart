import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:school_management_system/core/theme/app_colors.dart';

/// Multi-select chip picker that lists every class name currently in the
/// `classes` collection, in place of a free-text "comma separated"
/// field.
///
/// WHY THIS EXISTS: same root cause as `ClassDropdownField` (used for
/// the single-class Student field) — `AddTeacherScreen` previously had a
/// "Assigned Classes (comma separated)" free-text field. An admin typing
/// "Grade 9A, 9B" instead of "9A, Grade 9B" produces a `classes` array on
/// the teacher doc that won't exact-match any `classes` collection name,
/// which silently breaks `TeacherRepository.watchAssignedClassNames` (and
/// therefore the teacher's "Today's Classes" dashboard card, their
/// Attendance class picker, and the Timetable filtered-by-teacher view).
///
/// This widget makes that typo-drift structurally impossible: a teacher
/// can only be assigned classes that already exist verbatim in the
/// `classes` collection.
class ClassMultiSelectField extends StatelessWidget {
  final List<String> selected;
  final ValueChanged<List<String>> onChanged;
  final String label;

  const ClassMultiSelectField({
    super.key,
    required this.selected,
    required this.onChanged,
    this.label = 'Assigned Classes',
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
            .toSet()
            .toList()
          ..sort();

        if (names.isEmpty) {
          return _noClassesYetField();
        }

        // Preserve any already-selected values even if they've since been
        // removed from `classes` (e.g. editing a teacher whose class was
        // deleted) — show them so the admin can see and explicitly
        // deselect, rather than silently losing data.
        final allOptions = List<String>.from(names);
        for (final s in selected) {
          if (!allOptions.contains(s)) allOptions.add(s);
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
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.divider),
              ),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: allOptions.map((c) {
                  final isSelected = selected.contains(c);
                  final stillExists = names.contains(c);
                  return GestureDetector(
                    onTap: () {
                      final next = List<String>.from(selected);
                      if (isSelected) {
                        next.remove(c);
                      } else {
                        next.add(c);
                      }
                      onChanged(next);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.teacherColor
                            : AppColors.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.teacherColor
                              : (stillExists ? AppColors.divider : AppColors.danger.withOpacity(0.4)),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isSelected) ...[
                            const Icon(Icons.check_rounded, size: 14, color: Colors.white),
                            const SizedBox(width: 4),
                          ],
                          if (!stillExists) ...[
                            Icon(Icons.error_outline_rounded,
                                size: 14, color: AppColors.danger.withOpacity(0.7)),
                            const SizedBox(width: 4),
                          ],
                          Text(
                            c,
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isSelected
                                  ? Colors.white
                                  : (stillExists
                                      ? AppColors.textPrimary
                                      : AppColors.danger),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            if (selected.isEmpty) ...[
              const SizedBox(height: 6),
              Text(
                'No classes selected yet — tap to assign.',
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 11,
                  color: AppColors.textHint,
                ),
              ),
            ],
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
          width: double.infinity,
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

  Widget _noClassesYetField() {
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
          child: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 20),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'No classes exist yet. Create classes in Manage Classes first, '
                  'then assign them to this teacher.',
                  style: TextStyle(
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