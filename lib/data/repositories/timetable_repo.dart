import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/timetable_model.dart';
import '../services/firebase_service.dart';

/// Centralized repository for managing timetable period slots.
class TimetableRepository {
  TimetableRepository._();
  static final TimetableRepository instance = TimetableRepository._();

  final _fs = FirebaseService.instance;

  /// Stream timetable slots for a specific class and day of week.
  Stream<List<TimetableModel>> watchByClassAndDay(
      String className, String day) {
    return _fs.timetable
        .where('className', isEqualTo: className.trim())
        .where('day', isEqualTo: day.trim())
        .snapshots()
        .map((snap) {
      final slots = snap.docs.map(TimetableModel.fromDoc).toList();
      slots.sort((a, b) => a.startTime.compareTo(b.startTime));
      return slots;
    });
  }

  /// Stream all timetable slots for a class across all days.
  Stream<List<TimetableModel>> watchByClass(String className) {
    return _fs.timetable
        .where('className', isEqualTo: className.trim())
        .snapshots()
        .map((snap) {
      final slots = snap.docs.map(TimetableModel.fromDoc).toList();
      slots.sort((a, b) => a.startTime.compareTo(b.startTime));
      return slots;
    });
  }

  /// Stream all timetable slots assigned to a specific teacher name.
  Stream<List<TimetableModel>> watchByTeacher(String teacherName) {
    return _fs.timetable
        .where('teacher', isEqualTo: teacherName.trim())
        .snapshots()
        .map((snap) {
      final slots = snap.docs.map(TimetableModel.fromDoc).toList();
      slots.sort((a, b) => a.startTime.compareTo(b.startTime));
      return slots;
    });
  }

  /// Add a new period slot to timetable.
  Future<DocumentReference<Map<String, dynamic>>> addSlot(
      TimetableModel slot) {
    return _fs.timetable.add(slot.toMap());
  }

  /// Delete a timetable slot.
  Future<void> deleteSlot(String id) {
    return _fs.timetable.doc(id).delete();
  }

  /// Update an existing timetable slot.
  Future<void> updateSlot(String id, Map<String, dynamic> data) {
    return _fs.timetable.doc(id).update(data);
  }
}
