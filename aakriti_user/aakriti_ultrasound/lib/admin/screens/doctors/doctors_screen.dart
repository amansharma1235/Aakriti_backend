import 'package:flutter/material.dart';
import 'package:aakriti_ultrasound/admin/screens/services/api_service.dart';
import 'package:aakriti_ultrasound/admin/theme/app_theme.dart';

class DoctorsScreen extends StatefulWidget {
  const DoctorsScreen({super.key});

  @override
  State<DoctorsScreen> createState() => _DoctorsScreenState();
}

class _DoctorsScreenState extends State<DoctorsScreen> {
  final TextEditingController _searchController = TextEditingController();

  String _statusFilter = 'All';
  String _specializationFilter = 'All';

  final List<Map<String, dynamic>> _doctors = [
    {
      'id': 'DOC001',
      'name': 'Dr. Rajesh Sharma',
      'specialization': 'Radiologist',
      'phone': '9876543210',
      'experience': '12 Years',
      'status': 'Active',
      'patients': 245,
    },
    {
      'id': 'DOC002',
      'name': 'Dr. Neha Verma',
      'specialization': 'Pathologist',
      'phone': '9123456780',
      'experience': '8 Years',
      'status': 'Active',
      'patients': 186,
    },
    {
      'id': 'DOC003',
      'name': 'Dr. Amit Gupta',
      'specialization': 'Radiologist',
      'phone': '9988776655',
      'experience': '10 Years',
      'status': 'Active',
      'patients': 210,
    },
    {
      'id': 'DOC004',
      'name': 'Dr. Priya Singh',
      'specialization': 'Sonologist',
      'phone': '9876501234',
      'experience': '6 Years',
      'status': 'Inactive',
      'patients': 132,
    },
    {
      'id': 'DOC005',
      'name': 'Dr. Ankit Verma',
      'specialization': 'Physician',
      'phone': '9001122334',
      'experience': '5 Years',
      'status': 'Active',
      'patients': 98,
    },
  ];

  List<Map<String, dynamic>> get _filteredDoctors {
    final query = _searchController.text.trim().toLowerCase();

    return _doctors.where((doctor) {
      final matchesSearch =
          doctor['name'].toString().toLowerCase().contains(query) ||
          doctor['id'].toString().toLowerCase().contains(query) ||
          doctor['phone'].toString().contains(query) ||
          doctor['specialization'].toString().toLowerCase().contains(query);

      final matchesStatus =
          _statusFilter == 'All' ||
          doctor['status'].toString() == _statusFilter;

      final matchesSpecialization =
          _specializationFilter == 'All' ||
          doctor['specialization'].toString() == _specializationFilter;

      return matchesSearch && matchesStatus && matchesSpecialization;
    }).toList();
  }

  int get _activeDoctors =>
      _doctors.where((doctor) => doctor['status'] == 'Active').length;

  int get _inactiveDoctors =>
      _doctors.where((doctor) => doctor['status'] == 'Inactive').length;

  int get _radiologists => _doctors
      .where((doctor) => doctor['specialization'] == 'Radiologist')
      .length;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_refresh);
    _loadDoctorsFromApi();
  }

  Future<void> _loadDoctorsFromApi() async {
    try {
      final list = await ApiService.getDoctors();
      if (list.isNotEmpty && mounted) {
        setState(() {
          _doctors.clear();
          for (final item in list) {
            _doctors.add({
              'id': item['doctor_id'] ?? 'DOC${_doctors.length + 1}',
              'name': item['doctor_name'] ?? 'Doctor',
              'specialization': item['specialization'] ?? 'Radiologist',
              'phone': item['mobile'] ?? '',
              'experience': item['experience'] ?? '5 Years',
              'status': item['status'] ?? 'Active',
              'patients': item['total_patients'] ?? 50,
            });
          }
        });
      }
    } catch (_) {}
  }

  void _refresh() {
    setState(() {});
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        if (width < 700) {
          return _buildMobileLayout();
        }

        if (width < 1100) {
          return _buildTabletLayout();
        }

        return _buildDesktopLayout();
      },
    );
  }

  Widget _buildMobileLayout() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(isMobile: true),
          const SizedBox(height: 18),
          _buildStatsGrid(crossAxisCount: 2),
          const SizedBox(height: 18),
          _buildFilters(),
          const SizedBox(height: 18),
          ..._filteredDoctors.map(_buildDoctorCard),
        ],
      ),
    );
  }

  Widget _buildTabletLayout() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 22),
          _buildStatsGrid(crossAxisCount: 4),
          const SizedBox(height: 22),
          _buildFilters(),
          const SizedBox(height: 20),
          _buildDoctorsTable(),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 26),
          _buildStatsGrid(crossAxisCount: 4),
          const SizedBox(height: 26),
          _buildFilters(),
          const SizedBox(height: 22),
          _buildDoctorsTable(),
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
            'Doctors',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary(context),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Manage doctors and medical specialists',
            style: TextStyle(fontSize: 13, color: AppTheme.textSecondary(context)),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _showAddDoctorDialog,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add Doctor'),
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
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Doctors',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary(context),
                ),
              ),
              const SizedBox(height: 5),
              Text(
                'Manage doctors and medical specialists',
                style: TextStyle(fontSize: 14, color: AppTheme.textSecondary(context)),
              ),
            ],
          ),
        ),
        ElevatedButton.icon(
          onPressed: _showAddDoctorDialog,
          icon: const Icon(Icons.add),
          label: const Text('Add Doctor'),
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

  Widget _buildStatsGrid({required int crossAxisCount}) {
    final bool isMobile = crossAxisCount == 2;

    return GridView.count(
      crossAxisCount: crossAxisCount,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: isMobile ? 10 : 14,
      mainAxisSpacing: isMobile ? 10 : 14,
      childAspectRatio: isMobile ? 1.6 : 2.1,
      children: [
        _statCard(
          title: 'Total Doctors',
          value: _doctors.length.toString(),
          icon: Icons.medical_services_outlined,
          isMobile: isMobile,
        ),
        _statCard(
          title: 'Active',
          value: _activeDoctors.toString(),
          icon: Icons.check_circle_outline,
          isMobile: isMobile,
        ),
        _statCard(
          title: 'Inactive',
          value: _inactiveDoctors.toString(),
          icon: Icons.pause_circle_outline,
          isMobile: isMobile,
        ),
        _statCard(
          title: 'Radiologists',
          value: _radiologists.toString(),
          icon: Icons.biotech_outlined,
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
      padding: EdgeInsets.all(isMobile ? 10 : 16),
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
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: isMobile ? 18 : 22,
                    fontWeight: FontWeight.w800,
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
          final isNarrow = constraints.maxWidth < 500;
          final compact = constraints.maxWidth < 750;

          if (isNarrow) {
            return Column(
              children: [
                _searchBox(),
                const SizedBox(height: 12),
                _statusDropdown(),
                const SizedBox(height: 12),
                _specializationDropdown(),
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
                    Expanded(child: _statusDropdown()),
                    const SizedBox(width: 10),
                    Expanded(child: _specializationDropdown()),
                  ],
                ),
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: _searchBox()),
              const SizedBox(width: 12),
              SizedBox(width: 170, child: _statusDropdown()),
              const SizedBox(width: 12),
              SizedBox(width: 190, child: _specializationDropdown()),
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
        hintText: 'Search doctor, ID, phone...',
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
        DropdownMenuItem(value: 'Active', child: Text('Active')),
        DropdownMenuItem(value: 'Inactive', child: Text('Inactive')),
      ],
      onChanged: (value) {
        if (value == null) return;
        setState(() {
          _statusFilter = value;
        });
      },
    );
  }

  Widget _specializationDropdown() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return DropdownButtonFormField<String>(
      initialValue: _specializationFilter,
      decoration: InputDecoration(
        labelText: 'Specialization',
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
        DropdownMenuItem(value: 'All', child: Text('All Specializations')),
        DropdownMenuItem(value: 'Radiologist', child: Text('Radiologist')),
        DropdownMenuItem(value: 'Pathologist', child: Text('Pathologist')),
        DropdownMenuItem(value: 'Sonologist', child: Text('Sonologist')),
        DropdownMenuItem(value: 'Physician', child: Text('Physician')),
      ],
      onChanged: (value) {
        if (value == null) return;
        setState(() {
          _specializationFilter = value;
        });
      },
    );
  }

  Widget _buildDoctorsTable() {
    final doctors = _filteredDoctors;

    if (doctors.isEmpty) {
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
          dataRowMinHeight: 68,
          dataRowMaxHeight: 78,
          headingRowColor: WidgetStateProperty.all(
            Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF14273A)
                : const Color(0xFFF7F9FC),
          ),
          columns: const [
            DataColumn(label: Text('Doctor')),
            DataColumn(label: Text('Specialization')),
            DataColumn(label: Text('Phone')),
            DataColumn(label: Text('Experience')),
            DataColumn(label: Text('Patients')),
            DataColumn(label: Text('Status')),
            DataColumn(label: Text('Actions')),
          ],
          rows: doctors.map((doctor) {
            return DataRow(
              cells: [
                DataCell(_doctorNameCell(doctor)),
                DataCell(
                  Text(
                    doctor['specialization'],
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary(context),
                    ),
                  ),
                ),
                DataCell(
                  Text(
                    doctor['phone'],
                    style: TextStyle(color: AppTheme.textPrimary(context)),
                  ),
                ),
                DataCell(
                  Text(
                    doctor['experience'],
                    style: TextStyle(color: AppTheme.textPrimary(context)),
                  ),
                ),
                DataCell(
                  Text(
                    doctor['patients'].toString(),
                    style: TextStyle(color: AppTheme.textPrimary(context)),
                  ),
                ),
                DataCell(_statusChip(doctor['status'])),
                DataCell(_actionButtons(doctor)),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _doctorNameCell(Map<String, dynamic> doctor) {
    return SizedBox(
      width: 190,
      child: Row(
        children: [
          _doctorAvatar(doctor['name']),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  doctor['name'],
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary(context),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  doctor['id'],
                  style: TextStyle(fontSize: 11, color: AppTheme.textSecondary(context)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _doctorAvatar(String name) {
    final letter = name
        .replaceFirst('Dr. ', '')
        .trim()
        .substring(0, 1)
        .toUpperCase();

    return CircleAvatar(
      radius: 22,
      backgroundColor: const Color(0xFF1677FF).withValues(alpha: 0.10),
      child: Text(
        letter,
        style: const TextStyle(
          color: Color(0xFF1677FF),
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _statusChip(String status) {
    final active = status == 'Active';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: active
            ? Colors.green.withValues(alpha: 0.10)
            : Colors.orange.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: active ? Colors.green.shade700 : Colors.orange.shade700,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _actionButtons(Map<String, dynamic> doctor) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: 'View',
          onPressed: () => _showDoctorDetails(doctor),
          icon: const Icon(Icons.visibility_outlined, size: 20),
        ),
        IconButton(
          tooltip: 'Edit',
          onPressed: () => _showEditDoctorDialog(doctor),
          icon: const Icon(Icons.edit_outlined, size: 20),
        ),
        IconButton(
          tooltip: 'Delete',
          onPressed: () => _deleteDoctor(doctor),
          icon: const Icon(Icons.delete_outline, size: 20),
        ),
      ],
    );
  }

  Widget _buildDoctorCard(Map<String, dynamic> doctor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBg(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.border(context)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _doctorAvatar(doctor['name']),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      doctor['name'],
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary(context),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      doctor['id'],
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary(context),
                      ),
                    ),
                  ],
                ),
              ),
              _statusChip(doctor['status']),
            ],
          ),
          const SizedBox(height: 16),
          _infoRow(
            Icons.medical_services_outlined,
            'Specialization',
            doctor['specialization'],
          ),
          _infoRow(Icons.phone_outlined, 'Phone', doctor['phone']),
          _infoRow(
            Icons.workspace_premium_outlined,
            'Experience',
            doctor['experience'],
          ),
          _infoRow(
            Icons.people_outline,
            'Patients',
            doctor['patients'].toString(),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showDoctorDetails(doctor),
                  icon: const Icon(Icons.visibility_outlined),
                  label: const Text('View'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _showEditDoctorDialog(doctor),
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Edit'),
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
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF1677FF)),
          const SizedBox(width: 10),
          Text(
            '$title:',
            style: TextStyle(color: AppTheme.textSecondary(context), fontSize: 13),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textPrimary(context)),
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
          Icon(Icons.search_off, size: 48, color: AppTheme.textSecondary(context)),
          const SizedBox(height: 12),
          Text(
            'No doctors found',
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

  void _showAddDoctorDialog() {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final experienceController = TextEditingController();

    String specialization = 'Radiologist';
    String status = 'Active';

    _showDoctorFormDialog(
      title: 'Add Doctor',
      nameController: nameController,
      phoneController: phoneController,
      experienceController: experienceController,
      specialization: specialization,
      status: status,
      onSave:
          (name, phone, experience, selectedSpecialization, selectedStatus) async {
            final nextId = 'DOC${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';

            setState(() {
              _doctors.insert(0, {
                'id': nextId,
                'name': name,
                'specialization': selectedSpecialization,
                'phone': phone,
                'experience': experience,
                'status': selectedStatus,
                'patients': 0,
              });
            });

            try {
              await ApiService.addDoctor(
                doctorId: nextId,
                doctorName: name,
                specialization: selectedSpecialization,
                mobile: phone,
                experience: experience,
                status: selectedStatus,
              );
            } catch (e) {
              debugPrint("[DoctorsScreen Admin] addDoctor API error: $e");
            }
          },
    );
  }

  void _showEditDoctorDialog(Map<String, dynamic> doctor) {
    final nameController = TextEditingController(text: doctor['name']);
    final phoneController = TextEditingController(text: doctor['phone']);
    final experienceController = TextEditingController(
      text: doctor['experience'],
    );

    _showDoctorFormDialog(
      title: 'Edit Doctor',
      nameController: nameController,
      phoneController: phoneController,
      experienceController: experienceController,
      specialization: doctor['specialization'],
      status: doctor['status'],
      onSave:
          (name, phone, experience, selectedSpecialization, selectedStatus) async {
            setState(() {
              doctor['name'] = name;
              doctor['phone'] = phone;
              doctor['experience'] = experience;
              doctor['specialization'] = selectedSpecialization;
              doctor['status'] = selectedStatus;
            });

            try {
              final docId = (doctor['id'] ?? '').toString();
              if (docId.isNotEmpty) {
                await ApiService.updateDoctor(
                  doctorId: docId,
                  doctorName: name,
                  specialization: selectedSpecialization,
                  mobile: phone,
                  experience: experience,
                  status: selectedStatus,
                );
              }
            } catch (e) {
              debugPrint("[DoctorsScreen Admin] updateDoctor API error: $e");
            }
          },
    );
  }

  void _showDoctorFormDialog({
    required String title,
    required TextEditingController nameController,
    required TextEditingController phoneController,
    required TextEditingController experienceController,
    required String specialization,
    required String status,
    required void Function(
      String name,
      String phone,
      String experience,
      String specialization,
      String status,
    )
    onSave,
  }) {
    String selectedSpecialization = specialization;
    String selectedStatus = status;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              scrollable: true,
              title: Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              content: Container(
                width: double.maxFinite,
                constraints: const BoxConstraints(maxWidth: 500),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _formField(
                        controller: nameController,
                        label: 'Doctor Name',
                        icon: Icons.person_outline,
                      ),
                      const SizedBox(height: 12),
                      _formField(
                        controller: phoneController,
                        label: 'Phone Number',
                        icon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 12),
                      _formField(
                        controller: experienceController,
                        label: 'Experience',
                        icon: Icons.workspace_premium_outlined,
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: ['Radiologist', 'Pathologist', 'Sonologist', 'Physician', 'Gynecologist', 'Cardiologist'].contains(selectedSpecialization)
                            ? selectedSpecialization
                            : 'Radiologist',
                        decoration: InputDecoration(
                          labelText: 'Specialization',
                          prefixIcon: const Icon(
                            Icons.medical_services_outlined,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'Radiologist',
                            child: Text('Radiologist'),
                          ),
                          DropdownMenuItem(
                            value: 'Pathologist',
                            child: Text('Pathologist'),
                          ),
                          DropdownMenuItem(
                            value: 'Sonologist',
                            child: Text('Sonologist'),
                          ),
                          DropdownMenuItem(
                            value: 'Physician',
                            child: Text('Physician'),
                          ),
                          DropdownMenuItem(
                            value: 'Gynecologist',
                            child: Text('Gynecologist'),
                          ),
                          DropdownMenuItem(
                            value: 'Cardiologist',
                            child: Text('Cardiologist'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value == null) return;
                          setDialogState(() {
                            selectedSpecialization = value;
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: ['Active', 'Inactive'].contains(selectedStatus)
                            ? selectedStatus
                            : 'Active',
                        decoration: InputDecoration(
                          labelText: 'Status',
                          prefixIcon: const Icon(Icons.toggle_on_outlined),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'Active',
                            child: Text('Active'),
                          ),
                          DropdownMenuItem(
                            value: 'Inactive',
                            child: Text('Inactive'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value == null) return;
                          setDialogState(() {
                            selectedStatus = value;
                          });
                        },
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
                ElevatedButton(
                  onPressed: () {
                    if (nameController.text.trim().isEmpty ||
                        phoneController.text.trim().isEmpty ||
                        experienceController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please fill all required fields.'),
                        ),
                      );
                      return;
                    }

                    onSave(
                      nameController.text.trim(),
                      phoneController.text.trim(),
                      experienceController.text.trim(),
                      selectedSpecialization,
                      selectedStatus,
                    );

                    Navigator.pop(dialogContext);

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          title == 'Add Doctor'
                              ? 'Doctor added successfully.'
                              : 'Doctor updated successfully.',
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1677FF),
                    foregroundColor: Colors.white,
                  ),
                  child: Text(
                    title == 'Add Doctor' ? 'Add Doctor' : 'Save Changes',
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _formField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showDoctorDetails(Map<String, dynamic> doctor) {
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
                      _doctorAvatar(doctor['name']),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              doctor['name'],
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              doctor['id'],
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      ),
                      _statusChip(doctor['status']),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _detailItem(
                    'Specialization',
                    doctor['specialization'],
                    Icons.medical_services_outlined,
                  ),
                  _detailItem('Phone', doctor['phone'], Icons.phone_outlined),
                  _detailItem(
                    'Experience',
                    doctor['experience'],
                    Icons.workspace_premium_outlined,
                  ),
                  _detailItem(
                    'Patients Served',
                    doctor['patients'].toString(),
                    Icons.people_outline,
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _showEditDoctorDialog(doctor);
                      },
                      icon: const Icon(Icons.edit_outlined),
                      label: const Text('Edit Doctor'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1677FF),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
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

  Widget _detailItem(String title, String value, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9FC),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF1677FF)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(title, style: TextStyle(color: Colors.grey.shade600)),
          ),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  void _deleteDoctor(Map<String, dynamic> doctor) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Delete Doctor?',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          content: Text('Are you sure you want to delete ${doctor['name']}?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final docId = (doctor['id'] ?? '').toString();

                setState(() {
                  _doctors.remove(doctor);
                });

                Navigator.pop(dialogContext);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Doctor deleted successfully.')),
                );

                if (docId.isNotEmpty) {
                  try {
                    await ApiService.deleteDoctor(doctorId: docId);
                  } catch (e) {
                    debugPrint("[DoctorsScreen Admin] deleteDoctor API error: $e");
                  }
                }
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
