import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../core/app_colors.dart';
import '../models/ticket_model.dart';
import '../services/download_service.dart';
import '../services/firestore_service.dart';
import '../widgets/desktop_web_navbar.dart';
import '../widgets/official_e_ticket_stub.dart';
import '../widgets/responsive_layout.dart';
import 'home_screen.dart';
import 'ticket_screen.dart';

class MyTicketsScreen extends StatefulWidget {
  const MyTicketsScreen({super.key});

  @override
  State<MyTicketsScreen> createState() => _MyTicketsScreenState();
}

class _MyTicketsScreenState extends State<MyTicketsScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  TicketModel? _selectedTicket;
  final GlobalKey _ticketKey = GlobalKey();
  bool _isSaving = false;

  Future<void> _captureAndSaveTicket(TicketModel ticket) async {
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
        await DownloadService.downloadImage(
          pngBytes,
          'BRTC_Ticket_${ticket.ticketId ?? "BRTC-TKT"}.png',
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.check_circle_rounded, color: Colors.white),
                  SizedBox(width: 8),
                  Text('টিকিটটি সফলভাবে ডাউনলোড করা হয়েছে!'),
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

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final String currentUserId = user?.uid ?? 'guest';
    final isDesktop = ResponsiveLayout.isDesktop(context);

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: isDesktop
          ? const DesktopWebNavbar()
          : AppBar(
              title: const Text('My Tickets (আমার টিকিটসমূহ)'),
              elevation: 2,
              backgroundColor: AppColors.primaryRedDark,
            ),
      body: StreamBuilder<List<TicketModel>>(
        stream: _firestoreService.getUserTicketsStream(currentUserId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(
                color: AppColors.primaryRed,
              ),
            );
          }

          final tickets = snapshot.data ?? [];

          // Sort tickets descending (NEWEST tickets on TOP, OLDER tickets at BOTTOM)
          tickets.sort((a, b) {
            if (a.createdAt == null && b.createdAt == null) return 0;
            if (a.createdAt == null) return 1;
            if (b.createdAt == null) return -1;
            return b.createdAt!.compareTo(a.createdAt!);
          });

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

          // Default selected ticket for desktop master-detail
          if (_selectedTicket == null ||
              !tickets.any((t) => t.ticketId == _selectedTicket?.ticketId)) {
            _selectedTicket = tickets.first;
          }

          return ResponsiveLayout(
            mobile: _buildMobileList(context, tickets),
            desktop: _buildDesktopMasterDetail(context, tickets),
          );
        },
      ),
    );
  }

  Widget _buildMobileList(BuildContext context, List<TicketModel> tickets) {
    return ListView.builder(
      padding: const EdgeInsets.all(18),
      itemCount: tickets.length,
      itemBuilder: (context, index) {
        final ticket = tickets[index];
        return _buildTicketCard(context, ticket, isSelected: false);
      },
    );
  }

  Widget _buildDesktopMasterDetail(
    BuildContext context,
    List<TicketModel> tickets,
  ) {
    final activeTicket = _selectedTicket ?? tickets.first;
    final String issueDateTime =
        DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now());

    final screenHeight = MediaQuery.of(context).size.height;
    final availableHeight = (screenHeight - 110).clamp(580.0, 3000.0);

    return ConstrainedWebContainer(
      maxWidth: 1200,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
      child: SizedBox(
        height: availableHeight,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left Column: Independently Scrollable Master List of Tickets (42% width)
            Expanded(
              flex: 42,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Page Title Header Bar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'আমার টিকিটসমূহ',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryRed,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'বুকিং করা টিকিটে চাপ দিলে ডানে টিকিট দেখতে পাবেন',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryRed.withAlpha(15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.primaryRed.withAlpha(40),
                          ),
                        ),
                        child: Text(
                          'মোট ${tickets.length} টি',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryRed,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // Scrollable Left Tickets List
                  Expanded(
                    child: ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      itemCount: tickets.length,
                      itemBuilder: (context, index) {
                        final ticket = tickets[index];
                        final bool isSelected =
                            (ticket.ticketId == activeTicket.ticketId);

                        return InkWell(
                          onTap: () {
                            setState(() {
                              _selectedTicket = ticket;
                            });
                          },
                          borderRadius: BorderRadius.circular(20),
                          child: _buildTicketCard(context, ticket,
                              isSelected: isSelected),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 28),

            // Right Column: Fixed Pinned Live Interactive E-Ticket Panel (58% width)
            Expanded(
              flex: 58,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: StreamBuilder<TicketModel?>(
                  stream: _firestoreService
                      .getTicketStream(activeTicket.ticketId ?? ''),
                  builder: (context, snapshot) {
                    final liveTicket = snapshot.data;
                    final currentStatus =
                        liveTicket?.status ?? activeTicket.status;

                    final bool liveIsConfirmed = currentStatus == 'CONFIRMED';

                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.primaryRed.withAlpha(40),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(8),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // RepaintBoundary wrapping Official E-Ticket Stub
                          RepaintBoundary(
                            key: _ticketKey,
                            child: OfficialETicketStub(
                              ticketId: activeTicket.ticketId ?? 'BRTC-TKT',
                              passengerName: activeTicket.passengerName,
                              phoneNumber: activeTicket.passengerPhone,
                              busName: activeTicket.busName,
                              from: activeTicket.from,
                              to: activeTicket.to,
                              journeyDateAndDepartureTime:
                                  activeTicket.journeyDate,
                              seats: activeTicket.selectedSeats,
                              amountPaid: activeTicket.totalAmount,
                              issueDateTime: issueDateTime,
                              currentStatus: currentStatus,
                              isCompact: true,
                            ),
                          ),

                          const SizedBox(height: 14),

                          // Action Buttons Toolbar
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  icon:
                                      const Icon(Icons.home_rounded, size: 18),
                                  label: const Text('হোমে যান'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.primaryRed,
                                    side: const BorderSide(
                                        color: AppColors.primaryRed,
                                        width: 1.5),
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 11),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  onPressed: () {
                                    Navigator.pushAndRemoveUntil(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const HomeScreen(),
                                      ),
                                      (route) => false,
                                    );
                                  },
                                ),
                              ),
                              if (liveIsConfirmed) ...[
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    icon: _isSaving
                                        ? const SizedBox(
                                            width: 18,
                                            height: 18,
                                            child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : const Icon(Icons.download_rounded,
                                            size: 18),
                                    label: Text(
                                      _isSaving
                                          ? 'সেভ হচ্ছে...'
                                          : 'টিকিট ডাউনলোড',
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primaryGreen,
                                      foregroundColor: Colors.white,
                                      elevation: 2,
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 11),
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(12),
                                      ),
                                    ),
                                    onPressed: _isSaving
                                        ? null
                                        : () => _captureAndSaveTicket(
                                            activeTicket),
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
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTicketCard(
    BuildContext context,
    TicketModel ticket, {
    required bool isSelected,
  }) {
    final bool isPending = ticket.status == 'PENDING';
    final bool isConfirmed = ticket.status == 'CONFIRMED';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSelected
              ? AppColors.primaryGreen
              : (isPending
                  ? Colors.orange.shade300
                  : (isConfirmed
                      ? AppColors.primaryGreen.withAlpha(80)
                      : AppColors.primaryRed.withAlpha(80))),
          width: isSelected ? 2.5 : 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: isSelected
                ? AppColors.primaryGreen.withAlpha(30)
                : Colors.black.withAlpha(10),
            blurRadius: isSelected ? 12 : 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
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
                      fontSize: 14.5,
                      color: AppColors.primaryRed,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),

                // Status Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isPending
                        ? Colors.orange.shade100
                        : (isConfirmed
                            ? AppColors.primaryGreen.withAlpha(25)
                            : Colors.red.shade100),
                    borderRadius: BorderRadius.circular(10),
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
                        size: 12,
                        color: isPending
                            ? Colors.orange.shade900
                            : (isConfirmed
                                ? AppColors.primaryGreen
                                : AppColors.primaryRed),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isPending
                            ? 'PENDING'
                            : (isConfirmed ? 'CONFIRMED' : 'REJECTED'),
                        style: TextStyle(
                          fontSize: 10.5,
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

            const Divider(height: 16),

            // Route Timeline
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: AppColors.backgroundColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    ticket.from,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_rounded,
                    color: AppColors.primaryRed,
                    size: 15,
                  ),
                  Text(
                    ticket.to,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

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

            const SizedBox(height: 12),

            // Mobile Action Button
            if (!ResponsiveLayout.isDesktop(context))
              SizedBox(
                width: double.infinity,
                height: 42,
                child: ElevatedButton.icon(
                  icon: Icon(
                    isConfirmed
                        ? Icons.qr_code_2_rounded
                        : Icons.receipt_long_rounded,
                    size: 17,
                  ),
                  label: Text(
                    isConfirmed
                        ? 'ই-টিকিট ও কিউআর কোড দেখুন ➔'
                        : 'টিকিটের স্ট্যাটাস ভিউ করুন ➔',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
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
  }

  Widget _buildTicketCardRow(String label, String value,
      {required IconData icon, bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        children: [
          Icon(icon, size: 14, color: AppColors.textSecondary),
          const SizedBox(width: 6),
          Text(
            '$label: ',
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
