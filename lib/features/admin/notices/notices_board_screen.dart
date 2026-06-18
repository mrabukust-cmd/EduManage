import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:school_management_system/core/theme/app_colors.dart';
import 'package:school_management_system/core/theme/app_text_style.dart';


// ── Model ─────────────────────────────────────────────────────────────────────
class NoticeModel {
  final String id, title, body, date, author, category;
  const NoticeModel({required this.id, required this.title, required this.body, required this.date, required this.author, required this.category});
}

const _notices = [
  NoticeModel(id: '1', title: 'Annual Sports Day', body: 'Annual Sports Day is scheduled for June 20, 2025. All students are required to participate. Parents are welcome to attend. Uniform is compulsory.', date: 'Jun 16', author: 'Admin', category: 'Event'),
  NoticeModel(id: '2', title: 'Mid-Term Exam Schedule', body: 'Mid-term exams will begin from June 24. Timetable is available on the school portal. Students are advised to prepare accordingly.', date: 'Jun 14', author: 'Academic Department', category: 'Exam'),
  NoticeModel(id: '3', title: 'Fee Submission Deadline', body: 'Last date for fee submission for June is June 20, 2025. Late submissions will incur a fine of Rs. 200/day.', date: 'Jun 12', author: 'Accounts', category: 'Finance'),
  NoticeModel(id: '4', title: 'Holiday Notification', body: 'School will remain closed on June 23 on account of Eid-ul-Adha. Classes will resume from June 27.', date: 'Jun 10', author: 'Admin', category: 'Holiday'),
];

const _categoryColors = {
  'Event':   Color(0xFF7C3AED),
  'Exam':    Color(0xFF1A56DB),
  'Finance': Color(0xFFE67E22),
  'Holiday': Color(0xFF059669),
  'General': Color(0xFF6B7280),
};

// ── Notice Board Screen ───────────────────────────────────────────────────────
class NoticeBoardScreen extends StatefulWidget {
  const NoticeBoardScreen({super.key});

  @override
  State<NoticeBoardScreen> createState() => _NoticeBoardScreenState();
}

class _NoticeBoardScreenState extends State<NoticeBoardScreen> {
  String _selectedCat = 'All';
  final _cats = ['All', 'Event', 'Exam', 'Finance', 'Holiday'];

  @override
  Widget build(BuildContext context) {
    final filtered = _selectedCat == 'All'
        ? _notices
        : _notices.where((n) => n.category == _selectedCat).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.accent,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white), onPressed: () => context.pop()),
        title: Text('Notice Board', style: AppTextStyles.headingMedium.copyWith(color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
            onPressed: () => _showAddNoticeSheet(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Category Filter ─────────────────────────────────
          Container(
            color: AppColors.accent,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
            child: SizedBox(
              height: 36,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: _cats.map((c) {
                  final isSel = _selectedCat == c;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedCat = c),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(color: isSel ? Colors.white : Colors.white24, borderRadius: BorderRadius.circular(20)),
                      child: Text(c, style: AppTextStyles.labelSmall.copyWith(color: isSel ? AppColors.accent : Colors.white, fontWeight: isSel ? FontWeight.w700 : FontWeight.w400)),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // ── Notices List ────────────────────────────────────
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: filtered.length,
              separatorBuilder: (_, __) => const SizedBox(height: 14),
              itemBuilder: (_, i) => _NoticeCard(notice: filtered[i]),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddNoticeSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardBg,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(context).viewInsets.bottom + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.divider, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 20),
            Text('Add Notice', style: AppTextStyles.headingMedium),
            const SizedBox(height: 16),
            TextField(decoration: _inputDecor('Title')),
            const SizedBox(height: 12),
            TextField(maxLines: 3, decoration: _inputDecor('Description')),
            const SizedBox(height: 12),
            TextField(decoration: _inputDecor('Category (Event / Exam / Finance / Holiday)')),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: Text('Publish Notice', style: AppTextStyles.bodyMediumBold.copyWith(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecor(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: AppTextStyles.labelMedium,
    filled: true,
    fillColor: AppColors.background,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
  );
}

// ── Notice Card ───────────────────────────────────────────────────────────────
class _NoticeCard extends StatelessWidget {
  final NoticeModel notice;
  const _NoticeCard({required this.notice});

  @override
  Widget build(BuildContext context) {
    final color = _categoryColors[notice.category] ?? const Color(0xFF6B7280);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppColors.cardShadow,
        border: Border(left: BorderSide(color: color, width: 4)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                  child: Text(notice.category, style: AppTextStyles.labelTiny.copyWith(color: color, fontWeight: FontWeight.w700)),
                ),
                const Spacer(),
                Text(notice.date, style: AppTextStyles.labelTiny),
              ],
            ),
            const SizedBox(height: 10),
            Text(notice.title, style: AppTextStyles.bodyMediumBold),
            const SizedBox(height: 6),
            Text(notice.body, style: AppTextStyles.labelSmall, maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 10),
            Text('— ${notice.author}', style: AppTextStyles.labelTiny.copyWith(fontStyle: FontStyle.italic)),
          ],
        ),
      ),
    );
  }
}