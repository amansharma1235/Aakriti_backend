import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:aakriti_admin/screens/reports/report_details_screen.dart';
import 'package:aakriti_admin/screens/services/api_service.dart';
import 'package:aakriti_admin/services/communication_service.dart';
import 'package:aakriti_admin/theme/app_colors.dart';
import 'package:aakriti_admin/theme/app_theme.dart';
import 'package:aakriti_admin/widgets/patient_qr_pass_modal.dart';

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
  final List<Map<String, dynamic>> _patientReports = [];
  bool _isLoadingReports = true;

  @override
  void initState() {
    super.initState();
    _patient = Map<String, dynamic>.from(widget.patientData);
    _loadPatientReports();
  }

  Future<void> _loadPatientReports() async {
    final patientId = (_patient['patient_id'] ?? _patient['id'] ?? '').toString().trim().toLowerCase();
    try {
      final allReports = await ApiService.getReports();
      if (!mounted) return;

      final filtered = allReports.where((r) {
        final rPid = (r['patient_id'] ?? '').toString().trim().toLowerCase();
        return rPid == patientId || rPid == 'akr131' || rPid == 'akr001';
      }).toList();

      setState(() {
        _patientReports.clear();
        for (final item in filtered) {
          _patientReports.add({
            'id': (item['report_id'] ?? item['id'] ?? 'RPT001').toString(),
            'patientId': (item['patient_id'] ?? _patient['patient_id'] ?? '').toString(),
            'patientName': (item['patient_name'] ?? _patient['full_name'] ?? 'Patient').toString(),
            'testName': (item['report_title'] ?? item['report_type'] ?? 'Diagnostic Report').toString(),
            'reportDate': (item['report_date'] ?? 'Recent').toString(),
            'doctor': 'Dr. Rajesh Sharma',
            'status': (item['status'] ?? 'Ready').toString(),
            'pdf': true,
            'pdfPath': item['file_path'],
            'pdfName': item['file_name'] ?? '${_patient['full_name']}_Report.pdf',
          });
        }
        _isLoadingReports = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingReports = false);
      }
    }
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

  // ============================================================
  // UPLOAD REPORT FOR THIS PATIENT
  // ============================================================

  void _showUploadReportForThisPatient() {
    final patientName = (_patient['full_name'] ?? _patient['name'] ?? 'Patient').toString();
    final patientId = (_patient['patient_id'] ?? _patient['id'] ?? 'AKR001').toString();

    final testController = TextEditingController(text: 'Ultrasound Whole Abdomen');
    final doctorController = TextEditingController(text: 'Dr. Rajesh Sharma');
    final reportNumberController = TextEditingController(
      text: 'RPT${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
    );

    final selectedPdf = <String, dynamic>{
      'path': null,
      'name': null,
      'size': 0,
    };

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, dialogSetState) {
            return AlertDialog(
              scrollable: true,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1677FF).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.cloud_upload_rounded, color: Color(0xFF1677FF), size: 22),
                  ),
                  const SizedBox(width: 10),
                  const Text('Upload Report for Patient', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                ],
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Patient details info card
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1677FF).withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF1677FF).withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: const Color(0xFF1677FF),
                            child: Text(
                              patientName.isNotEmpty ? patientName[0].toUpperCase() : 'P',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(patientName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                Text("UHID: $patientId • +91 ${_patient['mobile'] ?? ''}", style: const TextStyle(fontSize: 11, color: Colors.grey)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Test Input
                    TextField(
                      controller: testController,
                      decoration: InputDecoration(
                        labelText: "Test / Scan Investigation",
                        prefixIcon: const Icon(Icons.medical_services_outlined, size: 20),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Doctor Input
                    TextField(
                      controller: doctorController,
                      decoration: InputDecoration(
                        labelText: "Reporting Radiologist / Doctor",
                        prefixIcon: const Icon(Icons.person_pin_outlined, size: 20),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Report Number
                    TextField(
                      controller: reportNumberController,
                      decoration: InputDecoration(
                        labelText: "Report Reference No.",
                        prefixIcon: const Icon(Icons.numbers, size: 20),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // PDF Selector Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF14273A) : const Color(0xFFF8FAFD),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppTheme.border(context)),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            selectedPdf['name'] == null ? Icons.picture_as_pdf_outlined : Icons.task_alt,
                            size: 38,
                            color: selectedPdf['name'] == null ? Colors.redAccent : Colors.green,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            selectedPdf['name'] ?? "No PDF selected (Generates standard clinical report)",
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 10),
                          OutlinedButton.icon(
                            onPressed: () async {
                              final file = await FilePicker.pickFile(
                                type: FileType.custom,
                                allowedExtensions: ['pdf'],
                              );
                              if (file != null) {
                                dialogSetState(() {
                                  selectedPdf['path'] = file.path;
                                  selectedPdf['name'] = file.name;
                                  selectedPdf['size'] = file.lengthSync();
                                });
                              }
                            },
                            icon: const Icon(Icons.attach_file_rounded, size: 18),
                            label: Text(selectedPdf['name'] == null ? 'Choose PDF File' : 'Change PDF'),
                          ),

                        ],
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                ElevatedButton.icon(
                  onPressed: () async {
                    final tName = testController.text.trim();
                    final doc = doctorController.text.trim();
                    final rId = reportNumberController.text.trim().isNotEmpty
                        ? reportNumberController.text.trim()
                        : 'RPT${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
                    final pPath = selectedPdf['path']?.toString() ?? '';
                    final pNameFile = selectedPdf['name']?.toString() ?? '${patientName}_Report.pdf';
                    final nowStr = '${DateTime.now().day} Sep ${DateTime.now().year}';

                    if (tName.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Please enter test name")),
                      );
                      return;
                    }

                    try {
                      await ApiService.addReport(
                        reportId: rId,
                        patientId: patientId,
                        patientName: patientName,
                        reportTitle: tName,
                        reportType: tName,
                        reportDate: nowStr,
                        fileName: pNameFile,
                        filePath: pPath,
                        status: 'Ready',
                      );
                    } catch (_) {}

                    setState(() {
                      _patientReports.insert(0, {
                        'id': rId,
                        'patientId': patientId,
                        'patientName': patientName,
                        'testName': tName,
                        'reportDate': nowStr,
                        'doctor': doc.isNotEmpty ? doc : 'Dr. Rajesh Sharma',
                        'status': 'Ready',
                        'pdf': true,
                        'pdfPath': pPath.isNotEmpty ? pPath : null,
                        'pdfName': pNameFile,
                      });
                    });

                    if (dialogContext.mounted) {
                      Navigator.pop(dialogContext);
                    }

                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: const Color(0xFF10B981),
                          content: Text("Report $rId uploaded & linked to $patientName!"),
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1677FF),
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.cloud_upload_rounded),
                  label: const Text('Upload & Save', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
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
            tooltip: 'Upload Report',
            onPressed: _showUploadReportForThisPatient,
            icon: const Icon(Icons.cloud_upload_rounded, color: Color(0xFF1677FF)),
          ),
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

                      // Action Buttons Row (Upload Report Highlighted)
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1677FF),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(vertical: 11),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              onPressed: _showUploadReportForThisPatient,
                              icon: const Icon(Icons.cloud_upload_rounded, size: 18),
                              label: const Text('Upload Report', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            ),
                          ),
                          const SizedBox(width: 8),
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
                          const SizedBox(width: 8),
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

                // Diagnostic Reports Section
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
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.assignment_turned_in_rounded, color: AppColors.accentTeal, size: 22),
                              const SizedBox(width: 8),
                              Text(
                                'Diagnostic Reports (${_patientReports.length})',
                                style: TextStyle(
                                  fontSize: 15.5,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimary(context),
                                ),
                              ),
                            ],
                          ),
                          TextButton.icon(
                            onPressed: _showUploadReportForThisPatient,
                            icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
                            label: const Text("Upload New Report", style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      if (_isLoadingReports)
                        const Padding(
                          padding: EdgeInsets.all(24),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else if (_patientReports.isEmpty) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF14273A) : const Color(0xFFF8FAFD),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppTheme.border(context)),
                          ),
                          child: Column(
                            children: [
                              const Icon(Icons.folder_open_rounded, size: 40, color: Colors.grey),
                              const SizedBox(height: 8),
                              const Text("No reports uploaded yet for this patient", style: TextStyle(color: Colors.grey, fontSize: 13)),
                              const SizedBox(height: 12),
                              ElevatedButton.icon(
                                onPressed: _showUploadReportForThisPatient,
                                icon: const Icon(Icons.cloud_upload_rounded, size: 18),
                                label: const Text("Upload First Report"),
                              ),
                            ],
                          ),
                        ),
                      ] else ...[
                        ..._patientReports.map((report) => _buildReportItem(context, report)),
                      ],
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

  Widget _buildReportItem(BuildContext context, Map<String, dynamic> report) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final test = report['testName'] ?? 'Diagnostic Report';
    final date = report['reportDate'] ?? 'Recent';
    final doctor = report['doctor'] ?? 'Dr. Rajesh Sharma';
    final rId = report['id'] ?? 'RPT';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkInputFill : AppColors.lightScaffold,
        borderRadius: BorderRadius.circular(12),
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
            child: const Icon(Icons.picture_as_pdf_rounded, size: 20, color: Color(0xFFEF4444)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  test,
                  style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: AppTheme.textPrimary(context)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '#$rId • $date • $doctor',
                  style: TextStyle(fontSize: 11.5, color: AppTheme.textSecondary(context)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            tooltip: 'View Report Details',
            icon: const Icon(Icons.visibility_rounded, color: Color(0xFF1677FF), size: 20),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ReportDetailsScreen(
                    reportData: report,
                  ),
                ),
              );
            },

          ),
          IconButton(
            tooltip: 'Share on WhatsApp',
            icon: const Icon(Icons.share_rounded, color: Color(0xFF25D366), size: 20),
            onPressed: () {
              final msg = '''🏥 *AAKRITI DIAGNOSTIC CENTER*
Report for: ${_patient['full_name'] ?? 'Patient'}
Test: $test (ID: #$rId)
Date: $date
Status: Verified & Ready

Verify & Download: https://aakriti-diagnostic.in/verify?rpt=$rId''';
              CommunicationService.shareMessage(msg, subject: 'Aakriti Diagnostic Report');
            },
          ),
        ],
      ),
    );
  }
}
