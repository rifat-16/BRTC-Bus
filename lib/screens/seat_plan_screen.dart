import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../services/firestore_service.dart';
import '../widgets/bus_seat_plan_widget.dart';
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

  final List<String> _selectedSeats = [];
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

  void _toggleSeat(String seatId, List<String> bookedSeats, List<String> lockedSeats) {
    if (bookedSeats.contains(seatId) || lockedSeats.contains(seatId)) return;

    setState(() {
      if (_selectedSeats.contains(seatId)) {
        _selectedSeats.remove(seatId);
      } else {
        if (_selectedSeats.length < _maxSeatsAllowed) {
          _selectedSeats.add(seatId);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('আপনি সর্বোচ্চ ৪টি সিট নির্বাচন করতে পারবেন'),
              backgroundColor: AppColors.primaryRed,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
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
          final seatsData = snapshot.data ?? ScheduleSeatsData(bookedSeats: [], lockedSeats: []);
          final List<String> bookedSeats = seatsData.bookedSeats;
          final List<String> lockedSeats = seatsData.lockedSeats;

          return Column(
            children: [
              // Animated Legend Bar with 4 Clear Seat Indicators
              SlideTransition(
                position: _headerSlide,
                child: FadeTransition(
                  opacity: _headerFade,
                  child: Container(
                    margin: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    padding: const EdgeInsets.symmetric(
                        vertical: 10, horizontal: 12),
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
                        _buildIndicator(Colors.orange.shade800, 'Locked', icon: Icons.lock_rounded),
                        _buildIndicator(AppColors.primaryRed, 'Booked'),
                      ],
                    ),
                  ),
                ),
              ),

              // Reusable Bus Interior Seat Plan Component
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
                        selectedSeats: _selectedSeats,
                        onSeatTap: (seatId) => _toggleSeat(seatId, bookedSeats, lockedSeats),
                      ),
                    ),
                  ),
                ),
              ),

              // Bottom Total & Action Section
              SlideTransition(
                position: _bottomSlide,
                child: FadeTransition(
                  opacity: _bottomFade,
                  child: _buildBottomSection(),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildIndicator(Color color, String text, {bool isBorder = false, IconData? icon}) {
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

  Widget _buildBottomSection() {
    final int totalPrice = _selectedSeats.length * widget.fare;

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
                        _selectedSeats.isEmpty
                            ? 'None'
                            : _selectedSeats.join(', '),
                        key: ValueKey(_selectedSeats.join(',')),
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
                onPressed: _selectedSeats.isEmpty
                    ? null
                    : () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CheckoutScreen(
                              busId: widget.busId,
                              busName: widget.busName,
                              from: widget.from,
                              to: widget.to,
                              journeyDate: widget.journeyDate,
                              departureTime: widget.departureTime,
                              selectedSeats: _selectedSeats,
                              totalAmount: totalPrice,
                            ),
                          ),
                        );
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  disabledBackgroundColor: Colors.grey.shade300,
                  elevation: _selectedSeats.isEmpty ? 0 : 3,
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
