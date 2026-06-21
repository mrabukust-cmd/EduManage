import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:school_management_system/core/theme/app_colors.dart';
import 'package:school_management_system/core/theme/app_text_style.dart';
import 'package:school_management_system/core/widgets/custom_button.dart';
import 'package:school_management_system/core/widgets/custom_text_field.dart';

// ── Place this file at:
// lib/features/admin/fees/fee_management_screen.dart
//
// Firestore collection: 'fees'
// Document fields:
//   { studentId, studentName, className, month, year,
//     amount, status: 'paid'|'pending'|'overdue',
//     paidAt: Timestamp|null, createdAt: Timestamp }
//
// Update route in app_router.dart:
//   GoRoute(path: 'fees', builder: (_, __) => const FeeManagementScreen()),

class FeeManagementScreen extends StatefulWidget {
  const FeeManagementScreen({super.key});

  @override
  State<FeeManagementScreen> createState() => _FeeManagementScreenState();
}

class _FeeManagementScreenState extends State<FeeManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  String _searchQuery = '';
  final _searchCtrl = TextEditingController();

  static const _statuses = ['all', 'pending', 'paid', 'overdue'];
  String _statusFilter = 'all';

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

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
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
            onPressed: () => _showAddFeeSheet(context),
          ),
        ],
        bottom: TabBar(
          controller: _tab,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(text: 'Records'),
            Tab(text: 'Summary'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: [
          _RecordsTab(searchQuery: _searchQuery, statusFilter: _statusFilter,
              searchCtrl: _searchCtrl,
              onSearch: (v) => setState(() => _searchQuery = v.toLowerCase()),
              onFilter: (v) => setState(() => _statusFilter = v),
              statuses: _statuses),
          const _SummaryTab(),
        ],
      ),
    );
  }

  void _showAddFeeSheet(BuildContext context) {
    final studentCtrl = TextEditingController();
    final studentIdCtrl = TextEditingController();
    final classCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    final monthCtrl = TextEditingController(
        text: DateFormat('MMMM').format(DateTime.now()));
    final yearCtrl = TextEditingController(
        text: DateTime.now().year.toString());
    String status = 'pending';
    bool loading = false;
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardBg,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (sheetCtx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: EdgeInsets.only(
            left: 20, right: 20, top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(width: 40, height: 4,
                    decoration: BoxDecoration(color: AppColors.divider,
                        borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 20),
                Text('Add Fee Record', style: AppTextStyles.headingMedium),
                const SizedBox(height: 16),
                // Student name + ID row
                Row(children: [
                  Expanded(child: CustomTextField(label: 'Student Name',
                      controller: studentCtrl,
                      validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Required' : null)),
                  const SizedBox(width: 12),
                  Expanded(child: CustomTextField(label: 'Student UID',
                      hint: 'From Firestore',
                      controller: studentIdCtrl,
                      validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Required' : null)),
                ]),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: CustomTextField(label: 'Class',
                      controller: classCtrl,
                      validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Required' : null)),
                  const SizedBox(width: 12),
                  Expanded(child: CustomTextField(label: 'Amount (Rs.)',
                      controller: amountCtrl,
                      keyboardType: TextInputType.number,
                      validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Required' : null)),
                ]),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: CustomTextField(label: 'Month',
                      controller: monthCtrl)),
                  const SizedBox(width: 12),
                  Expanded(child: CustomTextField(label: 'Year',
                      controller: yearCtrl,
                      keyboardType: TextInputType.number)),
                ]),
                const SizedBox(height: 12),
                // Status selector
                Text('Status', style: AppTextStyles.labelMedium),
                const SizedBox(height: 8),
                Row(children: ['pending', 'paid', 'overdue'].map((s) {
                  final selected = status == s;
                  return GestureDetector(
                    onTap: () => setSheet(() => status = s),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: selected
                            ? _statusColor(s).withOpacity(0.15)
                            : AppColors.background,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: selected
                              ? _statusColor(s)
                              : AppColors.divider,
                          width: selected ? 1.5 : 1,
                        ),
                      ),
                      child: Text(s[0].toUpperCase() + s.substring(1),
                          style: AppTextStyles.labelSmall.copyWith(
                            color: selected
                                ? _statusColor(s)
                                : AppColors.textSecondary,
                            fontWeight: selected
                                ? FontWeight.w700
                                : FontWeight.w400,
                          )),
                    ),
                  );
                }).toList()),
                const SizedBox(height: 20),
                CustomButton(
                  label: 'Save Fee Record',
                  isLoading: loading,
                  gradient: const LinearGradient(
                      colors: [Color(0xFFF59E0B), Color(0xFFD97706)]),
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;
                    setSheet(() => loading = true);
                    await FirebaseFirestore.instance.collection('fees').add({
                      'studentId': studentIdCtrl.text.trim(),
                      'studentName': studentCtrl.text.trim(),
                      'className': classCtrl.text.trim(),
                      'amount': double.tryParse(amountCtrl.text.trim()) ?? 0,
                      'month': monthCtrl.text.trim(),
                      'year': int.tryParse(yearCtrl.text.trim()) ??
                          DateTime.now().year,
                      'status': status,
                      'paidAt': status == 'paid'
                          ? FieldValue.serverTimestamp()
                          : null,
                      'createdAt': FieldValue.serverTimestamp(),
                    });
                    if (ctx.mounted) Navigator.pop(ctx);
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

// ── Records tab ───────────────────────────────────────────────────────────────
class _RecordsTab extends StatelessWidget {
  final String searchQuery, statusFilter;
  final TextEditingController searchCtrl;
  final ValueChanged<String> onSearch, onFilter;
  final List<String> statuses;

  const _RecordsTab({
    required this.searchQuery,
    required this.statusFilter,
    required this.searchCtrl,
    required this.onSearch,
    required this.onFilter,
    required this.statuses,
  });

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      // Search bar
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        child: TextField(
          controller: searchCtrl,
          onChanged: onSearch,
          decoration: InputDecoration(
            hintText: 'Search by student name...',
            prefixIcon: const Icon(Icons.search_rounded,
                color: AppColors.textHint),
            filled: true,
            fillColor: AppColors.cardBg,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.divider)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.divider)),
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ),
      // Status filter chips
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
        child: SizedBox(
          height: 34,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: statuses.map((s) {
              final isSel = statusFilter == s;
              final color = s == 'all'
                  ? AppColors.textSecondary
                  : _statusColor(s);
              return GestureDetector(
                onTap: () => onFilter(s),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSel ? color.withOpacity(0.12) : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: isSel ? color : AppColors.divider),
                  ),
                  child: Text(
                    s == 'all' ? 'All' : s[0].toUpperCase() + s.substring(1),
                    style: AppTextStyles.labelSmall.copyWith(
                      color: isSel ? color : AppColors.textSecondary,
                      fontWeight:
                      isSel ? FontWeight.w700 : FontWeight.w400,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
      // List
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
            final docs = snap.data?.docs ?? [];
            final filtered = docs.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final name = (data['studentName'] as String? ?? '')
                  .toLowerCase();
              final status = data['status'] as String? ?? '';
              final matchName = name.contains(searchQuery);
              final matchStatus =
                  statusFilter == 'all' || status == statusFilter;
              return matchName && matchStatus;
            }).toList();

            if (filtered.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.receipt_long_outlined,
                        size: 64, color: AppColors.textHint),
                    const SizedBox(height: 16),
                    Text('No fee records found',
                        style: AppTextStyles.bodyMedium
                            .copyWith(color: AppColors.textSecondary)),
                  ],
                ),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 100),
              itemCount: filtered.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final data =
                filtered[i].data() as Map<String, dynamic>;
                return _FeeCard(
                  docId: filtered[i].id,
                  data: data,
                );
              },
            );
          },
        ),
      ),
    ]);
  }
}

// ── Fee card ──────────────────────────────────────────────────────────────────
class _FeeCard extends StatelessWidget {
  final String docId;
  final Map<String, dynamic> data;
  const _FeeCard({required this.docId, required this.data});

  @override
  Widget build(BuildContext context) {
    final status = data['status'] as String? ?? 'pending';
    final color = _statusColor(status);
    final amount = (data['amount'] as num?)?.toDouble() ?? 0;
    final month = data['month'] as String? ?? '';
    final year = data['year'] as int? ?? DateTime.now().year;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(14),
        boxShadow: AppColors.cardShadow,
        border: Border(left: BorderSide(color: color, width: 4)),
      ),
      padding: const EdgeInsets.all(14),
      child: Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(data['studentName'] as String? ?? '',
                style: AppTextStyles.bodyMediumBold),
            const SizedBox(height: 4),
            Row(children: [
              _Chip(label: data['className'] as String? ?? '',
                  color: AppColors.primary),
              const SizedBox(width: 6),
              _Chip(label: '$month $year', color: AppColors.textSecondary),
            ]),
          ]),
        ),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('Rs. ${amount.toStringAsFixed(0)}',
              style: AppTextStyles.bodyMediumBold
                  .copyWith(color: AppColors.textPrimary)),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20)),
            child: Text(status[0].toUpperCase() + status.substring(1),
                style: AppTextStyles.labelTiny
                    .copyWith(color: color, fontWeight: FontWeight.w700)),
          ),
          if (status == 'pending' || status == 'overdue') ...[
            const SizedBox(height: 6),
            GestureDetector(
              onTap: () => FirebaseFirestore.instance
                  .collection('fees')
                  .doc(docId)
                  .update({
                'status': 'paid',
                'paidAt': FieldValue.serverTimestamp(),
              }),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: AppColors.success.withOpacity(0.4))),
                child: Text('Mark Paid',
                    style: AppTextStyles.labelTiny.copyWith(
                        color: AppColors.success,
                        fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ]),
      ]),
    );
  }
}

// ── Summary tab ───────────────────────────────────────────────────────────────
class _SummaryTab extends StatelessWidget {
  const _SummaryTab();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('fees').snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snap.data?.docs ?? [];

        double totalCollected = 0, totalPending = 0, totalOverdue = 0;
        int paidCount = 0, pendingCount = 0, overdueCount = 0;

        for (final doc in docs) {
          final data = doc.data() as Map<String, dynamic>;
          final amount = (data['amount'] as num?)?.toDouble() ?? 0;
          final status = data['status'] as String? ?? 'pending';
          switch (status) {
            case 'paid':
              totalCollected += amount;
              paidCount++;
              break;
            case 'pending':
              totalPending += amount;
              pendingCount++;
              break;
            case 'overdue':
              totalOverdue += amount;
              overdueCount++;
              break;
          }
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Big collected card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [Color(0xFF22C55E), Color(0xFF16A34A)]),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: AppColors.cardShadow,
                ),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Total Collected',
                          style: AppTextStyles.labelMedium
                              .copyWith(color: Colors.white70)),
                      const SizedBox(height: 8),
                      Text('Rs. ${_fmt(totalCollected)}',
                          style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 32,
                              fontWeight: FontWeight.w700,
                              color: Colors.white)),
                      const SizedBox(height: 4),
                      Text('$paidCount payments received',
                          style: AppTextStyles.labelSmall
                              .copyWith(color: Colors.white60)),
                    ]),
              ),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(child: _SummaryCard(
                    label: 'Pending',
                    amount: totalPending,
                    count: pendingCount,
                    color: AppColors.warning)),
                const SizedBox(width: 12),
                Expanded(child: _SummaryCard(
                    label: 'Overdue',
                    amount: totalOverdue,
                    count: overdueCount,
                    color: AppColors.danger)),
              ]),
              const SizedBox(height: 24),
              Text('Collection rate', style: AppTextStyles.sectionTitle),
              const SizedBox(height: 12),
              _CollectionBar(
                  paid: totalCollected,
                  pending: totalPending,
                  overdue: totalOverdue),
              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }

  String _fmt(double v) => NumberFormat('#,##0').format(v);
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final double amount;
  final int count;
  final Color color;
  const _SummaryCard({
    required this.label,
    required this.amount,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppColors.cardShadow),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label,
            style: AppTextStyles.labelSmall.copyWith(color: color)),
        const SizedBox(height: 8),
        Text('Rs. ${NumberFormat('#,##0').format(amount)}',
            style: AppTextStyles.bodyMediumBold),
        const SizedBox(height: 4),
        Text('$count records',
            style: AppTextStyles.labelTiny),
      ]),
    );
  }
}

class _CollectionBar extends StatelessWidget {
  final double paid, pending, overdue;
  const _CollectionBar(
      {required this.paid, required this.pending, required this.overdue});

  @override
  Widget build(BuildContext context) {
    final total = paid + pending + overdue;
    if (total == 0) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppColors.cardShadow),
      child: Column(children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: SizedBox(
            height: 12,
            child: Row(children: [
              if (paid > 0)
                Flexible(
                    flex: (paid / total * 100).round(),
                    child: Container(color: AppColors.success)),
              if (pending > 0)
                Flexible(
                    flex: (pending / total * 100).round(),
                    child: Container(color: AppColors.warning)),
              if (overdue > 0)
                Flexible(
                    flex: (overdue / total * 100).round(),
                    child: Container(color: AppColors.danger)),
            ]),
          ),
        ),
        const SizedBox(height: 14),
        Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
          _LegendItem(color: AppColors.success, label: 'Paid',
              pct: paid / total),
          _LegendItem(color: AppColors.warning, label: 'Pending',
              pct: pending / total),
          _LegendItem(color: AppColors.danger, label: 'Overdue',
              pct: overdue / total),
        ]),
      ]),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final double pct;
  const _LegendItem(
      {required this.color, required this.label, required this.pct});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(width: 10, height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 6),
      Text('$label ${(pct * 100).toStringAsFixed(0)}%',
          style: AppTextStyles.labelTiny),
    ]);
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color color;
  const _Chip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20)),
      child: Text(label,
          style: AppTextStyles.labelTiny
              .copyWith(color: color, fontWeight: FontWeight.w600)),
    );
  }
}

Color _statusColor(String status) {
  switch (status) {
    case 'paid':
      return AppColors.success;
    case 'overdue':
      return AppColors.danger;
    default:
      return AppColors.warning;
  }
}