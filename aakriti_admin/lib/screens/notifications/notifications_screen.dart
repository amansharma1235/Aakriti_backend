import 'package:flutter/material.dart';
import 'package:aakriti_admin/theme/app_theme.dart';
import '../../services/api_service.dart';
import '../../services/websocket_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final TextEditingController _searchController = TextEditingController();

  String _typeFilter = 'All';
  String _statusFilter = 'All';
  bool _isLoading = false;

  List<Map<String, dynamic>> _notifications = [];

  List<Map<String, dynamic>> get _filteredNotifications {
    final query = _searchController.text.trim().toLowerCase();

    return _notifications.where((notification) {
      final matchesSearch =
          notification['title'].toString().toLowerCase().contains(query) ||
          notification['message'].toString().toLowerCase().contains(query) ||
          notification['patient'].toString().toLowerCase().contains(query) ||
          notification['id'].toString().toLowerCase().contains(query);

      final matchesType =
          _typeFilter == 'All' || notification['type'] == _typeFilter;

      final matchesStatus =
          _statusFilter == 'All' || notification['status'] == _statusFilter;

      return matchesSearch && matchesType && matchesStatus;
    }).toList();
  }

  int get _sentCount =>
      _notifications.where((item) => item['status'] == 'Sent').length;

  int get _pendingCount =>
      _notifications.where((item) => item['status'] == 'Pending').length;

  int get _reportCount =>
      _notifications.where((item) => item['type'] == 'Report').length;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_refresh);
    _loadNotifications();

    // Listen to real-time WebSocket events
    WebSocketService.instance.addListener(_onWsNotification);
  }

  @override
  void dispose() {
    WebSocketService.instance.removeListener(_onWsNotification);
    _searchController.dispose();
    super.dispose();
  }

  void _onWsNotification(Map<String, dynamic> event) {
    if (!mounted) return;
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);
    try {
      final list = await ApiService.getNotifications();
      if (mounted && list.isNotEmpty) {
        setState(() {
          _notifications = list.map<Map<String, dynamic>>((n) {
            return {
              'dbId': n['id'],
              'id': n['notification_id'] ?? 'NTF',
              'title': n['title'] ?? 'Notification',
              'message': n['message'] ?? '',
              'patient': n['patient_name'] ?? 'Patient',
              'type': n['notification_type'] ?? 'General',
              'date': (n['created_at'] != null && n['created_at'].toString().length >= 10)
                  ? n['created_at'].toString().substring(0, 10)
                  : 'Today',
              'time': (n['created_at'] != null && n['created_at'].toString().length > 11)
                  ? n['created_at'].toString().substring(11, 16)
                  : '',
              'status': n['status'] ?? 'Sent',
              'isRead': n['is_read'] == 1 || n['is_read'] == true,
            };
          }).toList();
          _isLoading = false;
        });
        return;
      }
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  void _refresh() {
    setState(() {});
  }


  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 700) {
          return _buildMobile();
        }

        if (constraints.maxWidth < 1100) {
          return _buildTablet();
        }

        return _buildDesktop();
      },
    );
  }

  Widget _buildMobile() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(isMobile: true),
          const SizedBox(height: 18),
          _buildStats(crossAxisCount: 2),
          const SizedBox(height: 18),
          _buildFilters(),
          if (_isLoading) const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: LinearProgressIndicator(minHeight: 2)),
          const SizedBox(height: 18),
          ..._filteredNotifications.map(_notificationCard),
        ],
      ),
    );
  }

  Widget _buildTablet() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(isMobile: false),
          const SizedBox(height: 22),
          _buildStats(crossAxisCount: 4),
          const SizedBox(height: 22),
          _buildFilters(),
          if (_isLoading) const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: LinearProgressIndicator(minHeight: 2)),
          const SizedBox(height: 20),
          _buildTable(),
        ],
      ),
    );
  }

  Widget _buildDesktop() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(isMobile: false),
          const SizedBox(height: 26),
          _buildStats(crossAxisCount: 4),
          const SizedBox(height: 26),
          _buildFilters(),
          if (_isLoading) const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: LinearProgressIndicator(minHeight: 2)),
          const SizedBox(height: 22),
          _buildTable(),
        ],
      ),
    );
  }

  Widget _buildHeader({bool isMobile = false}) {
    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Notifications',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary(context),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Send and manage patient notifications',
            style: TextStyle(fontSize: 13, color: AppTheme.textSecondary(context)),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _showSendNotificationDialog,
              icon: const Icon(Icons.send_outlined, size: 18),
              label: const Text('Send Notification'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1677FF),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 13),
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
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Notifications',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary(context),
                ),
              ),
              const SizedBox(height: 5),
              Text(
                'Send and manage patient notifications',
                style: TextStyle(fontSize: 14, color: AppTheme.textSecondary(context)),
              ),
            ],
          ),
        ),
        ElevatedButton.icon(
          onPressed: _showSendNotificationDialog,
          icon: const Icon(Icons.send_outlined),
          label: const Text('Send Notification'),
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

  Widget _buildStats({required int crossAxisCount}) {
    final bool isMobile = crossAxisCount == 2;

    return GridView.count(
      crossAxisCount: crossAxisCount,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: isMobile ? 10 : 14,
      mainAxisSpacing: isMobile ? 10 : 14,
      childAspectRatio: isMobile ? 1.65 : 2.1,
      children: [
        _statCard(
          title: 'Total',
          value: _notifications.length.toString(),
          icon: Icons.notifications_outlined,
          isMobile: isMobile,
        ),
        _statCard(
          title: 'Sent',
          value: _sentCount.toString(),
          icon: Icons.check_circle_outline,
          isMobile: isMobile,
        ),
        _statCard(
          title: 'Pending',
          value: _pendingCount.toString(),
          icon: Icons.schedule_outlined,
          isMobile: isMobile,
        ),
        _statCard(
          title: 'Reports',
          value: _reportCount.toString(),
          icon: Icons.picture_as_pdf_outlined,
          isMobile: isMobile,
        ),
      ],
    );
  }

  Widget _statCard({
    required String title,
    required String value,
    required IconData icon,
    bool isMobile = false,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 10 : 16,
        vertical: isMobile ? 10 : 16,
      ),
      decoration: BoxDecoration(
        color: AppTheme.cardBg(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border(context)),
      ),
      child: Row(
        children: [
          Container(
            height: isMobile ? 38 : 46,
            width: isMobile ? 38 : 46,
            decoration: BoxDecoration(
              color: const Color(0xFF1677FF).withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF1677FF),
              size: isMobile ? 20 : 24,
            ),
          ),
          SizedBox(width: isMobile ? 8 : 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: isMobile ? 11 : 12,
                    color: AppTheme.textSecondary(context),
                  ),
                ),
                SizedBox(height: isMobile ? 2 : 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: isMobile ? 18 : 22,
                      fontWeight: FontWeight.w800,
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

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBg(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border(context)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 480;
          final compact = constraints.maxWidth < 750;

          if (isNarrow) {
            return Column(
              children: [
                _searchBox(),
                const SizedBox(height: 12),
                _typeDropdown(),
                const SizedBox(height: 12),
                _statusDropdown(),
              ],
            );
          }

          if (compact) {
            return Column(
              children: [
                _searchBox(),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _typeDropdown()),
                    const SizedBox(width: 10),
                    Expanded(child: _statusDropdown()),
                  ],
                ),
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: _searchBox()),
              const SizedBox(width: 12),
              SizedBox(width: 180, child: _typeDropdown()),
              const SizedBox(width: 12),
              SizedBox(width: 160, child: _statusDropdown()),
            ],
          );
        },
      ),
    );
  }

  Widget _searchBox() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: 'Search notification, patient...',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: _searchController.text.isNotEmpty
            ? IconButton(
                onPressed: () {
                  _searchController.clear();
                },
                icon: const Icon(Icons.clear),
              )
            : null,
        filled: true,
        fillColor: isDark ? const Color(0xFF14273A) : const Color(0xFFF7F9FC),
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

  Widget _typeDropdown() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return DropdownButtonFormField<String>(
      initialValue: _typeFilter,
      decoration: InputDecoration(
        labelText: 'Type',
        filled: true,
        fillColor: isDark ? const Color(0xFF14273A) : const Color(0xFFF7F9FC),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.border(context)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.border(context)),
        ),
      ),
      items: const [
        DropdownMenuItem(value: 'All', child: Text('All Types')),
        DropdownMenuItem(value: 'Report', child: Text('Report')),
        DropdownMenuItem(value: 'Appointment', child: Text('Appointment')),
        DropdownMenuItem(value: 'Payment', child: Text('Payment')),
        DropdownMenuItem(value: 'General', child: Text('General')),
      ],
      onChanged: (value) {
        if (value == null) return;

        setState(() {
          _typeFilter = value;
        });
      },
    );
  }

  Widget _statusDropdown() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return DropdownButtonFormField<String>(
      initialValue: _statusFilter,
      decoration: InputDecoration(
        labelText: 'Status',
        filled: true,
        fillColor: isDark ? const Color(0xFF14273A) : const Color(0xFFF7F9FC),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.border(context)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.border(context)),
        ),
      ),
      items: const [
        DropdownMenuItem(value: 'All', child: Text('All Status')),
        DropdownMenuItem(value: 'Sent', child: Text('Sent')),
        DropdownMenuItem(value: 'Pending', child: Text('Pending')),
      ],
      onChanged: (value) {
        if (value == null) return;

        setState(() {
          _statusFilter = value;
        });
      },
    );
  }

  Widget _buildTable() {
    final notifications = _filteredNotifications;

    if (notifications.isEmpty) {
      return _emptyState();
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.cardBg(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border(context)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowHeight: 56,
          dataRowMinHeight: 70,
          dataRowMaxHeight: 82,
          headingRowColor: WidgetStateProperty.all(
            Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF14273A)
                : const Color(0xFFF7F9FC),
          ),
          columns: const [
            DataColumn(label: Text('Notification')),
            DataColumn(label: Text('Patient')),
            DataColumn(label: Text('Type')),
            DataColumn(label: Text('Date & Time')),
            DataColumn(label: Text('Status')),
            DataColumn(label: Text('Actions')),
          ],
          rows: notifications.map((notification) {
            return DataRow(
              cells: [
                DataCell(_notificationName(notification)),
                DataCell(
                  Text(
                    notification['patient'],
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary(context),
                    ),
                  ),
                ),
                DataCell(_typeChip(notification['type'])),
                DataCell(
                  Text(
                    '${notification['date']}\n${notification['time']}',
                    style: TextStyle(color: AppTheme.textPrimary(context)),
                  ),
                ),
                DataCell(_statusChip(notification['status'])),
                DataCell(_actionButtons(notification)),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _notificationName(Map<String, dynamic> notification) {
    return SizedBox(
      width: 240,
      child: Row(
        children: [
          _notificationIcon(notification['type']),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  notification['title'],
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary(context),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  notification['id'],
                  style: TextStyle(fontSize: 11, color: AppTheme.textSecondary(context)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _notificationIcon(String type) {
    IconData icon;

    switch (type) {
      case 'Report':
        icon = Icons.picture_as_pdf_outlined;
        break;
      case 'Appointment':
        icon = Icons.calendar_month_outlined;
        break;
      case 'Payment':
        icon = Icons.payments_outlined;
        break;
      default:
        icon = Icons.notifications_outlined;
    }

    return Container(
      height: 42,
      width: 42,
      decoration: BoxDecoration(
        color: const Color(0xFF1677FF).withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: const Color(0xFF1677FF), size: 21),
    );
  }

  Widget _typeChip(String type) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF1677FF).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        type,
        style: const TextStyle(
          color: Color(0xFF1677FF),
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _statusChip(String status) {
    final sent = status == 'Sent';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: sent
            ? Colors.green.withValues(alpha: 0.10)
            : Colors.orange.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: sent ? Colors.green.shade700 : Colors.orange.shade700,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _actionButtons(Map<String, dynamic> notification) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: 'View',
          onPressed: () {
            _showNotificationDetails(notification);
          },
          icon: const Icon(Icons.visibility_outlined, size: 20),
        ),
        IconButton(
          tooltip: 'Delete',
          onPressed: () {
            _deleteNotification(notification);
          },
          icon: const Icon(Icons.delete_outline, size: 20),
        ),
      ],
    );
  }

  Widget _notificationCard(Map<String, dynamic> notification) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
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
              _notificationIcon(notification['type']),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification['title'],
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary(context),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification['id'],
                      style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.textSecondary(context),
                      ),
                    ),
                  ],
                ),
              ),
              _statusChip(notification['status']),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            notification['message'],
            style: TextStyle(height: 1.4, color: AppTheme.textSecondary(context)),
          ),
          const SizedBox(height: 14),
          _mobileInfo(Icons.person_outline, notification['patient']),
          _mobileInfo(Icons.category_outlined, notification['type']),
          _mobileInfo(
            Icons.schedule_outlined,
            '${notification['date']} • ${notification['time']}',
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    _showNotificationDetails(notification);
                  },
                  icon: const Icon(Icons.visibility_outlined),
                  label: const Text('View'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    _deleteNotification(notification);
                  },
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Delete'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _mobileInfo(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 17, color: const Color(0xFF1677FF)),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 13, color: AppTheme.textPrimary(context)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: AppTheme.cardBg(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border(context)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.notifications_off_outlined,
            size: 48,
            color: AppTheme.textSecondary(context),
          ),
          const SizedBox(height: 12),
          Text(
            'No notifications found',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary(context),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'Try changing your search or filters.',
            style: TextStyle(color: AppTheme.textSecondary(context)),
          ),
        ],
      ),
    );
  }

  void _showSendNotificationDialog() {
    final titleController = TextEditingController();
    final messageController = TextEditingController();

    String selectedPatient = 'All Patients';
    String selectedType = 'General';

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              scrollable: true,
              title: const Text(
                'Send Notification',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              content: Container(
                width: double.maxFinite,
                constraints: const BoxConstraints(maxWidth: 500),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownButtonFormField<String>(
                        initialValue: selectedPatient,
                        decoration: InputDecoration(
                          labelText: 'Patient',
                          prefixIcon: const Icon(Icons.person_outline),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'All Patients',
                            child: Text('All Patients'),
                          ),
                          DropdownMenuItem(
                            value: 'Rahul Kumar',
                            child: Text('Rahul Kumar'),
                          ),
                          DropdownMenuItem(
                            value: 'Priya Singh',
                            child: Text('Priya Singh'),
                          ),
                          DropdownMenuItem(
                            value: 'Amit Verma',
                            child: Text('Amit Verma'),
                          ),
                          DropdownMenuItem(
                            value: 'Neha Sharma',
                            child: Text('Neha Sharma'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value == null) return;

                          setDialogState(() {
                            selectedPatient = value;
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: selectedType,
                        decoration: InputDecoration(
                          labelText: 'Notification Type',
                          prefixIcon: const Icon(Icons.category_outlined),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'General',
                            child: Text('General'),
                          ),
                          DropdownMenuItem(
                            value: 'Report',
                            child: Text('Report'),
                          ),
                          DropdownMenuItem(
                            value: 'Appointment',
                            child: Text('Appointment'),
                          ),
                          DropdownMenuItem(
                            value: 'Payment',
                            child: Text('Payment'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value == null) return;

                          setDialogState(() {
                            selectedType = value;
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: titleController,
                        decoration: InputDecoration(
                          labelText: 'Notification Title',
                          prefixIcon: const Icon(Icons.title_outlined),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: messageController,
                        maxLines: 4,
                        decoration: InputDecoration(
                          labelText: 'Message',
                          alignLabelWithHint: true,
                          prefixIcon: const Padding(
                            padding: EdgeInsets.only(bottom: 70),
                            child: Icon(Icons.message_outlined),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                  },
                  child: const Text('Cancel'),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    if (titleController.text.trim().isEmpty ||
                        messageController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please enter title and message.'),
                        ),
                      );
                      return;
                    }

                    setState(() {
                      _notifications.insert(0, {
                        'id':
                            'NTF${(_notifications.length + 1).toString().padLeft(3, '0')}',
                        'title': titleController.text.trim(),
                        'message': messageController.text.trim(),
                        'patient': selectedPatient,
                        'type': selectedType,
                        'date': 'Today',
                        'time': 'Now',
                        'status': 'Sent',
                      });
                    });

                    Navigator.pop(dialogContext);

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Notification sent successfully.'),
                      ),
                    );
                  },
                  icon: const Icon(Icons.send_outlined),
                  label: const Text('Send'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1677FF),
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showNotificationDetails(Map<String, dynamic> notification) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(22),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      height: 4,
                      width: 45,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      _notificationIcon(notification['type']),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          notification['title'],
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _detailItem('Notification ID', notification['id']),
                  _detailItem('Patient', notification['patient']),
                  _detailItem('Type', notification['type']),
                  _detailItem('Status', notification['status']),
                  _detailItem('Date', notification['date']),
                  _detailItem('Time', notification['time']),
                  const SizedBox(height: 8),
                  const Text(
                    'Message',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7F9FC),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      notification['message'],
                      style: TextStyle(
                        height: 1.5,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _detailItem(String title, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9FC),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(title, style: TextStyle(color: Colors.grey.shade600)),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  void _deleteNotification(Map<String, dynamic> notification) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Delete Notification?',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          content: Text(
            'Are you sure you want to delete '
            '${notification['title']}?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _notifications.remove(notification);
                });

                Navigator.pop(dialogContext);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Notification deleted successfully.'),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }
}
