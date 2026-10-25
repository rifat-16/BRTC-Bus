import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_colors.dart';
import '../providers/auth_provider.dart';
import '../screens/admin_screen.dart';
import '../screens/my_tickets_screen.dart';
import '../widgets/home/home_helpline_modal.dart';
import '../widgets/home/home_user_menu_modal.dart';

class DesktopWebNavbar extends StatelessWidget implements PreferredSizeWidget {
  const DesktopWebNavbar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(72);

  void _showHelplineModal(BuildContext context) {
    HomeHelplineModal.show(context);
  }

  void _showUserMenuModal(BuildContext context) {
    HomeUserMenuModal.show(context);
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return Container(
      height: preferredSize.height,
      decoration: const BoxDecoration(
        gradient: AppColors.darkHeaderGradient,
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Brand Crest & Title
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.directions_bus_filled_rounded,
                        color: AppColors.primaryRed,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text(
                              'BRTC Sakhipur',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.accentGold,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'ONLINE',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.primaryRedDark,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const Text(
                          'সখিপুর-ঢাকা এসি বাস টিকিট সার্ভিস',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                // Navigation Items & Profile Actions
                Row(
                  children: [
                    TextButton.icon(
                      icon: const Icon(Icons.phone_in_talk_rounded,
                          size: 16, color: AppColors.accentGold),
                      label: const Text(
                        'হেল্পলাইন (01624-622614)',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      onPressed: () => _showHelplineModal(context),
                    ),
                    const SizedBox(width: 12),
                    if (authProvider.isAuthenticated)
                      TextButton.icon(
                        icon: const Icon(Icons.confirmation_number_rounded,
                            size: 16, color: Colors.white),
                        label: const Text(
                          'মাই টিকিটস',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            createSmoothPageRoute(
                              const MyTicketsScreen(),
                            ),
                          );
                        },
                      ),
                    if (authProvider.isAdmin) ...[
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        icon: const Icon(
                          Icons.admin_panel_settings_rounded,
                          size: 16,
                        ),
                        label: const Text('এডমিন প্যানেল'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppColors.primaryRed,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          textStyle: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12.5,
                          ),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            createSmoothPageRoute(
                              const AdminScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                    const SizedBox(width: 16),
                    InkWell(
                      onTap: () => _showUserMenuModal(context),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.accentGold,
                            width: 2,
                          ),
                        ),
                        child: CircleAvatar(
                          radius: 18,
                          backgroundColor: AppColors.primaryRedDark,
                          child: Text(
                            authProvider.displayName.substring(0, 1).toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
