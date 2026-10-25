import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/app_colors.dart';
import '../models/ticket_model.dart';
import '../services/firestore_service.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/desktop_web_navbar.dart';
import '../widgets/manual_payment_verification_card.dart';
import '../widgets/responsive_layout.dart';
import '../widgets/summary_row.dart';
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
  State<ManualVerificationScreen> createState() =>
      _ManualVerificationScreenState();
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
    final isDesktop = ResponsiveLayout.isDesktop(context);
    final methodUpper = widget.selectedMethod.toUpperCase();

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: isDesktop
          ? const DesktopWebNavbar()
          : AppBar(
              title: Text('পেমেন্ট ভেরিফিকেশন ($methodUpper)'),
              elevation: 0,
            ),
      body: Form(
        key: _formKey,
        child: ResponsiveLayout(
          mobile: _buildMobileLayout(),
          desktop: _buildDesktopLayout(methodUpper),
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
                    onPressed: _isLoading ? null : _verifyPayment,
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
                        : const Text(
                            'পেমেন্ট নিশ্চিত করুন (Verify Payment)',
                            style: TextStyle(
                              fontSize: 16.5,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildMobileLayout() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
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
    );
  }

  Widget _buildDesktopLayout(String methodUpper) {
    return SingleChildScrollView(
      child: ConstrainedWebContainer(
        maxWidth: 1000,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left Column: Step-by-Step Payment Instructions Card (52% width)
            Expanded(
              flex: 52,
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
                            color: AppColors.primaryGreen.withAlpha(20),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.phonelink_ring_rounded,
                            color: AppColors.primaryGreen,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'সহজ পেমেন্ট নির্দেশনা ($methodUpper)',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'নিচের ৩টি ধাপ অনুসরণ করে পেমেন্ট সম্পন্ন করুন',
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
                      padding: EdgeInsets.symmetric(vertical: 18),
                      child: Divider(height: 1),
                    ),

                    // Step 1: Number Copy Box
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'ধাপ ১: $methodUpper পার্সোনাল নম্বর',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange.shade900,
                                ),
                              ),
                              Text(
                                'মোট ৳ ${widget.totalAmount}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.primaryRed,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 11,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
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
                                        widget.paymentNumber,
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
                                    ClipboardData(
                                        text: widget.paymentNumber),
                                  );
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        '$methodUpper নম্বরটি (${widget.paymentNumber}) কপি করা হয়েছে!',
                                      ),
                                      backgroundColor: AppColors.primaryGreen,
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(12),
                                      ),
                                    ),
                                  );
                                },
                                icon:
                                    const Icon(Icons.copy_rounded, size: 16),
                                label: const Text(
                                  'কপি করুন',
                                  style: TextStyle(fontSize: 12.5),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primaryGreen,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    _buildInstructionStep(
                      stepNumber: '২',
                      title: 'Send Money সম্পন্ন করুন',
                      description:
                          'আপনার $methodUpper মোবাইল অ্যাপ বা ডায়াল কোড ব্যবহার করে Send Money অপশনে যান এবং ওপরের নম্বরটিতে ঠিক ৳ ${widget.totalAmount} পাঠিয় দিন।',
                    ),
                    const SizedBox(height: 16),
                    _buildInstructionStep(
                      stepNumber: '৩',
                      title: 'SMS এর TrxID এখানে প্রদান করুন',
                      description:
                          'টাকা পাঠানো সফল হলে আপনার ফোনে কনফার্মেশন এসএমএস থেকে ৮ ডিজিটের TrxID (যেমন: 9J8A7B6C) কপি করে পাশের ফর্মে সাবমিট করুন।',
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(width: 28),

            // Right Column: TrxID Form & Summary Card (48% width)
            Expanded(
              flex: 48,
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: AppColors.primaryGreen.withAlpha(50),
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
                          Icons.verified_rounded,
                          color: AppColors.primaryGreen,
                          size: 22,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'পেমেন্ট ভেরিফিকেশন',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryGreen,
                          ),
                        ),
                      ],
                    ),

                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Divider(height: 1),
                    ),

                    SummaryRow(label: 'যাত্রীর নাম', value: widget.passengerName),
                    const SizedBox(height: 8),
                    SummaryRow(label: 'মোবাইল নম্বর', value: widget.phoneNumber),
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

                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Divider(height: 1),
                    ),

                    SummaryRow(
                      label: 'পরিশোধিত মূল্য',
                      value: '৳ ${widget.totalAmount}',
                      isTotal: true,
                    ),

                    const SizedBox(height: 24),

                    // TrxID Input Box
                    CustomTextField(
                      controller: _trxIdController,
                      labelText: 'ট্রানজেকশন আইডি (TrxID)',
                      hintText: 'উদাহরণ: 9J8A7B6C (এসএমএস থেকে লিখুন)',
                      prefixIcon: Icons.tag_rounded,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'অনুগ্রহ করে ট্রানজেকশন আইডি (TrxID) লিখুন';
                        }
                        if (value.trim().length < 6) {
                          return 'সঠিক ট্রানজেকশন আইডি প্রদান করুন';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _verifyPayment,
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
                            : const Text(
                                'পেমেন্ট নিশ্চিত করুন (Verify Payment)',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
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

  Widget _buildInstructionStep({
    required String stepNumber,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
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
                fontSize: 13.5,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14.5,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: const TextStyle(
                  fontSize: 12.5,
                  color: AppColors.textSecondary,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
