import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/app_colors.dart';
import '../models/ticket_model.dart';
import '../services/firestore_service.dart';
import 'ticket_screen.dart';

class MyTicketsScreen extends StatelessWidget {
  const MyTicketsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final FirestoreService firestoreService = FirestoreService();
    final String currentUserId = user?.uid ?? 'guest';

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        title: const Text('My Tickets (আমার টিকিটসমূহ)'),
        elevation: 2,
        backgroundColor: AppColors.primaryRedDark,
      ),
      body: StreamBuilder<List<TicketModel>>(
        stream: firestoreService.getUserTicketsStream(currentUserId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: AppColors.primaryRed,
              ),
            );
          }

          final tickets = snapshot.data ?? [];

          if (tickets.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.confirmation_number_outlined,
                        size: 64,
                        color: Colors.grey.shade400,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'আপনার কোনো বুকিং করা টিকিট নেই',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'আপনি এখনও পর্যন্ত কোনো বিআরটিসি টিকিট কাটেননি। টিকিট কাটলে তা এখানে রিয়েল-টাইম দেখা যাবে।',
                      style: TextStyle(
                        fontSize: 13.5,
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.directions_bus_rounded, size: 18),
                      label: const Text('টিকিট বুকিং শুরু করুন'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 22,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(18),
            itemCount: tickets.length,
            itemBuilder: (context, index) {
              final ticket = tickets[index];

              final bool isPending = ticket.status == 'PENDING';
              final bool isConfirmed = ticket.status == 'CONFIRMED';

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                    color: isPending
                        ? Colors.orange.shade300
                        : (isConfirmed
                            ? AppColors.primaryGreen.withAlpha(80)
                            : AppColors.primaryRed.withAlpha(80)),
                    width: 1.5,
                  ),
                ),
                elevation: 3,
                child: Padding(
                  padding: const EdgeInsets.all(18.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Row: Bus Name & Live Status Badge
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              ticket.busName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: AppColors.primaryRed,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),

                          // Prominent Status Chip on Card
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: isPending
                                  ? Colors.orange.shade100
                                  : (isConfirmed
                                      ? AppColors.primaryGreen.withAlpha(25)
                                      : Colors.red.shade100),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isPending
                                      ? Icons.hourglass_top_rounded
                                      : (isConfirmed
                                          ? Icons.check_circle_rounded
                                          : Icons.cancel_rounded),
                                  size: 13,
                                  color: isPending
                                      ? Colors.orange.shade900
                                      : (isConfirmed
                                          ? AppColors.primaryGreen
                                          : AppColors.primaryRed),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  isPending
                                      ? 'PENDING (পেন্ডিং)'
                                      : (isConfirmed
                                          ? 'CONFIRMED (অনুমোদিত)'
                                          : 'REJECTED (বাতিল)'),
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w900,
                                    color: isPending
                                        ? Colors.orange.shade900
                                        : (isConfirmed
                                            ? AppColors.primaryGreen
                                            : AppColors.primaryRed),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const Divider(height: 20),

                      // Route Timeline
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.backgroundColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              ticket.from,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const Icon(
                              Icons.arrow_forward_rounded,
                              color: AppColors.primaryRed,
                              size: 18,
                            ),
                            Text(
                              ticket.to,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Details Grid
                      _buildTicketCardRow(
                        'যাত্রার তারিখ',
                        ticket.journeyDate,
                        icon: Icons.calendar_today_rounded,
                      ),
                      _buildTicketCardRow(
                        'সিট নম্বর',
                        ticket.selectedSeats.join(', '),
                        icon: Icons.event_seat_rounded,
                      ),
                      _buildTicketCardRow(
                        'পরিশোধিত মূল্য',
                        '৳ ${ticket.totalAmount}',
                        icon: Icons.payments_rounded,
                        isBold: true,
                      ),

                      const SizedBox(height: 14),

                      // Action Button
                      SizedBox(
                        width: double.infinity,
                        height: 46,
                        child: ElevatedButton.icon(
                          icon: Icon(
                            isConfirmed
                                ? Icons.qr_code_2_rounded
                                : Icons.receipt_long_rounded,
                            size: 18,
                          ),
                          label: Text(
                            isConfirmed
                                ? 'ই-টিকিট ও কিউআর কোড দেখুন ➔'
                                : 'টিকিটের স্ট্যাটাস ভিউ করুন ➔',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13.5,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isConfirmed
                                ? AppColors.primaryGreen
                                : (isPending
                                    ? Colors.orange.shade800
                                    : AppColors.primaryRed),
                            foregroundColor: Colors.white,
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => TicketScreen(
                                  ticketId: ticket.ticketId ?? 'BRTC-TKT',
                                  passengerName: ticket.passengerName,
                                  phoneNumber: ticket.passengerPhone,
                                  busName: ticket.busName,
                                  from: ticket.from,
                                  to: ticket.to,
                                  journeyDate: ticket.journeyDate,
                                  seats: ticket.selectedSeats,
                                  amountPaid: ticket.totalAmount,
                                  initialStatus: ticket.status,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildTicketCardRow(String label, String value,
      {required IconData icon, bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.0),
      child: Row(
        children: [
          Icon(icon, size: 15, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: const TextStyle(
              fontSize: 12.5,
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isBold ? FontWeight.w900 : FontWeight.bold,
              color: isBold ? AppColors.primaryGreen : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
