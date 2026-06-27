import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:school_management_system/data/services/local_notification_service.dart';

/// Centralized notification writer.
///
/// Every public method writes one or more documents to the `notifications`
/// Firestore collection. NotificationsScreen streams that collection for
/// in-app delivery. FCM push delivery follows via a Cloud Function
/// (when configured) that reads the same documents.
///
/// Notification types map to icons/colours in NotificationsScreen:
///   general | exam | finance | attendance | assignment | result |
///   approval | registration | holiday
class AppNotifications {
  AppNotifications._();

  static final _db = FirebaseFirestore.instance;

  // ── Low-level write ──────────────────────────────────────────────────────

  static Future<void> _send({
    required String uid,
    required String title,
    required String body,
    String type = 'general',
  }) async {
    // Save to Firestore (existing code)
    await _db.collection('notifications').add({
      'uid': uid,
      'title': title,
      'body': body,
      'type': type,
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // NEW: Also show as a popup banner on THIS device
    // (shows for the currently logged-in user)
  //   await LocalNotificationService.instance.show(
  //     title: title,
  //     body: body,
  //     type: type,
  //   );
  }

  /// Sends the same notification to every user whose `role` is in [roles].
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

    // NEW: Show popup on current device
  //   await LocalNotificationService.instance.show(
  //     title: title,
  //     body: body,
  //     type: type,
  //   );
  }

  // ── Admin adds a teacher ─────────────────────────────────────────────────

  /// Notifies the newly-created teacher that their account is ready.
  static Future<void> onTeacherAdded({
    required String teacherUid,
    required String teacherName,
  }) async {
    await _send(
      uid: teacherUid,
      title: 'Welcome to EduManage! 🎉',
      body:
          'Hi $teacherName, your teacher account has been created by the '
          'admin. You can now log in and start managing your classes, '
          'attendance, and assignments.',
      type: 'general',
    );
  }

  // ── Admin adds a student ─────────────────────────────────────────────────

  /// Notifies the newly-created student that their account is ready.
  static Future<void> onStudentAdded({
    required String studentUid,
    required String studentName,
    required String className,
    required String rollNo,
  }) async {
    await _send(
      uid: studentUid,
      title: 'Welcome to EduManage! 🎉',
      body:
          'Hi $studentName, your student account is ready. You have been '
          'enrolled in $className with Roll No $rollNo. Log in to view '
          'your timetable, assignments, and results.',
      type: 'general',
    );
  }

  // ── Admin publishes a notice ─────────────────────────────────────────────

  /// Broadcasts a notice to all approved students, teachers, and parents.
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

  // ── Admin approves a user ────────────────────────────────────────────────

  /// Notifies the approved user their account is active.
  static Future<void> onUserApproved({
    required String userUid,
    required String userName,
    required String role,
  }) async {
    final roleLabel = _roleLabel(role);
    await _send(
      uid: userUid,
      title: 'Account Approved ✅',
      body:
          'Good news, $userName! Your $roleLabel account has been approved '
          'by the school administrator. You can now log in and access all '
          'features available to you.',
      type: 'approval',
    );
  }

  // ── User self-registers ──────────────────────────────────────────────────

  /// Notifies all admins that a new user has registered and needs approval.
  static Future<void> onUserRegistered({
    required String userName,
    required String role,
    required String email,
  }) async {
    final roleLabel = _roleLabel(role);

    // Find all admin uids
    final admins = await _db
        .collection('users')
        .where('role', isEqualTo: 'admin')
        .get();

    final batch = _db.batch();
    for (final admin in admins.docs) {
      final ref = _db.collection('notifications').doc();
      batch.set(ref, {
        'uid': admin.id,
        'title': 'New Registration Pending Approval 🔔',
        'body':
            '$userName has registered as a $roleLabel ($email) and is '
            'waiting for your approval. Go to Approvals to review their '
            'request.',
        'type': 'registration',
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  }

  // ── Teacher posts an assignment ──────────────────────────────────────────

  /// Notifies all students in [className] about a new assignment.
  static Future<void> onAssignmentPosted({
    required String className,
    required String subject,
    required String assignmentTitle,
    required String teacherName,
    required String dueDate, // formatted, e.g. "Dec 15"
  }) async {
    // Get all students in this class
    final students = await _db
        .collection('students')
        .where('class', isEqualTo: className)
        .get();

    // Also notify parents linked to those students
    final studentIds = students.docs.map((d) => d.id).toList();

    final batch = _db.batch();

    // Notify students
    for (final student in students.docs) {
      final ref = _db.collection('notifications').doc();
      batch.set(ref, {
        'uid': student.id,
        'title': '📝 New Assignment: $subject',
        'body':
            '$teacherName has posted a new assignment "$assignmentTitle" '
            'for $className. Due date: $dueDate. Open Assignments to view '
            'the full details.',
        'type': 'assignment',
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();

    // Notify parents of those students
    if (studentIds.isNotEmpty) {
      await _notifyParentsOfStudents(
        studentIds: studentIds,
        title: '📝 New Assignment for Your Child: $subject',
        body:
            'A new $subject assignment "$assignmentTitle" has been posted '
            'for $className by $teacherName. Due: $dueDate.',
        type: 'assignment',
      );
    }
  }

  // ── Teacher records grades ───────────────────────────────────────────────

  /// Notifies a student (and their parents) when a grade is recorded.
  static Future<void> onGradeRecorded({
    required String studentUid,
    required String studentName,
    required String subject,
    required String examTitle,
    required double percentage,
    required String grade,
  }) async {
    final emoji = percentage >= 80
        ? '🌟'
        : percentage >= 60
        ? '📊'
        : '📉';

    // Notify student
    await _send(
      uid: studentUid,
      title: '$emoji Result Posted: $subject — $examTitle',
      body:
          'Your $subject result for "$examTitle" has been recorded. '
          'You scored $grade (${percentage.toStringAsFixed(1)}%). '
          'Open Results to view the full breakdown.',
      type: 'result',
    );

    // Notify parents
    await _notifyParentsOfStudents(
      studentIds: [studentUid],
      title: '$emoji $studentName\'s $subject Result: $grade',
      body:
          '$studentName scored $grade (${percentage.toStringAsFixed(1)}%) '
          'in "$examTitle" ($subject). Open Results to see the full '
          'breakdown.',
      type: 'result',
    );
  }

  // ── Teacher submits attendance ───────────────────────────────────────────

  /// Notifies absent/late students and their parents.
  static Future<void> onAttendanceMarked({
    required String className,
    required String dateLabel, // e.g. "Monday, Dec 9"
    required Map<String, String>
    statusByStudentId, // uid → 'absent'|'late'|'present'
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
        // Notify student
        final ref = _db.collection('notifications').doc();
        batch.set(ref, {
          'uid': uid,
          'title': '⚠️ Attendance: Marked Absent',
          'body':
              'You have been marked absent for $className on $dateLabel. '
              'If this is incorrect, please contact your class teacher '
              'promptly.',
          'type': 'attendance',
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      } else if (status == 'late') {
        absentOrLateIds.add(uid);
        // Notify student
        final ref = _db.collection('notifications').doc();
        batch.set(ref, {
          'uid': uid,
          'title': '⏰ Attendance: Marked Late',
          'body':
              'You have been marked late for $className on $dateLabel. '
              'Repeated late arrivals may affect your attendance record.',
          'type': 'attendance',
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    }

    await batch.commit();

    // Notify parents of absent/late students
    if (absentOrLateIds.isNotEmpty) {
      for (final uid in absentOrLateIds) {
        final status = statusByStudentId[uid]!;
        final name = studentNamesById[uid] ?? 'Your child';
        await _notifyParentsOfStudents(
          studentIds: [uid],
          title: status == 'absent'
              ? '⚠️ $name Was Absent Today'
              : '⏰ $name Was Late Today',
          body: status == 'absent'
              ? '$name has been marked absent for $className on $dateLabel. '
                    'Please ensure regular attendance.'
              : '$name was marked late for $className on $dateLabel. '
                    'Please encourage punctuality.',
          type: 'attendance',
        );
      }
    }
  }

  // ── Internal helpers ─────────────────────────────────────────────────────

  /// Notifies parents who have any of [studentIds] linked to their account.
  static Future<void> _notifyParentsOfStudents({
    required List<String> studentIds,
    required String title,
    required String body,
    required String type,
  }) async {
    if (studentIds.isEmpty) return;

    // Chunk into groups of 10 (Firestore whereIn limit)
    for (var i = 0; i < studentIds.length; i += 10) {
      final chunk = studentIds.sublist(
        i,
        i + 10 > studentIds.length ? studentIds.length : i + 10,
      );

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

  static String _roleLabel(String role) {
    return switch (role) {
      'teacher' => 'teacher',
      'parent' => 'parent',
      'admin' => 'administrator',
      _ => 'student',
    };
  }

  static String _noticeType(String category) {
    return switch (category.toLowerCase()) {
      'exam' => 'exam',
      'finance' => 'finance',
      'holiday' => 'holiday',
      _ => 'general',
    };
  }
}
