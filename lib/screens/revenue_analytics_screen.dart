import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../models/ticket_model.dart';
import '../services/firestore_service.dart';

class RevenueAnalyticsScreen extends StatefulWidget {
  final List<TicketModel>? initialTickets;

  const RevenueAnalyticsScreen({super.key, this.initialTickets});

  @override
  State<RevenueAnalyticsScreen> createState() => _RevenueAnalyticsScreenState();
}

class _RevenueAnalyticsScreenState extends State<RevenueAnalyticsScreen>
    with SingleTickerProviderStateMixin {
  final FirestoreService _firestoreService = FirestoreService();

  String _timeRange = 'ALL'; // ALL, TODAY, WEEK, MONTH

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750),
    );

    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );

    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    ));

    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  bool _isTicketInTimeRange(TicketModel ticket) {
    if (ticket.status != 'CONFIRMED') return false;
    if (_timeRange == 'ALL') return true;

    final DateTime now = DateTime.now();
    final DateTime ticketDate = ticket.createdAt ?? now;

    if (_timeRange == 'TODAY') {
      return ticketDate.year == now.year &&
          ticketDate.month == now.month &&
          ticketDate.day == now.day;
    } else if (_timeRange == 'WEEK') {
      final DateTime weekAgo = now.subtract(const Duration(days: 7));
      return ticketDate.isAfter(weekAgo);
    } else if (_timeRange == 'MONTH') {
      return ticketDate.year == now.year && ticketDate.month == now.month;
    }

    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        title: const Text('রেভিনিউ অ্যানালিটিক্স ড্যাশবোর্ড'),
        backgroundColor: AppColors.primaryRedDark,
        elevation: 2,
      ),
      body: StreamBuilder<List<TicketModel>>(
        stream: _firestoreService.getAllTicketsStream(),
        initialData: widget.initialTickets,
        builder: (context, snapshot) {
          final allTickets = snapshot.data ?? [];
          final confirmedTickets =
              allTickets.where(_isTicketInTimeRange).toList();

          int totalRevenue = 0;
          int bkashRevenue = 0;
          int nagadRevenue = 0;
          int rocketRevenue = 0;
          int cardRevenue = 0;
          int counterCashRevenue = 0;

          int bus1Revenue = 0;
          int bus2Revenue = 0;

          int bus1Count = 0;
          int bus2Count = 0;

          for (final t in confirmedTickets) {
            totalRevenue += t.totalAmount;

            final method = t.paymentMethod.toUpperCase();
            if (method.contains('BKASH')) {
              bkashRevenue += t.totalAmount;
            } else if (method.contains('NAGAD')) {
              nagadRevenue += t.totalAmount;
            } else if (method.contains('ROCKET')) {
              rocketRevenue += t.totalAmount;
            } else if (method.contains('CARD')) {
              cardRevenue += t.totalAmount;
            } else if (method.contains('COUNTER') || method.contains('CASH')) {
              counterCashRevenue += t.totalAmount;
            } else {
              bkashRevenue += t.totalAmount;
            }

            if (t.busName.contains('Service - 1') ||
                t.busName.contains('সার্ভিস - ১')) {
              bus1Revenue += t.totalAmount;
              bus1Count++;
            } else {
              bus2Revenue += t.totalAmount;
              bus2Count++;
            }
          }

          final int onlineTotal =
              bkashRevenue + nagadRevenue + rocketRevenue + cardRevenue;

          return SlideTransition(
            position: _slideAnim,
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Time Filter Pills
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildFilterPill('ALL', 'সর্বমোট আয়'),
                          const SizedBox(width: 8),
                          _buildFilterPill('TODAY', 'আজকের আয়'),
                          const SizedBox(width: 8),
                          _buildFilterPill('WEEK', 'এই সপ্তাহের আয়'),
                          const SizedBox(width: 8),
                          _buildFilterPill('MONTH', 'এই মাসের আয়'),
                        ],
                      ),
                    ),

                    const SizedBox(height: 18),

                    // Top Grand Total Revenue Banner
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        gradient: AppColors.darkHeaderGradient,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 16,
                            offset: Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'মোট অনুমোদিত আয় (Total Earnings)',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withAlpha(30),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(Icons.trending_up_rounded,
                                        color: AppColors.accentGold, size: 16),
                                    SizedBox(width: 4),
                                    Text(
                                      'VERIFIED',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            '৳ $totalRevenue',
                            style: const TextStyle(
                              fontSize: 34,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 1.0,
                            ),
                          ),
                          const SizedBox(height: 14),
                          const Divider(color: Colors.white24, height: 1),
                          const SizedBox(height: 14),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildSubMetric(
                                label: 'অনুমোদিত টিকিট',
                                value: '${confirmedTickets.length} টি',
                              ),
                              _buildSubMetric(
                                label: 'গড় টিকিট মূল্য',
                                value: confirmedTickets.isNotEmpty
                                    ? '৳ ${(totalRevenue / confirmedTickets.length).round()}'
                                    : '৳ 0',
                              ),
                              _buildSubMetric(
                                label: 'অনলাইন কালেকশন',
                                value: '৳ $onlineTotal',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Payment Method Breakdown Card
                    const Text(
                      'পেমেন্ট মেথড অনুপাত (Payment Breakdown)',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),

                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(8),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          _buildPaymentBarItem(
                            label: 'bKash (বিকাশ)',
                            amount: bkashRevenue,
                            total: totalRevenue,
                            color: const Color(0xFFE2136E),
                            icon: Icons.account_balance_wallet_rounded,
                          ),
                          const Divider(height: 20),
                          _buildPaymentBarItem(
                            label: 'Counter Cash (ক্যাশ)',
                            amount: counterCashRevenue,
                            total: totalRevenue,
                            color: AppColors.primaryGreen,
                            icon: Icons.point_of_sale_rounded,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Bus Service Comparison Section
                    const Text(
                      'বাস সার্ভিস ভিত্তিক আয় (Revenue per Bus)',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: _buildBusRevenueCard(
                            busName: 'BRTC AC Service - 1',
                            subtext: 'বড়চওনা / সখিপুর ➔ ঢাকা',
                            revenue: bus1Revenue,
                            ticketCount: bus1Count,
                            color: AppColors.primaryRed,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildBusRevenueCard(
                            busName: 'BRTC AC Service - 2',
                            subtext: 'গারোবাজার / সাগরদিঘী ➔ ঢাকা',
                            revenue: bus2Revenue,
                            ticketCount: bus2Count,
                            color: Colors.blue.shade800,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Recent Confirmed Transactions List
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'সাম্প্রতিক অনুমোদিত আয়সমূহ',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'মোট ${confirmedTickets.length} টি',
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    confirmedTickets.isEmpty
                        ? Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Center(
                              child: Text(
                                'এই সময়সীমার মধ্যে কোনো অনুমোদিত লেনদেন নেই',
                                style: TextStyle(color: AppColors.textSecondary),
                              ),
                            ),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: confirmedTickets.length > 8
                                ? 8
                                : confirmedTickets.length,
                            itemBuilder: (context, index) {
                              final ticket = confirmedTickets[index];
                              return Card(
                                margin: const EdgeInsets.only(bottom: 10),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                elevation: 1,
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 6),
                                  leading: Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryGreen.withAlpha(20),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.check_circle_rounded,
                                      color: AppColors.primaryGreen,
                                      size: 20,
                                    ),
                                  ),
                                  title: Text(
                                    ticket.passengerName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  subtitle: Text(
                                    '${ticket.busName.split('(').first.trim()} • ${ticket.selectedSeats.join(', ')}',
                                    style: const TextStyle(fontSize: 11.5),
                                  ),
                                  trailing: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        '৳ ${ticket.totalAmount}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w900,
                                          fontSize: 15,
                                          color: AppColors.primaryGreen,
                                        ),
                                      ),
                                      Text(
                                        ticket.paymentMethod,
                                        style: const TextStyle(
                                          fontSize: 10.5,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFilterPill(String value, String label) {
    final bool isSelected = _timeRange == value;

    return FilterChip(
      selected: isSelected,
      label: Text(label),
      selectedColor: AppColors.primaryRed.withAlpha(30),
      checkmarkColor: AppColors.primaryRed,
      labelStyle: TextStyle(
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        color: isSelected ? AppColors.primaryRed : AppColors.textPrimary,
        fontSize: 12.5,
      ),
      onSelected: (bool selected) {
        setState(() {
          _timeRange = value;
        });
      },
    );
  }

  Widget _buildSubMetric({required String label, required String value}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 11),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 13.5,
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentBarItem({
    required String label,
    required int amount,
    required int total,
    required Color color,
    required IconData icon,
  }) {
    final double percentage = total > 0 ? (amount / total) : 0.0;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 18),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ],
            ),
            Text(
              '৳ $amount (${(percentage * 100).toStringAsFixed(1)}%)',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                color: color,
                fontSize: 13,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: percentage,
            minHeight: 8,
            backgroundColor: color.withAlpha(25),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  Widget _buildBusRevenueCard({
    required String busName,
    required String subtext,
    required int revenue,
    required int ticketCount,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withAlpha(50)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(6),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            busName,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtext,
            style: const TextStyle(fontSize: 10.5, color: AppColors.textSecondary),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          Text(
            '৳ $revenue',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          Text(
            'বিক্রিত টিকিট: $ticketCount টি',
            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
