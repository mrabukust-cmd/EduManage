import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/fee_model.dart';
import '../services/firebase_service.dart';

/// Centralized repository for student fee records, invoices, and verification workflows.
class FeeRepository {
  FeeRepository._();
  static final FeeRepository instance = FeeRepository._();

  final _fs = FirebaseService.instance;

  /// Stream all fee records for a specific student, sorted by due date descending.
  Stream<List<FeeModel>> watchByStudent(String studentId) {
    return _fs.fees
        .where('studentId', isEqualTo: studentId)
        .snapshots()
        .map((snap) {
      final list = snap.docs.map(FeeModel.fromDoc).toList();
      list.sort((a, b) {
        final aDate = a.dueDate ?? DateTime(0);
        final bDate = b.dueDate ?? DateTime(0);
        return bDate.compareTo(aDate);
      });
      return list;
    });
  }

  /// Stream fee records for a specific class.
  Stream<List<FeeModel>> watchByClass(String className) {
    return _fs.fees
        .where('className', isEqualTo: className.trim())
        .snapshots()
        .map((snap) => snap.docs.map(FeeModel.fromDoc).toList());
  }

  /// Stream all fee records currently pending verification from admin.
  Stream<List<FeeModel>> watchPendingVerification() {
    return _fs.fees
        .where('status', isEqualTo: 'pending_verification')
        .snapshots()
        .map((snap) => snap.docs.map(FeeModel.fromDoc).toList());
  }

  /// Stream all fee records.
  Stream<List<FeeModel>> watchAll() {
    return _fs.fees
        .snapshots()
        .map((snap) => snap.docs.map(FeeModel.fromDoc).toList());
  }

  /// Submit payment proof from parent/student.
  Future<void> submitPaymentProof({
    required String feeId,
    required Map<String, dynamic> proofData,
  }) async {
    await _fs.fees.doc(feeId).update({
      'paymentProof': proofData,
      'status': 'pending_verification',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Verify and mark fee as paid by admin.
  Future<void> verifyPayment({
    required String feeId,
    required bool approved,
    String? adminNotes,
  }) async {
    if (approved) {
      await _fs.fees.doc(feeId).update({
        'status': 'paid',
        'paidAt': FieldValue.serverTimestamp(),
        if (adminNotes != null) 'adminNotes': adminNotes,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } else {
      await _fs.fees.doc(feeId).update({
        'status': 'pending',
        if (adminNotes != null) 'adminNotes': adminNotes,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  /// Create a new fee invoice.
  Future<DocumentReference<Map<String, dynamic>>> create(FeeModel fee) {
    return _fs.fees.add(fee.toMap());
  }

  /// Update an existing fee document.
  Future<void> update(String id, Map<String, dynamic> data) {
    return _fs.fees.doc(id).update(data);
  }

  /// Delete a fee document.
  Future<void> delete(String id) {
    return _fs.fees.doc(id).delete();
  }
}
