import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:school_management_system/core/theme/app_colors.dart';
import 'package:school_management_system/core/theme/app_text_style.dart';
import 'package:school_management_system/core/widgets/custom_button.dart';
import 'package:school_management_system/core/widgets/custom_text_field.dart';

class FeeScreen extends StatefulWidget {
  const FeeScreen({super.key});

  @override
  State<FeeScreen> createState() => _FeeScreenState();
}

class _FeeScreenState extends State<FeeScreen> {
  String _filter = 'All'; // All | Paid | Pending | Overdue

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.warning,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: Text('Fee Management',
            style: AppTextStyles.headingMedium.copyWith(color: Colors.white)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddFeeSheet(context),
        backgroundColor: AppColors.warning,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Record',
            style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
      ),
      body: Column(
        children: [
          // Status filter
          Container(
            color: AppColors.warning,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: SizedBox(
              height: 36,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: ['All', 'Paid', 'Pending', 'Overdue'].map((s) {
                  final isSel = _filter == s;
                  return GestureDetector(
                    onTap: () => setState(() => _filter = s),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSel ? Colors.white : Colors.white24,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(s,
                          style: AppTextStyles.labelSmall.copyWith(
                            color: isSel ? AppColors.warning : Colors.white,
                            fontWeight: isSel ? FontWeight.w700 : FontWeight.w400,
                          )),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('fees')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                var docs = snap.data?.docs ?? [];
                if (_filter != 'All') {
                  docs = docs.where((d) {
                    final data = d.data() as Map<String, dynamic>;
                    return (data['status'] as String? ?? '') == _filter;
                  }).toList();
                }

                if (docs.isEmpty) {
                  return Center(
                    child: Text('No fee records.',
                        style: AppTextStyles.bodyMedium
                            .copyWith(color: AppColors.textSecondary)),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final data = docs[i].data() as Map<String, dynamic>;
                    final status = data['status'] as String? ?? 'Pending';
                    final dueDate =
                        (data['dueDate'] as Timestamp?)?.toDate();
                    Color color;
                    switch (status) {
                      case 'Paid':    color = AppColors.success; break;
                      case 'Overdue': color = AppColors.danger;  break;
                      default:        color = AppColors.warning;
                    }

                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.cardBg,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: AppColors.cardShadow,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 44, height: 44,
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.attach_money_rounded,
                                color: color),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(data['studentName'] ?? '',
                                    style: AppTextStyles.bodyMediumBold),
                                Text(
                                  '${data['feeType'] ?? ''} · Rs ${data['amount'] ?? ''}',
                                  style: AppTextStyles.labelSmall,
                                ),
                                if (dueDate != null)
                                  Text(
                                    'Due ${DateFormat('MMM d, yyyy').format(dueDate)}',
                                    style: AppTextStyles.labelTiny.copyWith(
                                        color: AppColors.textSecondary),
                                  ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: color.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(status,
                                    style: AppTextStyles.labelTiny.copyWith(
                                        color: color,
                                        fontWeight: FontWeight.w700)),
                              ),
                              if (status == 'Pending')
                                TextButton(
                                  style: TextButton.styleFrom(
                                      padding: EdgeInsets.zero,
                                      minimumSize: const Size(0, 28)),
                                  onPressed: () =>
                                      FirebaseFirestore.instance
                                          .collection('fees')
                                          .doc(docs[i].id)
                                          .update({'status': 'Paid'}),
                                  child: Text('Mark paid',
                                      style: AppTextStyles.labelTiny
                                          .copyWith(color: AppColors.success)),
                                ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showAddFeeSheet(BuildContext context) {
    final nameCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    final typeCtrl = TextEditingController();
    DateTime? dueDate;
    bool loading = false;
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardBg,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (sheetCtx) => StatefulBuilder(
        builder: (sheetCtx, setSS) => Padding(
          padding: EdgeInsets.only(
            left: 20, right: 20, top: 20,
            bottom: MediaQuery.of(sheetCtx).viewInsets.bottom + 20,
          ),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                )),
                const SizedBox(height: 20),
                Text('Add Fee Record', style: AppTextStyles.headingMedium),
                const SizedBox(height: 16),
                CustomTextField(label: 'Student Name', controller: nameCtrl,
                    validator: (v) => v == null || v.isEmpty ? 'Required' : null),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: CustomTextField(
                    label: 'Fee Type', hint: 'Tuition / Transport',
                    controller: typeCtrl,
                    validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                  )),
                  const SizedBox(width: 14),
                  Expanded(child: CustomTextField(
                    label: 'Amount (Rs)',
                    controller: amountCtrl,
                    keyboardType: TextInputType.number,
                    validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                  )),
                ]),
                const SizedBox(height: 12),
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: sheetCtx,
                      initialDate: DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) setSS(() => dueDate = picked);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 16),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: Row(children: [
                      const Icon(Icons.calendar_today_rounded,
                          color: AppColors.textHint, size: 18),
                      const SizedBox(width: 10),
                      Text(
                        dueDate != null
                            ? DateFormat('MMM d, yyyy').format(dueDate!)
                            : 'Select due date',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: dueDate != null
                              ? AppColors.textPrimary
                              : AppColors.textHint,
                        ),
                      ),
                    ]),
                  ),
                ),
                const SizedBox(height: 20),
                CustomButton(
                  label: 'Save Record',
                  isLoading: loading,
                  gradient: const LinearGradient(
                    colors: [Color(0xFFE67E22), Color(0xFFF59E0B)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;
                    setSS(() => loading = true);
                    await FirebaseFirestore.instance.collection('fees').add({
                      'studentName': nameCtrl.text.trim(),
                      'feeType': typeCtrl.text.trim(),
                      'amount': amountCtrl.text.trim(),
                      'status': 'Pending',
                      'dueDate': dueDate != null
                          ? Timestamp.fromDate(dueDate!)
                          : null,
                      'createdAt': FieldValue.serverTimestamp(),
                    });
                    if (sheetCtx.mounted) Navigator.pop(sheetCtx);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}