import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../core/app_colors.dart';
import '../providers/auth_provider.dart';
import '../widgets/desktop_web_navbar.dart';
import '../widgets/home/home_helpline_modal.dart';
import '../widgets/home/home_search_card.dart';
import '../widgets/home/home_shortcuts_section.dart';
import '../widgets/home/home_user_menu_modal.dart';
import '../widgets/responsive_layout.dart';
import 'my_tickets_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final List<String> _locations = [
    'ঢাকা',
    'সখিপুর',
    'বড়চওনা',
    'গারোবাজার',
    'সাগরদিঘী'
  ];

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

    _entranceController.forward(from: 0.0);
  }

  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: ResponsiveLayout.isDesktop(context)
          ? const DesktopWebNavbar()
          : null,
      body: ResponsiveLayout(
        mobile: _buildMobileLayout(authProvider),
        desktop: _buildDesktopLayout(authProvider),
      ),
    );
  }

  Widget _buildMobileLayout(AuthProvider authProvider) {
    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero Header Banner
            SlideTransition(
              position: _headerSlide,
              child: FadeTransition(
                opacity: _headerFade,
                child: Stack(
                  children: [
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

                    // Header Content
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                                        createSmoothPageRoute(
                                          const MyTicketsScreen(),
                                        ),
                                      );
                                    },
                                  ),
                                  const SizedBox(width: 6),
                                  GestureDetector(
                                    onTap: () =>
                                        HomeUserMenuModal.show(context),
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

            // Animated Floating Bus Search Card
            SlideTransition(
              position: _searchSlide,
              child: FadeTransition(
                opacity: _searchFade,
                child: HomeSearchCard(locations: _locations),
              ),
            ),

            const SizedBox(height: 28),

            // Quick Shortcuts Grid
            SlideTransition(
              position: _shortcutsSlide,
              child: FadeTransition(
                opacity: _shortcutsFade,
                child: const HomeShortcutsSection(),
              ),
            ),

            const SizedBox(height: 35),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopLayout(AuthProvider authProvider) {
    return SingleChildScrollView(
      child: ConstrainedWebContainer(
        padding: const EdgeInsets.all(28),
        child: Column(
          children: [
            // Welcome Web Banner with Bus Background Image (Animated)
            SlideTransition(
              position: _headerSlide,
              child: FadeTransition(
                opacity: _headerFade,
                child: Container(
                  width: double.infinity,
                  height: 300,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 18,
                        offset: Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: Stack(
                      children: [
                        // Cover Bus Photo Background
                        Positioned.fill(
                          child: Image.asset(
                            'assets/images/brtc_bus.jpg',
                            fit: BoxFit.cover,
                            alignment: Alignment.center,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: AppColors.primaryRedDark,
                              );
                            },
                          ),
                        ),
                        // Soft Red Vignette Overlay
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.primaryRedDark.withAlpha(140),
                                  Colors.transparent,
                                  AppColors.primaryRedDark.withAlpha(160),
                                ],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                            ),
                          ),
                        ),
                        // Banner Content
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 36,
                            vertical: 28,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'স্বাগতম, ${authProvider.displayName}!',
                                style: const TextStyle(
                                  fontSize: 34,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black54,
                                      blurRadius: 12,
                                      offset: Offset(0, 3),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 10),
                              const Text(
                                'সখিপুর-ঢাকা রুটে আপনার পছন্দের বিআরটিসি এসি বাসের সিট সিলেক্ট করে টিকিট কাটুন',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black45,
                                      blurRadius: 8,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 28),

            // 2-Column Split View Layout with Animated Entrance
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left Column: Interactive Search Card (Animated 42% Width)
                Expanded(
                  flex: 42,
                  child: SlideTransition(
                    position: _searchSlide,
                    child: FadeTransition(
                      opacity: _searchFade,
                      child: HomeSearchCard(locations: _locations),
                    ),
                  ),
                ),

                const SizedBox(width: 28),

                // Right Column: Executive Command Panel (Animated 58% Width)
                Expanded(
                  flex: 58,
                  child: SlideTransition(
                    position: _shortcutsSlide,
                    child: FadeTransition(
                      opacity: _shortcutsFade,
                      child: _buildDesktopRightColumn(context),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopRightColumn(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Executive Quick Cards Row (2 Cards)
        Row(
          children: [
            Expanded(
              child: _buildDesktopQuickCard(
                title: 'আমার টিকিটস',
                subtitle: 'ই-টিকিট দেখুন',
                icon: Icons.confirmation_number_rounded,
                color: AppColors.primaryRed,
                bgColor: AppColors.primaryRed.withAlpha(20),
                onTap: () {
                  Navigator.push(
                    context,
                    createSmoothPageRoute(const MyTicketsScreen()),
                  );
                },
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _buildDesktopQuickCard(
                title: 'সখিপুর হেল্পলাইন',
                subtitle: '01624-622614',
                icon: Icons.headset_mic_rounded,
                color: AppColors.primaryGreen,
                bgColor: AppColors.primaryGreen.withAlpha(20),
                onTap: () => HomeHelplineModal.show(context),
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),

        // 2. Daily 4 Trips Departure Schedule Live Board Card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: Colors.grey.shade300),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(8),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.departure_board_rounded,
                          color: AppColors.primaryRed, size: 22),
                      SizedBox(width: 8),
                      Text(
                        'দৈনিক ট্রিপ সময়সূচী (Schedule)',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primaryGreen.withAlpha(20),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      'DAILY AC SERVICE',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryGreen,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Divider(height: 1),
              const SizedBox(height: 14),
              _buildTripScheduleItem(
                time: '05:20 AM',
                route: 'বড়চওনা / সখিপুর ➔ ঢাকা',
                busName: 'BRTC AC Service - 1',
              ),
              const SizedBox(height: 10),
              _buildTripScheduleItem(
                time: '05:15 AM',
                route: 'গারোবাজার / সাগরদিঘী ➔ ঢাকা',
                busName: 'BRTC AC Service - 2',
              ),
              const SizedBox(height: 10),
              _buildTripScheduleItem(
                time: '03:30 PM',
                route: 'ঢাকা (সচিবালয়) ➔ সখিপুর / বড়চওনা',
                busName: 'BRTC AC Service - 2 (ফিরতী)',
              ),
              const SizedBox(height: 10),
              _buildTripScheduleItem(
                time: '06:00 PM',
                route: 'ঢাকা ➔ সখিপুর / সাগরদিঘী',
                busName: 'BRTC AC Service - 1 (ফিরতী)',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopQuickCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withAlpha(40)),
          boxShadow: [
            BoxShadow(
              color: color.withAlpha(10),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: bgColor,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: AppColors.textSecondary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTripScheduleItem({
    required String time,
    required String route,
    required String busName,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.backgroundColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryRed.withAlpha(20),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  time,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: AppColors.primaryRed,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    route,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    busName,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const Icon(
            Icons.chevron_right_rounded,
            size: 18,
            color: AppColors.textMuted,
          ),
        ],
      ),
    );
  }
}
