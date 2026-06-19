import 'package:flutter/material.dart';
import 'package:school_management_system/core/theme/app_colors.dart';
import 'package:school_management_system/core/theme/app_text_style.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: Text('Reports', style: AppTextStyles.headingMedium.copyWith(color: Colors.white)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Overview', style: AppTextStyles.sectionTitle),
            const SizedBox(height: 16),
            Row(
              children: const [
                Expanded(child: _ReportCard(title: 'Attendance', value: '96%', color: AppColors.success)),
                SizedBox(width: 12),
                Expanded(child: _ReportCard(title: 'Average Grades', value: 'B+', color: AppColors.primary)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: const [
                Expanded(child: _ReportCard(title: 'New Students', value: '12', color: AppColors.studentColor)),
                SizedBox(width: 12),
                Expanded(child: _ReportCard(title: 'Teacher Load', value: '24 classes', color: AppColors.teacherColor)),
              ],
            ),
            const SizedBox(height: 24),
            Text('Monthly highlights', style: AppTextStyles.sectionTitle),
            const SizedBox(height: 12),
            const _ReportListItem(title: 'Student performance improved by 8%', subtitle: 'Based on recent exam results'),
            const _ReportListItem(title: 'Attendance remained above 92%', subtitle: 'Across all grades'),
            const _ReportListItem(title: '3 new classes created', subtitle: 'For STEM and arts programs'),
            const _ReportListItem(title: 'Parent-teacher meetings scheduled', subtitle: 'Next week, 4 sessions'),
          ],
        ),
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;
  const _ReportCard({required this.title, required this.value, required this.color});

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
          Text(title, style: AppTextStyles.labelSmall.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 14),
          Text(value, style: AppTextStyles.headingLarge.copyWith(color: color)),
        ],
      ),
    );
  }
}

class _ReportListItem extends StatelessWidget {
  final String title;
  final String subtitle;
  const _ReportListItem({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(14),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.bodyMediumBold),
          const SizedBox(height: 6),
          Text(subtitle, style: AppTextStyles.labelSmall.copyWith(color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}
