import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/app_colors.dart';
import '../models/bus_model.dart';
import '../services/firestore_service.dart';
import '../widgets/bus_info_card.dart';
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

  @override
  void initState() {
    super.initState();
    _currentSelectedDate = widget.date;
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

      // Compare day and month with current real device calendar date
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

      // If at least one departure time today is in the future, keep the bus available
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

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: PreferredSize(
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
          title: Row(
            children: [
              Text(
                '$cleanFrom  ➔  $cleanTo',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          actions: [
            Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
      body: Column(
        children: [
          // Sleek Sub-Header Bar
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
            child: StreamBuilder<List<BusModel>>(
              stream: _firestoreService.getBusesStream(
                from: widget.from,
                to: widget.to,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
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

                // Time-aware filtering if the selected journey date is TODAY
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

                // If all buses for today have departed, suggest tomorrow's trip
                if (allPassedToday || availableBuses.isEmpty) {
                  final nextDateObj = _getNextDate(_currentSelectedDate);
                  final formattedNextDate =
                      DateFormat('dd MMM yyyy').format(nextDateObj);

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
                                  icon: const Icon(Icons.calendar_today_rounded,
                                      size: 18),
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

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: availableBuses.length,
                  itemBuilder: (context, index) {
                    final bus = availableBuses[index];

                    return StreamBuilder<ScheduleSeatsData>(
                      stream: _firestoreService.getScheduleSeatsStream(
                        busId: bus.id,
                        journeyDate: _currentSelectedDate,
                      ),
                      builder: (context, seatsSnapshot) {
                        final seatsData = seatsSnapshot.data ??
                            ScheduleSeatsData(bookedSeats: [], lockedSeats: []);
                        final int occupiedCount = seatsData.bookedSeats.length +
                            seatsData.lockedSeats.length;
                        final int freeSeatsCount =
                            (bus.totalSeats - occupiedCount)
                                .clamp(0, bus.totalSeats);

                        return TweenAnimationBuilder<double>(
                          tween: Tween<double>(begin: 0.0, end: 1.0),
                          duration:
                              Duration(milliseconds: 500 + (index * 140)),
                          curve: Curves.easeOutCubic,
                          builder: (context, value, child) {
                            return Transform.translate(
                              offset: Offset(0, 24 * (1 - value)),
                              child: Opacity(
                                opacity: value,
                                child: child,
                              ),
                            );
                          },
                          child: BusInfoCard(
                            bus: {
                              'busName': bus.busName,
                              'departureTime': bus.departureTime,
                              'arrivalTime': bus.arrivalTime,
                              'route': bus.route,
                              'seatAvailable': freeSeatsCount,
                              'fare': '৳ ${bus.fare}',
                            },
                            onViewSeats: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => SeatPlanScreen(
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
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
