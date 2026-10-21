import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../screens/my_tickets_screen.dart';
import 'home_helpline_modal.dart';

class HomeShortcutsSection extends StatelessWidget {
  const HomeShortcutsSection({super.key});

  Widget _buildShortcutItem({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withAlpha(35)),
              boxShadow: [
                BoxShadow(
                  color: color.withAlpha(15),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildShortcutItem(
            icon: Icons.confirmation_number_rounded,
            label: 'My Tickets',
            color: AppColors.primaryRed,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const MyTicketsScreen(),
                ),
              );
            },
          ),
          _buildShortcutItem(
            icon: Icons.schedule_rounded,
            label: 'Schedule',
            color: Colors.blue.shade700,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                      'প্রতিদিন সকাল ৬:০০ টা থেকে রাত ১০:০০ টা পর্যন্ত গাড়ি চলাচল করে'),
                ),
              );
            },
          ),
          _buildShortcutItem(
            icon: Icons.headset_mic_rounded,
            label: 'Helpline',
            color: Colors.orange.shade800,
            onTap: () => HomeHelplineModal.show(context),
          ),
        ],
      ),
    );
  }
}
