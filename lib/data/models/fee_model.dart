import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

enum FeeStatus { paid, pending, overdue, pendingVerification, unknown }

FeeStatus feeStatusFromString(String? s) {
  switch (s?.toLowerCase().trim()) {
    case 'paid':
      return FeeStatus.paid;
    case 'pending':
      return FeeStatus.pending;
    case 'overdue':
      return FeeStatus.overdue;
    case 'pending_verification':
    case 'pendingverification':
      return FeeStatus.pendingVerification;
    default:
      return FeeStatus.unknown;
  }
}

String feeStatusToString(FeeStatus status) {
  switch (status) {
    case FeeStatus.paid:
      return 'paid';
    case FeeStatus.pending:
      return 'pending';
    case FeeStatus.overdue:
      return 'overdue';
    case FeeStatus.pendingVerification:
      return 'pending_verification';
    case FeeStatus.unknown:
      return 'pending';
  }
}

/// Represents a fee record for a student.
class FeeModel {
  final String id;
  final String studentId;
  final String studentName;
  final String className;
  final String feeType;
  final double amount;
  final FeeStatus status;
  final DateTime? dueDate;
  final String? month;
  final String? year;
  final Map<String, dynamic>? paymentProof;
  final DateTime? paidAt;
  final DateTime? createdAt;

  const FeeModel({
    required this.id,
    required this.studentId,
    this.studentName = '',
    this.className = '',
    this.feeType = 'Tuition Fee',
    required this.amount,
    this.status = FeeStatus.pending,
    this.dueDate,
    this.month,
    this.year,
    this.paymentProof,
    this.paidAt,
    this.createdAt,
  });

  factory FeeModel.fromMap(String id, Map<String, dynamic> map) {
    DateTime? parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String && val.isNotEmpty) {
        try {
          return DateTime.parse(val);
        } catch (_) {
          return null;
        }
      }
      return null;
    }

    return FeeModel(
      id: id,
      studentId: map['studentId'] as String? ?? '',
      studentName: map['studentName'] as String? ?? '',
      className: map['className'] as String? ?? '',
      feeType: map['feeType'] as String? ?? 'Tuition Fee',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      status: feeStatusFromString(map['status'] as String?),
      dueDate: parseDate(map['dueDate']),
      month: map['month'] as String?,
      year: map['year']?.toString(),
      paymentProof: map['paymentProof'] as Map<String, dynamic>?,
      paidAt: parseDate(map['paidAt']),
      createdAt: parseDate(map['createdAt']) ?? parseDate(map['timestamp']),
    );
  }

  factory FeeModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return FeeModel.fromMap(doc.id, data);
  }

  Map<String, dynamic> toMap() {
    return {
      'studentId': studentId,
      'studentName': studentName,
      'className': className,
      'feeType': feeType,
      'amount': amount,
      'status': feeStatusToString(status),
      'dueDate': dueDate != null ? Timestamp.fromDate(dueDate!) : null,
      if (month != null) 'month': month,
      if (year != null) 'year': year,
      if (paymentProof != null) 'paymentProof': paymentProof,
      if (paidAt != null) 'paidAt': Timestamp.fromDate(paidAt!),
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
    };
  }

  bool get isOverdue {
    if (status == FeeStatus.paid) return false;
    if (dueDate == null) return false;
    return DateTime.now().isAfter(dueDate!);
  }

  String get formattedDueDate {
    if (dueDate == null) return 'No due date';
    return DateFormat('MMM d, yyyy').format(dueDate!);
  }

  String get formattedAmount => 'Rs. ${amount.toStringAsFixed(0)}';

  FeeModel copyWith({
    String? id,
    String? studentId,
    String? studentName,
    String? className,
    String? feeType,
    double? amount,
    FeeStatus? status,
    DateTime? dueDate,
    String? month,
    String? year,
    Map<String, dynamic>? paymentProof,
    DateTime? paidAt,
    DateTime? createdAt,
  }) {
    return FeeModel(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      studentName: studentName ?? this.studentName,
      className: className ?? this.className,
      feeType: feeType ?? this.feeType,
      amount: amount ?? this.amount,
      status: status ?? this.status,
      dueDate: dueDate ?? this.dueDate,
      month: month ?? this.month,
      year: year ?? this.year,
      paymentProof: paymentProof ?? this.paymentProof,
      paidAt: paidAt ?? this.paidAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
