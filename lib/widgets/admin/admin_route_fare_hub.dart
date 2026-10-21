import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../models/route_fare_model.dart';
import '../../services/firestore_service.dart';

class AdminRouteFareHub extends StatelessWidget {
  final FirestoreService firestoreService;

  const AdminRouteFareHub({
    super.key,
    required this.firestoreService,
  });

  void _showEditRouteFareDialog(BuildContext context, RouteFareModel route) {
    final TextEditingController fareController =
        TextEditingController(text: route.fare.toString());

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            void adjustFare(int delta) {
              final current = int.tryParse(fareController.text) ?? route.fare;
              final newVal = (current + delta).clamp(10, 2000);
              fareController.text = newVal.toString();
              setStateDialog(() {});
            }

            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryRed.withAlpha(20),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.price_change_rounded,
                      color: AppColors.primaryRed,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'রুটভিত্তিক ভাড়া পরিবর্তন',
                      style: TextStyle(
                        fontSize: 17,
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
                  Text(
                    'রুট: ${route.from} ➔ ${route.to}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: AppColors.primaryRed,
                    ),
                  ),
                  const SizedBox(height: 18),

                  const Text(
                    'নতুন ভাড়া নির্ধারণ করুন (৳):',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 8),

                  TextField(
                    controller: fareController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primaryGreen,
                    ),
                    decoration: InputDecoration(
                      prefixText: '৳ ',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(
                          color: AppColors.primaryGreen,
                          width: 2,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildQuickAdjustChip('-৫০', () => adjustFare(-50)),
                      _buildQuickAdjustChip('-১০', () => adjustFare(-10)),
                      _buildQuickAdjustChip('+১০', () => adjustFare(10)),
                      _buildQuickAdjustChip('+৫০', () => adjustFare(50)),
                    ],
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
                  label: const Text('ভাড়া সেভ করুন'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () async {
                    final int? newFare =
                        int.tryParse(fareController.text.trim());
                    if (newFare == null || newFare <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('অনুগ্রহ করে সঠিক ভাড়া ইনপুট দিন'),
                          backgroundColor: AppColors.primaryRed,
                        ),
                      );
                      return;
                    }

                    final nav = Navigator.of(context);
                    final messenger = ScaffoldMessenger.of(context);

                    nav.pop();

                    await firestoreService.updateRouteFare(
                      routeId: route.id,
                      newFare: newFare,
                    );

                    messenger.showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            const Icon(Icons.check_circle_rounded,
                                color: Colors.white),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '${route.from} ➔ ${route.to} এর নতুন ভাড়া ৳ $newFare সফলভাবে আপডেট করা হয়েছে!',
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
      },
    );
  }

  Widget _buildQuickAdjustChip(String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.backgroundColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'রুটভিত্তিক ভাড়া নিয়ন্ত্রণ মডিউল (Route Fare Hub)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.primaryGreen.withAlpha(20),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'LIVE SYNC',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryGreen,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        StreamBuilder<List<RouteFareModel>>(
          stream: firestoreService.getRouteFaresStream(),
          builder: (context, snapshot) {
            final routeFares =
                snapshot.data ?? FirestoreService.officialRouteFares;

            return Column(
              children: routeFares.map((route) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 1,
                  child: Padding(
                    padding: const EdgeInsets.all(14.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${route.from}  ➔  ${route.to}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: AppColors.primaryRed,
                                ),
                              ),
                              const SizedBox(height: 2),
                              const Text(
                                'স্টেশন-টু-স্টেশন সরাসরি ভাড়া',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primaryGreen.withAlpha(20),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '৳ ${route.fare}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.primaryGreen,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(
                                Icons.edit_note_rounded,
                                color: AppColors.primaryRed,
                                size: 24,
                              ),
                              tooltip: 'ভাড়া পরিবর্তন করুন',
                              onPressed: () =>
                                  _showEditRouteFareDialog(context, route),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }
}
