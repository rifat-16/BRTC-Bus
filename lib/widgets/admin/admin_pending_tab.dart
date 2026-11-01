import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/app_colors.dart';
import '../../models/ticket_model.dart';
import '../../services/firestore_service.dart';
import '../responsive_layout.dart';

class AdminPendingTab extends StatefulWidget {
  final List<TicketModel> pendingTickets;
  final FirestoreService firestoreService;

  const AdminPendingTab({
    super.key,
    required this.pendingTickets,
    required this.firestoreService,
  });

  @override
  State<AdminPendingTab> createState() => _AdminPendingTabState();
}

class _AdminPendingTabState extends State<AdminPendingTab> {
  void _makePhoneCall(String phoneNumber) async {
    final cleanNum = phoneNumber.replaceAll(RegExp(r'[^0-9+]'), '');
    final Uri url = Uri(scheme: 'tel', path: cleanNum);
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url);
      } else {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
  }

  void _approveTicket(TicketModel ticket) async {
    final String busIdToUse = ticket.busId.isNotEmpty
        ? ticket.busId
        : (FirestoreService.officialBRTCBuses
            .firstWhere((b) => b.busName == ticket.busName,
                orElse: () => FirestoreService.officialBRTCBuses.first)
            .id);

    try {
      await widget.firestoreService.approveTicket(
        ticketId: ticket.ticketId!,
        busId: busIdToUse,
        journeyDate: ticket.journeyDate,
        selectedSeats: ticket.selectedSeats,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'টিকিট #${ticket.ticketId} সফলভাবে অনুমোদন করা হয়েছে!',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.primaryGreen,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('অনুমোদন করতে সমস্যা হয়েছে: $e'),
            backgroundColor: AppColors.primaryRed,
          ),
        );
      }
    }
  }

  void _rejectTicket(TicketModel ticket) async {
    final String busIdToUse = ticket.busId.isNotEmpty
        ? ticket.busId
        : (FirestoreService.officialBRTCBuses
            .firstWhere((b) => b.busName == ticket.busName,
                orElse: () => FirestoreService.officialBRTCBuses.first)
            .id);

    try {
      await widget.firestoreService.rejectTicket(
        busId: busIdToUse,
        journeyDate: ticket.journeyDate,
        selectedSeats: ticket.selectedSeats,
        ticketId: ticket.ticketId!,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.cancel_rounded, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'টিকিট #${ticket.ticketId} বাতিল করা হয়েছে ও সিট মুক্ত করা হয়েছে।',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.primaryRed,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('বাতিল করতে সমস্যা হয়েছে: $e'),
            backgroundColor: AppColors.primaryRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.pendingTickets.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle_outline_rounded,
                  size: 64, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              const Text(
                'কোনো পেন্ডিং পেমেন্ট রিকোয়েস্ট নেই!',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'যাত্রীরা নতুন পেমেন্ট সাবমিট করলে তা এখানে রিয়েল-টাইম চলে আসবে।',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    final isDesktop = ResponsiveLayout.isDesktop(context);

    if (isDesktop) {
      return SingleChildScrollView(
        child: ConstrainedWebContainer(
          maxWidth: 1200,
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'পেন্ডিং ভেরিফিকেশন ইনবক্স (Pending Inbox)',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryRed,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'পেমেন্ট যাচাই করে ১-ক্লিকে অনুমোদন বা বাতিল করুন',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.hourglass_top_rounded,
                          size: 16,
                          color: Colors.orange,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'মোট ${widget.pendingTickets.length} টি পেন্ডিং',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange.shade900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // 2-Column Desktop Grid
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: widget.pendingTickets.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisExtent: 345,
                  crossAxisSpacing: 18,
                  mainAxisSpacing: 18,
                ),
                itemBuilder: (context, index) {
                  final ticket = widget.pendingTickets[index];
                  return _buildPendingCard(ticket);
                },
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(18),
      itemCount: widget.pendingTickets.length,
      itemBuilder: (context, index) {
        final ticket = widget.pendingTickets[index];
        return _buildPendingCard(ticket);
      },
    );
  }

  Widget _buildPendingCard(TicketModel ticket) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.orange.shade300, width: 1.5),
      ),
      elevation: 3,
      shadowColor: Colors.black.withAlpha(15),
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.hourglass_top_rounded,
                          size: 13, color: Colors.orange),
                      SizedBox(width: 4),
                      Text(
                        'PENDING APPROVAL',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const Divider(height: 16),

            // Passenger Details
            _buildInfoRow('যাত্রীর নাম', ticket.passengerName),
            Row(
              children: [
                Expanded(
                  child:
                      _buildInfoRow('মোবাইল নম্বর', ticket.passengerPhone),
                ),
                IconButton(
                  icon: const Icon(Icons.phone_rounded,
                      color: AppColors.primaryGreen, size: 20),
                  tooltip: 'যাত্রীকে কল দিন',
                  onPressed: () => _makePhoneCall(ticket.passengerPhone),
                ),
              ],
            ),
            _buildInfoRow('রুট', '${ticket.from} ➔ ${ticket.to}'),
            _buildInfoRow('যাত্রার তারিখ', ticket.journeyDate),
            _buildInfoRow('সিট নম্বর', ticket.selectedSeats.join(', ')),
            _buildInfoRow('পরিশোধিত মূল্য', '৳ ${ticket.totalAmount}',
                isBold: true),
            _buildInfoRow('পেমেন্ট মেথড', ticket.paymentMethod),
            _buildInfoRow('TrxID', ticket.trxId, isBold: true),

            const SizedBox(height: 14),

            // Action Buttons Row
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.cancel_rounded, size: 16),
                    label: const Text(
                      'বাতিল করুন',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primaryRed,
                      side: const BorderSide(color: AppColors.primaryRed),
                      padding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => _rejectTicket(ticket),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.check_circle_rounded, size: 16),
                    label: const Text(
                      'অনুমোদন করুন',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGreen,
                      foregroundColor: Colors.white,
                      elevation: 2,
                      padding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => _approveTicket(ticket),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: isBold ? FontWeight.w900 : FontWeight.bold,
              color: isBold ? AppColors.primaryGreen : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
