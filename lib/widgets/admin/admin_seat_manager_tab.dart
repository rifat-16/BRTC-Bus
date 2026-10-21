import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/app_colors.dart';
import '../../models/bus_model.dart';
import '../../services/firestore_service.dart';
import '../bus_seat_plan_widget.dart';

class AdminSeatManagerTab extends StatefulWidget {
  final FirestoreService firestoreService;

  const AdminSeatManagerTab({
    super.key,
    required this.firestoreService,
  });

  @override
  State<AdminSeatManagerTab> createState() => _AdminSeatManagerTabState();
}

class _AdminSeatManagerTabState extends State<AdminSeatManagerTab> {
  BusModel _selectedBus = FirestoreService.officialBRTCBuses.first;
  DateTime _seatManagerDate = DateTime.now();
  final List<String> _manualSelectedSeats = [];

  @override
  Widget build(BuildContext context) {
    final String formattedDate =
        DateFormat('dd MMM yyyy').format(_seatManagerDate);

    return StreamBuilder<ScheduleSeatsData>(
      stream: widget.firestoreService.getScheduleSeatsStream(
        busId: _selectedBus.id,
        journeyDate: formattedDate,
      ),
      builder: (context, snapshot) {
        final seatsData = snapshot.data ??
            ScheduleSeatsData(bookedSeats: [], lockedSeats: []);
        final List<String> bookedSeats = seatsData.bookedSeats;
        final List<String> lockedSeats = seatsData.lockedSeats;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Bus & Date Selection Cards Row
              Row(
                children: [
                  // Bus Selector Dropdown
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<BusModel>(
                          value: _selectedBus,
                          isExpanded: true,
                          items: FirestoreService.officialBRTCBuses
                              .map((bus) => DropdownMenuItem(
                                    value: bus,
                                    child: Text(
                                      bus.busName,
                                      style: const TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ))
                              .toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _selectedBus = val;
                                _manualSelectedSeats.clear();
                              });
                            }
                          },
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 10),

                  // Date Picker Button
                  ElevatedButton.icon(
                    icon: const Icon(Icons.calendar_today_rounded, size: 16),
                    label: Text(formattedDate,
                        style: const TextStyle(fontSize: 12)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryRed,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _seatManagerDate,
                        firstDate:
                            DateTime.now().subtract(const Duration(days: 30)),
                        lastDate:
                            DateTime.now().add(const Duration(days: 60)),
                      );
                      if (picked != null) {
                        setState(() {
                          _seatManagerDate = picked;
                          _manualSelectedSeats.clear();
                        });
                      }
                    },
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Summary Stats Card
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border:
                      Border.all(color: AppColors.primaryRed.withAlpha(40)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildSeatStat('বুকড (Booked)', '${bookedSeats.length}',
                        AppColors.primaryRed),
                    _buildSeatStat('লকড (Locked)', '${lockedSeats.length}',
                        Colors.orange.shade800),
                    _buildSeatStat(
                        'ফাঁকা (Available)',
                        '${45 - (bookedSeats.length + lockedSeats.length)}',
                        AppColors.primaryGreen),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Bus Seat Grid Area
              Container(
                height: 480,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: BusSeatPlanWidget(
                  bookedSeats: bookedSeats,
                  lockedSeats: lockedSeats,
                  selectedSeats: _manualSelectedSeats,
                  onSeatTap: (seatId) {
                    setState(() {
                      if (_manualSelectedSeats.contains(seatId)) {
                        _manualSelectedSeats.remove(seatId);
                      } else {
                        _manualSelectedSeats.add(seatId);
                      }
                    });
                  },
                ),
              ),

              const SizedBox(height: 16),

              // Action Buttons Row
              if (_manualSelectedSeats.isNotEmpty)
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.lock_rounded, size: 18),
                        label: Text(
                            'ম্যানুয়ালি লক করুন (${_manualSelectedSeats.length})'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange.shade800,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: () async {
                          final messenger = ScaffoldMessenger.of(context);
                          final seatsToLock = List<String>.from(_manualSelectedSeats);

                          setState(() {
                            _manualSelectedSeats.clear();
                          });

                          await widget.firestoreService.manuallyLockSeats(
                            busId: _selectedBus.id,
                            journeyDate: formattedDate,
                            seats: seatsToLock,
                          );

                          messenger.showSnackBar(
                            SnackBar(
                              content: Text(
                                  'সিট ${seatsToLock.join(", ")} সফলভাবে ম্যানুয়ালি লক করা হয়েছে!'),
                              backgroundColor: Colors.orange.shade800,
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.lock_open_rounded, size: 18),
                        label: Text(
                            'সিট মুক্ত করুন (${_manualSelectedSeats.length})'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryGreen,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: () async {
                          final messenger = ScaffoldMessenger.of(context);
                          final seatsToUnlock = List<String>.from(_manualSelectedSeats);

                          setState(() {
                            _manualSelectedSeats.clear();
                          });

                          await widget.firestoreService.manuallyUnlockSeats(
                            busId: _selectedBus.id,
                            journeyDate: formattedDate,
                            seats: seatsToUnlock,
                          );

                          messenger.showSnackBar(
                            SnackBar(
                              content: Text(
                                  'সিট ${seatsToUnlock.join(", ")} সফলভাবে আনলক করা হয়েছে!'),
                              backgroundColor: AppColors.primaryGreen,
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSeatStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11.5,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
