// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:go_router/go_router.dart';
// import 'package:school_management_system/core/theme/app_colors.dart';
// import 'package:school_management_system/core/theme/app_text_style.dart';
// import 'package:school_management_system/features/auth/providers/auth_provider.dart';

// class AdminHomeScreen extends ConsumerWidget {
//   const AdminHomeScreen({super.key});

//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     final user = ref.watch(authProvider).user;

//     return Scaffold(
//       backgroundColor: AppColors.background,
//       body: SafeArea(
//         child: CustomScrollView(
//           slivers: [
//             // ── Header ──────────────────────────────────────────
//             SliverToBoxAdapter(
//               child: _AdminHeader(userName: user?.displayName ?? 'Admin'),
//             ),

//             // ── Stats Row ────────────────────────────────────────
//             SliverToBoxAdapter(
//               child: Padding(
//                 padding: const EdgeInsets.symmetric(horizontal: 20),
//                 child: Row(
//                   children: [
//                     Expanded(
//                       child: StreamBuilder<QuerySnapshot>(
//                         stream: FirebaseFirestore.instance.collection('students').snapshots(),
//                         builder: (context, snap) {
//                           final count = snap.hasData ? snap.data!.docs.length : null;
//                           return _StatCard(
//                             label: 'Students',
//                             value: count?.toString() ?? '...',
//                             icon: Icons.school_rounded,
//                             color: AppColors.studentColor,
//                           );
//                         },
//                       ),
//                     ),
//                     const SizedBox(width: 12),
//                     Expanded(
//                       child: StreamBuilder<QuerySnapshot>(
//                         stream: FirebaseFirestore.instance.collection('teachers').snapshots(),
//                         builder: (context, snap) {
//                           final count = snap.hasData ? snap.data!.docs.length : null;
//                           return _StatCard(
//                             label: 'Teachers',
//                             value: count?.toString() ?? '...',
//                             icon: Icons.person_rounded,
//                             color: AppColors.teacherColor,
//                           );
//                         },
//                       ),
//                     ),
//                     const SizedBox(width: 12),
//                     Expanded(
//                       child: StreamBuilder<QuerySnapshot>(
//                         stream: FirebaseFirestore.instance.collection('classes').snapshots(),
//                         builder: (context, snap) {
//                           final count = snap.hasData ? snap.data!.docs.length : null;
//                           return _StatCard(
//                             label: 'Classes',
//                             value: count?.toString() ?? '...',
//                             icon: Icons.class_rounded,
//                             color: AppColors.adminColor,
//                           );
//                         },
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),

//             const SliverToBoxAdapter(child: SizedBox(height: 28)),

//             // ── Quick Actions ────────────────────────────────────
//             SliverToBoxAdapter(
//               child: Padding(
//                 padding: const EdgeInsets.symmetric(horizontal: 20),
//                 child: Text('Quick Actions', style: AppTextStyles.sectionTitle),
//               ),
//             ),
//             const SliverToBoxAdapter(child: SizedBox(height: 14)),
//             SliverToBoxAdapter(
//               child: Padding(
//                 padding: const EdgeInsets.symmetric(horizontal: 20),
//                 child: GridView.count(
//                   crossAxisCount: 3,
//                   shrinkWrap: true,
//                   physics: const NeverScrollableScrollPhysics(),
//                   mainAxisSpacing: 14,
//                   crossAxisSpacing: 14,
//                   children: [
//                     _QuickAction(icon: Icons.person_add_rounded, label: 'Add Student', color: AppColors.studentColor, onTap: () => context.push('/admin/home/students/add')),
//                     _QuickAction(icon: Icons.person_add_alt_1_rounded, label: 'Add Teacher', color: AppColors.teacherColor, onTap: () => context.push('/admin/home/teachers/add')),
//                     _QuickAction(icon: Icons.class_rounded, label: 'Manage Classes', color: AppColors.adminColor, onTap: () => context.push('/admin/home/classes')),
//                     _QuickAction(icon: Icons.calendar_month_rounded, label: 'Timetable', color: AppColors.primary, onTap: () => context.push('/admin/home/timetable')),
//                     _QuickAction(icon: Icons.attach_money_rounded, label: 'Fees', color: AppColors.warning, onTap: () => context.push('/admin/home/fees')),
//                     _QuickAction(icon: Icons.announcement_rounded, label: 'Notices', color: AppColors.accent, onTap: () => context.push('/admin/home/notices')),
//                   ],
//                 ),
//               ),
//             ),

//             const SliverToBoxAdapter(child: SizedBox(height: 28)),

//             // ── Recent Activity ──────────────────────────────────
//             SliverToBoxAdapter(
//               child: Padding(
//                 padding: const EdgeInsets.symmetric(horizontal: 20),
//                 child: Text('Recent Activity', style: AppTextStyles.sectionTitle),
//               ),
//             ),
//             const SliverToBoxAdapter(child: SizedBox(height: 14)),
//             SliverList(
//               delegate: SliverChildListDelegate([
//                 _ActivityItem(icon: Icons.person_add_rounded, color: AppColors.studentColor, title: 'New student enrolled', subtitle: 'Ali Khan — Grade 9A', time: '2 min ago'),
//                 _ActivityItem(icon: Icons.payment_rounded, color: AppColors.success, title: 'Fee payment received', subtitle: 'Sara Noor — Rs 5,000', time: '15 min ago'),
//                 _ActivityItem(icon: Icons.announcement_rounded, color: AppColors.accent, title: 'Notice published', subtitle: 'Annual Sports Day – June 20', time: '1 hr ago'),
//                 _ActivityItem(icon: Icons.cancel_rounded, color: AppColors.danger, title: 'Absence reported', subtitle: 'Grade 8B — 3 students', time: '2 hr ago'),
//                 const SizedBox(height: 32),
//               ]),
//             ),
//           ],
//         ),
//       ),

//       // ── Bottom Nav ──────────────────────────────────────────────
//       bottomNavigationBar: const _AdminBottomNav(currentIndex: 0),
//     );
//   }
// }

// // ── Header ──────────────────────────────────────────────────────────────────
// class _AdminHeader extends StatelessWidget {
//   final String userName;
//   const _AdminHeader({required this.userName});

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
//       decoration: const BoxDecoration(
//         gradient: AppColors.primaryGradient,
//         borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text('Good Morning,', style: AppTextStyles.labelMedium.copyWith(color: Colors.white70)),
//                   const SizedBox(height: 4),
//                   Text(userName, style: AppTextStyles.headingLarge.copyWith(color: Colors.white)),
//                 ],
//               ),
//               CircleAvatar(
//                 radius: 24,
//                 backgroundColor: Colors.white24,
//                 child: const Icon(Icons.admin_panel_settings_rounded, color: Colors.white, size: 26),
//               ),
//             ],
//           ),
//           const SizedBox(height: 20),
//           // Search Bar
//           Container(
//             padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//             decoration: BoxDecoration(
//               color: Colors.white.withOpacity(0.15),
//               borderRadius: BorderRadius.circular(14),
//               border: Border.all(color: Colors.white24),
//             ),
//             child: Row(
//               children: [
//                 const Icon(Icons.search_rounded, color: Colors.white70, size: 20),
//                 const SizedBox(width: 10),
//                 Text('Search students, teachers...', style: AppTextStyles.bodyMedium.copyWith(color: Colors.white60)),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// // ── Stat Card ───────────────────────────────────────────────────────────────
// class _StatCard extends StatelessWidget {
//   final String label, value;
//   final IconData icon;
//   final Color color;
//   const _StatCard({required this.label, required this.value, required this.icon, required this.color});

//   @override
//   Widget build(BuildContext context) {
//     return Expanded(
//       child: Container(
//         padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
//         decoration: BoxDecoration(
//           color: AppColors.cardBg,
//           borderRadius: BorderRadius.circular(16),
//           boxShadow: AppColors.cardShadow,
//         ),
//         child: Column(
//           children: [
//             Container(
//               padding: const EdgeInsets.all(8),
//               decoration: BoxDecoration(color: color.withOpacity(0.12), shape: BoxShape.circle),
//               child: Icon(icon, color: color, size: 20),
//             ),
//             const SizedBox(height: 8),
//             Text(value, style: AppTextStyles.statValue),
//             const SizedBox(height: 2),
//             Text(label, style: AppTextStyles.labelSmall, textAlign: TextAlign.center),
//           ],
//         ),
//       ),
//     );
//   }
// }

// // ── Quick Action ────────────────────────────────────────────────────────────
// class _QuickAction extends StatelessWidget {
//   final IconData icon;
//   final String label;
//   final Color color;
//   final VoidCallback onTap;
//   const _QuickAction({required this.icon, required this.label, required this.color, required this.onTap});

//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       onTap: onTap,
//       child: Container(
//         decoration: BoxDecoration(
//           color: AppColors.cardBg,
//           borderRadius: BorderRadius.circular(16),
//           boxShadow: AppColors.cardShadow,
//         ),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Container(
//               padding: const EdgeInsets.all(12),
//               decoration: BoxDecoration(color: color.withOpacity(0.12), shape: BoxShape.circle),
//               child: Icon(icon, color: color, size: 24),
//             ),
//             const SizedBox(height: 8),
//             Text(label, style: AppTextStyles.labelSmall, textAlign: TextAlign.center),
//           ],
//         ),
//       ),
//     );
//   }
// }

// // ── Activity Item ────────────────────────────────────────────────────────────
// class _ActivityItem extends StatelessWidget {
//   final IconData icon;
//   final Color color;
//   final String title, subtitle, time;
//   const _ActivityItem({required this.icon, required this.color, required this.title, required this.subtitle, required this.time});

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
//       padding: const EdgeInsets.all(14),
//       decoration: BoxDecoration(
//         color: AppColors.cardBg,
//         borderRadius: BorderRadius.circular(14),
//         boxShadow: AppColors.cardShadow,
//       ),
//       child: Row(
//         children: [
//           Container(
//             padding: const EdgeInsets.all(8),
//             decoration: BoxDecoration(color: color.withOpacity(0.12), shape: BoxShape.circle),
//             child: Icon(icon, color: color, size: 18),
//           ),
//           const SizedBox(width: 12),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(title, style: AppTextStyles.bodyMediumBold),
//                 const SizedBox(height: 2),
//                 Text(subtitle, style: AppTextStyles.labelSmall),
//               ],
//             ),
//           ),
//           Text(time, style: AppTextStyles.labelTiny),
//         ],
//       ),
//     );
//   }
// }

// // ── Bottom Nav ───────────────────────────────────────────────────────────────
// class _AdminBottomNav extends StatelessWidget {
//   final int currentIndex;
//   const _AdminBottomNav({required this.currentIndex});

//   @override
//   Widget build(BuildContext context) {
//     return BottomNavigationBar(
//       currentIndex: currentIndex,
//       type: BottomNavigationBarType.fixed,
//       selectedItemColor: AppColors.primary,
//       unselectedItemColor: AppColors.textSecondary,
//       backgroundColor: AppColors.cardBg,
//       elevation: 12,
//       selectedLabelStyle: AppTextStyles.navLabel,
//       unselectedLabelStyle: AppTextStyles.navLabel,
//       onTap: (i) {
//         switch (i) {
//           case 0: context.go('/admin/home'); break;
//           case 1: context.go('/admin/home/students'); break;
//           case 2: context.go('/admin/home/teachers'); break;
//           case 3: context.go('/admin/home/reports'); break;
//           case 4: context.go('/admin/home/settings'); break;
//         }
//       },
//       items: const [
//         BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Home'),
//         BottomNavigationBarItem(icon: Icon(Icons.school_rounded), label: 'Students'),
//         BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'Teachers'),
//         BottomNavigationBarItem(icon: Icon(Icons.bar_chart_rounded), label: 'Reports'),
//         BottomNavigationBarItem(icon: Icon(Icons.settings_rounded), label: 'Settings'),
//       ],
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:school_management_system/core/theme/app_colors.dart';
import 'package:school_management_system/features/auth/providers/auth_provider.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();

  String _selectedRole = 'student';

  late AnimationController _animController;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fade = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _slide = Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
        );

    Future.delayed(const Duration(milliseconds: 100), () {
      _animController.forward();
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmPassCtrl.dispose();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    final notifier = ref.read(authProvider.notifier);
    final error = await notifier.register(
      name: _nameCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      password: _passCtrl.text,
      role: _selectedRole,
    );

    if (error != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.divider),
            ),
            child: const Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 16,
              color: AppColors.textPrimary,
            ),
          ),
          onPressed: () => context.pop(),
        ),
      ),
      body: SlideTransition(
        position: _slide,
        child: FadeTransition(
          opacity: _fade,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Header ───────────────────────────────────
                  const Text(
                    'Create Account',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Join EduManage and get started today',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // ── Role selection ───────────────────────────
                  // ── Role selection ───────────────────────────
                  const Text(
                    'I am a',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _buildRoleCard(
                        role: 'teacher',
                        label: 'Teacher',
                        icon: Icons.cast_for_education_rounded,
                        color: AppColors.teacherColor,
                        gradient: AppColors.teacherGradient,
                      ),
                      const SizedBox(width: 10),
                      _buildRoleCard(
                        role: 'student',
                        label: 'Student',
                        icon: Icons.menu_book_rounded,
                        color: AppColors.studentColor,
                        gradient: AppColors.studentGradient,
                      ),
                      const SizedBox(width: 10),
                      _buildRoleCard(
                        role: 'parent',
                        label: 'Parent',
                        icon: Icons.family_restroom_rounded,
                        color: AppColors.accent,
                        gradient: AppColors.primaryGradient,
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  Row(
                    children: [
                      _buildRoleCard(
                        role: 'parent',
                        label: 'Parent',
                        icon: Icons.family_restroom_rounded,
                        color: AppColors.accent,
                        gradient: AppColors.primaryGradient,
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),

                  // ── Form fields ──────────────────────────────
                  CustomTextField(
                    label: 'Full Name',
                    hint: 'Muhammad Abubakar',
                    controller: _nameCtrl,
                    prefixIcon: Icons.person_outline_rounded,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Full name is required';
                      }
                      if (v.trim().length < 3) return 'Name too short';
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  CustomTextField(
                    label: 'Email Address',
                    hint: 'you@kust.edu.pk',
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    prefixIcon: Icons.email_outlined,
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Email is required';
                      if (!RegExp(
                        r'^[\w-\.]+@([\w-]+\.)+[\w]{2,4}$',
                      ).hasMatch(v)) {
                        return 'Enter a valid email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  CustomTextField(
                    label: 'Password',
                    hint: 'At least 6 characters',
                    controller: _passCtrl,
                    isPassword: true,
                    prefixIcon: Icons.lock_outline_rounded,
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Password is required';
                      if (v.length < 6) return 'Minimum 6 characters';
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  CustomTextField(
                    label: 'Confirm Password',
                    hint: 'Re-enter your password',
                    controller: _confirmPassCtrl,
                    isPassword: true,
                    prefixIcon: Icons.lock_outline_rounded,
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Please confirm';
                      if (v != _passCtrl.text) return 'Passwords do not match';
                      return null;
                    },
                  ),
                  const SizedBox(height: 32),

                  // ── Register button ──────────────────────────
                  CustomButton(
                    label: 'Create Account',
                    onPressed: _register,
                    isLoading: authState.isLoading,
                    gradient: _roleGradient(),
                  ),
                  const SizedBox(height: 20),

                  // ── Login link ───────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Already have an account? ',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => context.pop(),
                        child: const Text(
                          'Sign In',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Gradient _roleGradient() {
    switch (_selectedRole) {
      case 'admin':
        return AppColors.adminGradient;
      case 'teacher':
        return AppColors.teacherGradient;
      case 'parent':
        return AppColors.primaryGradient;
      default:
        return AppColors.studentGradient;
    }
  }

  Widget _buildRoleCard({
    required String role,
    required String label,
    required IconData icon,
    required Color color,
    required Gradient gradient,
  }) {
    final isSelected = _selectedRole == role;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedRole = role),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            gradient: isSelected ? gradient : null,
            color: isSelected ? null : AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? Colors.transparent : AppColors.divider,
              width: 1.5,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: color.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? Colors.white : color, size: 28),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
