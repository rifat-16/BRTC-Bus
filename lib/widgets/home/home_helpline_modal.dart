import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/app_colors.dart';

class HomeHelplineModal {
  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.headset_mic_rounded,
                    color: Colors.orange.shade800, size: 30),
              ),
              const SizedBox(height: 14),
              const Text(
                'BRTC Helpline & Support',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              const Text(
                'টিকিট বুকিং ও তথ্যের জন্য সরাসরি কল করতে নম্বরে চাপ দিন:',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 16),

              // Booking Time Notice Banner
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen.withAlpha(15),
                  borderRadius: BorderRadius.circular(12),
                  border:
                      Border.all(color: AppColors.primaryGreen.withAlpha(40)),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.access_time_filled_rounded,
                        size: 16, color: AppColors.primaryGreen),
                    SizedBox(width: 8),
                    Text(
                      'টিকিট বুকিং: সকাল ৮:০০ টা থেকে রাত ১০:০০ টা পর্যন্ত',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryGreen,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              _buildPhoneCallTile(
                context,
                title: 'বিআরটিসি বুকিং নম্বর - ১',
                phoneNumber: '01753-183383',
                rawNumber: '01753183383',
              ),

              const SizedBox(height: 10),

              _buildPhoneCallTile(
                context,
                title: 'বিআরটিসি বুকিং নম্বর - ২',
                phoneNumber: '01686-336475',
                rawNumber: '01686336475',
              ),

              const SizedBox(height: 10),

              _buildPhoneCallTile(
                context,
                title: 'বিআরটিসি কেন্দ্রীয় হটলাইন',
                phoneNumber: '১৬১০৭ / ০১৯১১-১২২৩৩৩',
                rawNumber: '16107',
                isCentral: true,
              ),

              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  static void _makePhoneCall(BuildContext context, String phoneNumber) async {
    final Uri url = Uri(scheme: 'tel', path: phoneNumber);
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url);
      } else {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('কল করতে সমস্যা হয়েছে: $phoneNumber'),
            backgroundColor: AppColors.primaryRed,
          ),
        );
      }
    }
  }

  static Widget _buildPhoneCallTile(
    BuildContext context, {
    required String title,
    required String phoneNumber,
    required String rawNumber,
    bool isCentral = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.pop(context);
          _makePhoneCall(context, rawNumber);
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isCentral ? Colors.red.shade50 : AppColors.backgroundColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isCentral
                  ? AppColors.primaryRed.withAlpha(50)
                  : Colors.grey.shade300,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isCentral
                      ? AppColors.primaryRed.withAlpha(20)
                      : AppColors.primaryGreen.withAlpha(20),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.phone_forwarded_rounded,
                  color:
                      isCentral ? AppColors.primaryRed : AppColors.primaryGreen,
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      phoneNumber,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: isCentral
                            ? AppColors.primaryRed
                            : AppColors.textPrimary,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color:
                      isCentral ? AppColors.primaryRed : AppColors.primaryGreen,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.call, size: 14, color: Colors.white),
                    SizedBox(width: 4),
                    Text(
                      'কল করুন',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
