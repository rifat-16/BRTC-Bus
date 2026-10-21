import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../services/firestore_service.dart';

class AdminPaymentConfigCard extends StatelessWidget {
  final FirestoreService firestoreService;

  const AdminPaymentConfigCard({
    super.key,
    required this.firestoreService,
  });

  void _showEditBkashNumberDialog(BuildContext context, String currentNumber) {
    final TextEditingController numberController =
        TextEditingController(text: currentNumber);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFE2136E).withAlpha(20),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.phone_android_rounded,
                  color: Color(0xFFE2136E),
                  size: 22,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'bKash পার্সোনাল নম্বর পরিবর্তন',
                  style: TextStyle(
                    fontSize: 16.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'যাত্রীরা টিকিট কাটার সময় এই বিকাশ পার্সোনাল নম্বরে Send Money করবেন:',
                style: TextStyle(
                  fontSize: 12.5,
                  color: AppColors.textSecondary,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: numberController,
                keyboardType: TextInputType.phone,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                  letterSpacing: 1.0,
                ),
                decoration: InputDecoration(
                  labelText: 'bKash Personal Mobile Number',
                  prefixIcon: const Icon(Icons.phone_android_rounded),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                      color: Color(0xFFE2136E),
                      width: 2,
                    ),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('বাতিল'),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.check_circle_rounded, size: 18),
              label: const Text('নম্বর সেভ করুন'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () async {
                final String newNum = numberController.text.trim();
                if (newNum.isEmpty || newNum.length < 11) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('অনুগ্রহ করে সঠিক ১১ ডিজিটের মোবাইল নম্বর দিন'),
                      backgroundColor: AppColors.primaryRed,
                    ),
                  );
                  return;
                }

                final nav = Navigator.of(context);
                final messenger = ScaffoldMessenger.of(context);

                nav.pop();

                await firestoreService.updateBkashNumber(newNum);

                messenger.showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        const Icon(Icons.check_circle_rounded, color: Colors.white),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'bKash পার্সোনাল নম্বর সফলভাবে $newNum আপডেট করা হয়েছে!',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    backgroundColor: AppColors.primaryGreen,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<String>(
      stream: firestoreService.getPaymentConfigStream(),
      builder: (context, snapshot) {
        final String bkashNumber = snapshot.data ?? '01712345678';

        return Card(
          margin: const EdgeInsets.only(top: 20, bottom: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(
                color: const Color(0xFFE2136E).withAlpha(80), width: 1.5),
          ),
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE2136E).withAlpha(20),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.phone_android_rounded,
                            color: Color(0xFFE2136E),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'পেমেন্ট নম্বর সেটিংস (Payment Settings)',
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.edit_rounded, size: 15),
                      label: const Text('পরিবর্তন করুন',
                          style: TextStyle(fontSize: 11.5)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFE2136E),
                        side: const BorderSide(color: Color(0xFFE2136E)),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () =>
                          _showEditBkashNumberDialog(context, bkashNumber),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF0F5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'bKash পার্সোনাল নম্বর:',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        bkashNumber,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFFE2136E),
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
