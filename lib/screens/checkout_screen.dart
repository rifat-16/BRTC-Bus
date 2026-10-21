import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/app_colors.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/summary_row.dart';
import 'payment_screen.dart';

class CheckoutScreen extends StatefulWidget {
  final String busId;
  final String busName;
  final String from;
  final String to;
  final String journeyDate;
  final String departureTime;
  final List<String> selectedSeats;
  final int totalAmount;

  const CheckoutScreen({
    super.key,
    required this.busId,
    required this.busName,
    required this.from,
    required this.to,
    required this.journeyDate,
    this.departureTime = '',
    required this.selectedSeats,
    required this.totalAmount,
  });

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    _nameController = TextEditingController(text: user?.displayName ?? '');
    _phoneController = TextEditingController(text: user?.phoneNumber ?? '');
  }

  void _confirmBooking() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      await Future.delayed(const Duration(milliseconds: 300));

      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PaymentScreen(
              busId: widget.busId,
              passengerName: _nameController.text.trim(),
              phoneNumber: _phoneController.text.trim(),
              busName: widget.busName,
              from: widget.from,
              to: widget.to,
              journeyDate: widget.journeyDate,
              departureTime: widget.departureTime,
              selectedSeats: widget.selectedSeats,
              totalAmount: widget.totalAmount,
            ),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        title: const Text('Checkout'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Summary Card
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Booking Summary', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const Divider(),
                    const SizedBox(height: 10),
                    SummaryRow(label: 'Bus', value: widget.busName),
                    const SizedBox(height: 8),
                    SummaryRow(label: 'Route', value: '${widget.from} → ${widget.to}'),
                    const SizedBox(height: 8),
                    SummaryRow(label: 'Date', value: widget.journeyDate),
                    const SizedBox(height: 8),
                    SummaryRow(label: 'Seats', value: widget.selectedSeats.join(', ')),
                    const SizedBox(height: 8),
                    SummaryRow(label: 'Total Amount', value: '৳ ${widget.totalAmount}', isTotal: true),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 30),

            Text(
              user != null ? 'Passenger Details' : 'Passenger Details (Guest Checkout)',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              user != null
                  ? 'Your details are loaded from your account. You can update phone if needed.'
                  : 'Please provide your name and phone number to receive ticket confirmation.',
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),

            const SizedBox(height: 20),

            // Input Form
            Form(
              key: _formKey,
              child: Column(
                children: [
                  CustomTextField(
                    controller: _nameController,
                    labelText: 'Full Name',
                    hintText: 'Enter your full name (আপনার নাম লিখুন)',
                    prefixIcon: Icons.person_outline,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter your name (আপনার নাম লিখুন)';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: _phoneController,
                    labelText: 'Mobile Number',
                    prefixIcon: Icons.phone_android,
                    hintText: 'Enter your phone number (১১ ডিজিটের মোবাইল নম্বর)',
                    keyboardType: TextInputType.phone,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter your mobile number';
                      }
                      if (value.trim().length != 11) {
                        return 'Please enter a valid 11-digit mobile number';
                      }
                      return null;
                    },
                  ),
                ],
              ),
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
              onPressed: _isLoading ? null : _confirmBooking,
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
                      'Proceed to Payment',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
