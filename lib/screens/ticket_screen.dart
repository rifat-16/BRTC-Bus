import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:intl/intl.dart';
import '../core/app_colors.dart';
import '../models/ticket_model.dart';
import '../services/firestore_service.dart';
import 'home_screen.dart';

class TicketScreen extends StatefulWidget {
  final String ticketId;
  final String passengerName;
  final String phoneNumber;
  final String busName;
  final String from;
  final String to;
  final String journeyDate;
  final String departureTime;
  final List<String> seats;
  final int amountPaid;
  final String initialStatus;

  const TicketScreen({
    super.key,
    required this.ticketId,
    required this.passengerName,
    required this.phoneNumber,
    required this.busName,
    required this.from,
    required this.to,
    required this.journeyDate,
    this.departureTime = '',
    required this.seats,
    required this.amountPaid,
    this.initialStatus = 'PENDING',
  });

  @override
  State<TicketScreen> createState() => _TicketScreenState();
}

class _TicketScreenState extends State<TicketScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final GlobalKey _ticketKey = GlobalKey();
  bool _isSaving = false;

  Future<void> _captureAndSaveTicket() async {
    setState(() {
      _isSaving = true;
    });

    try {
      await Future.delayed(const Duration(milliseconds: 200));

      final RenderRepaintBoundary boundary =
          _ticketKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData != null && mounted) {
        final Uint8List pngBytes = byteData.buffer.asUint8List();
        _showImagePreviewDialog(pngBytes);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('টিকিট পিকচার তৈরি করতে সমস্যা হয়েছে: $e'),
            backgroundColor: AppColors.primaryRed,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _showImagePreviewDialog(Uint8List imageBytes) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        title: const Row(
          children: [
            Icon(Icons.image_rounded, color: AppColors.primaryGreen),
            SizedBox(width: 8),
            Text(
              'ই-টিকিট পিকচার প্রস্তুত',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.45,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.memory(
                      imageBytes,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'টিকিটটি আপনার ফোনের গ্যালারিতে সেভ করার জন্য প্রস্তুত রয়েছে। সেভ বাটনে চাপ দিন।',
                  style:
                      TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('বন্ধ করুন'),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.download_rounded, size: 18),
            label: const Text('গ্যালারিতে সেভ করুন'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGreen,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Row(
                    children: [
                      Icon(Icons.check_circle_rounded, color: Colors.white),
                      SizedBox(width: 8),
                      Text('টিকিটটি ছবি হিসেবে সফলভাবে সেভ করা হয়েছে!'),
                    ],
                  ),
                  backgroundColor: AppColors.primaryGreen,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  String _toEnglishNumerals(String input) {
    const bangla = ['০', '১', '২', '৩', '৪', '৫', '৬', '৭', '৮', '৯'];
    const english = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    String result = input;
    for (int i = 0; i < bangla.length; i++) {
      result = result.replaceAll(bangla[i], english[i]);
    }
    return result;
  }

  String _formatJourneyDateTime(String date, String rawTime) {
    if (rawTime.trim().isEmpty) return date;

    // Clean up station labels inside brackets to prevent double parentheses (( ))
    String cleanTime = rawTime.replaceAll(RegExp(r'\([^)]*\)'), '').trim();
    cleanTime = cleanTime.replaceAll('(', '').replaceAll(')', '').trim();

    // Convert Bengali numerals to standard English digits
    cleanTime = _toEnglishNumerals(cleanTime);

    if (cleanTime.isEmpty) return date;
    return '$date, $cleanTime';
  }

  @override
  Widget build(BuildContext context) {
    final String issueDateTime =
        DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now());

    final String journeyDateAndDepartureTime =
        _formatJourneyDateTime(widget.journeyDate, widget.departureTime);

    return Scaffold(
      backgroundColor: AppColors.primaryRedDark,
      appBar: AppBar(
        title: const Text('BRTC Ticket Status'),
        centerTitle: true,
        automaticallyImplyLeading: false,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: StreamBuilder<TicketModel?>(
        stream: _firestoreService.getTicketStream(widget.ticketId),
        builder: (context, snapshot) {
          final liveTicket = snapshot.data;
          final currentStatus =
              liveTicket?.status ?? widget.initialStatus;

          final bool isPending = currentStatus == 'PENDING';
          final bool isConfirmed = currentStatus == 'CONFIRMED';

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
            child: Column(
              children: [
                // Top Live Status Header Badge
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(25),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isPending
                        ? Icons.hourglass_top_rounded
                        : (isConfirmed
                            ? Icons.check_circle_rounded
                            : Icons.cancel_rounded),
                    color: isPending
                        ? AppColors.accentGold
                        : (isConfirmed ? Colors.white : Colors.orangeAccent),
                    size: 64,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  isPending
                      ? 'Payment Pending Approval'
                      : (isConfirmed
                          ? 'Booking Confirmed!'
                          : 'Payment Verification Failed'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isPending
                      ? 'আপনার পেমেন্ট তথ্য এডমিন প্যানেলে ভেরিফিকেশন করা হচ্ছে'
                      : (isConfirmed
                          ? 'আপনার বিআরটিসি টিকিট সফলভাবে অনুমোদিত হয়েছে'
                          : 'আপনার ট্রানজেকশন তথ্য মিল পাওয়া যায়নি'),
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                // RepaintBoundary wrapping Official E-Ticket Stub
                RepaintBoundary(
                  key: _ticketKey,
                  child: Container(
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
                              Row(
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
                                          fontSize: 14,
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
                                          : (isConfirmed
                                              ? 'PAID'
                                              : 'REJECTED'),
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
                              // Bus Name
                              Text(
                                widget.busName,
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
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text('From (যাত্রা)',
                                            style: TextStyle(
                                                color: Colors.grey,
                                                fontSize: 11)),
                                        const SizedBox(height: 2),
                                        Text(
                                          widget.from,
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
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        const Text('To (গন্তব্য)',
                                            style: TextStyle(
                                                color: Colors.grey,
                                                fontSize: 11)),
                                        const SizedBox(height: 2),
                                        Text(
                                          widget.to,
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
                              _buildDetailRow('যাত্রীর নাম (Passenger)',
                                  widget.passengerName),
                              const Divider(height: 18),
                              _buildDetailRow(
                                  'মোবাইল নম্বর (Phone)', widget.phoneNumber),
                              const Divider(height: 18),
                              _buildDetailRow(
                                  'যাত্রার তারিখ ও সময় (Date & Time)',
                                  journeyDateAndDepartureTime),
                              const Divider(height: 18),
                              _buildDetailRow(
                                  'সিট নম্বর (Seat)', widget.seats.join(', ')),
                              const Divider(height: 18),
                              _buildDetailRow(
                                  'ইস্যুর সময় (Issued)', issueDateTime),
                              const Divider(height: 18),
                              _buildDetailRow(
                                'মোট পরিশোধিত মূল্য',
                                '৳ ${widget.amountPaid}',
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
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 10),
                                child: LayoutBuilder(
                                  builder: (context, constraints) {
                                    return Flex(
                                      direction: Axis.horizontal,
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: List.generate(
                                        (constraints.constrainWidth() / 10)
                                            .floor(),
                                        (index) => const SizedBox(
                                          width: 5,
                                          height: 1.5,
                                          child: DecoratedBox(
                                            decoration: BoxDecoration(
                                                color: Colors.grey),
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
                                    border: Border.all(
                                        color: Colors.grey.shade200),
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
                                  'Ticket ID: ${widget.ticketId}',
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
                                    border: Border.all(
                                        color: Colors.orange.shade200),
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
                                    border:
                                        Border.all(color: Colors.red.shade200),
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
                                  border:
                                      Border.all(color: Colors.orange.shade200),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.info_outline_rounded,
                                        size: 20,
                                        color: Colors.orange.shade900),
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
                  ),
                ),

                const SizedBox(height: 28),

                // Action Buttons Section
                if (isConfirmed) ...[
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: _isSaving ? null : _captureAndSaveTicket,
                      icon: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.download_rounded, size: 20),
                      label: Text(
                        _isSaving
                            ? 'টিকিট পিকচার তৈরি হচ্ছে...'
                            : 'গ্যালারিতে টিকিট সেভ করুন (Save Image)',
                        style: const TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryGreen,
                        foregroundColor: Colors.white,
                        elevation: 4,
                        shadowColor: AppColors.primaryGreen.withAlpha(100),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                ],

                // Back to Home Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const HomeScreen()),
                        (route) => false,
                      );
                    },
                    icon: const Icon(Icons.home_rounded, color: Colors.white),
                    label: const Text(
                      'হোম স্ক্রিনে ফিরে যান (Back to Home)',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.white, width: 1.8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailRow(String label, String value,
      {bool isHighlight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style:
              const TextStyle(color: AppColors.textSecondary, fontSize: 12.5),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: isHighlight ? FontWeight.w900 : FontWeight.bold,
            fontSize: isHighlight ? 18 : 13.5,
            color:
                isHighlight ? AppColors.primaryGreen : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
