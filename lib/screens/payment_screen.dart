import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../services/firestore_service.dart';
import '../widgets/desktop_web_navbar.dart';
import '../widgets/responsive_layout.dart';
import '../widgets/summary_row.dart';
import 'manual_verification_screen.dart';

class PaymentScreen extends StatefulWidget {
  final String busId;
  final String passengerName;
  final String phoneNumber;
  final String busName;
  final String from;
  final String to;
  final String journeyDate;
  final String departureTime;
  final List<String> selectedSeats;
  final int totalAmount;

  const PaymentScreen({
    super.key,
    required this.busId,
    required this.passengerName,
    required this.phoneNumber,
    required this.busName,
    required this.from,
    required this.to,
    required this.journeyDate,
    this.departureTime = '',
    required this.selectedSeats,
    required this.totalAmount,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  void _proceedToNext(String currentBkashNumber) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ManualVerificationScreen(
          busId: widget.busId,
          passengerName: widget.passengerName,
          phoneNumber: widget.phoneNumber,
          busName: widget.busName,
          from: widget.from,
          to: widget.to,
          journeyDate: widget.journeyDate,
          departureTime: widget.departureTime,
          selectedSeats: widget.selectedSeats,
          totalAmount: widget.totalAmount,
          selectedMethod: 'bkash',
          paymentNumber: currentBkashNumber,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveLayout.isDesktop(context);

    return StreamBuilder<String>(
      stream: _firestoreService.getPaymentConfigStream(),
      builder: (context, snapshot) {
        final String activeBkashNumber = snapshot.data ?? '01712345678';

        return Scaffold(
          backgroundColor: AppColors.backgroundColor,
          appBar: isDesktop
              ? const DesktopWebNavbar()
              : AppBar(
                  title: const Text('পেমেন্ট পদ্ধতি নির্বাচন'),
                  elevation: 0,
                  backgroundColor: AppColors.primaryRedDark,
                ),
          body: ResponsiveLayout(
            mobile: _buildMobileLayout(activeBkashNumber),
            desktop: _buildDesktopLayout(activeBkashNumber),
          ),
          bottomNavigationBar: isDesktop
              ? null
              : SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: () => _proceedToNext(activeBkashNumber),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryGreen,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 2,
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'পরবর্তী ধাপে যান (Proceed)',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(width: 6),
                            Icon(
                              Icons.arrow_forward_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
        );
      },
    );
  }

  Widget _buildMobileLayout(String activeBkashNumber) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Amount Display Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primaryRed, Colors.redAccent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.red.withAlpha(76),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              children: [
                const Text(
                  'পরিশোধযোগ্য মূল্য (Amount to Pay)',
                  style: TextStyle(color: Colors.white70, fontSize: 15),
                ),
                const SizedBox(height: 8),
                Text(
                  '৳ ${widget.totalAmount}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 38,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          const Text(
            'পেমেন্ট মেথড (Payment Method)',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 14),

          // Official bKash Card Option
          _buildBkashMethodCard(),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout(String activeBkashNumber) {
    return SingleChildScrollView(
      child: ConstrainedWebContainer(
        maxWidth: 950,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left Column: Payment Method Selection (55% width)
            Expanded(
              flex: 55,
              child: Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.grey.shade300),
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
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE2136E).withAlpha(20),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.account_balance_wallet_rounded,
                            color: Color(0xFFE2136E),
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'পেমেন্ট পদ্ধতি নির্বাচন করুন',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Select your preferred payment gateway',
                              style: TextStyle(
                                fontSize: 12.5,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Divider(height: 1),
                    ),

                    // Official bKash Card Option
                    _buildBkashMethodCard(),

                    const SizedBox(height: 24),

                    // Security Info Box
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.backgroundColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.security_rounded,
                            color: AppColors.primaryGreen,
                            size: 22,
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'আপনার লেনদেনটি বিআরটিসি অফিসিয়াল এডমিন প্যানেল দ্বারা নিরাপদে সংরক্ষিত ও ভেরিফাই হবে।',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                                height: 1.35,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(width: 28),

            // Right Column: Price & Order Summary Card (45% width)
            Expanded(
              flex: 45,
              child: Container(
                padding: const EdgeInsets.all(24),
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
                    // Amount Display Gradient Banner
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.primaryRed, Colors.redAccent],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.red.withAlpha(60),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'পরিশোধযোগ্য মূল্য (Amount to Pay)',
                            style:
                                TextStyle(color: Colors.white70, fontSize: 13.5),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '৳ ${widget.totalAmount}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 36,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 18),
                      child: Divider(height: 1),
                    ),

                    SummaryRow(label: 'যাত্রীর নাম', value: widget.passengerName),
                    const SizedBox(height: 8),
                    SummaryRow(label: 'ফোন নম্বর', value: widget.phoneNumber),
                    const SizedBox(height: 8),
                    SummaryRow(label: 'বাস নাম', value: widget.busName),
                    const SizedBox(height: 8),
                    SummaryRow(
                        label: 'রুট', value: '${widget.from} → ${widget.to}'),
                    const SizedBox(height: 8),
                    SummaryRow(label: 'তারিখ', value: widget.journeyDate),
                    const SizedBox(height: 8),
                    SummaryRow(
                        label: 'সিটসমূহ', value: widget.selectedSeats.join(', ')),

                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: () => _proceedToNext(activeBkashNumber),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryGreen,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 3,
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'পরবর্তী ধাপে যান (Proceed)',
                              style: TextStyle(
                                fontSize: 16.5,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(width: 8),
                            Icon(
                              Icons.arrow_forward_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBkashMethodCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE2136E),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE2136E).withAlpha(25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const _BKashOfficialLogoWidget(),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'bKash (বিকাশ)',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFE2136E),
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Send Money করে নিরাপদ পেমেন্ট করুন',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 22,
            height: 22,
            decoration: const BoxDecoration(
              color: Color(0xFFE2136E),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_rounded,
              color: Colors.white,
              size: 15,
            ),
          ),
        ],
      ),
    );
  }
}

/// Official bKash Brand Logo Widget
class _BKashOfficialLogoWidget extends StatelessWidget {
  const _BKashOfficialLogoWidget();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 76,
      height: 44,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2136E).withAlpha(40)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Image.network(
        'https://seeklogo.com/images/B/bkash-logo-FBB258B90F-seeklogo.com.png',
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return Image.network(
            'https://raw.githubusercontent.com/bikash-logo/bkash_logo.png',
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFE2136E),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Text(
                    'bKash',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
