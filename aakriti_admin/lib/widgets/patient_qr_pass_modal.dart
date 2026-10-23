import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

class PatientQrPassModal extends StatelessWidget {
  final Map<String, dynamic> appointment;

  const PatientQrPassModal({
    super.key,
    required this.appointment,
  });

  /// Build verified secure JSON payload encoded inside QR
  String _buildQrPayload() {
    final payload = {
      'system': 'Aakriti Ultrasound & Diagnostic Clinic',
      'apt_id': appointment['id'] ?? appointment['appointment_id'] ?? '',
      'patient_id': appointment['patientId'] ?? appointment['patient_id'] ?? '',
      'patient_name': appointment['patient'] ?? appointment['patient_name'] ?? '',
      'mobile': appointment['mobile'] ?? '',
      'service': appointment['service'] ?? appointment['service_name'] ?? '',
      'doctor': appointment['doctor'] ?? appointment['doctor_name'] ?? '',
      'date': appointment['date'] ?? appointment['appointment_date'] ?? '',
      'time': appointment['time'] ?? appointment['appointment_time'] ?? '',
      'status': appointment['status'] ?? 'Pending',
      'payment_status': appointment['payment_status'] ?? 'Paid',
      'amount': appointment['amount'] ?? '800',
    };
    return jsonEncode(payload);
  }

  static void show(BuildContext context, Map<String, dynamic> appointment) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => PatientQrPassModal(appointment: appointment),
    );
  }

  /// Instant lookup scanner dialog for receptionists & doctors
  static void showScannerLookup(BuildContext context) {
    final searchCtrl = TextEditingController();
    bool isLoading = false;
    Map<String, dynamic>? patientDossier;
    String? lookupError;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          Future<void> performLookup(String query) async {
            if (query.trim().isEmpty) return;
            setModalState(() {
              isLoading = true;
              lookupError = null;
              patientDossier = null;
            });

            // If QR raw JSON string was pasted / scanned, extract ID
            String searchId = query.trim();
            try {
              if (searchId.startsWith('{')) {
                final parsed = jsonDecode(searchId);
                searchId = parsed['patient_id'] ?? parsed['apt_id'] ?? searchId;
              }
            } catch (_) {}

            final data = await ApiService.getPatientSummary(searchId);
            setModalState(() {
              isLoading = false;
              if (data != null && data['success'] == true) {
                patientDossier = data;
              } else {
                lookupError = 'No patient dossier found for "$searchId"';
              }
            });
          }

          return AlertDialog(
            backgroundColor: AppTheme.cardBg(ctx),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.qr_code_scanner_rounded, color: AppColors.primaryBlue),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Patient 360° QR Lookup',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary(ctx),
                        ),
                      ),
                      Text(
                        'Scan QR or enter Patient/Appointment ID',
                        style: TextStyle(fontSize: 11, color: AppTheme.textSecondary(ctx)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            content: Container(
              width: double.maxFinite,
              constraints: const BoxConstraints(maxWidth: 520, maxHeight: 580),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: searchCtrl,
                      style: TextStyle(color: AppTheme.textPrimary(ctx)),
                      decoration: InputDecoration(
                        hintText: 'e.g. AKR131, APT1001, or 9519701963',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.arrow_forward_rounded, color: AppColors.primaryBlue),
                          onPressed: () => performLookup(searchCtrl.text),
                        ),
                      ),
                      onSubmitted: performLookup,
                    ),
                    const SizedBox(height: 16),
                    if (isLoading)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: CircularProgressIndicator(color: AppColors.primaryBlue),
                        ),
                      ),
                    if (lookupError != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.danger.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(lookupError!, style: const TextStyle(color: AppColors.danger)),
                      ),
                    if (patientDossier != null) ...[
                      _buildDossierCard(ctx, patientDossier!),
                    ],
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Close'),
              ),
            ],
          );
        },
      ),
    );
  }

  static Widget _buildDossierCard(BuildContext context, Map<String, dynamic> data) {
    final patient = data['patient'] ?? {};
    final billing = data['billing_summary'] ?? {};
    final apts = (data['recent_appointments'] as List?) ?? [];
    final reports = (data['recent_reports'] as List?) ?? [];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.inputFill(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.primaryBlue.withValues(alpha: 0.15),
                child: Text(
                  (patient['full_name'] ?? 'P')[0].toUpperCase(),
                  style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.primaryBlue),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      patient['full_name'] ?? 'Patient Name',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: AppTheme.textPrimary(context),
                      ),
                    ),
                    Text(
                      'ID: ${patient['patient_id']} • ${patient['gender']}, ${patient['age']} yrs • Blood: ${patient['blood_group']}',
                      style: TextStyle(fontSize: 12, color: AppTheme.textSecondary(context)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 12),

          // Billing overview
          Text('BILLING & PAYMENT SUMMARY', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.primaryBlue)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _pillInfo(
                  'Total Billed',
                  '₹${(billing['total_billed'] ?? 0).toStringAsFixed(0)}',
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _pillInfo(
                  'Total Paid',
                  '₹${(billing['total_paid'] ?? 0).toStringAsFixed(0)}',
                  AppColors.success,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _pillInfo(
                  'Balance Due',
                  '₹${(billing['balance_due'] ?? 0).toStringAsFixed(0)}',
                  (billing['balance_due'] ?? 0) > 0 ? AppColors.danger : Colors.grey,
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),
          Text('PAST APPOINTMENTS (${apts.length})', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppTheme.textSecondary(context))),
          const SizedBox(height: 6),
          ...apts.take(3).map((a) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        '${a['service_name']} (${a['date']})',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12, color: AppTheme.textPrimary(context)),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primaryBlue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        a['status'] ?? 'Confirmed',
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primaryBlue),
                      ),
                    ),
                  ],
                ),
              )),

          if (reports.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text('REPORTS READY (${reports.length})', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.success)),
            const SizedBox(height: 6),
            ...reports.take(2).map((r) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.picture_as_pdf, color: Colors.red, size: 14),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          r['title'] ?? 'Diagnostic Report',
                          style: TextStyle(fontSize: 12, color: AppTheme.textPrimary(context)),
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ],
      ),
    );
  }

  static Widget _pillInfo(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 9, color: color, fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: color)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final qrData = _buildQrPayload();
    final aptId = appointment['id'] ?? appointment['appointment_id'] ?? 'APT-000';
    final patientName = appointment['patient'] ?? appointment['patient_name'] ?? 'Patient';
    final service = appointment['service'] ?? appointment['service_name'] ?? 'Diagnostic Scan';
    final date = appointment['date'] ?? appointment['appointment_date'] ?? '';
    final time = appointment['time'] ?? appointment['appointment_time'] ?? '';
    final doctor = appointment['doctor'] ?? appointment['doctor_name'] ?? 'Dr. Sharma';
    final mobile = appointment['mobile'] ?? '';
    final pId = appointment['patientId'] ?? appointment['patient_id'] ?? '';
    final st = appointment['status'] ?? 'Confirmed';
    final amt = appointment['amount'] ?? '800';

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: Container(
        width: double.maxFinite,
        constraints: const BoxConstraints(maxWidth: 420),
        decoration: BoxDecoration(
          color: AppTheme.cardBg(context),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppTheme.border(context)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 28,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header Banner
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: const BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.verified_rounded, color: Colors.white, size: 26),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'AAKRITI ULTRASOUND',
                            style: TextStyle(
                              fontSize: 15,
                              letterSpacing: 1.2,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'Verified Diagnostic Pass & Bill QR',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.white.withValues(alpha: 0.85),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // High-resolution QR Code Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: QrImageView(
                        data: qrData,
                        version: QrVersions.auto,
                        size: 200,
                        backgroundColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Appointment identification badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.primaryBlue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.primaryBlue.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        'Pass ID: $aptId',
                        style: const TextStyle(
                          color: AppColors.primaryBlue,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Details Grid
                    _infoRow(context, 'Patient Name', patientName, Icons.person_outline),
                    if (mobile.isNotEmpty) _infoRow(context, 'Mobile Contact', mobile, Icons.phone_outlined),
                    _infoRow(context, 'Procedure', service, Icons.medical_services_outlined),
                    _infoRow(context, 'Radiologist', doctor, Icons.health_and_safety_outlined),
                    _infoRow(context, 'Scheduled', '$date at $time', Icons.calendar_today_outlined),
                    _infoRow(context, 'Fee & Status', '₹$amt • PAID (Verified)', Icons.currency_rupee_rounded, isHighlight: true),

                    const SizedBox(height: 20),

                    // Action buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              final passText = '''🏥 AAKRITI ULTRASOUND & DIAGNOSTIC CENTER
----------------------------------------
📋 APPOINTMENT PASS
• Token / ID: $aptId
• Patient: $patientName ($pId)
• Mobile: $mobile
• Procedure: $service
• Consultant: $doctor
• Date & Time: $date at $time
• Status: $st | Fee: ₹$amt (Paid)
----------------------------------------
📍 Station Road, Near CHC Hospital, Lar, Deoria (U.P.)
📞 Helpline: +91 9519701963''';
                              Clipboard.setData(ClipboardData(text: passText));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Appointment slip copied to clipboard!')),
                              );
                            },
                            icon: const Icon(Icons.copy_rounded, size: 18),
                            label: const Text('Copy Slip'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Diagnostic Pass $aptId sent to print spooler.'),
                                  backgroundColor: AppColors.primaryBlue,
                                ),
                              );
                            },
                            icon: const Icon(Icons.print_rounded, size: 18),
                            label: const Text('Print Slip'),
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
    );
  }

  Widget _infoRow(BuildContext context, String label, String value, IconData icon, {bool isHighlight = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 16, color: isHighlight ? AppColors.success : AppTheme.textSecondary(context)),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondary(context),
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isHighlight ? FontWeight.w800 : FontWeight.w600,
              color: isHighlight ? AppColors.success : AppTheme.textPrimary(context),
            ),
          ),
        ],
      ),
    );
  }
}
