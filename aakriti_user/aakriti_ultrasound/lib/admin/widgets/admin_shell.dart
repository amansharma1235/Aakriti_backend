import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../controllers/profile_controller.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/patients/patients_screen.dart';
import '../screens/appointments/appointments_screen.dart';
import '../screens/services/services_screen.dart';
import '../screens/reports/reports_screen.dart';
import '../screens/doctors/doctors_screen.dart';
import '../screens/notifications/notifications_screen.dart';
import '../screens/payments/payment_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/login/login_screen.dart';
import '../services/api_service.dart';
import '../services/websocket_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../theme/theme_controller.dart';
import '../../screen/home_screen.dart';
import 'booking_modal.dart';
import 'patient_qr_pass_modal.dart';

class AdminShell extends StatefulWidget {
  final bool isFromUserApp;
  const AdminShell({super.key, this.isFromUserApp = false});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int selectedIndex = 0;
  int unreadNotificationsCount = 2;

  final List<String> titles = [
    'Dashboard',
    'Patients',
    'Appointments',
    'Diagnostic Reports',
    'Diagnostic Services',
    'Doctors & Radiologists',
    'Notifications',
    'Payments & Billing',
    'Center Settings',
  ];

  late final List<Widget> pages;

  @override
  void initState() {
    super.initState();

    pages = [
      DashboardScreen(onNavigate: changePage),
      const PatientsScreen(),
      const AppointmentsScreen(),
      const ReportsScreen(),
      const ServicesScreen(),
      const DoctorsScreen(),
      const NotificationsScreen(),
      const PaymentScreen(),
      const SettingsScreen(),
    ];

    // Initialize admin profile controller and load photo
    ProfileController.instance.init();

    // Check server and database health
    ApiService.checkHealth();

    // Connect real-time WebSocket
    WebSocketService.instance.connect();
    WebSocketService.instance.addListener(_handleRealtimeEvent);
  }

  @override
  void dispose() {
    WebSocketService.instance.removeListener(_handleRealtimeEvent);
    super.dispose();
  }

  void _handleRealtimeEvent(Map<String, dynamic> event) {
    if (!mounted) return;
    final eventType = event['event'] ?? '';
    final data = event['data'] ?? {};

    if (eventType == 'NEW_APPOINTMENT') {
      // Play audio notification chime
      SystemSound.play(SystemSoundType.click);

      setState(() {
        unreadNotificationsCount++;
      });

      // Show instant live notification banner
      final patientName = data['patient_name'] ?? 'Patient';
      final serviceName = data['service_name'] ?? 'Ultrasound Procedure';
      final timeSlot = data['appointment_time'] ?? '';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 5),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF0F172A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppColors.primaryBlue, width: 1.5),
          ),
          content: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.notifications_active_rounded, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '⚡ NEW APPOINTMENT RECEIVED',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.8,
                        color: AppColors.primaryCyan,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$patientName • $serviceName ($timeSlot)',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  changePage(2); // Go to Appointments
                },
                child: const Text('VIEW', style: TextStyle(color: AppColors.primaryCyan, fontWeight: FontWeight.w800)),
              ),
            ],
          ),
        ),
      );
    }
  }


  void changePage(int index) {
    setState(() {
      selectedIndex = index;
    });
    if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
      Navigator.pop(context);
    }
  }

  Widget _buildAdminAvatar({double radius = 17}) {
    return ValueListenableBuilder<Uint8List?>(
      valueListenable: ProfileController.instance.profileImageBytes,
      builder: (context, bytes, _) {
        if (bytes != null) {
          return CircleAvatar(
            radius: radius,
            backgroundImage: MemoryImage(bytes),
          );
        }
        return CircleAvatar(
          radius: radius,
          backgroundColor: AppColors.primary.withValues(alpha: 0.15),
          backgroundImage: const AssetImage('assets/AMAN.jpeg'),
          onBackgroundImageError: (error, stack) {},
        );
      },
    );
  }

  void _showServerIpDialog() {
    final ipCtrl = TextEditingController(text: ApiService.baseUrl);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardBg(context),
        scrollable: true,
        title: Text(
          'FastAPI Server URL',
          style: TextStyle(fontWeight: FontWeight.w800, color: AppTheme.textPrimary(context)),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Change your backend address if testing on a physical phone over Wi-Fi:',
              style: TextStyle(fontSize: 12, color: AppTheme.textSecondary(context)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: ipCtrl,
              style: TextStyle(color: AppTheme.textPrimary(context)),
              decoration: const InputDecoration(
                labelText: 'Server URL',
                prefixIcon: Icon(Icons.lan_outlined),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              ApiService.baseUrl = ipCtrl.text.trim();
              ApiService.checkHealth();
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Server URL set to: ${ApiService.baseUrl}'),
                  backgroundColor: const Color(0xFF1677FF),
                ),
              );
            },
            child: const Text('Save & Reconnect'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final bool isMobile = width < 800;
    final bool isTablet = width >= 800 && width < 1100;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppTheme.scaffoldBg(context),

      // DRAWER FOR ALL FEATURES
      drawer: _buildAppDrawer(),

      body: SafeArea(
        child: Row(
          children: [
            if (!isMobile) _buildSidebar(compact: isTablet),

            Expanded(
              child: Column(
                children: [
                  _buildTopBar(isMobile: isMobile),
                  Expanded(child: pages[selectedIndex]),
                ],
              ),
            ),
          ],
        ),
      ),

      bottomNavigationBar: isMobile ? _buildMobileBottomNavigation() : null,
    );
  }

  // ============================================================
  // ADMIN NAVIGATION DRAWER
  // ============================================================

  Widget _buildAppDrawer() {
    final isDark = AppTheme.isDark(context);
    final drawerBg = isDark ? const Color(0xFF071A2B) : Colors.white;
    final dividerColor = isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0);

    return Drawer(
      backgroundColor: drawerBg,
      child: SafeArea(
        child: Column(
          children: [
            // Drawer Header
            _buildDrawerHeader(),

            // Navigation Links
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                children: [
                  _drawerSectionTitle('CORE MODULES'),
                  _drawerItem(
                    index: 0,
                    icon: Icons.dashboard_outlined,
                    selectedIcon: Icons.dashboard_rounded,
                    title: 'Dashboard',
                  ),
                  _drawerItem(
                    index: 1,
                    icon: Icons.people_outline_rounded,
                    selectedIcon: Icons.people_rounded,
                    title: 'Patients',
                    badge: 'Active',
                    badgeColor: const Color(0xFF10B981),
                  ),
                  _drawerItem(
                    index: 2,
                    icon: Icons.calendar_month_outlined,
                    selectedIcon: Icons.calendar_month_rounded,
                    title: 'Appointments',
                    badge: '5 Today',
                    badgeColor: const Color(0xFF1677FF),
                  ),
                  _drawerItem(
                    index: 3,
                    icon: Icons.description_outlined,
                    selectedIcon: Icons.description_rounded,
                    title: 'Diagnostic Reports',
                    badge: 'Ready',
                    badgeColor: const Color(0xFFF59E0B),
                  ),

                  const SizedBox(height: 12),
                  _drawerSectionTitle('DIAGNOSTICS & MANAGEMENT'),
                  _drawerItem(
                    index: 4,
                    icon: Icons.medical_services_outlined,
                    selectedIcon: Icons.medical_services_rounded,
                    title: 'Diagnostic Services',
                  ),
                  _drawerItem(
                    index: 5,
                    icon: Icons.medical_information_outlined,
                    selectedIcon: Icons.medical_information_rounded,
                    title: 'Doctors & Radiologists',
                  ),
                  _drawerItem(
                    index: 6,
                    icon: Icons.notifications_none_rounded,
                    selectedIcon: Icons.notifications_rounded,
                    title: 'Notifications',
                  ),
                  _drawerItem(
                    index: 7,
                    icon: Icons.payments_outlined,
                    selectedIcon: Icons.payments_rounded,
                    title: 'Payments & Billing',
                  ),

                  const SizedBox(height: 12),
                  _drawerSectionTitle('SYSTEM & SETTINGS'),
                  _drawerItem(
                    index: 8,
                    icon: Icons.settings_outlined,
                    selectedIcon: Icons.settings_rounded,
                    title: 'Settings',
                  ),

                  Divider(color: dividerColor, height: 28),

                  // Dark mode toggle in drawer
                  ValueListenableBuilder<ThemeMode>(
                    valueListenable: ThemeController.instance.themeMode,
                    builder: (context, themeMode, _) {
                      final isDarkNow = themeMode == ThemeMode.dark;
                      final primaryTextColor = isDarkNow ? const Color(0xFFCBD5E1) : const Color(0xFF0F172A);
                      final secondaryTextColor = isDarkNow ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
                      return ListTile(
                        dense: true,
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 14),
                        leading: Icon(
                          isDarkNow
                              ? Icons.dark_mode_rounded
                              : Icons.light_mode_rounded,
                          color: isDarkNow ? const Color(0xFFF59E0B) : const Color(0xFF1677FF),
                          size: 20,
                        ),
                        title: Text(
                          isDarkNow ? 'Dark Theme' : 'Light Theme',
                          style: TextStyle(
                            color: primaryTextColor,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          isDarkNow ? 'Dark mode enabled' : 'Light mode enabled',
                          style: TextStyle(
                            color: secondaryTextColor,
                            fontSize: 10,
                          ),
                        ),
                        trailing: Switch(
                          value: isDarkNow,
                          activeThumbColor: const Color(0xFF1677FF),
                          onChanged: (val) {
                            ThemeController.instance.toggleDarkMode(val);
                          },
                        ),
                      );
                    },
                  ),

                  // Back to Patient App option
                  ListTile(
                    dense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14),
                    leading: const Icon(
                      Icons.arrow_back_rounded,
                      color: Color(0xFF1677FF),
                      size: 20,
                    ),
                    title: const Text(
                      'Back to Patient Portal',
                      style: TextStyle(
                        color: Color(0xFF1677FF),
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    onTap: () {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const HomeScreen()),
                        (route) => false,
                      );
                    },
                  ),

                  // Logout option
                  ListTile(
                    dense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14),
                    leading: const Icon(
                      Icons.logout_rounded,
                      color: Color(0xFFEF4444),
                      size: 20,
                    ),
                    title: const Text(
                      'Log Out',
                      style: TextStyle(
                        color: Color(0xFFEF4444),
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    onTap: () async {
                      await ApiService.clearAdminToken();
                      if (!mounted) return;
                      if (widget.isFromUserApp) {
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(builder: (_) => const HomeScreen()),
                          (route) => false,
                        );
                      } else {
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(builder: (_) => const LoginScreen(isFromUserApp: true)),
                          (route) => false,
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerHeader() {
    final isDark = AppTheme.isDark(context);
    final headerBg = isDark ? const Color(0xFF061524) : const Color(0xFFF8FAFC);
    final borderBottomColor = isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0);
    final userCardBg = isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFEDF2F7);
    final primaryTextColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final secondaryTextColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: headerBg,
        border: Border(bottom: BorderSide(color: borderBottomColor)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1677FF), Color(0xFF00C6FF)],
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    'assets/image.png',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.local_hospital_rounded,
                      color: Colors.white,
                      size: 26,
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
                      'AAKRITI',
                      style: TextStyle(
                        color: primaryTextColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const Text(
                      'ULTRASOUND & DIAGNOSTIC',
                      style: TextStyle(
                        color: Color(0xFF1677FF),
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // User Card
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: userCardBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                _buildAdminAvatar(radius: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ValueListenableBuilder<String>(
                        valueListenable: ProfileController.instance.adminName,
                        builder: (context, name, _) => Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: primaryTextColor,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      ValueListenableBuilder<String>(
                        valueListenable: ProfileController.instance.adminRole,
                        builder: (context, role, _) => Text(
                          role,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: secondaryTextColor,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Server status indicator dot
                ValueListenableBuilder<bool>(
                  valueListenable: ApiService.isServerOnline,
                  builder: (context, isOnline, _) {
                    return Tooltip(
                      message: isOnline ? 'Backend Online' : 'Local Fallback',
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isOnline
                              ? const Color(0xFF10B981)
                              : const Color(0xFFF59E0B),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _drawerSectionTitle(String title) {
    final isDark = AppTheme.isDark(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 6),
      child: Text(
        title,
        style: TextStyle(
          color: isDark ? const Color(0xFF64748B) : const Color(0xFF475569),
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _drawerItem({
    required int index,
    required IconData icon,
    required IconData selectedIcon,
    required String title,
    String? badge,
    Color? badgeColor,
  }) {
    final bool isSelected = selectedIndex == index;
    final isDark = AppTheme.isDark(context);
    final unselectedTextColor = isDark ? const Color(0xFFCBD5E1) : const Color(0xFF1E293B);
    final unselectedIconColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => changePage(index),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF1677FF) : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  isSelected ? selectedIcon : icon,
                  color: isSelected ? Colors.white : unselectedIconColor,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: isSelected
                          ? Colors.white
                          : unselectedTextColor,
                      fontSize: 13,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
                if (badge != null)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.white.withValues(alpha: 0.25)
                          : (badgeColor ?? const Color(0xFF1677FF)),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      badge,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // SIDEBAR (DESKTOP / TABLET)
  // ============================================================

  Widget _buildSidebar({required bool compact}) {
    final isDark = AppTheme.isDark(context);
    final sidebarBg = isDark ? const Color(0xFF071A2B) : Colors.white;
    final sidebarBorder = isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0);
    final titleColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final userCardBg = isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF1F5F9);

    return Container(
      width: compact ? 80 : 240,
      decoration: BoxDecoration(
        color: sidebarBg,
        border: Border(right: BorderSide(color: sidebarBorder)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 20),
          // Logo
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1677FF), Color(0xFF00C6FF)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                'assets/image.png',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.local_hospital_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          ),
          if (!compact) ...[
            const SizedBox(height: 10),
            Text(
              'AAKRITI',
              style: TextStyle(
                color: titleColor,
                fontSize: 16,
                fontWeight: FontWeight.w800,
                letterSpacing: 2,
              ),
            ),
            const Text(
              'ULTRASOUND & DIAGNOSTIC',
              style: TextStyle(
                color: Color(0xFF1677FF),
                fontSize: 8,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
              ),
            ),
          ],
          const SizedBox(height: 24),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              children: [
                _sidebarItem(0, Icons.dashboard_outlined,
                    Icons.dashboard_rounded, 'Dashboard', compact),
                _sidebarItem(1, Icons.people_outline_rounded,
                    Icons.people_rounded, 'Patients', compact),
                _sidebarItem(2, Icons.calendar_month_outlined,
                    Icons.calendar_month_rounded, 'Appointments', compact),
                _sidebarItem(3, Icons.description_outlined,
                    Icons.description_rounded, 'Reports', compact),
                _sidebarItem(4, Icons.medical_services_outlined,
                    Icons.medical_services_rounded, 'Services', compact),
                _sidebarItem(5, Icons.medical_information_outlined,
                    Icons.medical_information_rounded, 'Doctors', compact),
                _sidebarItem(6, Icons.notifications_none_rounded,
                    Icons.notifications_rounded, 'Notifications', compact),
                _sidebarItem(7, Icons.payments_outlined,
                    Icons.payments_rounded, 'Payments', compact),
                _sidebarItem(8, Icons.settings_outlined,
                    Icons.settings_rounded, 'Settings', compact),
              ],
            ),
          ),
          // User profile at bottom
          Padding(
            padding: const EdgeInsets.all(12),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => changePage(8),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: EdgeInsets.all(compact ? 8 : 10),
                  decoration: BoxDecoration(
                    color: userCardBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: compact
                      ? Icon(Icons.person_rounded, color: titleColor)
                      : Row(
                          children: [
                            _buildAdminAvatar(radius: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ValueListenableBuilder<String>(
                                    valueListenable: ProfileController.instance.adminName,
                                    builder: (context, name, _) => Text(
                                      name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: titleColor,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                  const Text(
                                    'Online',
                                    style: TextStyle(
                                      color: Color(0xFF10B981),
                                      fontSize: 10,
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
        ],
      ),
    );
  }

  Widget _sidebarItem(int index, IconData icon, IconData selectedIcon,
      String title, bool compact) {
    final bool isSelected = selectedIndex == index;
    final isDark = AppTheme.isDark(context);
    final unselectedTextColor = isDark ? const Color(0xFFCBD5E1) : const Color(0xFF1E293B);
    final unselectedIconColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => changePage(index),
          borderRadius: BorderRadius.circular(10),
          child: Container(
            height: 42,
            padding: EdgeInsets.symmetric(horizontal: compact ? 0 : 12),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF1677FF) : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment:
                  compact ? MainAxisAlignment.center : MainAxisAlignment.start,
              children: [
                Icon(
                  isSelected ? selectedIcon : icon,
                  color: isSelected ? Colors.white : unselectedIconColor,
                  size: 20,
                ),
                if (!compact) ...[
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : unselectedTextColor,
                        fontSize: 13,
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // TOP BAR (RESPONSIVE WITH HAMBURGER BUTTON)
  // ============================================================

  Widget _buildTopBar({required bool isMobile}) {
    final isDark = AppTheme.isDark(context);

    return Container(
      height: 64,
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 20),
      decoration: BoxDecoration(
        color: AppTheme.cardBg(context),
        border: Border(bottom: BorderSide(color: AppTheme.border(context))),
      ),
      child: Row(
        children: [
          // Return to Patient App button
          if (widget.isFromUserApp)
            IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF1677FF)),
              onPressed: () {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const HomeScreen()),
                  (route) => false,
                );
              },
              tooltip: 'Return to Patient App',
            ),

          // Hamburger button on mobile / tablet to open Drawer
          if (isMobile)
            IconButton(
              icon: Icon(Icons.menu_rounded, color: AppTheme.textPrimary(context)),
              onPressed: () {
                _scaffoldKey.currentState?.openDrawer();
              },
              tooltip: 'Open Menu',
            ),

          if (isMobile) const SizedBox(width: 6),

          Expanded(
            child: Text(
              titles[selectedIndex],
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: isMobile ? 18 : 20,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary(context),
              ),
            ),
          ),

          // Server & Real-time Connection Status
          ValueListenableBuilder<bool>(
            valueListenable: ApiService.isServerOnline,
            builder: (context, isOnline, _) {
              return ValueListenableBuilder<WsConnectionState>(
                valueListenable: WebSocketService.instance.connectionState,
                builder: (context, wsState, _) {
                  final isWsConnected = wsState == WsConnectionState.connected;
                  final isWsConnecting = wsState == WsConnectionState.connecting;

                  return InkWell(
                    onTap: _showServerIpDialog,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: isOnline
                            ? (isDark ? const Color(0xFF064E3B).withValues(alpha: 0.5) : const Color(0xFFE6F7ED))
                            : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isOnline
                              ? (isDark ? const Color(0xFF059669) : const Color(0xFF86EFAC))
                              : AppTheme.border(context),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isOnline ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                            ),
                          ),
                          const SizedBox(width: 5),
                          Container(
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isWsConnected
                                  ? const Color(0xFF06B6D4)
                                  : (isWsConnecting ? const Color(0xFFF59E0B) : const Color(0xFF64748B)),
                            ),
                          ),
                          if (!isMobile) ...[
                            const SizedBox(width: 6),
                            Text(
                              isOnline ? (isWsConnected ? 'Live • Real-Time' : 'FastAPI Connected') : 'Offline',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: isOnline
                                    ? (isDark ? const Color(0xFF34D399) : const Color(0xFF15803D))
                                    : AppTheme.textSecondary(context),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),

          const SizedBox(width: 8),

          // Quick Patient QR Scanner / Lookup Action
          IconButton(
            tooltip: 'Patient 360° QR Scanner / Lookup',
            onPressed: () => PatientQrPassModal.showScannerLookup(context),
            icon: Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.qr_code_scanner_rounded, color: AppColors.primaryBlue, size: 20),
            ),
          ),

          // Quick Booking Action
          if (!isMobile)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: ElevatedButton.icon(
                onPressed: () => BookingModal.show(context),
                icon: const Icon(Icons.add_rounded, size: 16),
                label: const Text('New Booking', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
              ),
            ),

          const SizedBox(width: 4),

          // Notifications button with live unread badge
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                onPressed: () {
                  setState(() => unreadNotificationsCount = 0);
                  changePage(6);
                },
                icon: Icon(
                  Icons.notifications_none_rounded,
                  color: AppTheme.textSecondary(context),
                  size: 22,
                ),
                tooltip: 'Notifications',
              ),
              if (unreadNotificationsCount > 0)
                Positioned(
                  top: 6,
                  right: 6,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppColors.danger,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Center(
                      child: Text(
                        unreadNotificationsCount > 9 ? '9+' : '$unreadNotificationsCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),


          // Profile menu
          PopupMenuButton<String>(
            tooltip: 'Admin Profile',
            offset: const Offset(0, 48),
            color: AppTheme.cardBg(context),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(color: AppTheme.border(context)),
            ),
            onSelected: (val) async {
              if (val == 'settings') {
                changePage(8);
              } else if (val == 'patient_portal') {
                if (!mounted) return;
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const HomeScreen()),
                  (route) => false,
                );
              } else if (val == 'logout') {
                await ApiService.clearAdminToken();
                if (!mounted) return;
                if (widget.isFromUserApp) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const HomeScreen()),
                    (route) => false,
                  );
                } else {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginScreen(isFromUserApp: true)),
                    (route) => false,
                  );
                }
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'patient_portal',
                child: Row(
                  children: [
                    const Icon(Icons.arrow_back_rounded, size: 18, color: Color(0xFF1677FF)),
                    const SizedBox(width: 10),
                    Text('Exit to Patient Portal', style: TextStyle(color: AppTheme.textPrimary(context), fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'settings',
                child: Row(
                  children: [
                    Icon(Icons.settings_outlined, size: 18, color: AppTheme.textPrimary(context)),
                    const SizedBox(width: 10),
                    Text('Settings', style: TextStyle(color: AppTheme.textPrimary(context))),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout_rounded, size: 18, color: Colors.red),
                    SizedBox(width: 10),
                    Text('Logout', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: _buildAdminAvatar(radius: 17),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // MOBILE BOTTOM NAVIGATION (CORE TABS + MENU)
  // ============================================================

  Widget _buildMobileBottomNavigation() {
    int activeIndex = 0;
    if (selectedIndex == 0) {
      activeIndex = 0;
    } else if (selectedIndex == 1) {
      activeIndex = 1;
    } else if (selectedIndex == 2) {
      activeIndex = 2;
    } else if (selectedIndex == 3) {
      activeIndex = 3;
    } else {
      activeIndex = 4;
    }

    return NavigationBar(
      selectedIndex: activeIndex,
      onDestinationSelected: (index) {
        if (index == 4) {
          // Open Drawer to view all features
          _scaffoldKey.currentState?.openDrawer();
        } else {
          changePage(index);
        }
      },
      backgroundColor: AppTheme.cardBg(context),
      elevation: 8,
      height: 64,
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.dashboard_outlined),
          selectedIcon: Icon(Icons.dashboard_rounded),
          label: 'Home',
        ),
        NavigationDestination(
          icon: Icon(Icons.people_outline_rounded),
          selectedIcon: Icon(Icons.people_rounded),
          label: 'Patients',
        ),
        NavigationDestination(
          icon: Icon(Icons.calendar_month_outlined),
          selectedIcon: Icon(Icons.calendar_month_rounded),
          label: 'Appointments',
        ),
        NavigationDestination(
          icon: Icon(Icons.description_outlined),
          selectedIcon: Icon(Icons.description_rounded),
          label: 'Reports',
        ),
        NavigationDestination(
          icon: Icon(Icons.menu_rounded),
          selectedIcon: Icon(Icons.menu_open_rounded),
          label: 'All Features',
        ),
      ],
    );
  }
}
