import 'package:flutter/material.dart';

import 'appointment_screen.dart';
import 'support_screen.dart';

class ScanDetailScreen extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;

  const ScanDetailScreen({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  static const Color navy = Color(0xFF071A2B);
  static const Color blue = Color(0xFF1677FF);
  static const Color teal = Color(0xFF18C8C8);

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color bgColor = Theme.of(context).scaffoldBackgroundColor;
    final Color cardColor = Theme.of(context).cardColor;
    final Color primaryText = isDark ? Colors.white : navy;
    final Color secondaryText = isDark ? Colors.white70 : Colors.grey.shade600;
    final Color borderColor = isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE8EEF5);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: navy,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, size: 26),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Scan Details",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // HERO CARD
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      navy,
                      color.withValues(alpha: 0.75),
                      const Color(0xFF087F91),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(26),
                  boxShadow: [
                    BoxShadow(
                      color: navy.withValues(alpha: 0.22),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 64,
                      width: 64,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Icon(icon, color: Colors.white, size: 34),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: teal.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        "AAKRITI ULTRASOUND",
                        style: TextStyle(
                          color: teal,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 26),

              Text(
                "About This Scan",
                style: TextStyle(
                  color: primaryText,
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              _infoCard(
                icon: Icons.info_outline_rounded,
                title: "Clinical Purpose",
                text: "This ultrasound examination provides detailed diagnostic imaging with real-time digital sonography. It is evaluated by our consulting Radiologists for high diagnostic accuracy.",
                color: blue,
                cardColor: cardColor,
                primaryText: primaryText,
                secondaryText: secondaryText,
                borderColor: borderColor,
                isDark: isDark,
              ),

              const SizedBox(height: 22),

              Text(
                "What It Examines",
                style: TextStyle(
                  color: primaryText,
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              _checkItem("High-resolution organ tissue evaluation", Icons.medical_information_rounded, cardColor, primaryText, borderColor, isDark),
              _checkItem("Anatomical structures & vascular blood flow", Icons.accessibility_new_rounded, cardColor, primaryText, borderColor, isDark),
              _checkItem("Specific parameters as indicated by referring doctor", Icons.health_and_safety_rounded, cardColor, primaryText, borderColor, isDark),

              const SizedBox(height: 22),

              Text(
                "Patient Preparation",
                style: TextStyle(
                  color: primaryText,
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              _infoCard(
                icon: Icons.restaurant_rounded,
                title: "Preparation Guidelines",
                text: "For abdominal ultrasound, 6-8 hours fasting is advised. For pelvic or urinary ultrasound, drinking 4-5 glasses of water 1 hour prior to scan is recommended for full bladder.",
                color: const Color(0xFFFF8A00),
                cardColor: cardColor,
                primaryText: primaryText,
                secondaryText: secondaryText,
                borderColor: borderColor,
                isDark: isDark,
              ),

              const SizedBox(height: 22),

              Text(
                "Quick Information",
                style: TextStyle(
                  color: primaryText,
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _quickInfo(
                      icon: Icons.access_time_rounded,
                      title: "Duration",
                      value: "15-25 Mins",
                      cardColor: cardColor,
                      primaryText: primaryText,
                      secondaryText: secondaryText,
                      borderColor: borderColor,
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _quickInfo(
                      icon: Icons.description_rounded,
                      title: "Report",
                      value: "Same Day / 30m",
                      cardColor: cardColor,
                      primaryText: primaryText,
                      secondaryText: secondaryText,
                      borderColor: borderColor,
                      isDark: isDark,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              // BOOK BUTTON
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AppointmentScreen(scanName: title),
                      ),
                    );
                  },
                  icon: const Icon(Icons.calendar_month_rounded, size: 20),
                  label: const Text(
                    "Book Scan Appointment",
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: blue,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // CONTACT BUTTON
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const SupportScreen()),
                    );
                  },
                  icon: const Icon(Icons.phone_in_talk_rounded, size: 18),
                  label: const Text(
                    "Contact Aakriti Diagnostic Helpdesk",
                    style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: blue,
                    side: const BorderSide(color: blue),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoCard({
    required IconData icon,
    required String title,
    required String text,
    required Color color,
    required Color cardColor,
    required Color primaryText,
    required Color secondaryText,
    required Color borderColor,
    required bool isDark,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.035),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 44,
            width: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: primaryText,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  text,
                  style: TextStyle(
                    color: secondaryText,
                    fontSize: 12.5,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _checkItem(
    String text,
    IconData icon,
    Color cardColor,
    Color primaryText,
    Color borderColor,
    bool isDark,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Icon(icon, color: teal, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: primaryText,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _quickInfo({
    required IconData icon,
    required String title,
    required String value,
    required Color cardColor,
    required Color primaryText,
    required Color secondaryText,
    required Color borderColor,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Icon(icon, color: blue, size: 22),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(color: secondaryText, fontSize: 11)),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  color: primaryText,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
