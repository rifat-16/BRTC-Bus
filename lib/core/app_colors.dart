import 'package:flutter/material.dart';

class AppColors {
  // BRTC Modern Brand Colors
  static const Color primaryRed = Color(0xFFD32F2F); 
  static const Color primaryRedDark = Color(0xFFB71C1C);
  static const Color vibrantRed = Color(0xFFFF1744);
  
  static const Color primaryGreen = Color(0xFF00875A); 
  static const Color primaryGreenDark = Color(0xFF006644);
  
  static const Color accentYellow = Color(0xFFFFC107);
  static const Color accentGold = Color(0xFFFFB300);

  // Background & Surface Gradients
  static const Color backgroundColor = Color(0xFFF8FAFC); // Very clean slate tint
  static const Color surfaceColor = Colors.white;
  static const Color cardBorder = Color(0xFFE2E8F0);

  // Text Colors
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textMuted = Color(0xFF94A3B8);

  // Seat Colors
  static const Color seatAvailable = Colors.white;
  static const Color seatSelected = primaryGreen;
  static const Color seatBooked = Color(0xFFCBD5E1);

  // Linear Gradients
  static const LinearGradient redGradient = LinearGradient(
    colors: [primaryRed, vibrantRed],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient greenGradient = LinearGradient(
    colors: [primaryGreen, Color(0xFF10B981)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkHeaderGradient = LinearGradient(
    colors: [Color(0xFFB71C1C), Color(0xFFD32F2F), Color(0xFFFF1744)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

Route<T> createSmoothPageRoute<T>(Widget page) {
  return PageRouteBuilder<T>(
    transitionDuration: const Duration(milliseconds: 320),
    reverseTransitionDuration: const Duration(milliseconds: 280),
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curvedAnimation = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      return FadeTransition(
        opacity: curvedAnimation,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.05, 0),
            end: Offset.zero,
          ).animate(curvedAnimation),
          child: child,
        ),
      );
    },
  );
}
