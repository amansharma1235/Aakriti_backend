import 'package:flutter/material.dart';
import 'package:aakriti_admin/screens/services/api_service.dart';
import 'package:aakriti_admin/theme/app_theme.dart';

class ServicesScreen extends StatefulWidget {
  const ServicesScreen({super.key});

  @override
  State<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends State<ServicesScreen> {
  final TextEditingController searchController = TextEditingController();

  String selectedCategory = 'All';
  String selectedStatus = 'All';

  final List<Map<String, dynamic>> services = [
    {
      'id': 'SRV001',
      'name': 'Ultrasound Whole Abdomen',
      'category': 'Ultrasound',
      'description': 'High-resolution scan of Liver, Gallbladder, Pancreas, Spleen & Kidneys',
      'price': '₹1,200',
      'duration': '20 min',
      'status': 'Active',
    },
    {
      'id': 'SRV002',
      'name': 'Obstetric Ultrasound (Level II / TIFFA Scan)',
      'category': 'Ultrasound',
      'description': 'Targeted Imaging for Fetal Anomalies & detailed anatomical screening',
      'price': '₹2,500',
      'duration': '35 min',
      'status': 'Active',
    },
    {
      'id': 'SRV003',
      'name': 'Pelvic & Lower Abdomen Ultrasound (USG Pelvis)',
      'category': 'Ultrasound',
      'description': 'Transabdominal sonography for Uterus, Ovaries & Urinary Bladder',
      'price': '₹1,000',
      'duration': '20 min',
      'status': 'Active',
    },
    {
      'id': 'SRV004',
      'name': 'Color Doppler - Lower Limb (Arterial & Venous)',
      'category': 'Doppler',
      'description': 'Duplex vascular imaging for Deep Vein Thrombosis (DVT) & arterial stenosis',
      'price': '₹3,000',
      'duration': '35 min',
      'status': 'Active',
    },
    {
      'id': 'SRV005',
      'name': 'Thyroid & Neck Ultrasound with Doppler',
      'category': 'Doppler',
      'description': 'High-frequency linear probe assessment for thyroid nodules & vascularity',
      'price': '₹1,100',
      'duration': '15 min',
      'status': 'Active',
    },
    {
      'id': 'SRV006',
      'name': 'KUB & Prostate Ultrasound',
      'category': 'Ultrasound',
      'description': 'Kidneys, Ureters, Urinary Bladder & Prostate pre/post-void scan',
      'price': '₹900',
      'duration': '15 min',
      'status': 'Active',
    },
    {
      'id': 'SRV007',
      'name': 'Bilateral Breast Ultrasound (Sonomammography)',
      'category': 'Ultrasound',
      'description': 'Dedicated high-resolution acoustic screening for breast tissue & axilla',
      'price': '₹1,600',
      'duration': '25 min',
      'status': 'Active',
    },
    {
      'id': 'SRV008',
      'name': 'Scrotal & Testicular Color Doppler',
      'category': 'Doppler',
      'description': 'Color Doppler evaluation for varicocele, torsion & epididymal pathology',
      'price': '₹1,400',
      'duration': '20 min',
      'status': 'Active',
    },
    {
      'id': 'SRV009',
      'name': 'Early Pregnancy / Viability & NT/NB Scan',
      'category': 'Ultrasound',
      'description': '11-13.6 weeks sonographic screening for nuchal translucency & nasal bone',
      'price': '₹1,800',
      'duration': '25 min',
      'status': 'Active',
    },
    {
      'id': 'SRV010',
      'name': 'Musculoskeletal (MSK) Ultrasound (Shoulder/Knee)',
      'category': 'Ultrasound',
      'description': 'High-resolution imaging for rotator cuff, tendonitis & joint effusions',
      'price': '₹1,800',
      'duration': '25 min',
      'status': 'Active',
    },
    {
      'id': 'SRV011',
      'name': 'Follicular Monitoring & Ovulation Study (Series)',
      'category': 'Ultrasound',
      'description': 'Serial transvaginal / transabdominal tracking of dominant follicles',
      'price': '₹1,500',
      'duration': '15 min',
      'status': 'Active',
    },
    {
      'id': 'SRV012',
      'name': 'Complete Blood Count (CBC) with ESR',
      'category': 'Pathology',
      'description': 'Comprehensive automated hematology profile and differential count',
      'price': '₹350',
      'duration': '15 min',
      'status': 'Active',
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadServicesFromApi();
  }

  Future<void> _loadServicesFromApi() async {
    try {
      final list = await ApiService.getServices();
      if (list.isNotEmpty && mounted) {
        setState(() {
          services.clear();
          for (final item in list) {
            services.add({
              'id': item['service_id'] ?? 'SRV${services.length + 1}',
              'name': item['service_name'] ?? 'Ultrasound Procedure',
              'category': item['category'] ?? 'Ultrasound',
              'description': item['description'] ?? 'Diagnostic medical imaging',
              'price': item['price'] != null ? '₹${item['price']}' : '₹1,000',
              'duration': item['duration'] ?? '20 min',
              'status': item['status'] ?? 'Active',
            });
          }
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get filteredServices {
    final search = searchController.text.toLowerCase();

    return services.where((service) {
      final matchesSearch =
          service['name'].toString().toLowerCase().contains(search) ||
          service['id'].toString().toLowerCase().contains(search) ||
          service['category'].toString().toLowerCase().contains(search);

      final matchesCategory =
          selectedCategory == 'All' || service['category'] == selectedCategory;

      final matchesStatus =
          selectedStatus == 'All' || service['status'] == selectedStatus;

      return matchesSearch && matchesCategory && matchesStatus;
    }).toList();
  }

  int get totalServices => services.length;

  int get activeServices =>
      services.where((service) => service['status'] == 'Active').length;

  int get inactiveServices =>
      services.where((service) => service['status'] == 'Inactive').length;

  int get imagingServices =>
      services.where((service) => service['category'] == 'Imaging').length;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    if (width < 700) {
      return _mobileLayout();
    }

    if (width < 1100) {
      return _tabletLayout();
    }

    return _desktopLayout();
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
          _desktopHeader(),
          const SizedBox(height: 24),
          _summaryCards(4),
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
          _desktopHeader(),
          const SizedBox(height: 20),
          _summaryCards(2),
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
          _summaryCards(2),
          const SizedBox(height: 20),
          _filterSection(),
          const SizedBox(height: 20),
          ...filteredServices.map(
            (service) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _serviceCard(service),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // HEADER
  // =========================================================

  Widget _desktopHeader() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Services & Tests',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary(context),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Manage ultrasound, pathology and diagnostic services',
                style: TextStyle(fontSize: 14, color: AppTheme.textSecondary(context)),
              ),
            ],
          ),
        ),
        ElevatedButton.icon(
          onPressed: _showAddServiceDialog,
          icon: const Icon(Icons.add),
          label: const Text('Add Service'),
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
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Services & Tests',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary(context),
                ),
              ),
              const SizedBox(height: 5),
              Text(
                'Manage diagnostic services',
                style: TextStyle(fontSize: 12, color: AppTheme.textSecondary(context)),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: _showAddServiceDialog,
          style: IconButton.styleFrom(
            backgroundColor: const Color(0xFF1677FF),
            foregroundColor: Colors.white,
          ),
          icon: const Icon(Icons.add),
        ),
      ],
    );
  }

  // =========================================================
  // SUMMARY CARDS
  // =========================================================

  Widget _summaryCards(int crossAxisCount) {
    final bool isMobile = crossAxisCount == 2;

    return GridView.count(
      crossAxisCount: crossAxisCount,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: isMobile ? 10 : 14,
      mainAxisSpacing: isMobile ? 10 : 14,
      childAspectRatio: isMobile ? 1.45 : 2.1,
      children: [
        _summaryCard(
          'Total Services',
          totalServices.toString(),
          Icons.medical_services_outlined,
          const Color(0xFF1677FF),
          isMobile: isMobile,
        ),
        _summaryCard(
          'Active',
          activeServices.toString(),
          Icons.check_circle_outline,
          Colors.green,
          isMobile: isMobile,
        ),
        _summaryCard(
          'Inactive',
          inactiveServices.toString(),
          Icons.pause_circle_outline,
          Colors.orange,
          isMobile: isMobile,
        ),
        _summaryCard(
          'Imaging',
          imagingServices.toString(),
          Icons.image_outlined,
          Colors.teal,
          isMobile: isMobile,
        ),
      ],
    );
  }

  Widget _summaryCard(
    String title,
    String value,
    IconData icon,
    Color iconColor, {
    bool isMobile = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: EdgeInsets.all(isMobile ? 10 : 16),
      decoration: BoxDecoration(
        color: AppTheme.cardBg(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            height: isMobile ? 38 : 46,
            width: isMobile ? 38 : 46,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: isMobile ? 20 : 24),
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
                SizedBox(height: isMobile ? 2 : 3),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: isMobile ? 18 : 21,
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

  // =========================================================
  // FILTER
  // =========================================================

  Widget _filterSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBg(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 480;

          if (isNarrow) {
            return Column(
              children: [
                _searchBox(),
                const SizedBox(height: 12),
                _categoryDropdown(),
                const SizedBox(height: 12),
                _statusDropdown(),
              ],
            );
          }

          if (constraints.maxWidth < 650) {
            return Column(
              children: [
                _searchBox(),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _categoryDropdown()),
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
              SizedBox(width: 180, child: _categoryDropdown()),
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
      controller: searchController,
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        hintText: 'Search service, category or ID',
        prefixIcon: const Icon(Icons.search),
        filled: true,
        fillColor: isDark ? const Color(0xFF14273A) : const Color(0xFFF4F8FC),
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

  Widget _categoryDropdown() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final List<String> categories = [
      'All',
      'Ultrasound',
      'Doppler',
      'Imaging',
      'Pathology',
      'Radiology',
      'Diagnostic',
      'Cardiology',
    ];
    if (!categories.contains(selectedCategory)) {
      categories.add(selectedCategory);
    }

    return DropdownButtonFormField<String>(
      initialValue: selectedCategory,
      decoration: InputDecoration(
        labelText: 'Category',
        filled: true,
        fillColor: isDark ? const Color(0xFF14273A) : const Color(0xFFF4F8FC),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.border(context)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.border(context)),
        ),
      ),
      items: categories
          .map((cat) => DropdownMenuItem(
                value: cat,
                child: Text(cat == 'All' ? 'All Categories' : cat),
              ))
          .toList(),
      onChanged: (value) {
        if (value == null) return;

        setState(() {
          selectedCategory = value;
        });
      },
    );
  }

  Widget _statusDropdown() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return DropdownButtonFormField<String>(
      initialValue: selectedStatus,
      decoration: InputDecoration(
        labelText: 'Status',
        filled: true,
        fillColor: isDark ? const Color(0xFF14273A) : const Color(0xFFF4F8FC),
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
          selectedStatus = value;
        });
      },
    );
  }

  // =========================================================
  // DESKTOP TABLE
  // =========================================================

  Widget _desktopTable() {
    final data = filteredServices;

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
            DataColumn(label: Text('Service')),
            DataColumn(label: Text('Category')),
            DataColumn(label: Text('Description')),
            DataColumn(label: Text('Price')),
            DataColumn(label: Text('Duration')),
            DataColumn(label: Text('Status')),
            DataColumn(label: Text('Actions')),
          ],
          rows: data.map((service) {
            return DataRow(
              cells: [
                DataCell(
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        height: 38,
                        width: 38,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1677FF).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.medical_services_outlined,
                          color: Color(0xFF1677FF),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            service['name'],
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary(context),
                            ),
                          ),
                          Text(
                            service['id'],
                            style: TextStyle(
                              fontSize: 10,
                              color: AppTheme.textSecondary(context),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                DataCell(_categoryChip(service['category'])),
                DataCell(
                  SizedBox(
                    width: 180,
                    child: Text(
                      service['description'],
                      style: TextStyle(color: AppTheme.textPrimary(context)),
                    ),
                  ),
                ),
                DataCell(
                  Text(
                    service['price'],
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary(context),
                    ),
                  ),
                ),
                DataCell(
                  Text(
                    service['duration'],
                    style: TextStyle(color: AppTheme.textPrimary(context)),
                  ),
                ),
                DataCell(_statusChip(service['status'])),
                DataCell(
                  Row(
                    children: [
                      IconButton(
                        tooltip: 'View',
                        onPressed: () {
                          _showServiceDetails(service);
                        },
                        icon: const Icon(Icons.visibility_outlined),
                      ),
                      IconButton(
                        tooltip: 'Edit',
                        onPressed: () {
                          _showEditServiceDialog(service);
                        },
                        icon: const Icon(Icons.edit_outlined),
                      ),
                      IconButton(
                        tooltip: 'Delete',
                        onPressed: () {
                          _deleteService(service);
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

  Widget _serviceCard(Map<String, dynamic> service) {
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
              Container(
                height: 45,
                width: 45,
                decoration: BoxDecoration(
                  color: const Color(0xFF1677FF).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.medical_services_outlined,
                  color: Color(0xFF1677FF),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      service['name'],
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary(context),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      service['id'],
                      style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.textSecondary(context),
                      ),
                    ),
                  ],
                ),
              ),
              _statusChip(service['status']),
            ],
          ),
          const SizedBox(height: 15),
          Text(
            service['description'],
            style: TextStyle(color: AppTheme.textSecondary(context), fontSize: 13),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _smallInfo(Icons.category_outlined, service['category']),
              _smallInfo(Icons.currency_rupee, service['price']),
              _smallInfo(Icons.access_time, service['duration']),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    _showServiceDetails(service);
                  },
                  icon: const Icon(Icons.visibility_outlined, size: 18),
                  label: const Text('View'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    _showEditServiceDialog(service);
                  },
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text('Edit'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _smallInfo(IconData icon, String text) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF14273A) : const Color(0xFFF4F8FC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.border(context)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: const Color(0xFF1677FF)),
          const SizedBox(width: 5),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppTheme.textPrimary(context),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // CHIPS
  // =========================================================

  Widget _categoryChip(String category) {
    final color = category == 'Imaging' ? Colors.blue : Colors.purple;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        category,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _statusChip(String status) {
    final color = status == 'Active' ? Colors.green : Colors.orange;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
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

  // =========================================================
  // VIEW DETAILS
  // =========================================================

  void _showServiceDetails(Map<String, dynamic> service) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) {
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 25),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Service Details',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 18),
                _detailRow('Service ID', service['id']),
                _detailRow('Service', service['name']),
                _detailRow('Category', service['category']),
                _detailRow('Description', service['description']),
                _detailRow('Price', service['price']),
                _detailRow('Duration', service['duration']),
                _detailRow('Status', service['status']),
                const SizedBox(height: 15),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _detailRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 105,
            child: Text(
              title,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // ADD SERVICE
  // =========================================================

  void _showAddServiceDialog() {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    final priceController = TextEditingController();
    final durationController = TextEditingController();

    String category = 'Ultrasound';
    final List<String> availableCategories = [
      'Ultrasound',
      'Doppler',
      'Imaging',
      'Pathology',
      'Radiology',
      'Diagnostic',
      'Cardiology',
      'Maternal',
      'General',
    ];

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              scrollable: true,
              title: const Text('Add Service'),
              content: SizedBox(
                width: 500,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _dialogField(
                        nameController,
                        'Service Name',
                        Icons.medical_services_outlined,
                      ),
                      _dialogField(
                        descriptionController,
                        'Description',
                        Icons.description_outlined,
                      ),
                      _dialogField(
                        priceController,
                        'Price',
                        Icons.currency_rupee,
                      ),
                      _dialogField(
                        durationController,
                        'Duration',
                        Icons.access_time,
                      ),
                      DropdownButtonFormField<String>(
                        initialValue: category,
                        decoration: const InputDecoration(
                          labelText: 'Category',
                          border: OutlineInputBorder(),
                        ),
                        items: availableCategories
                            .map((c) => DropdownMenuItem(
                                  value: c,
                                  child: Text(c),
                                ))
                            .toList(),
                        onChanged: (value) {
                          if (value == null) return;

                          setDialogState(() {
                            category = value;
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
                  onPressed: () async {
                    final sName = nameController.text.trim();
                    if (sName.isEmpty) return;

                    final priceVal = double.tryParse(priceController.text.trim().replaceAll('₹', '')) ?? 0.0;
                    final durVal = durationController.text.trim().isEmpty ? '15 min' : durationController.text.trim();
                    final descVal = descriptionController.text.trim().isEmpty ? 'Diagnostic service' : descriptionController.text.trim();
                    final newId = 'SRV${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';

                    setState(() {
                      services.insert(0, {
                        'id': newId,
                        'name': sName,
                        'category': category,
                        'description': descVal,
                        'price': '₹${priceVal.toInt()}',
                        'duration': durVal,
                        'status': 'Active',
                      });
                    });

                    final messenger = ScaffoldMessenger.of(context);
                    Navigator.pop(dialogContext);

                    try {
                      await ApiService.addService(
                        serviceId: newId,
                        serviceName: sName,
                        category: category,
                        price: priceVal,
                        duration: durVal,
                        description: descVal,
                        status: 'Active',
                      );
                      _loadServicesFromApi();
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text("Service '$sName' added successfully!"),
                          backgroundColor: const Color(0xFF10B981),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    } catch (_) {}
                  },
                  child: const Text('Add Service'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // =========================================================
  // EDIT SERVICE
  // =========================================================

  void _showEditServiceDialog(Map<String, dynamic> service) {
    final nameController = TextEditingController(text: service['name']);

    final descriptionController = TextEditingController(
      text: service['description'],
    );

    final priceController = TextEditingController(
      text: service['price'].toString().replaceAll('₹', ''),
    );

    final durationController = TextEditingController(text: service['duration']);

    String category = (service['category'] ?? 'Ultrasound').toString().trim();
    if (category.isEmpty) category = 'Ultrasound';
    String status = (service['status'] ?? 'Active').toString().trim();
    if (status.isEmpty) status = 'Active';

    final List<String> availableCategories = [
      'Ultrasound',
      'Doppler',
      'Imaging',
      'Pathology',
      'Radiology',
      'Diagnostic',
      'Cardiology',
      'Maternal',
      'General',
    ];
    if (!availableCategories.contains(category)) {
      availableCategories.add(category);
    }

    final List<String> availableStatuses = ['Active', 'Inactive'];
    if (!availableStatuses.contains(status)) {
      availableStatuses.add(status);
    }

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              scrollable: true,
              title: const Text('Edit Service'),
              content: SizedBox(
                width: 500,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _dialogField(
                        nameController,
                        'Service Name',
                        Icons.medical_services_outlined,
                      ),
                      _dialogField(
                        descriptionController,
                        'Description',
                        Icons.description_outlined,
                      ),
                      _dialogField(
                        priceController,
                        'Price',
                        Icons.currency_rupee,
                      ),
                      _dialogField(
                        durationController,
                        'Duration',
                        Icons.access_time,
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        initialValue: category,
                        decoration: const InputDecoration(
                          labelText: 'Category',
                          border: OutlineInputBorder(),
                        ),
                        items: availableCategories
                            .map((c) => DropdownMenuItem(
                                  value: c,
                                  child: Text(c),
                                ))
                            .toList(),
                        onChanged: (value) {
                          if (value == null) return;

                          setDialogState(() {
                            category = value;
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: status,
                        decoration: const InputDecoration(
                          labelText: 'Status',
                          border: OutlineInputBorder(),
                        ),
                        items: availableStatuses
                            .map((s) => DropdownMenuItem(
                                  value: s,
                                  child: Text(s),
                                ))
                            .toList(),
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
                  onPressed: () {
                    Navigator.pop(dialogContext);
                  },
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final sName = nameController.text.trim();
                    final sDesc = descriptionController.text.trim();
                    final sPriceStr = priceController.text.trim().replaceAll('₹', '');
                    final sPrice = double.tryParse(sPriceStr) ?? 0.0;
                    final sDur = durationController.text.trim();
                    final sId = service['id'] ?? service['service_id'] ?? '';

                    setState(() {
                      service['name'] = sName;
                      service['description'] = sDesc;
                      service['price'] = '₹${sPrice.toInt()}';
                      service['duration'] = sDur;
                      service['category'] = category;
                      service['status'] = status;
                    });

                    final messenger = ScaffoldMessenger.of(context);
                    Navigator.pop(dialogContext);

                    if (sId.toString().isNotEmpty) {
                      try {
                        await ApiService.updateService(
                          serviceId: sId.toString(),
                          serviceName: sName,
                          category: category,
                          price: sPrice,
                          duration: sDur,
                          description: sDesc,
                          status: status,
                        );
                        _loadServicesFromApi();
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text("Service '$sName' updated successfully!"),
                            backgroundColor: const Color(0xFF10B981),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      } catch (_) {}
                    }
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
  // DELETE
  // =========================================================

  void _deleteService(Map<String, dynamic> service) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete Service?'),
          content: Text('Are you sure you want to delete ${service['name']}?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                final serviceId = service['id'] ?? service['service_id'];
                setState(() {
                  services.removeWhere((s) =>
                      s == service ||
                      (serviceId != null && (s['id'] == serviceId || s['service_id'] == serviceId)));
                });

                Navigator.pop(dialogContext);

                if (serviceId != null) {
                  ApiService.deleteService(id: serviceId);
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
  // EMPTY STATE
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
            Icons.medical_services_outlined,
            size: 55,
            color: AppTheme.textSecondary(context),
          ),
          const SizedBox(height: 12),
          Text(
            'No services found',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
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
}
