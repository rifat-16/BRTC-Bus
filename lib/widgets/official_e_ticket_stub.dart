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
  final bool isCompact;

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
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final bool isPending = currentStatus == 'PENDING';
    final bool isConfirmed = currentStatus == 'CONFIRMED';

    final double outerPadding = isCompact ? 12.0 : 20.0;
    final double headerPadding = isCompact ? 12.0 : 18.0;
    final double dividerHeight = isCompact ? 10.0 : 18.0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isCompact ? 18 : 24),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          // Official BRTC Red Banner
          Container(
            padding: EdgeInsets.all(headerPadding),
            decoration: BoxDecoration(
              gradient: AppColors.darkHeaderGradient,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(isCompact ? 18 : 24),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.directions_bus_filled_rounded,
                          color: AppColors.primaryRed,
                          size: isCompact ? 18 : 20,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'BRTC OFFICIAL E-TICKET',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: isCompact ? 12 : 13,
                                letterSpacing: 0.5,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const Text(
                              'বাংলাদেশ সড়ক পরিবহন কর্পোরেশন',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 10,
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
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isPending
                            ? Icons.access_time_filled_rounded
                            : (isConfirmed
                                ? Icons.verified_rounded
                                : Icons.error_rounded),
                        size: 13,
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
                          fontSize: 11,
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
            padding: EdgeInsets.all(outerPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  busName,
                  style: TextStyle(
                    fontSize: isCompact ? 14.5 : 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryRed,
                  ),
                ),
                SizedBox(height: isCompact ? 8 : 14),

                // Route Timeline Card
                Container(
                  padding: EdgeInsets.all(isCompact ? 10 : 14),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundColor,
                    borderRadius: BorderRadius.circular(isCompact ? 12 : 16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('From (যাত্রা)',
                              style: TextStyle(color: Colors.grey, fontSize: 10.5)),
                          const SizedBox(height: 2),
                          Text(
                            from,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: isCompact ? 13.5 : 15,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: EdgeInsets.all(isCompact ? 6 : 8),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.arrow_forward_rounded,
                          color: AppColors.primaryRed,
                          size: isCompact ? 16 : 18,
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text('To (গন্তব্য)',
                              style: TextStyle(color: Colors.grey, fontSize: 10.5)),
                          const SizedBox(height: 2),
                          Text(
                            to,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: isCompact ? 13.5 : 15,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                SizedBox(height: isCompact ? 10 : 16),

                // Passenger & Journey Grid
                _buildDetailRow('যাত্রীর নাম (Passenger)', passengerName, isCompact),
                Divider(height: dividerHeight),
                _buildDetailRow('মোবাইল নম্বর (Phone)', phoneNumber, isCompact),
                Divider(height: dividerHeight),
                _buildDetailRow(
                    'যাত্রার তারিখ ও সময় (Date & Time)', journeyDateAndDepartureTime, isCompact),
                Divider(height: dividerHeight),
                _buildDetailRow('সিট নম্বর (Seat)', seats.join(', '), isCompact),
                Divider(height: dividerHeight),
                _buildDetailRow('ইস্যুর সময় (Issued)', issueDateTime, isCompact),
                Divider(height: dividerHeight),
                _buildDetailRow(
                  'মোট পরিশোধিত মূল্য',
                  '৳ $amountPaid',
                  isCompact,
                  isHighlight: true,
                ),
              ],
            ),
          ),

          // Ticket Stub Tear-Off Dashed Line
          Row(
            children: [
              const SizedBox(
                height: 20,
                width: 10,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.primaryRedDark,
                    borderRadius: BorderRadius.horizontal(
                      right: Radius.circular(10),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
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
                height: 20,
                width: 10,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.primaryRedDark,
                    borderRadius: BorderRadius.horizontal(
                      left: Radius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Bottom QR Code & Supervisor Scanner Stub
          Container(
            padding: EdgeInsets.all(isCompact ? 12 : 20),
            child: Column(
              children: [
                if (isConfirmed) ...[
                  // QR Scanner Box for Confirmed Tickets
                  Container(
                    padding: EdgeInsets.all(isCompact ? 8 : 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.grey.shade200),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(8),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.qr_code_2_rounded,
                      size: isCompact ? 68 : 90,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  SelectableText(
                    'Ticket ID: $ticketId',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: isCompact ? 12 : 13,
                      letterSpacing: 1.0,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'বাসে ওঠার সময় সুপারভাইজারকে এই টিকিট বা কিউআর কোডটি দেখান',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: isCompact ? 11 : 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ] else if (isPending) ...[
                  Container(
                    padding: EdgeInsets.all(isCompact ? 10 : 16),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.hourglass_bottom_rounded,
                          color: Colors.orange,
                          size: isCompact ? 28 : 36,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'পেমেন্ট ভেরিফিকেশন পেন্ডিং রয়েছে',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: isCompact ? 13 : 14,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'এডমিন আপনার TrxID যাচাই করে অনুমোদন দিলে এখানে কিউআর কোড চলে আসবে।',
                          style: TextStyle(
                            fontSize: isCompact ? 11 : 12,
                            color: Colors.grey.shade800,
                            height: 1.3,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  Container(
                    padding: EdgeInsets.all(isCompact ? 10 : 16),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Text(
                      'পেমেন্ট তথ্যের সাথে মিল না থাকায় রিকোয়েস্টটি বাতিল করা হয়েছে।',
                      style: TextStyle(
                        fontSize: isCompact ? 11 : 12,
                        color: AppColors.primaryRed,
                        height: 1.3,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
                SizedBox(height: isCompact ? 8 : 14),

                // Reporting Time Notice Box
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(isCompact ? 8 : 12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline_rounded,
                          size: isCompact ? 16 : 20, color: Colors.orange.shade900),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'বিশেষ দ্রষ্টব্য: বাস ছাড়ার ১৫ মিনিট পূর্বে নির্দিষ্ট কাউন্টারে উপস্থিত থাকুন।',
                          style: TextStyle(
                            fontSize: isCompact ? 10.5 : 11.5,
                            fontWeight: FontWeight.w600,
                            color: Colors.orange.shade900,
                            height: 1.25,
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

  Widget _buildDetailRow(String label, String value, bool isCompact,
      {bool isHighlight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: isCompact ? 11.5 : 12,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: isCompact ? 12 : 12.5,
            fontWeight: isHighlight ? FontWeight.w900 : FontWeight.bold,
            color:
                isHighlight ? AppColors.primaryGreen : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
