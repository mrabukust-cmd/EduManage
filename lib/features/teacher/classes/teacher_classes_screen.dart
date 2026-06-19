import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:school_management_system/core/theme/app_colors.dart';
import 'package:school_management_system/core/theme/app_text_style.dart';

class TeacherClassesScreen extends StatelessWidget {
  const TeacherClassesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.teacherColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('My Classes', style: AppTextStyles.headingMedium.copyWith(color: Colors.white)),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('classes').orderBy('name').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text(
                'No classes available yet.',
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
              ),
            );
          }

          final docs = snapshot.data!.docs;
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final name = data['name'] as String? ?? 'Unknown Class';
              final section = data['section'] as String? ?? '-';
              final teacherName = data['classTeacher'] as String? ?? 'Unassigned';
              return _ClassTile(
                name: name,
                section: section,
                teacherName: teacherName,
                studentCount: 0,
                docId: docs[index].id,
              );
            },
          );
        },
      ),
    );
  }
}

class _ClassTile extends StatelessWidget {
  final String name;
  final String section;
  final String teacherName;
  final int studentCount;
  final String docId;

  const _ClassTile({
    required this.name,
    required this.section,
    required this.teacherName,
    required this.studentCount,
    required this.docId,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(18),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(name, style: AppTextStyles.bodyMediumBold),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.layers_rounded, size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              Text('Section $section', style: AppTextStyles.labelSmall),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.person_rounded, size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              Expanded(child: Text('Teacher: $teacherName', style: AppTextStyles.labelSmall)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.class_rounded, size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              Text('$studentCount students', style: AppTextStyles.labelSmall),
            ],
          ),
        ],
      ),
    );
  }
}
