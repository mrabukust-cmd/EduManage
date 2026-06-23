import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:school_management_system/core/theme/app_colors.dart';
import 'package:school_management_system/core/theme/app_text_style.dart';

/// One-time admin tool: finds every distinct class-name string actually
/// present across BOTH `students.class` (a single string field) and
/// `teachers.classes` (an array field), groups visually-similar ones,
/// and lets you merge a group onto a single canonical name in one batch
/// write per collection.
///
/// WHY THIS SCREEN EXISTS: free-text class fields previously let admins
/// type "9A" for some students/teachers and "Grade 9A" for others. Both
/// render fine in a list, but every screen that filters by class name
/// (attendance, grades, timetable, teacher dashboards) uses Firestore's
/// exact-match `where`/`arrayContains`, so a class picker built from one
/// spelling silently excludes records saved under a different spelling.
///
/// Run this ONCE after upgrading to the dropdown/multi-select Class
/// fields (see core/widgets/class_dropdown_field.dart and
/// core/widgets/class_multi_select_field.dart) to clean up data created
/// before those fixes existed. Safe to leave installed afterward — it
/// just reports "no mismatches" once there's nothing left to fix.
class ClassNameMergeScreen extends StatefulWidget {
  const ClassNameMergeScreen({super.key});

  @override
  State<ClassNameMergeScreen> createState() => _ClassNameMergeScreenState();
}

enum _Source { student, teacher }

class _ClassNameMergeScreenState extends State<ClassNameMergeScreen> {
  bool _loading = true;
  bool _merging = false;
  String? _error;

  // distinctClassValue -> list of (source, doc) referencing it
  Map<String, List<_Ref>> _studentGroups = {};
  Map<String, List<_Ref>> _teacherGroups = {};

  @override
  void initState() {
    super.initState();
    _scan();
  }

  Future<void> _scan() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final studentSnap = await FirebaseFirestore.instance.collection('students').get();
      final studentGroups = <String, List<_Ref>>{};
      for (final doc in studentSnap.docs) {
        final data = doc.data();
        final raw = (data['class'] as String? ?? '').trim();
        final key = raw.isEmpty ? '(no class set)' : raw;
        studentGroups.putIfAbsent(key, () => []).add(_Ref(doc.reference, doc.id));
      }

      final teacherSnap = await FirebaseFirestore.instance.collection('teachers').get();
      final teacherGroups = <String, List<_Ref>>{};
      for (final doc in teacherSnap.docs) {
        final data = doc.data();
        final list = (data['classes'] as List<dynamic>?)
                ?.map((e) => e.toString().trim())
                .where((s) => s.isNotEmpty)
                .toList() ??
            <String>[];
        for (final raw in list) {
          teacherGroups.putIfAbsent(raw, () => []).add(_Ref(doc.reference, doc.id));
        }
      }

      if (mounted) {
        setState(() {
          _studentGroups = studentGroups;
          _teacherGroups = teacherGroups;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to scan: $e';
          _loading = false;
        });
      }
    }
  }

  String _normalize(String s) => s.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

  Map<String, List<String>> _clustersFor(Map<String, List<_Ref>> groups) {
    final byNormalized = <String, List<String>>{};
    for (final rawValue in groups.keys) {
      if (rawValue == '(no class set)') continue;
      final norm = _normalize(rawValue);
      byNormalized.putIfAbsent(norm, () => []).add(rawValue);
    }
    return {
      for (final entry in byNormalized.entries)
        if (entry.value.length > 1) entry.key: entry.value,
    };
  }

  Future<void> _mergeStudents(List<String> rawValues, String canonical) async {
    setState(() => _merging = true);
    try {
      final batch = FirebaseFirestore.instance.batch();
      int count = 0;
      for (final raw in rawValues) {
        if (raw == canonical) continue;
        for (final ref in _studentGroups[raw] ?? <_Ref>[]) {
          batch.update(ref.docRef, {'class': canonical});
          count++;
        }
      }
      await batch.commit();
      _showResult('Merged $count student record(s) into "$canonical"');
      await _scan();
    } catch (e) {
      _showResult('Merge failed: $e', isError: true);
    } finally {
      if (mounted) setState(() => _merging = false);
    }
  }

  /// Teacher merges are trickier: `classes` is an array, and a teacher
  /// doc might contain BOTH spellings at once (e.g. ["9A", "Grade 9B"]).
  /// We rebuild each affected teacher's array: drop every raw value in
  /// this cluster, add the canonical value once.
  Future<void> _mergeTeachers(List<String> rawValues, String canonical) async {
    setState(() => _merging = true);
    try {
      // Collect every distinct teacher doc touched by any raw value in
      // this cluster, so a teacher referenced by two different raw
      // spellings only gets updated once with the final correct array.
      final affectedDocIds = <String>{};
      for (final raw in rawValues) {
        for (final ref in _teacherGroups[raw] ?? <_Ref>[]) {
          affectedDocIds.add(ref.docId);
        }
      }

      final batch = FirebaseFirestore.instance.batch();
      int teacherCount = 0;
      for (final docId in affectedDocIds) {
        final docRef = FirebaseFirestore.instance.collection('teachers').doc(docId);
        final snap = await docRef.get();
        final data = snap.data();
        if (data == null) continue;
        final current = (data['classes'] as List<dynamic>?)
                ?.map((e) => e.toString().trim())
                .where((s) => s.isNotEmpty)
                .toList() ??
            <String>[];

        final rebuilt = <String>[];
        bool sawClusterValue = false;
        for (final c in current) {
          if (rawValues.contains(c)) {
            sawClusterValue = true;
            continue; // drop old spelling, re-add canonical once below
          }
          rebuilt.add(c);
        }
        if (sawClusterValue) rebuilt.add(canonical);
        rebuilt.sort();

        batch.update(docRef, {'classes': rebuilt});
        teacherCount++;
      }
      await batch.commit();
      _showResult('Updated $teacherCount teacher record(s) to use "$canonical"');
      await _scan();
    } catch (e) {
      _showResult('Merge failed: $e', isError: true);
    } finally {
      if (mounted) setState(() => _merging = false);
    }
  }

  void _showResult(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.danger : AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showMergeDialog(List<String> rawValues, _Source source) {
    String canonical = rawValues.first;
    final groups = source == _Source.student ? _studentGroups : _teacherGroups;
    final noun = source == _Source.student ? 'student' : 'teacher';

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (dialogCtx, setDialog) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Merge class names'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'These look like the same class. Choose the spelling to keep:',
                style: AppTextStyles.labelSmall.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 14),
              ...rawValues.map((v) {
                final refCount = groups[v]?.length ?? 0;
                return RadioListTile<String>(
                  value: v,
                  // ignore: deprecated_member_use
                  groupValue: canonical,
                  contentPadding: EdgeInsets.zero,
                  title: Text(v, style: AppTextStyles.bodyMediumBold),
                  subtitle: Text('$refCount $noun(s)', style: AppTextStyles.labelTiny),
                  onChanged: (v2) => setDialog(() => canonical = v2!),
                );
              }),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              onPressed: () {
                Navigator.pop(dialogCtx);
                if (source == _Source.student) {
                  _mergeStudents(rawValues, canonical);
                } else {
                  _mergeTeachers(rawValues, canonical);
                }
              },
              child: const Text('Merge'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final studentClusters = _clustersFor(_studentGroups);
    final teacherClusters = _clustersFor(_teacherGroups);
    final totalClusters = studentClusters.length + teacherClusters.length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.adminColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: Text('Fix Class Name Mismatches',
            style: AppTextStyles.headingMedium.copyWith(color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: _loading ? null : _scan,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Text(_error!,
                      style: AppTextStyles.bodyMedium.copyWith(color: AppColors.danger)),
                )
              : ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline_rounded, color: AppColors.primary, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Scans every student\'s class value and every teacher\'s assigned '
                              'classes, groups similar-looking spellings (like "9A" and "Grade 9A"), '
                              'and lets you merge them into one. Run this once, then use the Class '
                              'dropdown/picker everywhere going forward so this never happens again.',
                              style: AppTextStyles.labelSmall.copyWith(color: AppColors.textSecondary),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    if (totalClusters == 0) ...[
                      const SizedBox(height: 40),
                      const Icon(Icons.check_circle_outline_rounded,
                          size: 64, color: AppColors.success),
                      const SizedBox(height: 16),
                      Center(
                        child: Text(
                          'No mismatched class names detected.',
                          style: AppTextStyles.bodyMediumBold,
                        ),
                      ),
                    ] else ...[
                      if (studentClusters.isNotEmpty) ...[
                        Text('Student class mismatches (${studentClusters.length})',
                            style: AppTextStyles.sectionTitle),
                        const SizedBox(height: 14),
                        ...studentClusters.entries.map((e) => _ClusterCard(
                              rawValues: e.value,
                              countFor: (v) => _studentGroups[v]?.length ?? 0,
                              countLabel: 'student record(s)',
                              merging: _merging,
                              onMerge: () => _showMergeDialog(e.value, _Source.student),
                            )),
                        const SizedBox(height: 24),
                      ],
                      if (teacherClusters.isNotEmpty) ...[
                        Text('Teacher class mismatches (${teacherClusters.length})',
                            style: AppTextStyles.sectionTitle),
                        const SizedBox(height: 14),
                        ...teacherClusters.entries.map((e) => _ClusterCard(
                              rawValues: e.value,
                              countFor: (v) => _teacherGroups[v]?.length ?? 0,
                              countLabel: 'teacher record(s)',
                              merging: _merging,
                              onMerge: () => _showMergeDialog(e.value, _Source.teacher),
                            )),
                        const SizedBox(height: 24),
                      ],
                    ],

                    const SizedBox(height: 8),
                    Text('All student class values currently in use', style: AppTextStyles.sectionTitle),
                    const SizedBox(height: 12),
                    ..._studentGroups.entries.map((entry) => _ValueRow(
                          label: entry.key,
                          count: entry.value.length,
                          countLabel: 'students',
                        )),

                    const SizedBox(height: 24),
                    Text('All teacher-assigned class values currently in use', style: AppTextStyles.sectionTitle),
                    const SizedBox(height: 12),
                    if (_teacherGroups.isEmpty)
                      Text('No teachers have any classes assigned yet.',
                          style: AppTextStyles.labelSmall.copyWith(color: AppColors.textHint)),
                    ..._teacherGroups.entries.map((entry) => _ValueRow(
                          label: entry.key,
                          count: entry.value.length,
                          countLabel: 'teachers',
                        )),
                    const SizedBox(height: 32),
                  ],
                ),
    );
  }
}

class _Ref {
  final DocumentReference docRef;
  final String docId;
  const _Ref(this.docRef, this.docId);
}

class _ClusterCard extends StatelessWidget {
  final List<String> rawValues;
  final int Function(String) countFor;
  final String countLabel;
  final bool merging;
  final VoidCallback onMerge;

  const _ClusterCard({
    required this.rawValues,
    required this.countFor,
    required this.countLabel,
    required this.merging,
    required this.onMerge,
  });

  @override
  Widget build(BuildContext context) {
    final total = rawValues.fold<int>(0, (sum, v) => sum + countFor(v));
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: rawValues.map((v) {
              final c = countFor(v);
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.warning.withOpacity(0.3)),
                ),
                child: Text('"$v" ($c)',
                    style: AppTextStyles.labelSmall
                        .copyWith(color: AppColors.warning, fontWeight: FontWeight.w600)),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          Text('$total $countLabel total',
              style: AppTextStyles.labelSmall.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: merging ? null : onMerge,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Merge these'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ValueRow extends StatelessWidget {
  final String label;
  final int count;
  final String countLabel;
  const _ValueRow({required this.label, required this.count, required this.countLabel});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(12),
        boxShadow: AppColors.cardShadow,
      ),
      child: Row(
        children: [
          Expanded(child: Text(label, style: AppTextStyles.bodyMediumBold)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.divider,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text('$count $countLabel', style: AppTextStyles.labelTiny),
          ),
        ],
      ),
    );
  }
}