import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../core/app_colors.dart';
import '../models/bus_model.dart';
import '../providers/booking_provider.dart';
import '../services/firestore_service.dart';
import '../widgets/bus_info_card.dart';
import '../widgets/bus_seat_plan_widget.dart';
import '../widgets/desktop_web_navbar.dart';
import '../widgets/responsive_layout.dart';
import 'checkout_screen.dart';
import 'seat_plan_screen.dart';

class BusListScreen extends StatefulWidget {
  final String from;
  final String to;
  final String date;

  const BusListScreen({
    super.key,
    required this.from,
    required this.to,
    required this.date,
  });

  @override
  State<BusListScreen> createState() => _BusListScreenState();
}

class _BusListScreenState extends State<BusListScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  late String _currentSelectedDate;

  late final Stream<List<BusModel>> _busesStream;

  @override
  void initState() {
    super.initState();
    _currentSelectedDate = widget.date;
    _busesStream = _firestoreService.getBusesStream(
      from: widget.from,
      to: widget.to,
    );
  }

  Stream<ScheduleSeatsData> _getSeatsStream(String busId, String journeyDate) {
    return _firestoreService.getScheduleSeatsStream(
      busId: busId,
      journeyDate: journeyDate,
    );
  }

  String _cleanLocation(String loc) {
    return loc.replaceAll(RegExp(r'\([^)]*\)'), '').trim();
  }

  String _convertBengaliNumerals(String input) {
    const bangla = ['০', '১', '২', '৩', '৪', '৫', '৬', '৭', '৮', '৯'];
    const english = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    String result = input;
    for (int i = 0; i < bangla.length; i++) {
      result = result.replaceAll(bangla[i], english[i]);
    }
    return result;
  }

  bool _isRealToday(String dateStr) {
    try {
      final now = DateTime.now();
      final parsed = DateFormat('dd MMM yyyy').parse(dateStr);
      return parsed.day == now.day && parsed.month == now.month;
    } catch (e) {
      return false;
    }
  }

  bool _isBusPassedToday(BusModel bus) {
    final now = DateTime.now();
    final cleanDeparture = _convertBengaliNumerals(bus.departureTime);

    final timeRegex =
        RegExp(r'(\d{1,2})[:ঃ](\d{2})\s*(AM|PM)?', caseSensitive: false);
    final matches = timeRegex.allMatches(cleanDeparture);

    bool allTimesPassed = true;
    bool foundAnyMatch = false;

    for (final Match match in matches) {
      foundAnyMatch = true;
      int hour = int.parse(match.group(1)!);
      int minute = int.parse(match.group(2)!);
      final period = match.group(3)?.toUpperCase();

      if (period == 'PM' && hour < 12) hour += 12;
      if (period == 'AM' && hour == 12) hour = 0;

      final busTimeToday = DateTime(
        now.year,
        now.month,
        now.day,
        hour,
        minute,
      );

      if (!now.isAfter(busTimeToday)) {
        allTimesPassed = false;
      }
    }

    return foundAnyMatch && allTimesPassed;
  }

  DateTime _getNextDate(String dateStr) {
    try {
      final parsed = DateFormat('dd MMM yyyy').parse(dateStr);
      final now = DateTime.now();
      return DateTime(now.year, parsed.month, parsed.day)
          .add(const Duration(days: 1));
    } catch (e) {
      return DateTime.now().add(const Duration(days: 1));
    }
  }

  @override
  Widget build(BuildContext context) {
    final cleanFrom = _cleanLocation(widget.from);
    final cleanTo = _cleanLocation(widget.to);
    final isDesktop = ResponsiveLayout.isDesktop(context);
    final bookingProvider = context.watch<BookingProvider>();

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: isDesktop
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
                title: Text(
                  '$cleanFrom  ➔  $cleanTo',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.3,
                  ),
                ),
                actions: [
                  Container(
                    margin: const EdgeInsets.only(right: 16),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(25),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withAlpha(40)),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.calendar_month_rounded,
                          size: 14,
                          color: AppColors.accentGold,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _currentSelectedDate,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
      body: StreamBuilder<List<BusModel>>(
        stream: _busesStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(
                color: AppColors.primaryRed,
              ),
            );
          }

          List<BusModel> allBuses = snapshot.data ?? [];
          if (snapshot.hasError || allBuses.isEmpty) {
            allBuses = FirestoreService.officialBRTCBuses;
          }

          final routeBuses = FirestoreService.filterBusesList(
            allBuses,
            from: widget.from,
            to: widget.to,
          );

          List<BusModel> availableBuses = routeBuses;
          bool allPassedToday = false;

          if (_isRealToday(_currentSelectedDate)) {
            final upcoming = routeBuses
                .where((bus) => !_isBusPassedToday(bus))
                .toList();
            if (upcoming.isEmpty && routeBuses.isNotEmpty) {
              allPassedToday = true;
              availableBuses = [];
            } else {
              availableBuses = upcoming;
            }
          }

          return ResponsiveLayout(
            mobile: _buildMobileLayout(
              availableBuses,
              allPassedToday,
              cleanFrom,
              cleanTo,
            ),
            desktop: _buildDesktopLayout(
              availableBuses,
              allPassedToday,
              cleanFrom,
              cleanTo,
              bookingProvider,
            ),
          );
        },
      ),
    );
  }

  Widget _buildMobileLayout(
    List<BusModel> availableBuses,
    bool allPassedToday,
    String cleanFrom,
    String cleanTo,
  ) {
    if (allPassedToday || availableBuses.isEmpty) {
      return _buildNoBusesCard(cleanFrom, cleanTo);
    }

    return Column(
      children: [
        // Sub-Header Bar
        Container(
          margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(8),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.primaryGreen,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'উপলব্ধ বাস সার্ভিস',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen.withAlpha(20),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _currentSelectedDate,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryGreen,
                  ),
                ),
              ),
            ],
          ),
        ),

        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: availableBuses.length,
            itemBuilder: (context, index) {
              final bus = availableBuses[index];
              return _buildBusListItem(bus, cleanFrom, cleanTo, index);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopLayout(
    List<BusModel> availableBuses,
    bool allPassedToday,
    String cleanFrom,
    String cleanTo,
    BookingProvider bookingProvider,
  ) {
    if (allPassedToday || availableBuses.isEmpty) {
      return Center(
        child: ConstrainedWebContainer(
          maxWidth: 600,
          child: _buildNoBusesCard(cleanFrom, cleanTo),
        ),
      );
    }

    if (bookingProvider.selectedBus == null ||
        !availableBuses.contains(bookingProvider.selectedBus)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        bookingProvider.selectBus(availableBuses.first);
      });
    }

    final activeBus = bookingProvider.selectedBus ?? availableBuses.first;

    return SingleChildScrollView(
      child: ConstrainedWebContainer(
        padding: const EdgeInsets.all(28),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left Column: Bus Search Results List (38% Width)
            Expanded(
              flex: 38,
              child: Column(
                children: [
                  // Route & Date Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.primaryRed.withAlpha(40),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(8),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primaryRed.withAlpha(20),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.directions_bus_filled_rounded,
                            color: AppColors.primaryRed,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '$cleanFrom  ➔  $cleanTo',
                                style: const TextStyle(
                                  fontSize: 16.5,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primaryRed,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'যাত্রার তারিখ: $_currentSelectedDate',
                                style: const TextStyle(
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

                  const SizedBox(height: 16),

                  // Available Buses Cards List
                  Column(
                    children: List.generate(availableBuses.length, (index) {
                      final bus = availableBuses[index];
                      final bool isSelectedBus = (bus.id == activeBus.id);

                      return StreamBuilder<ScheduleSeatsData>(
                        stream: _getSeatsStream(bus.id, _currentSelectedDate),
                        builder: (context, seatsSnapshot) {
                          final seatsData = seatsSnapshot.data ??
                              ScheduleSeatsData(
                                  bookedSeats: [], lockedSeats: []);
                          final int occupiedCount = seatsData.bookedSeats.length +
                              seatsData.lockedSeats.length;
                          final int freeSeatsCount =
                              (bus.totalSeats - occupiedCount)
                                  .clamp(0, bus.totalSeats);

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelectedBus
                                    ? AppColors.primaryGreen
                                    : Colors.grey.shade300,
                                width: isSelectedBus ? 2.5 : 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: isSelectedBus
                                      ? AppColors.primaryGreen.withAlpha(30)
                                      : Colors.black.withAlpha(6),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: InkWell(
                              onTap: () {
                                bookingProvider.selectBus(bus);
                              },
                              borderRadius: BorderRadius.circular(20),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            bus.busName,
                                            style: const TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.primaryRed,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        Text(
                                          '৳ ${bus.fare}',
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w900,
                                            color: AppColors.primaryGreen,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'সময়: ${bus.departureTime}',
                                      style: const TextStyle(
                                        fontSize: 12.5,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.orange.shade50,
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            '🪑 $freeSeatsCount সিট ফাঁকা',
                                            style: TextStyle(
                                              fontSize: 11.5,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.orange.shade900,
                                            ),
                                          ),
                                        ),
                                        ElevatedButton(
                                          onPressed: () {
                                            bookingProvider.selectBus(bus);
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: isSelectedBus
                                                ? AppColors.primaryGreen
                                                : AppColors.primaryRed,
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 14,
                                              vertical: 6,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                          ),
                                          child: Text(
                                            isSelectedBus
                                                ? 'সিট সিলেক্টড ➔'
                                                : 'বাস বাছুন',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    }),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 28),

            // Right Column: Master-Detail Interactive Seat Plan (62% Width)
            Expanded(
              flex: 62,
              child: StreamBuilder<ScheduleSeatsData>(
                stream: _getSeatsStream(activeBus.id, _currentSelectedDate),
                builder: (context, snapshot) {
                  final seatsData = snapshot.data ??
                      ScheduleSeatsData(bookedSeats: [], lockedSeats: []);
                  final List<String> bookedSeats = seatsData.bookedSeats;
                  final List<String> lockedSeats = seatsData.lockedSeats;

                  final selectedSeats = bookingProvider.selectedSeats;
                  final int totalPrice =
                      selectedSeats.length * activeBus.fare;

                  return Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: AppColors.primaryRed.withAlpha(40),
                      ),
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
                        // Selected Bus Header Bar
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  activeBus.busName,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primaryRed,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '$cleanFrom ➔ $cleanTo (${activeBus.departureTime})',
                                  style: const TextStyle(
                                    fontSize: 12.5,
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
                                color: AppColors.primaryGreen.withAlpha(20),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '৳ ${activeBus.fare} / সিট',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.primaryGreen,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 14),

                        // Legend Indicators
                        Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 360),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                vertical: 8,
                                horizontal: 12,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.backgroundColor,
                                borderRadius: BorderRadius.circular(12),
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

                        // Interactive 45-Seat Bus Grid
                        SizedBox(
                          height: 440,
                          child: BusSeatPlanWidget(
                            bookedSeats: bookedSeats,
                            lockedSeats: lockedSeats,
                            selectedSeats: selectedSeats,
                            onSeatTap: (seatId) {
                              if (!bookedSeats.contains(seatId) &&
                                  !lockedSeats.contains(seatId)) {
                                bookingProvider.toggleSeat(seatId);
                              }
                            },
                          ),
                        ),

                        const SizedBox(height: 16),
                        const Divider(height: 1),
                        const SizedBox(height: 16),

                        // Price Summary & Action
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('নির্বাচিত সিট:',
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textSecondary)),
                                const SizedBox(height: 2),
                                Text(
                                  selectedSeats.isEmpty
                                      ? 'কোনোটি নয়'
                                      : selectedSeats.join(', '),
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                const Text('মোট প্রদেয় মূল্য:',
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textSecondary)),
                                const SizedBox(height: 2),
                                Text(
                                  '৳ $totalPrice',
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.primaryRed,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: selectedSeats.isEmpty
                                ? null
                                : () {
                                    Navigator.push(
                                      context,
                                      createSmoothPageRoute(
                                        CheckoutScreen(
                                          busId: activeBus.id,
                                          busName: activeBus.busName,
                                          from: cleanFrom,
                                          to: cleanTo,
                                          journeyDate: _currentSelectedDate,
                                          departureTime: activeBus.departureTime,
                                          selectedSeats: selectedSeats,
                                          totalAmount: totalPrice,
                                        ),
                                      ),
                                    );
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryGreen,
                              disabledBackgroundColor: Colors.grey.shade300,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: const Text(
                              'Continue to Checkout',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
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

  Widget _buildIndicator(Color color, String text,
      {bool isBorder = false, IconData? icon}) {
    return Row(
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
            border: isBorder ? Border.all(color: Colors.grey.shade400) : null,
          ),
          child: icon != null
              ? Icon(icon, size: 9, color: Colors.white)
              : null,
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 11,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildBusListItem(
    BusModel bus,
    String cleanFrom,
    String cleanTo,
    int index,
  ) {
    return StreamBuilder<ScheduleSeatsData>(
      stream: _getSeatsStream(bus.id, _currentSelectedDate),
      builder: (context, seatsSnapshot) {
        final seatsData = seatsSnapshot.data ??
            ScheduleSeatsData(bookedSeats: [], lockedSeats: []);
        final int occupiedCount =
            seatsData.bookedSeats.length + seatsData.lockedSeats.length;
        final int freeSeatsCount =
            (bus.totalSeats - occupiedCount).clamp(0, bus.totalSeats);

        return BusInfoCard(
          bus: {
            'busName': bus.busName,
            'departureTime': bus.departureTime,
            'arrivalTime': bus.arrivalTime,
            'route': bus.route,
            'seatAvailable': freeSeatsCount,
            'fare': '৳ ${bus.fare}',
          },
          onViewSeats: () {
            context.read<BookingProvider>().selectBus(bus);
            Navigator.push(
              context,
              createSmoothPageRoute(
                SeatPlanScreen(
                  busId: bus.id,
                  busName: bus.busName,
                  from: cleanFrom,
                  to: cleanTo,
                  journeyDate: _currentSelectedDate,
                  departureTime: bus.departureTime,
                  fare: bus.fare,
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildNoBusesCard(String cleanFrom, String cleanTo) {
    final nextDateObj = _getNextDate(_currentSelectedDate);
    final formattedNextDate = DateFormat('dd MMM yyyy').format(nextDateObj);

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Card(
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.access_time_filled_rounded,
                    color: Colors.orange.shade800,
                    size: 44,
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'আজকের সকল ট্রিপ ইতিমধ্যে ছেড়ে গেছে',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Text(
                  'আজকের ($_currentSelectedDate) $cleanFrom ➔ $cleanTo রুটের সকল বিআরটিসি বাসের সময়সীমা অতিক্রম করেছে। অনুগ্রহ করে আগামীকালের টিকিট বুক করুন।',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.calendar_today_rounded, size: 18),
                    label: Text(
                      'আগামীকালের ($formattedNextDate) বাস দেখুন',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryRed,
                      foregroundColor: Colors.white,
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () {
                      setState(() {
                        _currentSelectedDate = formattedNextDate;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
