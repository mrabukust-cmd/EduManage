import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:school_management_system/core/theme/app_colors.dart';
import 'package:school_management_system/core/theme/app_text_style.dart';
import 'package:school_management_system/data/models/notice_model.dart';
import 'package:school_management_system/data/repositories/notice_repo.dart';
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
  final _repo = NoticeRepository.instance;

  @override
  Widget build(BuildContext context) {
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

          // ── Notices List (real Firestore data) ───────────────
          Expanded(
            child: StreamBuilder<List<NoticeModel>>(
              stream: _repo.watchAll(category: _selectedCat),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting && !snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snap.hasError) {
                  return Center(
                    child: Text('Failed to load notices', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
                  );
                }
                final notices = snap.data ?? [];
                if (notices.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.campaign_outlined, size: 64, color: AppColors.textHint),
                        const SizedBox(height: 16),
                        Text('No notices yet.\nTap + to add one.', textAlign: TextAlign.center,
                            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
                      ],
                    ),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: notices.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 14),
                  itemBuilder: (_, i) => _NoticeCard(notice: notices[i], onDelete: () => _repo.delete(notices[i].id)),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showAddNoticeSheet(BuildContext context) {
    final titleCtrl = TextEditingController();
    final bodyCtrl = TextEditingController();
    String category = 'General';
    bool loading = false;
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardBg,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (sheetCtx) => StatefulBuilder(
        builder: (sheetCtx, setSheet) => Padding(
          padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(sheetCtx).viewInsets.bottom + 20),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.divider, borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 20),
                Text('Add Notice', style: AppTextStyles.headingMedium),
                const SizedBox(height: 16),
                TextFormField(
                  controller: titleCtrl,
                  decoration: _inputDecor('Title'),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: bodyCtrl,
                  maxLines: 3,
                  decoration: _inputDecor('Description'),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: category,
                  decoration: _inputDecor('Category'),
                  items: const ['General', 'Event', 'Exam', 'Finance', 'Holiday']
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (v) => setSheet(() => category = v ?? 'General'),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: loading
                        ? null
                        : () async {
                            if (!formKey.currentState!.validate()) return;
                            setSheet(() => loading = true);
                            await _repo.create(NoticeModel(
                              id: '',
                              title: titleCtrl.text.trim(),
                              body: bodyCtrl.text.trim(),
                              category: category,
                              author: 'Admin',
                            ));
                            if (sheetCtx.mounted) Navigator.pop(sheetCtx);
                          },
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    child: loading
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Text('Publish Notice', style: AppTextStyles.bodyMediumBold.copyWith(color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
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
  final VoidCallback onDelete;
  const _NoticeCard({required this.notice, required this.onDelete});

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
                Text(notice.dateLabel, style: AppTextStyles.labelTiny),
                PopupMenuButton<String>(
                  padding: EdgeInsets.zero,
                  icon: const Icon(Icons.more_vert_rounded, size: 18, color: AppColors.textHint),
                  onSelected: (v) {
                    if (v == 'delete') onDelete();
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'delete', child: Text('Delete')),
                  ],
                ),
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