import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/app_colors.dart';
import '../models/bus_model.dart';
import '../models/ticket_model.dart';
import '../services/firestore_service.dart';
import '../services/pdf_service.dart';

class BusManifestScreen extends StatefulWidget {
  const BusManifestScreen({super.key});

  @override
  State<BusManifestScreen> createState() => _BusManifestScreenState();
}

class _BusManifestScreenState extends State<BusManifestScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  DateTime _selectedDate = DateTime.now();

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

  @override
  Widget build(BuildContext context) {
    final String formattedDate =
        DateFormat('dd MMM yyyy').format(_selectedDate);

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        title: const Text('লাইভ বাস ট্রিপ ও যাত্রী ম্যানিফেস্ট'),
        backgroundColor: AppColors.primaryRedDark,
        elevation: 2,
      ),
      body: StreamBuilder<List<TicketModel>>(
        stream: _firestoreService.getAllTicketsStream(),
        builder: (context, snapshot) {
          final allTickets = snapshot.data ?? [];

          return SingleChildScrollView(
            padding: const EdgeInsets.all(18),
            child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Date Picker Selection Banner
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(8),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'যাত্রার ম্যানিফেস্ট তারিখ:',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                formattedDate,
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primaryRed,
                                ),
                              ),
                            ],
                          ),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.calendar_month_rounded,
                                size: 18),
                            label: const Text('তারিখ পরিবর্তন'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryGreen,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: _selectedDate,
                                firstDate: DateTime.now()
                                    .subtract(const Duration(days: 30)),
                                lastDate: DateTime.now()
                                    .add(const Duration(days: 60)),
                              );
                              if (picked != null) {
                                setState(() {
                                  _selectedDate = picked;
                                });
                              }
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    const Text(
                      'দৈনিক ৪টি ট্রিপের লাইভ স্ট্যাটাস (Trip Manifests):',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),

                    // List of all 4 Official BRTC Bus Trips
                    ...FirestoreService.officialBRTCBuses.map((bus) {
                      final tripTickets = allTickets.where((t) {
                        if (t.journeyDate != formattedDate ||
                            t.status == 'REJECTED') {
                          return false;
                        }

                        // 1. Direct Exact Match by busId
                        if (t.busId.isNotEmpty) {
                          return t.busId == bus.id;
                        }

                        // 2. Strict Fallback Match by busName & Direction (Going vs Return)
                        final bool busIsReturn = bus.busName.contains('ফিরতী');
                        final bool ticketIsReturn = t.busName.contains('ফিরতী');

                        if (busIsReturn != ticketIsReturn) {
                          return false;
                        }

                        if (bus.id.contains('_1_')) {
                          return t.busName.contains('1') || t.busName.contains('১');
                        } else if (bus.id.contains('_2_')) {
                          return t.busName.contains('2') || t.busName.contains('২');
                        }

                        return t.busName == bus.busName;
                      }).toList();

                      return _buildTripManifestCard(
                        bus: bus,
                        dateStr: formattedDate,
                        tripTickets: tripTickets,
                      );
                    }),
                  ],
                ),
              );
        },
      ),
    );
  }

  Widget _buildTripManifestCard({
    required BusModel bus,
    required String dateStr,
    required List<TicketModel> tripTickets,
  }) {
    return StreamBuilder<ScheduleSeatsData>(
      stream: _firestoreService.getScheduleSeatsStream(
        busId: bus.id,
        journeyDate: dateStr,
      ),
      builder: (context, snapshot) {
        final seatsData =
            snapshot.data ?? ScheduleSeatsData(bookedSeats: [], lockedSeats: []);

        final Set<String> occupiedSeatIds = {
          ...seatsData.bookedSeats,
          ...seatsData.lockedSeats,
        };

        final int totalSeats = bus.totalSeats; // 45
        final int bookedCount = occupiedSeatIds.length;
        final int availableCount = totalSeats - bookedCount;
        final double percentage =
            totalSeats > 0 ? (bookedCount / totalSeats) : 0.0;

        Color statusColor = AppColors.primaryGreen;
        if (percentage >= 0.85) {
          statusColor = AppColors.primaryRed;
        } else if (percentage >= 0.5) {
          statusColor = Colors.orange.shade800;
        }

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: statusColor.withAlpha(80), width: 1.5),
          ),
          elevation: 2,
          child: ExpansionTile(
            shape: const Border(),
            tilePadding:
                const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: statusColor.withAlpha(20),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.directions_bus_filled_rounded,
                color: statusColor,
                size: 24,
              ),
            ),
            title: Text(
              bus.busName,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: statusColor,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 2),
                Text(
                  'সময়: ${bus.departureTime}',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'বুকড: $bookedCount / $totalSeats সিট',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12.5,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      'ফাঁকা: $availableCount টি',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12.5,
                        color: AppColors.primaryGreen,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: statusColor.withAlpha(25),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${(percentage * 100).round()}% Full',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: percentage,
                    minHeight: 6,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                  ),
                ),
              ],
            ),
            children: [
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Flexible(
                          child: Text(
                            'যাত্রী ম্যানিফেস্ট তালিকা (Passengers List):',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        Row(
                          children: [
                            OutlinedButton.icon(
                              icon: const Icon(Icons.picture_as_pdf_rounded,
                                  size: 15),
                              label: const Text('PDF ওয়েবিল',
                                  style: TextStyle(fontSize: 11.5)),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.primaryRed,
                                side: const BorderSide(
                                    color: AppColors.primaryRed),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 6),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              onPressed: () =>
                                  PdfService.generateAndPrintManifest(
                                bus: bus,
                                dateStr: dateStr,
                                tripTickets: tripTickets,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    tripTickets.isEmpty
                        ? Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.backgroundColor,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'এই ট্রিপে এখন পর্যন্ত কোনো অনলাইন/কাউন্টার টিকিট বিক্রি হয়নি।',
                              style: TextStyle(
                                  fontSize: 12, color: AppColors.textSecondary),
                              textAlign: TextAlign.center,
                            ),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: tripTickets.length,
                            itemBuilder: (context, index) {
                              final ticket = tripTickets[index];
                              final bool isConfirmed =
                                  ticket.status == 'CONFIRMED';

                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.backgroundColor,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                      color: Colors.grey.shade300),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '${ticket.passengerName} (${ticket.passengerPhone})',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            'সিট: ${ticket.selectedSeats.join(', ')} • ৳ ${ticket.totalAmount}',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey.shade800,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: isConfirmed
                                                ? AppColors.primaryGreen
                                                    .withAlpha(20)
                                                : Colors.orange.shade100,
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            ticket.paymentMethod,
                                            style: TextStyle(
                                              fontSize: 10.5,
                                              fontWeight: FontWeight.bold,
                                              color: isConfirmed
                                                  ? AppColors.primaryGreen
                                                  : Colors.orange.shade900,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        IconButton(
                                          icon: const Icon(
                                              Icons.phone_forwarded_rounded,
                                              size: 18,
                                              color: AppColors.primaryGreen),
                                          onPressed: () => _makePhoneCall(
                                              ticket.passengerPhone),
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                          tooltip: 'কল করুন',
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
