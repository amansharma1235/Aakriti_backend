import 'package:flutter/material.dart';
import 'package:aakriti_ultrasound/admin/services/communication_service.dart';
import 'package:aakriti_ultrasound/admin/theme/app_colors.dart';
import 'package:aakriti_ultrasound/admin/theme/app_theme.dart';
import 'package:aakriti_ultrasound/admin/widgets/patient_qr_pass_modal.dart';

class PatientDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> patientData;

  const PatientDetailsScreen({
    super.key,
    required this.patientData,
  });

  @override
  State<PatientDetailsScreen> createState() => _PatientDetailsScreenState();
}

class _PatientDetailsScreenState extends State<PatientDetailsScreen> {
  late Map<String, dynamic> _patient;

  @override
  void initState() {
    super.initState();
    _patient = Map<String, dynamic>.from(widget.patientData);
  }

  void _showQrPassModal() {
    PatientQrPassModal.show(context, {
      'patient_id': _patient['patient_id'] ?? _patient['id'] ?? 'AKR001',
      'patient_name': _patient['full_name'] ?? _patient['name'] ?? 'Patient',
      'mobile': _patient['mobile'] ?? '9519701963',
      'service': 'Ultrasound Whole Abdomen',
      'doctor': 'Dr. S. K. Sharma',
      'status': 'Active',
      'payment_status': 'Paid',
    });
  }

  void _openWhatsApp() {
    final name = _patient['full_name'] ?? _patient['name'] ?? 'Patient';
    final uhid = _patient['patient_id'] ?? _patient['id'] ?? 'AKR';
    final mobile = _patient['mobile'] ?? '9519701963';

    final message = '''🏥 *AAKRITI ULTRASOUND & DIAGNOSTIC CENTER*
Dear *$name* (UHID: $uhid, Mobile: $mobile),
Thank you for visiting Aakriti Ultrasound & Diagnostic Center.
For your test reports, appointments, or medical queries, feel free to contact our helpline at +91 9519701963.
Wish you a quick recovery!''';

    CommunicationService.shareMessage(message, subject: 'Aakriti Diagnostic Center');
  }

  @override
  Widget build(BuildContext context) {
    final name = _patient['full_name'] ?? _patient['name'] ?? 'Unknown Patient';
    final id = _patient['patient_id'] ?? _patient['id'] ?? 'AKR001';
    final age = _patient['age']?.toString() ?? '28';
    final gender = _patient['gender'] ?? 'Male';
    final mobile = _patient['mobile'] ?? '9519701963';
    final bloodGroup = _patient['blood_group'] ?? 'O+';
    final address = _patient['address'] ?? 'Lar, Deoria';
    final email = _patient['email'] ?? 'patient@example.com';
    final status = _patient['status'] ?? 'Active';

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg(context),
      appBar: AppBar(
        title: Text(
          'Patient Profile #$id',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.textPrimary(context)),
          overflow: TextOverflow.ellipsis,
        ),
        backgroundColor: AppTheme.cardBg(context),
        foregroundColor: AppTheme.textPrimary(context),
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Patient QR Card',
            onPressed: _showQrPassModal,
            icon: Icon(Icons.qr_code_2_rounded, color: isDark ? const Color(0xFF38BDF8) : AppColors.primaryDarkBlue),
          ),
          IconButton(
            tooltip: 'WhatsApp Msg',
            onPressed: _openWhatsApp,
            icon: const Icon(Icons.mark_chat_unread_rounded, color: Color(0xFF25D366)),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Profile Card
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppTheme.cardBg(context),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.border(context)),
                    boxShadow: AppTheme.subtleShadow,
                  ),
                  child: Column(
                    children: [
                      // Patient Info Row
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 28,
                            backgroundColor: AppColors.accentTeal.withValues(alpha: 0.12),
                            child: Text(
                              name.isNotEmpty ? name[0].toUpperCase() : 'P',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: AppColors.accentTeal,
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Wrap(
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  spacing: 8,
                                  runSpacing: 4,
                                  children: [
                                    Text(
                                      name,
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.textPrimary(context),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: isDark ? const Color(0xFF064E3B) : AppColors.successBg,
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Text(
                                        status,
                                        style: TextStyle(
                                          color: isDark ? const Color(0xFF34D399) : AppColors.success,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  'UHID: $id • $gender • $age Years • Blood: $bloodGroup',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    color: AppTheme.textSecondary(context),
                                    height: 1.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      // Action Buttons Row
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: isDark ? const Color(0xFF38BDF8) : AppColors.primaryDarkBlue,
                                side: BorderSide(color: isDark ? const Color(0xFF38BDF8) : AppColors.primaryDarkBlue),
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              onPressed: _showQrPassModal,
                              icon: const Icon(Icons.qr_code_rounded, size: 16),
                              label: const Text('QR Pass', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF25D366),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              onPressed: _openWhatsApp,
                              icon: const Icon(Icons.send_rounded, size: 16),
                              label: const Text('WhatsApp', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Divider(height: 1, color: AppTheme.divider(context)),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 20,
                        runSpacing: 10,
                        children: [
                          _buildMetaItem(context, 'Phone Number', '+91 $mobile', Icons.phone_rounded),
                          _buildMetaItem(context, 'Email Address', email, Icons.email_rounded),
                          _buildMetaItem(context, 'Address / City', address, Icons.location_on_rounded),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                // Recent Diagnostics History
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppTheme.cardBg(context),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.border(context)),
                    boxShadow: AppTheme.subtleShadow,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.history_rounded, color: AppColors.accentTeal, size: 22),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Diagnostic Investigations History',
                              style: TextStyle(
                                fontSize: 15.5,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary(context),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      _buildVisitItem(context, 'Ultrasound Whole Abdomen', '18 Sep 2026', 'Dr. S. K. Sharma', 'Ready', AppColors.success),
                      _buildVisitItem(context, 'Blood Routine & CBC Profile', '12 Aug 2026', 'Dr. S. K. Sharma', 'Delivered', isDark ? const Color(0xFF60A5FA) : AppColors.primaryDarkBlue),
                      _buildVisitItem(context, 'Thyroid Profile (T3, T4, TSH)', '02 Jun 2026', 'Dr. Verma', 'Delivered', isDark ? const Color(0xFF60A5FA) : AppColors.primaryDarkBlue),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetaItem(BuildContext context, String label, String value, IconData icon) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: AppColors.accentTeal),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 11, color: AppTheme.textSecondary(context))),
            const SizedBox(height: 2),
            Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textPrimary(context))),
          ],
        ),
      ],
    );
  }

  Widget _buildVisitItem(BuildContext context, String test, String date, String doctor, String status, Color statusColor) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkInputFill : AppColors.lightScaffold,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.border(context)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.medical_information_rounded, size: 18, color: AppColors.accentTeal),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  test,
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textPrimary(context)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '$date • $doctor',
                  style: TextStyle(fontSize: 11.5, color: AppTheme.textSecondary(context)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: isDark ? 0.2 : 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              status,
              style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
