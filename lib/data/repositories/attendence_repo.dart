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

  /// Submits a full class's attendance for today as a single batch write.
  Future<void> submitClassAttendance({
    required String className,
    required Map<String, AttendanceStatusValue> statusByStudentId,
    required Map<String, String> studentNamesById,
  }) async {
    final dateStr = todayKey();
    await _fs.runBatch((batch) {
      statusByStudentId.forEach((studentId, status) {
        final ref = _fs.attendance.doc();
        batch.set(ref, {
          'studentId': studentId,
          'studentName': studentNamesById[studentId] ?? '',
          'className': className,
          'date': dateStr,
          'status': status.name,
          'timestamp': FieldValue.serverTimestamp(),
          'createdAt': FieldValue.serverTimestamp(),
        });
      });
    });
  }
}