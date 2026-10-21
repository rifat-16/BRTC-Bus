import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/bus_model.dart';
import '../models/ticket_model.dart';

class PdfService {
  static String _cleanBengaliText(String input) {
    var result = input;
    // Map Bengali Station / Location Names to English
    result = result.replaceAll('ঢাকা', 'Dhaka');
    result = result.replaceAll('সখিপুর', 'Sakhipur');
    result = result.replaceAll('সখীপুর', 'Sakhipur');
    result = result.replaceAll('বড়চওনা', 'Borochowna');
    result = result.replaceAll('গারোবাজার', 'Garobazar');
    result = result.replaceAll('সাগরদিঘী', 'Sagardighi');
    result = result.replaceAll('ফিরতী', 'Return');
    result = result.replaceAll('সচিবালয়', 'Secretariat');
    result = result.replaceAll('খামার বাড়ী', 'Khamar Bari');
    result = result.replaceAll('মোড়', 'Intersection');

    // Convert Bengali Numerals to Standard English Digits
    const bangla = ['০', '১', '২', '৩', '৪', '৫', '৬', '৭', '৮', '৯'];
    const english = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    for (int i = 0; i < bangla.length; i++) {
      result = result.replaceAll(bangla[i], english[i]);
    }

    return result;
  }

  static Future<void> generateAndPrintManifest({
    required BusModel bus,
    required String dateStr,
    required List<TicketModel> tripTickets,
  }) async {
    final pdf = pw.Document();

    int totalEarnings = 0;
    int totalBookedSeats = 0;

    for (final t in tripTickets) {
      totalEarnings += t.totalAmount;
      totalBookedSeats += t.selectedSeats.length;
    }

    final String generatedAt =
        DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now());

    final String cleanBusName = _cleanBengaliText(bus.busName);
    final String cleanFrom = _cleanBengaliText(bus.from);
    final String cleanTo = _cleanBengaliText(bus.to);
    final String cleanDepartureTime = _cleanBengaliText(bus.departureTime);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header Banner
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: PdfColors.red900,
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Column(
                  children: [
                    pw.Text(
                      'BANGLADESH ROAD TRANSPORT CORPORATION (BRTC)',
                      style: pw.TextStyle(
                        color: PdfColors.white,
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                      ),
                      textAlign: pw.TextAlign.center,
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'OFFICIAL BUS PASSENGER MANIFEST & WAYBILL',
                      style: pw.TextStyle(
                        color: PdfColors.white,
                        fontSize: 11,
                        fontWeight: pw.FontWeight.bold,
                      ),
                      textAlign: pw.TextAlign.center,
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 16),

              // Trip Metadata Grid
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey400),
                  borderRadius: pw.BorderRadius.circular(8),
                  color: PdfColors.grey100,
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          'Bus Service: $cleanBusName',
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 12,
                            color: PdfColors.red900,
                          ),
                        ),
                        pw.Text(
                          'Date: $dateStr',
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 6),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          'Route: $cleanFrom -> $cleanTo',
                          style: const pw.TextStyle(fontSize: 10.5),
                        ),
                        pw.Text(
                          'Departure: $cleanDepartureTime',
                          style: const pw.TextStyle(fontSize: 10.5),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 6),
                    pw.Divider(color: PdfColors.grey300),
                    pw.SizedBox(height: 4),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          'Seats Booked: $totalBookedSeats / 45',
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 11,
                            color: PdfColors.green900,
                          ),
                        ),
                        pw.Text(
                          'Total Collection: Tk $totalEarnings',
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 11,
                            color: PdfColors.green900,
                          ),
                        ),
                        pw.Text(
                          'Generated: $generatedAt',
                          style: const pw.TextStyle(
                            fontSize: 9.5,
                            color: PdfColors.grey700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 16),

              pw.Text(
                'PASSENGER LIST (WAYBILL)',
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.grey900,
                ),
              ),

              pw.SizedBox(height: 8),

              // Passenger Table
              if (tripTickets.isEmpty)
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.all(20),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey300),
                    borderRadius: pw.BorderRadius.circular(6),
                  ),
                  child: pw.Center(
                    child: pw.Text(
                      'No online or counter tickets sold for this trip.',
                      style: const pw.TextStyle(
                        fontSize: 11,
                        color: PdfColors.grey700,
                      ),
                    ),
                  ),
                )
              else
                pw.TableHelper.fromTextArray(
                  headers: [
                    'SL',
                    'Passenger Name',
                    'Phone Number',
                    'Seat(s)',
                    'Fare (Tk)',
                    'Payment',
                    'Supervisor Check'
                  ],
                  data: List<List<String>>.generate(tripTickets.length,
                      (index) {
                    final t = tripTickets[index];
                    return [
                      '${index + 1}',
                      _cleanBengaliText(t.passengerName),
                      _cleanBengaliText(t.passengerPhone),
                      t.selectedSeats.join(', '),
                      'Tk ${t.totalAmount}',
                      t.paymentMethod,
                      '[   ] Verified'
                    ];
                  }),
                  headerStyle: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                    fontSize: 10,
                  ),
                  headerDecoration: const pw.BoxDecoration(
                    color: PdfColors.red900,
                  ),
                  rowDecoration: const pw.BoxDecoration(
                    border: pw.Border(
                      bottom: pw.BorderSide(color: PdfColors.grey300),
                    ),
                  ),
                  cellPadding: const pw.EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                  cellStyle: const pw.TextStyle(fontSize: 9.5),
                  cellAlignment: pw.Alignment.centerLeft,
                ),

              pw.Spacer(),

              // Footer Signatures
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(vertical: 12),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      children: [
                        pw.Container(
                          width: 140,
                          decoration: const pw.BoxDecoration(
                            border: pw.Border(
                              top: pw.BorderSide(color: PdfColors.black),
                            ),
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          'Counter Manager Signature',
                          style: pw.TextStyle(
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      children: [
                        pw.Container(
                          width: 140,
                          decoration: const pw.BoxDecoration(
                            border: pw.Border(
                              top: pw.BorderSide(color: PdfColors.black),
                            ),
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          'Bus Supervisor Signature',
                          style: pw.TextStyle(
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );

    // Trigger Native Printing / PDF Download / Share Dialog
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'BRTC_Manifest_${bus.id}_$dateStr.pdf',
    );
  }
}
