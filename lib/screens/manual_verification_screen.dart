import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/app_colors.dart';
import '../models/ticket_model.dart';
import '../services/firestore_service.dart';
import '../widgets/manual_payment_verification_card.dart';
import 'ticket_screen.dart';

class ManualVerificationScreen extends StatefulWidget {
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
  final String selectedMethod;
  final String paymentNumber;

  const ManualVerificationScreen({
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
    required this.selectedMethod,
    required this.paymentNumber,
  });

  @override
  State<ManualVerificationScreen> createState() => _ManualVerificationScreenState();
}

class _ManualVerificationScreenState extends State<ManualVerificationScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  bool _isLoading = false;
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _trxIdController = TextEditingController();

  @override
  void dispose() {
    _trxIdController.dispose();
    super.dispose();
  }

  void _verifyPayment() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

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
        paymentMethod: widget.selectedMethod.toUpperCase(),
        trxId: _trxIdController.text.trim(),
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        title: Text('পেমেন্ট ভেরিফিকেশন (${widget.selectedMethod.toUpperCase()})'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ManualPaymentVerificationCard(
                selectedMethod: widget.selectedMethod,
                paymentNumber: widget.paymentNumber,
                totalAmount: widget.totalAmount,
                trxIdController: _trxIdController,
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _verifyPayment,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 2,
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Text(
                      'পেমেন্ট নিশ্চিত করুন (Verify Payment)',
                      style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
