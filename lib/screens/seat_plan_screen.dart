import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_colors.dart';
import '../models/bus_model.dart';
import '../providers/booking_provider.dart';
import '../services/firestore_service.dart';
import '../widgets/bus_seat_plan_widget.dart';
import '../widgets/desktop_web_navbar.dart';
import '../widgets/responsive_layout.dart';
import 'checkout_screen.dart';

class SeatPlanScreen extends StatefulWidget {
  final String busId;
  final String busName;
  final String from;
  final String to;
  final String journeyDate;
  final String departureTime;
  final int fare;

  const SeatPlanScreen({
    super.key,
    required this.busId,
    required this.busName,
    required this.from,
    required this.to,
    required this.journeyDate,
    this.departureTime = '',
    required this.fare,
  });

  @override
  State<SeatPlanScreen> createState() => _SeatPlanScreenState();
}

class _SeatPlanScreenState extends State<SeatPlanScreen>
    with SingleTickerProviderStateMixin {
  final FirestoreService _firestoreService = FirestoreService();
  final int _maxSeatsAllowed = 4;

  late AnimationController _entranceController;
  late Animation<double> _headerFade;
  late Animation<Offset> _headerSlide;
  late Animation<double> _busBodyFade;
  late Animation<double> _busBodyScale;
  late Animation<double> _bottomFade;
  late Animation<Offset> _bottomSlide;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _headerFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.0, 0.45, curve: Curves.easeOut),
      ),
    );

    _headerSlide = Tween<Offset>(
      begin: const Offset(0, -0.2),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOutCubic),
      ),
    );

    _busBodyFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.2, 0.75, curve: Curves.easeOut),
      ),
    );

    _busBodyScale = Tween<double>(begin: 0.94, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.2, 0.75, curve: Curves.easeOutBack),
      ),
    );

    _bottomFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.5, 1.0, curve: Curves.easeOut),
      ),
    );

    _bottomSlide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.5, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    _entranceController.forward();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
  }

  void _toggleSeat(
    String seatId,
    List<String> bookedSeats,
    List<String> lockedSeats,
    BookingProvider bookingProvider,
  ) {
    if (bookedSeats.contains(seatId) || lockedSeats.contains(seatId)) return;

    if (!bookingProvider.selectedSeats.contains(seatId) &&
        bookingProvider.selectedSeats.length >= _maxSeatsAllowed) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('আপনি সর্বোচ্চ ৪টি সিট নির্বাচন করতে পারবেন'),
          backgroundColor: AppColors.primaryRed,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }

    bookingProvider.toggleSeat(seatId, maxSeats: _maxSeatsAllowed);
  }

  @override
  Widget build(BuildContext context) {
    final bookingProvider = context.watch<BookingProvider>();

    if (bookingProvider.selectedBus?.id != widget.busId) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        bookingProvider.selectBus(
          BusModel(
            id: widget.busId,
            busName: widget.busName,
            from: widget.from,
            to: widget.to,
            route: '${widget.from}-${widget.to}',
            departureTime: widget.departureTime,
            arrivalTime: '',
            fare: widget.fare,
            totalSeats: 45,
          ),
        );
      });
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: ResponsiveLayout.isDesktop(context)
          ? const DesktopWebNavbar()
          : PreferredSize(
              preferredSize: const Size.fromHeight(70),
              child: AppBar(
                flexibleSpace: Container(
                  decoration: const BoxDecoration(
                    gradient: AppColors.darkHeaderGradient,
                    borderRadius: BorderRadius.vertical(
                      bottom: Radius.circular(24),
                    ),
                  ),
                ),
                backgroundColor: Colors.transparent,
                elevation: 4,
                shadowColor: Colors.black26,
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.busName,
                      style: const TextStyle(
                        fontSize: 16.5,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${widget.from} ➔ ${widget.to} (${widget.journeyDate})',
                      style: const TextStyle(fontSize: 12, color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ),
      body: StreamBuilder<ScheduleSeatsData>(
        stream: _firestoreService.getScheduleSeatsStream(
          busId: widget.busId,
          journeyDate: widget.journeyDate,
        ),
        builder: (context, snapshot) {
          final seatsData = snapshot.data ??
              ScheduleSeatsData(bookedSeats: [], lockedSeats: []);
          final List<String> bookedSeats = seatsData.bookedSeats;
          final List<String> lockedSeats = seatsData.lockedSeats;

          return ResponsiveLayout(
            mobile: _buildMobileLayout(
              bookedSeats,
              lockedSeats,
              bookingProvider,
            ),
            desktop: _buildDesktopLayout(
              bookedSeats,
              lockedSeats,
              bookingProvider,
            ),
          );
        },
      ),
    );
  }

  Widget _buildMobileLayout(
    List<String> bookedSeats,
    List<String> lockedSeats,
    BookingProvider bookingProvider,
  ) {
    return Column(
      children: [
        // Legend Bar
        SlideTransition(
          position: _headerSlide,
          child: FadeTransition(
            opacity: _headerFade,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(10),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildIndicator(Colors.white, 'Available', isBorder: true),
                  _buildIndicator(AppColors.primaryGreen, 'Selected'),
                  _buildIndicator(Colors.orange.shade800, 'Locked',
                      icon: Icons.lock_rounded),
                  _buildIndicator(AppColors.primaryRed, 'Booked'),
                ],
              ),
            ),
          ),
        ),

        // Bus Seat Grid
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: ScaleTransition(
              scale: _busBodyScale,
              child: FadeTransition(
                opacity: _busBodyFade,
                child: BusSeatPlanWidget(
                  bookedSeats: bookedSeats,
                  lockedSeats: lockedSeats,
                  selectedSeats: bookingProvider.selectedSeats,
                  onSeatTap: (seatId) => _toggleSeat(
                    seatId,
                    bookedSeats,
                    lockedSeats,
                    bookingProvider,
                  ),
                ),
              ),
            ),
          ),
        ),

        // Bottom Total & Action
        SlideTransition(
          position: _bottomSlide,
          child: FadeTransition(
            opacity: _bottomFade,
            child: _buildBottomSection(bookingProvider),
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopLayout(
    List<String> bookedSeats,
    List<String> lockedSeats,
    BookingProvider bookingProvider,
  ) {
    final selectedSeats = bookingProvider.selectedSeats;
    final int totalPrice = selectedSeats.length * widget.fare;

    return SingleChildScrollView(
      child: ConstrainedWebContainer(
        padding: const EdgeInsets.all(28),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left Column: Bus Seat Plan (50% Width)
            Expanded(
              flex: 50,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.grey.shade300),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(8),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Legend
                    Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 360),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              vertical: 10, horizontal: 12),
                          decoration: BoxDecoration(
                            color: AppColors.backgroundColor,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildIndicator(Colors.white, 'Available',
                                  isBorder: true),
                              _buildIndicator(
                                  AppColors.primaryGreen, 'Selected'),
                              _buildIndicator(
                                  Colors.orange.shade800, 'Locked',
                                  icon: Icons.lock_rounded),
                              _buildIndicator(AppColors.primaryRed, 'Booked'),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 520,
                      child: BusSeatPlanWidget(
                        bookedSeats: bookedSeats,
                        lockedSeats: lockedSeats,
                        selectedSeats: selectedSeats,
                        onSeatTap: (seatId) => _toggleSeat(
                          seatId,
                          bookedSeats,
                          lockedSeats,
                          bookingProvider,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(width: 28),

            // Right Column: Trip Summary & Proceed Card (50% Width)
            Expanded(
              flex: 50,
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                          color: AppColors.primaryRed.withAlpha(40)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(8),
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.primaryRed.withAlpha(20),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.directions_bus_filled_rounded,
                                color: AppColors.primaryRed,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.busName,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primaryRed,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${widget.from} ➔ ${widget.to} (${widget.journeyDate})',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 18),
                          child: Divider(height: 1),
                        ),
                        _buildDesktopSummaryRow(
                            'প্রতি সিটের ভাড়া', '৳ ${widget.fare}'),
                        const SizedBox(height: 12),
                        _buildDesktopSummaryRow(
                          'নির্বাচিত সিটসমূহ',
                          selectedSeats.isEmpty
                              ? 'কোনোটি নয়'
                              : selectedSeats.join(', '),
                          isBold: true,
                        ),
                        const SizedBox(height: 12),
                        _buildDesktopSummaryRow(
                          'সর্বমোট প্রদেয় মূল্য',
                          '৳ $totalPrice',
                          isPrice: true,
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: selectedSeats.isEmpty
                                ? null
                                : () {
                                    Navigator.push(
                                      context,
                                      createSmoothPageRoute(
                                        CheckoutScreen(
                                          busId: widget.busId,
                                          busName: widget.busName,
                                          from: widget.from,
                                          to: widget.to,
                                          journeyDate: widget.journeyDate,
                                          departureTime: widget.departureTime,
                                          selectedSeats: selectedSeats,
                                          totalAmount: totalPrice,
                                        ),
                                      ),
                                    );
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryGreen,
                              disabledBackgroundColor: Colors.grey.shade300,
                              elevation: selectedSeats.isEmpty ? 0 : 3,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: const Text(
                              'Continue to Checkout',
                              style: TextStyle(
                                fontSize: 16.5,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
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
    );
  }

  Widget _buildDesktopSummaryRow(String label, String value,
      {bool isBold = false, bool isPrice = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13.5,
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isPrice ? 22 : 15,
            fontWeight:
                (isBold || isPrice) ? FontWeight.w900 : FontWeight.bold,
            color: isPrice ? AppColors.primaryRed : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildIndicator(Color color, String text,
      {bool isBorder = false, IconData? icon}) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(5),
            border: isBorder ? Border.all(color: Colors.grey.shade400) : null,
          ),
          child: icon != null
              ? Icon(icon, size: 10, color: Colors.white)
              : null,
        ),
        const SizedBox(width: 5),
        Text(
          text,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 11.5,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomSection(BookingProvider bookingProvider) {
    final selectedSeats = bookingProvider.selectedSeats;
    final int totalPrice = selectedSeats.length * widget.fare;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(15),
            offset: const Offset(0, -5),
            blurRadius: 18,
          )
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Selected Seats',
                        style: TextStyle(
                            color: AppColors.textSecondary, fontSize: 13)),
                    const SizedBox(height: 4),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: Text(
                        selectedSeats.isEmpty
                            ? 'None'
                            : selectedSeats.join(', '),
                        key: ValueKey(selectedSeats.join(',')),
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 17,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('Total Price',
                        style: TextStyle(
                            color: AppColors.textSecondary, fontSize: 13)),
                    const SizedBox(height: 4),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: Text(
                        '৳ $totalPrice',
                        key: ValueKey(totalPrice),
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 22,
                          color: AppColors.primaryRed,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: selectedSeats.isEmpty
                    ? null
                    : () {
                        Navigator.push(
                          context,
                          createSmoothPageRoute(
                            CheckoutScreen(
                              busId: widget.busId,
                              busName: widget.busName,
                              from: widget.from,
                              to: widget.to,
                              journeyDate: widget.journeyDate,
                              departureTime: widget.departureTime,
                              selectedSeats: selectedSeats,
                              totalAmount: totalPrice,
                            ),
                          ),
                        );
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  disabledBackgroundColor: Colors.grey.shade300,
                  elevation: selectedSeats.isEmpty ? 0 : 3,
                  shadowColor: AppColors.primaryGreen.withAlpha(80),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Continue to Checkout',
                  style: TextStyle(
                    fontSize: 16.5,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
