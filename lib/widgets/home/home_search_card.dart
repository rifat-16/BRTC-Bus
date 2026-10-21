import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/app_colors.dart';
import '../../providers/booking_provider.dart';
import '../../screens/bus_list_screen.dart';
import '../custom_dropdown.dart';

class HomeSearchCard extends StatefulWidget {
  final List<String> locations;

  const HomeSearchCard({
    super.key,
    required this.locations,
  });

  @override
  State<HomeSearchCard> createState() => _HomeSearchCardState();
}

class _HomeSearchCardState extends State<HomeSearchCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _swapAnimController;
  late Animation<double> _swapAnimation;

  @override
  void initState() {
    super.initState();
    _swapAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _swapAnimation = Tween<double>(begin: 0, end: math.pi).animate(
      CurvedAnimation(
        parent: _swapAnimController,
        curve: Curves.easeInOutCubic,
      ),
    );
  }

  @override
  void dispose() {
    _swapAnimController.dispose();
    super.dispose();
  }

  void _swapLocations(BookingProvider bookingProvider) {
    _swapAnimController.forward(from: 0);
    final tempFrom = bookingProvider.selectedFrom;
    final tempTo = bookingProvider.selectedTo;
    bookingProvider.updateRouteFilter(tempTo, tempFrom);
  }

  Future<void> _selectDate(
      BuildContext context, BookingProvider bookingProvider) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: bookingProvider.journeyDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primaryRed,
              onPrimary: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      bookingProvider.updateJourneyDate(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bookingProvider = context.watch<BookingProvider>();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(14),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // From Dropdown
          CustomDropdown(
            label: 'কোথা থেকে (From)',
            value: bookingProvider.selectedFrom,
            items: widget.locations,
            onChanged: (newValue) {
              if (newValue != null) {
                bookingProvider.updateRouteFilter(
                    newValue, bookingProvider.selectedTo);
              }
            },
          ),

          // Divider with Swap Icon
          Stack(
            alignment: Alignment.centerRight,
            clipBehavior: Clip.none,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12.0),
                child: Divider(height: 1),
              ),
              Positioned(
                right: 0,
                child: GestureDetector(
                  onTap: () => _swapLocations(bookingProvider),
                  child: AnimatedBuilder(
                    animation: _swapAnimation,
                    builder: (context, child) {
                      return Transform.rotate(
                        angle: _swapAnimation.value,
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.primaryGreen,
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primaryGreen.withAlpha(35),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.swap_vert_rounded,
                            color: AppColors.primaryGreen,
                            size: 22,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),

          // To Dropdown
          CustomDropdown(
            label: 'কোথায় যাবেন (To)',
            value: bookingProvider.selectedTo,
            items: widget.locations,
            onChanged: (newValue) {
              if (newValue != null) {
                bookingProvider.updateRouteFilter(
                    bookingProvider.selectedFrom, newValue);
              }
            },
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12.0),
            child: Divider(height: 1),
          ),

          // Date Picker Tile
          GestureDetector(
            onTap: () => _selectDate(context, bookingProvider),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.backgroundColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primaryRed.withAlpha(20),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.calendar_month_rounded,
                      color: AppColors.primaryRed,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'যাত্রার তারিখ (Date)',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        DateFormat('dd MMM yyyy, EEEE')
                            .format(bookingProvider.journeyDate),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Search Button
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.search_rounded, size: 22),
              label: const Text(
                'বাস খুঁজুন (Search Buses)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 3,
                shadowColor: AppColors.primaryGreen.withAlpha(80),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BusListScreen(
                      from: bookingProvider.selectedFrom,
                      to: bookingProvider.selectedTo,
                      date: DateFormat('dd MMM yyyy')
                          .format(bookingProvider.journeyDate),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
