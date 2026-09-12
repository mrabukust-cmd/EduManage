import 'package:flutter_test/flutter_test.dart';
import 'package:school_management_system/core/utils/academic_analytics.dart';

void main() {
  group('AcademicAnalytics Suite', () {
    test('calculateAttendanceStreak handles empty and single records', () {
      final empty = AcademicAnalytics.calculateAttendanceStreak([]);
      expect(empty.currentStreak, 0);
      expect(empty.longestStreak, 0);
      expect(empty.consistencyRate, 0.0);
      expect(empty.isAtRisk(), isTrue);

      final single = AcademicAnalytics.calculateAttendanceStreak(['present']);
      expect(single.currentStreak, 1);
      expect(single.longestStreak, 1);
      expect(single.consistencyRate, 100.0);
      expect(single.isAtRisk(), isFalse);
    });

    test('calculateAttendanceStreak calculates streaks and consistency accurately', () {
      final statuses = [
        'present',
        'present',
        'present', // streak 3
        'absent',  // broken
        'present',
        'present',
        'late',    // broken
        'present',
        'present',
        'present',
        'present', // current streak 4
      ];

      final result = AcademicAnalytics.calculateAttendanceStreak(statuses);
      expect(result.totalDays, 11);
      expect(result.presentDays, 9);
      expect(result.absentDays, 1);
      expect(result.lateDays, 1);
      expect(result.longestStreak, 4);
      expect(result.currentStreak, 4);
      expect(result.consistencyRate, closeTo(81.81, 0.05));
      expect(result.isAtRisk(), isFalse);
    });

    test('analyzeGradeTrajectory classifies improving trend', () {
      final scores = [65.0, 70.0, 75.0, 82.0, 88.0, 94.0];
      final trajectory = AcademicAnalytics.analyzeGradeTrajectory(scores);

      expect(trajectory.trend, ProgressionTrend.improving);
      expect(trajectory.slope, greaterThan(0.0));
      expect(trajectory.changeDelta, greaterThan(0.0));
      expect(trajectory.averageScore, closeTo(79.0, 0.5));
    });

    test('analyzeGradeTrajectory classifies declining trend', () {
      final scores = [92.0, 88.0, 80.0, 74.0, 68.0, 60.0];
      final trajectory = AcademicAnalytics.analyzeGradeTrajectory(scores);

      expect(trajectory.trend, ProgressionTrend.declining);
      expect(trajectory.slope, lessThan(0.0));
      expect(trajectory.changeDelta, lessThan(0.0));
    });

    test('analyzeGradeTrajectory classifies stable trend', () {
      final scores = [85.0, 84.0, 86.0, 85.0, 85.0];
      final trajectory = AcademicAnalytics.analyzeGradeTrajectory(scores);

      expect(trajectory.trend, ProgressionTrend.stable);
      expect(trajectory.standardDeviation, lessThan(2.0));
    });

    test('evaluateAcademicRisk identifies low risk for high achievers', () {
      final report = AcademicAnalytics.evaluateAcademicRisk(
        attendancePercentage: 95.0,
        gpa: 3.8,
        unsubmittedAssignments: 0,
        gradeTrend: ProgressionTrend.improving,
      );

      expect(report.level, AcademicRiskLevel.low);
      expect(report.requiresIntervention, isFalse);
      expect(report.riskFactors, isEmpty);
    });

    test('evaluateAcademicRisk triggers critical intervention for severe deficits', () {
      final report = AcademicAnalytics.evaluateAcademicRisk(
        attendancePercentage: 62.0,
        gpa: 1.8,
        unsubmittedAssignments: 4,
        gradeTrend: ProgressionTrend.declining,
      );

      expect(report.level, AcademicRiskLevel.critical);
      expect(report.requiresIntervention, isTrue);
      expect(report.riskFactors.length, greaterThanOrEqualTo(3));
      expect(report.recommendedActions, isNotEmpty);
    });

    test('computePercentileRank calculates correct rank within cohort', () {
      final scores = [50.0, 60.0, 70.0, 80.0, 90.0];

      // Score 70 is exactly in the middle (50th percentile)
      final midRank = AcademicAnalytics.computePercentileRank(70.0, scores);
      expect(midRank, 50.0);

      // Score 95 is higher than all (100th percentile)
      final topRank = AcademicAnalytics.computePercentileRank(95.0, scores);
      expect(topRank, 100.0);

      // Score 40 is lower than all (0th percentile)
      final bottomRank = AcademicAnalytics.computePercentileRank(40.0, scores);
      expect(bottomRank, 0.0);
    });

    test('computeGradeDistribution tallies grades in appropriate buckets', () {
      final scores = [95.0, 91.0, 85.0, 78.0, 72.0, 65.0, 52.0];
      final dist = AcademicAnalytics.computeGradeDistribution(scores);

      expect(dist['A'], 2);
      expect(dist['B'], 1);
      expect(dist['C'], 2);
      expect(dist['D'], 1);
      expect(dist['F'], 1);
    });
  });
}
