import 'package:flutter/material.dart';
import '../core/app_colors.dart';

class RouteCard extends StatelessWidget {
  final String routeName;
  final VoidCallback onTap;

  const RouteCard({
    super.key,
    required this.routeName,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shadowColor: Colors.black.withAlpha(15),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.primaryRed.withAlpha(20),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.alt_route_rounded, color: AppColors.primaryRed),
        ),
        title: Text(
          routeName,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
            fontSize: 15,
          ),
        ),
        subtitle: const Text(
          'নিয়মিত এসি / নন-এসি ট্রিপ',
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
        trailing: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppColors.backgroundColor,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.arrow_forward_rounded, size: 18, color: AppColors.primaryGreen),
        ),
        onTap: onTap,
      ),
    );
  }
}
