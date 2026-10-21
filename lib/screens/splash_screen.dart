import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:provider/provider.dart';
import '../core/app_colors.dart';
import '../providers/auth_provider.dart';
import '../widgets/brtc_express_bus_widget.dart';
import 'admin_screen.dart';
import 'home_screen.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _roadController;

  late Animation<double> _busPosition;
  late Animation<double> _logoScale;
  late Animation<double> _logoFade;
  late Animation<double> _roadFade;

  @override
  void initState() {
    super.initState();

    _mainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    );

    _roadController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat();

    // Bus movement sequence across the screen width (from -1.2 left to 1.3 right)
    _busPosition = TweenSequence<double>([
      // 1. Enter from far left (-1.2) to center-left (-0.05)
      TweenSequenceItem(
        tween: Tween<double>(begin: -1.2, end: -0.05)
            .chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 38,
      ),
      // 2. Drive smoothly past center (-0.05 to 0.05) while logo reveals
      TweenSequenceItem(
        tween: Tween<double>(begin: -0.05, end: 0.05)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 24,
      ),
      // 3. Accelerate off to the far right (1.3)
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.05, end: 1.3)
            .chain(CurveTween(curve: Curves.easeInCubic)),
        weight: 38,
      ),
    ]).animate(_mainController);

    // Logo entrance animations
    _logoFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.2, 0.55, curve: Curves.easeIn),
      ),
    );

    _logoScale = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.2, 0.55, curve: Curves.elasticOut),
      ),
    );

    _roadFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.0, 0.3, curve: Curves.easeIn),
      ),
    );

    _mainController.forward();

    // Navigate after splash completes
    Timer(const Duration(milliseconds: 3300), () async {
      if (mounted) {
        final authProvider = context.read<AuthProvider>();
        final user = FirebaseAuth.instance.currentUser;

        Widget targetScreen = const LoginScreen();
        if (user != null) {
          await authProvider.verifyAdminStatusDirect(user);
          targetScreen =
              authProvider.isAdmin ? const AdminScreen() : const HomeScreen();
        }

        if (mounted) {
          Navigator.of(context).pushReplacement(
            PageRouteBuilder(
              transitionDuration: const Duration(milliseconds: 800),
              pageBuilder: (context, animation, secondaryAnimation) =>
                  targetScreen,
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                return FadeTransition(opacity: animation, child: child);
              },
            ),
          );
        }
      }
    });
  }

  @override
  void dispose() {
    _mainController.dispose();
    _roadController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: AppColors.darkHeaderGradient,
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Ambient Decorative Background Glows
              Positioned(
                top: -60,
                right: -60,
                child: Container(
                  width: 220,
                  height: 220,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withAlpha(15),
                  ),
                ),
              ),
              Positioned(
                top: screenSize.height * 0.12,
                left: -80,
                child: Container(
                  width: 280,
                  height: 280,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primaryRed.withAlpha(30),
                  ),
                ),
              ),

              // Main Content: Brand Logo & Title
              Positioned(
                top: screenSize.height * 0.16,
                left: 0,
                right: 0,
                child: Column(
                  children: [
                    // BRTC Crest Badge
                    ScaleTransition(
                      scale: _logoScale,
                      child: FadeTransition(
                        opacity: _logoFade,
                        child: Container(
                          padding: const EdgeInsets.all(22),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withAlpha(50),
                                blurRadius: 25,
                                offset: const Offset(0, 10),
                              ),
                              BoxShadow(
                                color: AppColors.accentGold.withAlpha(120),
                                blurRadius: 20,
                                spreadRadius: 3,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.directions_bus_filled_rounded,
                            size: 64,
                            color: AppColors.primaryRed,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Title & Bengali Subtitle
                    FadeTransition(
                      opacity: _logoFade,
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                'BRTC',
                                style: TextStyle(
                                  fontSize: 38,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  letterSpacing: 2,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 5),
                                decoration: BoxDecoration(
                                  color: AppColors.accentGold,
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withAlpha(30),
                                      blurRadius: 8,
                                    ),
                                  ],
                                ),
                                child: const Text(
                                  'E-TICKET',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.primaryRedDark,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'বাংলাদেশ সড়ক পরিবহন কর্পোরেশন',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.accentYellow,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'নিরাপদ ও আধুনিক অনলাইন টিকিট সেবা',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w400,
                              color: Colors.white.withAlpha(200),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Road & Moving Bus Section (Positioned at Bottom Half)
              Positioned(
                bottom: 80,
                left: 0,
                right: 0,
                child: FadeTransition(
                  opacity: _roadFade,
                  child: Column(
                    children: [
                      // Road & Bus Stack
                      SizedBox(
                        height: 130,
                        width: double.infinity,
                        child: Stack(
                          alignment: Alignment.bottomLeft,
                          children: [
                            // Asphalt Road
                            Positioned(
                              bottom: 8,
                              left: 0,
                              right: 0,
                              child: Container(
                                height: 48,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1E293B),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withAlpha(70),
                                      blurRadius: 10,
                                      offset: const Offset(0, 5),
                                    ),
                                  ],
                                ),
                                child: CustomPaint(
                                  size: Size(screenSize.width, 48),
                                  painter: DashRoadPainter(
                                    progress: _roadController.value,
                                  ),
                                ),
                              ),
                            ),

                            // Moving BRTC Express Bus
                            AnimatedBuilder(
                              animation: _mainController,
                              builder: (context, child) {
                                final double posX =
                                    _busPosition.value * screenSize.width;
                                final double bounceY =
                                    math.sin(_mainController.value * 40) * 1.5;

                                return Positioned(
                                  left: posX,
                                  bottom: 28 + bounceY,
                                  child: BrtcExpressBusWidget(
                                    wheelAngle:
                                        _roadController.value * 2 * math.pi,
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 18),

                      // Network Sub-Badge
                      FadeTransition(
                        opacity: _logoFade,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(20),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withAlpha(40),
                            ),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.route_rounded,
                                size: 16,
                                color: AppColors.accentGold,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'সমগ্র বাংলাদেশে বিস্তৃত স্মার্ট টিকিট নেটওয়ার্ক',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Bottom Progress Bar
              Positioned(
                bottom: 25,
                left: 60,
                right: 60,
                child: FadeTransition(
                  opacity: _logoFade,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: const LinearProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.accentGold,
                      ),
                      backgroundColor: Colors.white24,
                      minHeight: 3,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
