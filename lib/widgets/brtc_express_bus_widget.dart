import 'package:flutter/material.dart';
import '../core/app_colors.dart';

class BrtcExpressBusWidget extends StatelessWidget {
  final double wheelAngle;

  const BrtcExpressBusWidget({
    super.key,
    required this.wheelAngle,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Headlight Beam Effect (Shining ahead to the right)
        Positioned(
          right: -55,
          bottom: 12,
          child: Container(
            width: 65,
            height: 28,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.amberAccent.withAlpha(160),
                  Colors.amberAccent.withAlpha(0),
                ],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
            ),
          ),
        ),

        // Speed Motion Trails (Behind the bus on the left)
        Positioned(
          left: -28,
          top: 14,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(width: 22, height: 2, color: Colors.white38),
              const SizedBox(height: 6),
              Container(width: 30, height: 2, color: Colors.white24),
              const SizedBox(height: 6),
              Container(width: 16, height: 2, color: Colors.white12),
            ],
          ),
        ),

        // Bus Main Body
        Container(
          width: 165,
          height: 56,
          decoration: BoxDecoration(
            color: AppColors.primaryRed,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(8),
              topRight: Radius.circular(18),
              bottomLeft: Radius.circular(6),
              bottomRight: Radius.circular(10),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(90),
                blurRadius: 12,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Stack(
            children: [
              // BRTC Green Side Stripe
              Positioned(
                bottom: 12,
                left: 0,
                right: 0,
                child: Container(
                  height: 10,
                  decoration: const BoxDecoration(
                    color: AppColors.primaryGreen,
                  ),
                ),
              ),

              // Glass Windows Row
              Positioned(
                top: 8,
                left: 12,
                right: 18,
                child: Row(
                  children: [
                    // Driver Window
                    Expanded(
                      flex: 2,
                      child: Container(
                        height: 18,
                        decoration: BoxDecoration(
                          color: Colors.lightBlue.shade100,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(4),
                            topRight: Radius.circular(10),
                          ),
                          border: Border.all(color: Colors.black26, width: 0.5),
                        ),
                      ),
                    ),
                    const SizedBox(width: 3),
                    // Passenger Windows
                    for (int i = 0; i < 4; i++) ...[
                      Expanded(
                        flex: 3,
                        child: Container(
                          height: 18,
                          margin: const EdgeInsets.only(right: 2),
                          decoration: BoxDecoration(
                            color: Colors.lightBlue.shade100,
                            borderRadius: BorderRadius.circular(2),
                            border:
                                Border.all(color: Colors.black26, width: 0.5),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // BRTC Side Branding Text
              Positioned(
                bottom: 13,
                left: 16,
                child: const Text(
                  'BRTC EXPRESS',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 8.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                  ),
                ),
              ),

              // Front Headlight Bulb
              Positioned(
                bottom: 10,
                right: 0,
                child: Container(
                  width: 5,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.amber,
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(4),
                      bottomRight: Radius.circular(4),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.amber.withAlpha(220),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
              ),

              // Rear Tail Light
              Positioned(
                bottom: 10,
                left: 0,
                child: Container(
                  width: 4,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: Colors.redAccent,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(2),
                      bottomLeft: Radius.circular(2),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Front Spinning Wheel
        Positioned(
          bottom: -8,
          right: 24,
          child: Transform.rotate(
            angle: wheelAngle,
            child: const BusWheel(),
          ),
        ),

        // Rear Spinning Wheel
        Positioned(
          bottom: -8,
          left: 24,
          child: Transform.rotate(
            angle: wheelAngle,
            child: const BusWheel(),
          ),
        ),
      ],
    );
  }
}

class BusWheel extends StatelessWidget {
  const BusWheel({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFF374151), width: 2),
        boxShadow: const [
          BoxShadow(
            color: Colors.black45,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Container(
          width: 10,
          height: 10,
          decoration: const BoxDecoration(
            color: Color(0xFF9CA3AF),
            shape: BoxShape.circle,
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(width: 8, height: 1.5, color: Colors.grey.shade800),
              Container(width: 1.5, height: 8, color: Colors.grey.shade800),
            ],
          ),
        ),
      ),
    );
  }
}

class DashRoadPainter extends CustomPainter {
  final double progress;

  DashRoadPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.accentGold
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    const double dashWidth = 18;
    const double dashSpace = 12;
    final double totalDash = dashWidth + dashSpace;
    final double startX = -(progress * totalDash);

    for (double x = startX; x < size.width + totalDash; x += totalDash) {
      canvas.drawLine(
        Offset(x, size.height / 2),
        Offset(x + dashWidth, size.height / 2),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant DashRoadPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
