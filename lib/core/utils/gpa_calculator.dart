/// Academic standings based on semester or cumulative GPA.
enum AcademicStanding {
  deansList,
  firstClassHonors,
  goodStanding,
  academicWarning,
  academicProbation,
}

/// Represents an individual course grade entry with credit hours.
class CourseGrade {
  final String subject;
  final double percentage;
  final double creditHours;
  final String? overrideGrade;

  const CourseGrade({
    required this.subject,
    required this.percentage,
    this.creditHours = 3.0,
    this.overrideGrade,
  });

  double get gradePoint => GpaCalculator.percentageToGradePoint(percentage);
  String get letterGrade => overrideGrade ?? GpaCalculator.percentageToLetterGrade(percentage);
  double get qualityPoints => gradePoint * creditHours;
}

/// Represents semester summary with courses and computed metrics.
class SemesterSummary {
  final String semesterId;
  final List<CourseGrade> courses;

  const SemesterSummary({
    required this.semesterId,
    required this.courses,
  });

  double get totalCredits => courses.fold(0.0, (acc, c) => acc + c.creditHours);
  double get totalQualityPoints => courses.fold(0.0, (acc, c) => acc + c.qualityPoints);
  double get gpa => totalCredits <= 0 ? 0.0 : totalQualityPoints / totalCredits;
}

/// Professional GPA, CGPA and Academic Standing evaluation engine.
class GpaCalculator {
  GpaCalculator._();

  /// Converts percentage to 4.0 grading scale point.
  static double percentageToGradePoint(double pct) {
    if (pct >= 90) return 4.0;
    if (pct >= 85) return 3.7;
    if (pct >= 80) return 3.3;
    if (pct >= 75) return 3.0;
    if (pct >= 70) return 2.7;
    if (pct >= 65) return 2.3;
    if (pct >= 60) return 2.0;
    if (pct >= 55) return 1.7;
    if (pct >= 50) return 1.0;
    return 0.0;
  }

  /// Maps percentage to standard academic letter grade.
  static String percentageToLetterGrade(double pct) {
    if (pct >= 90) return 'A+';
    if (pct >= 85) return 'A';
    if (pct >= 80) return 'B+';
    if (pct >= 75) return 'B';
    if (pct >= 70) return 'B-';
    if (pct >= 65) return 'C+';
    if (pct >= 60) return 'C';
    if (pct >= 55) return 'C-';
    if (pct >= 50) return 'D';
    return 'F';
  }

  /// Converts letter grade directly to grade points.
  static double letterGradeToPoint(String grade) {
    switch (grade.toUpperCase().trim()) {
      case 'A+':
        return 4.0;
      case 'A':
        return 3.7;
      case 'B+':
        return 3.3;
      case 'B':
        return 3.0;
      case 'B-':
        return 2.7;
      case 'C+':
        return 2.3;
      case 'C':
        return 2.0;
      case 'C-':
        return 1.7;
      case 'D':
        return 1.0;
      case 'F':
      default:
        return 0.0;
    }
  }

  /// Computes semester GPA from a list of courses.
  static double computeSemesterGPA(List<CourseGrade> courses) {
    if (courses.isEmpty) return 0.0;
    final totalCredits = courses.fold(0.0, (acc, c) => acc + c.creditHours);
    if (totalCredits <= 0) return 0.0;

    final totalQualityPoints = courses.fold(0.0, (acc, c) => acc + c.qualityPoints);
    return double.parse((totalQualityPoints / totalCredits).toStringAsFixed(2));
  }

  /// Computes Cumulative GPA (CGPA) across multiple semester summaries.
  static double computeCGPA(List<SemesterSummary> semesters) {
    if (semesters.isEmpty) return 0.0;
    final totalCredits = semesters.fold(0.0, (acc, s) => acc + s.totalCredits);
    if (totalCredits <= 0) return 0.0;

    final totalQualityPoints = semesters.fold(0.0, (acc, s) => acc + s.totalQualityPoints);
    return double.parse((totalQualityPoints / totalCredits).toStringAsFixed(2));
  }

  /// Evaluates academic standing based on cumulative GPA.
  static AcademicStanding evaluateStanding(double cgpa) {
    if (cgpa >= 3.8) return AcademicStanding.deansList;
    if (cgpa >= 3.5) return AcademicStanding.firstClassHonors;
    if (cgpa >= 2.0) return AcademicStanding.goodStanding;
    if (cgpa >= 1.7) return AcademicStanding.academicWarning;
    return AcademicStanding.academicProbation;
  }

  /// Returns a descriptive feedback label for the given standing.
  static String standingDescription(AcademicStanding standing) {
    switch (standing) {
      case AcademicStanding.deansList:
        return "Dean's Honor Roll (Exceptional Academic Excellence)";
      case AcademicStanding.firstClassHonors:
        return 'First Class Honors (High Academic Achievement)';
      case AcademicStanding.goodStanding:
        return 'Good Academic Standing';
      case AcademicStanding.academicWarning:
        return 'Academic Warning (Performance below threshold)';
      case AcademicStanding.academicProbation:
        return 'Academic Probation (Immediate improvement required)';
    }
  }
}
