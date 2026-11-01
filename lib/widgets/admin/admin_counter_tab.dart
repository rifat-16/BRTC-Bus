import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/app_colors.dart';
import '../../models/bus_model.dart';
import '../../models/ticket_model.dart';
import '../../services/firestore_service.dart';
import '../bus_seat_plan_widget.dart';
import '../responsive_layout.dart';
import '../summary_row.dart';
import 'admin_e_ticket_dialog.dart';

class AdminCounterTab extends StatefulWidget {
  final FirestoreService firestoreService;

  const AdminCounterTab({
    super.key,
    required this.firestoreService,
  });

  @override
  State<AdminCounterTab> createState() => _AdminCounterTabState();
}

class _AdminCounterTabState extends State<AdminCounterTab> {
  final _counterFormKey = GlobalKey<FormState>();
  final TextEditingController _counterNameController = TextEditingController();
  final TextEditingController _counterPhoneController = TextEditingController();

  BusModel _counterSelectedBus = FirestoreService.officialBRTCBuses.first;
  DateTime _counterJourneyDate = DateTime.now();
  final List<String> _counterSelectedSeats = [];
  bool _isCounterSubmitting = false;

  @override
  void dispose() {
    _counterNameController.dispose();
    _counterPhoneController.dispose();
    super.dispose();
  }

  void _submitCounterBooking(String formattedCounterDate) async {
    if (!_counterFormKey.currentState!.validate()) {
      return;
    }

    if (_counterSelectedSeats.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('অনুগ্রহ করে অন্তত ১টি সিট নির্বাচন করুন'),
          backgroundColor: AppColors.primaryRed,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }

    setState(() {
      _isCounterSubmitting = true;
    });

    final ticketToIssue = TicketModel(
      busId: _counterSelectedBus.id,
      userId: 'counter_admin',
      userEmail: 'counter@brtc.gov.bd',
      busName: _counterSelectedBus.busName,
      from: _counterSelectedBus.from,
      to: _counterSelectedBus.to,
      journeyDate: formattedCounterDate,
      selectedSeats: List<String>.from(_counterSelectedSeats),
      totalAmount: _counterSelectedSeats.length * _counterSelectedBus.fare,
      passengerName: _counterNameController.text.trim(),
      passengerPhone: _counterPhoneController.text.trim(),
      paymentMethod: 'COUNTER CASH',
      trxId:
          'COUNTER-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
    );

    final messenger = ScaffoldMessenger.of(context);

    try {
      final issuedTicket = await widget.firestoreService.issueCounterTicket(
        busId: _counterSelectedBus.id,
        ticket: ticketToIssue,
      );

      messenger.showSnackBar(
        const SnackBar(
          content: Text('কাউন্টার টিকিট সফলভাবে তৈরি হয়েছে!'),
          backgroundColor: AppColors.primaryGreen,
        ),
      );

      if (mounted && context.mounted) {
        AdminETicketDialog.show(context, issuedTicket);

        setState(() {
          _counterSelectedSeats.clear();
          _counterNameController.clear();
          _counterPhoneController.clear();
        });
      }
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('টিকিট তৈরি করতে ব্যর্থ: $e'),
          backgroundColor: AppColors.primaryRed,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isCounterSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final String formattedCounterDate =
        DateFormat('dd MMM yyyy').format(_counterJourneyDate);

    return SingleChildScrollView(
      child: ConstrainedWebContainer(
        maxWidth: 1200,
        padding: const EdgeInsets.all(22),
        child: Form(
          key: _counterFormKey,
          child: ResponsiveLayout(
            mobile: _buildMobileLayout(formattedCounterDate),
            desktop: _buildDesktopLayout(formattedCounterDate),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileLayout(String formattedCounterDate) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'কাউন্টার ক্যাশ টিকিট ইস্যুকরণ (Direct Sales)',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),

        // Name & Phone Input
        TextFormField(
          controller: _counterNameController,
          decoration: InputDecoration(
            labelText: 'যাত্রীর নাম',
            prefixIcon: const Icon(Icons.person_rounded),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          validator: (v) =>
              v == null || v.trim().isEmpty ? 'যাত্রীর নাম দিন' : null,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _counterPhoneController,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(
            labelText: 'মোবাইল নম্বর',
            prefixIcon: const Icon(Icons.phone_android_rounded),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          validator: (v) => v == null || v.trim().length != 11
              ? '১১ ডিজিটের মোবাইল নম্বর দিন'
              : null,
        ),

        const SizedBox(height: 16),

        // Bus & Date Selectors Row
        Row(
          children: [
            Expanded(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<BusModel>(
                    value: _counterSelectedBus,
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
                          _counterSelectedBus = val;
                          _counterSelectedSeats.clear();
                        });
                      }
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            ElevatedButton.icon(
              icon: const Icon(Icons.calendar_today_rounded, size: 16),
              label:
                  Text(formattedCounterDate, style: const TextStyle(fontSize: 12)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryRed,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _counterJourneyDate,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 60)),
                );
                if (picked != null) {
                  setState(() {
                    _counterJourneyDate = picked;
                    _counterSelectedSeats.clear();
                  });
                }
              },
            ),
          ],
        ),

        const SizedBox(height: 18),

        // Seat Picker Grid for Counter
        const Text(
          'সিট নির্বাচন করুন:',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
        ),
        const SizedBox(height: 8),

        StreamBuilder<ScheduleSeatsData>(
          stream: widget.firestoreService.getScheduleSeatsStream(
            busId: _counterSelectedBus.id,
            journeyDate: formattedCounterDate,
          ),
          builder: (context, snapshot) {
            final seatsData = snapshot.data ??
                ScheduleSeatsData(bookedSeats: [], lockedSeats: []);

            return Container(
              height: 420,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: BusSeatPlanWidget(
                bookedSeats: seatsData.bookedSeats,
                lockedSeats: seatsData.lockedSeats,
                selectedSeats: _counterSelectedSeats,
                onSeatTap: (seatId) {
                  setState(() {
                    if (_counterSelectedSeats.contains(seatId)) {
                      _counterSelectedSeats.remove(seatId);
                    } else {
                      _counterSelectedSeats.add(seatId);
                    }
                  });
                },
              ),
            );
          },
        ),

        const SizedBox(height: 20),

        // Submit Counter Ticket Button
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            icon: _isCounterSubmitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2),
                  )
                : const Icon(Icons.print_rounded, size: 20),
            label: Text(
              _counterSelectedSeats.isEmpty
                  ? 'সিট নির্বাচন করুন'
                  : 'কাউন্টার টিকিট প্রিন্ট ও কনফার্ম করুন (৳ ${_counterSelectedSeats.length * _counterSelectedBus.fare})',
              style:
                  const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: _counterSelectedSeats.isEmpty
                  ? Colors.grey.shade400
                  : AppColors.primaryGreen,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onPressed:
                (_counterSelectedSeats.isEmpty || _isCounterSubmitting)
                    ? null
                    : () => _submitCounterBooking(formattedCounterDate),
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopLayout(String formattedCounterDate) {
    final int totalAmount =
        _counterSelectedSeats.length * _counterSelectedBus.fare;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left Column: Direct Cash Sale Form (50% width)
        Expanded(
          flex: 50,
          child: Container(
            padding: const EdgeInsets.all(26),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: Colors.grey.shade300),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(8),
                  blurRadius: 12,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primaryRed.withAlpha(20),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.point_of_sale_rounded,
                        color: AppColors.primaryRed,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'কাউন্টার ক্যাশ টিকিট ইস্যুকরণ (Direct Sales)',
                          style: TextStyle(
                            fontSize: 16.5,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryRed,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'কাউন্টার ক্যাশ গ্রাহকের জন্য তৎক্ষণাৎ সরাসরি টিকিট ইস্যু করুন',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Divider(height: 1),
                ),

                // Name Input
                TextFormField(
                  controller: _counterNameController,
                  decoration: InputDecoration(
                    labelText: 'যাত্রীর নাম',
                    hintText: 'যাত্রীর পূর্ণ নাম লিখুন',
                    prefixIcon: const Icon(Icons.person_rounded),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'যাত্রীর নাম দিন' : null,
                ),
                const SizedBox(height: 16),

                // Phone Input
                TextFormField(
                  controller: _counterPhoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: 'মোবাইল নম্বর',
                    hintText: '১১ ডিজিটের মোবাইল নম্বর লিখুন',
                    prefixIcon: const Icon(Icons.phone_android_rounded),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  validator: (v) => v == null || v.trim().length != 11
                      ? '১১ ডিজিটের মোবাইল নম্বর দিন'
                      : null,
                ),

                const SizedBox(height: 16),

                // Bus & Date Selectors Row
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.backgroundColor,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<BusModel>(
                            value: _counterSelectedBus,
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
                                  _counterSelectedBus = val;
                                  _counterSelectedSeats.clear();
                                });
                              }
                            },
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.calendar_today_rounded, size: 16),
                      label: Text(formattedCounterDate,
                          style: const TextStyle(fontSize: 12)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryRed,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _counterJourneyDate,
                          firstDate: DateTime.now(),
                          lastDate:
                              DateTime.now().add(const Duration(days: 60)),
                        );
                        if (picked != null) {
                          setState(() {
                            _counterJourneyDate = picked;
                            _counterSelectedSeats.clear();
                          });
                        }
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Fare Summary Box
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Column(
                    children: [
                      SummaryRow(
                          label: 'নির্বাচিত সিট',
                          value: _counterSelectedSeats.isEmpty
                              ? 'কোনোটি নয়'
                              : _counterSelectedSeats.join(', ')),
                      const SizedBox(height: 6),
                      SummaryRow(
                        label: 'মোট প্রদেয় মূল্য (ক্যাশ)',
                        value: '৳ $totalAmount',
                        isTotal: true,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 22),

                // Submit Counter Ticket Button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    icon: _isCounterSubmitting
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
                      _counterSelectedSeats.isEmpty
                          ? 'ডানপাশ থেকে সিট নির্বাচন করুন'
                          : 'টিকিট ইস্যু ও প্রিন্ট করুন (৳ $totalAmount)',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _counterSelectedSeats.isEmpty
                          ? Colors.grey.shade400
                          : AppColors.primaryGreen,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: _counterSelectedSeats.isEmpty ? 0 : 3,
                    ),
                    onPressed: (_counterSelectedSeats.isEmpty ||
                            _isCounterSubmitting)
                        ? null
                        : () => _submitCounterBooking(formattedCounterDate),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(width: 26),

        // Right Column: Live Interactive Seat Map (50% width)
        Expanded(
          flex: 50,
          child: Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: AppColors.primaryRed.withAlpha(40),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(8),
                  blurRadius: 12,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.event_seat_rounded,
                      color: AppColors.primaryRed,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'সিট নির্বাচন করুন:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: AppColors.primaryRed,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                StreamBuilder<ScheduleSeatsData>(
                  stream: widget.firestoreService.getScheduleSeatsStream(
                    busId: _counterSelectedBus.id,
                    journeyDate: formattedCounterDate,
                  ),
                  builder: (context, snapshot) {
                    final seatsData = snapshot.data ??
                        ScheduleSeatsData(bookedSeats: [], lockedSeats: []);

                    return SizedBox(
                      height: 440,
                      child: BusSeatPlanWidget(
                        bookedSeats: seatsData.bookedSeats,
                        lockedSeats: seatsData.lockedSeats,
                        selectedSeats: _counterSelectedSeats,
                        onSeatTap: (seatId) {
                          setState(() {
                            if (_counterSelectedSeats.contains(seatId)) {
                              _counterSelectedSeats.remove(seatId);
                            } else {
                              _counterSelectedSeats.add(seatId);
                            }
                          });
                        },
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
