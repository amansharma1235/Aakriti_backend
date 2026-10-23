import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../widgets/whatsapp_logo.dart';

class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  static const Color navy = Color(0xFF071A2B);
  static const Color blue = Color(0xFF1677FF);
  static const Color teal = Color(0xFF18C8C8);

  static const String centerPhone = "+919519701963";
  static const String centerWhatsApp = "919519701963";
  static const String centerAddress = "Near CHC Hospital, Lar, Salempur, Deoria District, Uttar Pradesh 274502";
  static const String mapsUrl = "https://www.google.com/maps/search/?api=1&query=Community+Health+Center+Lar+Salempur+Deoria+Uttar+Pradesh";

  Future<void> _callCenter(BuildContext context) async {
    final uri = Uri.parse("tel:$centerPhone");
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        if (context.mounted) _showFallback(context, "Call Center: $centerPhone");
      }
    } catch (_) {
      if (context.mounted) _showFallback(context, "Call Center: $centerPhone");
    }
  }

  Future<void> _openWhatsApp(BuildContext context) async {
    final uri = Uri.parse("https://wa.me/$centerWhatsApp?text=Hello%20Aakriti%20Ultrasound%20Support");
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) _showFallback(context, "WhatsApp Support: +$centerWhatsApp");
      }
    } catch (_) {
      if (context.mounted) _showFallback(context, "WhatsApp Support: +$centerWhatsApp");
    }
  }

  Future<void> _openDirections(BuildContext context) async {
    final uri = Uri.parse(mapsUrl);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) _showFallback(context, "Address: $centerAddress");
      }
    } catch (_) {
      if (context.mounted) _showFallback(context, "Address: $centerAddress");
    }
  }

  void _showFallback(BuildContext context, String text) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

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
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Help & Support",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(18),
        children: [
          // Emergency Header Card
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [navy, Color(0xFF0F3E61), Color(0xFF136894)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: navy.withValues(alpha: 0.25),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
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
                        color: Colors.redAccent.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.emergency_rounded, color: Colors.redAccent, size: 26),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "24/7 Diagnostic Helpline",
                            style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            "We're here to assist your medical queries.",
                            style: TextStyle(color: Colors.white70, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _callCenter(context),
                        icon: const Icon(Icons.phone_in_talk_rounded, size: 18),
                        label: const Text("Call: 9519701963"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _openWhatsApp(context),
                        icon: const WhatsAppLogo(size: 18, color: Colors.white),
                        label: const Text("WhatsApp"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF25D366),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Diagnostic Center Details
          Text(
            "Diagnostic Center Location",
            style: TextStyle(color: primaryText, fontSize: 16, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 12),

          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: borderColor),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.035),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 46,
                      width: 46,
                      decoration: BoxDecoration(
                        color: blue.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.location_on_rounded, color: blue, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Aakriti Ultrasound & Diagnostics",
                            style: TextStyle(color: primaryText, fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            centerAddress,
                            style: TextStyle(color: secondaryText, fontSize: 12, height: 1.4),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: borderColor),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.access_time_filled_rounded, color: teal, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Mon - Sat: 10:00 AM - 04:00 PM",
                              style: TextStyle(color: primaryText, fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              "Sunday: 10:00 AM - 04:00 PM",
                              style: TextStyle(color: secondaryText, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      Builder(
                        builder: (context) {
                          final now = DateTime.now();
                          final bool isOpen = now.hour >= 10 && now.hour < 16;
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: (isOpen ? Colors.green : Colors.red).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              isOpen ? "OPEN NOW" : "CLOSED",
                              style: TextStyle(
                                color: isOpen ? Colors.green : Colors.red,
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _openDirections(context),
                    icon: const Icon(Icons.navigation_rounded, size: 18, color: blue),
                    label: const Text("Get Directions on Google Maps"),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: blue,
                      side: const BorderSide(color: blue),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // FAQs
          Text(
            "Frequently Asked Questions (FAQ)",
            style: TextStyle(color: primaryText, fontSize: 16, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 12),

          _faqItem(
            question: "Is fasting required for Ultrasound Abdomen?",
            answer: "Yes, 6 to 8 hours of fasting is recommended for Upper & Whole Abdomen scans to ensure optimal visualization.",
            cardColor: cardColor,
            primaryText: primaryText,
            secondaryText: secondaryText,
            borderColor: borderColor,
          ),
          _faqItem(
            question: "How long does it take to get test reports?",
            answer: "Most ultrasound reports are prepared within 30-45 minutes. Blood test reports are typically ready within 2-4 hours and downloadable in the Reports section.",
            cardColor: cardColor,
            primaryText: primaryText,
            secondaryText: secondaryText,
            borderColor: borderColor,
          ),
          _faqItem(
            question: "Can I reschedule or cancel my appointment?",
            answer: "Yes, you can easily reschedule or cancel an appointment through the 'My Appointments' tab in the app.",
            cardColor: cardColor,
            primaryText: primaryText,
            secondaryText: secondaryText,
            borderColor: borderColor,
          ),
          _faqItem(
            question: "Are digital reports legally valid?",
            answer: "Yes, all reports downloaded from Aakriti Ultrasound are digitally signed by certified Radiologists & Pathologists with QR verification.",
            cardColor: cardColor,
            primaryText: primaryText,
            secondaryText: secondaryText,
            borderColor: borderColor,
          ),
        ],
      ),
    );
  }

  Widget _faqItem({
    required String question,
    required String answer,
    required Color cardColor,
    required Color primaryText,
    required Color secondaryText,
    required Color borderColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
      ),
      child: ExpansionTile(
        shape: const Border(),
        collapsedShape: const Border(),
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        title: Text(
          question,
          style: TextStyle(color: primaryText, fontSize: 13.5, fontWeight: FontWeight.w600),
        ),
        children: [
          Text(
            answer,
            style: TextStyle(color: secondaryText, fontSize: 12.5, height: 1.4),
          ),
        ],
      ),
    );
  }
}
