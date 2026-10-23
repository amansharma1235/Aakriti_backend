import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:aakriti_ultrasound/admin/services/communication_service.dart';
import 'package:aakriti_ultrasound/admin/services/pdf_report_service.dart';
import 'package:aakriti_ultrasound/admin/theme/app_colors.dart';

class ReportDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> reportData;

  const ReportDetailsScreen({
    super.key,
    required this.reportData,
  });

  @override
  State<ReportDetailsScreen> createState() => _ReportDetailsScreenState();
}

class _ReportDetailsScreenState extends State<ReportDetailsScreen> {
  late Map<String, dynamic> _report;
  bool _isGeneratingPdf = false;

  @override
  void initState() {
    super.initState();
    _report = Map<String, dynamic>.from(widget.reportData);
  }

  Future<void> _handlePrintOrPreviewPdf() async {
    setState(() => _isGeneratingPdf = true);
    try {
      final Uint8List pdfBytes = await PdfReportService.generateMedicalReportPdf(
        reportId: _report['id'] ?? 'RPT001',
        patientId: _report['patientId'] ?? 'AKR1001',
        patientName: _report['patientName'] ?? 'Unknown Patient',
        age: _report['age']?.toString() ?? '32',
        gender: _report['gender'] ?? 'Male',
        mobile: _report['mobile'] ?? '9519701963',
        referringDoctor: _report['doctor'] ?? 'Dr. S. K. Sharma',
        testName: _report['testName'] ?? 'Ultrasound Whole Abdomen',
        reportDate: _report['reportDate'] ?? '18 Sep 2026',
        impression: _report['impression'],
      );

      final fileName = '${_report['patientName']}_${_report['testName']}.pdf'
          .replaceAll(' ', '_');
      await PdfReportService.printOrPreviewReport(pdfBytes, fileName);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating PDF: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isGeneratingPdf = false);
    }
  }

  Future<void> _handleSharePdf() async {
    setState(() => _isGeneratingPdf = true);
    try {
      final Uint8List pdfBytes = await PdfReportService.generateMedicalReportPdf(
        reportId: _report['id'] ?? 'RPT001',
        patientId: _report['patientId'] ?? 'AKR1001',
        patientName: _report['patientName'] ?? 'Unknown Patient',
        age: _report['age']?.toString() ?? '32',
        gender: _report['gender'] ?? 'Male',
        mobile: _report['mobile'] ?? '9519701963',
        referringDoctor: _report['doctor'] ?? 'Dr. S. K. Sharma',
        testName: _report['testName'] ?? 'Ultrasound Whole Abdomen',
        reportDate: _report['reportDate'] ?? '18 Sep 2026',
      );

      final fileName = '${_report['patientName']}_${_report['testName']}.pdf'
          .replaceAll(' ', '_');
      await PdfReportService.sharePdf(pdfBytes, fileName);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sharing PDF: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isGeneratingPdf = false);
    }
  }

  void _showWhatsAppDispatchDialog() {
    final patientName = _report['patientName'] ?? 'Patient';
    final reportId = _report['id'] ?? 'RPT001';
    final testName = _report['testName'] ?? 'Ultrasound';
    final date = _report['reportDate'] ?? '18 Sep 2026';
    final mobile = _report['mobile'] ?? '9519701963';

    final message = CommunicationService.buildReportReadyWhatsAppMessage(
      patientName: patientName,
      reportId: reportId,
      testName: testName,
      date: date,
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF25D366).withValues(alpha:0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.send_rounded, color: Color(0xFF25D366), size: 22),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'WhatsApp Report',
                style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.bold),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 380,
            maxHeight: MediaQuery.of(context).size.height * 0.42,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Recipient: $patientName (+91 $mobile)',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.lightTextSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFBBF7D0)),
                  ),
                  child: Text(
                    message,
                    style: const TextStyle(fontSize: 12, height: 1.4, fontFamily: 'monospace', color: Colors.black87),
                  ),
                ),
              ],
            ),
          ),
        ),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          OutlinedButton.icon(
            onPressed: () {
              CommunicationService.copyToClipboard(message);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('WhatsApp message template copied to clipboard!'),
                  backgroundColor: AppColors.accentTeal,
                ),
              );
            },
            icon: const Icon(Icons.copy_rounded, size: 15),
            label: const Text('Copy'),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF25D366),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              CommunicationService.shareMessage(message, subject: 'Aakriti Diagnostic Report Ready');
              Navigator.pop(ctx);
            },
            icon: const Icon(Icons.share_rounded, size: 15),
            label: const Text('Dispatch'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final status = _report['status'] ?? 'Pending';
    final isReady = status == 'Ready' || status == 'Delivered';

    Color statusColor;
    Color statusBg;
    if (status == 'Ready') {
      statusColor = AppColors.success;
      statusBg = AppColors.successBg;
    } else if (status == 'Delivered') {
      statusColor = AppColors.primaryDarkBlue;
      statusBg = AppColors.primaryBlue.withValues(alpha:0.12);
    } else {
      statusColor = AppColors.warning;
      statusBg = AppColors.warningBg;
    }

    return Scaffold(
      backgroundColor: AppColors.lightScaffold,
      appBar: AppBar(
        title: Text(
          'Report #${_report['id'] ?? 'RPT'}',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: AppColors.primaryDarkBlue,
        actions: [
          IconButton(
            tooltip: 'Send on WhatsApp',
            onPressed: _showWhatsAppDispatchDialog,
            icon: const Icon(Icons.mark_chat_unread_rounded, color: Color(0xFF25D366)),
          ),
          IconButton(
            tooltip: 'Share Report',
            onPressed: _isGeneratingPdf ? null : _handleSharePdf,
            icon: const Icon(Icons.share_outlined, color: AppColors.primaryDarkBlue),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Header Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha:0.04),
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
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: AppColors.accentTeal.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.assignment_turned_in_rounded,
                              color: AppColors.accentTeal,
                              size: 26,
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
                                      _report['patientName'] ?? 'Unknown Patient',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.lightTextPrimary,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: statusBg,
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                                      ),
                                      child: Text(
                                        status,
                                        style: TextStyle(
                                          color: statusColor,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  'Patient ID: ${_report['patientId'] ?? 'N/A'} • Investigation: ${_report['testName'] ?? 'Ultrasound'}',
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    color: AppColors.lightTextSecondary,
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
                                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                                side: const BorderSide(color: Color(0xFF25D366)),
                                foregroundColor: const Color(0xFF15803D),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              onPressed: _showWhatsAppDispatchDialog,
                              icon: const Icon(Icons.send_rounded, size: 16),
                              label: const FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text('WhatsApp Alert', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.accentTeal,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              onPressed: _isGeneratingPdf ? null : _handlePrintOrPreviewPdf,
                              icon: _isGeneratingPdf
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                    )
                                  : const Icon(Icons.print_rounded, size: 17),
                              label: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  _isGeneratingPdf ? 'Generating...' : 'Print / Preview PDF',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      const Divider(height: 1),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 20,
                        runSpacing: 10,
                        children: [
                          _buildDetailItem('Exam Date', _report['reportDate'] ?? '18 Sep 2026', Icons.calendar_today_rounded),
                          _buildDetailItem('Referring Doctor', _report['doctor'] ?? 'Dr. S. K. Sharma', Icons.person_pin_rounded),
                          _buildDetailItem('Modality', 'Ultrasound / Color Doppler', Icons.medical_services_rounded),
                          _buildDetailItem('PDF Generated', isReady ? 'Yes (NABH Standard)' : 'Pending Verification', Icons.picture_as_pdf_rounded),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Clinical Findings Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha:0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.biotech_rounded, color: AppColors.accentTeal, size: 22),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Sonographic Findings & Observations',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.lightTextPrimary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          TextButton.icon(
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Report observation templates are synced.')),
                              );
                            },
                            icon: const Icon(Icons.edit_note_rounded, size: 16),
                            label: const Text('Edit', style: TextStyle(fontSize: 12)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      _buildFindingItem('LIVER', 'Normal in size (13.4 cm), shape and acoustic texture. No focal lesion or IHBRD seen.'),
                      _buildFindingItem('GALL BLADDER', 'Well distended. Normal wall thickness. No calculus or sludge identified.'),
                      _buildFindingItem('CBD & PORTAL VEIN', 'Common Bile Duct (4.1 mm) and Portal Vein (9.8 mm) are normal in caliber.'),
                      _buildFindingItem('PANCREAS', 'Normal in size, contour and echogenicity. Main pancreatic duct is normal.'),
                      _buildFindingItem('SPLEEN', 'Normal in size (9.6 cm) and homogenous parenchymal pattern.'),
                      _buildFindingItem('KIDNEYS', 'Both kidneys are normal in size, position and cortical thickness. (Right: 10.2 x 4.4 cm, Left: 10.6 x 4.8 cm). No calculus or hydronephrosis.'),
                      _buildFindingItem('URINARY BLADDER', 'Adequately distended with uniform smooth wall.'),
                      _buildFindingItem('PELVIS / POD', 'No free fluid or mass detected in pouch of Douglas.'),

                      const SizedBox(height: 16),
                      // Impression Box
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0FDF4),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFBBF7D0)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.verified_rounded, color: Color(0xFF15803D), size: 18),
                                SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    'DIAGNOSTIC IMPRESSION / CONCLUSION:',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF15803D),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _report['impression'] ??
                                  '• NO SIGNIFICANT SONOGRAPHIC ABNORMALITY DETECTED IN VISUALIZED ABDOMINAL ORGANS.\n• STUDY IS WITHIN NORMAL PHYSIOLOGICAL LIMITS.',
                              style: const TextStyle(
                                fontSize: 13,
                                height: 1.4,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Bottom Doctor Signature & Stamp Preview (Responsive wrap)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final isNarrow = constraints.maxWidth < 500;
                      if (isNarrow) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryDarkBlue.withValues(alpha:0.08),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(Icons.qr_code_2_rounded, color: AppColors.primaryDarkBlue, size: 32),
                                ),
                                const SizedBox(width: 12),
                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('QR Code Verification Active', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                      SizedBox(height: 2),
                                      Text(
                                        'Patients & Clinicians can verify report online.',
                                        style: TextStyle(fontSize: 11.5, color: AppColors.lightTextSecondary),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            const Divider(height: 1),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _report['doctor'] ?? 'Dr. S. K. Sharma',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                                const Text(
                                  'MD (Radio) • Reg # UP-48920',
                                  style: TextStyle(fontSize: 11, color: AppColors.lightTextSecondary),
                                ),
                              ],
                            ),
                          ],
                        );
                      }
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryDarkBlue.withValues(alpha:0.08),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(Icons.qr_code_2_rounded, color: AppColors.primaryDarkBlue, size: 36),
                                ),
                                const SizedBox(width: 12),
                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('QR Code Verification Active', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                      SizedBox(height: 2),
                                      Text(
                                        'Patients & Clinicians can verify report integrity online.',
                                        style: TextStyle(fontSize: 12, color: AppColors.lightTextSecondary),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                _report['doctor'] ?? 'Dr. S. K. Sharma',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              const Text(
                                'MBBS, MD (Radiodiagnosis) - Reg # UP-48920',
                                style: TextStyle(fontSize: 11, color: AppColors.lightTextSecondary),
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.accentTeal),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 11, color: AppColors.lightTextSecondary)),
            const SizedBox(height: 2),
            Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.lightTextPrimary)),
          ],
        ),
      ],
    );
  }

  Widget _buildFindingItem(String organ, String finding) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 115,
            child: Text(
              organ,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primaryDarkBlue),
            ),
          ),
          Expanded(
            child: Text(
              finding,
              style: const TextStyle(fontSize: 12.5, color: Colors.black87, height: 1.3),
            ),
          ),
        ],
      ),
    );
  }
}
