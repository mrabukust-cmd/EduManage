import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:school_management_system/core/router/route_names.dart';
import 'package:school_management_system/core/theme/app_colors.dart';
import 'package:school_management_system/core/theme/app_text_style.dart';
import 'package:school_management_system/core/widgets/custom_button.dart';
import 'package:school_management_system/features/auth/providers/auth_provider.dart';

/// Shown to a newly self-registered student / teacher / parent while their
/// account is awaiting admin approval (`users/{uid}.approved == false`).
///
/// THIS IS NOT THE ADMIN'S APPROVAL SCREEN. The admin-facing
/// approve/reject tool is `PendingApprovalsScreen`
/// (features/auth/screens/pending_approvel_screen.dart), mounted only at
/// `/admin/home/approvals`. Previously `/pending` pointed at that same
/// admin screen, which meant a freshly-registered parent landed on a
/// screen full of *other* users' approve/reject buttons instead of a
/// simple "please wait" message — this screen replaces that route.
///
/// Once an admin approves this user, AuthNotifier's role/approved state
/// flips on the next auth check and the router redirect in app_router.dart
/// sends them straight to their role's home screen — no manual refresh
/// needed here, but a refresh affordance is included anyway in case
/// Firestore listeners haven't fired yet.
class WaitingApprovalScreen extends ConsumerStatefulWidget {
  const WaitingApprovalScreen({super.key});

  @override
  ConsumerState<WaitingApprovalScreen> createState() => _WaitingApprovalScreenState();
}

class _WaitingApprovalScreenState extends ConsumerState<WaitingApprovalScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  bool _signingOut = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  /// Back button / "Back to Login" — signs the half-registered user out
  /// and sends them to /login. We can't just context.pop() here: this
  /// screen is reached via a router *redirect* (not a push), so there is
  /// nothing to pop back to, and even if there were, popping while still
  /// signed-in-but-pending would just bounce the redirect right back to
  /// /pending. Signing out is the only way to actually leave this state.
  Future<void> _backToLogin() async {
    setState(() => _signingOut = true);
    await ref.read(authProvider.notifier).signOut();
    if (mounted) context.go(RouteNames.login);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final role = authState.role ?? 'account';
    final roleLabel = switch (role) {
      'teacher' => 'teacher',
      'parent' => 'parent',
      _ => 'student',
    };

    return PopScope(
      // Hardware/gesture back behaves the same as the on-screen button —
      // sign out rather than doing nothing or crashing on an empty stack.
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _backToLogin();
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(28, 24, 28, 28),
            child: Column(
              children: [
                Align(
                  alignment: Alignment.topLeft,
                  child: IconButton(
                    onPressed: _signingOut ? null : _backToLogin,
                    icon: const Icon(Icons.arrow_back_ios_rounded,
                        color: AppColors.textSecondary),
                    tooltip: 'Back to login',
                  ),
                ),
                const Spacer(),

                // ── Pulsing clock illustration ───────────────────
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    final scale = 1.0 + (_pulseController.value * 0.08);
                    return Transform.scale(scale: scale, child: child);
                  },
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.warning.withOpacity(0.12),
                    ),
                    child: Icon(Icons.hourglass_top_rounded,
                        size: 56, color: AppColors.warning),
                  ),
                ),
                const SizedBox(height: 32),

                Text(
                  'Awaiting Approval',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.headingLarge,
                ),
                const SizedBox(height: 12),
                Text(
                  'Thanks for registering! Your $roleLabel account has been '
                  'created, but a school administrator still needs to '
                  'approve it before you can sign in.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'This usually doesn\'t take long. You\'ll be able to log '
                  'in as soon as it\'s approved.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.textHint,
                  ),
                ),

                const Spacer(),

                // ── Refresh: re-checks Firestore in case approval just
                // landed but the redirect hasn't re-evaluated yet ──────
                CustomOutlineButton(
                  label: 'Check Approval Status',
                  icon: Icons.refresh_rounded,
                  onPressed: () async {
                    final user = authState.user;
                    if (user != null) {
                      // ignore: use_build_context_synchronously
                      await ref.read(authProvider.notifier).refreshApprovalStatus();
                    }
                  },
                ),
                const SizedBox(height: 12),
                CustomButton(
                  label: _signingOut ? 'Signing out...' : 'Back to Login',
                  isLoading: _signingOut,
                  backgroundColor: AppColors.textSecondary,
                  onPressed: _signingOut ? null : _backToLogin,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}