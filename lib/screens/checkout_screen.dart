import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/app_colors.dart';
import '../models/ticket_model.dart';
import '../services/firestore_service.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/desktop_web_navbar.dart';
import '../widgets/responsive_layout.dart';
import '../widgets/summary_row.dart';
import 'payment_screen.dart';
import 'ticket_screen.dart';

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
  final FirestoreService _firestoreService = FirestoreService();
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  final TextEditingController _trxIdController = TextEditingController();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    _nameController = TextEditingController(text: user?.displayName ?? '');
    _phoneController = TextEditingController(text: user?.phoneNumber ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _trxIdController.dispose();
    super.dispose();
  }

  void _confirmMobileBooking() async {
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

  void _confirmUnifiedDesktopBooking() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_trxIdController.text.trim().length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('অনুগ্রহ করে সঠিক ট্রানজেকশন আইডি (TrxID) প্রদান করুন'),
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
        passengerName: _nameController.text.trim(),
        passengerPhone: _phoneController.text.trim(),
        paymentMethod: 'BKASH',
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
              passengerName: _nameController.text.trim(),
              phoneNumber: _phoneController.text.trim(),
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
    final user = FirebaseAuth.instance.currentUser;
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
                  title: const Text('Checkout'),
                  elevation: 0,
                ),
          body: Form(
            key: _formKey,
            child: ResponsiveLayout(
              mobile: _buildMobileLayout(user),
              desktop: _buildDesktopLayout(user, activeBkashNumber),
            ),
          ),
          bottomNavigationBar: isDesktop
              ? null
              : SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _confirmMobileBooking,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryGreen,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 2,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Proceed to Payment',
                                    style: TextStyle(
                                      fontSize: 17,
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
                  ),
                ),
        );
      },
    );
  }

  Widget _buildMobileLayout(User? user) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary Card
          Card(
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Booking Summary',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryRed,
                    ),
                  ),
                  const Divider(height: 20),
                  SummaryRow(label: 'Bus', value: widget.busName),
                  const SizedBox(height: 8),
                  SummaryRow(
                      label: 'Route', value: '${widget.from} → ${widget.to}'),
                  const SizedBox(height: 8),
                  SummaryRow(label: 'Date', value: widget.journeyDate),
                  if (widget.departureTime.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    SummaryRow(label: 'Time', value: widget.departureTime),
                  ],
                  const SizedBox(height: 8),
                  SummaryRow(
                      label: 'Seats', value: widget.selectedSeats.join(', ')),
                  const SizedBox(height: 12),
                  const Divider(),
                  const SizedBox(height: 6),
                  SummaryRow(
                    label: 'Total Amount',
                    value: '৳ ${widget.totalAmount}',
                    isTotal: true,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 28),

          Text(
            user != null
                ? 'Passenger Details'
                : 'Passenger Details (Guest Checkout)',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            user != null
                ? 'Your details are loaded from your account. You can update phone if needed.'
                : 'Please provide your name and phone number to receive ticket confirmation.',
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),

          const SizedBox(height: 18),

          // Input Form
          Column(
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
        ],
      ),
    );
  }

  Widget _buildDesktopLayout(User? user, String activeBkashNumber) {
    return SingleChildScrollView(
      child: ConstrainedWebContainer(
        maxWidth: 1200,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left Column: Unified Express Checkout Panel (60% width)
            Expanded(
              flex: 60,
              child: Column(
                children: [
                  // Step 1: Passenger Details Card
                  Container(
                    padding: const EdgeInsets.all(24),
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
                                Icons.assignment_ind_rounded,
                                color: AppColors.primaryRed,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  user != null
                                      ? '১. যাত্রীর তথ্য (Passenger Details)'
                                      : '১. যাত্রীর তথ্য (Guest Checkout)',
                                  style: const TextStyle(
                                    fontSize: 16.5,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primaryRed,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  user != null
                                      ? 'Your account details loaded. Update phone if needed.'
                                      : 'Provide details to receive ticket SMS and PDF.',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),

                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 14),
                          child: Divider(height: 1),
                        ),

                        Row(
                          children: [
                            Expanded(
                              child: CustomTextField(
                                controller: _nameController,
                                labelText: 'Full Name',
                                hintText: 'আপনার নাম লিখুন',
                                prefixIcon: Icons.person_outline,
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'আপনার নাম লিখুন';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: CustomTextField(
                                controller: _phoneController,
                                labelText: 'Mobile Number',
                                prefixIcon: Icons.phone_android,
                                hintText: '১১ ডিজিটের মোবাইল নম্বর',
                                keyboardType: TextInputType.phone,
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'মোবাইল নম্বর লিখুন';
                                  }
                                  if (value.trim().length != 11) {
                                    return '১১ ডিজিটের নম্বর প্রদান করুন';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Step 2 & 3: Payment Method & TrxID Verification Card
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: AppColors.primaryGreen.withAlpha(60),
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
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE2136E).withAlpha(20),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.account_balance_wallet_rounded,
                                color: Color(0xFFE2136E),
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '২. বিকাশ পেমেন্ট নির্দেশিকা ও ট্রানজেকশন (BKASH)',
                                  style: TextStyle(
                                    fontSize: 16.5,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFFE2136E),
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Send Money করে ট্রানজেকশন আইডি (TrxID) দিন',
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
                          padding: EdgeInsets.symmetric(vertical: 14),
                          child: Divider(height: 1),
                        ),

                        // bKash Number Copy Box
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.orange.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'BKASH পার্সোনাল নম্বর',
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.orange.shade900,
                                    ),
                                  ),
                                  Text(
                                    'মোট প্রদেয়: ৳ ${widget.totalAmount}',
                                    style: const TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w900,
                                      color: AppColors.primaryRed,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 10,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius:
                                            BorderRadius.circular(10),
                                        border: Border.all(
                                            color: Colors.grey.shade300),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.phone_android_rounded,
                                            size: 18,
                                            color: Colors.grey,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            activeBkashNumber,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 0.5,
                                              color: AppColors.textPrimary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  ElevatedButton.icon(
                                    onPressed: () {
                                      Clipboard.setData(
                                        ClipboardData(text: activeBkashNumber),
                                      );
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'বিকাশ নম্বরটি ($activeBkashNumber) কপি করা হয়েছে!',
                                          ),
                                          backgroundColor:
                                              AppColors.primaryGreen,
                                          behavior: SnackBarBehavior.floating,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                        ),
                                      );
                                    },
                                    icon: const Icon(Icons.copy_rounded,
                                        size: 15),
                                    label: const Text(
                                      'কপি করুন',
                                      style: TextStyle(fontSize: 12),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primaryGreen,
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 12,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(10),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Send Money Steps & TrxID Field Row
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildInstructionStep(
                                    stepNumber: '১',
                                    title: 'Send Money করুন',
                                    description:
                                        'বিকাশ অ্যাপ/ডায়াল থেকে Send Money করে ঠিক ৳ ${widget.totalAmount} টাকা পাঠিয় দিন।',
                                  ),
                                  const SizedBox(height: 10),
                                  _buildInstructionStep(
                                    stepNumber: '২',
                                    title: 'TrxID সাবমিট করুন',
                                    description:
                                        'পেমেন্ট এসএমএস থেকে ট্রানজেকশন আইডি (TrxID) কপি করে ডানের বক্সে প্রদান করুন।',
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: CustomTextField(
                                controller: _trxIdController,
                                labelText: 'ট্রানজেকশন আইডি (TrxID)',
                                hintText: 'উদাহরণ: 9J8A7B6C',
                                prefixIcon: Icons.tag_rounded,
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'TrxID লিখুন';
                                  }
                                  if (value.trim().length < 6) {
                                    return 'সঠিক TrxID দিন';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // Express Complete Booking Button
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: _isLoading
                                ? null
                                : _confirmUnifiedDesktopBooking,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryGreen,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 3,
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.check_circle_rounded,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        'পেমেন্ট নিশ্চিত করুন ও টিকিট বুক করুন (Complete Booking)',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 28),

            // Right Column: Sticky Live Order Summary Card (40% width)
            Expanded(
              flex: 40,
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
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
                    const Row(
                      children: [
                        Icon(
                          Icons.receipt_long_rounded,
                          color: AppColors.primaryRed,
                          size: 22,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'অর্ডার সামারি (Order Summary)',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryRed,
                          ),
                        ),
                      ],
                    ),

                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 14),
                      child: Divider(height: 1),
                    ),

                    SummaryRow(label: 'বাসের নাম', value: widget.busName),
                    const SizedBox(height: 10),
                    SummaryRow(
                        label: 'রুট', value: '${widget.from} → ${widget.to}'),
                    const SizedBox(height: 10),
                    SummaryRow(
                        label: 'যাত্রার তারিখ', value: widget.journeyDate),
                    if (widget.departureTime.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      SummaryRow(label: 'সময়', value: widget.departureTime),
                    ],
                    const SizedBox(height: 10),
                    SummaryRow(
                        label: 'সিটসমূহ',
                        value: widget.selectedSeats.join(', ')),

                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 14),
                      child: Divider(height: 1),
                    ),

                    SummaryRow(
                      label: 'সর্বমোট প্রদেয় মূল্য',
                      value: '৳ ${widget.totalAmount}',
                      isTotal: true,
                    ),

                    const SizedBox(height: 24),

                    // Official BRTC Security Badge
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.backgroundColor,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.verified_user_rounded,
                            color: AppColors.primaryGreen,
                            size: 20,
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'BRTC Official E-Ticketing System\n100% Verified & Secure Payment',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                                height: 1.3,
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
          ],
        ),
      ),
    );
  }

  Widget _buildInstructionStep({
    required String stepNumber,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: const BoxDecoration(
            color: AppColors.primaryRed,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              stepNumber,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 11.5,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: const TextStyle(
                  fontSize: 11.5,
                  color: AppColors.textSecondary,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
