import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/app_colors.dart';
import 'custom_text_field.dart';

class ManualPaymentVerificationCard extends StatelessWidget {
  final String selectedMethod;
  final String paymentNumber;
  final int totalAmount;
  final TextEditingController trxIdController;

  const ManualPaymentVerificationCard({
    super.key,
    required this.selectedMethod,
    required this.paymentNumber,
    required this.totalAmount,
    required this.trxIdController,
  });

  @override
  Widget build(BuildContext context) {
    final methodUpper = selectedMethod.toUpperCase();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.primaryGreen.withAlpha(60)),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Badge
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen.withAlpha(20),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.payments_rounded,
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
                      fontSize: 16.5,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'নিচের ধাপগুলো অনুসরণ করে মূল্য পরিশোধ করুন',
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
            padding: EdgeInsets.symmetric(vertical: 16.0),
            child: Divider(height: 1),
          ),

          // Step 1: Copy Payment Number Card
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
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'ধাপ ১: BKASH পার্সোনাল নম্বর',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange.shade900,
                      ),
                    ),
                    Text(
                      'মোট ৳ $totalAmount',
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
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.phone_android_rounded,
                                size: 18, color: Colors.grey),
                            const SizedBox(width: 10),
                            Text(
                              paymentNumber,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.0,
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
                        Clipboard.setData(ClipboardData(text: paymentNumber));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                                '$methodUpper নম্বরটি ($paymentNumber) কপি করা হয়েছে!'),
                            backgroundColor: AppColors.primaryGreen,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.copy_rounded, size: 16),
                      label: const Text('কপি করুন'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryGreen,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          // Step 2 & 3: Bengali Guidelines
          _buildInstructionStep(
            stepNumber: '২',
            title: 'Send Money করুন',
            description:
                'আপনার $methodUpper অ্যাপ বা ডায়াল করে Send Money অপশনে যান এবং ওপরের নম্বরটিতে ঠিক ৳ $totalAmount টাকা পাঠান।',
          ),
          const SizedBox(height: 12),
          _buildInstructionStep(
            stepNumber: '৩',
            title: 'TrxID টি এখানে লিখুন',
            description:
                'টাকা পাঠানোর পর বিকাশ/নগদ থেকে আসা কনফার্মেশন এসএমএস (SMS) এ একটি TrxID পাবেন। সেটি কপি করে নিচের বক্সে লিখুন।',
          ),

          const SizedBox(height: 22),

          // TrxID Input Box
          CustomTextField(
            controller: trxIdController,
            labelText: 'ট্রানজেকশন আইডি (TrxID)',
            hintText: 'উদাহরণ: 9J8A7B6C (এসএমএস থেকে TrxID লিখুন)',
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
        ],
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
          width: 26,
          height: 26,
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
                fontSize: 13,
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
                  fontSize: 14,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 3),
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
