import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:intl/intl.dart';
import '../core/app_colors.dart';
import '../models/ticket_model.dart';
import '../services/firestore_service.dart';
import '../widgets/official_e_ticket_stub.dart';
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

    String cleanTime = rawTime.replaceAll(RegExp(r'\([^)]*\)'), '').trim();
    cleanTime = cleanTime.replaceAll('(', '').replaceAll(')', '').trim();
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
                  child: OfficialETicketStub(
                    ticketId: widget.ticketId,
                    passengerName: widget.passengerName,
                    phoneNumber: widget.phoneNumber,
                    busName: widget.busName,
                    from: widget.from,
                    to: widget.to,
                    journeyDateAndDepartureTime: journeyDateAndDepartureTime,
                    seats: widget.seats,
                    amountPaid: widget.amountPaid,
                    issueDateTime: issueDateTime,
                    currentStatus: currentStatus,
                  ),
                ),

                const SizedBox(height: 28),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.home_rounded, size: 20),
                        label: const Text('হোমে যান'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white, width: 1.5),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: () {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const HomeScreen(),
                            ),
                            (route) => false,
                          );
                        },
                      ),
                    ),
                    if (isConfirmed) ...[
                      const SizedBox(width: 14),
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: _isSaving
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: AppColors.primaryRed,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.download_rounded, size: 20),
                          label: Text(
                            _isSaving ? 'সেভ হচ্ছে...' : 'টিকিট সেভ করুন',
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: AppColors.primaryRed,
                            elevation: 3,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            textStyle: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          onPressed: _isSaving ? null : _captureAndSaveTicket,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
