import 'package:flutter_test/flutter_test.dart';
import 'package:school_management_system/core/utils/gpa_calculator.dart';

void main() {
  group('GpaCalculator Suite', () {
    test('percentageToGradePoint maps scores across grading intervals', () {
      expect(GpaCalculator.percentageToGradePoint(95), 4.0);
      expect(GpaCalculator.percentageToGradePoint(88), 3.7);
      expect(GpaCalculator.percentageToGradePoint(82), 3.3);
      expect(GpaCalculator.percentageToGradePoint(76), 3.0);
      expect(GpaCalculator.percentageToGradePoint(71), 2.7);
      expect(GpaCalculator.percentageToGradePoint(66), 2.3);
      expect(GpaCalculator.percentageToGradePoint(61), 2.0);
      expect(GpaCalculator.percentageToGradePoint(56), 1.7);
      expect(GpaCalculator.percentageToGradePoint(52), 1.0);
      expect(GpaCalculator.percentageToGradePoint(45), 0.0);
    });

    test('percentageToLetterGrade categorizes correctly', () {
      expect(GpaCalculator.percentageToLetterGrade(92), 'A+');
      expect(GpaCalculator.percentageToLetterGrade(86), 'A');
      expect(GpaCalculator.percentageToLetterGrade(81), 'B+');
      expect(GpaCalculator.percentageToLetterGrade(77), 'B');
      expect(GpaCalculator.percentageToLetterGrade(72), 'B-');
      expect(GpaCalculator.percentageToLetterGrade(67), 'C+');
      expect(GpaCalculator.percentageToLetterGrade(62), 'C');
      expect(GpaCalculator.percentageToLetterGrade(57), 'C-');
      expect(GpaCalculator.percentageToLetterGrade(51), 'D');
      expect(GpaCalculator.percentageToLetterGrade(38), 'F');
    });

    test('computeSemesterGPA computes credit-weighted GPA accurately', () {
      final courses = [
        const CourseGrade(subject: 'Calculus I', percentage: 92, creditHours: 4.0), // 4.0 * 4 = 16.0
        const CourseGrade(subject: 'Physics Mechanics', percentage: 86, creditHours: 3.0), // 3.7 * 3 = 11.1
        const CourseGrade(subject: 'English Comp', percentage: 76, creditHours: 3.0), // 3.0 * 3 = 9.0
      ];
      // Total quality points = 16.0 + 11.1 + 9.0 = 36.1
      // Total credits = 10.0
      // GPA = 36.1 / 10.0 = 3.61
      final gpa = GpaCalculator.computeSemesterGPA(courses);
      expect(gpa, 3.61);
    });

    test('computeCGPA calculates cumulative results across multiple semesters', () {
      final sem1 = SemesterSummary(
        semesterId: 'Fall 2025',
        courses: [
          const CourseGrade(subject: 'Course A', percentage: 90, creditHours: 3.0), // 4.0 * 3 = 12
          const CourseGrade(subject: 'Course B', percentage: 75, creditHours: 3.0), // 3.0 * 3 = 9
        ],
      ); // 21 / 6 = 3.5

      final sem2 = SemesterSummary(
        semesterId: 'Spring 2026',
        courses: [
          const CourseGrade(subject: 'Course C', percentage: 95, creditHours: 4.0), // 4.0 * 4 = 16
          const CourseGrade(subject: 'Course D', percentage: 80, creditHours: 4.0), // 3.3 * 4 = 13.2
        ],
      ); // 29.2 / 8 = 3.65

      // Total quality points = 21 + 29.2 = 50.2
      // Total credits = 14
      // CGPA = 50.2 / 14 = 3.5857... -> 3.59
      final cgpa = GpaCalculator.computeCGPA([sem1, sem2]);
      expect(cgpa, 3.59);
    });

    test('evaluateStanding identifies academic honors and probation', () {
      expect(GpaCalculator.evaluateStanding(3.9), AcademicStanding.deansList);
      expect(GpaCalculator.evaluateStanding(3.6), AcademicStanding.firstClassHonors);
      expect(GpaCalculator.evaluateStanding(2.5), AcademicStanding.goodStanding);
      expect(GpaCalculator.evaluateStanding(1.8), AcademicStanding.academicWarning);
      expect(GpaCalculator.evaluateStanding(1.2), AcademicStanding.academicProbation);

      final label = GpaCalculator.standingDescription(AcademicStanding.deansList);
      expect(label, contains("Dean's"));
    });
  });
}
