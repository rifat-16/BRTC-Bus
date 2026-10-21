import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/app_colors.dart';
import '../../models/bus_model.dart';
import '../../models/ticket_model.dart';
import '../../services/firestore_service.dart';
import '../bus_seat_plan_widget.dart';
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

  @override
  Widget build(BuildContext context) {
    final String formattedCounterDate =
        DateFormat('dd MMM yyyy').format(_counterJourneyDate);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(18),
      child: Form(
        key: _counterFormKey,
        child: Column(
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
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 4),
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
                  label: Text(formattedCounterDate,
                      style: const TextStyle(fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryRed,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 14),
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
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.bold),
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
                onPressed: (_counterSelectedSeats.isEmpty ||
                        _isCounterSubmitting)
                    ? null
                    : () async {
                        if (!_counterFormKey.currentState!.validate()) {
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
                          selectedSeats:
                              List<String>.from(_counterSelectedSeats),
                          totalAmount: _counterSelectedSeats.length *
                              _counterSelectedBus.fare,
                          passengerName: _counterNameController.text.trim(),
                          passengerPhone: _counterPhoneController.text.trim(),
                          paymentMethod: 'COUNTER CASH',
                          trxId:
                              'COUNTER-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
                        );

                        final messenger = ScaffoldMessenger.of(context);

                        try {
                          final issuedTicket = await widget.firestoreService
                              .issueCounterTicket(
                            busId: _counterSelectedBus.id,
                            ticket: ticketToIssue,
                          );

                          messenger.showSnackBar(
                            const SnackBar(
                              content: Text(
                                  'কাউন্টার টিকিট সফলভাবে তৈরি হয়েছে!'),
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
                      },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
