import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import 'seat_widget.dart';

class BusSeatPlanWidget extends StatelessWidget {
  final List<String> bookedSeats;
  final List<String> lockedSeats;
  final List<String> selectedSeats;
  final Function(String seatId) onSeatTap;

  static const List<String> rowsAtoJ = [
    'A',
    'B',
    'C',
    'D',
    'E',
    'F',
    'G',
    'H',
    'I',
    'J'
  ];

  const BusSeatPlanWidget({
    super.key,
    required this.bookedSeats,
    this.lockedSeats = const [],
    required this.selectedSeats,
    required this.onSeatTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.grey.shade200, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          // Driver & Gate Cockpit Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.backgroundColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(26),
              ),
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade200),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.sensor_door_rounded,
                        size: 18, color: Colors.grey),
                    SizedBox(width: 6),
                    Text(
                      'GATE',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.primaryRed.withAlpha(15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.airline_seat_recline_extra_rounded,
                        size: 18,
                        color: AppColors.primaryRed,
                      ),
                      SizedBox(width: 6),
                      Text(
                        'DRIVER',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryRed,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Scrollable 45-Seat Grid with Hard Edge Clipping
          Expanded(
            child: SingleChildScrollView(
              clipBehavior: Clip.hardEdge,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  ...rowsAtoJ.map(
                    (rowLabel) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              SeatWidget(
                                seatId: '${rowLabel}1',
                                isBooked: bookedSeats.contains('${rowLabel}1'),
                                isLocked: lockedSeats.contains('${rowLabel}1'),
                                isSelected: selectedSeats.contains('${rowLabel}1'),
                                onTap: () => onSeatTap('${rowLabel}1'),
                              ),
                              const SizedBox(width: 8),
                              SeatWidget(
                                seatId: '${rowLabel}2',
                                isBooked: bookedSeats.contains('${rowLabel}2'),
                                isLocked: lockedSeats.contains('${rowLabel}2'),
                                isSelected: selectedSeats.contains('${rowLabel}2'),
                                onTap: () => onSeatTap('${rowLabel}2'),
                              ),
                            ],
                          ),
                          Text(
                            rowLabel,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade400,
                              fontSize: 13,
                            ),
                          ),
                          Row(
                            children: [
                              SeatWidget(
                                seatId: '${rowLabel}3',
                                isBooked: bookedSeats.contains('${rowLabel}3'),
                                isLocked: lockedSeats.contains('${rowLabel}3'),
                                isSelected: selectedSeats.contains('${rowLabel}3'),
                                onTap: () => onSeatTap('${rowLabel}3'),
                              ),
                              const SizedBox(width: 8),
                              SeatWidget(
                                seatId: '${rowLabel}4',
                                isBooked: bookedSeats.contains('${rowLabel}4'),
                                isLocked: lockedSeats.contains('${rowLabel}4'),
                                isSelected: selectedSeats.contains('${rowLabel}4'),
                                onTap: () => onSeatTap('${rowLabel}4'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Back Row K (5 Seats)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        SeatWidget(
                          seatId: 'K1',
                          isBooked: bookedSeats.contains('K1'),
                          isLocked: lockedSeats.contains('K1'),
                          isSelected: selectedSeats.contains('K1'),
                          onTap: () => onSeatTap('K1'),
                        ),
                        SeatWidget(
                          seatId: 'K2',
                          isBooked: bookedSeats.contains('K2'),
                          isLocked: lockedSeats.contains('K2'),
                          isSelected: selectedSeats.contains('K2'),
                          onTap: () => onSeatTap('K2'),
                        ),
                        SeatWidget(
                          seatId: 'K3',
                          isBooked: bookedSeats.contains('K3'),
                          isLocked: lockedSeats.contains('K3'),
                          isSelected: selectedSeats.contains('K3'),
                          onTap: () => onSeatTap('K3'),
                        ),
                        SeatWidget(
                          seatId: 'K4',
                          isBooked: bookedSeats.contains('K4'),
                          isLocked: lockedSeats.contains('K4'),
                          isSelected: selectedSeats.contains('K4'),
                          onTap: () => onSeatTap('K4'),
                        ),
                        SeatWidget(
                          seatId: 'K5',
                          isBooked: bookedSeats.contains('K5'),
                          isLocked: lockedSeats.contains('K5'),
                          isSelected: selectedSeats.contains('K5'),
                          onTap: () => onSeatTap('K5'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
