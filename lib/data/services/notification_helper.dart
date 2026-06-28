// lib/data/services/notification_helper.dart
//
// ADDITIONS vs previous version:
// 1. onFeePaymentVerified()  — admin approves → notifies parent
// 2. onFeePaymentRejected()  — admin rejects  → notifies parent
// 3. onFeePaymentSubmitted() — parent pays     → notifies ALL admins
//    (was inline in parent_fee_screen.dart — centralised here so the
//     local notification popup fires reliably)
// 4. onAttendanceMarked() unchanged but kept for completeness.
// 5. onGradeRecorded()    unchanged but kept for completeness.
// 6. onNoticePublished()  unchanged but kept for completeness.

import 'package:cloud_firestore/cloud_firestore.dart';

class AppNotifications {
  AppNotifications._();

  static final _db = FirebaseFirestore.instance;

  // ── Low-level: write one notification doc ────────────────────────────────

  static Future<void> _send({
    required String uid,
    required String title,
    required String body,
    String type = 'general',
    Map<String, dynamic> extra = const {},
  }) async {
    await _db.collection('notifications').add({
      'uid': uid,
      'title': title,
      'body': body,
      'type': type,
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
      ...extra,
    });
  }

  /// Broadcast to all approved users with one of [roles].
  static Future<void> _broadcast({
    required List<String> roles,
    required String title,
    required String body,
    String type = 'general',
  }) async {
    for (final role in roles) {
      final users = await _db
          .collection('users')
          .where('role', isEqualTo: role)
          .where('approved', isEqualTo: true)
          .get();

      final batch = _db.batch();
      for (final doc in users.docs) {
        final ref = _db.collection('notifications').doc();
        batch.set(ref, {
          'uid': doc.id,
          'title': title,
          'body': body,
          'type': type,
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();
    }
  }

  // ── Helper: notify all admins ─────────────────────────────────────────────

  static Future<void> _notifyAllAdmins({
    required String title,
    required String body,
    String type = 'general',
    Map<String, dynamic> extra = const {},
  }) async {
    final admins = await _db
        .collection('users')
        .where('role', isEqualTo: 'admin')
        .get();

    final batch = _db.batch();
    for (final doc in admins.docs) {
      final ref = _db.collection('notifications').doc();
      batch.set(ref, {
        'uid': doc.id,
        'title': title,
        'body': body,
        'type': type,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
        ...extra,
      });
    }
    await batch.commit();
  }

  // ── Helper: notify parents of a student ──────────────────────────────────

  static Future<void> _notifyParentsOfStudents({
    required List<String> studentIds,
    required String title,
    required String body,
    required String type,
  }) async {
    if (studentIds.isEmpty) return;

    for (var i = 0; i < studentIds.length; i += 10) {
      final chunk = studentIds.sublist(
          i, (i + 10).clamp(0, studentIds.length));

      final links = await _db
          .collection('parent_children')
          .where('studentId', whereIn: chunk)
          .get();

      if (links.docs.isEmpty) continue;

      final parentIds = links.docs
          .map((d) => d.data()['parentId'] as String?)
          .whereType<String>()
          .toSet();

      final batch = _db.batch();
      for (final parentId in parentIds) {
        final ref = _db.collection('notifications').doc();
        batch.set(ref, {
          'uid': parentId,
          'title': title,
          'body': body,
          'type': type,
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();
    }
  }

  // ════════════════════════════════════════════════════════════════════════
  // FEE NOTIFICATIONS
  // ════════════════════════════════════════════════════════════════════════

  /// Parent submits payment proof → notify ALL admins.
  /// Call this from parent_fee_screen.dart instead of the inline batch write.
  static Future<void> onFeePaymentSubmitted({
    required String studentName,
    required String feeType,
    required double paidAmount,
    required String transactionId,
    required String feeDocId,
  }) async {
    await _notifyAllAdmins(
      title: '💳 Fee Payment Submitted — Action Required',
      body: '$studentName submitted $feeType payment of '
          'Rs. ${paidAmount.toStringAsFixed(0)}. '
          'TXN: $transactionId. Tap to verify.',
      type: 'finance',
      extra: {'feeDocId': feeDocId},
    );
  }

  /// Admin approves a fee payment → notify parent.
  static Future<void> onFeePaymentVerified({
    required String parentUid,
    required String studentName,
    required String feeType,
    required double paidAmount,
  }) async {
    await _send(
      uid: parentUid,
      title: '✅ Fee Payment Verified',
      body: '$feeType payment of Rs. ${paidAmount.toStringAsFixed(0)} '
          'for $studentName has been verified and marked as PAID by the admin.',
      type: 'finance',
    );
  }

  /// Admin rejects a fee payment → notify parent.
  static Future<void> onFeePaymentRejected({
    required String parentUid,
    required String studentName,
    required String feeType,
    String? reason,
  }) async {
    await _send(
      uid: parentUid,
      title: '❌ Payment Proof Rejected',
      body: reason == null || reason.isEmpty
          ? 'Your payment proof for $studentName ($feeType) was rejected. '
            'Please re-submit with correct details.'
          : 'Your payment proof for $studentName ($feeType) was rejected. '
            'Reason: $reason. Please re-submit.',
      type: 'finance',
    );
  }

  // ════════════════════════════════════════════════════════════════════════
  // ATTENDANCE NOTIFICATIONS
  // ════════════════════════════════════════════════════════════════════════

  /// Teacher submits attendance → notify absent/late students + their parents.
  static Future<void> onAttendanceMarked({
    required String className,
    required String dateLabel,
    required Map<String, String> statusByStudentId,
    required Map<String, String> studentNamesById,
  }) async {
    final batch = _db.batch();
    final absentOrLateIds = <String>[];

    for (final entry in statusByStudentId.entries) {
      final uid = entry.key;
      final status = entry.value;
      final name = studentNamesById[uid] ?? 'Student';

      if (status == 'absent') {
        absentOrLateIds.add(uid);
        final ref = _db.collection('notifications').doc();
        batch.set(ref, {
          'uid': uid,
          'title': '⚠️ Attendance: Marked Absent',
          'body': 'You have been marked absent for $className on $dateLabel. '
              'If this is incorrect, contact your class teacher.',
          'type': 'attendance',
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      } else if (status == 'late') {
        absentOrLateIds.add(uid);
        final ref = _db.collection('notifications').doc();
        batch.set(ref, {
          'uid': uid,
          'title': '⏰ Attendance: Marked Late',
          'body': 'You have been marked late for $className on $dateLabel.',
          'type': 'attendance',
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    }

    await batch.commit();

    // Notify parents of absent/late students
    for (final uid in absentOrLateIds) {
      final status = statusByStudentId[uid]!;
      final name = studentNamesById[uid] ?? 'Your child';
      await _notifyParentsOfStudents(
        studentIds: [uid],
        title: status == 'absent'
            ? '⚠️ $name Was Absent Today'
            : '⏰ $name Was Late Today',
        body: status == 'absent'
            ? '$name has been marked absent for $className on $dateLabel.'
            : '$name was marked late for $className on $dateLabel.',
        type: 'attendance',
      );
    }
  }

  // ════════════════════════════════════════════════════════════════════════
  // GRADE NOTIFICATIONS
  // ════════════════════════════════════════════════════════════════════════

  /// Teacher records a grade → notify student + parents.
  static Future<void> onGradeRecorded({
    required String studentUid,
    required String studentName,
    required String subject,
    required String examTitle,
    required double percentage,
    required String grade,
  }) async {
    final emoji = percentage >= 80 ? '🌟' : percentage >= 60 ? '📊' : '📉';

    await _send(
      uid: studentUid,
      title: '$emoji Result Posted: $subject — $examTitle',
      body: 'Your $subject result for "$examTitle" has been recorded. '
          'You scored $grade (${percentage.toStringAsFixed(1)}%). '
          'Open Results to view the full breakdown.',
      type: 'result',
    );

    await _notifyParentsOfStudents(
      studentIds: [studentUid],
      title: '$emoji $studentName\'s $subject Result: $grade',
      body: '$studentName scored $grade (${percentage.toStringAsFixed(1)}%) '
          'in "$examTitle" ($subject). Open Results to see the full breakdown.',
      type: 'result',
    );
  }

  // ════════════════════════════════════════════════════════════════════════
  // ASSIGNMENT NOTIFICATIONS
  // ════════════════════════════════════════════════════════════════════════

  /// Teacher posts an assignment → notify students + parents in class.
  static Future<void> onAssignmentPosted({
    required String className,
    required String subject,
    required String assignmentTitle,
    required String teacherName,
    required String dueDate,
  }) async {
    final students = await _db
        .collection('students')
        .where('class', isEqualTo: className)
        .get();

    final studentIds = students.docs.map((d) => d.id).toList();

    final batch = _db.batch();
    for (final student in students.docs) {
      final ref = _db.collection('notifications').doc();
      batch.set(ref, {
        'uid': student.id,
        'title': '📝 New Assignment: $subject',
        'body': '$teacherName posted "$assignmentTitle" for $className. '
            'Due: $dueDate.',
        'type': 'assignment',
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();

    if (studentIds.isNotEmpty) {
      await _notifyParentsOfStudents(
        studentIds: studentIds,
        title: '📝 New Assignment for Your Child: $subject',
        body: 'A new $subject assignment "$assignmentTitle" has been posted '
            'for $className by $teacherName. Due: $dueDate.',
        type: 'assignment',
      );
    }
  }

  // ════════════════════════════════════════════════════════════════════════
  // NOTICE NOTIFICATIONS
  // ════════════════════════════════════════════════════════════════════════

  /// Admin publishes a notice → broadcast to all students, teachers, parents.
  static Future<void> onNoticePublished({
    required String noticeTitle,
    required String noticeBody,
    required String category,
  }) async {
    final title = '📢 New $category Notice: $noticeTitle';
    final body = noticeBody.length > 120
        ? '${noticeBody.substring(0, 117)}...'
        : noticeBody;

    await _broadcast(
      roles: ['student', 'teacher', 'parent'],
      title: title,
      body: body,
      type: _noticeType(category),
    );
  }

  // ════════════════════════════════════════════════════════════════════════
  // ACCOUNT NOTIFICATIONS
  // ════════════════════════════════════════════════════════════════════════

  static Future<void> onUserApproved({
    required String userUid,
    required String userName,
    required String role,
  }) async {
    await _send(
      uid: userUid,
      title: 'Account Approved ✅',
      body: 'Good news, $userName! Your ${_roleLabel(role)} account has been '
          'approved by the school administrator.',
      type: 'approval',
    );
  }

  static Future<void> onUserRegistered({
    required String userName,
    required String role,
    required String email,
  }) async {
    await _notifyAllAdmins(
      title: 'New Registration Pending Approval 🔔',
      body: '$userName has registered as a ${_roleLabel(role)} ($email) and '
          'is waiting for your approval.',
      type: 'registration',
    );
  }

  static Future<void> onTeacherAdded({
    required String teacherUid,
    required String teacherName,
  }) async {
    await _send(
      uid: teacherUid,
      title: 'Welcome to EduManage! 🎉',
      body: 'Hi $teacherName, your teacher account has been created. '
          'You can now log in and manage your classes.',
      type: 'general',
    );
  }

  static Future<void> onStudentAdded({
    required String studentUid,
    required String studentName,
    required String className,
    required String rollNo,
  }) async {
    await _send(
      uid: studentUid,
      title: 'Welcome to EduManage! 🎉',
      body: 'Hi $studentName, your student account is ready. '
          'You are enrolled in $className with Roll No $rollNo.',
      type: 'general',
    );
  }

  // ── Private helpers ───────────────────────────────────────────────────────

  static String _roleLabel(String role) => switch (role) {
        'teacher' => 'teacher',
        'parent'  => 'parent',
        'admin'   => 'administrator',
        _         => 'student',
      };

  static String _noticeType(String category) => switch (category.toLowerCase()) {
        'exam'    => 'exam',
        'finance' => 'finance',
        'holiday' => 'holiday',
        _         => 'general',
      };
}