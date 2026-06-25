import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/attendence_model.dart';
import '../services/firebase_service.dart';

class AttendanceRepository {
  AttendanceRepository._();
  static final AttendanceRepository instance = AttendanceRepository._();

  final _fs = FirebaseService.instance;

  String todayKey() {
    final now = DateTime.now();
    return '${now.year.toString().padLeft(4, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
  }

  /// All attendance records for one student, most recent first.
  Stream<List<AttendanceModel>> watchByStudent(String studentId) {
    return _fs.attendance
        .where('studentId', isEqualTo: studentId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(AttendanceModel.fromDoc).toList());
  }

  /// Checks whether a given class already has any attendance recorded
  /// for a given date — use this before showing a marking UI so the
  /// caller can warn/pre-fill instead of silently allowing a second
  /// blind submission. Mirrors the same check ClassAttendanceScreen runs
  /// internally; exposed here too since this repository may be used by
  /// other entry points in future.
  Future<bool> isAlreadyMarked({
    required String className,
    String? date,
  }) async {
    final dateKey = date ?? todayKey();
    final snap = await _fs.attendance
        .where('className', isEqualTo: className)
        .where('date', isEqualTo: dateKey)
        .limit(1)
        .get();
    return snap.docs.isNotEmpty;
  }

  /// Submits a full class's attendance for today as a single batch write.
  ///
  /// THE FIX — NO DOUBLE ATTENDANCE: this previously called
  /// `_fs.attendance.doc()` (an auto-generated ID) for every student,
  /// which meant calling this method twice for the same class/day would
  /// silently create a SECOND full set of attendance documents — true
  /// duplicates, since auto-generated IDs are never the same twice.
  ///
  /// Every write now targets the deterministic ID
  /// `attendance/{studentId}_{date}`, exactly matching the scheme already
  /// used by ClassAttendanceScreen (the actual UI wired to the app).
  /// Calling this method any number of times for the same student and
  /// date always overwrites the same one document — it is structurally
  /// impossible to end up with two attendance records for one student on
  /// one day through this method, regardless of how many times it's
  /// invoked or whether the caller checked [isAlreadyMarked] first.
  ///
  /// [date] defaults to today and should normally be left unset — date is
  /// mandatory by construction here too: every write always carries a
  /// 'yyyy-MM-dd' value, never null/blank.
  Future<void> submitClassAttendance({
    required String className,
    required Map<String, AttendanceStatusValue> statusByStudentId,
    required Map<String, String> studentNamesById,
    String? date,
  }) async {
    final dateStr = date ?? todayKey();
    await _fs.runBatch((batch) {
      statusByStudentId.forEach((studentId, status) {
        final ref = _fs.attendance.doc('${studentId}_$dateStr');
        batch.set(ref, {
          'studentId': studentId,
          'studentName': studentNamesById[studentId] ?? '',
          'className': className,
          'date': dateStr,
          'status': status.name,
          'timestamp': FieldValue.serverTimestamp(),
          'createdAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      });
    });
  }
}