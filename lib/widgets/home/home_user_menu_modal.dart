import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../screens/admin_screen.dart';
import '../../screens/login_screen.dart';
import '../../screens/my_tickets_screen.dart';

class HomeUserMenuModal {
  static void show(BuildContext context) {
    final authProvider = context.read<AuthProvider>();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 24.0, vertical: 28.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!authProvider.isGuestMode && authProvider.user != null) ...[
                CircleAvatar(
                  radius: 38,
                  backgroundColor: AppColors.primaryRed.withAlpha(20),
                  backgroundImage: authProvider.user?.photoURL != null
                      ? NetworkImage(authProvider.user!.photoURL!)
                      : null,
                  onBackgroundImageError: authProvider.user?.photoURL != null
                      ? (_, __) {}
                      : null,
                  child: authProvider.user?.photoURL == null
                      ? const Icon(Icons.person,
                          size: 38, color: AppColors.primaryRed)
                      : null,
                ),
                const SizedBox(height: 12),
                Text(
                  authProvider.displayName,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  authProvider.email,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 20),
                const Divider(),
                if (authProvider.isAdmin) ...[
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primaryRed.withAlpha(25),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.admin_panel_settings_rounded,
                          color: AppColors.primaryRed),
                    ),
                    title: const Text('Admin Panel (এডমিন প্যানেল)',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryRed)),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AdminScreen(),
                        ),
                      );
                    },
                  ),
                  const Divider(),
                ],
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryGreen.withAlpha(25),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.confirmation_number_rounded,
                        color: AppColors.primaryGreen),
                  ),
                  title: const Text('My Tickets',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const MyTicketsScreen(),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryRed.withAlpha(25),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.logout_rounded,
                        color: AppColors.primaryRed),
                  ),
                  title: const Text('Sign Out',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  onTap: () async {
                    final nav = Navigator.of(context);
                    nav.pop();
                    await authProvider.signOut();
                    if (context.mounted) {
                      nav.pushAndRemoveUntil(
                        MaterialPageRoute(
                          builder: (context) => const LoginScreen(),
                        ),
                        (route) => false,
                      );
                    }
                  },
                ),
              ] else ...[
                const CircleAvatar(
                  radius: 38,
                  backgroundColor: AppColors.backgroundColor,
                  child: Icon(Icons.person_rounded,
                      size: 38, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Guest Passenger',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (context) => const LoginScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.login_rounded),
                  label: const Text('Sign In with Google'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    minimumSize: const Size(double.infinity, 50),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
