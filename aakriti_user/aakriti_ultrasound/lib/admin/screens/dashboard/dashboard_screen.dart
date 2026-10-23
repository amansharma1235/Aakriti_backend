import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../services/api_service.dart';
import '../../services/websocket_service.dart';
import '../../widgets/booking_modal.dart';
import '../../widgets/patient_qr_pass_modal.dart';

class DashboardScreen extends StatefulWidget {
  final Function(int index)? onNavigate;

  const DashboardScreen({super.key, this.onNavigate});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isLoading = true;

  // 8 Specific Diagnostic Center Stats
  int _totalPatients = 4;
  int _todayAppointments = 5;
  int _pendingAppointments = 2;
  int _confirmedAppointments = 4;
  int _completedAppointments = 2;
  int _cancelledAppointments = 1;
  int _pendingReports = 1;
  double _todayRevenue = 1950.0;
  double _totalRevenue = 48500.0;
  String _lastSyncTime = 'Just now';

  List<Map<String, dynamic>> _recentAppointments = [];

  final List<Map<String, dynamic>> _rooms = [
    {
      'title': 'Room 1: GE Voluson E8 (4D Ultrasound)',
      'subtitle': 'In Procedure • Patient #AKR001',
      'status': 'Busy',
      'color': const Color(0xFFF59E0B),
    },
    {
      'title': 'Room 2: Mindray Resona 7 (Color Doppler)',
      'subtitle': 'Ready for next scan',
      'status': 'Available',
      'color': const Color(0xFF10B981),
    },
    {
      'title': 'Room 3: Samsung HS70A (General Scans)',
      'subtitle': 'Doctor arriving at 12:30 PM',
      'status': 'Standby',
      'color': const Color(0xFF64748B),
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadStats();
    _loadRecentAppointments();

    // Listen to real-time WebSocket events for automatic live reload!
    WebSocketService.instance.addListener(_onRealtimeEvent);
  }

  @override
  void dispose() {
    WebSocketService.instance.removeListener(_onRealtimeEvent);
    super.dispose();
  }

  void _onRealtimeEvent(Map<String, dynamic> event) {
    if (!mounted) return;
    final eventType = event['event'] ?? '';
    debugPrint('[Dashboard] Real-time event received: $eventType');

    // On new appointment, appointment update, or cancellation, auto-refresh stats and appointments!
    if (eventType == 'NEW_APPOINTMENT' ||
        eventType == 'APPOINTMENT_UPDATED' ||
        eventType == 'APPOINTMENT_CANCELLED' ||
        eventType == 'PAYMENT_UPDATED') {
      _loadStats();
      _loadRecentAppointments();
    }
  }

  Future<void> _loadStats() async {
    setState(() => _isLoading = true);
    final stats = await ApiService.getDashboardStats();
    if (mounted) {
      final now = DateTime.now();
      setState(() {
        _totalPatients = stats['total_patients'] ?? _totalPatients;
        _todayAppointments =
            stats['today_appointments'] ??
            stats['total_appointments'] ??
            _todayAppointments;
        _pendingAppointments =
            stats['pending_appointments'] ?? _pendingAppointments;
        _confirmedAppointments =
            stats['confirmed_appointments'] ?? _confirmedAppointments;
        _completedAppointments =
            stats['completed_appointments'] ?? _completedAppointments;
        _cancelledAppointments =
            stats['cancelled_appointments'] ?? _cancelledAppointments;
        _pendingReports = stats['pending_reports'] ?? _pendingReports;
        _todayRevenue =
            (stats['today_revenue'] as num?)?.toDouble() ?? _todayRevenue;
        _totalRevenue =
            (stats['total_revenue'] as num?)?.toDouble() ?? _totalRevenue;
        _lastSyncTime =
            "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";
        _isLoading = false;
      });
    }
  }

  Future<void> _loadRecentAppointments() async {
    try {
      final list = await ApiService.getAppointments();
      if (mounted) {
        setState(() {
          _recentAppointments = list.take(6).map<Map<String, dynamic>>((item) {
            return {
              'id': item['appointment_id'] ?? 'APT',
              'dbId': item['id'],
              'patientId': item['patient_id'] ?? '',
              'patient': item['patient_name'] ?? 'Patient',
              'service': item['service_name'] ?? 'Diagnostic Procedure',
              'date': item['appointment_date'] ?? '',
              'time': item['appointment_time'] ?? '10:00 AM',
              'status': item['status'] ?? 'Pending',
              'doctor': item['doctor_name'] ?? 'Dr. Sharma',
              'mobile': item['mobile'] ?? '',
            };
          }).toList();
        });
      }
    } catch (_) {}
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning, Admin 🌅';
    if (hour < 17) return 'Good Afternoon, Admin ☀️';
    return 'Good Evening, Admin 🌙';
  }

  void _toggleRoomStatus(int index) {
    setState(() {
      final current = _rooms[index]['status'];
      if (current == 'Available') {
        _rooms[index]['status'] = 'Busy';
        _rooms[index]['subtitle'] = 'Scan in progress';
        _rooms[index]['color'] = const Color(0xFFF59E0B);
      } else if (current == 'Busy') {
        _rooms[index]['status'] = 'Cleaning';
        _rooms[index]['subtitle'] = 'Sanitizing transducer probe';
        _rooms[index]['color'] = const Color(0xFF64748B);
      } else {
        _rooms[index]['status'] = 'Available';
        _rooms[index]['subtitle'] = 'Ready for next patient';
        _rooms[index]['color'] = const Color(0xFF10B981);
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${_rooms[index]['title']} is now ${_rooms[index]['status']}',
        ),
        duration: const Duration(seconds: 2),
        backgroundColor: const Color(0xFF1677FF),
      ),
    );
  }

  // =========================================================
  // DIALOG: NEW PATIENT
  // =========================================================
  void _showNewPatientDialog() {
    final nameCtrl = TextEditingController();
    final mobileCtrl = TextEditingController();
    final ageCtrl = TextEditingController();
    String gender = 'Male';
    String bloodGroup = 'B+';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          title: const Text(
            'Register New Patient',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          content: SingleChildScrollView(
            child: Container(
              width: double.maxFinite,
              constraints: const BoxConstraints(maxWidth: 450),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Full Name',
                      prefixIcon: Icon(Icons.person),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: mobileCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Mobile Number',
                      prefixIcon: Icon(Icons.phone),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: ageCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Age'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: gender,
                          items: const [
                            DropdownMenuItem(
                              value: 'Male',
                              child: Text('Male'),
                            ),
                            DropdownMenuItem(
                              value: 'Female',
                              child: Text('Female'),
                            ),
                          ],
                          onChanged: (v) => setDlgState(() => gender = v!),
                          decoration: const InputDecoration(
                            labelText: 'Gender',
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameCtrl.text.trim().isEmpty ||
                    mobileCtrl.text.trim().isEmpty) {
                  return;
                }
                Navigator.pop(ctx);
                final id =
                    'AKR${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';
                await ApiService.addPatient(
                  patientId: id,
                  fullName: nameCtrl.text.trim(),
                  mobile: mobileCtrl.text.trim(),
                  age: ageCtrl.text.trim(),
                  gender: gender,
                  bloodGroup: bloodGroup,
                );
                _loadStats();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Patient registered: ${nameCtrl.text.trim()} ($id)',
                      ),
                    ),
                  );
                }
              },
              child: const Text('Register Patient'),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // DIALOG: BOOK SCAN
  // =========================================================
  void _showBookScanDialog() {
    BookingModal.show(
      context,
      onSuccess: () {
        _loadStats();
        _loadRecentAppointments();
      },
    );
  }

  // =========================================================
  // DIALOG: UPLOAD REPORT
  // =========================================================
  void _showUploadReportDialog() {
    final patientCtrl = TextEditingController(text: 'Rahul Kumar');
    final titleCtrl = TextEditingController(
      text: 'Ultrasound Whole Abdomen Report',
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'Upload Diagnostic Report',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        content: SingleChildScrollView(
          child: Container(
            width: double.maxFinite,
            constraints: const BoxConstraints(maxWidth: 450),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: patientCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Patient Name',
                    prefixIcon: Icon(Icons.person),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Report Title',
                    prefixIcon: Icon(Icons.description),
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.picture_as_pdf_rounded,
                        color: Colors.red,
                        size: 28,
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Ultrasound_Report_Ready.pdf\n(Signed by Radiologist)',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final rptId =
                  'RPT${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';
              await ApiService.addReport(
                reportId: rptId,
                patientId: 'AKR001',
                patientName: patientCtrl.text.trim(),
                reportTitle: titleCtrl.text.trim(),
                reportType: 'Ultrasound',
                reportDate: DateTime.now().toString().substring(0, 10),
                fileName: 'Report_${patientCtrl.text.trim()}.pdf',
                status: 'Ready',
              );
              _loadStats();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Report generated & saved: $rptId')),
                );
              }
            },
            child: const Text('Save & Publish'),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // DIALOG: NEW BILL / PAYMENT
  // =========================================================
  void _showNewBillDialog() {
    final patientCtrl = TextEditingController(text: 'Rahul Kumar');
    final amountCtrl = TextEditingController(text: '800');
    String method = 'UPI';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          title: const Text(
            'Generate Invoice / Bill',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          content: SingleChildScrollView(
            child: Container(
              width: double.maxFinite,
              constraints: const BoxConstraints(maxWidth: 450),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: patientCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Patient Name',
                      prefixIcon: Icon(Icons.person),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: amountCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Fee Amount (₹)',
                      prefixIcon: Icon(Icons.currency_rupee),
                    ),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    initialValue: method,
                    items: const [
                      DropdownMenuItem(
                        value: 'UPI',
                        child: Text('UPI (GPay, PhonePe)'),
                      ),
                      DropdownMenuItem(
                        value: 'Cash',
                        child: Text('Cash at Counter'),
                      ),
                      DropdownMenuItem(
                        value: 'Card',
                        child: Text('Debit / Credit Card'),
                      ),
                    ],
                    onChanged: (v) => setDlgState(() => method = v!),
                    decoration: const InputDecoration(
                      labelText: 'Payment Mode',
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final amt = double.tryParse(amountCtrl.text.trim()) ?? 0;
                if (amt <= 0) return;
                Navigator.pop(ctx);
                final payId =
                    'PAY${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';
                await ApiService.addPayment(
                  paymentId: payId,
                  patientId: 'AKR001',
                  patientName: patientCtrl.text.trim(),
                  amount: amt,
                  paymentMethod: method,
                  paymentDate: DateTime.now().toString().substring(0, 10),
                  status: 'Paid',
                  transactionId: 'TXN${DateTime.now().millisecondsSinceEpoch}',
                );
                _loadStats();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Payment of ₹$amt recorded for ${patientCtrl.text.trim()}!',
                      ),
                    ),
                  );
                }
              },
              child: const Text('Collect & Print Bill'),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // APPOINTMENT DETAILS BOTTOM SHEET
  // =========================================================
  void _showAppointmentDetail(
    String name,
    String test,
    String time,
    String status,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppTheme.cardBg(ctx),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppTheme.border(ctx),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: const Color(0xFF1677FF)
                          .withValues(alpha: 0.12),
                      child: Text(
                        name.substring(0, 1),
                        style: const TextStyle(
                          color: Color(0xFF1677FF),
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary(ctx),
                            ),
                          ),
                          Text(
                            test,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: AppTheme.textSecondary(ctx),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        status,
                        style: const TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                Divider(height: 32, color: AppTheme.border(ctx)),
                _detailRow('Scheduled Time', time, Icons.access_time),
                _detailRow(
                  'Reporting Radiologist',
                  'Dr. Rajesh Sharma',
                  Icons.medical_services_outlined,
                ),
                _detailRow(
                  'Centre Location',
                  'Aakriti Ultrasound Centre #01',
                  Icons.location_on_outlined,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(ctx);
                          widget.onNavigate?.call(2); // Appointments tab
                        },
                        icon: const Icon(Icons.calendar_month, size: 18),
                        label: const FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text('View All Bookings'),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Patient $name marked as Checked-In.',
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.check_circle_outline, size: 18),
                        label: const FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text('Check-In'),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _detailRow(String title, String val, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppTheme.textSecondary(context)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppTheme.textSecondary(context),
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              val,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: AppTheme.textPrimary(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // BUILD
  // =========================================================
  bool get _isCenterOpen {
    final now = DateTime.now();
    return now.hour >= 10 && now.hour < 16;
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 700;

    return RefreshIndicator(
      onRefresh: _loadStats,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(isMobile ? 16 : 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Diagnostic Center Header & Clinic Status
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: AppTheme.cardBg(context),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.border(context)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getGreeting(),
                          style: TextStyle(
                            fontSize: isMobile ? 19 : 24,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.textPrimary(context),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 6,
                          runSpacing: 2,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: _isCenterOpen
                                        ? AppColors.success
                                        : AppColors.danger,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  _isCenterOpen
                                      ? 'Center: OPEN (10:00 AM - 04:00 PM)'
                                      : 'Center: CLOSED (Opens at 10:00 AM)',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: _isCenterOpen
                                        ? (AppTheme.isDark(context)
                                            ? const Color(0xFF34D399)
                                            : const Color(0xFF15803D))
                                        : (AppTheme.isDark(context)
                                            ? const Color(0xFFF87171)
                                            : const Color(0xFFDC2626)),
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              '• Synced: $_lastSyncTime',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppTheme.textSecondary(context),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      _loadStats();
                      _loadRecentAppointments();
                    },
                    icon: const Icon(
                      Icons.sync_rounded,
                      color: AppColors.primaryBlue,
                    ),
                    tooltip: 'Sync Database & WebSocket',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 8 DIAGNOSTIC CENTER STATISTICS CARDS
            GridView.count(
              crossAxisCount: isMobile ? 2 : (width < 1100 ? 4 : 4),
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: isMobile
                  ? (width < 380 ? 1.28 : 1.35)
                  : (width < 1100 ? 1.6 : 1.5),
              children: [
                _StatCard(
                  title: "Today's Scans",
                  value: _isLoading ? '...' : _todayAppointments.toString(),
                  sub: 'Total for today',
                  icon: Icons.calendar_month_rounded,
                  color: const Color(0xFF1677FF),
                  onTap: () => widget.onNavigate?.call(2),
                ),
                _StatCard(
                  title: 'Pending Requests',
                  value: _isLoading ? '...' : _pendingAppointments.toString(),
                  sub: 'Awaiting review',
                  icon: Icons.pending_actions_rounded,
                  color: const Color(0xFFF59E0B),
                  onTap: () => widget.onNavigate?.call(2),
                ),
                _StatCard(
                  title: 'Confirmed Scans',
                  value: _isLoading ? '...' : _confirmedAppointments.toString(),
                  sub: 'Ready for scanning',
                  icon: Icons.check_circle_outline_rounded,
                  color: const Color(0xFF10B981),
                  onTap: () => widget.onNavigate?.call(2),
                ),
                _StatCard(
                  title: 'Completed Scans',
                  value: _isLoading ? '...' : _completedAppointments.toString(),
                  sub: 'Procedures finished',
                  icon: Icons.task_alt_rounded,
                  color: const Color(0xFF0D9488),
                  onTap: () => widget.onNavigate?.call(2),
                ),
                _StatCard(
                  title: 'Cancelled Scans',
                  value: _isLoading ? '...' : _cancelledAppointments.toString(),
                  sub: 'Rescheduled/Cancelled',
                  icon: Icons.cancel_outlined,
                  color: const Color(0xFFEF4444),
                  onTap: () => widget.onNavigate?.call(2),
                ),
                _StatCard(
                  title: "Today's Revenue",
                  value: _isLoading
                      ? '...'
                      : '₹${_todayRevenue.toStringAsFixed(0)}',
                  sub: 'Collected today',
                  icon: Icons.currency_rupee_rounded,
                  color: const Color(0xFF8B5CF6),
                  onTap: () => widget.onNavigate?.call(7),
                ),
                _StatCard(
                  title: 'Total Patients',
                  value: _isLoading ? '...' : _totalPatients.toString(),
                  sub: 'Registered profiles',
                  icon: Icons.people_alt_rounded,
                  color: const Color(0xFF0284C7),
                  onTap: () => widget.onNavigate?.call(1),
                ),
                _StatCard(
                  title: 'Pending Reports',
                  value: _isLoading
                      ? '...'
                      : _pendingReports.toString().padLeft(2, '0'),
                  sub: 'Drafts to finalize',
                  icon: Icons.description_rounded,
                  color: const Color(0xFFD97706),
                  onTap: () => widget.onNavigate?.call(3),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Quick Operations (Clickable and Functional)
            Text(
              'Quick Clinical Operations',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary(context),
              ),
            ),

            const SizedBox(height: 12),

            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _ActionButton(
                  icon: Icons.add_alarm_rounded,
                  title: 'Book Scan',
                  color: const Color(0xFF10B981),
                  onTap: _showBookScanDialog,
                ),
                _ActionButton(
                  icon: Icons.qr_code_scanner_rounded,
                  title: 'Scan Patient QR',
                  color: const Color(0xFF1677FF),
                  onTap: () => PatientQrPassModal.showScannerLookup(context),
                ),
                _ActionButton(
                  icon: Icons.person_add_alt_1_rounded,
                  title: 'New Patient',
                  color: const Color(0xFF0284C7),
                  onTap: _showNewPatientDialog,
                ),
                _ActionButton(
                  icon: Icons.upload_file_outlined,
                  title: 'Upload Report',
                  color: const Color(0xFFF59E0B),
                  onTap: _showUploadReportDialog,
                ),
                _ActionButton(
                  icon: Icons.receipt_long_outlined,
                  title: 'New Bill',
                  color: const Color(0xFF8B5CF6),
                  onTap: _showNewBillDialog,
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Ultrasound Rooms Status (Interactive Clickable Cards)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.cardBg(context),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppTheme.border(context)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.meeting_room_outlined,
                        size: 20,
                        color: Color(0xFF1677FF),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Sonography Suites Live Status',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: isMobile ? 13 : 15,
                            color: AppTheme.textPrimary(context),
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1677FF)
                              .withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Live',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1677FF),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  for (int i = 0; i < _rooms.length; i++) ...[
                    InkWell(
                      onTap: () => _toggleRoomStatus(i),
                      borderRadius: BorderRadius.circular(10),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: _roomStatusRow(
                          _rooms[i]['title'],
                          _rooms[i]['subtitle'],
                          _rooms[i]['status'],
                          _rooms[i]['color'],
                        ),
                      ),
                    ),
                    if (i != _rooms.length - 1)
                      Divider(height: 18, color: AppTheme.border(context)),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Real-Time Recent Appointments Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          isMobile
                              ? 'Recent Visits'
                              : 'Live Recent Patient Visits',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: isMobile ? 16 : 18,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textPrimary(context),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryBlue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Live',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primaryBlue,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                InkWell(
                  onTap: () => widget.onNavigate?.call(2),
                  borderRadius: BorderRadius.circular(8),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    child: Text(
                      'View All ➜',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1677FF),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppTheme.cardBg(context),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppTheme.border(context)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(
                      alpha: AppTheme.isDark(context) ? 0.2 : 0.02,
                    ),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: _recentAppointments.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(28),
                      child: Center(
                        child: Text(
                          'No appointments scheduled yet today.',
                          style: TextStyle(
                            color: AppTheme.textSecondary(context),
                          ),
                        ),
                      ),
                    )
                  : Column(
                      children: [
                        for (
                          int i = 0;
                          i < _recentAppointments.length;
                          i++
                        ) ...[
                          ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 4,
                            ),
                            leading: CircleAvatar(
                              backgroundColor: AppColors.primaryBlue.withValues(
                                alpha: 0.1,
                              ),
                              child: const Icon(
                                Icons.person_outline,
                                color: AppColors.primaryBlue,
                                size: 20,
                              ),
                            ),
                            title: Text(
                              _recentAppointments[i]['patient'] ?? 'Patient',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                color: AppTheme.textPrimary(context),
                              ),
                            ),
                            subtitle: Text(
                              "${_recentAppointments[i]['service']} • ${_recentAppointments[i]['time']} • ${_recentAppointments[i]['doctor']}",
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.textSecondary(context),
                              ),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Status Pill
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        _recentAppointments[i]['status'] ==
                                            'Confirmed'
                                        ? const Color(0xFF10B981)
                                              .withValues(alpha: 0.12)
                                        : const Color(0xFFF59E0B)
                                              .withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    _recentAppointments[i]['status'] ??
                                        'Pending',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color:
                                          _recentAppointments[i]['status'] ==
                                              'Confirmed'
                                          ? const Color(0xFF10B981)
                                          : const Color(0xFFF59E0B),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                // QR Pass Action
                                IconButton(
                                  tooltip: 'View Diagnostic Pass & QR',
                                  icon: const Icon(
                                    Icons.qr_code_2_rounded,
                                    color: AppColors.primaryBlue,
                                  ),
                                  onPressed: () => PatientQrPassModal.show(
                                    context,
                                    _recentAppointments[i],
                                  ),
                                ),
                              ],
                            ),
                            onTap: () => _showAppointmentDetail(
                              _recentAppointments[i]['patient'],
                              _recentAppointments[i]['service'],
                              _recentAppointments[i]['time'],
                              _recentAppointments[i]['status'],
                            ),
                          ),
                          if (i < _recentAppointments.length - 1)
                            const Divider(height: 1),
                        ],
                      ],
                    ),
            ),

            const SizedBox(height: 28),
          ],
        ),
      ),
    );
  }

  Widget _roomStatusRow(
    String title,
    String subtitle,
    String status,
    Color color,
  ) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: AppTheme.textPrimary(context),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  color: AppTheme.textSecondary(context),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            status,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

// ------------------------------------------------------------
// STAT CARD (CLICKABLE & OVERFLOW SAFE)
// ------------------------------------------------------------
class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String sub;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _StatCard({
    required this.title,
    required this.value,
    required this.sub,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.cardBg(context),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            color: AppTheme.cardBg(context),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.border(context)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(
                  alpha: AppTheme.isDark(context) ? 0.2 : 0.02,
                ),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: color, size: 17),
                  ),
                  Flexible(
                    child: Text(
                      sub,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.textPrimary(context),
                      ),
                    ),
                  ),
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10,
                      color: AppTheme.textSecondary(context),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ------------------------------------------------------------
// ACTION BUTTON (CLICKABLE & OVERFLOW SAFE)
// ------------------------------------------------------------
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.title,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppTheme.cardBg(context),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.border(context)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 12,
                color: AppTheme.textPrimary(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
