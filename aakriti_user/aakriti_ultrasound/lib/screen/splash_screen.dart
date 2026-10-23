import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _mainAnimController;
  late final AnimationController _pulseAnimController;

  late final Animation<double> _logoScaleAnimation;
  late final Animation<double> _logoFadeAnimation;
  late final Animation<Offset> _textSlideAnimation;
  late final Animation<double> _textFadeAnimation;
  late final Animation<double> _waveformFadeAnimation;
  late final Animation<double> _progressAnimation;

  String _loadingMessage = "Initializing Clinical Diagnostics...";

  @override
  void initState() {
    super.initState();

    // 1. Entrance animation controller (snappy 1.2s start)
    _mainAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    // 2. Continuous animation controller for sonar ripples & ECG heartbeat
    _pulseAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    // Staggered curves
    _logoScaleAnimation = Tween<double>(begin: 0.65, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainAnimController,
        curve: const Interval(0.0, 0.45, curve: Curves.easeOutBack),
      ),
    );

    _logoFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainAnimController,
        curve: const Interval(0.0, 0.35, curve: Curves.easeIn),
      ),
    );

    _textSlideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.30), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _mainAnimController,
        curve: const Interval(0.30, 0.65, curve: Curves.easeOutCubic),
      ),
    );

    _textFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainAnimController,
        curve: const Interval(0.30, 0.60, curve: Curves.easeIn),
      ),
    );

    _waveformFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainAnimController,
        curve: const Interval(0.50, 0.75, curve: Curves.easeIn),
      ),
    );

    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainAnimController,
        curve: const Interval(0.20, 0.95, curve: Curves.easeInOutCubic),
      ),
    );

    _progressAnimation.addListener(() {
      final val = _progressAnimation.value;
      String nextMsg = _loadingMessage;
      if (val < 0.35) {
        nextMsg = "Initializing Clinical Diagnostics...";
      } else if (val < 0.70) {
        nextMsg = "Connecting Digital Sonography Engine...";
      } else if (val < 0.90) {
        nextMsg = "Synchronizing Secure Health Portal...";
      } else {
        nextMsg = "Welcome to Aakriti Diagnostics";
      }

      if (nextMsg != _loadingMessage && mounted) {
        setState(() {
          _loadingMessage = nextMsg;
        });
      }
    });

    _mainAnimController.forward();

    // Check login state and navigate to LoginScreen / HomeScreen
    _checkSessionAndNavigate();
  }

  Future<void> _checkSessionAndNavigate() async {
    await Future.delayed(const Duration(milliseconds: 1400));

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, anim, secondaryAnim) => const LoginScreen(),
        transitionsBuilder: (context, anim, secondaryAnim, child) {
          return FadeTransition(
            opacity: CurvedAnimation(parent: anim, curve: Curves.easeInOut),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 350),
      ),
    );
  }

  @override
  void dispose() {
    _mainAnimController.dispose();
    _pulseAnimController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFF040F1D),
      body: Stack(
        children: [
          // 1. High-Tech Ambient Radial Background
          Positioned.fill(
            child: DecoratedBox(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0.0, -0.2),
                  radius: 1.1,
                  colors: [
                    Color(0xFF0B2D4A),
                    Color(0xFF061828),
                    Color(0xFF030A14),
                  ],
                ),
              ),
            ),
          ),

          // Top right subtle glow orb
          Positioned(
            top: -60,
            right: -60,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF18C8C8).withValues(alpha: 0.18),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Bottom left subtle glow orb
          Positioned(
            bottom: -50,
            left: -50,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF1677FF).withValues(alpha: 0.18),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // 2. Central Content (Wrapped in SafeArea & Scrollable to prevent any possible overflow)
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 20),

                    // ==========================================
                    // LOGO BADGE WITH PULSING SONAR RINGS
                    // ==========================================
                    AnimatedBuilder(
                      animation: _pulseAnimController,
                      builder: (context, child) {
                        return Stack(
                          alignment: Alignment.center,
                          children: [
                            // Concentric sonar ripple waves
                            _SonarPulseRing(
                              progress: _pulseAnimController.value,
                              maxRadius: 95,
                              color: const Color(0xFF18C8C8),
                            ),
                            _SonarPulseRing(
                              progress: (_pulseAnimController.value + 0.5) % 1.0,
                              maxRadius: 95,
                              color: const Color(0xFF1677FF),
                            ),

                            // Main Logo container with entrance scale & fade
                            ScaleTransition(
                              scale: _logoScaleAnimation,
                              child: FadeTransition(
                                opacity: _logoFadeAnimation,
                                child: Container(
                                  width: 100,
                                  height: 100,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(26),
                                    gradient: const LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        Color(0xFF0F4C75),
                                        Color(0xFF072740),
                                      ],
                                    ),
                                    border: Border.all(
                                      color: const Color(0xFF18C8C8)
                                          .withValues(alpha: 0.75),
                                      width: 2,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF18C8C8)
                                            .withValues(alpha: 0.35),
                                        blurRadius: 26,
                                        spreadRadius: 2,
                                        offset: const Offset(0, 6),
                                      ),
                                      BoxShadow(
                                        color: const Color(0xFF1677FF)
                                            .withValues(alpha: 0.25),
                                        blurRadius: 18,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(24),
                                    child: Image.asset(
                                      'assets/image.png',
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) =>
                                          const Center(
                                        child: Icon(
                                          Icons.medical_services_rounded,
                                          color: Color(0xFF18C8C8),
                                          size: 50,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),

                    const SizedBox(height: 28),

                    // ==========================================
                    // BRAND TYPOGRAPHY & BADGE
                    // ==========================================
                    SlideTransition(
                      position: _textSlideAnimation,
                      child: FadeTransition(
                        opacity: _textFadeAnimation,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Main Title
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: const Text(
                                "AAKRITI",
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 4,
                                  color: Colors.white,
                                  shadows: [
                                    Shadow(
                                      color: Color(0xFF18C8C8),
                                      blurRadius: 16,
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(height: 8),

                            // Subtitle Badge (FittedBox guarantees zero overflow)
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF18C8C8)
                                      .withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: const Color(0xFF18C8C8)
                                        .withValues(alpha: 0.40),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 6,
                                      height: 6,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFF18C8C8),
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Color(0xFF18C8C8),
                                            blurRadius: 5,
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 7),
                                    const Text(
                                      "ULTRASOUND & DIAGNOSTIC CENTRE",
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1.0,
                                        color: Color(0xFF18C8C8),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(height: 10),

                            // Tagline
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              child: Text(
                                "Advanced Sonography • 4D Imaging • Pathology",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white.withValues(alpha: 0.65),
                                  letterSpacing: 0.4,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 26),

                    // ==========================================
                    // LIVE ULTRASOUND / ECG WAVEFORM
                    // ==========================================
                    FadeTransition(
                      opacity: _waveformFadeAnimation,
                      child: SizedBox(
                        width: min(size.width * 0.70, 250),
                        height: 36,
                        child: AnimatedBuilder(
                          animation: _pulseAnimController,
                          builder: (context, _) {
                            return CustomPaint(
                              painter: _EcgWavePainter(
                                animationValue: _pulseAnimController.value,
                                color: const Color(0xFF18C8C8),
                              ),
                            );
                          },
                        ),
                      ),
                    ),

                    const SizedBox(height: 36),

                    // ==========================================
                    // DYNAMIC PROGRESS BAR & STATUS TICKER
                    // ==========================================
                    AnimatedBuilder(
                      animation: _progressAnimation,
                      builder: (context, child) {
                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Sleek rounded progress bar
                            Container(
                              width: min(size.width * 0.60, 220),
                              height: 4.5,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              alignment: Alignment.centerLeft,
                              child: FractionallySizedBox(
                                widthFactor:
                                    _progressAnimation.value.clamp(0.05, 1.0),
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFF1677FF),
                                        Color(0xFF18C8C8),
                                      ],
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF18C8C8)
                                            .withValues(alpha: 0.6),
                                        blurRadius: 8,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 10),

                            // Dynamic Loading text
                            Text(
                              _loadingMessage,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: Colors.white.withValues(alpha: 0.60),
                                letterSpacing: 0.4,
                              ),
                            ),
                          ],
                        );
                      },
                    ),

                    const SizedBox(height: 24),

                    // ==========================================
                    // BOTTOM SECURITY & ACCREDITATION BADGE
                    // ==========================================
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.verified_user_rounded,
                          size: 13,
                          color: Colors.white.withValues(alpha: 0.45),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          "NABH ACCREDITED • 256-BIT ENCRYPTED",
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.0,
                            color: Colors.white.withValues(alpha: 0.45),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// CONCENTRIC SONAR / ULTRASOUND RIPPLE RING
// ============================================================
class _SonarPulseRing extends StatelessWidget {
  final double progress;
  final double maxRadius;
  final Color color;

  const _SonarPulseRing({
    required this.progress,
    required this.maxRadius,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final double radius = 50 + (maxRadius - 50) * progress;
    final double opacity = (1.0 - progress).clamp(0.0, 1.0) * 0.45;

    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: color.withValues(alpha: opacity),
          width: 1.5,
        ),
      ),
    );
  }
}

// ============================================================
// LIVE ECG / SONOGRAM FREQUENCY WAVE PAINTER
// ============================================================
class _EcgWavePainter extends CustomPainter {
  final double animationValue;
  final Color color;

  _EcgWavePainter({required this.animationValue, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final glowPaint = Paint()
      ..color = color.withValues(alpha: 0.35)
      ..strokeWidth = 5.0
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

    final path = Path();
    final width = size.width;
    final midY = size.height / 2;

    path.moveTo(0, midY);

    for (double x = 0; x <= width; x += 2) {
      final progress = (x / width + animationValue) % 1.0;
      double y = midY;

      // Pulse pattern simulating a clean ECG / Doppler waveform
      if (progress > 0.38 && progress < 0.42) {
        y = midY - 4;
      } else if (progress >= 0.42 && progress < 0.46) {
        y = midY + 6;
      } else if (progress >= 0.46 && progress < 0.52) {
        // High R-peak
        final t = (progress - 0.46) / 0.06;
        y = midY - 18 * sin(t * pi);
      } else if (progress >= 0.52 && progress < 0.56) {
        // S-wave
        final t = (progress - 0.52) / 0.04;
        y = midY + 9 * sin(t * pi);
      } else if (progress >= 0.56 && progress < 0.62) {
        // T-wave
        final t = (progress - 0.56) / 0.06;
        y = midY - 5 * sin(t * pi);
      }

      path.lineTo(x, y);
    }

    canvas.drawPath(path, glowPaint);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _EcgWavePainter oldDelegate) =>
      oldDelegate.animationValue != animationValue;
}
