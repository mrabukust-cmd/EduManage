import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:school_management_system/core/theme/app_colors.dart';
import 'package:school_management_system/core/theme/app_dimensions.dart';
import 'package:school_management_system/core/theme/app_text_style.dart';
import 'package:school_management_system/core/utils/responsive_sizer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class _OnboardingPage {
  final String title;
  final String subtitle;
  final IconData icon;
  final Gradient gradient;
  final Color accentColor;

  const _OnboardingPage({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradient,
    required this.accentColor,
  });
}

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  late AnimationController _iconController;
  late Animation<double> _iconBounce;

  final List<_OnboardingPage> _pages = const [
    _OnboardingPage(
      title: 'Smart Admin Control',
      subtitle:
          'Manage students, teachers, classes, and announcements from one powerful dashboard.',
      icon: Icons.admin_panel_settings_rounded,
      gradient: AppColors.adminGradient,
      accentColor: AppColors.adminColor,
    ),
    _OnboardingPage(
      title: 'Teacher Tools',
      subtitle:
          'Mark attendance, enter results, and communicate with students — all in seconds.',
      icon: Icons.cast_for_education_rounded,
      gradient: AppColors.teacherGradient,
      accentColor: AppColors.teacherColor,
    ),
    _OnboardingPage(
      title: 'Student Portal',
      subtitle:
          'View your attendance, results, and notices anytime, anywhere on your phone.',
      icon: Icons.menu_book_rounded,
      gradient: AppColors.studentGradient,
      accentColor: AppColors.studentColor,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _iconController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _iconBounce = Tween<double>(begin: -10, end: 10).animate(
      CurvedAnimation(parent: _iconController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _iconController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_done', true);

    if (mounted) {
      context.go('/login');
    }
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _finish();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // ── Page view ──────────────────────────────────────────
          PageView.builder(
            controller: _pageController,
            onPageChanged: (i) => setState(() => _currentPage = i),
            itemCount: _pages.length,
            itemBuilder: (context, index) {
              final page = _pages[index];
              return _buildPage(page);
            },
          ),

          // ── Skip button ────────────────────────────────────────
          Positioned(
            top: MediaQuery.of(context).padding.top + 2.h,
            right: 6.w,
            child: TextButton(
              onPressed: _finish,
              child: Text(
                'Skip',
                style: AppTextStyles.bodyMedium.copyWith(
                  fontSize: 13.sp,
                  color: AppColors.onPrimary.withValues(alpha: 0.85),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),

          // ── Bottom controls ────────────────────────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(
                8.w,
                2.h,
                8.w,
                MediaQuery.of(context).padding.bottom + 3.h,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Page dots
                  SmoothPageIndicator(
                    controller: _pageController,
                    count: _pages.length,
                    effect: ExpandingDotsEffect(
                      activeDotColor: AppColors.onPrimary,
                      dotColor: AppColors.onPrimary.withValues(alpha: 0.38),
                      dotHeight: 8,
                      dotWidth: 8,
                      expansionFactor: 3,
                    ),
                  ),

                  // Next / Get Started button
                  GestureDetector(
                    onTap: _nextPage,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      padding: EdgeInsets.symmetric(
                        horizontal: 6.w,
                        vertical: 1.8.h,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.onPrimary,
                        borderRadius: BorderRadius.circular(50),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.overlay.withValues(alpha: 0.15),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _currentPage == _pages.length - 1
                                ? 'Get Started'
                                : 'Next',
                            style: AppTextStyles.bodyMediumBold.copyWith(
                              fontSize: 13.sp,
                              color: _pages[_currentPage].accentColor,
                            ),
                          ),
                          SizedBox(width: 2.w),
                          Icon(
                            Icons.arrow_forward_rounded,
                            size: 4.w.clamp(16.0, 20.0),
                            color: _pages[_currentPage].accentColor,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPage(_OnboardingPage page) {
    final outerRingSize = 58.w.clamp(200.0, 260.0);
    final innerRingSize = 46.w.clamp(160.0, 200.0);
    final iconBoxSize = 34.w.clamp(120.0, 150.0);
    final iconSize = 16.w.clamp(56.0, 76.0);

    return Container(
      decoration: BoxDecoration(gradient: page.gradient),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            SizedBox(height: 6.h),

            // ── Icon illustration area ─────────────────────────
            Expanded(
              flex: 5,
              child: Center(
                child: AnimatedBuilder(
                  animation: _iconBounce,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(0, _iconBounce.value),
                      child: child,
                    );
                  },
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Large glow circle
                      Container(
                        width: outerRingSize,
                        height: outerRingSize,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.onPrimary.withValues(alpha: 0.08),
                        ),
                      ),
                      Container(
                        width: innerRingSize,
                        height: innerRingSize,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.onPrimary.withValues(alpha: 0.12),
                        ),
                      ),
                      // Icon container
                      Container(
                        width: iconBoxSize,
                        height: iconBoxSize,
                        decoration: BoxDecoration(
                          color: AppColors.onPrimary.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(AppDimensions.radiusLarge + 16),
                          border: Border.all(
                            color: AppColors.onPrimary.withValues(alpha: 0.35),
                            width: 2,
                          ),
                        ),
                        child: Icon(page.icon, size: iconSize, color: AppColors.onPrimary),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ── Text content ───────────────────────────────────
            Expanded(
              flex: 4,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.w),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Page number badge
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 4.w,
                        vertical: 0.6.h,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.onPrimary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: Text(
                        '0${_currentPage + 1} / 0${_pages.length}',
                        style: AppTextStyles.labelSmall.copyWith(
                          fontSize: 11.sp,
                          color: AppColors.onPrimary.withValues(alpha: 0.85),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      page.title,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.headingLarge.copyWith(
                        fontSize: 22.sp,
                        color: AppColors.onPrimary,
                      ),
                    ),
                    SizedBox(height: 1.5.h),
                    Text(
                      page.subtitle,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontSize: 13.sp,
                        color: AppColors.onPrimary.withValues(alpha: 0.85),
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Space for bottom controls
            SizedBox(height: 12.h),
          ],
        ),
      ),
    );
  }
}
