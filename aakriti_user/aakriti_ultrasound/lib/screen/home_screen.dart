import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/clinic_actions_helper.dart';
import '../services/notification_service.dart';
import '../services/notifications_store.dart';
import '../services/profile_service.dart';

import 'profile_screen.dart';
import 'notifications_screen.dart';
import 'health_packages_screen.dart';
import 'blood_tests_screen.dart';
import 'sugar_tests_screen.dart';
import 'thyroid_screen.dart';
import 'my_appoinments_screen.dart';
import 'services_screen.dart';
import 'reports_screen.dart';
import 'appointment_screen.dart';
import 'doctors_screen.dart';
import 'payments_screen.dart';
import 'support_screen.dart';
import '../widgets/whatsapp_logo.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int selectedIndex = 0;

  // ============================================================
  // COLORS
  // ============================================================

  static const Color navy = Color(0xFF071A2B);

  static const Color navy2 = Color(0xFF0D304A);

  static const Color blue = Color(0xFF1677FF);

  static const Color blueDark = Color(0xFF0C5ED7);

  static const Color teal = Color(0xFF18C8C8);

  // ============================================================
  // FIREBASE & SESSION USER
  // ============================================================

  User? get currentUser => FirebaseAuth.instance.currentUser;

  String? _sessionUserName;
  String? _sessionUserEmail;

  String get userName {
    final profileName = ProfileService.userNameNotifier.value.trim();
    if (profileName.isNotEmpty &&
        profileName != 'there' &&
        profileName != 'Patient' &&
        profileName != 'User') {
      return profileName;
    }

    final name = currentUser?.displayName?.trim();
    if (name != null && name.isNotEmpty) {
      return name;
    }

    if (_sessionUserName != null &&
        _sessionUserName!.trim().isNotEmpty &&
        _sessionUserName != 'Patient' &&
        _sessionUserName != 'User') {
      return _sessionUserName!.trim();
    }

    final email = currentUser?.email ?? _sessionUserEmail ?? ProfileService.userEmailNotifier.value;
    if (email.isNotEmpty && email.contains('@')) {
      final part = email.split('@').first;
      if (part.isNotEmpty) {
        return part[0].toUpperCase() + part.substring(1);
      }
    }

    return "User";
  }

  String get firstName {
    final name = userName.trim();
    if (name.isEmpty || name == "there") {
      return "User";
    }
    return name.split(' ').first;
  }

  String get userEmail {
    return currentUser?.email ?? _sessionUserEmail ?? "";
  }

  String? get profilePhoto {
    final photo = currentUser?.photoURL?.trim();

    if (photo != null && photo.isNotEmpty) {
      return photo;
    }

    return null;
  }

  String get userInitials {
    final name = userName.trim();

    if (name.isEmpty || name == "there") {
      return "U";
    }

    final parts = name.split(RegExp(r'\s+'));

    if (parts.length >= 2) {
      return "${parts.first[0]}${parts.last[0]}".toUpperCase();
    }

    return parts.first[0].toUpperCase();
  }

  Timer? _bannerTimer;
  Map<String, dynamic>? _clinicStatus;

  bool get _isClinicOpenNow {
    if (_clinicStatus != null && _clinicStatus!['is_open'] != null) {
      return _clinicStatus!['is_open'] == true;
    }
    final hour = DateTime.now().hour;
    return hour >= 10 && hour < 16;
  }

  String get _clinicStatusText {
    return _isClinicOpenNow ? "OPEN NOW" : "CLOSED";
  }

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    ProfileService.init();
    ProfileService.userNameNotifier.addListener(_onProfileChanged);
    NotificationStore.instance.loadRealNotifications();
    NotificationService.startRealtimeSync();
    NotificationStore.instance.realTimeBannerNotifier
        .addListener(_onRealtimeNotification);
    _loadSessionInfo();
    _loadClinicStatus();
  }

  Future<void> _loadClinicStatus() async {
    final status = await ApiService.getClinicStatus();
    if (mounted) {
      setState(() {
        _clinicStatus = status;
      });
    }
  }


  @override
  void dispose() {
    ProfileService.userNameNotifier.removeListener(_onProfileChanged);
    NotificationStore.instance.realTimeBannerNotifier
        .removeListener(_onRealtimeNotification);
    _bannerTimer?.cancel();
    super.dispose();
  }

  void _onProfileChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _onRealtimeNotification() {
    if (NotificationStore.instance.realTimeBannerNotifier.value != null &&
        mounted) {
      _bannerTimer?.cancel();
      _bannerTimer = Timer(const Duration(seconds: 5), () {
        NotificationStore.instance.dismissBanner();
      });
      setState(() {});
    }
  }

  Future<void> _loadSessionInfo() async {
    final name = await AuthService.getUserName();
    final email = await AuthService.getUserEmail();
    if (mounted) {
      setState(() {
        _sessionUserName = name;
        _sessionUserEmail = email;
      });
    }
  }

  // ============================================================
  // THEME COLORS
  // ============================================================

  Color get backgroundColor => Theme.of(context).scaffoldBackgroundColor;

  Color get cardColor => Theme.of(context).cardColor;

  Color get primaryText =>
      Theme.of(context).brightness == Brightness.dark ? Colors.white : navy;

  Color get secondaryText => Theme.of(context).brightness == Brightness.dark
      ? Colors.white70
      : Colors.grey.shade600;

  Color get borderColor => Theme.of(context).brightness == Brightness.dark
      ? Colors.white.withValues(alpha: 0.08)
      : Colors.grey.withValues(alpha: 0.12);

  // ============================================================
  // NAVIGATION
  // ============================================================

  Widget _getSelectedPage() {
    switch (selectedIndex) {
      case 0:
        return _homePage();

      case 1:
        return const MyAppointmentsScreen();

      case 2:
        return const DoctorsScreen(isEmbedded: true);

      case 3:
        return const ProfileScreen();

      default:
        return _homePage();
    }
  }

  // ============================================================
  // NOTIFICATIONS
  // ============================================================

  void _openNotifications() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const NotificationsScreen()),
    ).then((_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  // ============================================================
  // PROFILE
  // ============================================================

  void _openProfile() {
    setState(() {
      selectedIndex = 3;
    });
  }

  // ============================================================
  // APPOINTMENT
  // ============================================================

  void _openAppointment() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AppointmentScreen()),
    ).then((_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,

      body: Stack(
        children: [
          _getSelectedPage(),
          _buildLiveNotificationBanner(),
        ],
      ),

      // ========================================================
      // BOTTOM NAVIGATION
      // ========================================================
      bottomNavigationBar: NavigationBar(
        height: 74,

        selectedIndex: selectedIndex,

        onDestinationSelected: (index) {
          setState(() {
            selectedIndex = index;
          });
        },

        backgroundColor: cardColor,

        indicatorColor: blue.withValues(alpha: 0.12),

        elevation: 10,

        destinations: [
          NavigationDestination(
            icon: Icon(Icons.home_outlined, color: secondaryText),
            selectedIcon: const Icon(Icons.home_rounded, color: blue),
            label: "Home",
          ),

          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined, color: secondaryText),
            selectedIcon: const Icon(Icons.calendar_month_rounded, color: blue),
            label: "Appointments",
          ),

          NavigationDestination(
            icon: Icon(Icons.badge_outlined, color: secondaryText),
            selectedIcon: const Icon(Icons.badge_rounded, color: blue),
            label: "Doctors",
          ),

          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded, color: secondaryText),
            selectedIcon: const Icon(Icons.person_rounded, color: blue),
            label: "Profile",
          ),
        ],
      ),
    );
  }

  // ============================================================
  // LIVE FLOATING NOTIFICATION BANNER
  // ============================================================

  Widget _buildLiveNotificationBanner() {
    return ValueListenableBuilder<Map<String, dynamic>?>(
      valueListenable: NotificationStore.instance.realTimeBannerNotifier,
      builder: (context, notification, _) {
        if (notification == null) return const SizedBox.shrink();

        final title = (notification['title'] ?? 'Notification').toString();
        final message = (notification['message'] ?? '').toString();
        final icon = (notification['icon'] as IconData?) ??
            Icons.notifications_active_rounded;
        final color = (notification['color'] as Color?) ?? blue;

        return Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Material(
                elevation: 16,
                borderRadius: BorderRadius.circular(20),
                shadowColor: Colors.black.withValues(alpha: 0.5),
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    NotificationStore.instance.dismissBanner();
                    _openNotifications();
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 13),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF071A2B), Color(0xFF0D304A)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: color.withValues(alpha: 0.55),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: color.withValues(alpha: 0.25),
                          blurRadius: 16,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.18),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: color.withValues(alpha: 0.4),
                            ),
                          ),
                          child: Icon(icon, color: color, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 7, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.redAccent,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Text(
                                      "LIVE",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 8.5,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              if (message.isNotEmpty) ...[
                                const SizedBox(height: 3),
                                Text(
                                  message,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.8),
                                    fontSize: 12,
                                    height: 1.25,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.close_rounded,
                              color: Colors.white60, size: 19),
                          onPressed: () {
                            NotificationStore.instance.dismissBanner();
                          },
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                              minWidth: 28, minHeight: 28),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // HOME PAGE
  // ============================================================

  Widget _homePage() {
    return SafeArea(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            // ==================================================
            // PREMIUM HEADER
            // ==================================================

            Container(
              width: double.infinity,

              padding: const EdgeInsets.fromLTRB(20, 14, 20, 26),

              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [navy, Color(0xFF0B3150), Color(0xFF123D61)],
                ),

                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),

                boxShadow: [
                  BoxShadow(
                    color: navy.withValues(alpha: 0.20),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),

              child: Column(
                children: [
                  // ==========================================
                  // TOP BAR
                  // ==========================================

                  Row(
                    children: [
                      // ========================================
                      // AAKRITI LOGO
                      // ========================================

                      GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedIndex = 0;
                          });
                        },

                        child: Container(
                          height: 58,
                          width: 58,

                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(17),

                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.20),
                                blurRadius: 12,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),

                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(17),

                            child: Image.asset(
                              'assets/image.png',
                              fit: BoxFit.cover,

                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  decoration: const BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [blue, teal],
                                    ),
                                  ),

                                  child: const Icon(
                                    Icons.monitor_heart_rounded,
                                    color: Colors.white,
                                    size: 30,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 12),

                      // ========================================
                      // BRAND
                      // ========================================
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,

                          children: [
                            const Text(
                              "AAKRITI",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.5,
                              ),
                            ),

                            const SizedBox(height: 2),

                            Text(
                              "ULTRASOUND & DIAGNOSTICS",
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.68),
                                fontSize: 8.5,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // ========================================
                      // NOTIFICATION
                      // ========================================
                      AnimatedBuilder(
                        animation: NotificationStore.instance,
                        builder: (context, _) {
                          final count = NotificationStore.instance.unreadCount;
                          return _headerIconButton(
                            icon: count > 0
                                ? Icons.notifications_active_rounded
                                : Icons.notifications_none_rounded,
                            onTap: _openNotifications,
                            badgeCount: count,
                          );
                        },
                      ),

                      const SizedBox(width: 9),

                      // ========================================
                      // USER PROFILE PHOTO
                      // ========================================
                      GestureDetector(
                        onTap: _openProfile,

                        child: Container(
                          height: 46,
                          width: 46,

                          padding: const EdgeInsets.all(2),

                          decoration: BoxDecoration(
                            shape: BoxShape.circle,

                            color: Colors.white,

                            boxShadow: [
                              BoxShadow(
                                color: teal.withValues(alpha: 0.28),
                                blurRadius: 12,
                              ),
                            ],
                          ),

                          child: _profileAvatar(),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // ==========================================
                  // GREETING
                  // ==========================================
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,

                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,

                          children: [
                            Text(
                              "Good ${_getGreeting()},",
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),

                            const SizedBox(height: 3),

                            Text(
                              "$firstName 👋",
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 25,
                                fontWeight: FontWeight.w800,
                              ),
                            ),

                            const SizedBox(height: 5),

                            const Text(
                              "Your health, our priority.",
                              style: TextStyle(
                                color: Colors.white60,
                                fontSize: 12.5,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Small verified badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 7,
                        ),

                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.09),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.10),
                          ),
                        ),

                        child: const Row(
                          children: [
                            Icon(Icons.verified_rounded, color: teal, size: 15),
                            SizedBox(width: 5),
                            Text(
                              "Verified Care",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
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

            const SizedBox(height: 20),

            // ==================================================
            // SEARCH
            // ==================================================
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),

              child: Container(
                height: 56,

                padding: const EdgeInsets.symmetric(horizontal: 16),

                decoration: BoxDecoration(
                  color: cardColor,

                  borderRadius: BorderRadius.circular(18),

                  border: Border.all(color: borderColor),

                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: Theme.of(context).brightness == Brightness.dark
                            ? 0.16
                            : 0.045,
                      ),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),

                child: TextField(
                  textAlignVertical: TextAlignVertical.center,
                  style: TextStyle(color: primaryText, fontSize: 13.5),
                  onSubmitted: (_) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ServicesScreen(),
                      ),
                    );
                  },
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    prefixIcon: const Icon(Icons.search_rounded, color: blue, size: 22),
                    hintText: "Search tests, scans or services",
                    hintStyle: TextStyle(color: secondaryText, fontSize: 13),
                    border: InputBorder.none,
                    suffixIcon: IconButton(
                      icon: const Icon(
                        Icons.arrow_forward_rounded,
                        color: blue,
                        size: 20,
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ServicesScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 18),

            // ==================================================
            // LIVE CLINIC QUEUE & OPERATIONAL STATUS BANNER
            // ==================================================
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                height: 56,
                padding: const EdgeInsets.symmetric(horizontal: 18),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: borderColor),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: Theme.of(context).brightness == Brightness.dark
                            ? 0.16
                            : 0.045,
                      ),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Status Badge (Open / Closed)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: _isClinicOpenNow
                                ? const Color(0xFF10B981)
                                : const Color(0xFFEF4444),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: (_isClinicOpenNow
                                        ? const Color(0xFF10B981)
                                        : const Color(0xFFEF4444))
                                    .withValues(alpha: 0.5),
                                blurRadius: 6,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 9),
                        Text(
                          _clinicStatusText,
                          style: TextStyle(
                            color: _isClinicOpenNow
                                ? const Color(0xFF10B981)
                                : const Color(0xFFEF4444),
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ],
                    ),

                    // Timing Display with Schedule Icon
                    Flexible(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Icon(
                            Icons.schedule_rounded,
                            size: 15,
                            color: secondaryText,
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              _clinicStatus?['timing_text'] ?? "10:00 AM - 04:00 PM",
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: secondaryText,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.2,
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

            const SizedBox(height: 16),

            // ==================================================
            // 1-TAP QUICK ACTIONS (Rx, WhatsApp, Map, Call)
            // ==================================================
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const MyAppointmentsScreen(),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: borderColor),
                        ),
                        child: const Column(
                          children: [
                            Icon(Icons.track_changes_rounded, color: Color(0xFF1677FF), size: 22),
                            SizedBox(height: 5),
                            Text(
                              "Track Appt",
                              style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => WhatsAppHelper.openChat(
                        message: "Hello Aakriti Diagnostic Centre, I need assistance with test booking & reports.",
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: borderColor),
                        ),
                        child: const Column(
                          children: [
                            WhatsAppLogo(size: 22),
                            SizedBox(height: 5),
                            Text(
                              "WhatsApp",
                              style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => MapHelper.openClinicDirections(),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: borderColor),
                        ),
                        child: const Column(
                          children: [
                            Icon(Icons.directions_rounded, color: Color(0xFFEF4444), size: 22),
                            SizedBox(height: 5),
                            Text(
                              "Directions",
                              style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => CallHelper.callHelpline(),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: borderColor),
                        ),
                        child: const Column(
                          children: [
                            Icon(Icons.phone_in_talk_rounded, color: Color(0xFF10B981), size: 22),
                            SizedBox(height: 5),
                            Text(
                              "Helpline",
                              style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ==================================================
            // APPOINTMENT BANNER
            // ==================================================

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),

              child: GestureDetector(
                onTap: _openAppointment,

                child: Container(
                  padding: const EdgeInsets.all(22),

                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [blueDark, blue, teal],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),

                    borderRadius: BorderRadius.circular(25),

                    boxShadow: [
                      BoxShadow(
                        color: blue.withValues(alpha: 0.25),
                        blurRadius: 20,
                        offset: const Offset(0, 9),
                      ),
                    ],
                  ),

                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,

                          children: [
                            const Text(
                              "Need a Checkup?",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                              ),
                            ),

                            const SizedBox(height: 7),

                            const Text(
                              "Book your diagnostic appointment\n"
                              "in just a few taps.",
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                                height: 1.4,
                              ),
                            ),

                            const SizedBox(height: 15),

                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 9,
                              ),

                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.16),
                                borderRadius: BorderRadius.circular(12),
                              ),

                              child: const Row(
                                mainAxisSize: MainAxisSize.min,

                                children: [
                                  Text(
                                    "Book Appointment",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),

                                  SizedBox(width: 7),

                                  Icon(
                                    Icons.arrow_forward_rounded,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 10),

                      Container(
                        height: 76,
                        width: 76,

                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.15),
                          ),
                        ),

                        child: const Icon(
                          Icons.calendar_month_rounded,
                          size: 38,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 30),

            // ==================================================
            // QUICK ACCESS
            // ==================================================
            _sectionTitle("Quick Access"),

            const SizedBox(height: 13),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _quickCard(
                          "Book Scan",
                          Icons.calendar_month_rounded,
                          blue,
                          _openAppointment,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _quickCard(
                          "My Reports",
                          Icons.description_rounded,
                          teal,
                          () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const ReportsScreen(),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _quickCard(
                          "Doctors",
                          Icons.medical_information_rounded,
                          const Color(0xFF7C4DFF),
                          () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const DoctorsScreen(),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _quickCard(
                          "Bills & Pay",
                          Icons.receipt_long_rounded,
                          const Color(0xFF10B981),
                          () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const PaymentsScreen(),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _quickCard(
                          "24/7 Helpline",
                          Icons.support_agent_rounded,
                          const Color(0xFFF59E0B),
                          () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const SupportScreen(),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // ==================================================
            // SERVICES
            // ==================================================
            _sectionTitle("Our Services"),

            const SizedBox(height: 13),

            _services(),

            const SizedBox(height: 30),

            // ==================================================
            // HEALTH PACKAGES
            // ==================================================
            _sectionTitle("Health Packages"),

            const SizedBox(height: 13),

            _healthPackages(),

            const SizedBox(height: 30),

            // ==================================================
            // PREPARATION TIPS
            // ==================================================
            _sectionTitle("Diagnostic Preparation Tips"),

            const SizedBox(height: 13),

            _preparationTips(),

            const SizedBox(height: 30),

            // ==================================================
            // TRUST
            // ==================================================
            _trustSection(),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // HEADER ICON
  // ============================================================

  Widget _headerIconButton({
    required IconData icon,
    required VoidCallback onTap,
    int badgeCount = 0,
  }) {
    return GestureDetector(
      onTap: onTap,

      child: Stack(
        clipBehavior: Clip.none,

        children: [
          Container(
            height: 46,
            width: 46,

            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.09),

              shape: BoxShape.circle,

              border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
            ),

            child: Icon(icon, color: Colors.white, size: 23),
          ),

          if (badgeCount > 0)
            Positioned(
              right: -2,
              top: -4,

              child: Container(
                constraints: const BoxConstraints(minWidth: 18, minHeight: 18),

                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),

                decoration: BoxDecoration(
                  color: Colors.redAccent,
                  borderRadius: BorderRadius.circular(20),

                  border: Border.all(color: navy, width: 2),
                ),

                child: Text(
                  badgeCount > 9 ? "9+" : "$badgeCount",

                  textAlign: TextAlign.center,

                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ============================================================
  // PROFILE AVATAR
  // ============================================================

  Widget _profileAvatar() {
    return ValueListenableBuilder<String?>(
      valueListenable: ProfileService.profilePhotoNotifier,
      builder: (context, photoPath, _) {
        if (photoPath != null && photoPath.isNotEmpty) {
          if (photoPath.startsWith('data:image')) {
            try {
              final bytes = base64Decode(photoPath.split(',').last);
              return ClipOval(
                child: Image.memory(
                  bytes,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => _defaultAvatar(),
                ),
              );
            } catch (_) {}
          } else if (!kIsWeb) {
            final file = File(photoPath);
            if (file.existsSync()) {
              return ClipOval(
                child: Image.file(
                  file,
                  key: ValueKey(photoPath),
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => _defaultAvatar(),
                ),
              );
            }
          }
        }

        if (profilePhoto != null && profilePhoto!.isNotEmpty) {
          return ClipOval(
            child: Image.network(
              profilePhoto!,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return _defaultAvatar();
              },
            ),
          );
        }

        return _defaultAvatar();
      },
    );
  }

  Widget _defaultAvatar() {
    return Container(
      decoration: const BoxDecoration(
        shape: BoxShape.circle,

        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [blue, teal],
        ),
      ),

      child: Center(
        child: Text(
          userInitials,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // GREETING
  // ============================================================

  String _getGreeting() {
    final hour = DateTime.now().hour;

    if (hour < 12) {
      return "Morning";
    }

    if (hour < 17) {
      return "Afternoon";
    }

    if (hour < 21) {
      return "Evening";
    }

    return "Night";
  }

  // ============================================================
  // SECTION TITLE
  // ============================================================

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),

      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,

        children: [
          Text(
            title,

            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: primaryText,
            ),
          ),

          if (title == "Our Services" || title == "Health Packages")
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => title == "Health Packages"
                        ? const HealthPackagesScreen()
                        : const ServicesScreen(),
                  ),
                );
              },

              child: const Row(
                children: [
                  Text(
                    "View All",
                    style: TextStyle(
                      color: blue,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),

                  SizedBox(width: 4),

                  Icon(Icons.arrow_forward_rounded, color: blue, size: 15),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ============================================================
  // QUICK CARD
  // ============================================================

  Widget _quickCard(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,

      child: Container(
        height: 108,

        padding: const EdgeInsets.all(10),

        decoration: BoxDecoration(
          color: cardColor,

          borderRadius: BorderRadius.circular(18),

          border: Border.all(color: color.withValues(alpha: 0.10)),

          boxShadow: [
            BoxShadow(
              color: color.withValues(
                alpha: Theme.of(context).brightness == Brightness.dark
                    ? 0.12
                    : 0.08,
              ),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),

        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,

          children: [
            Container(
              padding: const EdgeInsets.all(10),

              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.10),

                borderRadius: BorderRadius.circular(13),
              ),

              child: Icon(icon, color: color, size: 25),
            ),

            const SizedBox(height: 8),

            Text(
              title,

              textAlign: TextAlign.center,

              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.bold,
                color: primaryText,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // SERVICES
  // ============================================================

  Widget _services() {
    return SizedBox(
      height: 132,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          _serviceCard(
            "All Services",
            Icons.grid_view_rounded,
            blue,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ServicesScreen()),
              );
            },
          ),
          _serviceCard(
            "Ultrasound",
            Icons.monitor_heart_rounded,
            teal,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ServicesScreen()),
              );
            },
          ),
          _serviceCard(
            "Blood Tests",
            Icons.bloodtype_rounded,
            const Color(0xFFFF4D6D),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const BloodTestsScreen()),
              );
            },
          ),
          _serviceCard(
            "Sugar Tests",
            Icons.water_drop_rounded,
            const Color(0xFFFF8A00),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SugarTestsScreen()),
              );
            },
          ),
          _serviceCard(
            "Thyroid",
            Icons.biotech_rounded,
            const Color(0xFF7C4DFF),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ThyroidScreen()),
              );
            },
          ),
          _serviceCard(
            "Other Tests",
            Icons.medical_services_rounded,
            const Color(0xFF10B981),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ServicesScreen()),
              );
            },
          ),
          _serviceCard(
            "Health Packages",
            Icons.card_membership_rounded,
            const Color(0xFF18C8C8),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const HealthPackagesScreen()),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _serviceCard(String title, IconData icon, Color color, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap ?? () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ServicesScreen()),
        );
      },
      child: Container(
        width: 150,
        margin: const EdgeInsets.only(right: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.10)),
          boxShadow: [
            BoxShadow(
              color: color.withValues(
                alpha: Theme.of(context).brightness == Brightness.dark
                    ? 0.12
                    : 0.08,
              ),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 29),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: primaryText,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // HEALTH PACKAGES
  // ============================================================

  Widget _healthPackages() {
    return SizedBox(
      height: 185,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          _packageCard(
            "Basic Health Checkup",
            "Essential 28 tests screening",
            "₹699",
            "₹1,500",
            Icons.favorite_outline_rounded,
            blue,
          ),
          _packageCard(
            "Comprehensive Full Body",
            "Complete 64 tests with LFT & KFT",
            "₹1,799",
            "₹4,200",
            Icons.card_membership_rounded,
            const Color(0xFF10B981),
          ),
          _packageCard(
            "Diabetes & Heart Care",
            "HbA1c + Lipid + Sugar (36 tests)",
            "₹1,199",
            "₹2,400",
            Icons.water_drop_outlined,
            const Color(0xFFFF8A00),
          ),
          _packageCard(
            "Thyroid Profile Total",
            "T3, T4, TSH Ultrasensitive",
            "₹450",
            "₹750",
            Icons.biotech_outlined,
            const Color(0xFF7C4DFF),
          ),
        ],
      ),
    );
  }

  Widget _packageCard(
    String title,
    String subtitle,
    String price,
    String originalPrice,
    IconData icon,
    Color color,
  ) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const HealthPackagesScreen()),
        );
      },
      child: Container(
        width: 250,
        margin: const EdgeInsets.only(right: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withValues(alpha: 0.10), cardColor],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: color.withValues(alpha: 0.16)),
          boxShadow: [
            BoxShadow(
              color: color.withValues(
                alpha: Theme.of(context).brightness == Brightness.dark
                    ? 0.12
                    : 0.07,
              ),
              blurRadius: 12,
              offset: const Offset(0, 5),
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
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    "SAVE 50%+",
                    style: TextStyle(
                      color: color,
                      fontSize: 9.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: primaryText,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 11, color: secondaryText),
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      price,
                      style: TextStyle(
                        color: color,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      originalPrice,
                      style: TextStyle(
                        decoration: TextDecoration.lineThrough,
                        color: secondaryText,
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Text(
                      "Book Now",
                      style: TextStyle(
                        color: color,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.arrow_forward_rounded, size: 12, color: color),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // PREPARATION TIPS
  // ============================================================

  Widget _preparationTips() {
    final tips = [
      {
        'title': 'Fasting Blood Tests',
        'subtitle': 'FBS, Lipid Profile, LFT, KFT',
        'tip': 'Fast for 10-12 hours prior. Plain drinking water is permitted and encouraged.',
        'icon': Icons.water_drop_outlined,
        'color': const Color(0xFFFF8A00),
      },
      {
        'title': 'Pelvic & KUB Ultrasound',
        'subtitle': 'Full Bladder Protocol',
        'tip': 'Drink 4 to 5 glasses of plain water 1 hour before scan. Do not empty bladder until scan finishes.',
        'icon': Icons.monitor_heart_outlined,
        'color': blue,
      },
      {
        'title': 'Thyroid Panel',
        'subtitle': 'T3, T4, TSH Guidance',
        'tip': 'Collect morning sample before taking thyroid medication unless specifically advised otherwise.',
        'icon': Icons.biotech_outlined,
        'color': const Color(0xFF7C4DFF),
      },
      {
        'title': 'Whole Abdomen Scan',
        'subtitle': 'Liver, Gallbladder, Pancreas',
        'tip': 'Fasting 6-8 hours ensures clear gallbladder visualization without gas interference.',
        'icon': Icons.healing_outlined,
        'color': teal,
      },
    ];

    return SizedBox(
      height: 142,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: tips.length,
        separatorBuilder: (_, index) => const SizedBox(width: 14),
        itemBuilder: (context, index) {
          final t = tips[index];
          final color = t['color'] as Color;
          return Container(
            width: 270,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withValues(alpha: 0.16)),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(
                    alpha: Theme.of(context).brightness == Brightness.dark
                        ? 0.10
                        : 0.05,
                  ),
                  blurRadius: 12,
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
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(t['icon'] as IconData, color: color, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            t['title'] as String,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: primaryText,
                            ),
                          ),
                          Text(
                            t['subtitle'] as String,
                            style: TextStyle(
                              fontSize: 10.5,
                              color: secondaryText,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  t['tip'] as String,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11.5,
                    color: secondaryText,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ============================================================
  // TRUST SECTION
  // ============================================================

  Widget _trustSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [navy, Color(0xFF0C2B47), navy2],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: const BorderRadius.all(Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: navy.withValues(alpha: 0.3),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  height: 52,
                  width: 52,
                  decoration: BoxDecoration(
                    color: teal.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: teal.withValues(alpha: 0.3),
                    ),
                  ),
                  child: const Icon(Icons.verified_rounded, color: teal, size: 30),
                ),
                const SizedBox(width: 15),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Certified Diagnostic Center",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        "ISO certified & NABL aligned standards with digital automated reporting.",
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 11.5,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _statBadge("99.8%", "Report Accuracy"),
                  Container(height: 24, width: 1, color: Colors.white24),
                  _statBadge("2-4 Hrs", "Fast Delivery"),
                  Container(height: 24, width: 1, color: Colors.white24),
                  _statBadge("25k+", "Patients Served"),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SupportScreen()),
                  );
                },
                icon: const Icon(Icons.headset_mic_rounded, color: teal, size: 18),
                label: const Text(
                  "Contact Support & Help Desk",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: teal.withValues(alpha: 0.4)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statBadge(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Color(0xFF18C8C8),
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white60,
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
