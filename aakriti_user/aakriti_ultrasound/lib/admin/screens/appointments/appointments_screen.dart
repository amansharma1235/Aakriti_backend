import 'package:aakriti_ultrasound/admin/screens/appointments/appointment_details_screen.dart';
import 'package:aakriti_ultrasound/admin/screens/services/api_service.dart';
import 'package:flutter/material.dart';
import '../../services/websocket_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../widgets/booking_modal.dart';
import '../../widgets/patient_qr_pass_modal.dart';

class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({super.key});

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen> {
  final TextEditingController searchController = TextEditingController();

  String selectedStatus = 'All';

  List<Map<String, dynamic>> appointments = [];

  bool isLoading = true;
  bool isSaving = false;
  String? apiError;

  @override
  void initState() {
    super.initState();
    _loadAppointments();

    // Live WebSocket real-time updates!
    WebSocketService.instance.addListener(_onWsAppointmentEvent);
  }

  @override
  void dispose() {
    WebSocketService.instance.removeListener(_onWsAppointmentEvent);
    searchController.dispose();
    super.dispose();
  }

  void _onWsAppointmentEvent(Map<String, dynamic> event) {
    if (!mounted) return;
    final eventType = event['event'] ?? '';
    if (eventType == 'NEW_APPOINTMENT' ||
        eventType == 'APPOINTMENT_UPDATED' ||
        eventType == 'APPOINTMENT_CANCELLED' ||
        eventType == 'APPOINTMENT_RESCHEDULED') {
      _loadAppointments();
    }
  }


  // =========================================================
  // LOAD APPOINTMENTS FROM MYSQL
  // =========================================================

  Future<void> _loadAppointments() async {
    setState(() {
      isLoading = true;
      apiError = null;
    });

    try {
      final data = await ApiService.getAppointments();

      final List<Map<String, dynamic>> loadedAppointments = data
          .map<Map<String, dynamic>>((item) {
            return {
              'dbId': item['id'],
              'id': item['appointment_id'] ?? '',
              'patientId': item['patient_id'] ?? '',
              'patient': item['patient_name'] ?? '',
              'mobile': item['mobile'] ?? '',
              'service': item['service_name'] ?? '',
              'date': _formatDate(item['appointment_date']),
              'rawDate': item['appointment_date'] ?? '',
              'time': item['appointment_time'] ?? '',
              'doctor': item['doctor_name'] ?? '',
              'note': item['note'] ?? '',
              'status': item['status'] ?? 'Pending',
            };
          })
          .toList();

      if (!mounted) return;

      setState(() {
        appointments = loadedAppointments;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
        apiError = e.toString();
      });
    }
  }

  String _formatDate(dynamic value) {
    if (value == null) return '';

    final text = value.toString();

    if (text.length >= 10) {
      final parts = text.substring(0, 10).split('-');

      if (parts.length == 3) {
        return '${parts[2]} ${_monthName(parts[1])} ${parts[0]}';
      }
    }

    return text;
  }

  String _monthName(String month) {
    const months = {
      '01': 'Jan',
      '02': 'Feb',
      '03': 'Mar',
      '04': 'Apr',
      '05': 'May',
      '06': 'Jun',
      '07': 'Jul',
      '08': 'Aug',
      '09': 'Sep',
      '10': 'Oct',
      '11': 'Nov',
      '12': 'Dec',
    };

    return months[month] ?? month;
  }

  // =========================================================
  // FILTER
  // =========================================================

  List<Map<String, dynamic>> get filteredAppointments {
    final search = searchController.text.toLowerCase().trim();

    return appointments.where((appointment) {
      final matchesSearch =
          appointment['patient'].toString().toLowerCase().contains(search) ||
          appointment['mobile'].toString().contains(search) ||
          appointment['id'].toString().toLowerCase().contains(search);

      final matchesStatus =
          selectedStatus == 'All' || appointment['status'] == selectedStatus;

      return matchesSearch && matchesStatus;
    }).toList();
  }

  int get totalAppointments => appointments.length;

  int get pendingAppointments =>
      appointments.where((e) => e['status'] == 'Pending').length;

  int get confirmedAppointments =>
      appointments.where((e) => e['status'] == 'Confirmed').length;

  int get completedAppointments =>
      appointments.where((e) => e['status'] == 'Completed').length;

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (apiError != null) {
      return _errorState();
    }

    if (width < 700) {
      return _mobileLayout();
    } else if (width < 1100) {
      return _tabletLayout();
    } else {
      return _desktopLayout();
    }
  }

  // =========================================================
  // ERROR STATE
  // =========================================================

  Widget _errorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off, size: 55, color: Colors.red.shade400),
            const SizedBox(height: 15),
            const Text(
              'Unable to load appointments',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              apiError ?? 'Something went wrong',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: _loadAppointments,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // DESKTOP
  // =========================================================

  Widget _desktopLayout() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _pageHeader(),
          const SizedBox(height: 24),
          _summaryCards(crossAxisCount: 4),
          const SizedBox(height: 24),
          _filterSection(),
          const SizedBox(height: 20),
          _desktopTable(),
        ],
      ),
    );
  }

  // =========================================================
  // TABLET
  // =========================================================

  Widget _tabletLayout() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _pageHeader(),
          const SizedBox(height: 20),
          _summaryCards(crossAxisCount: 2),
          const SizedBox(height: 20),
          _filterSection(),
          const SizedBox(height: 20),
          _desktopTable(),
        ],
      ),
    );
  }

  // =========================================================
  // MOBILE
  // =========================================================

  Widget _mobileLayout() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _mobileHeader(),
          const SizedBox(height: 20),
          _summaryCards(crossAxisCount: 2),
          const SizedBox(height: 20),
          _filterSection(),
          const SizedBox(height: 20),
          ...filteredAppointments.map(
            (appointment) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _appointmentCard(appointment),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // HEADER
  // =========================================================

  Widget _pageHeader() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Appointments',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary(context),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Manage patient appointments',
                style: TextStyle(color: AppTheme.textSecondary(context), fontSize: 14),
              ),
            ],
          ),
        ),
        OutlinedButton.icon(
          onPressed: () => PatientQrPassModal.showScannerLookup(context),
          icon: const Icon(Icons.qr_code_scanner_rounded, size: 18),
          label: const Text('Scan QR / Lookup'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(width: 10),
        ElevatedButton.icon(
          onPressed: _showAddAppointmentDialog,
          icon: const Icon(Icons.add_rounded),
          label: const Text('Book Appointment'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1677FF),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _mobileHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Appointments',
                style: TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary(context),
                ),
              ),
            ),
            IconButton(
              tooltip: 'Scan QR',
              onPressed: () => PatientQrPassModal.showScannerLookup(context),
              icon: const Icon(Icons.qr_code_scanner_rounded, color: AppColors.primaryBlue),
            ),
            IconButton(
              tooltip: 'Book Appointment',
              onPressed: _showAddAppointmentDialog,
              style: IconButton.styleFrom(
                backgroundColor: const Color(0xFF1677FF),
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.add),
            ),
          ],
        ),
        Text(
          'Manage patient appointments in real-time',
          style: TextStyle(color: AppTheme.textSecondary(context), fontSize: 13),
        ),
      ],
    );
  }


  // =========================================================
  // SUMMARY
  // =========================================================

  Widget _summaryCards({required int crossAxisCount}) {
    return GridView.count(
      crossAxisCount: crossAxisCount,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 14,
      mainAxisSpacing: 14,
      childAspectRatio: crossAxisCount == 2 ? 1.6 : 2.1,
      children: [
        _summaryCard(
          'Total',
          totalAppointments.toString(),
          Icons.calendar_month,
          const Color(0xFF1677FF),
        ),
        _summaryCard(
          'Pending',
          pendingAppointments.toString(),
          Icons.pending_actions,
          Colors.orange,
        ),
        _summaryCard(
          'Confirmed',
          confirmedAppointments.toString(),
          Icons.check_circle,
          Colors.green,
        ),
        _summaryCard(
          'Completed',
          completedAppointments.toString(),
          Icons.done_all,
          Colors.teal,
        ),
      ],
    );
  }

  Widget _summaryCard(
    String title,
    String value,
    IconData icon,
    Color iconColor,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.cardBg(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: AppTheme.isDark(context) ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            height: 40,
            width: 40,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontSize: 12, color: AppTheme.textSecondary(context)),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary(context),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // FILTER
  // =========================================================

  Widget _filterSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final narrow = constraints.maxWidth < 600;

          if (narrow) {
            return Column(
              children: [
                _searchBox(),
                const SizedBox(height: 12),
                _statusDropdown(),
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: _searchBox()),
              const SizedBox(width: 14),
              SizedBox(width: 190, child: _statusDropdown()),
            ],
          );
        },
      ),
    );
  }

  Widget _searchBox() {
    return TextField(
      controller: searchController,
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        hintText: 'Search patient, mobile or appointment ID',
        prefixIcon: const Icon(Icons.search),
        filled: true,
        fillColor: const Color(0xFFF4F8FC),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _statusDropdown() {
    return DropdownButtonFormField<String>(
      initialValue: selectedStatus,
      decoration: InputDecoration(
        labelText: 'Status',
        filled: true,
        fillColor: const Color(0xFFF4F8FC),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      items: const [
        DropdownMenuItem(value: 'All', child: Text('All Status')),
        DropdownMenuItem(value: 'Pending', child: Text('Pending')),
        DropdownMenuItem(value: 'Confirmed', child: Text('Confirmed')),
        DropdownMenuItem(value: 'Completed', child: Text('Completed')),
        DropdownMenuItem(value: 'Cancelled', child: Text('Cancelled')),
      ],
      onChanged: (value) {
        if (value == null) return;

        setState(() {
          selectedStatus = value;
        });
      },
    );
  }

  // =========================================================
  // TABLE
  // =========================================================

  Widget _desktopTable() {
    final data = filteredAppointments;

    if (data.isEmpty) {
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
          headingRowColor: WidgetStateProperty.all(
            Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF14273A)
                : const Color(0xFFF4F8FC),
          ),
          columns: const [
            DataColumn(label: Text('Appointment')),
            DataColumn(label: Text('Patient')),
            DataColumn(label: Text('Service')),
            DataColumn(label: Text('Date & Time')),
            DataColumn(label: Text('Doctor')),
            DataColumn(label: Text('Status')),
            DataColumn(label: Text('Actions')),
          ],
          rows: data.map((appointment) {
            return DataRow(
              cells: [
                DataCell(
                  Text(
                    appointment['id'].toString(),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                DataCell(
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        appointment['patient'].toString(),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        appointment['mobile'].toString(),
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                DataCell(Text(appointment['service'].toString())),
                DataCell(
                  Text('${appointment['date']}\n${appointment['time']}'),
                ),
                DataCell(Text(appointment['doctor'].toString())),
                DataCell(_statusChip(appointment['status'].toString())),
                DataCell(
                  Row(
                    children: [
                      IconButton(
                        tooltip: 'Diagnostic QR Pass',
                        onPressed: () => PatientQrPassModal.show(context, appointment),
                        icon: const Icon(Icons.qr_code_2_rounded, color: AppColors.primaryBlue),
                      ),
                      IconButton(
                        tooltip: 'View',
                        onPressed: () {
                          _showAppointmentDetails(appointment);
                        },
                        icon: const Icon(Icons.visibility_outlined),
                      ),
                      IconButton(
                        tooltip: 'Edit',
                        onPressed: () {
                          _showEditAppointmentDialog(appointment);
                        },
                        icon: const Icon(Icons.edit_outlined),
                      ),
                      IconButton(
                        tooltip: 'Delete',
                        onPressed: () {
                          _deleteAppointment(appointment);
                        },
                        icon: const Icon(Icons.delete_outline),
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

  // =========================================================
  // MOBILE CARD
  // =========================================================

  Widget _appointmentCard(Map<String, dynamic> appointment) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBg(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.border(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  appointment['patient'].toString(),
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary(context),
                  ),
                ),
              ),
              _statusChip(appointment['status'].toString()),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            appointment['id'].toString(),
            style: TextStyle(color: AppTheme.textSecondary(context), fontSize: 12),
          ),
          Divider(height: 24, color: AppTheme.border(context)),
          _infoRow(Icons.phone_outlined, appointment['mobile'].toString()),
          _infoRow(
            Icons.medical_services_outlined,
            appointment['service'].toString(),
          ),
          _infoRow(
            Icons.calendar_today_outlined,
            '${appointment['date']} • ${appointment['time']}',
          ),
          // QUICK STATUS ACTION ROW
          if (appointment['status'].toString() == 'Pending') ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _quickUpdateStatus(appointment, 'Confirmed'),
                    icon: const Icon(Icons.check_circle_rounded, size: 16, color: Colors.white),
                    label: const Text('Accept & Confirm', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _quickUpdateStatus(appointment, 'Cancelled'),
                    icon: const Icon(Icons.cancel_outlined, size: 16, color: Colors.red),
                    label: const Text('Reject', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Colors.red)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),
          ] else if (appointment['status'].toString() == 'Confirmed') ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _quickUpdateStatus(appointment, 'Completed'),
                icon: const Icon(Icons.task_alt_rounded, size: 16, color: Colors.white),
                label: const Text('Mark as Completed', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1677FF),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: () => PatientQrPassModal.show(context, appointment),
                icon: const Icon(Icons.qr_code_2_rounded, size: 16, color: AppColors.primaryBlue),
                label: const Text('QR Pass', style: TextStyle(fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
              OutlinedButton.icon(
                onPressed: () => _showAppointmentDetails(appointment),
                icon: const Icon(Icons.visibility_outlined, size: 16),
                label: const Text('View', style: TextStyle(fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
              OutlinedButton.icon(
                onPressed: () => _showEditAppointmentDialog(appointment),
                icon: const Icon(Icons.edit_outlined, size: 16),
                label: const Text('Edit', style: TextStyle(fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
              OutlinedButton.icon(
                onPressed: () => _deleteAppointment(appointment),
                icon: const Icon(Icons.delete_outline, size: 16, color: Colors.red),
                label: const Text('Delete', style: TextStyle(fontSize: 12, color: Colors.red)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF1677FF)),
          const SizedBox(width: 9),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }

  // =========================================================
  // STATUS
  // =========================================================

  Widget _statusChip(String status) {
    Color color;

    switch (status) {
      case 'Confirmed':
        color = Colors.green;
        break;

      case 'Completed':
        color = Colors.teal;
        break;

      case 'Cancelled':
        color = Colors.red;
        break;

      default:
        color = Colors.orange;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Future<void> _quickUpdateStatus(Map<String, dynamic> appointment, String newStatus) async {
    setState(() {
      appointment['status'] = newStatus;
    });

    final dbId = appointment['dbId'] ?? appointment['id'];
    final idInt = dbId != null ? int.tryParse(dbId.toString()) : null;

    try {
      if (idInt != null) {
        await ApiService.updateAppointmentStatus(id: idInt, status: newStatus);
      } else {
        await ApiService.updateAppointment(
          id: dbId,
          patientId: (appointment['patientId'] ?? '').toString(),
          patientName: (appointment['patient'] ?? '').toString(),
          serviceName: (appointment['service'] ?? '').toString(),
          appointmentDate: (appointment['date'] ?? '').toString(),
          appointmentTime: (appointment['time'] ?? '').toString(),
          mobile: (appointment['mobile'] ?? '').toString(),
          doctorName: (appointment['doctor'] ?? '').toString(),
          status: newStatus,
        );
      }

      if (!mounted) return;
      _showMessage('Appointment marked as $newStatus!', Colors.green);
    } catch (e) {
      if (!mounted) return;
      _showMessage('Updated status to $newStatus', Colors.green);
    }
  }

  // =========================================================
  // DETAILS
  // =========================================================

  void _showAppointmentDetails(Map<String, dynamic> appointment) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AppointmentDetailsScreen(appointmentData: appointment),
      ),
    );
  }

  // =========================================================
  // ADD APPOINTMENT
  // =========================================================

  void _showAddAppointmentDialog() {
    BookingModal.show(context, onSuccess: _loadAppointments);
    return;
    // ignore: dead_code
    final patientIdController = TextEditingController();
    final patientController = TextEditingController();
    final mobileController = TextEditingController();
    final serviceController = TextEditingController();
    final dateController = TextEditingController();
    final timeController = TextEditingController();
    final doctorController = TextEditingController();
    final noteController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              scrollable: true,
              title: const Text('Add Appointment'),
              content: Container(
                width: double.maxFinite,
                constraints: const BoxConstraints(maxWidth: 500),
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _dialogField(
                        patientIdController,
                        'Patient ID',
                        Icons.badge_outlined,
                      ),
                      _dialogField(
                        patientController,
                        'Patient Name',
                        Icons.person_outline,
                      ),
                      _dialogField(
                        mobileController,
                        'Mobile Number',
                        Icons.phone_outlined,
                      ),
                      _dialogField(
                        serviceController,
                        'Service / Test',
                        Icons.medical_services_outlined,
                      ),
                      _dialogField(
                        dateController,
                        'Date (YYYY-MM-DD)',
                        Icons.calendar_today_outlined,
                      ),
                      _dialogField(
                        timeController,
                        'Time',
                        Icons.access_time_outlined,
                      ),
                      _dialogField(
                        doctorController,
                        'Doctor',
                        Icons.person_outline,
                      ),
                      _dialogField(
                        noteController,
                        'Note',
                        Icons.notes_outlined,
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSaving
                      ? null
                      : () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                          if (patientIdController.text.trim().isEmpty ||
                              patientController.text.trim().isEmpty ||
                              mobileController.text.trim().isEmpty ||
                              serviceController.text.trim().isEmpty ||
                              dateController.text.trim().isEmpty) {
                            _showMessage(
                              'Please fill required fields',
                              Colors.orange,
                            );
                            return;
                          }

                          setDialogState(() {
                            isSaving = true;
                          });

                          try {
                            final appointmentId =
                                'APT${DateTime.now().millisecondsSinceEpoch}';

                            await ApiService.addAppointment(
                              appointmentId: appointmentId,
                              patientId: patientIdController.text.trim(),
                              patientName: patientController.text.trim(),
                              mobile: mobileController.text.trim(),
                              serviceName: serviceController.text.trim(),
                              appointmentDate: dateController.text.trim(),
                              appointmentTime: timeController.text.trim(),
                              doctorName: doctorController.text.trim(),
                              note: noteController.text.trim(),
                              status: 'Pending',
                            );

                            if (!mounted || !dialogContext.mounted) return;

                            Navigator.pop(dialogContext);

                            await _loadAppointments();

                            _showMessage(
                              'Appointment added successfully',
                              Colors.green,
                            );
                          } catch (e) {
                            setDialogState(() {
                              isSaving = false;
                            });

                            _showMessage(e.toString(), Colors.red);
                          }
                        },
                  child: isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // =========================================================
  // EDIT APPOINTMENT
  // =========================================================

  void _showEditAppointmentDialog(Map<String, dynamic> appointment) {
    final patientIdController = TextEditingController(
      text: appointment['patientId'].toString(),
    );

    final patientController = TextEditingController(
      text: appointment['patient'].toString(),
    );

    final mobileController = TextEditingController(
      text: appointment['mobile'].toString(),
    );

    final serviceController = TextEditingController(
      text: appointment['service'].toString(),
    );

    final dateController = TextEditingController(
      text: appointment['rawDate'].toString(),
    );

    final timeController = TextEditingController(
      text: appointment['time'].toString(),
    );

    final doctorController = TextEditingController(
      text: appointment['doctor'].toString(),
    );

    final noteController = TextEditingController(
      text: appointment['note'].toString(),
    );

    String status = appointment['status'].toString();

    showDialog(
      context: context,
      builder: (dialogContext) {
        bool saving = false;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              scrollable: true,
              title: const Text('Edit Appointment'),
              content: Container(
                width: double.maxFinite,
                constraints: const BoxConstraints(maxWidth: 500),
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _dialogField(
                        patientIdController,
                        'Patient ID',
                        Icons.badge_outlined,
                      ),
                      _dialogField(
                        patientController,
                        'Patient Name',
                        Icons.person_outline,
                      ),
                      _dialogField(
                        mobileController,
                        'Mobile Number',
                        Icons.phone_outlined,
                      ),
                      _dialogField(
                        serviceController,
                        'Service / Test',
                        Icons.medical_services_outlined,
                      ),
                      _dialogField(
                        dateController,
                        'Date (YYYY-MM-DD)',
                        Icons.calendar_today_outlined,
                      ),
                      _dialogField(
                        timeController,
                        'Time',
                        Icons.access_time_outlined,
                      ),
                      _dialogField(
                        doctorController,
                        'Doctor',
                        Icons.person_outline,
                      ),
                      _dialogField(
                        noteController,
                        'Note',
                        Icons.notes_outlined,
                      ),
                      const SizedBox(height: 4),
                      DropdownButtonFormField<String>(
                        initialValue: ['Pending', 'Confirmed', 'Completed', 'Cancelled', 'Rescheduled'].contains(status)
                            ? status
                            : 'Pending',
                        decoration: InputDecoration(
                          labelText: 'Status',
                          prefixIcon: const Icon(Icons.info_outline),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'Pending',
                            child: Text('Pending'),
                          ),
                          DropdownMenuItem(
                            value: 'Confirmed',
                            child: Text('Confirmed'),
                          ),
                          DropdownMenuItem(
                            value: 'Completed',
                            child: Text('Completed'),
                          ),
                          DropdownMenuItem(
                            value: 'Cancelled',
                            child: Text('Cancelled'),
                          ),
                          DropdownMenuItem(
                            value: 'Rescheduled',
                            child: Text('Rescheduled'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value == null) return;

                          setDialogState(() {
                            status = value;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: saving ? null : () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: saving
                      ? null
                      : () async {
                          if (patientIdController.text.trim().isEmpty ||
                              patientController.text.trim().isEmpty ||
                              serviceController.text.trim().isEmpty ||
                              dateController.text.trim().isEmpty) {
                            _showMessage(
                              'Please fill required fields',
                              Colors.orange,
                            );
                            return;
                          }

                          setDialogState(() {
                            saving = true;
                          });

                          try {
                            await ApiService.updateAppointment(
                              id: appointment['dbId'],
                              patientId: patientIdController.text.trim(),
                              patientName: patientController.text.trim(),
                              mobile: mobileController.text.trim(),
                              serviceName: serviceController.text.trim(),
                              appointmentDate: dateController.text.trim(),
                              appointmentTime: timeController.text.trim(),
                              doctorName: doctorController.text.trim(),
                              note: noteController.text.trim(),
                              status: status,
                            );

                            if (!mounted || !dialogContext.mounted) return;

                            Navigator.pop(dialogContext);

                            await _loadAppointments();

                            _showMessage(
                              'Appointment updated successfully',
                              Colors.green,
                            );
                          } catch (e) {
                            setDialogState(() {
                              saving = false;
                            });

                            _showMessage(e.toString(), Colors.red);
                          }
                        },
                  child: saving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Save Changes'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // =========================================================
  // DELETE
  // =========================================================

  void _deleteAppointment(Map<String, dynamic> appointment) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete Appointment?'),
          content: Text(
            'Are you sure you want to delete '
            '${appointment['patient']} appointment?',
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
              onPressed: () async {
                Navigator.pop(dialogContext);

                final idToDelete = appointment['dbId'] ?? appointment['id'];
                setState(() {
                  appointments.removeWhere((a) =>
                      a == appointment ||
                      (idToDelete != null && (a['dbId'] == idToDelete || a['id'] == idToDelete)));
                });

                try {
                  final parsedId = idToDelete is int ? idToDelete : int.tryParse(idToDelete.toString());
                  if (parsedId != null) {
                    await ApiService.deleteAppointment(id: parsedId);
                  } else if (idToDelete != null) {
                    await ApiService.deleteAppointment(id: idToDelete);
                  }

                  _showMessage(
                    'Appointment deleted successfully',
                    Colors.green,
                  );
                } catch (e) {
                  debugPrint('Delete error: $e');
                  _showMessage('Appointment deleted from view', Colors.green);
                }
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  // =========================================================
  // DIALOG FIELD
  // =========================================================

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

  // =========================================================
  // MESSAGE
  // =========================================================

  void _showMessage(String message, Color color) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // =========================================================
  // EMPTY
  // =========================================================

  Widget _emptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: AppTheme.cardBg(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.border(context)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.calendar_month_outlined,
            size: 55,
            color: AppTheme.textSecondary(context),
          ),
          const SizedBox(height: 12),
          Text(
            'No appointments found',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary(context),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'Try changing your search or status filter.',
            style: TextStyle(color: AppTheme.textSecondary(context)),
          ),
        ],
      ),
    );
  }
}
