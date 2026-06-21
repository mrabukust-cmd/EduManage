import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:school_management_system/core/theme/app_colors.dart';
import 'package:school_management_system/core/theme/app_text_style.dart';

class StudentNoticesScreen extends StatelessWidget {
  const StudentNoticesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.studentColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: Text('Notices',
            style: AppTextStyles.headingMedium.copyWith(color: Colors.white)),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('notices')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snap.hasData || snap.data!.docs.isEmpty) {
            return Center(
              child: Text('No notices yet.',
                  style: AppTextStyles.bodyMedium
                      .copyWith(color: AppColors.textSecondary)),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: snap.data!.docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              final data =
                  snap.data!.docs[i].data() as Map<String, dynamic>;
              final type = data['type'] as String? ?? 'general';
              final color = type == 'urgent'
                  ? AppColors.danger
                  : type == 'exam'
                      ? AppColors.warning
                      : AppColors.studentColor;

              return Container(
                decoration: BoxDecoration(
                  color: AppColors.cardBg,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: AppColors.cardShadow,
                  border: Border(left: BorderSide(color: color, width: 4)),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(type.toUpperCase(),
                              style: AppTextStyles.labelTiny.copyWith(
                                  color: color,
                                  fontWeight: FontWeight.w700)),
                        ),
                        const Spacer(),
                        Text(
                          data['createdAt'] != null
                              ? _formatDate(
                                  (data['createdAt'] as Timestamp).toDate())
                              : '',
                          style: AppTextStyles.labelTiny,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(data['title'] ?? '',
                        style: AppTextStyles.bodyMediumBold),
                    const SizedBox(height: 6),
                    Text(data['body'] ?? '',
                        style: AppTextStyles.labelSmall,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _formatDate(DateTime d) =>
      '${d.day} ${['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'][d.month - 1]}';
}