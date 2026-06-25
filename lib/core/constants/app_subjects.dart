/// Centralized subject + qualification constants.
///
/// WHY THIS EXISTS: both the "Add Teacher" screen and the Timetable
/// "Add Period" sheet previously had free-text Subject fields. Free text
/// let an admin type "Math" in one place and "Maths" in another, which
/// silently breaks any screen that matches subjects exactly (e.g. the
/// Timetable teacher-by-subject lookup added alongside this file, which
/// does `where('subjects', arrayContains: selectedSubject)`).
///
/// This file is the single source of truth for subject names and
/// qualification levels across the app. Add new subjects/levels here —
/// never hardcode a subject/qualification string a second time elsewhere.
class AppSubjects {
  AppSubjects._();

  // ── Subjects taught at Nursery / KG only ────────────────────────────
  static const List<String> earlyLevels = ['Nursery', 'KG'];

  static const List<String> earlyLevelSubjects = [
    'English',
    'Urdu',
    'Maths',
  ];

  // ── Subjects taught from Grade 1 through Grade 12 ───────────────────
  static const List<String> gradeLevelSubjects = [
    'English',
    'Urdu',
    'Maths',
    'Islamiyat',
    'Pakistan Studies',
    'Physics',
    'Biology',
    'Chemistry',
    'Computer Science',
  ];

  /// Every distinct subject in the school, regardless of level — used by
  /// the Add Teacher screen, where a teacher's subject expertise isn't
  /// tied to one specific class level.
  static List<String> get allSubjects {
    final set = <String>{...earlyLevelSubjects, ...gradeLevelSubjects};
    return set.toList()..sort();
  }

  /// Returns the correct subject list for a given class/level name, e.g.
  /// "Nursery - A" or "Grade 9 - A" (see ClassSeederScreen for the exact
  /// naming format). Falls back to [gradeLevelSubjects] for any class
  /// name that doesn't start with a recognised early-level prefix, so an
  /// admin is never blocked by an unrecognised/custom class name.
  static List<String> subjectsForClassName(String? className) {
    if (className == null || className.trim().isEmpty) {
      return gradeLevelSubjects;
    }
    final normalized = className.trim().toLowerCase();
    for (final level in earlyLevels) {
      if (normalized.startsWith(level.toLowerCase())) {
        return earlyLevelSubjects;
      }
    }
    return gradeLevelSubjects;
  }
}

/// Teacher qualification levels — replaces the old free-text
/// Qualification field on Add Teacher.
class AppQualifications {
  AppQualifications._();

  static const List<String> all = ['BS', 'MS', 'MPhil', 'PhD'];
}