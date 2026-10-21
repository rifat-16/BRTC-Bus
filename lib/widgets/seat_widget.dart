import 'package:flutter/material.dart';
import '../core/app_colors.dart';

class SeatWidget extends StatelessWidget {
  final String seatId;
  final bool isBooked;
  final bool isLocked;
  final bool isSelected;
  final VoidCallback onTap;

  const SeatWidget({
    super.key,
    required this.seatId,
    this.isBooked = false,
    this.isLocked = false,
    this.isSelected = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color seatColor = Colors.white;
    Color textColor = AppColors.textPrimary;
    Color borderColor = Colors.grey.shade300;
    List<BoxShadow> shadows = [];
    Widget? iconOverlay;

    if (isBooked) {
      // Confirmed Booked Seat (BRTC Red) - Permanent sold seat, cannot be selected
      seatColor = AppColors.primaryRed;
      textColor = Colors.white;
      borderColor = AppColors.primaryRedDark;
    } else if (isSelected) {
      // Selected Seat (Emerald Green)
      seatColor = AppColors.primaryGreen;
      textColor = Colors.white;
      borderColor = AppColors.primaryGreen;
      shadows = [
        BoxShadow(
          color: AppColors.primaryGreen.withAlpha(90),
          blurRadius: 8,
          offset: const Offset(0, 3),
        ),
      ];
    } else if (isLocked) {
      // Locked / Pending Payment Seat (Amber/Orange with Lock Icon)
      seatColor = Colors.orange.shade800;
      textColor = Colors.white;
      borderColor = Colors.orange.shade900;
      iconOverlay = const Positioned(
        top: 2,
        right: 2,
        child: Icon(Icons.lock_rounded, size: 10, color: Colors.white70),
      );
    }

    return GestureDetector(
      onTap: isBooked ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: seatColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: borderColor,
            width: isSelected ? 2.0 : 1.5,
          ),
          boxShadow: shadows,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Center(
              child: Text(
                seatId,
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
            if (iconOverlay != null && !isSelected) iconOverlay,
          ],
        ),
      ),
    );
  }
}
