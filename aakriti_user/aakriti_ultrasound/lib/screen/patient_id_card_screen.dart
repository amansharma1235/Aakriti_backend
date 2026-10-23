import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../services/profile_service.dart';
import 'qr_scanner_screen.dart';

class PatientIdCardScreen extends StatelessWidget {
  const PatientIdCardScreen({super.key});

  static const Color navy = Color(0xFF071A2B);
  static const Color blue = Color(0xFF1677FF);
  static const Color cyan = Color(0xFF18C8C8);

  void _openScanner(BuildContext context) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const QrScannerScreen()),
    );

    if (!context.mounted) return;

    if (result != null && result is String) {
      _showPatientResult(context, result);
    }
  }

  void _showPatientResult(BuildContext context, String result) {
    final parts = result.split('|');

    final patientId = parts.isNotEmpty ? parts[0] : "Unknown";

    final patientName = parts.length > 1 ? parts[1] : "Unknown";

    final age = parts.length > 2 ? parts[2] : "Unknown";

    final gender = parts.length > 3 ? parts[3] : "Unknown";

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: const Row(
            children: [
              Icon(Icons.verified_rounded, color: blue, size: 27),
              SizedBox(width: 8),
              Text(
                "Patient Found",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),

              _dialogLabel("Patient Name"),

              const SizedBox(height: 4),

              Text(
                patientName,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: navy,
                ),
              ),

              const SizedBox(height: 16),

              _dialogLabel("Patient ID"),

              const SizedBox(height: 4),

              Text(
                patientId,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: blue,
                ),
              ),

              const SizedBox(height: 18),

              Row(
                children: [
                  Expanded(child: _scanInfo("Age", age)),
                  Expanded(child: _scanInfo("Gender", gender)),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text(
                "Close",
                style: TextStyle(color: blue, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _dialogLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 12,
        color: Colors.grey.shade600,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _scanInfo(String title, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 11, color: Colors.black54),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: navy,
          ),
        ),
      ],
    );
  }

  void _shareCard(BuildContext context) async {
    final pid = ProfileService.patientIdNotifier.value.trim().isNotEmpty
        ? ProfileService.patientIdNotifier.value.trim()
        : "PT101";
    final name = ProfileService.userNameNotifier.value.trim().isNotEmpty
        ? ProfileService.userNameNotifier.value.trim()
        : "Patient";
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Sharing Patient ID Card for $name ($pid)"),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF1677FF),
      ),
    );
  }

  void _downloadCard(BuildContext context) async {
    final pid = ProfileService.patientIdNotifier.value.trim().isNotEmpty
        ? ProfileService.patientIdNotifier.value.trim()
        : "PT101";
    final name = ProfileService.userNameNotifier.value.trim().isNotEmpty
        ? ProfileService.userNameNotifier.value.trim()
        : "Patient";
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Downloading ID Card for $name ($pid)..."),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF10B981),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String patientName = ProfileService.userNameNotifier.value.trim().isNotEmpty
        ? ProfileService.userNameNotifier.value.trim()
        : "Patient";
    final String patientId = ProfileService.patientIdNotifier.value.trim().isNotEmpty
        ? ProfileService.patientIdNotifier.value.trim()
        : "PT101";
    final String patientAge = ProfileService.userAgeNotifier.value.trim().isNotEmpty
        ? ProfileService.userAgeNotifier.value.trim()
        : "24 Years";

    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color bgColor = Theme.of(context).scaffoldBackgroundColor;
    final Color cardColor = Theme.of(context).cardColor;
    final Color primaryText = isDark ? Colors.white : navy;
    final Color secondaryText = isDark ? Colors.white70 : Colors.grey.shade600;
    final Color borderColor = isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE8EEF5);

    return Scaffold(
      backgroundColor: bgColor,

      appBar: AppBar(
        elevation: 0,
        backgroundColor: navy,
        foregroundColor: Colors.white,
        title: const Text(
          "Patient ID Card",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(18),

          child: Column(
            children: [
              const SizedBox(height: 8),

              // =========================
              // PATIENT ID CARD
              // =========================
              Container(
                width: double.infinity,

                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),

                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF071A2B),
                      Color(0xFF103B62),
                      Color(0xFF1677FF),
                    ],
                  ),

                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 25,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),

                child: Padding(
                  padding: const EdgeInsets.all(22),

                  child: Column(
                    children: [
                      // Header
                      Row(
                        children: [
                          Container(
                            height: 48,
                            width: 48,

                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(15),
                            ),

                            child: const Icon(
                              Icons.local_hospital_rounded,
                              color: Colors.white,
                              size: 27,
                            ),
                          ),

                          const SizedBox(width: 13),

                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "AAKRITI",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 21,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  "ULTRASOUND & DIAGNOSTIC CENTRE",
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),

                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(20),
                            ),

                            child: const Text(
                              "PATIENT",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 28),

                      // Patient Details + QR
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,

                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "PATIENT NAME",
                                  style: TextStyle(
                                    color: Colors.white60,
                                    fontSize: 10,
                                    letterSpacing: 0.8,
                                  ),
                                ),

                                const SizedBox(height: 5),

                                Text(
                                  patientName,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),

                                const SizedBox(height: 18),

                                patientInfo("Patient ID", patientId),

                                const SizedBox(height: 12),

                                Row(
                                  children: [
                                    Expanded(
                                      child: patientInfo("Age", patientAge),
                                    ),
                                    Expanded(
                                      child: patientInfo("Gender", "Self"),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 12),

                                patientInfo("Registered", "2026"),
                              ],
                            ),
                          ),

                          const SizedBox(width: 18),

                          // QR
                          Container(
                            padding: const EdgeInsets.all(8),

                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(18),
                            ),

                            child: QrImageView(
                              data: '$patientId|$patientName|$patientAge|Self',
                              version: QrVersions.auto,
                              size: 125,
                              backgroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      Container(
                        height: 1,
                        color: Colors.white.withValues(alpha: 0.15),
                      ),

                      const SizedBox(height: 15),

                      const Row(
                        children: [
                          Icon(Icons.verified_rounded, color: cyan, size: 18),
                          SizedBox(width: 7),
                          Text(
                            "Verified Patient ID",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Spacer(),
                          Text(
                            "AAKRITI",
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 22),

              // =========================
              // SCAN + SHARE
              // =========================
              Row(
                children: [
                  Expanded(
                    child: _actionButton(
                      icon: Icons.qr_code_scanner_rounded,
                      title: "Scan QR",
                      color: blue,
                      onPressed: () {
                        _openScanner(context);
                      },
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: _actionButton(
                      icon: Icons.share_rounded,
                      title: "Share",
                      color: cyan,
                      onPressed: () {
                        _shareCard(context);
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // =========================
              // DOWNLOAD
              // =========================
              SizedBox(
                width: double.infinity,
                height: 56,

                child: ElevatedButton.icon(
                  onPressed: () {
                    _downloadCard(context);
                  },

                  icon: const Icon(Icons.download_rounded, color: Colors.white),

                  label: const Text(
                    "Download Patient ID Card",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  style: ElevatedButton.styleFrom(
                    backgroundColor: navy,
                    elevation: 0,

                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(17),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 22),

              // =========================
              // INFORMATION CARD
              // =========================
              Container(
                width: double.infinity,

                padding: const EdgeInsets.all(18),

                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(20),

                  border: Border.all(color: borderColor),

                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                      blurRadius: 18,
                      offset: const Offset(0, 7),
                    ),
                  ],
                ),

                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [
                    Row(
                      children: [
                        const Icon(Icons.info_outline_rounded, color: blue, size: 22),
                        const SizedBox(width: 9),
                        Text(
                          "About Patient ID",
                          style: TextStyle(
                            color: primaryText,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    Text(
                      "This digital Patient ID can be used "
                      "for appointment booking, report "
                      "identification and faster registration "
                      "at Aakriti Ultrasound & Diagnostic Centre.",
                      style: TextStyle(
                        color: secondaryText,
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),

                    const SizedBox(height: 15),

                    Container(
                      padding: const EdgeInsets.all(12),

                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0F2B44) : const Color(0xFFF5F8FC),
                        borderRadius: BorderRadius.circular(14),
                      ),

                      child: Row(
                        children: [
                          const Icon(Icons.qr_code_2_rounded, color: blue, size: 25),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              "Show this QR code at the centre "
                              "for quick patient identification.",
                              style: TextStyle(
                                color: primaryText,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              const Text(
                "Keep your Patient ID safe and do not share it publicly.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black45, fontSize: 11),
              ),

              const SizedBox(height: 15),
            ],
          ),
        ),
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      height: 56,

      child: ElevatedButton.icon(
        onPressed: onPressed,

        icon: Icon(icon, color: color, size: 22),

        label: Text(
          title,
          style: const TextStyle(
            color: navy,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),

        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          elevation: 0,

          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(17),
          ),

          side: BorderSide(color: color.withValues(alpha: 0.12)),
        ),
      ),
    );
  }

  Widget patientInfo(String title, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,

      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white60,
            fontSize: 9,
            letterSpacing: 0.6,
          ),
        ),

        const SizedBox(height: 3),

        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
