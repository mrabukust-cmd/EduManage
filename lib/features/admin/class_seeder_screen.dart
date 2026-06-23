import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:school_management_system/core/theme/app_colors.dart';
import 'package:school_management_system/core/theme/app_text_style.dart';

/// Admin utility screen: seeds the `classes` collection with every class
/// from Nursery to Grade 12, each with sections A, B and C.
/// Run once after initial setup. Safe to re-run — uses set() with merge
/// so existing docs won't lose classTeacher or student-count data.
class ClassSeederScreen extends StatefulWidget {
  const ClassSeederScreen({super.key});

  @override
  State<ClassSeederScreen> createState() => _ClassSeederScreenState();
}

class _ClassSeederScreenState extends State<ClassSeederScreen> {
  bool _seeding = false;
  bool _done = false;
  String _status = '';
  int _count = 0;

  static const _classLevels = [
    'Nursery',
    'KG',
    'Grade 1',
    'Grade 2',
    'Grade 3',
    'Grade 4',
    'Grade 5',
    'Grade 6',
    'Grade 7',
    'Grade 8',
    'Grade 9',
    'Grade 10',
    'Grade 11',
    'Grade 12',
  ];

  static const _sections = ['A', 'B', 'C'];

  Future<void> _seed() async {
    setState(() {
      _seeding = true;
      _done = false;
      _status = 'Seeding classes...';
      _count = 0;
    });

    try {
      final db = FirebaseFirestore.instance;
      final batch = db.batch();
      int count = 0;

      for (final level in _classLevels) {
        for (final section in _sections) {
          final fullName = '$level - $section';
          // Use a deterministic doc ID so re-running is idempotent
          final docId =
              fullName.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_');
          final ref = db.collection('classes').doc(docId);
          batch.set(
            ref,
            {
              'name': fullName,
              'section': section,
              'classLevel': level,
              'classTeacher': '',
              'createdAt': FieldValue.serverTimestamp(),
            },
            SetOptions(merge: true),
          );
          count++;
        }
      }

      await batch.commit();

      if (mounted) {
        setState(() {
          _seeding = false;
          _done = true;
          _count = count;
          _status =
              'Done! $count class entries created/updated (Nursery → Grade 12, sections A/B/C).';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _seeding = false;
          _status = 'Error: $e';
        });
      }
    }
  }

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
        title: Text(
          'Setup All Classes',
          style: AppTextStyles.headingMedium.copyWith(color: Colors.white),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.info.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.info.withOpacity(0.3)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline_rounded,
                      color: AppColors.info, size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'This will create all classes from Nursery to Grade 12 '
                      'with sections A, B, and C in Firestore.\n\n'
                      'Each class will be named like "Grade 9 - A". '
                      'All other screens (attendance, assignments, results, '
                      'timetable) use this exact name for filtering — '
                      'so consistent naming is critical.\n\n'
                      'Safe to run multiple times.',
                      style: AppTextStyles.labelSmall
                          .copyWith(color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text('Classes that will be created:',
                style: AppTextStyles.sectionTitle),
            const SizedBox(height: 12),
            Expanded(
              child: SingleChildScrollView(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final level in _classLevels)
                      for (final section in _sections)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.adminColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: AppColors.adminColor.withOpacity(0.3)),
                          ),
                          child: Text(
                            '$level - $section',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: AppColors.adminColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            if (_status.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _done
                      ? AppColors.success.withOpacity(0.1)
                      : AppColors.warning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      _done ? Icons.check_circle_outline_rounded : Icons.info_outline_rounded,
                      color: _done ? AppColors.success : AppColors.warning,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(_status,
                          style: AppTextStyles.labelSmall.copyWith(
                            color: _done ? AppColors.success : AppColors.warning,
                          )),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _seeding ? null : _seed,
                icon: _seeding
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.auto_fix_high_rounded),
                label: Text(_seeding
                    ? 'Creating classes...'
                    : _done
                        ? 'Run Again'
                        : 'Create All Classes'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.adminColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  textStyle: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}