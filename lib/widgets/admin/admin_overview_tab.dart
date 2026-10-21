import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../models/ticket_model.dart';
import '../../screens/bus_manifest_screen.dart';
import '../../screens/revenue_analytics_screen.dart';
import '../../services/firestore_service.dart';
import 'admin_payment_config_card.dart';
import 'admin_route_fare_hub.dart';

class AdminOverviewTab extends StatelessWidget {
  final List<TicketModel> allTickets;
  final TabController tabController;
  final FirestoreService firestoreService;

  const AdminOverviewTab({
    super.key,
    required this.allTickets,
    required this.tabController,
    required this.firestoreService,
  });

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withAlpha(50), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: color.withAlpha(15),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                Icon(Icons.chevron_right_rounded,
                    color: Colors.grey.shade400, size: 20),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ElevatedButton.icon(
      icon: Icon(icon, size: 18),
      label: Text(label, style: const TextStyle(fontSize: 13)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        elevation: 2,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      onPressed: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    final pendingTickets =
        allTickets.where((t) => t.status == 'PENDING').toList();
    final confirmedTickets =
        allTickets.where((t) => t.status == 'CONFIRMED').toList();
    final rejectedTickets =
        allTickets.where((t) => t.status == 'REJECTED').toList();

    int totalRevenue = 0;
    for (final t in confirmedTickets) {
      totalRevenue += t.totalAmount;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primaryRed, AppColors.primaryRedDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(35),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.admin_panel_settings_rounded,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'BRTC Admin Portal',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'টিকিট ভেরিফিকেশন, সিট ম্যানেজার ও রিভিনিউ কন্ট্রোল সেন্টার',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.5,
            children: [
              _buildMetricCard(
                title: 'পেন্ডিং রিকোয়েস্ট',
                value: '${pendingTickets.length} টি',
                icon: Icons.hourglass_top_rounded,
                color: Colors.orange.shade800,
                bgColor: Colors.orange.shade50,
                onTap: () => tabController.animateTo(1),
              ),
              _buildMetricCard(
                title: 'অনুমোদিত আয়',
                value: '৳ $totalRevenue',
                icon: Icons.account_balance_wallet_rounded,
                color: AppColors.primaryGreen,
                bgColor: Colors.green.shade50,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => RevenueAnalyticsScreen(
                        initialTickets: confirmedTickets,
                      ),
                    ),
                  );
                },
              ),
              _buildMetricCard(
                title: 'মোট ইস্যুকৃত টিকিট',
                value: '${confirmedTickets.length} টি',
                icon: Icons.confirmation_number_rounded,
                color: Colors.blue.shade800,
                bgColor: Colors.blue.shade50,
                onTap: () => tabController.animateTo(2),
              ),
              _buildMetricCard(
                title: 'বাতিল রিকোয়েস্ট',
                value: '${rejectedTickets.length} টি',
                icon: Icons.cancel_rounded,
                color: AppColors.primaryRed,
                bgColor: Colors.red.shade50,
                onTap: () => tabController.animateTo(2),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Live Bus Trip Manifest Banner
          InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const BusManifestScreen(),
                ),
              );
            },
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primaryRed, AppColors.primaryRedDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(35),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.format_list_bulleted_rounded,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'লাইভ বাস ট্রিপ ও যাত্রী ম্যানিফেস্ট 📋',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'দৈনিক ৪টি ট্রিপের সিট হিসাব, প্যাসেঞ্জার লিস্ট ও সুপারভাইজার কপি',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 11.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          const Text(
            'দ্রুত অ্যাকশনসমূহ (Quick Management)',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _buildQuickActionButton(
                  icon: Icons.analytics_rounded,
                  label: 'রেভিনিউ ড্যাশবোর্ড',
                  color: AppColors.primaryGreen,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => RevenueAnalyticsScreen(
                          initialTickets: confirmedTickets,
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildQuickActionButton(
                  icon: Icons.badge_rounded,
                  label: 'বাস ট্রিপ ম্যানিফেস্ট',
                  color: Colors.blue.shade800,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const BusManifestScreen(),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // 1. Modular bKash Payment Config Card
          AdminPaymentConfigCard(firestoreService: firestoreService),

          // 2. Modular Route Fare Hub
          AdminRouteFareHub(firestoreService: firestoreService),
        ],
      ),
    );
  }
}
