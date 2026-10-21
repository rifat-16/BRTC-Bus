import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/app_colors.dart';
import '../../models/ticket_model.dart';

class AdminETicketDialog {
  static void show(BuildContext context, TicketModel ticket) {
    final String issueDateTime = DateFormat('dd MMM yyyy, hh:mm a')
        .format(ticket.createdAt ?? DateTime.now());

    final bool isConfirmed = ticket.status == 'CONFIRMED';
    final bool isPending = ticket.status == 'PENDING';

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black.withAlpha(160),
      transitionDuration: const Duration(milliseconds: 350),
      pageBuilder: (context, anim1, anim2) {
        return const SizedBox.shrink();
      },
      transitionBuilder: (context, anim1, anim2, child) {
        final curvedValue = Curves.easeOutBack.transform(anim1.value);
        return Transform.scale(
          scale: curvedValue,
          child: Opacity(
            opacity: anim1.value,
            child: Dialog(
              backgroundColor: Colors.transparent,
              insetPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Top Right Close Circle Button
                    Align(
                      alignment: Alignment.topRight,
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close_rounded,
                              color: Colors.black87, size: 20),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Main E-Ticket Container
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 20,
                            offset: Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Red Header
                          Container(
                            padding: const EdgeInsets.all(18),
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.primaryRed,
                                  AppColors.primaryRedDark
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.vertical(
                                top: Radius.circular(24),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius:
                                            BorderRadius.circular(8),
                                      ),
                                      child: const Icon(
                                        Icons.directions_bus_filled_rounded,
                                        color: AppColors.primaryRed,
                                        size: 22,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    const Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'BRTC OFFICIAL E-TICKET',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13.5,
                                            letterSpacing: 0.8,
                                          ),
                                        ),
                                        Text(
                                          'বাংলাদেশ সড়ক পরিবহন কর্পোরেশন',
                                          style: TextStyle(
                                            color: Colors.white70,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isConfirmed
                                        ? AppColors.primaryGreen
                                        : (isPending
                                            ? Colors.orange.shade800
                                            : AppColors.primaryRed),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        isConfirmed
                                            ? Icons.verified_rounded
                                            : (isPending
                                                ? Icons.access_time_filled_rounded
                                                : Icons.error_rounded),
                                        size: 14,
                                        color: Colors.white,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        isConfirmed
                                            ? 'PAID'
                                            : ticket.status,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 11.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Ticket Details Body
                          Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  ticket.busName,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primaryRed,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppColors.backgroundColor,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        ticket.from,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                        ),
                                      ),
                                      const Icon(Icons.arrow_forward_rounded,
                                          color: AppColors.primaryRed),
                                      Text(
                                        ticket.to,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),
                                _buildDialogRow('টিকিট নম্বর (ID)',
                                    '#${ticket.ticketId ?? "BRTC-TKT"}'),
                                _buildDialogRow(
                                    'যাত্রীর নাম', ticket.passengerName),
                                _buildDialogRow(
                                    'মোবাইল নম্বর', ticket.passengerPhone),
                                _buildDialogRow(
                                    'যাত্রার তারিখ', ticket.journeyDate),
                                _buildDialogRow('সিট নম্বর',
                                    ticket.selectedSeats.join(', ')),
                                _buildDialogRow(
                                    'পরিশোধিত মূল্য', '৳ ${ticket.totalAmount}',
                                    isBold: true),
                                _buildDialogRow(
                                    'পেমেন্ট মেথড', ticket.paymentMethod),
                                _buildDialogRow('TrxID', ticket.trxId),
                                _buildDialogRow('ইস্যু সময়', issueDateTime),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  static Widget _buildDialogRow(String label, String value,
      {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
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
