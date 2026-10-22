import 'package:flutter/material.dart';
import '../core/app_colors.dart';

class OfficialETicketStub extends StatelessWidget {
  final String ticketId;
  final String passengerName;
  final String phoneNumber;
  final String busName;
  final String from;
  final String to;
  final String journeyDateAndDepartureTime;
  final List<String> seats;
  final int amountPaid;
  final String issueDateTime;
  final String currentStatus;

  const OfficialETicketStub({
    super.key,
    required this.ticketId,
    required this.passengerName,
    required this.phoneNumber,
    required this.busName,
    required this.from,
    required this.to,
    required this.journeyDateAndDepartureTime,
    required this.seats,
    required this.amountPaid,
    required this.issueDateTime,
    required this.currentStatus,
  });

  @override
  Widget build(BuildContext context) {
    final bool isPending = currentStatus == 'PENDING';
    final bool isConfirmed = currentStatus == 'CONFIRMED';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Colors.black38,
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Official BRTC Red Banner
          Container(
            padding: const EdgeInsets.all(18),
            decoration: const BoxDecoration(
              gradient: AppColors.darkHeaderGradient,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.directions_bus_filled_rounded,
                          color: AppColors.primaryRed,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'BRTC OFFICIAL E-TICKET',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                letterSpacing: 0.5,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'বাংলাদেশ সড়ক পরিবহন কর্পোরেশন',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 10.5,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isPending
                        ? Colors.orange.shade800
                        : (isConfirmed
                            ? AppColors.primaryGreen
                            : AppColors.primaryRed),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isPending
                            ? Icons.access_time_filled_rounded
                            : (isConfirmed
                                ? Icons.verified_rounded
                                : Icons.error_rounded),
                        size: 14,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isPending
                            ? 'PENDING'
                            : (isConfirmed ? 'PAID' : 'REJECTED'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Main Ticket Details
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  busName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryRed,
                  ),
                ),
                const SizedBox(height: 14),

                // Route Timeline Card
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('From (যাত্রা)',
                              style: TextStyle(color: Colors.grey, fontSize: 11)),
                          const SizedBox(height: 2),
                          Text(
                            from,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.arrow_forward_rounded,
                          color: AppColors.primaryRed,
                          size: 18,
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text('To (গন্তব্য)',
                              style: TextStyle(color: Colors.grey, fontSize: 11)),
                          const SizedBox(height: 2),
                          Text(
                            to,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Passenger & Journey Grid
                _buildDetailRow('যাত্রীর নাম (Passenger)', passengerName),
                const Divider(height: 18),
                _buildDetailRow('মোবাইল নম্বর (Phone)', phoneNumber),
                const Divider(height: 18),
                _buildDetailRow(
                    'যাত্রার তারিখ ও সময় (Date & Time)', journeyDateAndDepartureTime),
                const Divider(height: 18),
                _buildDetailRow('সিট নম্বর (Seat)', seats.join(', ')),
                const Divider(height: 18),
                _buildDetailRow('ইস্যুর সময় (Issued)', issueDateTime),
                const Divider(height: 18),
                _buildDetailRow(
                  'মোট পরিশোধিত মূল্য',
                  '৳ $amountPaid',
                  isHighlight: true,
                ),
              ],
            ),
          ),

          // Ticket Stub Tear-Off Dashed Line
          Row(
            children: [
              const SizedBox(
                height: 24,
                width: 12,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.primaryRedDark,
                    borderRadius: BorderRadius.horizontal(
                      right: Radius.circular(12),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return Flex(
                        direction: Axis.horizontal,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: List.generate(
                          (constraints.constrainWidth() / 10).floor(),
                          (index) => const SizedBox(
                            width: 5,
                            height: 1.5,
                            child: DecoratedBox(
                              decoration: BoxDecoration(color: Colors.grey),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(
                height: 24,
                width: 12,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.primaryRedDark,
                    borderRadius: BorderRadius.horizontal(
                      left: Radius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Bottom QR Code & Supervisor Scanner Stub
          Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                if (isConfirmed) ...[
                  // QR Scanner Box for Confirmed Tickets
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(8),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.qr_code_2_rounded,
                      size: 90,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  SelectableText(
                    'Ticket ID: $ticketId',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      letterSpacing: 1.1,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'বাসে ওঠার সময় সুপারভাইজারকে এই টিকিট বা কিউআর কোডটি দেখান',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ] else if (isPending) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.hourglass_bottom_rounded,
                          color: Colors.orange,
                          size: 36,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'পেমেন্ট ভেরিফিকেশন পেন্ডিং রয়েছে',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'এডমিন আপনার TrxID তথ্য যাচাই করে অনুমোদন দিলে এখানে স্বয়ংক্রিয়ভাবে ডাউনলোডযোগ্য কিউআর কোড চলে আসবে।',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade800,
                            height: 1.35,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: const Text(
                      'পেমেন্ট তথ্যের সাথে মিল না থাকায় রিকোয়েস্টটি বাতিল করা হয়েছে। অনুগ্রহ করে হেল্পলাইনে যোগাযোগ করুন।',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.primaryRed,
                        height: 1.35,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
                const SizedBox(height: 14),

                // Reporting Time Notice Box
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline_rounded,
                          size: 20, color: Colors.orange.shade900),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'বিশেষ দ্রষ্টব্য: বাস ছাড়ার ১৫ মিনিট পূর্বে নির্দিষ্ট কাউন্টারে উপস্থিত থাকুন।',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: Colors.orange.shade900,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value,
      {bool isHighlight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: isHighlight ? FontWeight.w900 : FontWeight.bold,
            color:
                isHighlight ? AppColors.primaryGreen : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
