import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:share_plus/share_plus.dart';
import 'package:aakriti_ultrasound/admin/screens/reports/report_details_screen.dart';
import 'package:aakriti_ultrasound/admin/screens/services/api_service.dart';
import 'package:aakriti_ultrasound/admin/services/pdf_report_service.dart';
import 'package:aakriti_ultrasound/admin/theme/app_theme.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final TextEditingController _searchController = TextEditingController();

  String _statusFilter = 'All';

  final List<Map<String, dynamic>> _reports = [
    {
      'id': 'RPT001',
      'patientId': 'AKR1001',
      'patientName': 'Rahul Kumar',
      'testName': 'Ultrasound Abdomen',
      'reportDate': '18 Sep 2026',
      'doctor': 'Dr. Sharma',
      'status': 'Ready',
      'pdf': true,
      'pdfPath': null,
      'pdfName': 'Rahul_Ultrasound_Abdomen.pdf',
      'pdfSize': 0,
    },
    {
      'id': 'RPT002',
      'patientId': 'AKR1002',
      'patientName': 'Priya Singh',
      'testName': 'Thyroid Profile',
      'reportDate': '18 Sep 2026',
      'doctor': 'Dr. Verma',
      'status': 'Pending',
      'pdf': false,
      'pdfPath': null,
      'pdfName': null,
      'pdfSize': 0,
    },
    {
      'id': 'RPT003',
      'patientId': 'AKR1003',
      'patientName': 'Amit Verma',
      'testName': 'Blood Test',
      'reportDate': '17 Sep 2026',
      'doctor': 'Dr. Sharma',
      'status': 'Ready',
      'pdf': true,
      'pdfPath': null,
      'pdfName': 'Amit_Blood_Test.pdf',
      'pdfSize': 0,
    },
    {
      'id': 'RPT004',
      'patientId': 'AKR1004',
      'patientName': 'Neha Sharma',
      'testName': 'Ultrasound Pelvis',
      'reportDate': '17 Sep 2026',
      'doctor': 'Dr. Verma',
      'status': 'Delivered',
      'pdf': true,
      'pdfPath': null,
      'pdfName': 'Neha_Ultrasound_Pelvis.pdf',
      'pdfSize': 0,
    },
    {
      'id': 'RPT005',
      'patientId': 'AKR1005',
      'patientName': 'Ravi Gupta',
      'testName': 'Sugar Test',
      'reportDate': '16 Sep 2026',
      'doctor': 'Dr. Sharma',
      'status': 'Pending',
      'pdf': false,
      'pdfPath': null,
      'pdfName': null,
      'pdfSize': 0,
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
    try {
      final liveReports = await ApiService.getReports();
      if (liveReports.isNotEmpty && mounted) {
        setState(() {
          _reports.clear();
          for (final r in liveReports) {
            _reports.add({
              'id': (r['report_id'] ?? r['id'] ?? 'RPT001').toString(),
              'patientId': (r['patient_id'] ?? 'AKR1001').toString(),
              'patientName': (r['patient_name'] ?? 'Patient').toString(),
              'testName': (r['report_title'] ?? 'Diagnostic Report').toString(),
              'reportDate': (r['report_date'] ?? 'Recent').toString(),
              'doctor': 'Dr. Rajesh Sharma',
              'status': (r['status'] ?? 'Ready').toString(),
              'pdf': true,
              'pdfPath': r['file_path'],
              'pdfName': r['file_name'] ?? '${r['patient_name']}_Report.pdf',
              'pdfSize': 0,
            });
          }
        });
      }
    } catch (_) {}
  }

  List<Map<String, dynamic>> get _filteredReports {
    final search = _searchController.text.toLowerCase().trim();

    return _reports.where((report) {
      final matchesSearch =
          report['patientName'].toString().toLowerCase().contains(search) ||
          report['patientId'].toString().toLowerCase().contains(search) ||
          report['id'].toString().toLowerCase().contains(search) ||
          report['testName'].toString().toLowerCase().contains(search);

      final matchesStatus =
          _statusFilter == 'All' || report['status'] == _statusFilter;

      return matchesSearch && matchesStatus;
    }).toList();
  }

  int get _totalReports => _reports.length;

  int get _pendingReports =>
      _reports.where((item) => item['status'] == 'Pending').length;

  int get _readyReports =>
      _reports.where((item) => item['status'] == 'Ready').length;

  int get _deliveredReports =>
      _reports.where((item) => item['status'] == 'Delivered').length;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    final isMobile = width < 700;
    final isTablet = width >= 700 && width < 1100;

    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(isMobile),
          const SizedBox(height: 24),
          _buildStats(isMobile, isTablet),
          const SizedBox(height: 24),
          _buildToolbar(isMobile),
          const SizedBox(height: 20),
          isMobile ? _buildMobileReports() : _buildDesktopReports(isTablet),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isMobile) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Reports',
                style: TextStyle(
                  fontSize: isMobile ? 24 : 30,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary(context),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Manage patient reports and PDF documents',
                style: TextStyle(
                  fontSize: isMobile ? 13 : 15,
                  color: AppTheme.textSecondary(context),
                ),
              ),
            ],
          ),
        ),
        if (!isMobile)
          ElevatedButton.icon(
            onPressed: _showUploadReportDialog,
            icon: const Icon(Icons.upload_file),
            label: const Text('Upload Report'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1677FF),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildStats(bool isMobile, bool isTablet) {
    final cards = [
      _statCard(
        'Total Reports',
        _totalReports.toString(),
        Icons.description_outlined,
        const Color(0xFF1677FF),
      ),
      _statCard(
        'Pending',
        _pendingReports.toString(),
        Icons.pending_actions,
        Colors.orange,
      ),
      _statCard(
        'Ready',
        _readyReports.toString(),
        Icons.check_circle_outline,
        Colors.green,
      ),
      _statCard(
        'Delivered',
        _deliveredReports.toString(),
        Icons.done_all,
        Colors.teal,
      ),
    ];

    if (isMobile) {
      return Column(
        children: [
          Row(
            children: [
              Expanded(child: cards[0]),
              const SizedBox(width: 12),
              Expanded(child: cards[1]),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: cards[2]),
              const SizedBox(width: 12),
              Expanded(child: cards[3]),
            ],
          ),
        ],
      );
    }

    return GridView.count(
      crossAxisCount: isTablet ? 2 : 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: isTablet ? 2.4 : 2.1,
      children: cards,
    );
  }

  Widget _statCard(String title, String value, IconData icon, Color iconColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.cardBg(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: Theme.of(context).brightness == Brightness.dark ? 0.2 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            height: 38,
            width: 38,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11, color: AppTheme.textSecondary(context)),
                ),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary(context),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolbar(bool isMobile) {
    if (isMobile) {
      return Column(
        children: [
          Row(
            children: [
              Expanded(child: _searchBox()),
              const SizedBox(width: 10),
              _filterButton(),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _showUploadReportDialog,
              icon: const Icon(Icons.upload_file),
              label: const Text('Upload Report'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1677FF),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      );
    }

    return Row(
      children: [
        Expanded(child: _searchBox()),
        const SizedBox(width: 12),
        _filterButton(),
      ],
    );
  }

  Widget _searchBox() {
    return TextField(
      controller: _searchController,
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        hintText: 'Search patient, report ID, test...',
        prefixIcon: const Icon(Icons.search),
        filled: true,
        fillColor: AppTheme.cardBg(context),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.border(context)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.border(context)),
        ),
      ),
    );
  }

  Widget _filterButton() {
    return PopupMenuButton<String>(
      onSelected: (value) {
        setState(() {
          _statusFilter = value;
        });
      },
      itemBuilder: (context) => const [
        PopupMenuItem(value: 'All', child: Text('All Reports')),
        PopupMenuItem(value: 'Pending', child: Text('Pending')),
        PopupMenuItem(value: 'Ready', child: Text('Ready')),
        PopupMenuItem(value: 'Delivered', child: Text('Delivered')),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        decoration: BoxDecoration(
          color: AppTheme.cardBg(context),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.border(context)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.filter_list, size: 20, color: AppTheme.textPrimary(context)),
            const SizedBox(width: 8),
            Text(_statusFilter, style: TextStyle(color: AppTheme.textPrimary(context))),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileReports() {
    final reports = _filteredReports;

    if (reports.isEmpty) {
      return _emptyState();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: reports.map((report) {
        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.cardBg(context),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppTheme.border(context)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
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
                  _pdfIcon(),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          report['testName'],
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary(context),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          report['id'],
                          style: TextStyle(
                            color: AppTheme.textSecondary(context),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _statusBadge(report['status']),
                ],
              ),
              Divider(height: 26, color: AppTheme.border(context)),
              _infoRow(Icons.person_outline, report['patientName']),
              const SizedBox(height: 8),
              _infoRow(Icons.badge_outlined, report['patientId']),
              const SizedBox(height: 8),
              _infoRow(Icons.calendar_today_outlined, report['reportDate']),
              const SizedBox(height: 8),
              _infoRow(Icons.medical_services_outlined, report['doctor']),
              if (report['pdf'] == true && report['pdfName'] != null) ...[
                const SizedBox(height: 10),
                _infoRow(Icons.picture_as_pdf_outlined, report['pdfName']),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _viewReport(report),
                      icon: const Icon(Icons.visibility_outlined),
                      label: const Text('View'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: report['pdf'] == true
                          ? () => _shareReport(report)
                          : null,
                      icon: const Icon(Icons.share_outlined),
                      label: const Text('Share'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  PopupMenuButton<String>(
                    onSelected: (value) => _handleAction(value, report),
                    itemBuilder: (context) => const [
                      PopupMenuItem(value: 'download', child: Text('Open PDF')),
                      PopupMenuItem(value: 'edit', child: Text('Edit Report')),
                      PopupMenuItem(
                        value: 'delete',
                        child: Text('Delete Report'),
                      ),
                    ],
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppTheme.border(context)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.more_vert),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDesktopReports(bool isTablet) {
    final reports = _filteredReports;

    if (reports.isEmpty) {
      return _emptyState();
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.cardBg(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.border(context)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStatePropertyAll(
            Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF14273A)
                : const Color(0xFFF7FAFD),
          ),
          columnSpacing: isTablet ? 22 : 35,
          columns: const [
            DataColumn(label: Text('Report')),
            DataColumn(label: Text('Patient')),
            DataColumn(label: Text('Test')),
            DataColumn(label: Text('Date')),
            DataColumn(label: Text('Doctor')),
            DataColumn(label: Text('Status')),
            DataColumn(label: Text('Actions')),
          ],
          rows: reports.map((report) {
            return DataRow(
              cells: [
                DataCell(
                  Row(
                    children: [
                      _pdfIcon(),
                      const SizedBox(width: 10),
                      Text(report['id']),
                    ],
                  ),
                ),
                DataCell(
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        report['patientName'],
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        report['patientId'],
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                DataCell(Text(report['testName'])),
                DataCell(Text(report['reportDate'])),
                DataCell(Text(report['doctor'])),
                DataCell(_statusBadge(report['status'])),
                DataCell(
                  Row(
                    children: [
                      IconButton(
                        tooltip: 'View',
                        onPressed: () => _viewReport(report),
                        icon: const Icon(Icons.visibility_outlined),
                      ),
                      IconButton(
                        tooltip: 'Open PDF',
                        onPressed: report['pdf'] == true
                            ? () => _openPdf(report)
                            : null,
                        icon: const Icon(Icons.picture_as_pdf_outlined),
                      ),
                      IconButton(
                        tooltip: 'Share',
                        onPressed: report['pdf'] == true
                            ? () => _shareReport(report)
                            : null,
                        icon: const Icon(Icons.share_outlined),
                      ),
                      PopupMenuButton<String>(
                        onSelected: (value) => _handleAction(value, report),
                        itemBuilder: (context) => const [
                          PopupMenuItem(value: 'edit', child: Text('Edit')),
                          PopupMenuItem(value: 'delete', child: Text('Delete')),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _pdfIcon() {
    return Container(
      height: 44,
      width: 44,
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(Icons.picture_as_pdf_outlined, color: Colors.red),
    );
  }

  Widget _statusBadge(String status) {
    Color color;

    switch (status) {
      case 'Ready':
        color = Colors.green;
        break;
      case 'Delivered':
        color = Colors.teal;
        break;
      default:
        color = Colors.orange;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 17, color: AppTheme.textSecondary(context)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 13, color: AppTheme.textPrimary(context)),
          ),
        ),
      ],
    );
  }

  Widget _emptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(50),
      decoration: BoxDecoration(
        color: AppTheme.cardBg(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.border(context)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.description_outlined,
            size: 60,
            color: AppTheme.textSecondary(context),
          ),
          const SizedBox(height: 15),
          Text(
            'No reports found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary(context),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Try changing your search or filter.',
            style: TextStyle(color: AppTheme.textSecondary(context)),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // PDF PICKER - NEW FILE_PICKER API
  // ============================================================

  Future<PlatformFile?> _pickPdf() async {
    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (file == null) {
      return null;
    }

    if (file.extension?.toLowerCase() != 'pdf') {
      return null;
    }

    return file;
  }

  Future<void> _choosePdf(
    StateSetter dialogSetState,
    Map<String, dynamic> selectedPdf,
  ) async {
    final file = await _pickPdf();

    if (file == null) {
      return;
    }

    final fileSize = file.lengthSync();

    dialogSetState(() {
      selectedPdf['path'] = file.path;
      selectedPdf['name'] = file.name;
      selectedPdf['size'] = fileSize;
    });
  }

  // ============================================================
  // UPLOAD REPORT DIALOG
  // ============================================================

  void _showUploadReportDialog() {
    final patientController = TextEditingController(text: 'Rahul Kumar');

    final testController = TextEditingController(text: 'Ultrasound Abdomen');

    final doctorController = TextEditingController(text: 'Dr. Sharma');

    final reportNumberController = TextEditingController();

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
              title: const Row(
                children: [
                  Icon(Icons.upload_file, color: Color(0xFF1677FF)),
                  SizedBox(width: 10),
                  Text('Upload Report'),
                ],
              ),
              content: Container(
                width: double.maxFinite,
                constraints: const BoxConstraints(maxWidth: 500),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _dialogField(
                        patientController,
                        'Patient Name',
                        Icons.person_outline,
                      ),
                      _dialogField(
                        testController,
                        'Test / Scan',
                        Icons.medical_services_outlined,
                      ),
                      _dialogField(
                        doctorController,
                        'Doctor',
                        Icons.person_pin_outlined,
                      ),
                      _dialogField(
                        reportNumberController,
                        'Report Number',
                        Icons.numbers,
                      ),
                      const SizedBox(height: 5),

                      // PDF SELECTOR
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? const Color(0xFF14273A)
                              : const Color(0xFFF8FAFD),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppTheme.border(context)),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              selectedPdf['name'] == null
                                  ? Icons.picture_as_pdf_outlined
                                  : Icons.task_alt,
                              size: 45,
                              color: selectedPdf['name'] == null
                                  ? Colors.red
                                  : Colors.green,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              selectedPdf['name'] ?? 'No PDF selected',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (selectedPdf['name'] != null) ...[
                              const SizedBox(height: 5),
                              Text(
                                _formatFileSize(selectedPdf['size'] ?? 0),
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                            const SizedBox(height: 14),
                            Wrap(
                              alignment: WrapAlignment.center,
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                OutlinedButton.icon(
                                  onPressed: () =>
                                      _choosePdf(dialogSetState, selectedPdf),
                                  icon: const Icon(Icons.attach_file),
                                  label: Text(
                                    selectedPdf['name'] == null
                                        ? 'Choose PDF'
                                        : 'Change PDF',
                                  ),
                                ),
                                if (selectedPdf['path'] != null)
                                  IconButton(
                                    tooltip: 'Open PDF',
                                    onPressed: () {
                                      _openSelectedPdf(selectedPdf['path']);
                                    },
                                    icon: const Icon(Icons.visibility_outlined),
                                  ),
                                if (selectedPdf['path'] != null)
                                  IconButton(
                                    tooltip: 'Remove PDF',
                                    onPressed: () {
                                      dialogSetState(() {
                                        selectedPdf['path'] = null;
                                        selectedPdf['name'] = null;
                                        selectedPdf['size'] = 0;
                                      });
                                    },
                                    icon: const Icon(
                                      Icons.delete_outline,
                                      color: Colors.red,
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 10),

                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Only PDF files should be uploaded.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                ElevatedButton.icon(
                  onPressed: () async {
                    if (patientController.text.trim().isEmpty ||
                        testController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Patient and Test fields are required.',
                          ),
                        ),
                      );
                      return;
                    }

                    final newReportId = 'RPT${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
                    final pName = patientController.text.trim();
                    final tName = testController.text.trim();
                    final doc = doctorController.text.trim();
                    final pPath = selectedPdf['path']?.toString() ?? '';
                    final pNameFile = selectedPdf['name']?.toString() ?? '${pName}_Report.pdf';
                    final nowStr = '${DateTime.now().day} Sep ${DateTime.now().year}';

                    // Save to backend
                    try {
                      await ApiService.addReport(
                        reportId: newReportId,
                        patientId: 'AKR131',
                        patientName: pName,
                        reportTitle: tName,
                        reportType: tName,
                        reportDate: nowStr,
                        fileName: pNameFile,
                        filePath: pPath,
                        status: 'Ready',
                      );
                    } catch (_) {}

                    setState(() {
                      _reports.insert(0, {
                        'id': newReportId,
                        'patientId': 'AKR131',
                        'patientName': pName,
                        'testName': tName,
                        'reportDate': nowStr,
                        'doctor': doc.isNotEmpty ? doc : 'Dr. Rajesh Sharma',
                        'status': 'Ready',
                        'pdf': true,
                        'pdfPath': pPath.isNotEmpty ? pPath : null,
                        'pdfName': pNameFile,
                        'pdfSize': selectedPdf['size'] ?? 0,
                      });
                    });

                    if (dialogContext.mounted) {
                      Navigator.pop(dialogContext);
                    }

                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Report saved and published to patient successfully.'),
                          backgroundColor: Color(0xFF10B981),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('Save Report'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _dialogField(
    TextEditingController controller,
    String label,
    IconData icon,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  // ============================================================
  // VIEW REPORT
  // ============================================================

  void _viewReport(Map<String, dynamic> report) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReportDetailsScreen(reportData: report),
      ),
    );
  }

  // ============================================================
  // OPEN PDF
  // ============================================================

  Future<void> _openSelectedPdf(String? path) async {
    if (path == null || path.isEmpty) {
      return;
    }

    final file = File(path);

    if (!await file.exists()) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PDF file could not be found.')),
      );
      return;
    }

    await OpenFilex.open(path);
  }

  Future<void> _openPdf(Map<String, dynamic> report) async {
    final path = report['pdfPath'];

    if (path != null && path.toString().isNotEmpty) {
      final file = File(path.toString());
      if (await file.exists()) {
        await OpenFilex.open(path.toString());
        return;
      }
    }

    // Direct Instant PDF Generation & Preview
    try {
      final Uint8List pdfBytes = await PdfReportService.generateMedicalReportPdf(
        reportId: report['id'] ?? 'RPT001',
        patientId: report['patientId'] ?? 'AKR1001',
        patientName: report['patientName'] ?? 'Unknown Patient',
        age: '32',
        gender: 'Male',
        mobile: '9519701963',
        referringDoctor: report['doctor'] ?? 'Dr. S. K. Sharma',
        testName: report['testName'] ?? 'Ultrasound Abdomen',
        reportDate: report['reportDate'] ?? '18 Sep 2026',
      );

      final fileName = '${report['patientName']}_${report['testName']}.pdf'
          .replaceAll(' ', '_');
      await PdfReportService.printOrPreviewReport(pdfBytes, fileName);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ============================================================
  // SHARE PDF
  // ============================================================

  Future<void> _shareReport(Map<String, dynamic> report) async {
    final path = report['pdfPath'];

    if (path != null && path.toString().isNotEmpty) {
      final file = File(path.toString());
      if (await file.exists()) {
        await SharePlus.instance.share(
          ShareParams(
            files: [XFile(path.toString())],
            text: 'Aakriti Diagnostic Report',
          ),
        );
        return;
      }
    }

    try {
      final Uint8List pdfBytes = await PdfReportService.generateMedicalReportPdf(
        reportId: report['id'] ?? 'RPT001',
        patientId: report['patientId'] ?? 'AKR1001',
        patientName: report['patientName'] ?? 'Unknown Patient',
        age: '32',
        gender: 'Male',
        mobile: '9519701963',
        referringDoctor: report['doctor'] ?? 'Dr. S. K. Sharma',
        testName: report['testName'] ?? 'Ultrasound Abdomen',
        reportDate: report['reportDate'] ?? '18 Sep 2026',
      );

      final fileName = '${report['patientName']}_${report['testName']}.pdf'
          .replaceAll(' ', '_');
      await PdfReportService.sharePdf(pdfBytes, fileName);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sharing PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ============================================================
  // OPEN / DOWNLOAD
  // ============================================================

  Future<void> _downloadReport(Map<String, dynamic> report) async {
    await _openPdf(report);
  }

  // ============================================================
  // ACTIONS
  // ============================================================

  void _handleAction(String action, Map<String, dynamic> report) {
    switch (action) {
      case 'download':
        _downloadReport(report);
        break;

      case 'edit':
        _showEditReportDialog(report);
        break;

      case 'delete':
        _deleteReport(report);
        break;
    }
  }

  // ============================================================
  // EDIT REPORT
  // ============================================================

  void _showEditReportDialog(Map<String, dynamic> report) {
    final patientController = TextEditingController(
      text: report['patientName'],
    );

    final testController = TextEditingController(text: report['testName']);

    final doctorController = TextEditingController(text: report['doctor']);

    String selectedStatus = report['status'];

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, dialogSetState) {
            return AlertDialog(
              scrollable: true,
              title: const Text('Edit Report'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _dialogField(
                      patientController,
                      'Patient Name',
                      Icons.person_outline,
                    ),
                    _dialogField(
                      testController,
                      'Test / Scan',
                      Icons.medical_services_outlined,
                    ),
                    _dialogField(
                      doctorController,
                      'Doctor',
                      Icons.person_pin_outlined,
                    ),
                    DropdownButtonFormField<String>(
                      initialValue: selectedStatus,
                      decoration: InputDecoration(
                        labelText: 'Status',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'Pending',
                          child: Text('Pending'),
                        ),
                        DropdownMenuItem(value: 'Ready', child: Text('Ready')),
                        DropdownMenuItem(
                          value: 'Delivered',
                          child: Text('Delivered'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          dialogSetState(() {
                            selectedStatus = value;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      report['patientName'] = patientController.text.trim();

                      report['testName'] = testController.text.trim();

                      report['doctor'] = doctorController.text.trim();

                      report['status'] = selectedStatus;
                    });

                    Navigator.pop(dialogContext);

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Report updated successfully.'),
                      ),
                    );
                  },
                  child: const Text('Save Changes'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ============================================================
  // DELETE
  // ============================================================

  void _deleteReport(Map<String, dynamic> report) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete Report?'),
          content: Text(
            'Are you sure you want to delete '
            '${report['id']}?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                final reportId = report['id'] ?? report['report_id'];
                setState(() {
                  _reports.removeWhere((r) =>
                      r == report ||
                      (reportId != null && (r['id'] == reportId || r['report_id'] == reportId)));
                });

                Navigator.pop(dialogContext);

                if (reportId != null) {
                  ApiService.deleteReport(id: reportId);
                }

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Report deleted.')),
                );
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // FILE SIZE
  // ============================================================

  String _formatFileSize(int bytes) {
    if (bytes <= 0) {
      return 'Unknown size';
    }

    if (bytes < 1024) {
      return '$bytes B';
    }

    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }

    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
