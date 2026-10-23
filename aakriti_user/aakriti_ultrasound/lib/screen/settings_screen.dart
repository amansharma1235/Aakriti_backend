import 'package:flutter/material.dart';

import '../services/theme_controller.dart';
import '../admin/screens/login/login_screen.dart' as admin_login;
import 'support_screen.dart';
import 'payments_screen.dart';
import 'doctors_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool notificationsEnabled = true;

  @override
  void initState() {
    super.initState();
    ThemeController.instance.themeMode.addListener(_themeChanged);
  }

  @override
  void dispose() {
    ThemeController.instance.themeMode.removeListener(_themeChanged);
    super.dispose();
  }

  void _themeChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  // =========================
  // CHANGE PASSWORD
  // =========================

  void _showChangePasswordDialog() {
    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: const Row(
            children: [
              Icon(Icons.lock_outline_rounded, color: Color(0xFF1677FF)),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  "Change Password",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: oldPasswordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: "Current Password",
                    prefixIcon: const Icon(Icons.lock_outline),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: newPasswordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: "New Password",
                    prefixIcon: const Icon(Icons.lock_reset_rounded),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: confirmPasswordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: "Confirm Password",
                    prefixIcon: const Icon(Icons.verified_user_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                if (newPasswordController.text.isEmpty ||
                    confirmPasswordController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Please enter all password fields.")),
                  );
                  return;
                }
                if (newPasswordController.text != confirmPasswordController.text) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("New passwords do not match.")),
                  );
                  return;
                }
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Password updated successfully.")),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1677FF),
                foregroundColor: Colors.white,
              ),
              child: const Text("Update"),
            ),
          ],
        );
      },
    );
  }

  // =========================
  // LANGUAGE
  // =========================

  void _showLanguageDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: 5,
                  width: 45,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  "Select Language / भाषा चुनें",
                  style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFE8F1FF),
                    child: Icon(Icons.language_rounded, color: Color(0xFF1677FF)),
                  ),
                  title: const Text("English", style: TextStyle(fontWeight: FontWeight.w600)),
                  trailing: const Icon(Icons.check_circle_rounded, color: Color(0xFF1677FF)),
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Language set to English.")),
                    );
                  },
                ),
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFE8FFF8),
                    child: Icon(Icons.translate_rounded, color: Color(0xFF18A999)),
                  ),
                  title: const Text("हिन्दी (Hindi)", style: TextStyle(fontWeight: FontWeight.w600)),
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("हिन्दी भाषा का चयन किया गया.")),
                    );
                  },
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        );
      },
    );
  }

  // =========================
  // FEEDBACK & RATING
  // =========================

  void _showFeedbackDialog() {
    int rating = 5;
    final feedbackController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            final cardColor = Theme.of(context).cardColor;
            final isDark = Theme.of(context).brightness == Brightness.dark;

            return Container(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 45,
                    height: 5,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white24 : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Rate Your Experience",
                    style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "How satisfied are you with Aakriti Ultrasound & Diagnostics?",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      final star = index + 1;
                      return IconButton(
                        iconSize: 36,
                        onPressed: () {
                          setModalState(() => rating = star);
                        },
                        icon: Icon(
                          star <= rating ? Icons.star_rounded : Icons.star_border_rounded,
                          color: Colors.amber,
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: feedbackController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: "Write your review or feedback...",
                      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Thank you! Your feedback has been recorded."),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1677FF),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text("Submit Review"),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // =========================
  // TERMS & CONDITIONS
  // =========================

  void _showTermsDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final cardColor = Theme.of(context).cardColor;
        final isDark = Theme.of(context).brightness == Brightness.dark;

        return Container(
          height: MediaQuery.of(ctx).size.height * 0.82,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 45,
                  height: 5,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                "Terms and Conditions",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(
                "Last updated: September 2026",
                style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
              ),
              const Divider(height: 24),
              Expanded(
                child: SingleChildScrollView(
                  child: Text(
                    "1. Clinical Examination Services:\n"
                    "All diagnostic examinations at Aakriti Ultrasound & Diagnostic Centre are performed following strict regulatory medical protocols by registered clinical professionals.\n\n"
                    "2. Appointment Booking & Schedules:\n"
                    "Appointment time slots represent estimated commencement. Emergency patient needs may alter timing.\n\n"
                    "3. Report Delivery & Verification:\n"
                    "Diagnostic reports are prepared and digitally signed by authorized Radiologists and Pathologists. Each report contains secure verification keys.\n\n"
                    "4. Patient Consent & Medical Records:\n"
                    "Patient details provided during booking must be accurate to ensure proper medical charting.",
                    style: TextStyle(
                      color: isDark ? Colors.white70 : Colors.black87,
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1677FF),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text("I Understand"),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // =========================
  // PRIVACY POLICY
  // =========================

  void _showPrivacyDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final cardColor = Theme.of(context).cardColor;
        final isDark = Theme.of(context).brightness == Brightness.dark;

        return Container(
          height: MediaQuery.of(ctx).size.height * 0.82,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 45,
                  height: 5,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                "Privacy & Security Policy",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(
                "HIPAA & Healthcare Data Compliance",
                style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
              ),
              const Divider(height: 24),
              Expanded(
                child: SingleChildScrollView(
                  child: Text(
                    "1. Confidentiality of Health Records:\n"
                    "Aakriti Ultrasound is committed to safeguarding patient medical data. Your diagnostic scan images, blood reports, and health history are encrypted.\n\n"
                    "2. Data Transmission Security:\n"
                    "Mobile application communications with our FastAPI servers are transmitted over secure encrypted connections.\n\n"
                    "3. Access Permissions:\n"
                    "Camera and storage permissions are strictly utilized for patient ID card scanning and PDF report downloads on your local device.\n\n"
                    "4. Data Retention:\n"
                    "Medical records are archived in compliance with clinical record regulations.",
                    style: TextStyle(
                      color: isDark ? Colors.white70 : Colors.black87,
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF18A999),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text("Acknowledge"),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // =========================
  // DELETE ACCOUNT
  // =========================

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.red),
              SizedBox(width: 8),
              Text("Delete Account", style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          content: const Text(
            "Are you sure you want to request account deletion? All local records and session tokens will be removed.",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Account deletion request submitted to administration."),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
              child: const Text("Delete"),
            ),
          ],
        );
      },
    );
  }

  // =========================
  // ABOUT AAKRITI
  // =========================

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          title: const Column(
            children: [
              CircleAvatar(
                radius: 32,
                backgroundColor: Color(0xFF071A2B),
                child: Icon(Icons.local_hospital_rounded, color: Colors.white, size: 32),
              ),
              SizedBox(height: 12),
              Text(
                "Aakriti Ultrasound",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: const Text(
            "Premier Ultrasound & Diagnostic Centre providing digital sonography, pathology, Doppler, and comprehensive patient health screening.",
            textAlign: TextAlign.center,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Close"),
            ),
          ],
        );
      },
    );
  }

  // =========================
  // ADMIN PANEL
  // =========================

  void _openAdminPanel() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const admin_login.LoginScreen(isFromUserApp: true),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = ThemeController.instance.isDarkMode;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          "Settings & Preferences",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          // APPEARANCE
          _sectionTitle("Appearance & Language"),
          _settingsCard(
            children: [
              _settingsTile(
                icon: Icons.notifications_none_rounded,
                iconColor: const Color(0xFF1677FF),
                title: "Push Notifications",
                subtitle: "Real-time appointment and report alerts",
                trailing: Switch(
                  value: notificationsEnabled,
                  onChanged: (value) {
                    setState(() => notificationsEnabled = value);
                  },
                ),
              ),
              _divider(),
              _settingsTile(
                icon: isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                iconColor: const Color(0xFF18C8C8),
                title: "Dark Theme",
                subtitle: isDark ? "Dark theme enabled across all screens" : "Light mode active",
                trailing: Switch(
                  value: isDark,
                  onChanged: (value) {
                    ThemeController.instance.toggleDarkMode(value);
                  },
                ),
              ),
              _divider(),
              _settingsTile(
                icon: Icons.language_rounded,
                iconColor: const Color(0xFF8B5CF6),
                title: "Language",
                subtitle: "English / हिन्दी",
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                onTap: _showLanguageDialog,
              ),
            ],
          ),

          const SizedBox(height: 25),

          // DIAGNOSTIC CENTER SERVICES
          _sectionTitle("Center & Patient Services"),
          _settingsCard(
            children: [
              _settingsTile(
                icon: Icons.medical_information_rounded,
                iconColor: const Color(0xFF1677FF),
                title: "Our Specialists & Doctors",
                subtitle: "View certified Radiologists & Pathologists",
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const DoctorsScreen()),
                  );
                },
              ),
              _divider(),
              _settingsTile(
                icon: Icons.receipt_long_rounded,
                iconColor: Colors.green,
                title: "Payment History & Invoices",
                subtitle: "Download receipts & view diagnostic billing",
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const PaymentsScreen()),
                  );
                },
              ),
              _divider(),
              _settingsTile(
                icon: Icons.support_agent_rounded,
                iconColor: const Color(0xFFFF8A00),
                title: "Help & Support Center",
                subtitle: "Helpline, WhatsApp, location & FAQ",
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SupportScreen()),
                  );
                },
              ),
            ],
          ),

          const SizedBox(height: 25),

          // ACCOUNT & SECURITY
          _sectionTitle("Account & Security"),
          _settingsCard(
            children: [
              _settingsTile(
                icon: Icons.lock_outline_rounded,
                iconColor: const Color(0xFF1677FF),
                title: "Change Password",
                subtitle: "Update account authentication credentials",
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                onTap: _showChangePasswordDialog,
              ),
              _divider(),
              _settingsTile(
                icon: Icons.star_rate_rounded,
                iconColor: Colors.amber,
                title: "Rate Diagnostic Experience",
                subtitle: "Leave feedback for our center",
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                onTap: _showFeedbackDialog,
              ),
              _divider(),
              _settingsTile(
                icon: Icons.delete_outline_rounded,
                iconColor: Colors.red,
                title: "Delete Account",
                subtitle: "Request deletion of patient account data",
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                onTap: _showDeleteAccountDialog,
              ),
            ],
          ),

          const SizedBox(height: 25),

          // STAFF & ADMINISTRATION
          _sectionTitle("Staff & Administration"),
          _settingsCard(
            children: [
              _settingsTile(
                icon: Icons.admin_panel_settings_rounded,
                iconColor: const Color(0xFF1677FF),
                title: "Staff & Admin Portal",
                subtitle: "Authorized diagnostic center management login",
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const admin_login.LoginScreen(isFromUserApp: true),
                    ),
                  );
                },
              ),
            ],
          ),

          const SizedBox(height: 25),

          // LEGAL & ABOUT
          _sectionTitle("Legal & About"),
          _settingsCard(
            children: [
              _settingsTile(
                icon: Icons.description_outlined,
                iconColor: const Color(0xFF1677FF),
                title: "Terms & Conditions",
                subtitle: "Center service agreements and policies",
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                onTap: _showTermsDialog,
              ),
              _divider(),
              _settingsTile(
                icon: Icons.privacy_tip_outlined,
                iconColor: const Color(0xFF18A999),
                title: "Privacy & Security Policy",
                subtitle: "Patient health data confidentiality",
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                onTap: _showPrivacyDialog,
              ),
              _divider(),
              _settingsTile(
                icon: Icons.info_outline_rounded,
                iconColor: const Color(0xFF18C8C8),
                title: "About Aakriti Ultrasound",
                subtitle: "Diagnostic centre accreditation and details",
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                onTap: _showAboutDialog,
              ),
            ],
          ),

          const SizedBox(height: 25),

          // ADMINISTRATIVE PORTAL
          _sectionTitle("Administrative Portal"),
          _settingsCard(
            children: [
              _settingsTile(
                icon: Icons.admin_panel_settings_rounded,
                iconColor: const Color(0xFF0284C7),
                title: "Diagnostic Admin Panel",
                subtitle: "Staff & Management Dashboard (Restricted)",
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0284C7).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF0284C7).withValues(alpha: 0.3)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.lock_rounded, size: 12, color: Color(0xFF0284C7)),
                      SizedBox(width: 4),
                      Text(
                        "Staff Only",
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0284C7),
                        ),
                      ),
                    ],
                  ),
                ),
                onTap: _openAdminPanel,
              ),
            ],
          ),

          const SizedBox(height: 30),

          // APP VERSION FOOTER
          Center(
            child: Column(
              children: [
                const Icon(
                  Icons.local_hospital_rounded,
                  color: Color(0xFF1677FF),
                  size: 28,
                ),
                const SizedBox(height: 8),
                const Text(
                  "AAKRITI ULTRASOUND & DIAGNOSTIC",
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Production Version 1.0.0",
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                ),
              ],
            ),
          ),

          const SizedBox(height: 25),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 10),
      child: Text(
        title,
        style: TextStyle(
          color: Theme.of(context).textTheme.bodySmall?.color,
          fontSize: 13,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _settingsCard({required List<Widget> children}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE8EEF5),
        ),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.035),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _settingsTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
      leading: Container(
        height: 44,
        width: 44,
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon, color: iconColor, size: 22),
      ),
      title: Text(
        title,
        style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 3),
        child: Text(
          subtitle,
          style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
        ),
      ),
      trailing: trailing,
      onTap: onTap,
    );
  }

  Widget _divider() {
    return Divider(
      height: 1,
      indent: 74,
      endIndent: 16,
      color: Colors.grey.withValues(alpha: 0.10),
    );
  }
}
