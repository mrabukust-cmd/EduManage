import 'dart:math';

/// Academic progression trend indication.
enum ProgressionTrend {
  improving,
  declining,
  stable,
  insufficientData,
}

/// Academic risk severity level.
enum AcademicRiskLevel {
  low,
  moderate,
  high,
  critical,
}

/// Evaluates attendance streak and overall consistency metrics.
class AttendanceStreak {
  final int currentStreak;
  final int longestStreak;
  final int totalDays;
  final int presentDays;
  final int absentDays;
  final int lateDays;

  const AttendanceStreak({
    required this.currentStreak,
    required this.longestStreak,
    required this.totalDays,
    required this.presentDays,
    required this.absentDays,
    required this.lateDays,
  });

  /// Overall attendance rate percentage (0.0 to 100.0).
  double get consistencyRate =>
      totalDays == 0 ? 0.0 : (presentDays / totalDays) * 100.0;

  /// Whether attendance falls below warning threshold (typically 75%).
  bool isAtRisk([double threshold = 75.0]) => consistencyRate < threshold;
}

/// Details student grade trajectory over time.
class GradeTrajectory {
  final double averageScore;
  final double standardDeviation;
  final double slope;
  final ProgressionTrend trend;
  final double changeDelta;

  const GradeTrajectory({
    required this.averageScore,
    required this.standardDeviation,
    required this.slope,
    required this.trend,
    required this.changeDelta,
  });
}

/// Academic risk analysis profile.
class AcademicRiskReport {
  final AcademicRiskLevel level;
  final List<String> riskFactors;
  final List<String> recommendedActions;

  const AcademicRiskReport({
    required this.level,
    required this.riskFactors,
    required this.recommendedActions,
  });

  bool get requiresIntervention =>
      level == AcademicRiskLevel.high || level == AcademicRiskLevel.critical;
}

/// Academic intelligence analytics suite for EduManage.
class AcademicAnalytics {
  AcademicAnalytics._();

  /// Calculates attendance streaks and consistency rate from a chronological list of statuses.
  /// Status strings can be: 'present', 'absent', 'late', 'excused'.
  static AttendanceStreak calculateAttendanceStreak(List<String> statuses) {
    if (statuses.isEmpty) {
      return const AttendanceStreak(
        currentStreak: 0,
        longestStreak: 0,
        totalDays: 0,
        presentDays: 0,
        absentDays: 0,
        lateDays: 0,
      );
    }

    int presentCount = 0;
    int absentCount = 0;
    int lateCount = 0;
    int longest = 0;
    int runningStreak = 0;

    for (final status in statuses) {
      final normalized = status.trim().toLowerCase();
      if (normalized == 'present') {
        presentCount++;
        runningStreak++;
        if (runningStreak > longest) longest = runningStreak;
      } else {
        if (normalized == 'absent') {
          absentCount++;
        } else if (normalized == 'late') {
          lateCount++;
        }
        runningStreak = 0;
      }
    }

    // Current streak counts consecutive 'present' from the end backwards
    int current = 0;
    for (int i = statuses.length - 1; i >= 0; i--) {
      if (statuses[i].trim().toLowerCase() == 'present') {
        current++;
      } else {
        break;
      }
    }

    return AttendanceStreak(
      currentStreak: current,
      longestStreak: longest,
      totalDays: statuses.length,
      presentDays: presentCount,
      absentDays: absentCount,
      lateDays: lateCount,
    );
  }

  /// Evaluates grade trajectory across chronologically ordered assessment scores.
  static GradeTrajectory analyzeGradeTrajectory(List<double> scores) {
    if (scores.isEmpty) {
      return const GradeTrajectory(
        averageScore: 0.0,
        standardDeviation: 0.0,
        slope: 0.0,
        trend: ProgressionTrend.insufficientData,
        changeDelta: 0.0,
      );
    }

    final n = scores.length;
    final avg = scores.reduce((a, b) => a + b) / n;

    if (n < 2) {
      return GradeTrajectory(
        averageScore: avg,
        standardDeviation: 0.0,
        slope: 0.0,
        trend: ProgressionTrend.insufficientData,
        changeDelta: 0.0,
      );
    }

    // Standard deviation
    final variance = scores.map((x) => pow(x - avg, 2)).reduce((a, b) => a + b) / n;
    final stdDev = sqrt(variance);

    // Linear regression slope (x = 0, 1, ..., n-1)
    double sumX = 0;
    double sumY = 0;
    double sumXY = 0;
    double sumX2 = 0;

    for (int i = 0; i < n; i++) {
      final x = i.toDouble();
      final y = scores[i];
      sumX += x;
      sumY += y;
      sumXY += x * y;
      sumX2 += x * x;
    }

    final denominator = (n * sumX2 - sumX * sumX);
    final slope = denominator == 0 ? 0.0 : (n * sumXY - sumX * sumY) / denominator;

    // Delta between latest half and earliest half
    final half = n ~/ 2;
    final firstHalfAvg = scores.sublist(0, half).reduce((a, b) => a + b) / half;
    final secondHalfAvg = scores.sublist(n - half).reduce((a, b) => a + b) / half;
    final changeDelta = secondHalfAvg - firstHalfAvg;

    ProgressionTrend trend;
    if (slope > 0.75 || changeDelta > 3.0) {
      trend = ProgressionTrend.improving;
    } else if (slope < -0.75 || changeDelta < -3.0) {
      trend = ProgressionTrend.declining;
    } else {
      trend = ProgressionTrend.stable;
    }

    return GradeTrajectory(
      averageScore: double.parse(avg.toStringAsFixed(2)),
      standardDeviation: double.parse(stdDev.toStringAsFixed(2)),
      slope: double.parse(slope.toStringAsFixed(2)),
      trend: trend,
      changeDelta: double.parse(changeDelta.toStringAsFixed(2)),
    );
  }

  /// Synthesizes attendance, GPA, and assignment submission to evaluate student academic risk.
  static AcademicRiskReport evaluateAcademicRisk({
    required double attendancePercentage,
    required double gpa,
    required int unsubmittedAssignments,
    required ProgressionTrend gradeTrend,
  }) {
    final factors = <String>[];
    final actions = <String>[];
    int score = 0;

    if (attendancePercentage < 70.0) {
      factors.add('Severe attendance deficit (${attendancePercentage.toStringAsFixed(1)}%)');
      actions.add('Schedule mandatory parent-teacher attendance consultation');
      score += 3;
    } else if (attendancePercentage < 80.0) {
      factors.add('Attendance warning (${attendancePercentage.toStringAsFixed(1)}%)');
      actions.add('Send official attendance advisory notification');
      score += 1;
    }

    if (gpa < 2.0) {
      factors.add('Failing GPA ($gpa / 4.0)');
      actions.add('Assign peer tutoring and academic remediation plan');
      score += 3;
    } else if (gpa < 2.5) {
      factors.add('Sub-par GPA ($gpa / 4.0)');
      actions.add('Conduct academic review with class mentor');
      score += 1;
    }

    if (unsubmittedAssignments >= 3) {
      factors.add('Multiple missing assignments ($unsubmittedAssignments pending)');
      actions.add('Issue deadline extension advisory and homework support');
      score += 2;
    }

    if (gradeTrend == ProgressionTrend.declining) {
      factors.add('Consistent downward trajectory in recent assessments');
      actions.add('Review recent exam scripts with subject teachers');
      score += 1;
    }

    AcademicRiskLevel level;
    if (score >= 5) {
      level = AcademicRiskLevel.critical;
    } else if (score >= 3) {
      level = AcademicRiskLevel.high;
    } else if (score >= 1) {
      level = AcademicRiskLevel.moderate;
    } else {
      level = AcademicRiskLevel.low;
    }

    if (actions.isEmpty) {
      actions.add('Student in good academic standing; continue routine monitoring');
    }

    return AcademicRiskReport(
      level: level,
      riskFactors: factors,
      recommendedActions: actions,
    );
  }

  /// Calculates percentile rank (0.0 to 100.0) of a score against class distribution.
  static double computePercentileRank(double score, List<double> classScores) {
    if (classScores.isEmpty) return 100.0;

    int belowCount = 0;
    int equalCount = 0;

    for (final s in classScores) {
      if (s < score) {
        belowCount++;
      } else if (s == score) {
        equalCount++;
      }
    }

    final percentile = ((belowCount + (0.5 * equalCount)) / classScores.length) * 100.0;
    return double.parse(percentile.toStringAsFixed(1));
  }

  /// Bins scores into standardized grade distribution counts.
  static Map<String, int> computeGradeDistribution(List<double> scores) {
    final distribution = <String, int>{
      'A': 0, // 90-100
      'B': 0, // 80-89.9
      'C': 0, // 70-79.9
      'D': 0, // 60-69.9
      'F': 0, // < 60
    };

    for (final s in scores) {
      if (s >= 90.0) {
        distribution['A'] = distribution['A']! + 1;
      } else if (s >= 80.0) {
        distribution['B'] = distribution['B']! + 1;
      } else if (s >= 70.0) {
        distribution['C'] = distribution['C']! + 1;
      } else if (s >= 60.0) {
        distribution['D'] = distribution['D']! + 1;
      } else {
        distribution['F'] = distribution['F']! + 1;
      }
    }

    return distribution;
  }
}
