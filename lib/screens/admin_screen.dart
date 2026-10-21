import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_colors.dart';
import '../models/ticket_model.dart';
import '../providers/auth_provider.dart';
import '../services/firestore_service.dart';
import '../widgets/admin/admin_counter_tab.dart';
import '../widgets/admin/admin_directory_tab.dart';
import '../widgets/admin/admin_overview_tab.dart';
import '../widgets/admin/admin_pending_tab.dart';
import '../widgets/admin/admin_seat_manager_tab.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen>
    with SingleTickerProviderStateMixin {
  final FirestoreService _firestoreService = FirestoreService();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    if (!authProvider.isAdmin) {
      return Scaffold(
        backgroundColor: AppColors.backgroundColor,
        appBar: AppBar(
          title: const Text('অননুমোদিত অ্যাক্সেস (Access Denied)'),
          backgroundColor: AppColors.primaryRed,
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              child: Padding(
                padding: const EdgeInsets.all(28.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.primaryRed.withAlpha(20),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.gpp_bad_rounded,
                        size: 56,
                        color: AppColors.primaryRed,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'অননুমোদিত অ্যাক্সেস!',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'আপনার জিমেইল একাউন্টটি (${authProvider.email}) এডমিন হিসেবে অনুমোদিত নয়। শুধুমাত্র নির্দিষ্ট বিআরটিসি এডমিন জিমেইল দিয়েই এই প্যানেল ব্যবহার করা সম্ভব।',
                      style: const TextStyle(
                        fontSize: 13.5,
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.arrow_back_rounded, size: 18),
                      label: const Text('হোম স্ক্রিনে ফিরে যান'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryRed,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        title: const Text('BRTC Admin Control Center'),
        elevation: 2,
        backgroundColor: AppColors.primaryRedDark,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: const [
            Tab(icon: Icon(Icons.analytics_rounded, size: 18), text: 'ওভারভিউ'),
            Tab(icon: Icon(Icons.hourglass_top_rounded, size: 18), text: 'পেন্ডিং ইনবক্স'),
            Tab(icon: Icon(Icons.receipt_long_rounded, size: 18), text: 'টিকিট ডিরেক্টরি'),
            Tab(icon: Icon(Icons.event_seat_rounded, size: 18), text: 'সিট ম্যানেজার'),
            Tab(icon: Icon(Icons.point_of_sale_rounded, size: 18), text: 'কাউন্টার বুকিং'),
          ],
        ),
      ),
      body: StreamBuilder<List<TicketModel>>(
        stream: _firestoreService.getAllTicketsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primaryRed),
            );
          }

          final allTickets = snapshot.data ?? [];
          final pendingTickets =
              allTickets.where((t) => t.status == 'PENDING').toList();

          return TabBarView(
            controller: _tabController,
            children: [
              AdminOverviewTab(
                allTickets: allTickets,
                tabController: _tabController,
                firestoreService: _firestoreService,
              ),
              AdminPendingTab(
                pendingTickets: pendingTickets,
                firestoreService: _firestoreService,
              ),
              AdminDirectoryTab(
                allTickets: allTickets,
              ),
              AdminSeatManagerTab(
                firestoreService: _firestoreService,
              ),
              AdminCounterTab(
                firestoreService: _firestoreService,
              ),
            ],
          );
        },
      ),
    );
  }
}
