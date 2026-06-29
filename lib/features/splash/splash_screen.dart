import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../shared/widgets/app_brand_logo.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _master;
  late final Animation<double> _logoScale;
  late final Animation<double> _logoOpacity;
  late final Animation<double> _titleOpacity;
  late final Animation<Offset> _titleSlide;
  late final Animation<double> _taglineOpacity;
  late final AnimationController _progress;
  late final Animation<double> _progressValue;

  @override
  void initState() {
    super.initState();
    _master = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _logoScale = Tween<double>(begin: 0.82, end: 1).animate(
      CurvedAnimation(
        parent: _master,
        curve: const Interval(0, 0.55, curve: Curves.easeOutCubic),
      ),
    );
    _logoOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _master,
        curve: const Interval(0, 0.4, curve: Curves.easeOut),
      ),
    );
    _titleOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _master,
        curve: const Interval(0.25, 0.65, curve: Curves.easeOut),
      ),
    );
    _titleSlide = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _master,
        curve: const Interval(0.25, 0.65, curve: Curves.easeOutCubic),
      ),
    );
    _taglineOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _master,
        curve: const Interval(0.45, 0.85, curve: Curves.easeOut),
      ),
    );
    _progress = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );
    _progressValue = CurvedAnimation(
      parent: _progress,
      curve: Curves.easeInOut,
    );

    _master.forward();
    _progress.forward();

    Future.delayed(const Duration(milliseconds: 2600), () {
      if (mounted) context.go('/library');
    });
  }

  @override
  void dispose() {
    _master.dispose();
    _progress.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF0C1018),
                  AppColors.background,
                  Color(0xFF06080C),
                ],
                stops: [0, 0.55, 1],
              ),
            ),
          ),
          Positioned(
            top: -120,
            right: -80,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: 0.14),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 36),
              child: Column(
                children: [
                  const Spacer(flex: 3),
                  FadeTransition(
                    opacity: _logoOpacity,
                    child: ScaleTransition(
                      scale: _logoScale,
                      child: const AppBrandHeroLogo(size: 108),
                    ),
                  ),
                  const SizedBox(height: 32),
                  FadeTransition(
                    opacity: _titleOpacity,
                    child: SlideTransition(
                      position: _titleSlide,
                      child: Column(
                        children: [
                          Text(
                            AppConstants.appName,
                            style: AppTextStyles.displayLarge.copyWith(
                              letterSpacing: -1.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            width: 48,
                            height: 2,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(1),
                              gradient: AppColors.primaryGradient,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  FadeTransition(
                    opacity: _taglineOpacity,
                    child: Text(
                      AppConstants.appTagline,
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: AppColors.textMuted,
                        letterSpacing: 0.2,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const Spacer(flex: 4),
                  FadeTransition(
                    opacity: _taglineOpacity,
                    child: Column(
                      children: [
                        AnimatedBuilder(
                          animation: _progressValue,
                          builder: (context, _) {
                            return ClipRRect(
                              borderRadius: BorderRadius.circular(2),
                              child: SizedBox(
                                width: 120,
                                height: 2,
                                child: LinearProgressIndicator(
                                  value: _progressValue.value,
                                  backgroundColor:
                                      AppColors.glassBorder.withValues(alpha: 0.6),
                                  valueColor: const AlwaysStoppedAnimation(
                                    AppColors.primary,
                                  ),
                                  minHeight: 2,
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'Loading your library',
                          style: AppTextStyles.labelSmall.copyWith(
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 36),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
