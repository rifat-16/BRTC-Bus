import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/app_colors.dart';
import '../providers/auth_provider.dart';
import '../providers/booking_provider.dart';
import '../widgets/custom_dropdown.dart';
import 'bus_list_screen.dart';
import 'login_screen.dart';
import 'my_tickets_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with TickerProviderStateMixin {
  final List<String> locations = [
    'ঢাকা',
    'সখিপুর',
    'বড়চওনা',
    'গারোবাজার',
    'সাগরদিঘী'
  ];

  late AnimationController _swapAnimController;
  late Animation<double> _swapAnimation;

  late AnimationController _entranceController;
  late Animation<double> _headerFade;
  late Animation<Offset> _headerSlide;
  late Animation<double> _searchFade;
  late Animation<Offset> _searchSlide;
  late Animation<double> _shortcutsFade;
  late Animation<Offset> _shortcutsSlide;

  @override
  void initState() {
    super.initState();

    // Swap Location Animation
    _swapAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _swapAnimation = Tween<double>(begin: 0, end: math.pi).animate(
      CurvedAnimation(
        parent: _swapAnimController,
        curve: Curves.easeInOutCubic,
      ),
    );

    // Staggered Entrance Animation
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );

    _headerFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.0, 0.45, curve: Curves.easeOut),
      ),
    );

    _headerSlide = Tween<Offset>(
      begin: const Offset(0, -0.15),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOutCubic),
      ),
    );

    _searchFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.2, 0.65, curve: Curves.easeOut),
      ),
    );

    _searchSlide = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.2, 0.7, curve: Curves.easeOutBack),
      ),
    );

    _shortcutsFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.4, 0.85, curve: Curves.easeOut),
      ),
    );

    _shortcutsSlide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.4, 0.85, curve: Curves.easeOutCubic),
      ),
    );

    _entranceController.forward();
  }

  @override
  void dispose() {
    _swapAnimController.dispose();
    _entranceController.dispose();
    super.dispose();
  }

  void swapLocations(BookingProvider bookingProvider) {
    _swapAnimController.forward(from: 0);
    final tempFrom = bookingProvider.selectedFrom;
    final tempTo = bookingProvider.selectedTo;
    bookingProvider.updateRouteFilter(tempTo, tempFrom);
  }

  Future<void> _selectDate(BuildContext context, BookingProvider bookingProvider) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: bookingProvider.journeyDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primaryRed,
              onPrimary: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      bookingProvider.updateJourneyDate(picked);
    }
  }

  void _showUserMenu(BuildContext context) {
    final authProvider = context.read<AuthProvider>();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 28.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!authProvider.isGuestMode && authProvider.user != null) ...[
                CircleAvatar(
                  radius: 38,
                  backgroundColor: AppColors.primaryRed.withAlpha(20),
                  backgroundImage: authProvider.user?.photoURL != null
                      ? NetworkImage(authProvider.user!.photoURL!)
                      : null,
                  onBackgroundImageError: authProvider.user?.photoURL != null
                      ? (_, __) {}
                      : null,
                  child: authProvider.user?.photoURL == null
                      ? const Icon(Icons.person, size: 38, color: AppColors.primaryRed)
                      : null,
                ),
                const SizedBox(height: 12),
                Text(
                  authProvider.displayName,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  authProvider.email,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 20),
                const Divider(),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryGreen.withAlpha(25),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.confirmation_number_rounded,
                        color: AppColors.primaryGreen),
                  ),
                  title: const Text('My Tickets', style: TextStyle(fontWeight: FontWeight.bold)),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const MyTicketsScreen(),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryRed.withAlpha(25),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.logout_rounded, color: AppColors.primaryRed),
                  ),
                  title: const Text('Sign Out', style: TextStyle(fontWeight: FontWeight.bold)),
                  onTap: () async {
                    final nav = Navigator.of(context);
                    nav.pop();
                    await authProvider.signOut();
                    if (mounted) {
                      nav.pushAndRemoveUntil(
                        MaterialPageRoute(
                          builder: (context) => const LoginScreen(),
                        ),
                        (route) => false,
                      );
                    }
                  },
                ),
              ] else ...[
                const CircleAvatar(
                  radius: 38,
                  backgroundColor: AppColors.backgroundColor,
                  child: Icon(Icons.person_rounded, size: 38, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Guest Passenger',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (context) => const LoginScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.login_rounded),
                  label: const Text('Sign In with Google'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    minimumSize: const Size(double.infinity, 50),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  void _makePhoneCall(String phoneNumber) async {
    final Uri url = Uri(scheme: 'tel', path: phoneNumber);
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url);
      } else {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('কল করতে সমস্যা হয়েছে: $phoneNumber'),
            backgroundColor: AppColors.primaryRed,
          ),
        );
      }
    }
  }

  void _showHelplineModal(BuildContext context) {
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
                title: 'বিআরটিসি বুকিং নম্বর - ১',
                phoneNumber: '01753-183383',
                rawNumber: '01753183383',
              ),

              const SizedBox(height: 10),

              _buildPhoneCallTile(
                title: 'বিআরটিসি বুকিং নম্বর - ২',
                phoneNumber: '01686-336475',
                rawNumber: '01686336475',
              ),

              const SizedBox(height: 10),

              _buildPhoneCallTile(
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

  Widget _buildPhoneCallTile({
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
          _makePhoneCall(rawNumber);
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

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final bookingProvider = context.watch<BookingProvider>();

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hero Header with BRTC Bus Image Background
              SlideTransition(
                position: _headerSlide,
                child: FadeTransition(
                  opacity: _headerFade,
                  child: Stack(
                    children: [
                      // Background Photo & Gradient
                      Positioned.fill(
                        child: Container(
                          decoration: const BoxDecoration(
                            borderRadius: BorderRadius.only(
                              bottomLeft: Radius.circular(36),
                              bottomRight: Radius.circular(36),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 18,
                                offset: Offset(0, 8),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(36),
                              bottomRight: Radius.circular(36),
                            ),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                Image.asset(
                                  'assets/images/brtc_bus.jpg',
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      color: AppColors.primaryRedDark,
                                    );
                                  },
                                ),
                                Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        AppColors.primaryRedDark.withAlpha(140),
                                        AppColors.primaryRed.withAlpha(100),
                                        AppColors.primaryRedDark.withAlpha(165),
                                      ],
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // Header Foreground Content
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
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
                                        color: Colors.white.withAlpha(35),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.white.withAlpha(50),
                                        ),
                                      ),
                                      child: const Icon(
                                        Icons.directions_bus_filled_rounded,
                                        color: Colors.white,
                                        size: 26,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    const Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'BRTC Ticket',
                                          style: TextStyle(
                                            fontSize: 22,
                                            fontWeight: FontWeight.w900,
                                            color: Colors.white,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                        Text(
                                          'E-Ticketing Portal',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.white70,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    IconButton(
                                      icon: Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withAlpha(30),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.confirmation_number_outlined,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                      ),
                                      tooltip: 'My Tickets',
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                const MyTicketsScreen(),
                                          ),
                                        );
                                      },
                                    ),
                                    const SizedBox(width: 6),
                                    GestureDetector(
                                      onTap: () => _showUserMenu(context),
                                      child: Stack(
                                        children: [
                                          CircleAvatar(
                                            radius: 20,
                                            backgroundColor:
                                                Colors.white.withAlpha(50),
                                            backgroundImage:
                                                authProvider.user?.photoURL != null
                                                    ? NetworkImage(
                                                        authProvider.user!.photoURL!)
                                                    : null,
                                            onBackgroundImageError:
                                                authProvider.user?.photoURL != null
                                                    ? (_, __) {}
                                                    : null,
                                            child: authProvider.user?.photoURL == null
                                                ? const Icon(Icons.person_rounded,
                                                    color: Colors.white)
                                                : null,
                                          ),
                                          Positioned(
                                            right: 0,
                                            bottom: 0,
                                            child: Container(
                                              width: 11,
                                              height: 11,
                                              decoration: BoxDecoration(
                                                color: AppColors.accentGold,
                                                shape: BoxShape.circle,
                                                border: Border.all(
                                                  color: AppColors.primaryRedDark,
                                                  width: 1.5,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),

                            const SizedBox(height: 22),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'স্বাগতম, ${authProvider.displayName}!',
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    const Text(
                                      'কোথায় যেতে চান আজ?',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.white70,
                                      ),
                                    ),
                                  ],
                                ),

                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withAlpha(25),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.white.withAlpha(40),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.today_rounded,
                                        size: 14,
                                        color: AppColors.accentGold,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        DateFormat('dd MMM').format(DateTime.now()),
                                        style: const TextStyle(
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
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Animated Floating Search Card
              SlideTransition(
                position: _searchSlide,
                child: FadeTransition(
                  opacity: _searchFade,
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(14),
                          blurRadius: 22,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // From Dropdown
                        CustomDropdown(
                          label: 'কোথা থেকে (From)',
                          value: bookingProvider.selectedFrom,
                          items: locations,
                          onChanged: (newValue) {
                            if (newValue != null) {
                              bookingProvider.updateRouteFilter(
                                  newValue, bookingProvider.selectedTo);
                            }
                          },
                        ),

                        // Divider with Swap Icon
                        Stack(
                          alignment: Alignment.centerRight,
                          clipBehavior: Clip.none,
                          children: [
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 12.0),
                              child: Divider(height: 1),
                            ),
                            Positioned(
                              right: 0,
                              child: GestureDetector(
                                onTap: () => swapLocations(bookingProvider),
                                child: AnimatedBuilder(
                                  animation: _swapAnimation,
                                  builder: (context, child) {
                                    return Transform.rotate(
                                      angle: _swapAnimation.value,
                                      child: Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: AppColors.primaryGreen,
                                            width: 1.5,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: AppColors.primaryGreen
                                                  .withAlpha(35),
                                              blurRadius: 8,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: const Icon(
                                          Icons.swap_vert_rounded,
                                          color: AppColors.primaryGreen,
                                          size: 22,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),

                        // To Dropdown
                        CustomDropdown(
                          label: 'কোথায় যাবেন (To)',
                          value: bookingProvider.selectedTo,
                          items: locations,
                          onChanged: (newValue) {
                            if (newValue != null) {
                              bookingProvider.updateRouteFilter(
                                  bookingProvider.selectedFrom, newValue);
                            }
                          },
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12.0),
                          child: Divider(height: 1),
                        ),

                        // Date Picker Tile
                        GestureDetector(
                          onTap: () => _selectDate(context, bookingProvider),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.backgroundColor,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryRed.withAlpha(20),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.calendar_month_rounded,
                                    color: AppColors.primaryRed,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'যাত্রার তারিখ (Date)',
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      DateFormat('dd MMM yyyy, EEEE')
                                          .format(bookingProvider.journeyDate),
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Search Button
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.search_rounded, size: 22),
                            label: const Text(
                              'বাস খুঁজুন (Search Buses)',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryGreen,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 3,
                              shadowColor: AppColors.primaryGreen.withAlpha(80),
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => BusListScreen(
                                    from: bookingProvider.selectedFrom,
                                    to: bookingProvider.selectedTo,
                                    date: DateFormat('dd MMM yyyy')
                                        .format(bookingProvider.journeyDate),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 28),

              // Quick Features Shortcuts Grid
              SlideTransition(
                position: _shortcutsSlide,
                child: FadeTransition(
                  opacity: _shortcutsFade,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildShortcutItem(
                          icon: Icons.confirmation_number_rounded,
                          label: 'My Tickets',
                          color: AppColors.primaryRed,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const MyTicketsScreen(),
                              ),
                            );
                          },
                        ),
                        _buildShortcutItem(
                          icon: Icons.schedule_rounded,
                          label: 'Schedule',
                          color: Colors.blue.shade700,
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                    'প্রতিদিন সকাল ৬:০০ টা থেকে রাত ১০:০০ টা পর্যন্ত গাড়ি চলাচল করে'),
                              ),
                            );
                          },
                        ),
                        _buildShortcutItem(
                          icon: Icons.headset_mic_rounded,
                          label: 'Helpline',
                          color: Colors.orange.shade800,
                          onTap: () => _showHelplineModal(context),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 35),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShortcutItem({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withAlpha(35)),
              boxShadow: [
                BoxShadow(
                  color: color.withAlpha(15),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
