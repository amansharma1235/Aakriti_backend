import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:aakriti_ultrasound/admin/services/communication_service.dart';
import 'package:aakriti_ultrasound/admin/services/pdf_report_service.dart';
import 'package:aakriti_ultrasound/admin/theme/app_theme.dart';
import '../../../widgets/whatsapp_logo.dart';


enum PaymentStatus { paid, pending, partial, refunded, failed, cancelled }

enum PaymentMethod { cash, upi, card, netBanking, online }

class PaymentRecord {
  final String id;
  final String patientName;
  final String patientId;
  final String appointmentId;
  final String testName;
  final double billAmount;
  final double discount;
  double paidAmount;
  final PaymentMethod method;
  PaymentStatus status;
  final String date;
  final String time;
  String? refundReason;

  PaymentRecord({
    required this.id,
    required this.patientName,
    required this.patientId,
    required this.appointmentId,
    required this.testName,
    required this.billAmount,
    required this.discount,
    required this.paidAmount,
    required this.method,
    required this.status,
    required this.date,
    required this.time,
    this.refundReason,
  });

  double get finalAmount => billAmount - discount;

  double get remainingAmount {
    final value = finalAmount - paidAmount;
    return value < 0 ? 0 : value;
  }

  String get statusText {
    switch (status) {
      case PaymentStatus.paid:
        return 'Paid';
      case PaymentStatus.pending:
        return 'Pending';
      case PaymentStatus.partial:
        return 'Partially Paid';
      case PaymentStatus.refunded:
        return 'Refunded';
      case PaymentStatus.failed:
        return 'Failed';
      case PaymentStatus.cancelled:
        return 'Cancelled';
    }
  }

  String get methodText {
    switch (method) {
      case PaymentMethod.cash:
        return 'Cash';
      case PaymentMethod.upi:
        return 'UPI';
      case PaymentMethod.card:
        return 'Card';
      case PaymentMethod.netBanking:
        return 'Net Banking';
      case PaymentMethod.online:
        return 'Online';
    }
  }
}

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final TextEditingController _searchController = TextEditingController();

  PaymentStatus? _statusFilter;
  PaymentMethod? _methodFilter;

  final List<PaymentRecord> _payments = [
    PaymentRecord(
      id: 'PAY001',
      patientName: 'Rahul Kumar',
      patientId: 'AKR1001',
      appointmentId: 'APT001',
      testName: 'Ultrasound Abdomen',
      billAmount: 800,
      discount: 0,
      paidAmount: 800,
      method: PaymentMethod.upi,
      status: PaymentStatus.paid,
      date: '18 Sep 2026',
      time: '10:35 AM',
    ),
    PaymentRecord(
      id: 'PAY002',
      patientName: 'Priya Singh',
      patientId: 'AKR1002',
      appointmentId: 'APT002',
      testName: 'Thyroid Profile',
      billAmount: 450,
      discount: 50,
      paidAmount: 200,
      method: PaymentMethod.cash,
      status: PaymentStatus.partial,
      date: '18 Sep 2026',
      time: '11:40 AM',
    ),
    PaymentRecord(
      id: 'PAY003',
      patientName: 'Amit Verma',
      patientId: 'AKR1003',
      appointmentId: 'APT003',
      testName: 'Blood Test',
      billAmount: 500,
      discount: 0,
      paidAmount: 0,
      method: PaymentMethod.cash,
      status: PaymentStatus.pending,
      date: '18 Sep 2026',
      time: '01:10 PM',
    ),
    PaymentRecord(
      id: 'PAY004',
      patientName: 'Neha Sharma',
      patientId: 'AKR1004',
      appointmentId: 'APT004',
      testName: 'Ultrasound Pelvis',
      billAmount: 900,
      discount: 100,
      paidAmount: 800,
      method: PaymentMethod.card,
      status: PaymentStatus.refunded,
      date: '17 Sep 2026',
      time: '04:25 PM',
      refundReason: 'Appointment cancelled',
    ),
    PaymentRecord(
      id: 'PAY005',
      patientName: 'Ravi Gupta',
      patientId: 'AKR1005',
      appointmentId: 'APT005',
      testName: 'Sugar Test',
      billAmount: 150,
      discount: 0,
      paidAmount: 0,
      method: PaymentMethod.online,
      status: PaymentStatus.failed,
      date: '17 Sep 2026',
      time: '05:15 PM',
    ),
    PaymentRecord(
      id: 'PAY006',
      patientName: 'Anjali Singh',
      patientId: 'AKR1006',
      appointmentId: 'APT006',
      testName: 'Liver Function Test',
      billAmount: 600,
      discount: 50,
      paidAmount: 0,
      method: PaymentMethod.upi,
      status: PaymentStatus.pending,
      date: '16 Sep 2026',
      time: '02:30 PM',
    ),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<PaymentRecord> get _filteredPayments {
    final query = _searchController.text.trim().toLowerCase();

    return _payments.where((payment) {
      final matchesSearch =
          query.isEmpty ||
          payment.patientName.toLowerCase().contains(query) ||
          payment.patientId.toLowerCase().contains(query) ||
          payment.id.toLowerCase().contains(query) ||
          payment.appointmentId.toLowerCase().contains(query) ||
          payment.testName.toLowerCase().contains(query);

      final matchesStatus =
          _statusFilter == null || payment.status == _statusFilter;

      final matchesMethod =
          _methodFilter == null || payment.method == _methodFilter;

      return matchesSearch && matchesStatus && matchesMethod;
    }).toList();
  }

  double get _totalRevenue {
    return _payments
        .where(
          (item) =>
              item.status == PaymentStatus.paid ||
              item.status == PaymentStatus.partial,
        )
        .fold(0, (sum, item) => sum + item.paidAmount);
  }

  double get _todayCollection {
    return _payments
        .where((item) => item.date == '18 Sep 2026')
        .fold(0, (sum, item) => sum + item.paidAmount);
  }

  double get _pendingAmount {
    return _payments
        .where(
          (item) =>
              item.status == PaymentStatus.pending ||
              item.status == PaymentStatus.partial,
        )
        .fold(0, (sum, item) => sum + item.remainingAmount);
  }

  double get _refundedAmount {
    return _payments
        .where((item) => item.status == PaymentStatus.refunded)
        .fold(0, (sum, item) => sum + item.paidAmount);
  }

  double get _onlineCollection {
    return _payments
        .where(
          (item) =>
              item.method == PaymentMethod.upi ||
              item.method == PaymentMethod.card ||
              item.method == PaymentMethod.netBanking ||
              item.method == PaymentMethod.online,
        )
        .fold(0, (sum, item) => sum + item.paidAmount);
  }

  double get _cashCollection {
    return _payments
        .where((item) => item.method == PaymentMethod.cash)
        .fold(0, (sum, item) => sum + item.paidAmount);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        if (width < 700) {
          return _buildMobile(context);
        }

        if (width < 1100) {
          return _buildTablet(context);
        }

        return _buildDesktop(context);
      },
    );
  }

  Widget _buildDesktop(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          const SizedBox(height: 24),
          _buildStatsGrid(context, 4),
          const SizedBox(height: 24),
          _buildCollectionOverview(context),
          const SizedBox(height: 24),
          _buildFilters(context),
          const SizedBox(height: 18),
          _buildDesktopTable(context),
        ],
      ),
    );
  }

  Widget _buildTablet(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          const SizedBox(height: 20),
          _buildStatsGrid(context, 2),
          const SizedBox(height: 20),
          _buildCollectionOverview(context),
          const SizedBox(height: 20),
          _buildFilters(context),
          const SizedBox(height: 18),
          _buildTabletTable(context),
        ],
      ),
    );
  }

  Widget _buildMobile(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context, isMobile: true),
          const SizedBox(height: 18),
          _buildMobileStats(),
          const SizedBox(height: 18),
          _buildCollectionOverview(context),
          const SizedBox(height: 18),
          _buildFilters(context),
          const SizedBox(height: 16),
          if (_filteredPayments.isEmpty)
            _buildEmptyState()
          else
            ..._filteredPayments.map(
              (payment) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildPaymentCard(context, payment),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, {bool isMobile = false}) {
    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Payments & Billing',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary(context),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Manage payments, invoices, refunds and collections',
            style: TextStyle(color: AppTheme.textSecondary(context), fontSize: 13),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _showAddPaymentDialog(context),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add Payment'),
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
                'Payments & Billing',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary(context),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Manage payments, invoices, refunds and collections',
                style: TextStyle(color: AppTheme.textSecondary(context), fontSize: 14),
              ),
            ],
          ),
        ),
        ElevatedButton.icon(
          onPressed: () => _showAddPaymentDialog(context),
          icon: const Icon(Icons.add),
          label: const Text('Add Payment'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1677FF),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsGrid(BuildContext context, int columns) {
    final cards = [
      _statCard(
        'Total Revenue',
        '₹${_totalRevenue.toStringAsFixed(0)}',
        Icons.currency_rupee,
        const Color(0xFF1677FF),
      ),
      _statCard(
        "Today's Collection",
        '₹${_todayCollection.toStringAsFixed(0)}',
        Icons.today,
        Colors.teal,
      ),
      _statCard(
        'Pending Amount',
        '₹${_pendingAmount.toStringAsFixed(0)}',
        Icons.pending_actions,
        Colors.orange,
      ),
      _statCard(
        'Refunded',
        '₹${_refundedAmount.toStringAsFixed(0)}',
        Icons.assignment_return,
        Colors.redAccent,
      ),
    ];

    return GridView.count(
      crossAxisCount: columns,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 14,
      mainAxisSpacing: 14,
      childAspectRatio: columns == 2 ? 2.3 : 2.1,
      children: cards,
    );
  }

  Widget _buildMobileStats() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _statCard(
                'Revenue',
                '₹${_totalRevenue.toStringAsFixed(0)}',
                Icons.currency_rupee,
                const Color(0xFF1677FF),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _statCard(
                'Today',
                '₹${_todayCollection.toStringAsFixed(0)}',
                Icons.today,
                Colors.teal,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _statCard(
                'Pending',
                '₹${_pendingAmount.toStringAsFixed(0)}',
                Icons.pending_actions,
                Colors.orange,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _statCard(
                'Refunded',
                '₹${_refundedAmount.toStringAsFixed(0)}',
                Icons.assignment_return,
                Colors.redAccent,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _statCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBg(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.border(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: Theme.of(context).brightness == Brightness.dark ? 0.2 : 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: AppTheme.textSecondary(context)),
                ),
                const SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: 19,
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

  Widget _buildCollectionOverview(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF071A2B), Color(0xFF123D61)],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isSmall = constraints.maxWidth < 600;

          final children = [
            _collectionItem(
              'Online Collection',
              '₹${_onlineCollection.toStringAsFixed(0)}',
              Icons.account_balance_wallet,
            ),
            _collectionItem(
              'Cash Collection',
              '₹${_cashCollection.toStringAsFixed(0)}',
              Icons.payments,
            ),
            _collectionItem(
              'Pending Bills',
              '${_payments.where((e) => e.status == PaymentStatus.pending || e.status == PaymentStatus.partial).length}',
              Icons.receipt_long,
            ),
          ];

          if (isSmall) {
            return Column(
              children: [
                for (int i = 0; i < children.length; i++) ...[
                  children[i],
                  if (i != children.length - 1)
                    const Divider(color: Colors.white24, height: 25),
                ],
              ],
            );
          }

          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: children,
          );
        },
      ),
    );
  }

  Widget _collectionItem(String title, String value, IconData icon) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: Colors.white),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
            const SizedBox(height: 3),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFilters(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBg(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.border(context)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 480;
          final compact = constraints.maxWidth < 650;

          if (isNarrow) {
            return Column(
              children: [
                _searchField(),
                const SizedBox(height: 12),
                _statusDropdown(),
                const SizedBox(height: 12),
                _methodDropdown(),
              ],
            );
          }

          if (compact) {
            return Column(
              children: [
                _searchField(),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _statusDropdown()),
                    const SizedBox(width: 10),
                    Expanded(child: _methodDropdown()),
                  ],
                ),
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: _searchField()),
              const SizedBox(width: 12),
              SizedBox(width: 190, child: _statusDropdown()),
              const SizedBox(width: 12),
              SizedBox(width: 190, child: _methodDropdown()),
            ],
          );
        },
      ),
    );
  }

  Widget _searchField() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextField(
      controller: _searchController,
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        hintText: 'Search patient, payment ID, appointment...',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: _searchController.text.isNotEmpty
            ? IconButton(
                onPressed: () {
                  _searchController.clear();
                  setState(() {});
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
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
      ),
    );
  }

  Widget _statusDropdown() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return DropdownButtonFormField<PaymentStatus?>(
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
      items: [
        const DropdownMenuItem<PaymentStatus?>(
          value: null,
          child: Text('All Status'),
        ),
        ...PaymentStatus.values.map(
          (status) => DropdownMenuItem<PaymentStatus?>(
            value: status,
            child: Text(_statusText(status)),
          ),
        ),
      ],
      onChanged: (value) {
        setState(() {
          _statusFilter = value;
        });
      },
    );
  }

  Widget _methodDropdown() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return DropdownButtonFormField<PaymentMethod?>(
      initialValue: _methodFilter,
      decoration: InputDecoration(
        labelText: 'Payment Method',
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
      items: [
        const DropdownMenuItem<PaymentMethod?>(
          value: null,
          child: Text('All Methods'),
        ),
        ...PaymentMethod.values.map(
          (method) => DropdownMenuItem<PaymentMethod?>(
            value: method,
            child: Text(_methodText(method)),
          ),
        ),
      ],
      onChanged: (value) {
        setState(() {
          _methodFilter = value;
        });
      },
    );
  }

  Widget _buildDesktopTable(BuildContext context) {
    return _tableContainer(
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columnSpacing: 22,
          headingRowColor: WidgetStatePropertyAll(
            Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF14273A)
                : const Color(0xFFF4F8FC),
          ),
          columns: const [
            DataColumn(label: Text('Payment')),
            DataColumn(label: Text('Patient')),
            DataColumn(label: Text('Test / Scan')),
            DataColumn(label: Text('Amount')),
            DataColumn(label: Text('Method')),
            DataColumn(label: Text('Date')),
            DataColumn(label: Text('Status')),
            DataColumn(label: Text('Action')),
          ],
          rows: _filteredPayments.map(_buildDataRow).toList(),
        ),
      ),
    );
  }

  Widget _buildTabletTable(BuildContext context) {
    return _tableContainer(
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columnSpacing: 20,
          headingRowColor: WidgetStatePropertyAll(
            Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF14273A)
                : const Color(0xFFF4F8FC),
          ),
          columns: const [
            DataColumn(label: Text('Payment')),
            DataColumn(label: Text('Patient')),
            DataColumn(label: Text('Amount')),
            DataColumn(label: Text('Method')),
            DataColumn(label: Text('Status')),
            DataColumn(label: Text('Action')),
          ],
          rows: _filteredPayments.map(_buildTabletRow).toList(),
        ),
      ),
    );
  }

  Widget _tableContainer(Widget child) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.cardBg(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.border(context)),
      ),
      child: ClipRRect(borderRadius: BorderRadius.circular(18), child: child),
    );
  }

  DataRow _buildDataRow(PaymentRecord payment) {
    return DataRow(
      cells: [
        DataCell(
          Text(payment.id, style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
        DataCell(
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                payment.patientName,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary(context),
                ),
              ),
              Text(
                payment.patientId,
                style: TextStyle(fontSize: 11, color: AppTheme.textSecondary(context)),
              ),
            ],
          ),
        ),
        DataCell(Text(payment.testName)),
        DataCell(
          Text(
            '₹${payment.finalAmount.toStringAsFixed(0)}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary(context),
            ),
          ),
        ),
        DataCell(Text(payment.methodText)),
        DataCell(
          Text(
            '${payment.date}\n${payment.time}',
            style: TextStyle(color: AppTheme.textPrimary(context)),
          ),
        ),
        DataCell(_statusChip(payment.status)),
        DataCell(
          IconButton(
            tooltip: 'View Payment',
            onPressed: () => _showPaymentDetails(payment),
            icon: const Icon(Icons.more_vert),
          ),
        ),
      ],
    );
  }

  DataRow _buildTabletRow(PaymentRecord payment) {
    return DataRow(
      cells: [
        DataCell(Text(payment.id)),
        DataCell(
          Text(
            payment.patientName,
            style: TextStyle(color: AppTheme.textPrimary(context)),
          ),
        ),
        DataCell(
          Text(
            '₹${payment.finalAmount.toStringAsFixed(0)}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary(context),
            ),
          ),
        ),
        DataCell(Text(payment.methodText)),
        DataCell(_statusChip(payment.status)),
        DataCell(
          IconButton(
            onPressed: () => _showPaymentDetails(payment),
            icon: const Icon(Icons.more_vert),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentCard(BuildContext context, PaymentRecord payment) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBg(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.border(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: Theme.of(context).brightness == Brightness.dark ? 0.2 : 0.03),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 45,
                height: 45,
                decoration: BoxDecoration(
                  color: const Color(0xFF1677FF).withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(Icons.receipt_long, color: Color(0xFF1677FF)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      payment.patientName,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: AppTheme.textPrimary(context),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${payment.id} • ${payment.patientId}',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.textSecondary(context),
                      ),
                    ),
                  ],
                ),
              ),
              _statusChip(payment.status),
            ],
          ),
          const SizedBox(height: 16),
          _infoRow(
            Icons.medical_services_outlined,
            'Test / Scan',
            payment.testName,
          ),
          _infoRow(
            Icons.calendar_today_outlined,
            'Date',
            '${payment.date} • ${payment.time}',
          ),
          _infoRow(Icons.payment_outlined, 'Method', payment.methodText),
          Divider(height: 24, color: AppTheme.border(context)),
          Row(
            children: [
              Expanded(
                child: _amountColumn(
                  'Bill',
                  '₹${payment.billAmount.toStringAsFixed(0)}',
                ),
              ),
              Expanded(
                child: _amountColumn(
                  'Discount',
                  '₹${payment.discount.toStringAsFixed(0)}',
                ),
              ),
              Expanded(
                child: _amountColumn(
                  'Paid',
                  '₹${payment.paidAmount.toStringAsFixed(0)}',
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: payment.remainingAmount > 0
                  ? Colors.orange.withValues(alpha: 0.08)
                  : Colors.green.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  payment.remainingAmount > 0
                      ? Icons.pending_actions
                      : Icons.check_circle,
                  size: 18,
                  color: payment.remainingAmount > 0
                      ? Colors.orange
                      : Colors.green,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    payment.remainingAmount > 0
                        ? 'Remaining: ₹${payment.remainingAmount.toStringAsFixed(0)}'
                        : 'Payment completed',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: payment.remainingAmount > 0
                          ? Colors.orange.shade800
                          : Colors.green.shade800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showPaymentDetails(payment),
                  icon: const Icon(Icons.visibility_outlined),
                  label: const Text('View'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _generateInvoice(payment),
                  icon: const Icon(Icons.receipt_long),
                  label: const Text('Invoice'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1677FF),
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

  Widget _infoRow(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        children: [
          Icon(icon, size: 17, color: Colors.grey.shade600),
          const SizedBox(width: 8),
          Text(
            '$title: ',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _amountColumn(String title, String amount) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 4),
        Text(
          amount,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
        ),
      ],
    );
  }

  Widget _statusChip(PaymentStatus status) {
    Color color;

    switch (status) {
      case PaymentStatus.paid:
        color = Colors.green;
        break;
      case PaymentStatus.pending:
        color = Colors.orange;
        break;
      case PaymentStatus.partial:
        color = Colors.deepOrange;
        break;
      case PaymentStatus.refunded:
        color = Colors.purple;
        break;
      case PaymentStatus.failed:
        color = Colors.red;
        break;
      case PaymentStatus.cancelled:
        color = Colors.grey;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        _statusText(status),
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Column(
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 55,
            color: AppTheme.textSecondary(context).withValues(alpha: 0.5),
          ),
          const SizedBox(height: 12),
          Text(
            'No payments found',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary(context),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'Try changing your search or filters',
            style: TextStyle(color: AppTheme.textSecondary(context)),
          ),
        ],
      ),
    );
  }

  void _showPaymentDetails(PaymentRecord payment) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          constraints: const BoxConstraints(maxWidth: 700),
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: AppTheme.cardBg(context),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Payment Details',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textPrimary(context),
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  _detailItem('Payment ID', payment.id),
                  _detailItem('Patient', payment.patientName),
                  _detailItem('Patient ID', payment.patientId),
                  _detailItem('Appointment ID', payment.appointmentId),
                  _detailItem('Test / Scan', payment.testName),
                  _detailItem(
                    'Bill Amount',
                    '₹${payment.billAmount.toStringAsFixed(0)}',
                  ),
                  _detailItem(
                    'Discount',
                    '₹${payment.discount.toStringAsFixed(0)}',
                  ),
                  _detailItem(
                    'Final Amount',
                    '₹${payment.finalAmount.toStringAsFixed(0)}',
                  ),
                  _detailItem(
                    'Paid Amount',
                    '₹${payment.paidAmount.toStringAsFixed(0)}',
                  ),
                  _detailItem(
                    'Remaining',
                    '₹${payment.remainingAmount.toStringAsFixed(0)}',
                  ),
                  _detailItem('Payment Method', payment.methodText),
                  _detailItem(
                    'Date & Time',
                    '${payment.date} • ${payment.time}',
                  ),
                  Row(
                    children: [
                      Text(
                        'Status: ',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary(context),
                        ),
                      ),
                      _statusChip(payment.status),
                    ],
                  ),
                  if (payment.refundReason != null)
                    _detailItem('Refund Reason', payment.refundReason!),
                  const SizedBox(height: 22),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _showUpiQrModal(payment);
                        },
                        icon: const Icon(Icons.qr_code_2_rounded),
                        label: const Text('UPI QR Pay'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1677FF),
                          foregroundColor: Colors.white,
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _shareWhatsAppReceipt(payment);
                        },
                        icon: const WhatsAppLogo(size: 16),
                        label: const Text('WhatsApp Slip'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _generateInvoice(payment);
                        },
                        icon: const Icon(Icons.picture_as_pdf),
                        label: const Text('Print Receipt'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _shareInvoice(payment);
                        },
                        icon: const Icon(Icons.share),
                        label: const Text('Share PDF'),
                      ),
                      if (payment.status != PaymentStatus.refunded)
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            _showRefundDialog(payment);
                          },
                          icon: const Icon(Icons.assignment_return),
                          label: const Text('Refund'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                        ),
                    ],
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 125,
            child: Text(
              title,
              style: TextStyle(
                color: AppTheme.textSecondary(context),
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: AppTheme.textPrimary(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddPaymentDialog(BuildContext context) {
    final patientController = TextEditingController();
    final testController = TextEditingController();
    final amountController = TextEditingController();
    final discountController = TextEditingController(text: '0');

    PaymentMethod selectedMethod = PaymentMethod.upi;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              scrollable: true,
              title: const Text('Add Payment'),
              content: Container(
                width: double.maxFinite,
                constraints: const BoxConstraints(maxWidth: 480),
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
                        amountController,
                        'Bill Amount',
                        Icons.currency_rupee,
                        number: true,
                      ),
                      _dialogField(
                        discountController,
                        'Discount',
                        Icons.discount_outlined,
                        number: true,
                      ),
                      DropdownButtonFormField<PaymentMethod>(
                        initialValue: selectedMethod,
                        decoration: InputDecoration(
                          labelText: 'Payment Method',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        items: PaymentMethod.values
                            .map(
                              (method) => DropdownMenuItem(
                                value: method,
                                child: Text(_methodText(method)),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setDialogState(() {
                              selectedMethod = value;
                            });
                          }
                        },
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
                ElevatedButton(
                  onPressed: () {
                    final patient = patientController.text.trim();
                    final test = testController.text.trim();
                    final amount =
                        double.tryParse(amountController.text.trim()) ?? 0;
                    final discount =
                        double.tryParse(discountController.text.trim()) ?? 0;

                    if (patient.isEmpty || test.isEmpty || amount <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Please enter patient, test and valid amount.',
                          ),
                        ),
                      );
                      return;
                    }

                    final finalAmount = amount - discount;

                    setState(() {
                      _payments.insert(
                        0,
                        PaymentRecord(
                          id: 'PAY${(_payments.length + 1).toString().padLeft(3, '0')}',
                          patientName: patient,
                          patientId: 'AKRNEW',
                          appointmentId: 'APTNEW',
                          testName: test,
                          billAmount: amount,
                          discount: discount,
                          paidAmount: finalAmount,
                          method: selectedMethod,
                          status: PaymentStatus.paid,
                          date: '18 Sep 2026',
                          time: 'Now',
                        ),
                      );
                    });

                    Navigator.pop(dialogContext);

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Payment added successfully.'),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1677FF),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Save Payment'),
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
    IconData icon, {
    bool number = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        keyboardType: number ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  void _showRefundDialog(PaymentRecord payment) {
    final reasonController = TextEditingController();
    final amountController = TextEditingController(
      text: payment.paidAmount.toStringAsFixed(0),
    );

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          scrollable: true,
          title: const Text('Refund Payment'),
          content: Container(
            width: double.maxFinite,
            constraints: const BoxConstraints(maxWidth: 420),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Refund Amount',
                      prefixIcon: const Icon(Icons.currency_rupee),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: reasonController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: 'Refund Reason',
                      prefixIcon: const Icon(Icons.notes),
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
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final refundAmount =
                    double.tryParse(amountController.text.trim()) ?? 0;

                if (refundAmount <= 0 || refundAmount > payment.paidAmount) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Enter a valid refund amount.'),
                    ),
                  );
                  return;
                }

                setState(() {
                  payment.paidAmount -= refundAmount;
                  payment.status = PaymentStatus.refunded;
                  payment.refundReason = reasonController.text.trim().isEmpty
                      ? 'Refund processed by admin'
                      : reasonController.text.trim();
                });

                Navigator.pop(dialogContext);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Refund processed successfully.'),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Process Refund'),
            ),
          ],
        );
      },
    );
  }

  void _showUpiQrModal(PaymentRecord payment) {
    final upiPayload =
        'upi://pay?pa=aakriti.ultrasound@upi&pn=Aakriti+Diagnostic&am=${payment.finalAmount.toStringAsFixed(2)}&tr=${payment.id}&tn=Bill+Payment';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF1677FF).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.qr_code_2_rounded, color: Color(0xFF1677FF), size: 24),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Dynamic UPI QR',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 320,
            maxHeight: MediaQuery.of(context).size.height * 0.65,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Scan to Pay: ₹${payment.finalAmount.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF1677FF)),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  'Patient: ${payment.patientName} (${payment.patientId})',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: QrImageView(
                    data: upiPayload,
                    version: QrVersions.auto,
                    size: 190.0,
                  ),
                ),
                const SizedBox(height: 12),
                const FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.verified_user_rounded, color: Color(0xFF15803D), size: 15),
                      SizedBox(width: 6),
                      Text(
                        'Accepting GPay, PhonePe, Paytm & BHIM',
                        style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: Color(0xFF15803D)),
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
            child: const Text('Close'),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF15803D),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              setState(() {
                payment.status = PaymentStatus.paid;
                payment.paidAmount = payment.finalAmount;
              });
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Payment marked as PAID successfully!'),
                  backgroundColor: Color(0xFF15803D),
                ),
              );
            },
            icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
            label: const Text('Mark Paid'),
          ),
        ],
      ),
    );
  }

  void _shareWhatsAppReceipt(PaymentRecord payment) {
    final message = CommunicationService.buildPaymentReceiptWhatsAppMessage(
      patientName: payment.patientName,
      receiptId: payment.id,
      testName: payment.testName,
      totalAmount: payment.billAmount,
      paidAmount: payment.paidAmount,
      balanceDue: payment.remainingAmount,
      paymentMode: payment.methodText,
      date: '${payment.date} ${payment.time}',
    );

    CommunicationService.shareMessage(message, subject: 'Payment Receipt - Aakriti Diagnostic');
  }

  Future<void> _generateInvoice(PaymentRecord payment) async {
    try {
      final pdfBytes = await PdfReportService.generateInvoiceReceiptPdf(
        receiptId: payment.id,
        patientName: payment.patientName,
        patientId: payment.patientId,
        appointmentId: payment.appointmentId,
        testName: payment.testName,
        totalAmount: payment.billAmount,
        discount: payment.discount,
        paidAmount: payment.paidAmount,
        balanceDue: payment.remainingAmount,
        paymentMode: payment.methodText,
        paymentStatus: payment.statusText,
        date: payment.date,
        time: payment.time,
      );

      await PdfReportService.printOrPreviewReport(pdfBytes, '${payment.id}_Invoice.pdf');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating invoice: $e')),
        );
      }
    }
  }

  Future<void> _shareInvoice(PaymentRecord payment) async {
    try {
      final pdfBytes = await PdfReportService.generateInvoiceReceiptPdf(
        receiptId: payment.id,
        patientName: payment.patientName,
        patientId: payment.patientId,
        appointmentId: payment.appointmentId,
        testName: payment.testName,
        totalAmount: payment.billAmount,
        discount: payment.discount,
        paidAmount: payment.paidAmount,
        balanceDue: payment.remainingAmount,
        paymentMode: payment.methodText,
        paymentStatus: payment.statusText,
        date: payment.date,
        time: payment.time,
      );

      await PdfReportService.sharePdf(pdfBytes, '${payment.id}_Invoice.pdf');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sharing invoice: $e')),
        );
      }
    }
  }

  String _statusText(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.paid:
        return 'Paid';
      case PaymentStatus.pending:
        return 'Pending';
      case PaymentStatus.partial:
        return 'Partially Paid';
      case PaymentStatus.refunded:
        return 'Refunded';
      case PaymentStatus.failed:
        return 'Failed';
      case PaymentStatus.cancelled:
        return 'Cancelled';
    }
  }

  String _methodText(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.cash:
        return 'Cash';
      case PaymentMethod.upi:
        return 'UPI';
      case PaymentMethod.card:
        return 'Card';
      case PaymentMethod.netBanking:
        return 'Net Banking';
      case PaymentMethod.online:
        return 'Online';
    }
  }
}
