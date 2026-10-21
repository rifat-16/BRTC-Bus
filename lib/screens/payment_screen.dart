import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/app_colors.dart';
import '../models/ticket_model.dart';
import '../services/firestore_service.dart';
import '../widgets/payment_method_card.dart';
import 'manual_verification_screen.dart';
import 'ticket_screen.dart';

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
  String _selectedMethod = 'bkash';
  bool _isLoading = false;

  final Map<String, String> _paymentNumbers = {
    'bkash': '01712345678',
    'nagad': '01912345678',
    'rocket': '01812345678',
  };

  final Map<String, String> _paymentSubtitles = {
    'bkash': 'Pay securely with bKash',
    'nagad': 'Pay via Nagad account',
    'rocket': 'Dutch-Bangla Bank Mobile Banking',
    'card': 'Visa, MasterCard, Amex',
  };

  void _proceedToNext() async {
    if (_selectedMethod == 'card') {
      setState(() {
        _isLoading = true;
      });

      try {
        final user = FirebaseAuth.instance.currentUser;
        final ticket = TicketModel(
          busId: widget.busId,
          userId: user?.uid ?? 'guest',
          userEmail: user?.email ?? 'guest@brtc.com',
          busName: widget.busName,
          from: widget.from,
          to: widget.to,
          journeyDate: widget.journeyDate,
          selectedSeats: widget.selectedSeats,
          totalAmount: widget.totalAmount,
          passengerName: widget.passengerName,
          passengerPhone: widget.phoneNumber,
          paymentMethod: 'CARD',
          trxId: 'CARD-${DateTime.now().millisecondsSinceEpoch.toString().substring(6)}',
        );

        final createdTicket = await _firestoreService.bookSeatsAndCreateTicket(
          busId: widget.busId,
          ticket: ticket,
        );

        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (context) => TicketScreen(
                ticketId: createdTicket.ticketId ?? 'BRTC-TICKET',
                passengerName: widget.passengerName,
                phoneNumber: widget.phoneNumber,
                busName: widget.busName,
                from: widget.from,
                to: widget.to,
                journeyDate: widget.journeyDate,
                departureTime: widget.departureTime,
                seats: widget.selectedSeats,
                amountPaid: widget.totalAmount,
              ),
            ),
            (route) => false,
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString().replaceAll('Exception: ', '')),
              backgroundColor: AppColors.primaryRed,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } else {
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
            selectedMethod: _selectedMethod,
            paymentNumber: _paymentNumbers[_selectedMethod]!,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        title: const Text('Payment'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
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
                borderRadius: BorderRadius.circular(16),
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
                  const Text('Amount to Pay', style: TextStyle(color: Colors.white70, fontSize: 16)),
                  const SizedBox(height: 8),
                  Text(
                    '৳ ${widget.totalAmount}',
                    style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            const Text(
              'Select Payment Method',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Payment Methods List
            _buildPaymentOption(
              id: 'bkash',
              title: 'bKash',
              subtitle: _paymentSubtitles['bkash']!,
              iconData: Icons.account_balance_wallet,
              color: Colors.pink,
            ),
            _buildPaymentOption(
              id: 'nagad',
              title: 'Nagad',
              subtitle: _paymentSubtitles['nagad']!,
              iconData: Icons.mobile_screen_share,
              color: Colors.deepOrange,
            ),
            _buildPaymentOption(
              id: 'rocket',
              title: 'Rocket',
              subtitle: _paymentSubtitles['rocket']!,
              iconData: Icons.rocket_launch,
              color: Colors.purple,
            ),
            _buildPaymentOption(
              id: 'card',
              title: 'Credit / Debit Card',
              subtitle: _paymentSubtitles['card']!,
              iconData: Icons.credit_card,
              color: Colors.blueAccent,
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _proceedToNext,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Text(
                      'Proceed',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentOption({
    required String id,
    required String title,
    required String subtitle,
    required IconData iconData,
    required Color color,
  }) {
    final isSelected = _selectedMethod == id;

    return PaymentMethodCard(
      title: title,
      subtitle: subtitle,
      iconData: iconData,
      color: color,
      isSelected: isSelected,
      onTap: () {
        setState(() {
          _selectedMethod = id;
        });
      },
    );
  }
}
