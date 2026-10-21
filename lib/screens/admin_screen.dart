import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/app_colors.dart';
import '../models/bus_model.dart';
import '../models/ticket_model.dart';
import '../providers/auth_provider.dart';
import '../services/firestore_service.dart';
import '../widgets/bus_seat_plan_widget.dart';
import 'revenue_analytics_screen.dart';
import 'bus_manifest_screen.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen>
    with TickerProviderStateMixin {
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _searchController = TextEditingController();

  // Counter Form Controllers
  final _counterFormKey = GlobalKey<FormState>();
  final TextEditingController _counterNameController = TextEditingController();
  final TextEditingController _counterPhoneController = TextEditingController();

  late TabController _tabController;
  late AnimationController _entryAnimController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Search & Filter States
  String _searchQuery = '';
  String _statusFilter = 'ALL';

  // Seat Manager States
  BusModel _selectedBus = FirestoreService.officialBRTCBuses.first;
  DateTime _seatManagerDate = DateTime.now();

  // Counter Form States
  BusModel _counterSelectedBus = FirestoreService.officialBRTCBuses.first;
  DateTime _counterJourneyDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);

    _entryAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _entryAnimController,
      curve: Curves.easeOut,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entryAnimController,
      curve: Curves.easeOutCubic,
    ));

    _entryAnimController.forward();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _entryAnimController.dispose();
    _searchController.dispose();
    _counterNameController.dispose();
    _counterPhoneController.dispose();
    super.dispose();
  }

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

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label ক্লিপবোর্ডে কপি করা হয়েছে!'),
        backgroundColor: AppColors.primaryGreen,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _approveTicket(TicketModel ticket) async {
    final String busIdToUse = ticket.busId.isNotEmpty
        ? ticket.busId
        : (FirestoreService.officialBRTCBuses
            .firstWhere((b) => b.busName == ticket.busName,
                orElse: () => _selectedBus)
            .id);

    try {
      await _firestoreService.approveTicket(
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
                orElse: () => _selectedBus)
            .id);

    try {
      await _firestoreService.rejectTicket(
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

  void _showETicketPopup(BuildContext context, TicketModel ticket) {
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
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.close_rounded,
                            color: AppColors.primaryRed,
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Official E-Ticket Card Stub
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black45,
                            blurRadius: 24,
                            offset: Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // BRTC Red Top Banner
                          Container(
                            padding: const EdgeInsets.all(18),
                            decoration: const BoxDecoration(
                              gradient: AppColors.darkHeaderGradient,
                              borderRadius: BorderRadius.vertical(
                                top: Radius.circular(28),
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

                          // Bus & Passenger Details
                          Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  ticket.busName,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primaryRed,
                                  ),
                                ),
                                const SizedBox(height: 14),

                                // Route Banner
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
                                            ticket.from,
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
                                            ticket.to,
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

                                _buildAdminRow('যাত্রীর নাম (Passenger)', ticket.passengerName),
                                const Divider(height: 18),
                                _buildAdminRow('মোবাইল নম্বর (Phone)', ticket.passengerPhone),
                                const Divider(height: 18),
                                _buildAdminRow('যাত্রার তারিখ (Date)', ticket.journeyDate),
                                const Divider(height: 18),
                                _buildAdminRow('সিট নম্বর (Seat)', ticket.selectedSeats.join(', ')),
                                const Divider(height: 18),
                                _buildAdminRow('ইস্যুর সময় (Issued)', issueDateTime),
                                const Divider(height: 18),
                                _buildAdminRow('মোট পরিশোধিত মূল্য', '৳ ${ticket.totalAmount}', isHighlight: true),
                              ],
                            ),
                          ),

                          // Dashed Tear-Off Line
                          Row(
                            children: [
                              const SizedBox(
                                height: 24,
                                width: 12,
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    color: Colors.black54,
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
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
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
                                    color: Colors.black54,
                                    borderRadius: BorderRadius.horizontal(
                                      left: Radius.circular(12),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          // Bottom QR Code & Notice Section
                          Container(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              children: [
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
                                  'Ticket ID: ${ticket.ticketId ?? 'BRTC-TICKET'}',
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
                                const SizedBox(height: 14),
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

  void _showEditRouteFareDialog(BuildContext context, RouteFareModel route) {
    final TextEditingController fareController =
        TextEditingController(text: route.fare.toString());

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            void adjustFare(int delta) {
              final current = int.tryParse(fareController.text) ?? route.fare;
              final newVal = (current + delta).clamp(10, 2000);
              fareController.text = newVal.toString();
              setStateDialog(() {});
            }

            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryRed.withAlpha(20),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.price_change_rounded,
                      color: AppColors.primaryRed,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'রুটভিত্তিক ভাড়া পরিবর্তন',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'রুট: ${route.from} ➔ ${route.to}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: AppColors.primaryRed,
                    ),
                  ),
                  const SizedBox(height: 18),

                  const Text(
                    'নতুন ভাড়া নির্ধারণ করুন (৳):',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 8),

                  TextField(
                    controller: fareController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primaryGreen,
                    ),
                    decoration: InputDecoration(
                      prefixText: '৳ ',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(
                          color: AppColors.primaryGreen,
                          width: 2,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildQuickAdjustChip('-৫০', () => adjustFare(-50)),
                      _buildQuickAdjustChip('-১০', () => adjustFare(-10)),
                      _buildQuickAdjustChip('+১০', () => adjustFare(10)),
                      _buildQuickAdjustChip('+৫০', () => adjustFare(50)),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('বাতিল'),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.check_circle_rounded, size: 18),
                  label: const Text('ভাড়া সেভ করুন'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () async {
                    final int? newFare =
                        int.tryParse(fareController.text.trim());
                    if (newFare == null || newFare <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('অনুগ্রহ করে সঠিক ভাড়া ইনপুট দিন'),
                          backgroundColor: AppColors.primaryRed,
                        ),
                      );
                      return;
                    }

                    final nav = Navigator.of(context);
                    final messenger = ScaffoldMessenger.of(context);

                    nav.pop();

                    await _firestoreService.updateRouteFare(
                      routeId: route.id,
                      newFare: newFare,
                    );

                    messenger.showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            const Icon(Icons.check_circle_rounded,
                                color: Colors.white),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '${route.from} ➔ ${route.to} এর নতুন ভাড়া ৳ $newFare সফলভাবে আপডেট করা হয়েছে!',
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
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildQuickAdjustChip(String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.backgroundColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildRouteFareSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'রুটভিত্তিক ভাড়া নিয়ন্ত্রণ মডিউল (Route Fare Hub)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.primaryGreen.withAlpha(20),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'LIVE SYNC',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryGreen,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        StreamBuilder<List<RouteFareModel>>(
          stream: _firestoreService.getRouteFaresStream(),
          builder: (context, snapshot) {
            final routeFares =
                snapshot.data ?? FirestoreService.officialRouteFares;

            return Column(
              children: routeFares.map((route) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 1,
                  child: Padding(
                    padding: const EdgeInsets.all(14.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${route.from}  ➔  ${route.to}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: AppColors.primaryRed,
                                ),
                              ),
                              const SizedBox(height: 2),
                              const Text(
                                'স্টেশন-টু-স্টেশন সরাসরি ভাড়া',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primaryGreen.withAlpha(20),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '৳ ${route.fare}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.primaryGreen,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(
                                Icons.edit_note_rounded,
                                color: AppColors.primaryRed,
                                size: 24,
                              ),
                              tooltip: 'ভাড়া পরিবর্তন করুন',
                              onPressed: () =>
                                  _showEditRouteFareDialog(context, route),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  void _showEditBkashNumberDialog(BuildContext context, String currentNumber) {
    final TextEditingController numberController =
        TextEditingController(text: currentNumber);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFE2136E).withAlpha(20),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.phone_android_rounded,
                  color: Color(0xFFE2136E),
                  size: 22,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'bKash পার্সোনাল নম্বর পরিবর্তন',
                  style: TextStyle(
                    fontSize: 16.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'যাত্রীরা টিকিট কাটার সময় এই বিকাশ পার্সোনাল নম্বরে Send Money করবেন:',
                style: TextStyle(
                  fontSize: 12.5,
                  color: AppColors.textSecondary,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: numberController,
                keyboardType: TextInputType.phone,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                  letterSpacing: 1.0,
                ),
                decoration: InputDecoration(
                  labelText: 'bKash Personal Mobile Number',
                  prefixIcon: const Icon(Icons.phone_android_rounded),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                      color: Color(0xFFE2136E),
                      width: 2,
                    ),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('বাতিল'),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.check_circle_rounded, size: 18),
              label: const Text('নম্বর সেভ করুন'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () async {
                final String newNum = numberController.text.trim();
                if (newNum.isEmpty || newNum.length < 11) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('অনুগ্রহ করে সঠিক ১১ ডিজিটের মোবাইল নম্বর দিন'),
                      backgroundColor: AppColors.primaryRed,
                    ),
                  );
                  return;
                }

                final nav = Navigator.of(context);
                final messenger = ScaffoldMessenger.of(context);

                nav.pop();

                await _firestoreService.updateBkashNumber(newNum);

                messenger.showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        const Icon(Icons.check_circle_rounded, color: Colors.white),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'bKash পার্সোনাল নম্বর সফলভাবে $newNum আপডেট করা হয়েছে!',
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
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildPaymentConfigSection() {
    return StreamBuilder<String>(
      stream: _firestoreService.getPaymentConfigStream(),
      builder: (context, snapshot) {
        final String bkashNumber = snapshot.data ?? '01712345678';

        return Card(
          margin: const EdgeInsets.only(top: 20, bottom: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(color: const Color(0xFFE2136E).withAlpha(80), width: 1.5),
          ),
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE2136E).withAlpha(20),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.phone_android_rounded,
                            color: Color(0xFFE2136E),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'পেমেন্ট নম্বর সেটিংস (Payment Settings)',
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.edit_rounded, size: 15),
                      label: const Text('পরিবর্তন করুন', style: TextStyle(fontSize: 11.5)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFE2136E),
                        side: const BorderSide(color: Color(0xFFE2136E)),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () => _showEditBkashNumberDialog(context, bkashNumber),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF0F5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'bKash পার্সোনাল নম্বর:',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        bkashNumber,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFFE2136E),
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
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
                final confirmedTickets =
                    allTickets.where((t) => t.status == 'CONFIRMED').toList();
                final rejectedTickets =
                    allTickets.where((t) => t.status == 'REJECTED').toList();

                int totalRevenue = 0;
                for (final t in confirmedTickets) {
                  totalRevenue += t.totalAmount;
                }

                final filteredTickets = allTickets.where((t) {
                  bool matchesQuery = _searchQuery.isEmpty ||
                      t.passengerName
                          .toLowerCase()
                          .contains(_searchQuery.toLowerCase()) ||
                      t.passengerPhone.contains(_searchQuery) ||
                      t.trxId.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                      (t.ticketId ?? '')
                          .toLowerCase()
                          .contains(_searchQuery.toLowerCase());

                  bool matchesStatus =
                      _statusFilter == 'ALL' || t.status == _statusFilter;

                  return matchesQuery && matchesStatus;
                }).toList();

                return SlideTransition(
                  position: _slideAnimation,
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildDashboardTab(
                          allTickets: allTickets,
                          pendingTickets: pendingTickets,
                          confirmedTickets: confirmedTickets,
                          rejectedTickets: rejectedTickets,
                          totalRevenue: totalRevenue,
                        ),
                        _buildPendingInboxTab(pendingTickets),
                        _buildDirectoryTab(filteredTickets),
                        _buildSeatManagerTab(),
                        _buildCounterBookingTab(),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  // TAB 1: Dashboard Overview
  Widget _buildDashboardTab({
    required List<TicketModel> allTickets,
    required List<TicketModel> pendingTickets,
    required List<TicketModel> confirmedTickets,
    required List<TicketModel> rejectedTickets,
    required int totalRevenue,
  }) {
    final user = FirebaseAuth.instance.currentUser;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.primaryGreen.withAlpha(50)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(10),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primaryGreen.withAlpha(20),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.verified_user_rounded,
                    color: AppColors.primaryGreen,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.email != null
                            ? 'অফিশিয়াল এডমিন: ${user!.email}'
                            : 'এডমিন কন্ট্রোল সেন্টার সক্রিয় (Master PIN Verified)',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'ফায়ারবেস রিয়েল-টাইম কাস্টমার টিকিট ডাটাবেজ',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.5,
            children: [
              _buildMetricCard(
                title: 'পেন্ডিং রিকোয়েস্ট',
                value: '${pendingTickets.length} টি',
                icon: Icons.hourglass_top_rounded,
                color: Colors.orange.shade800,
                bgColor: Colors.orange.shade50,
                onTap: () => _tabController.animateTo(1),
              ),
              _buildMetricCard(
                title: 'অনুমোদিত আয়',
                value: '৳ $totalRevenue',
                icon: Icons.account_balance_wallet_rounded,
                color: AppColors.primaryGreen,
                bgColor: Colors.green.shade50,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => RevenueAnalyticsScreen(
                        initialTickets: confirmedTickets,
                      ),
                    ),
                  );
                },
              ),
              _buildMetricCard(
                title: 'মোট ইস্যুকৃত টিকিট',
                value: '${confirmedTickets.length} টি',
                icon: Icons.confirmation_number_rounded,
                color: Colors.blue.shade800,
                bgColor: Colors.blue.shade50,
                onTap: () => _tabController.animateTo(2),
              ),
              _buildMetricCard(
                title: 'বাতিল রিকোয়েস্ট',
                value: '${rejectedTickets.length} টি',
                icon: Icons.cancel_rounded,
                color: AppColors.primaryRed,
                bgColor: Colors.red.shade50,
                onTap: () => _tabController.animateTo(2),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Live Bus Trip Manifest Banner
          InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const BusManifestScreen(),
                ),
              );
            },
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primaryRed, AppColors.primaryRedDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(35),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.format_list_bulleted_rounded,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'লাইভ বাস ট্রিপ ও যাত্রী ম্যানিফেস্ট 📋',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'দৈনিক ৪টি ট্রিপের সিট হিসাব, প্যাসেঞ্জার লিস্ট ও সুপারভাইজার কপি',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 11.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          const Text(
            'দ্রুত অ্যাকশনসমূহ (Quick Management)',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _buildQuickActionButton(
                  icon: Icons.analytics_rounded,
                  label: 'রেভিনিউ ড্যাশবোর্ড',
                  color: AppColors.primaryGreen,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => RevenueAnalyticsScreen(
                          initialTickets: confirmedTickets,
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildQuickActionButton(
                  icon: Icons.badge_rounded,
                  label: 'বাস ট্রিপ ম্যানিফেস্ট',
                  color: Colors.blue.shade800,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const BusManifestScreen(),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          _buildPaymentConfigSection(),

          _buildRouteFareSection(),
        ],
      ),
    );
  }

  // TAB 2: Pending Approval Inbox
  Widget _buildPendingInboxTab(List<TicketModel> pendingTickets) {
    if (pendingTickets.isEmpty) {
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

    return ListView.builder(
      padding: const EdgeInsets.all(18),
      itemCount: pendingTickets.length,
      itemBuilder: (context, index) {
        final ticket = pendingTickets[index];

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: Colors.orange.shade300, width: 1.5),
          ),
          elevation: 3,
          child: Padding(
            padding: const EdgeInsets.all(18.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      ticket.busName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: AppColors.primaryRed,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${ticket.paymentMethod} (PENDING)',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange.shade900,
                        ),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 18),
                _buildAdminRow('যাত্রীর নাম', ticket.passengerName),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'মোবাইল নম্বর:',
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                    Row(
                      children: [
                        Text(
                          ticket.passengerPhone,
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          icon: const Icon(Icons.phone_forwarded_rounded,
                              size: 18, color: AppColors.primaryGreen),
                          onPressed: () =>
                              _makePhoneCall(ticket.passengerPhone),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          tooltip: 'সরাসরি কল করুন',
                        ),
                      ],
                    ),
                  ],
                ),
                _buildAdminRow('রুট', '${ticket.from} ➔ ${ticket.to}'),
                _buildAdminRow('যাত্রার তারিখ', ticket.journeyDate),
                _buildAdminRow('সিট নম্বর', ticket.selectedSeats.join(', ')),
                _buildAdminRow('পরিশোধিত টাকা', '৳ ${ticket.totalAmount}',
                    isBold: true),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'TrxID (প্রমাণ):',
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                    Row(
                      children: [
                        SelectableText(
                          ticket.trxId,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: Colors.orange.shade900,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.copy_rounded,
                              size: 16, color: AppColors.primaryGreen),
                          onPressed: () =>
                              _copyToClipboard(ticket.trxId, 'TrxID'),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          tooltip: 'কপি করুন',
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.check_circle_rounded, size: 16),
                        label: const Text('অনুমোদন করুন (Approve)'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryGreen,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () => _approveTicket(ticket),
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.cancel_rounded, size: 16),
                      label: const Text('বাতিল (Reject)'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primaryRed,
                        side: const BorderSide(color: AppColors.primaryRed),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => _rejectTicket(ticket),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // TAB 3: Tickets Directory with Search & Filter
  Widget _buildDirectoryTab(List<TicketModel> tickets) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Column(
            children: [
              TextField(
                controller: _searchController,
                onChanged: (val) {
                  setState(() {
                    _searchQuery = val.trim();
                  });
                },
                decoration: InputDecoration(
                  hintText: 'নাম, মোবাইল নম্বর বা TrxID দিয়ে খুঁজুন...',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = '';
                            });
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: AppColors.backgroundColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(height: 10),

              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip('ALL', 'সকল টিকিট (${tickets.length})'),
                    const SizedBox(width: 8),
                    _buildFilterChip('PENDING', 'পেন্ডিং (PENDING)'),
                    const SizedBox(width: 8),
                    _buildFilterChip('CONFIRMED', 'অনুমোদিত (CONFIRMED)'),
                    const SizedBox(width: 8),
                    _buildFilterChip('REJECTED', 'বাতিল (REJECTED)'),
                  ],
                ),
              ),
            ],
          ),
        ),

        Expanded(
          child: tickets.isEmpty
              ? Center(
                  child: Text(
                    'কোনো মেলানো টিকিট পাওয়া যায়নি',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: tickets.length,
                  itemBuilder: (context, index) {
                    final ticket = tickets[index];

                    final bool isPending = ticket.status == 'PENDING';
                    final bool isConfirmed = ticket.status == 'CONFIRMED';

                    return Card(
                      margin: const EdgeInsets.only(bottom: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  ticket.busName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14.5,
                                    color: AppColors.primaryRed,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isPending
                                        ? Colors.orange.shade100
                                        : (isConfirmed
                                            ? AppColors.primaryGreen.withAlpha(20)
                                            : Colors.red.shade100),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    ticket.status,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: isPending
                                          ? Colors.orange.shade900
                                          : (isConfirmed
                                              ? AppColors.primaryGreen
                                              : AppColors.primaryRed),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 18),
                            _buildAdminRow('যাত্রীর নাম', ticket.passengerName),
                            _buildAdminRow('মোবাইল নম্বর', ticket.passengerPhone),
                            _buildAdminRow('রুট', '${ticket.from} ➔ ${ticket.to}'),
                            _buildAdminRow('যাত্রার তারিখ', ticket.journeyDate),
                            _buildAdminRow(
                                'সিট নম্বর', ticket.selectedSeats.join(', ')),
                            _buildAdminRow(
                                'পরিশোধিত টাকা', '৳ ${ticket.totalAmount}',
                                isBold: true),
                            if (ticket.trxId.isNotEmpty)
                              _buildAdminRow('TrxID', ticket.trxId),
                            const SizedBox(height: 10),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                icon: const Icon(Icons.receipt_long_rounded,
                                    size: 16),
                                label: const Text('ই-টিকিট ভিউ করুন'),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(
                                      color: AppColors.primaryGreen),
                                  foregroundColor: AppColors.primaryGreen,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                onPressed: () =>
                                    _showETicketPopup(context, ticket),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // TAB 4: Visual Seat Grid Manager (Reusing BusSeatPlanWidget)
  Widget _buildSeatManagerTab() {
    final String formattedDate =
        DateFormat('dd MMM yyyy').format(_seatManagerDate);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(8),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'বাস ও তারিখ সিলেক্ট করুন:',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textSecondary),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<BusModel>(
                  initialValue: _selectedBus,
                  isExpanded: true,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  items: FirestoreService.officialBRTCBuses
                      .map((bus) => DropdownMenuItem(
                            value: bus,
                            child: Text(
                              bus.busName,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _selectedBus = val;
                      });
                    }
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'তারিখ: $formattedDate',
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.calendar_month_rounded, size: 16),
                      label: const Text('তারিখ পাল্টান'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryRed,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _seatManagerDate,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 30)),
                        );
                        if (picked != null) {
                          setState(() {
                            _seatManagerDate = picked;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Reusable Non-Blinking Seat Grid Component
          _AdminIsolatedSeatGrid(
            busId: _selectedBus.id,
            journeyDate: formattedDate,
            firestoreService: _firestoreService,
          ),
        ],
      ),
    );
  }

  // TAB 5: Counter Walk-In Booking Form
  Widget _buildCounterBookingTab() {
    final String formattedDate =
        DateFormat('dd MMM yyyy').format(_counterJourneyDate);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _counterFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'কাউন্টার ক্যাশ টিকিট ইস্যু (Counter Ticket Sales)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text(
              'কাউন্টারে সরাসরি আসা যাত্রীদের জন্য ক্যাশে টিকিট বুকিং দিন:',
              style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 18),

            TextFormField(
              controller: _counterNameController,
              decoration: InputDecoration(
                labelText: 'যাত্রীর নাম',
                prefixIcon: const Icon(Icons.person_rounded),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'যাত্রীর নাম লিখুন' : null,
            ),
            const SizedBox(height: 14),

            TextFormField(
              controller: _counterPhoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'মোবাইল নম্বর',
                prefixIcon: const Icon(Icons.phone_android_rounded),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              validator: (v) => v == null || v.trim().length < 11
                  ? '১১ ডিজিটের মোবাইল নম্বর লিখুন'
                  : null,
            ),
            const SizedBox(height: 14),

            DropdownButtonFormField<BusModel>(
              initialValue: _counterSelectedBus,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: 'বাস ও সার্ভিস সিলেক্ট করুন',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              ),
              items: FirestoreService.officialBRTCBuses
                  .map((bus) => DropdownMenuItem(
                        value: bus,
                        child: Text(bus.busName, overflow: TextOverflow.ellipsis),
                      ))
                  .toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    _counterSelectedBus = val;
                  });
                }
              },
            ),
            const SizedBox(height: 14),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('যাত্রার তারিখ: $formattedDate',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14)),
                OutlinedButton.icon(
                  icon: const Icon(Icons.calendar_month_rounded, size: 16),
                  label: const Text('তারিখ চেঞ্জ'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primaryRed,
                    side: const BorderSide(color: AppColors.primaryRed),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _counterJourneyDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 30)),
                    );
                    if (picked != null) {
                      setState(() {
                        _counterJourneyDate = picked;
                      });
                    }
                  },
                ),
              ],
            ),

            const SizedBox(height: 18),

            _CounterIsolatedSeatSelector(
              bus: _counterSelectedBus,
              journeyDate: formattedDate,
              firestoreService: _firestoreService,
              passengerNameController: _counterNameController,
              passengerPhoneController: _counterPhoneController,
              formKey: _counterFormKey,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final bool isSelected = _statusFilter == value;

    return FilterChip(
      selected: isSelected,
      label: Text(label),
      selectedColor: AppColors.primaryRed.withAlpha(30),
      checkmarkColor: AppColors.primaryRed,
      labelStyle: TextStyle(
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        color: isSelected ? AppColors.primaryRed : AppColors.textPrimary,
      ),
      onSelected: (bool selected) {
        setState(() {
          _statusFilter = value;
        });
      },
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withAlpha(40)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(6),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: bgColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                Icon(Icons.arrow_forward_ios_rounded,
                    size: 12, color: Colors.grey.shade400),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: color,
                  ),
                ),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ElevatedButton.icon(
      icon: Icon(icon, size: 16),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      onPressed: onTap,
    );
  }

  Widget _buildAdminRow(String label, String value,
      {bool isBold = false, bool isHighlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style:
                const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: isHighlight ? 13.5 : 13,
                fontWeight: (isBold || isHighlight)
                    ? FontWeight.w900
                    : FontWeight.bold,
                color: isHighlight
                    ? Colors.orange.shade900
                    : (isBold ? AppColors.primaryGreen : AppColors.textPrimary),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Isolated Seat Grid Manager Component using Reusable BusSeatPlanWidget
class _AdminIsolatedSeatGrid extends StatefulWidget {
  final String busId;
  final String journeyDate;
  final FirestoreService firestoreService;

  const _AdminIsolatedSeatGrid({
    required this.busId,
    required this.journeyDate,
    required this.firestoreService,
  });

  @override
  State<_AdminIsolatedSeatGrid> createState() => _AdminIsolatedSeatGridState();
}

class _AdminIsolatedSeatGridState extends State<_AdminIsolatedSeatGrid> {
  final List<String> _selectedAdminSeats = [];

  void _toggleAdminSeat(String seatId, List<String> bookedSeats) {
    if (bookedSeats.contains(seatId)) return;

    setState(() {
      if (_selectedAdminSeats.contains(seatId)) {
        _selectedAdminSeats.remove(seatId);
      } else {
        _selectedAdminSeats.add(seatId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<ScheduleSeatsData>(
      stream: widget.firestoreService.getScheduleSeatsStream(
        busId: widget.busId,
        journeyDate: widget.journeyDate,
      ),
      builder: (context, snapshot) {
        final seatsData =
            snapshot.data ?? ScheduleSeatsData(bookedSeats: [], lockedSeats: []);

        return Column(
          children: [
            SizedBox(
              height: 540,
              child: BusSeatPlanWidget(
                bookedSeats: seatsData.bookedSeats,
                lockedSeats: seatsData.lockedSeats,
                selectedSeats: _selectedAdminSeats,
                onSeatTap: (seatId) =>
                    _toggleAdminSeat(seatId, seatsData.bookedSeats),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.lock_outline_rounded, size: 16),
                    label: const Text('কাউন্টারের জন্য লক করুন'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange.shade800,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _selectedAdminSeats.isEmpty
                        ? null
                        : () async {
                            await widget.firestoreService.manuallyLockSeats(
                              busId: widget.busId,
                              journeyDate: widget.journeyDate,
                              seats: _selectedAdminSeats,
                            );
                            setState(() {
                              _selectedAdminSeats.clear();
                            });
                          },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.lock_open_rounded, size: 16),
                    label: const Text('সিট মুক্ত করুন'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primaryGreen,
                      side: const BorderSide(color: AppColors.primaryGreen),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _selectedAdminSeats.isEmpty
                        ? null
                        : () async {
                            await widget.firestoreService.manuallyUnlockSeats(
                              busId: widget.busId,
                              journeyDate: widget.journeyDate,
                              seats: _selectedAdminSeats,
                            );
                            setState(() {
                              _selectedAdminSeats.clear();
                            });
                          },
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

/// Counter Isolated Seat Selector Component using Reusable BusSeatPlanWidget
class _CounterIsolatedSeatSelector extends StatefulWidget {
  final BusModel bus;
  final String journeyDate;
  final FirestoreService firestoreService;
  final TextEditingController passengerNameController;
  final TextEditingController passengerPhoneController;
  final GlobalKey<FormState> formKey;

  const _CounterIsolatedSeatSelector({
    required this.bus,
    required this.journeyDate,
    required this.firestoreService,
    required this.passengerNameController,
    required this.passengerPhoneController,
    required this.formKey,
  });

  @override
  State<_CounterIsolatedSeatSelector> createState() =>
      _CounterIsolatedSeatSelectorState();
}

class _CounterIsolatedSeatSelectorState
    extends State<_CounterIsolatedSeatSelector> {
  final List<String> _counterSelectedSeats = [];
  bool _isSubmitting = false;

  void _toggleSeat(String seatId) {
    setState(() {
      if (_counterSelectedSeats.contains(seatId)) {
        _counterSelectedSeats.remove(seatId);
      } else {
        _counterSelectedSeats.add(seatId);
      }
    });
  }

  void _submitCounterTicket() async {
    if (!widget.formKey.currentState!.validate() || _counterSelectedSeats.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('অনুগ্রহ করে যাত্রীর তথ্য ও অন্তত ১টি সিট সিলেক্ট করুন'),
          backgroundColor: AppColors.primaryRed,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final int totalPrice = _counterSelectedSeats.length * widget.bus.fare;

    final ticket = TicketModel(
      userId: 'counter_walkin',
      userEmail: 'counter@brtc.com',
      busName: widget.bus.busName,
      from: widget.bus.from,
      to: widget.bus.to,
      journeyDate: widget.journeyDate,
      selectedSeats: List.from(_counterSelectedSeats),
      totalAmount: totalPrice,
      passengerName: widget.passengerNameController.text.trim(),
      passengerPhone: widget.passengerPhoneController.text.trim(),
      paymentMethod: 'COUNTER CASH',
      trxId: 'COUNTER-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
      status: 'CONFIRMED',
    );

    try {
      final created = await widget.firestoreService.issueCounterTicket(
        busId: widget.bus.id,
        ticket: ticket,
      );

      setState(() {
        _counterSelectedSeats.clear();
        widget.passengerNameController.clear();
        widget.passengerPhoneController.clear();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('কাউন্টার টিকিট #${created.ticketId} সফলভাবে ইস্যু করা হয়েছে!'),
            backgroundColor: AppColors.primaryGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('টিকিট ইস্যু করতে সমস্যা হয়েছে: $e'),
            backgroundColor: AppColors.primaryRed,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final int totalPrice = _counterSelectedSeats.length * widget.bus.fare;

    return StreamBuilder<ScheduleSeatsData>(
      stream: widget.firestoreService.getScheduleSeatsStream(
        busId: widget.bus.id,
        journeyDate: widget.journeyDate,
      ),
      builder: (context, snapshot) {
        final seatsData =
            snapshot.data ?? ScheduleSeatsData(bookedSeats: [], lockedSeats: []);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'সিট সিলেক্ট করুন (সিলেক্টেড: ${_counterSelectedSeats.join(', ')})',
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryGreen),
            ),
            const SizedBox(height: 10),

            SizedBox(
              height: 520,
              child: BusSeatPlanWidget(
                bookedSeats: seatsData.bookedSeats,
                lockedSeats: seatsData.lockedSeats,
                selectedSeats: _counterSelectedSeats,
                onSeatTap: _toggleSeat,
              ),
            ),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _isSubmitting ? null : _submitCounterTicket,
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.print_rounded, size: 20),
                label: Text(
                  _isSubmitting
                      ? 'কাউন্টার টিকিট ইস্যু হচ্ছে...'
                      : 'কাউন্টার টিকিট প্রিন্ট ও ইস্যু করুন (৳ $totalPrice)',
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
