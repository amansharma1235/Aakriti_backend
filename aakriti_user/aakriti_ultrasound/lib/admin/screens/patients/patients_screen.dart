import 'package:aakriti_ultrasound/admin/screens/patients/patient_details_screen.dart';
import 'package:aakriti_ultrasound/admin/screens/services/api_service.dart';
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';

class PatientsScreen extends StatefulWidget {
  const PatientsScreen({super.key});

  @override
  State<PatientsScreen> createState() => _PatientsScreenState();
}

class _PatientsScreenState extends State<PatientsScreen> {
  final TextEditingController searchController = TextEditingController();

  String searchText = '';
  String selectedStatus = 'All';

  int patientCounter = 130;

  bool isLoading = true;
  String? apiError;

  final List<Map<String, dynamic>> patients = [];

  @override
  void initState() {
    super.initState();
    _loadPatientsFromApi();
  }

  // =========================================================
  // LOAD PATIENTS FROM FASTAPI + MYSQL
  // =========================================================

  Future<void> _loadPatientsFromApi() async {
    try {
      final data = await ApiService.getPatients();

      if (!mounted) return;

      setState(() {
        patients.clear();

        for (final item in data) {
          patients.add({
            'id': item['patient_id']?.toString() ?? '',
            'name': item['full_name']?.toString() ?? '',
            'mobile': item['mobile']?.toString() ?? '',
            'age': item['age']?.toString() ?? '',
            'gender': item['gender']?.toString() ?? '',
            'email': item['email']?.toString() ?? '',
            'bloodGroup': item['blood_group']?.toString() ?? '',
            'address': item['address']?.toString() ?? '',
            'test': 'No test recorded',
            'date': item['created_at']?.toString() ?? 'New Patient',
            'status': item['status']?.toString() ?? 'Active',
          });
        }

        isLoading = false;
        apiError = null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
        apiError = 'Unable to load patients from server.';
      });
    }
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  // =========================================================
  // FILTERED PATIENTS
  // =========================================================

  List<Map<String, dynamic>> get filteredPatients {
    return patients.where((patient) {
      final query = searchText.toLowerCase().trim();

      final matchesSearch =
          patient['name'].toString().toLowerCase().contains(query) ||
          patient['id'].toString().toLowerCase().contains(query) ||
          patient['mobile'].toString().contains(query);

      final matchesStatus =
          selectedStatus == 'All' ||
          patient['status'].toString() == selectedStatus;

      return matchesSearch && matchesStatus;
    }).toList();
  }

  // =========================================================
  // BUILD
  // =========================================================

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

          const SizedBox(height: 22),

          _buildSummaryCards(isMobile, isTablet),

          const SizedBox(height: 22),

          _buildSearchFilterSection(isMobile),

          const SizedBox(height: 20),

          if (isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(50),
                child: CircularProgressIndicator(color: Color(0xFF1677FF)),
              ),
            )
          else if (apiError != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(30),
                child: Column(
                  children: [
                    const Icon(
                      Icons.cloud_off_rounded,
                      size: 50,
                      color: Color(0xFF94A3B8),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      apiError!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 15),
                    ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          isLoading = true;
                          apiError = null;
                        });

                        _loadPatientsFromApi();
                      },
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            )
          else if (filteredPatients.isEmpty)
            const _EmptyPatients()
          else if (isMobile)
            _buildMobileList()
          else
            _buildDesktopTable(),

          const SizedBox(height: 30),
        ],
      ),
    );
  }

  // =========================================================
  // HEADER
  // =========================================================

  Widget _buildHeader(bool isMobile) {
    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Patients',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: Color(0xFF071A2B),
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'Manage patients and their medical records.',
            style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 16),
          SizedBox(width: double.infinity, child: _addPatientButton()),
        ],
      );
    }

    return Row(
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Patients',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF071A2B),
                ),
              ),
              SizedBox(height: 5),
              Text(
                'Manage patients and their medical records.',
                style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
              ),
            ],
          ),
        ),
        _addPatientButton(),
      ],
    );
  }

  Widget _addPatientButton() {
    return ElevatedButton.icon(
      onPressed: () => _showPatientDialog(),
      icon: const Icon(Icons.person_add_alt_1_rounded, size: 19),
      label: const Text(
        'Add Patient',
        style: TextStyle(fontWeight: FontWeight.w700),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF1677FF),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // =========================================================
  // SUMMARY
  // =========================================================

  Widget _buildSummaryCards(bool isMobile, bool isTablet) {
    final total = patients.length;

    final active = patients.where((p) => p['status'] == 'Active').length;

    final inactive = patients.where((p) => p['status'] == 'Inactive').length;

    if (isMobile) {
      return Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _SummaryCard(
                  title: 'Total Patients',
                  value: '$total',
                  icon: Icons.people_alt_outlined,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SummaryCard(
                  title: 'Active',
                  value: '$active',
                  icon: Icons.verified_user_outlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _SummaryCard(
            title: 'Inactive',
            value: '$inactive',
            icon: Icons.person_off_outlined,
            fullWidth: true,
          ),
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          child: _SummaryCard(
            title: 'Total Patients',
            value: '$total',
            icon: Icons.people_alt_outlined,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _SummaryCard(
            title: 'Active Patients',
            value: '$active',
            icon: Icons.verified_user_outlined,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _SummaryCard(
            title: 'Inactive Patients',
            value: '$inactive',
            icon: Icons.person_off_outlined,
          ),
        ),
      ],
    );
  }

  // =========================================================
  // SEARCH + FILTER
  // =========================================================

  Widget _buildSearchFilterSection(bool isMobile) {
    if (isMobile) {
      return Column(
        children: [_searchBox(), const SizedBox(height: 12), _statusFilter()],
      );
    }

    return Row(
      children: [
        Expanded(child: _searchBox()),
        const SizedBox(width: 12),
        SizedBox(width: 190, child: _statusFilter()),
      ],
    );
  }

  Widget _searchBox() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardBg(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border(context)),
      ),
      child: TextField(
        controller: searchController,
        style: TextStyle(color: AppTheme.textPrimary(context)),
        onChanged: (value) {
          setState(() {
            searchText = value;
          });
        },
        decoration: InputDecoration(
          hintText: 'Search name, ID or mobile number',
          hintStyle: TextStyle(color: AppTheme.textSecondary(context)),
          prefixIcon: Icon(Icons.search_rounded, color: AppTheme.textSecondary(context)),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          fillColor: Colors.transparent,
          filled: false,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  Widget _statusFilter() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardBg(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border(context)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedStatus,
          isExpanded: true,
          dropdownColor: AppTheme.cardBg(context),
          style: TextStyle(color: AppTheme.textPrimary(context), fontWeight: FontWeight.w600),
          icon: Icon(Icons.keyboard_arrow_down_rounded, color: AppTheme.textSecondary(context)),
          items: const [
            DropdownMenuItem(value: 'All', child: Text('All Status')),
            DropdownMenuItem(value: 'Active', child: Text('Active')),
            DropdownMenuItem(value: 'Inactive', child: Text('Inactive')),
          ],
          onChanged: (value) {
            if (value == null) return;

            setState(() {
              selectedStatus = value;
            });
          },
        ),
      ),
    );
  }

  // =========================================================
  // MOBILE LIST
  // =========================================================

  Widget _buildMobileList() {
    return Column(
      children: filteredPatients.map((patient) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _MobilePatientCard(
            patient: patient,
            onView: () => _showPatientDetails(patient),
            onEdit: () => _showPatientDialog(patient: patient),
            onDelete: () => _deletePatient(patient),
          ),
        );
      }).toList(),
    );
  }

  // =========================================================
  // DESKTOP TABLE
  // =========================================================

  Widget _buildDesktopTable() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.cardBg(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.border(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: AppTheme.isDark(context) ? 0.2 : 0.025),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowHeight: 56,
            dataRowMinHeight: 70,
            dataRowMaxHeight: 82,
            columnSpacing: 28,
            headingRowColor: WidgetStateProperty.all(AppTheme.surfaceBg(context)),
            columns: [
              DataColumn(
                label: Text(
                  'Patient',
                  style: TextStyle(fontWeight: FontWeight.w800, color: AppTheme.textPrimary(context)),
                ),
              ),
              DataColumn(
                label: Text(
                  'Patient ID',
                  style: TextStyle(fontWeight: FontWeight.w800, color: AppTheme.textPrimary(context)),
                ),
              ),
              DataColumn(
                label: Text(
                  'Mobile',
                  style: TextStyle(fontWeight: FontWeight.w800, color: AppTheme.textPrimary(context)),
                ),
              ),
              DataColumn(
                label: Text(
                  'Age / Gender',
                  style: TextStyle(fontWeight: FontWeight.w800, color: AppTheme.textPrimary(context)),
                ),
              ),
              DataColumn(
                label: Text(
                  'Last Test',
                  style: TextStyle(fontWeight: FontWeight.w800, color: AppTheme.textPrimary(context)),
                ),
              ),
              DataColumn(
                label: Text(
                  'Status',
                  style: TextStyle(fontWeight: FontWeight.w800, color: AppTheme.textPrimary(context)),
                ),
              ),
              DataColumn(
                label: Text(
                  'Actions',
                  style: TextStyle(fontWeight: FontWeight.w800, color: AppTheme.textPrimary(context)),
                ),
              ),
            ],
            rows: filteredPatients.map((patient) {
              return DataRow(
                cells: [
                  DataCell(
                    Row(
                      children: [
                        _avatar(patient['name']),
                        const SizedBox(width: 10),
                        Text(
                          patient['name'],
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                  DataCell(
                    Text(
                      patient['id'],
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textSecondary(context),
                      ),
                    ),
                  ),
                  DataCell(Text(patient['mobile'], style: TextStyle(color: AppTheme.textPrimary(context)))),
                  DataCell(Text('${patient['age']} / ${patient['gender']}', style: TextStyle(color: AppTheme.textSecondary(context)))),
                  DataCell(
                    SizedBox(
                      width: 170,
                      child: Text(
                        patient['test'],
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: AppTheme.textPrimary(context)),
                      ),
                    ),
                  ),
                  DataCell(_StatusBadge(status: patient['status'])),
                  DataCell(
                    Row(
                      children: [
                        _TableAction(
                          icon: Icons.visibility_outlined,
                          tooltip: 'View',
                          onTap: () {
                            _showPatientDetails(patient);
                          },
                        ),
                        _TableAction(
                          icon: Icons.edit_outlined,
                          tooltip: 'Edit',
                          onTap: () {
                            _showPatientDialog(patient: patient);
                          },
                        ),
                        _TableAction(
                          icon: Icons.delete_outline_rounded,
                          tooltip: 'Delete',
                          onTap: () {
                            _deletePatient(patient);
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  // =========================================================
  // ADD / EDIT PATIENT
  // =========================================================

  void _showPatientDialog({Map<String, dynamic>? patient}) {
    final isEditing = patient != null;

    final nameController = TextEditingController(text: patient?['name'] ?? '');

    final mobileController = TextEditingController(
      text: patient?['mobile'] ?? '',
    );

    final ageController = TextEditingController(text: patient?['age'] ?? '');

    final emailController = TextEditingController(
      text: patient?['email'] ?? '',
    );

    final addressController = TextEditingController(
      text: patient?['address'] ?? '',
    );

    String gender = patient?['gender'] ?? 'Male';
    String bloodGroup = patient?['bloodGroup'] ?? 'A+';
    String status = patient?['status'] ?? 'Active';

    bool saving = false;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final dialogWidth = MediaQuery.of(context).size.width;

            final isSmall = dialogWidth < 600;

            Future<void> savePatient() async {
              if (nameController.text.trim().isEmpty ||
                  mobileController.text.trim().isEmpty ||
                  ageController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please fill Name, Mobile and Age.'),
                  ),
                );
                return;
              }

              // =================================================
              // EDIT PATIENT
              // =================================================

              if (isEditing) {
                setState(() {
                  patient['name'] = nameController.text.trim();

                  patient['mobile'] = mobileController.text.trim();

                  patient['age'] = ageController.text.trim();

                  patient['gender'] = gender;

                  patient['bloodGroup'] = bloodGroup;

                  patient['email'] = emailController.text.trim();

                  patient['address'] = addressController.text.trim();

                  patient['status'] = status;
                });

                Navigator.pop(dialogContext);

                ScaffoldMessenger.of(this.context).showSnackBar(
                  const SnackBar(content: Text('Patient updated successfully')),
                );

                return;
              }

              // =================================================
              // ADD PATIENT TO FASTAPI + MYSQL
              // =================================================

              setDialogState(() {
                saving = true;
              });

              try {
                patientCounter++;

                final patientId = 'AKR$patientCounter';

                await ApiService.addPatient(
                  patientId: patientId,
                  fullName: nameController.text.trim(),
                  mobile: mobileController.text.trim(),
                  age: ageController.text.trim(),
                  gender: gender,
                  bloodGroup: bloodGroup,
                  email: emailController.text.trim(),
                  address: addressController.text.trim(),
                );

                if (!mounted || !dialogContext.mounted) return;

                Navigator.pop(dialogContext);

                ScaffoldMessenger.of(this.context).showSnackBar(
                  const SnackBar(
                    content: Text('Patient added successfully to database!'),
                    backgroundColor: Color(0xFF159570),
                  ),
                );

                // =================================================
                // RELOAD DATA FROM MYSQL
                // =================================================

                setState(() {
                  isLoading = true;
                  apiError = null;
                });

                await _loadPatientsFromApi();
              } catch (e) {
                setDialogState(() {
                  saving = false;
                });

                if (!mounted) return;

                ScaffoldMessenger.of(this.context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to add patient: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }

            return AlertDialog(
              backgroundColor: AppTheme.cardBg(context),
              scrollable: true,
              title: Text(
                isEditing ? 'Edit Patient' : 'Add New Patient',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary(context),
                ),
              ),
              content: SizedBox(
                width: isSmall ? double.maxFinite : 620,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _dialogTextField(
                              controller: nameController,
                              label: 'Full Name',
                              icon: Icons.person_outline,
                            ),
                          ),
                          if (!isSmall) ...[
                            const SizedBox(width: 12),
                            Expanded(
                              child: _dialogTextField(
                                controller: mobileController,
                                label: 'Mobile Number',
                                icon: Icons.phone_outlined,
                                keyboardType: TextInputType.phone,
                              ),
                            ),
                          ],
                        ],
                      ),

                      if (isSmall) ...[
                        const SizedBox(height: 12),
                        _dialogTextField(
                          controller: mobileController,
                          label: 'Mobile Number',
                          icon: Icons.phone_outlined,
                          keyboardType: TextInputType.phone,
                        ),
                      ],

                      if (isSmall) ...[
                        const SizedBox(height: 12),
                        _dialogTextField(
                          controller: ageController,
                          label: 'Age',
                          icon: Icons.cake_outlined,
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: 12),
                        _dialogDropdown(
                          label: 'Gender',
                          value: gender,
                          items: const ['Male', 'Female', 'Other'],
                          onChanged: (value) {
                            setDialogState(() {
                              gender = value;
                            });
                          },
                        ),
                        const SizedBox(height: 12),
                        _dialogDropdown(
                          label: 'Blood Group',
                          value: bloodGroup,
                          items: const [
                            'A+',
                            'A-',
                            'B+',
                            'B-',
                            'AB+',
                            'AB-',
                            'O+',
                            'O-',
                          ],
                          onChanged: (value) {
                            setDialogState(() {
                              bloodGroup = value;
                            });
                          },
                        ),
                        const SizedBox(height: 12),
                        _dialogDropdown(
                          label: 'Status',
                          value: status,
                          items: const ['Active', 'Inactive'],
                          onChanged: (value) {
                            setDialogState(() {
                              status = value;
                            });
                          },
                        ),
                      ] else ...[
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _dialogTextField(
                                controller: ageController,
                                label: 'Age',
                                icon: Icons.cake_outlined,
                                keyboardType: TextInputType.number,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _dialogDropdown(
                                label: 'Gender',
                                value: gender,
                                items: const ['Male', 'Female', 'Other'],
                                onChanged: (value) {
                                  setDialogState(() {
                                    gender = value;
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _dialogDropdown(
                                label: 'Blood Group',
                                value: bloodGroup,
                                items: const [
                                  'A+',
                                  'A-',
                                  'B+',
                                  'B-',
                                  'AB+',
                                  'AB-',
                                  'O+',
                                  'O-',
                                ],
                                onChanged: (value) {
                                  setDialogState(() {
                                    bloodGroup = value;
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _dialogDropdown(
                                label: 'Status',
                                value: status,
                                items: const ['Active', 'Inactive'],
                                onChanged: (value) {
                                  setDialogState(() {
                                    status = value;
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                      ],

                      const SizedBox(height: 12),

                      _dialogTextField(
                        controller: emailController,
                        label: 'Email Address',
                        icon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                      ),

                      const SizedBox(height: 12),

                      _dialogTextField(
                        controller: addressController,
                        label: 'Address',
                        icon: Icons.location_on_outlined,
                        maxLines: 2,
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: saving
                      ? null
                      : () {
                          Navigator.pop(dialogContext);
                        },
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: saving ? null : savePatient,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1677FF),
                    foregroundColor: Colors.white,
                  ),
                  child: saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(isEditing ? 'Update' : 'Add Patient'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // =========================================================
  // VIEW DETAILS
  // =========================================================

  void _showPatientDetails(Map<String, dynamic> patient) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PatientDetailsScreen(patientData: patient),
      ),
    );
  }

  // =========================================================
  // DELETE
  // =========================================================

  void _deletePatient(Map<String, dynamic> patient) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Delete Patient?',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          content: Text('Are you sure you want to delete ${patient['name']}?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final patientId = patient['patient_id'] ?? patient['id'];
                setState(() {
                  patients.removeWhere((p) =>
                      p == patient ||
                      (patientId != null && (p['patient_id'] == patientId || p['id'] == patientId)));
                });

                Navigator.pop(context);

                if (patientId != null) {
                  ApiService.deletePatient(id: patientId);
                }

                ScaffoldMessenger.of(this.context).showSnackBar(
                  const SnackBar(content: Text('Patient deleted successfully')),
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

  // =========================================================
  // HELPERS
  // =========================================================

  Widget _dialogTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: TextStyle(color: AppTheme.textPrimary(context)),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppTheme.textSecondary(context)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _dialogDropdown({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      isExpanded: true,
      initialValue: value,
      dropdownColor: AppTheme.cardBg(context),
      style: TextStyle(color: AppTheme.textPrimary(context), fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      items: items.map((item) {
        return DropdownMenuItem(
          value: item,
          child: Text(
            item,
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList(),
      onChanged: (value) {
        if (value != null) {
          onChanged(value);
        }
      },
    );
  }

  Widget _avatar(String name, {double radius = 22}) {
    final safeName = name.trim().isEmpty ? '?' : name.trim();

    return CircleAvatar(
      radius: radius,
      backgroundColor: const Color(0xFFEAF2FF),
      child: Text(
        safeName.substring(0, 1).toUpperCase(),
        style: TextStyle(
          fontSize: radius * 0.7,
          fontWeight: FontWeight.w800,
          color: const Color(0xFF1677FF),
        ),
      ),
    );
  }
}

// =============================================================
// SUMMARY CARD
// =============================================================

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final bool fullWidth;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: fullWidth ? double.infinity : null,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBg(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border(context)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primaryBlue.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.primaryBlue),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
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
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary(context),
                    ),
                  ),
                ),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11, color: AppTheme.textSecondary(context)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================
// MOBILE PATIENT CARD
// =============================================================

class _MobilePatientCard extends StatelessWidget {
  final Map<String, dynamic> patient;
  final VoidCallback onView;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _MobilePatientCard({
    required this.patient,
    required this.onView,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final patientName = patient['name'].toString();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBg(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.border(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: AppTheme.isDark(context) ? 0.2 : 0.025),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 25,
                backgroundColor: AppColors.primaryBlue.withValues(alpha: 0.12),
                child: Text(
                  patientName.isEmpty
                      ? '?'
                      : patientName.substring(0, 1).toUpperCase(),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryBlue,
                  ),
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      patient['name'],
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary(context),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      patient['id'],
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary(context),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              _StatusBadge(status: patient['status']),
            ],
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              Icon(
                Icons.phone_outlined,
                size: 17,
                color: AppTheme.textSecondary(context),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  patient['mobile'],
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 13, color: AppTheme.textPrimary(context)),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  '${patient['age']} yrs • ${patient['gender']}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: AppTheme.textSecondary(context)),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          Row(
            children: [
              Icon(
                Icons.medical_information_outlined,
                size: 17,
                color: AppTheme.textSecondary(context),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  patient['test'],
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.textSecondary(context),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          Divider(color: AppTheme.border(context)),

          const SizedBox(height: 4),

          Row(
            children: [
              Expanded(
                child: _MobileAction(
                  icon: Icons.visibility_outlined,
                  title: 'View',
                  onTap: onView,
                ),
              ),
              Expanded(
                child: _MobileAction(
                  icon: Icons.edit_outlined,
                  title: 'Edit',
                  onTap: onEdit,
                ),
              ),
              Expanded(
                child: _MobileAction(
                  icon: Icons.delete_outline_rounded,
                  title: 'Delete',
                  onTap: onDelete,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// =============================================================
// STATUS BADGE
// =============================================================

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final isActive = status == 'Active';
    final isDark = AppTheme.isDark(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isActive
            ? (isDark ? const Color(0xFF064E3B).withValues(alpha: 0.5) : const Color(0xFFE8F8F2))
            : (isDark ? const Color(0xFF7F1D1D).withValues(alpha: 0.5) : const Color(0xFFFFF1F1)),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isActive
              ? (isDark ? const Color(0xFF059669) : const Color(0xFFA7F3D0))
              : (isDark ? const Color(0xFFDC2626) : const Color(0xFFFECACA)),
          width: 0.8,
        ),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: isActive
              ? (isDark ? const Color(0xFF34D399) : const Color(0xFF159570))
              : (isDark ? const Color(0xFFF87171) : const Color(0xFFE04747)),
        ),
      ),
    );
  }
}

// =============================================================
// TABLE ACTION
// =============================================================

class _TableAction extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _TableAction({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onTap,
      icon: Icon(icon, size: 19, color: const Color(0xFF475569)),
    );
  }
}

// =============================================================
// MOBILE ACTION
// =============================================================

class _MobileAction extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _MobileAction({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          children: [
            Icon(icon, size: 19, color: AppColors.primaryBlue),
            const SizedBox(height: 3),
            Text(
              title,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}



// =============================================================
// EMPTY STATE
// =============================================================

class _EmptyPatients extends StatelessWidget {
  const _EmptyPatients();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 55, horizontal: 20),
      decoration: BoxDecoration(
        color: AppTheme.cardBg(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.border(context)),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.person_search_outlined,
            size: 55,
            color: Color(0xFF94A3B8),
          ),
          const SizedBox(height: 14),
          Text(
            'No patients found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary(context),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Try another search or change the status filter.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: AppTheme.textSecondary(context)),
          ),
        ],
      ),
    );
  }
}
