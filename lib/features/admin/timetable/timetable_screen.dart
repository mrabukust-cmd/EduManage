import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:school_management_system/core/theme/app_colors.dart';
import 'package:school_management_system/core/theme/app_text_style.dart';
import 'package:school_management_system/core/widgets/custom_button.dart';
import 'package:school_management_system/core/widgets/custom_text_field.dart';

class TimetableScreen extends StatefulWidget {
  const TimetableScreen({super.key});

  @override
  State<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends State<TimetableScreen> {
  String _selectedClass = '';
  String _selectedDay = 'Monday';
  final _days = ['Monday','Tuesday','Wednesday','Thursday','Friday','Saturday'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: Text('Timetable',
            style: AppTextStyles.headingMedium.copyWith(color: Colors.white)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddSlotSheet(context),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Slot',
            style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
      ),
      body: Column(
        children: [
          // Class filter
          Container(
            color: AppColors.primary,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('classes')
                  .orderBy('name')
                  .snapshots(),
              builder: (context, snap) {
                final names = snap.hasData
                    ? snap.data!.docs
                        .map((d) =>
                            (d.data() as Map<String, dynamic>)['name'] as String? ?? '')
                        .where((n) => n.isNotEmpty)
                        .toSet()
                        .toList()
                    : <String>[];
                if (names.isNotEmpty && _selectedClass.isEmpty) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) setState(() => _selectedClass = names.first);
                  });
                }
                return SizedBox(
                  height: 36,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: names.map((c) {
                      final isSel = _selectedClass == c;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedClass = c),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSel ? Colors.white : Colors.white24,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(c,
                              style: AppTextStyles.labelSmall.copyWith(
                                color: isSel ? AppColors.primary : Colors.white,
                                fontWeight: isSel
                                    ? FontWeight.w700
                                    : FontWeight.w400,
                              )),
                        ),
                      );
                    }).toList(),
                  ),
                );
              },
            ),
          ),
          // Day tabs
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: _days.map((d) {
                final isSel = _selectedDay == d;
                return GestureDetector(
                  onTap: () => setState(() => _selectedDay = d),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: isSel
                          ? AppColors.primary
                          : AppColors.background,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSel
                            ? AppColors.primary
                            : AppColors.divider,
                      ),
                    ),
                    child: Text(d,
                        style: AppTextStyles.labelSmall.copyWith(
                          color: isSel
                              ? Colors.white
                              : AppColors.textSecondary,
                          fontWeight: isSel
                              ? FontWeight.w700
                              : FontWeight.w400,
                        )),
                  ),
                );
              }).toList(),
            ),
          ),

          // Slots
          Expanded(
            child: _selectedClass.isEmpty
                ? const SizedBox.shrink()
                : StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('timetable')
                        .where('className', isEqualTo: _selectedClass)
                        .where('day', isEqualTo: _selectedDay)
                        .orderBy('startTime')
                        .snapshots(),
                    builder: (context, snap) {
                      if (snap.connectionState == ConnectionState.waiting) {
                        return const Center(
                            child: CircularProgressIndicator());
                      }
                      if (!snap.hasData || snap.data!.docs.isEmpty) {
                        return Center(
                          child: Text(
                            'No classes on $_selectedDay for $_selectedClass.',
                            style: AppTextStyles.bodyMedium
                                .copyWith(color: AppColors.textSecondary),
                            textAlign: TextAlign.center,
                          ),
                        );
                      }

                      return ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                        itemCount: snap.data!.docs.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 10),
                        itemBuilder: (context, i) {
                          final data = snap.data!.docs[i].data()
                              as Map<String, dynamic>;
                          return _SlotCard(
                            docId: snap.data!.docs[i].id,
                            subject: data['subject'] ?? '',
                            teacher: data['teacherName'] ?? '',
                            room: data['room'] ?? '',
                            start: data['startTime'] ?? '',
                            end: data['endTime'] ?? '',
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

  void _showAddSlotSheet(BuildContext context) {
    final subjectCtrl = TextEditingController();
    final teacherCtrl = TextEditingController();
    final roomCtrl = TextEditingController();
    final startCtrl = TextEditingController();
    final endCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool loading = false;

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
                Text('Add Time Slot', style: AppTextStyles.headingMedium),
                Text(
                  '$_selectedClass · $_selectedDay',
                  style: AppTextStyles.labelMedium,
                ),
                const SizedBox(height: 16),
                CustomTextField(label: 'Subject', controller: subjectCtrl,
                    validator: (v) => v == null || v.isEmpty ? 'Required' : null),
                const SizedBox(height: 12),
                CustomTextField(label: 'Teacher name', controller: teacherCtrl),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: CustomTextField(
                    label: 'Start time', hint: '08:00', controller: startCtrl,
                    validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                  )),
                  const SizedBox(width: 14),
                  Expanded(child: CustomTextField(
                    label: 'End time', hint: '09:00', controller: endCtrl,
                    validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                  )),
                ]),
                const SizedBox(height: 12),
                CustomTextField(label: 'Room', hint: 'Room 101', controller: roomCtrl),
                const SizedBox(height: 20),
                CustomButton(
                  label: 'Save Slot',
                  isLoading: loading,
                  gradient: AppColors.primaryGradient,
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;
                    setSS(() => loading = true);
                    await FirebaseFirestore.instance
                        .collection('timetable')
                        .add({
                      'className': _selectedClass,
                      'day': _selectedDay,
                      'subject': subjectCtrl.text.trim(),
                      'teacherName': teacherCtrl.text.trim(),
                      'startTime': startCtrl.text.trim(),
                      'endTime': endCtrl.text.trim(),
                      'room': roomCtrl.text.trim(),
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

class _SlotCard extends StatelessWidget {
  final String docId, subject, teacher, room, start, end;
  const _SlotCard({
    required this.docId, required this.subject, required this.teacher,
    required this.room, required this.start, required this.end,
  });

  @override
  Widget build(BuildContext context) {
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
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                Text(start, style: AppTextStyles.labelSmall
                    .copyWith(color: AppColors.primary, fontWeight: FontWeight.w700)),
                Text('–', style: AppTextStyles.labelTiny),
                Text(end, style: AppTextStyles.labelTiny
                    .copyWith(color: AppColors.primary)),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(subject, style: AppTextStyles.bodyMediumBold),
                const SizedBox(height: 3),
                Text('$teacher · $room', style: AppTextStyles.labelSmall),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded,
                color: AppColors.danger, size: 20),
            onPressed: () => FirebaseFirestore.instance
                .collection('timetable')
                .doc(docId)
                .delete(),
          ),
        ],
      ),
    );
  }
}