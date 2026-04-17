import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/routes/app_router.dart';
import '../../data/services/storage_service.dart';
import '../../core/theme/app_colors.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // Logo scale-in
  late AnimationController _logoController;
  late Animation<double> _logoScale;

  // Staggered fade-ins
  late AnimationController _textController;
  late Animation<double> _titleFade;
  late Animation<Offset> _titleSlide;
  late Animation<double> _subtitleFade;
  late Animation<double> _dotsOpacity;

  // Floating logo bob
  late AnimationController _floatController;
  late Animation<double> _floatOffset;

  // Pulsing rings
  late AnimationController _ringController;
  late Animation<double> _ring1Scale;
  late Animation<double> _ring2Scale;
  late Animation<double> _ring3Scale;

  // Ripple expand
  late AnimationController _rippleController;

  // Loading dots
  late AnimationController _dotsController;

  // Animated gradient background
  late AnimationController _gradientController;
  late Animation<Alignment?> _gradientBegin;
  late Animation<Alignment?> _gradientEnd;

  @override
  void initState() {
    super.initState();

    // ── Logo scale bounce ──
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 750),
      vsync: this,
    );
    _logoScale = CurvedAnimation(
      parent: _logoController,
      curve: Curves.elasticOut,
    );
    _logoController.forward();

    // ── Staggered text + dots ──
    _textController = AnimationController(
      duration: const Duration(milliseconds: 1400),
      vsync: this,
    );

    _titleFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _textController,
        curve: const Interval(0.0, 0.45, curve: Curves.easeOut),
      ),
    );
    _titleSlide = Tween<Offset>(begin: const Offset(0, 0.4), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _textController,
            curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
          ),
        );
    _subtitleFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _textController,
        curve: const Interval(0.3, 0.7, curve: Curves.easeOut),
      ),
    );
    _dotsOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _textController,
        curve: const Interval(0.6, 1.0, curve: Curves.easeOut),
      ),
    );

    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) _textController.forward();
    });

    // ── Floating bob ──
    _floatController = AnimationController(
      duration: const Duration(milliseconds: 2800),
      vsync: this,
    )..repeat(reverse: true);
    _floatOffset = Tween<double>(begin: 0, end: -10).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );

    // ── Pulsing rings ──
    _ringController = AnimationController(
      duration: const Duration(milliseconds: 2600),
      vsync: this,
    )..repeat(reverse: true);
    _ring1Scale = Tween<double>(begin: 1.0, end: 1.06).animate(
      CurvedAnimation(
        parent: _ringController,
        curve: const Interval(0.0, 1.0, curve: Curves.easeInOut),
      ),
    );
    _ring2Scale = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(
        parent: _ringController,
        curve: const Interval(0.15, 1.0, curve: Curves.easeInOut),
      ),
    );
    _ring3Scale = Tween<double>(begin: 1.0, end: 1.10).animate(
      CurvedAnimation(
        parent: _ringController,
        curve: const Interval(0.3, 1.0, curve: Curves.easeInOut),
      ),
    );

    // ── Ripple ──
    _rippleController = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    )..repeat();

    // ── Loading dots ──
    _dotsController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat();

    // ── Animated gradient alignment ──
    _gradientController = AnimationController(
      duration: const Duration(seconds: 5),
      vsync: this,
    )..repeat(reverse: true);

    _gradientBegin =
        AlignmentTween(
          begin: Alignment.topLeft,
          end: Alignment.bottomLeft,
        ).animate(
          CurvedAnimation(parent: _gradientController, curve: Curves.easeInOut),
        );

    _gradientEnd =
        AlignmentTween(
          begin: Alignment.bottomRight,
          end: Alignment.topRight,
        ).animate(
          CurvedAnimation(parent: _gradientController, curve: Curves.easeInOut),
        );

    _navigateToNext();
  }

  Future<void> _navigateToNext() async {
    await Future.delayed(const Duration(seconds: 3));
    if (!mounted) return;
    
    final isRegistered = StorageService.isUserRegistered();
    final isLoggedIn = StorageService.isLoggedIn();

    if (isLoggedIn) {
      context.go(AppRouter.home);
    } else {
      context.go(isRegistered ? AppRouter.login : AppRouter.register);
    }
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    _floatController.dispose();
    _ringController.dispose();
    _rippleController.dispose();
    _dotsController.dispose();
    _gradientController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: _gradientController,
        builder: (context, child) {
          return Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: const [AppColors.orange, AppColors.purple],
                begin: _gradientBegin.value ?? Alignment.topLeft,
                end: _gradientEnd.value ?? Alignment.bottomRight,
              ),
            ),
            child: child,
          );
        },
        child: Stack(
          alignment: Alignment.center,
          children: [
            // ── Pulsing concentric rings ──
            ...[90.0, 140.0, 190.0].asMap().entries.map((e) {
              final animations = [_ring1Scale, _ring2Scale, _ring3Scale];
              return AnimatedBuilder(
                animation: animations[e.key],
                builder: (_, __) => Transform.scale(
                  scale: animations[e.key].value,
                  child: Container(
                    width: e.value * 2,
                    height: e.value * 2,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.12),
                        width: 1.2,
                      ),
                    ),
                  ),
                ),
              );
            }),

            // ── Ripple effect (multiple staggered instances) ──
            ...List.generate(3, (i) {
              return AnimatedBuilder(
                animation: _rippleController,
                builder: (_, __) {
                  final delay = i / 3;
                  final progress = (_rippleController.value + delay) % 1.0;
                  final scale = 1.0 + progress * 1.8;
                  final opacity = (1.0 - progress) * 0.35;
                  return Opacity(
                    opacity: opacity.clamp(0.0, 1.0),
                    child: Transform.scale(
                      scale: scale,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.6),
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            }),

            // ── Main column ──
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ScaleTransition(
                  scale: _logoScale,
                  child: AnimatedBuilder(
                    animation: _floatOffset,
                    builder: (_, child) => Transform.translate(
                      offset: Offset(0, _floatOffset.value),
                      child: child,
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 30,
                            spreadRadius: 4,
                          ),
                          BoxShadow(
                            color: AppColors.orange.withValues(alpha: 0.3),
                            blurRadius: 50,
                            spreadRadius: 8,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.message_rounded,
                        size: 72,
                        color: AppColors.orange,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 36),

                FadeTransition(
                  opacity: _titleFade,
                  child: SlideTransition(
                    position: _titleSlide,
                    child: ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [Colors.white, Color(0xFFFFE0C8), Colors.white],
                        stops: [0.0, 0.5, 1.0],
                      ).createShader(bounds),
                      child: const Text(
                        'SMSMitra',
                        style: TextStyle(
                          fontSize: 38,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 3,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                FadeTransition(
                  opacity: _subtitleFade,
                  child: Text(
                    'Send SMS with Ease',
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.white.withValues(alpha: 0.82),
                      letterSpacing: 2.5,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),

                const SizedBox(height: 48),

                FadeTransition(
                  opacity: _dotsOpacity,
                  child: _LoadingDots(controller: _dotsController),
                ),
              ],
            ),

            Positioned(
              bottom: 36,
              child: FadeTransition(
                opacity: _dotsOpacity,
                child: Text(
                  'CONNECTING PEOPLE · SIMPLY',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withValues(alpha: 0.45),
                    letterSpacing: 2.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingDots extends StatelessWidget {
  final AnimationController controller;
  const _LoadingDots({required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final delay = i / 3;
            final progress = ((controller.value + delay) % 1.0);
            final scale =
                0.6 +
                (progress < 0.5 ? progress * 2 : (1 - progress) * 2) * 0.4;
            final opacity =
                0.3 +
                (progress < 0.5 ? progress * 2 : (1 - progress) * 2) * 0.7;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5),
              child: Opacity(
                opacity: opacity.clamp(0.3, 1.0),
                child: Transform.scale(
                  scale: scale,
                  child: Container(
                    width: 9,
                    height: 9,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
