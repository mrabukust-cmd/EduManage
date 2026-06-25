import 'package:cloud_firestore/cloud_firestore.dart';

/// Generates sequential, class-scoped roll numbers using a Firestore
/// transaction so concurrent admin sessions never produce duplicates.
///
/// Firestore layout:
///   class_counters/{classKey}  →  { lastRollNo: int, className: string }
///
/// classKey  = className with every non-alphanumeric character collapsed
///             to an underscore, lower-cased.  Keeps doc IDs safe and
///             deterministic regardless of spacing/casing in the class name.
///             e.g.  "Grade 9 - A"  →  "grade_9___a"
///
/// Roll number format:  zero-padded to 3 digits  →  "001", "002", … "999".
/// Adjust [_padWidth] if you ever expect a class larger than 999 students.
///
/// Usage:
///   final rollNo = await RollNumberService.instance.nextRollNo('Grade 9 - A');
///   // rollNo == "001" on the first call, "002" on the second, etc.
///
/// To preview the NEXT roll number without reserving it (for display while
/// the admin fills in the form), call [peekNextRollNo].  This is a plain
/// read — not a transaction — so treat it as an estimate; the real number
/// is locked in only when [nextRollNo] commits.
class RollNumberService {
  RollNumberService._();
  static final RollNumberService instance = RollNumberService._();

  static const int _padWidth = 3;
  static const String _collection = 'class_counters';

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ── helpers ──────────────────────────────────────────────────────────────

  /// Converts a class name to a safe Firestore document key.
  String _keyFor(String className) =>
      className.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');

  String _format(int n) => n.toString().padLeft(_padWidth, '0');

  // ── public API ────────────────────────────────────────────────────────────

  /// Atomically reserves and returns the next roll number for [className].
  ///
  /// Safe to call from multiple clients simultaneously — the Firestore
  /// transaction guarantees no two callers ever get the same number.
  ///
  /// Throws if [className] is blank or if the Firestore transaction fails
  /// after its default retry attempts.
  Future<String> nextRollNo(String className) async {
    if (className.trim().isEmpty) {
      throw ArgumentError('className must not be empty');
    }

    final docRef = _db
        .collection(_collection)
        .doc(_keyFor(className));

    int reserved = 0;

    await _db.runTransaction((tx) async {
      final snap = await tx.get(docRef);

      if (!snap.exists) {
        // First student ever in this class.
        reserved = 1;
        tx.set(docRef, {
          'lastRollNo': 1,
          'className': className.trim(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        final last = (snap.data()?['lastRollNo'] as int?) ?? 0;
        reserved = last + 1;
        tx.update(docRef, {
          'lastRollNo': reserved,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    });

    return _format(reserved);
  }

  /// Non-transactional peek at what the next roll number *would* be.
  ///
  /// Use this only for UI preview (e.g. showing "Roll No will be 007"
  /// while the admin fills in the form).  Always call [nextRollNo] on
  /// actual save — never rely on the peeked value as the real number.
  Future<String> peekNextRollNo(String className) async {
    if (className.trim().isEmpty) return _format(1);

    try {
      final snap = await _db
          .collection(_collection)
          .doc(_keyFor(className))
          .get();

      if (!snap.exists) return _format(1);

      final last = (snap.data()?['lastRollNo'] as int?) ?? 0;
      return _format(last + 1);
    } catch (_) {
      // Non-critical — return a placeholder if the read fails.
      return '—';
    }
  }

  /// Returns the current counter value for a class (0 if never used).
  /// Useful for displaying "X students enrolled" without querying students.
  Future<int> currentCount(String className) async {
    if (className.trim().isEmpty) return 0;
    try {
      final snap = await _db
          .collection(_collection)
          .doc(_keyFor(className))
          .get();
      return (snap.data()?['lastRollNo'] as int?) ?? 0;
    } catch (_) {
      return 0;
    }
  }
}