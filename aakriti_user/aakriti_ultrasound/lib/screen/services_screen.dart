import 'package:flutter/material.dart';

import '../data/diagnostic_tests_data.dart';
import '../services/api_service.dart';
import '../widgets/diagnostic_test_card.dart';
import '../widgets/notification_app_bar_button.dart';
import 'appointment_screen.dart';
import 'blood_tests_screen.dart';
import 'health_packages_screen.dart';
import 'kidney_tests_screen.dart';
import 'lipid_profile_screen.dart';
import 'liver_tests_screen.dart';
import 'sugar_tests_screen.dart';
import 'thyroid_screen.dart';
import 'ultrasound_detail_screen.dart';

class ServicesScreen extends StatefulWidget {
  const ServicesScreen({super.key});

  @override
  State<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends State<ServicesScreen> {
  static const Color navy = Color(0xFF071A2B);
  static const Color blue = Color(0xFF1677FF);
  static const Color teal = Color(0xFF18C8C8);

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  // Dynamic services loaded from MySQL Backend
  List<Map<String, dynamic>> _dynamicServices = [];
  bool _isLoadingServices = true;
  String _selectedCategory = "All";

  // Static Diagnostic Departments
  final List<Map<String, dynamic>> departments = const [
    {
      "title": "Ultrasound",
      "subtitle": "Abdomen, Pelvic, KUB & Doppler",
      "startingPrice": "₹800",
      "badge": "7 Scans",
      "icon": Icons.monitor_heart_rounded,
      "color": Color(0xFF1677FF),
    },
    {
      "title": "Blood Tests",
      "subtitle": "CBC, Hemoglobin, ESR & Platelets",
      "startingPrice": "₹120",
      "badge": "5 Tests",
      "icon": Icons.bloodtype_rounded,
      "color": Color(0xFFE53935),
    },
    {
      "title": "Sugar Tests",
      "subtitle": "Fasting, PP & HbA1c screening",
      "startingPrice": "₹80",
      "badge": "3 Tests",
      "icon": Icons.water_drop_rounded,
      "color": Color(0xFF18C8C8),
    },
    {
      "title": "Thyroid",
      "subtitle": "T3, T4, TSH & Thyroid Panel",
      "startingPrice": "₹220",
      "badge": "2 Tests",
      "icon": Icons.healing_rounded,
      "color": Color(0xFF8E5CF7),
    },
    {
      "title": "Liver Tests",
      "subtitle": "SGOT, SGPT, Bilirubin & LFT",
      "startingPrice": "₹250",
      "badge": "2 Panels",
      "icon": Icons.local_hospital_rounded,
      "color": Color(0xFFFF8A3D),
    },
    {
      "title": "Kidney Tests",
      "subtitle": "Creatinine, Urea, Uric Acid & KFT",
      "startingPrice": "₹150",
      "badge": "2 Panels",
      "icon": Icons.health_and_safety_rounded,
      "color": Color(0xFF00B4D8),
    },
    {
      "title": "Lipid Profile",
      "subtitle": "Cholesterol, HDL, LDL & Triglycerides",
      "startingPrice": "₹650",
      "badge": "8 Parameters",
      "icon": Icons.favorite_rounded,
      "color": Color(0xFFE91E63),
    },
    {
      "title": "Health Packages",
      "subtitle": "Comprehensive full body checks",
      "startingPrice": "₹699",
      "badge": "4 Bundles",
      "icon": Icons.card_membership_rounded,
      "color": Color(0xFF10B981),
    },
  ];

  @override
  void initState() {
    super.initState();
    _fetchServices();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ============================================================
  // FETCH SERVICES FROM BACKEND API
  // ============================================================
  Future<void> _fetchServices() async {
    setState(() {
      _isLoadingServices = true;
    });

    try {
      final list = await ApiService.getServices();
      if (mounted) {
        setState(() {
          _dynamicServices = List<Map<String, dynamic>>.from(list);
          _isLoadingServices = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingServices = false;
        });
      }
    }
  }

  // Unique categories list
  List<String> get _availableCategories {
    final Set<String> cats = {"All"};
    for (final s in _dynamicServices) {
      final cat = s['category']?.toString().trim();
      if (cat != null && cat.isNotEmpty) {
        cats.add(cat);
      }
    }
    return cats.toList();
  }

  // Filtered dynamic services
  List<Map<String, dynamic>> get _filteredDynamicServices {
    var list = _dynamicServices;
    if (_selectedCategory != "All") {
      list = list.where((s) => (s['category']?.toString().toLowerCase() == _selectedCategory.toLowerCase())).toList();
    }
    return list;
  }

  // Search results combining catalog tests and dynamic services
  List<DiagnosticTestItem> get _filteredSearchResults {
    if (_searchQuery.trim().isEmpty) return [];
    final q = _searchQuery.trim().toLowerCase();
    return DiagnosticCatalog.allTests.where((t) {
      return t.name.toLowerCase().contains(q) ||
          t.shortName.toLowerCase().contains(q) ||
          t.category.toLowerCase().contains(q) ||
          t.description.toLowerCase().contains(q);
    }).toList();
  }

  List<Map<String, dynamic>> get _filteredDynamicSearchResults {
    if (_searchQuery.trim().isEmpty) return [];
    final q = _searchQuery.trim().toLowerCase();
    return _dynamicServices.where((s) {
      final name = (s['service_name'] ?? '').toString().toLowerCase();
      final cat = (s['category'] ?? '').toString().toLowerCase();
      final desc = (s['description'] ?? '').toString().toLowerCase();
      return name.contains(q) || cat.contains(q) || desc.contains(q);
    }).toList();
  }

  void _navigateToDepartment(BuildContext context, String title) {
    Widget target;
    switch (title) {
      case "Ultrasound":
        target = const UltrasoundDetailScreen();
        break;
      case "Blood Tests":
        target = const BloodTestsScreen();
        break;
      case "Sugar Tests":
        target = const SugarTestsScreen();
        break;
      case "Thyroid":
        target = const ThyroidScreen();
        break;
      case "Liver Tests":
        target = const LiverTestsScreen();
        break;
      case "Kidney Tests":
        target = const KidneyTestsScreen();
        break;
      case "Lipid Profile":
        target = const LipidProfileScreen();
        break;
      case "Health Packages":
        target = const HealthPackagesScreen();
        break;
      default:
        target = const UltrasoundDetailScreen();
    }
    Navigator.push(context, MaterialPageRoute(builder: (_) => target));
  }

  Color _getCategoryColor(String cat) {
    final lower = cat.toLowerCase();
    if (lower.contains('ultrasound')) return const Color(0xFF1677FF);
    if (lower.contains('doppler')) return const Color(0xFF8E5CF7);
    if (lower.contains('blood') || lower.contains('pathology')) return const Color(0xFFE53935);
    if (lower.contains('sugar') || lower.contains('diabetes')) return const Color(0xFF18C8C8);
    if (lower.contains('cardio') || lower.contains('heart')) return const Color(0xFFE91E63);
    if (lower.contains('radio') || lower.contains('imaging') || lower.contains('x-ray')) return const Color(0xFF00B4D8);
    if (lower.contains('liver')) return const Color(0xFFFF8A3D);
    if (lower.contains('package')) return const Color(0xFF10B981);
    return const Color(0xFF1677FF);
  }

  IconData _getCategoryIcon(String cat) {
    final lower = cat.toLowerCase();
    if (lower.contains('ultrasound')) return Icons.monitor_heart_rounded;
    if (lower.contains('doppler')) return Icons.healing_rounded;
    if (lower.contains('blood') || lower.contains('pathology')) return Icons.bloodtype_rounded;
    if (lower.contains('sugar') || lower.contains('diabetes')) return Icons.water_drop_rounded;
    if (lower.contains('cardio') || lower.contains('heart')) return Icons.favorite_rounded;
    if (lower.contains('radio') || lower.contains('imaging') || lower.contains('x-ray')) return Icons.document_scanner_rounded;
    if (lower.contains('package')) return Icons.card_membership_rounded;
    return Icons.medical_services_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color bgColor = Theme.of(context).scaffoldBackgroundColor;
    final Color cardColor = Theme.of(context).cardColor;
    final Color primaryText = isDark ? Colors.white : navy;
    final Color secondaryText = isDark ? Colors.white70 : Colors.grey.shade600;
    final Color borderColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : const Color(0xFFE8EEF5);

    final catalogResults = _filteredSearchResults;
    final dynamicResults = _filteredDynamicSearchResults;
    final bool isSearching = _searchQuery.trim().isNotEmpty;
    final int totalFound = catalogResults.length + dynamicResults.length;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: navy,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, size: 26),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Diagnostic Services",
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        actions: const [
          NotificationAppBarButton(),
          SizedBox(width: 6),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _fetchServices,
          color: blue,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // SEARCH BAR
                Container(
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: borderColor),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    textAlignVertical: TextAlignVertical.center,
                    style: TextStyle(color: primaryText, fontSize: 13.5),
                    onChanged: (val) {
                      setState(() {
                        _searchQuery = val;
                      });
                    },
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: "Search test, scan or service...",
                      hintStyle: TextStyle(color: secondaryText, fontSize: 13),
                      prefixIcon: const Icon(Icons.search_rounded, color: blue, size: 22),
                      suffixIcon: isSearching
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 20),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _searchQuery = "";
                                });
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                // ======================================================
                // SEARCH RESULTS VIEW
                // ======================================================
                if (isSearching) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Found $totalFound Tests & Services",
                        style: TextStyle(
                          color: primaryText,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = "";
                          });
                        },
                        child: const Text("Show All"),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (totalFound == 0)
                    Container(
                      padding: const EdgeInsets.all(28),
                      alignment: Alignment.center,
                      child: Column(
                        children: [
                          const Icon(
                            Icons.search_off_rounded,
                            size: 48,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            "No test found matching '$_searchQuery'",
                            style: TextStyle(color: primaryText, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            "Try searching for 'Ultrasound', 'CBC', 'Sugar', 'Thyroid' or 'Doppler'",
                            style: TextStyle(color: secondaryText, fontSize: 12),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  else ...[
                    // Newly added dynamic services that match search
                    ...dynamicResults.map((s) => _buildDynamicServiceCard(s, isDark, cardColor, primaryText, secondaryText, borderColor)),
                    // Static catalog tests that match search
                    ...catalogResults.map((test) => DiagnosticTestCard(test: test)),
                  ],
                ] else ...[
                  // ====================================================
                  // HEADER HERO CARD
                  // ====================================================
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          navy,
                          Color(0xFF0B4C68),
                          Color(0xFF087F91),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: navy.withValues(alpha: 0.22),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Aakriti Diagnostic Care",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 19,
                                  fontWeight: FontWeight.bold,
                                  height: 1.2,
                                ),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                "Certified 3D/4D Ultrasound, Digital Pathology, Color Doppler & Clinical Investigations.",
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 11.5,
                                  height: 1.35,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: teal.withValues(alpha: 0.18),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  "AFFORDABLE & ACCURATE",
                                  style: TextStyle(
                                    color: teal,
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          height: 64,
                          width: 64,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.medical_services_rounded,
                            color: teal,
                            size: 34,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ====================================================
                  // LIVE DIAGNOSTIC SERVICES (FROM BACKEND)
                  // ====================================================
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    "Available Diagnostic Services",
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: primaryText,
                                      fontSize: 16.5,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: blue.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    "${_filteredDynamicServices.length}",
                                    style: const TextStyle(
                                      color: blue,
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              "Select any service to book appointment directly",
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: secondaryText, fontSize: 11.5),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (_isLoadingServices)
                        const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: blue),
                        )
                      else
                        IconButton(
                          icon: const Icon(Icons.refresh_rounded, size: 20, color: blue),
                          tooltip: "Refresh services",
                          onPressed: _fetchServices,
                        ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // CATEGORY FILTER CHIPS
                  if (_availableCategories.length > 2) ...[
                    SizedBox(
                      height: 38,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        itemCount: _availableCategories.length,
                        itemBuilder: (context, idx) {
                          final cat = _availableCategories[idx];
                          final isSelected = _selectedCategory == cat;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              label: Text(
                                cat,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                  color: isSelected ? Colors.white : (isDark ? Colors.white70 : navy),
                                ),
                              ),
                              selected: isSelected,
                              onSelected: (_) {
                                setState(() {
                                  _selectedCategory = cat;
                                });
                              },
                              backgroundColor: cardColor,
                              selectedColor: blue,
                              showCheckmark: false,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                                side: BorderSide(
                                  color: isSelected ? blue : borderColor,
                                ),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],

                  // SERVICES LIST FROM BACKEND
                  if (_dynamicServices.isEmpty && _isLoadingServices) ...[
                    Container(
                      padding: const EdgeInsets.all(28),
                      alignment: Alignment.center,
                      child: Column(
                        children: [
                          const CircularProgressIndicator(strokeWidth: 2.5, color: blue),
                          const SizedBox(height: 12),
                          Text(
                            "Loading available services...",
                            style: TextStyle(color: secondaryText, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ] else if (_filteredDynamicServices.isEmpty) ...[
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: borderColor),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        "No services found under '$_selectedCategory'",
                        style: TextStyle(color: secondaryText, fontSize: 13),
                      ),
                    ),
                  ] else ...[
                    ..._filteredDynamicServices.map(
                      (service) => _buildDynamicServiceCard(
                        service,
                        isDark,
                        cardColor,
                        primaryText,
                        secondaryText,
                        borderColor,
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // ====================================================
                  // DIAGNOSTIC DEPARTMENTS
                  // ====================================================
                  Text(
                    "Diagnostic Departments",
                    style: TextStyle(
                      color: primaryText,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Choose department to view specialized catalog & guidelines",
                    style: TextStyle(color: secondaryText, fontSize: 12),
                  ),

                  const SizedBox(height: 16),

                  // DEPARTMENT GRID
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: departments.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                      mainAxisExtent: 185,
                    ),
                    itemBuilder: (context, index) {
                      final item = departments[index];
                      final color = item["color"] as Color;

                      return GestureDetector(
                        onTap: () => _navigateToDepartment(
                          context,
                          item["title"] as String,
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(15),
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(color: borderColor),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(
                                  alpha: isDark ? 0.2 : 0.035,
                                ),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    height: 38,
                                    width: 38,
                                    decoration: BoxDecoration(
                                      color: color.withValues(alpha: 0.14),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      item["icon"] as IconData,
                                      color: color,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: color.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Text(
                                          item["badge"] as String,
                                          style: TextStyle(
                                            color: color,
                                            fontSize: 9.5,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const Spacer(),
                              Text(
                                item["title"] as String,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: primaryText,
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                item["subtitle"] as String,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: secondaryText,
                                  fontSize: 11,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "Starts ${item["startingPrice"]}",
                                    style: TextStyle(
                                      color: color,
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  Icon(
                                    Icons.arrow_forward_rounded,
                                    size: 14,
                                    color: color,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 24),

                  // QUICK BOOKING ACTION
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [navy, Color(0xFF133F63)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: teal.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.calendar_month_rounded,
                            color: teal,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Have a Doctor's Prescription?",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14.5,
                                ),
                              ),
                              const SizedBox(height: 3),
                              const Text(
                                "Book slot directly and show prescription on arrival.",
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 11.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const AppointmentScreen(),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: teal,
                            foregroundColor: navy,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            "Book Slot",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // DYNAMIC SERVICE CARD WIDGET
  // ============================================================
  Widget _buildDynamicServiceCard(
    Map<String, dynamic> item,
    bool isDark,
    Color cardColor,
    Color primaryText,
    Color secondaryText,
    Color borderColor,
  ) {
    final String name = item['service_name']?.toString() ?? 'Diagnostic Procedure';
    final String category = item['category']?.toString() ?? 'General';
    final dynamic rawPrice = item['price'];
    final int price = rawPrice is num
        ? rawPrice.toInt()
        : (int.tryParse(rawPrice.toString().replaceAll(RegExp(r'[^0-9]'), '')) ?? 0);
    final String duration = item['duration']?.toString() ?? '15 min';
    final String description = item['description']?.toString() ?? '';
    final Color catColor = _getCategoryColor(category);
    final IconData catIcon = _getCategoryIcon(category);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.035),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 46,
                width: 46,
                decoration: BoxDecoration(
                  color: catColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(catIcon, color: catColor, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            style: TextStyle(
                              fontSize: 15.5,
                              fontWeight: FontWeight.bold,
                              color: primaryText,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: catColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            category,
                            style: TextStyle(
                              color: catColor,
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (description.isNotEmpty) ...[
                      const SizedBox(height: 5),
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 12.5,
                          color: secondaryText,
                          height: 1.35,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.access_time_rounded, size: 14, color: secondaryText),
                        const SizedBox(width: 4),
                        Text(
                          duration,
                          style: TextStyle(fontSize: 11.5, color: secondaryText),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            "Available",
                            style: TextStyle(
                              color: Color(0xFF10B981),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(color: borderColor, height: 1),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Price",
                    style: TextStyle(fontSize: 11, color: secondaryText),
                  ),
                  Text(
                    price > 0 ? "₹$price" : "Contact Clinic",
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: catColor,
                    ),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AppointmentScreen(
                        scanName: name,
                        scanPrice: price > 0 ? price : null,
                        preparation: description.isNotEmpty
                            ? description
                            : "Standard diagnostic clinical preparation",
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.calendar_month_rounded, size: 16),
                label: const Text(
                  "Book Slot",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
