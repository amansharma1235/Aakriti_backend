import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/profile_service.dart';
import '../widgets/notification_app_bar_button.dart';
import 'report_details_screen.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final TextEditingController searchController = TextEditingController();

  String searchQuery = "";
  String selectedFilter = "All";
  bool isLoading = true;
  bool isRefreshing = false;

  // =========================================================
  // THEME COLORS
  // =========================================================

  bool get isDark => Theme.of(context).brightness == Brightness.dark;

  Color get bgColor => Theme.of(context).scaffoldBackgroundColor;

  Color get cardColor => Theme.of(context).cardColor;

  Color get primaryText => isDark ? Colors.white : const Color(0xFF071A2B);

  Color get secondaryText => isDark ? Colors.white70 : Colors.grey.shade600;

  Color get borderColor =>
      isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE8EEF5);

  Color get shadowColor =>
      isDark ? Colors.black.withValues(alpha: 0.25) : Colors.black.withValues(alpha: 0.04);

  // =========================================================
  // REPORT DATA
  // =========================================================

  List<Map<String, dynamic>> reports = [];

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports({bool silent = false}) async {
    if (!silent && mounted) {
      setState(() => isLoading = true);
    }
    try {
      final patientId = await AuthService.getPatientId();
      List<Map<String, dynamic>> fetchedReports = [];

      final mysqlReports = await ApiService.getMyReports(patientId: patientId);

      if (mysqlReports.isNotEmpty) {
        fetchedReports = mysqlReports.map((item) {
          final title = (item['report_title'] ?? item['testName'] ?? 'Diagnostic Report').toString();
          IconData icon = Icons.description_outlined;
          final lower = title.toLowerCase();
          if (lower.contains('ultrasound') || lower.contains('abdomen') || lower.contains('scan')) {
            icon = Icons.monitor_heart_outlined;
          } else if (lower.contains('blood') || lower.contains('cbc') || lower.contains('hemoglobin')) {
            icon = Icons.bloodtype_outlined;
          } else if (lower.contains('thyroid') || lower.contains('t3') || lower.contains('tsh')) {
            icon = Icons.healing_outlined;
          } else if (lower.contains('sugar') || lower.contains('glucose') || lower.contains('hba1c')) {
            icon = Icons.water_drop_outlined;
          } else if (lower.contains('lipid') || lower.contains('cholesterol')) {
            icon = Icons.favorite_outlined;
          } else if (lower.contains('kidney') || lower.contains('creatinine')) {
            icon = Icons.health_and_safety_outlined;
          } else if (lower.contains('liver') || lower.contains('sgot') || lower.contains('sgpt')) {
            icon = Icons.local_hospital_outlined;
          }

          final rawDate = (item['report_date'] ?? item['created_at'] ?? 'Recent').toString();
          final dateStr = rawDate.length >= 10 ? rawDate.substring(0, 10) : rawDate;
          final rawPath = (item['file_path'] ?? item['reportUrl'] ?? '').toString();
          final fullUrl = rawPath.startsWith('http')
              ? rawPath
              : (rawPath.isNotEmpty ? '${ApiService.baseUrl}$rawPath' : '');

          return {
            "id": (item['id'] ?? item['report_id'] ?? '').toString(),
            "reportId": (item['report_id'] ?? '').toString(),
            "test": title,
            "patient": (item['patient_name'] ?? ProfileService.userNameNotifier.value.isNotEmpty ? ProfileService.userNameNotifier.value : 'Patient').toString(),
            "date": dateStr,
            "status": (item['status'] ?? 'Ready').toString().toUpperCase(),
            "icon": icon,
            "reportUrl": fullUrl,
            "file_name": (item['file_name'] ?? '').toString(),
          };
        }).toList();
      } else {
        // Fallback check: Firestore legacy if MySQL returns no records for patient
        final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
        if (uid.isNotEmpty) {
          final snap = await FirebaseFirestore.instance
              .collection('reports')
              .where('userId', isEqualTo: uid)
              .get();

          fetchedReports = snap.docs.map((doc) {
            final data = doc.data();
            final title = (data['testName'] ?? data['test_name'] ?? 'Diagnostic Report').toString();
            IconData icon = Icons.description_outlined;
            final lower = title.toLowerCase();
            if (lower.contains('ultrasound') || lower.contains('abdomen')) {
              icon = Icons.monitor_heart_outlined;
            } else if (lower.contains('blood')) {
              icon = Icons.bloodtype_outlined;
            }

            String dateStr = 'Recent';
            if (data['uploadedAt'] != null && data['uploadedAt'] is Timestamp) {
              dateStr = (data['uploadedAt'] as Timestamp).toDate().toIso8601String().substring(0, 10);
            }

            return {
              "id": doc.id,
              "reportId": data['reportId'] ?? doc.id,
              "test": title,
              "patient": (data['patientName'] ?? ProfileService.userNameNotifier.value).toString(),
              "date": dateStr,
              "status": (data['reportStatus'] ?? 'available').toString().toUpperCase(),
              "icon": icon,
              "reportUrl": data['reportUrl'] ?? '',
            };
          }).toList();
        }
      }

      if (mounted) {
        setState(() {
          isLoading = false;
          isRefreshing = false;
          reports = fetchedReports;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
          isRefreshing = false;
          reports = [];
        });
      }
    }
  }

  Future<void> _onRefresh() async {
    setState(() => isRefreshing = true);
    await _loadReports(silent: true);
  }

  // =========================================================
  // DISPOSE
  // =========================================================

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  // =========================================================
  // FILTERED REPORTS
  // =========================================================

  List<Map<String, dynamic>> get filteredReports {
    final query = searchQuery.trim().toLowerCase();

    return reports.where((report) {
      final test = report["test"].toString().toLowerCase();
      final id = report["id"].toString().toLowerCase();
      final reportId = (report["reportId"] ?? "").toString().toLowerCase();
      final patient = report["patient"].toString().toLowerCase();
      final status = (report["status"] ?? "").toString().toUpperCase();

      final matchesSearch =
          query.isEmpty ||
          test.contains(query) ||
          id.contains(query) ||
          reportId.contains(query) ||
          patient.contains(query);

      bool matchesFilter = true;
      if (selectedFilter == "All") {
        matchesFilter = true;
      } else if (selectedFilter == "Ultrasound") {
        matchesFilter = test.contains("ultrasound") || test.contains("scan") || test.contains("doppler") || test.contains("abdomen") || test.contains("pelvis");
      } else if (selectedFilter == "Blood Test") {
        matchesFilter = test.contains("blood") || test.contains("cbc") || test.contains("sugar") || test.contains("lipid") || test.contains("thyroid") || test.contains("hemoglobin");
      } else if (selectedFilter == "Ready") {
        matchesFilter = status == "AVAILABLE" || status == "READY" || status == "COMPLETED" || status == "DELIVERED" || status == "APPROVED";
      } else if (selectedFilter == "Processing") {
        matchesFilter = !(status == "AVAILABLE" || status == "READY" || status == "COMPLETED" || status == "DELIVERED" || status == "APPROVED");
      } else {
        matchesFilter = status == selectedFilter.toUpperCase() || test.contains(selectedFilter.toLowerCase());
      }

      return matchesSearch && matchesFilter;
    }).toList();
  }

  Widget _filterChip(String label, IconData icon) {
    final bool isSelected = selectedFilter == label;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: () {
          setState(() {
            selectedFilter = label;
          });
        },
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF1677FF)
                : (isDark ? Colors.white.withValues(alpha: 0.06) : Colors.white),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF1677FF)
                  : borderColor,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: const Color(0xFF1677FF).withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    )
                  ]
                : [],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 15,
                color: isSelected ? Colors.white : (isDark ? Colors.white70 : const Color(0xFF1677FF)),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? Colors.white : primaryText,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,

      // =====================================================
      // APP BAR
      // =====================================================
      appBar: AppBar(
        backgroundColor: const Color(0xFF071A2B),
        foregroundColor: Colors.white,
        elevation: 0,

        title: const Text(
          "My Reports",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 21),
        ),

        actions: [
          const NotificationAppBarButton(),
          IconButton(
            onPressed: () {
              _showFilterSheet(context);
            },
            icon: const Icon(Icons.tune_rounded),
          ),
        ],
      ),

      // =====================================================
      // BODY
      // =====================================================
      body: isLoading
          ? _loadingState()
          : RefreshIndicator(
              onRefresh: _onRefresh,
              color: const Color(0xFF1677FF),
              child: ListView(
        padding: const EdgeInsets.all(18),

        children: [
          // =================================================
          // HEADER
          // =================================================

          Container(
            padding: const EdgeInsets.all(22),

            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF071A2B),
                  Color(0xFF123D61),
                  Color(0xFF1677FF),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),

              borderRadius: BorderRadius.circular(24),

              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1677FF).withValues(alpha: 0.18),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),

            child: Row(
              children: [
                Container(
                  width: 58,
                  height: 58,

                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(18),
                  ),

                  child: const Icon(
                    Icons.description_rounded,
                    color: Colors.white,
                    size: 32,
                  ),
                ),

                const SizedBox(width: 15),

                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Your Medical Reports",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      SizedBox(height: 6),

                      Text(
                        "View and manage your diagnostic reports",
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // =================================================
          // SEARCH
          // =================================================
          Container(
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(16),

              border: Border.all(color: borderColor),

              boxShadow: [
                BoxShadow(
                  color: shadowColor,
                  blurRadius: 12,
                  offset: const Offset(0, 5),
                ),
              ],
            ),

            child: TextField(
              controller: searchController,
              textAlignVertical: TextAlignVertical.center,
              style: TextStyle(color: primaryText, fontSize: 13.5),
              onChanged: (value) {
                setState(() {
                  searchQuery = value;
                });
              },
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                hintText: "Search by test, patient or report ID",
                hintStyle: TextStyle(color: secondaryText, fontSize: 13),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: Color(0xFF1677FF),
                  size: 22,
                ),
                suffixIcon: searchQuery.isNotEmpty
                    ? IconButton(
                        onPressed: () {
                          searchController.clear();
                          setState(() {
                            searchQuery = "";
                          });
                        },
                        icon: Icon(Icons.close_rounded, color: secondaryText, size: 20),
                      )
                    : null,
                border: InputBorder.none,
              ),
            ),
          ),

          const SizedBox(height: 18),

          // =================================================
          // CATEGORY FILTER CHIPS
          // =================================================
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                _filterChip("All", Icons.grid_view_rounded),
                _filterChip("Ultrasound", Icons.monitor_heart_outlined),
                _filterChip("Blood Test", Icons.bloodtype_outlined),
                _filterChip("Ready", Icons.check_circle_outline),
                _filterChip("Processing", Icons.hourglass_top_outlined),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // =================================================
          // SUMMARY
          // =================================================
          Row(
            children: [
              Expanded(
                child: _summaryCard(
                  icon: Icons.folder_copy_outlined,
                  title: "Total Reports",
                  value: "${reports.length}",
                ),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: _summaryCard(
                  icon: Icons.check_circle_outline,
                  title: "Ready",
                  value: "${reports.where((r) {
                    final s = r["status"].toString().toUpperCase();
                    return s == 'AVAILABLE' || s == 'READY' || s == 'COMPLETED' || s == 'DELIVERED' || s == 'APPROVED';
                  }).length}",
                ),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: _summaryCard(
                  icon: Icons.hourglass_top_rounded,
                  title: "Processing",
                  value: "${reports.where((r) {
                    final s = r["status"].toString().toUpperCase();
                    return !(s == 'AVAILABLE' || s == 'READY' || s == 'COMPLETED' || s == 'DELIVERED' || s == 'APPROVED');
                  }).length}",
                ),
              ),
            ],
          ),

          const SizedBox(height: 25),

          // =================================================
          // ACTIVE FILTER
          // =================================================
          if (selectedFilter != "All")
            Padding(
              padding: const EdgeInsets.only(bottom: 15),

              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 13,
                      vertical: 8,
                    ),

                    decoration: BoxDecoration(
                      color: const Color(0xFF1677FF).withValues(alpha: 0.10),

                      borderRadius: BorderRadius.circular(20),

                      border: Border.all(
                        color: const Color(0xFF1677FF).withValues(alpha: 0.20),
                      ),
                    ),

                    child: Row(
                      mainAxisSize: MainAxisSize.min,

                      children: [
                        const Icon(
                          Icons.filter_alt_outlined,
                          size: 15,
                          color: Color(0xFF1677FF),
                        ),

                        const SizedBox(width: 6),

                        Text(
                          selectedFilter,
                          style: const TextStyle(
                            color: Color(0xFF1677FF),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),

                        const SizedBox(width: 5),

                        GestureDetector(
                          onTap: () {
                            setState(() {
                              selectedFilter = "All";
                            });
                          },

                          child: const Icon(
                            Icons.close,
                            size: 16,
                            color: Color(0xFF1677FF),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          // =================================================
          // TITLE
          // =================================================
          Row(
            children: [
              Expanded(
                child: Text(
                  "Recent Reports",

                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: primaryText,
                  ),
                ),
              ),

              Text(
                "${filteredReports.length} Reports",

                style: const TextStyle(
                  color: Color(0xFF1677FF),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),

          const SizedBox(height: 15),

          // =================================================
          // REPORT LIST
          // =================================================
          if (filteredReports.isEmpty)
            _emptySearchState()
          else
            ...filteredReports.map(
              (report) => _reportCard(
                context,

                reportId: report["id"],
                testName: report["test"],
                patientName: report["patient"],
                date: report["date"],
                status: report["status"],
                icon: report["icon"],
              ),
            ),

          const SizedBox(height: 5),

          // =================================================
          // INFO CARD
          // =================================================
          Container(
            padding: const EdgeInsets.all(18),

            decoration: BoxDecoration(
              color: const Color(0xFF1677FF).withValues(alpha: isDark ? 0.12 : 0.08),

              borderRadius: BorderRadius.circular(18),

              border: Border.all(
                color: const Color(0xFF1677FF).withValues(alpha: 0.15),
              ),
            ),

            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  color: Color(0xFF1677FF),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Text(
                    "Your reports will appear here after they are uploaded and verified by the diagnostic centre.",

                    style: TextStyle(
                      color: isDark ? Colors.white70 : const Color(0xFF123D61),

                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
          ),
    );
  }

  // =========================================================
  // LOADING STATE
  // =========================================================

  Widget _loadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: const Color(0xFF1677FF).withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const CircularProgressIndicator(
              color: Color(0xFF1677FF),
              strokeWidth: 2.5,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            "Loading your reports...",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: primaryText,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "Fetching from Aakriti Diagnostic Centre",
            style: TextStyle(fontSize: 12, color: secondaryText),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // SUMMARY CARD
  // =========================================================

  Widget _summaryCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(13),

      decoration: BoxDecoration(
        color: cardColor,

        borderRadius: BorderRadius.circular(17),

        border: Border.all(color: borderColor),

        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Icon(icon, color: const Color(0xFF1677FF), size: 22),

          const SizedBox(height: 10),

          Text(
            value,

            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: primaryText,
            ),
          ),

          const SizedBox(height: 3),

          Text(
            title,

            maxLines: 1,
            overflow: TextOverflow.ellipsis,

            style: TextStyle(color: secondaryText, fontSize: 10),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // REPORT CARD
  // =========================================================

  Widget _reportCard(
    BuildContext context, {
    required String reportId,
    required String testName,
    required String patientName,
    required String date,
    required String status,
    required IconData icon,
  }) {
    final String st = status.trim().toUpperCase();
    final bool available = st == "AVAILABLE" ||
        st == "READY" ||
        st == "COMPLETED" ||
        st == "DELIVERED" ||
        st == "APPROVED" ||
        st == "SIGNED";

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // =================================================
          // TOP
          // =================================================
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF1677FF).withValues(alpha: isDark ? 0.20 : 0.12),
                      const Color(0xFF18C8C8).withValues(alpha: isDark ? 0.16 : 0.10),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: const Color(0xFF1677FF), size: 27),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      testName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: primaryText,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Icon(
                          Icons.person_outline,
                          size: 14,
                          color: secondaryText,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            patientName,
                            style: TextStyle(
                              color: secondaryText,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 5),

              _statusBadge(status),
            ],
          ),

          const SizedBox(height: 18),

          Divider(height: 1, color: borderColor),

          const SizedBox(height: 16),

          // =================================================
          // DETAILS
          // =================================================
          Row(
            children: [
              Expanded(
                child: _detailItem(
                  Icons.calendar_today_outlined,
                  "Report Date",
                  date,
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: _detailItem(Icons.tag_outlined, "Report ID", reportId),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // =================================================
          // BUTTONS
          // =================================================
          if (available)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ReportDetailScreen(
                            reportId: reportId,
                            testName: testName,
                            patientName: patientName,
                            date: date,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.visibility_outlined, size: 17),
                    label: const FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text("View Report"),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF1677FF),
                      side: const BorderSide(color: Color(0xFF1677FF)),
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(13),
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 8),

                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ReportDetailScreen(
                            reportId: reportId,
                            testName: testName,
                            patientName: patientName,
                            date: date,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.picture_as_pdf_outlined, size: 16),
                    label: const FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text("PDF Report"),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1677FF),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(13),
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 8),

                SizedBox(
                  width: 48,
                  height: 48,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ReportDetailScreen(
                            reportId: reportId,
                            testName: testName,
                            patientName: patientName,
                            date: date,
                          ),
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF18A6A6),
                      side: const BorderSide(color: Color(0xFF18A6A6)),
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(13),
                      ),
                    ),
                    child: const Icon(Icons.share_outlined, size: 18),
                  ),
                ),
              ],
            )
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: isDark ? 0.14 : 0.08),
                borderRadius: BorderRadius.circular(13),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.hourglass_top_rounded,
                    color: Colors.orange,
                    size: 18,
                  ),
                  SizedBox(width: 8),
                  Text(
                    "Report is being processed",
                    style: TextStyle(
                      color: Colors.orange,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
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
  // STATUS BADGE
  // =========================================================

  Widget _statusBadge(String status) {
    final String st = status.trim().toUpperCase();
    final bool available = st == "AVAILABLE" ||
        st == "READY" ||
        st == "COMPLETED" ||
        st == "DELIVERED" ||
        st == "APPROVED" ||
        st == "SIGNED";

    final displayLabel = available ? "READY" : (st.isEmpty ? "PROCESSING" : st);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: available
            ? Colors.green.withValues(alpha: isDark ? 0.20 : 0.12)
            : Colors.orange.withValues(alpha: isDark ? 0.20 : 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: available
              ? Colors.green.withValues(alpha: 0.3)
              : Colors.orange.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            available ? Icons.check_circle_rounded : Icons.schedule_rounded,
            size: 13,
            color: available ? Colors.green : Colors.orange,
          ),
          const SizedBox(width: 4),
          Text(
            displayLabel,
            style: TextStyle(
              color: available ? (isDark ? Colors.greenAccent : Colors.green.shade800) : (isDark ? Colors.orangeAccent : Colors.orange.shade800),
              fontSize: 10.5,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // DETAIL ITEM
  // =========================================================

  Widget _detailItem(IconData icon, String title, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,

      children: [
        Icon(icon, size: 17, color: const Color(0xFF1677FF)),

        const SizedBox(width: 7),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              Text(title, style: TextStyle(color: secondaryText, fontSize: 10)),

              const SizedBox(height: 3),

              Text(
                value,

                maxLines: 1,
                overflow: TextOverflow.ellipsis,

                style: TextStyle(
                  color: primaryText,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // =========================================================
  // EMPTY SEARCH
  // =========================================================

  Widget _emptySearchState() {
    return Container(
      margin: const EdgeInsets.only(top: 10),

      padding: const EdgeInsets.all(30),

      decoration: BoxDecoration(
        color: cardColor,

        borderRadius: BorderRadius.circular(20),

        border: Border.all(color: borderColor),
      ),

      child: Column(
        children: [
          Icon(
            searchQuery.isEmpty && selectedFilter == "All"
                ? Icons.folder_off_outlined
                : Icons.search_off_rounded,
            size: 55,
            color: secondaryText,
          ),

          const SizedBox(height: 12),

          Text(
            searchQuery.isEmpty && selectedFilter == "All"
                ? "No Reports Yet"
                : "No Reports Found",

            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: primaryText,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            searchQuery.isEmpty && selectedFilter == "All"
                ? "Your diagnostic reports will appear here\nafter your tests are completed."
                : selectedFilter != "All"
                    ? "No $selectedFilter reports found. Try changing the filter."
                    : "Try searching with another test name or report ID.",

            textAlign: TextAlign.center,

            style: TextStyle(color: secondaryText, fontSize: 12, height: 1.5),
          ),

          if (searchQuery.isEmpty && selectedFilter == "All") ...[
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.calendar_today_outlined, size: 16),
              label: const Text("Book a Test"),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1677FF),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _onRefresh,
              child: const Text(
                "Refresh",
                style: TextStyle(color: Color(0xFF1677FF), fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // =========================================================
  // FILTER SHEET
  // =========================================================

  void _showFilterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,

      backgroundColor: cardColor,

      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),

      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(22),

          child: Column(
            mainAxisSize: MainAxisSize.min,

            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      "Filter Reports",

                      style: TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                        color: primaryText,
                      ),
                    ),
                  ),

                  IconButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },

                    icon: Icon(Icons.close, color: secondaryText),
                  ),
                ],
              ),

              const SizedBox(height: 15),

              _filterOption(context, Icons.all_inclusive, "All Reports", "All"),

              _filterOption(
                context,
                Icons.check_circle_outline,
                "Available Reports",
                "Available",
              ),

              _filterOption(
                context,
                Icons.hourglass_top_outlined,
                "Processing Reports",
                "Processing",
              ),

              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  // =========================================================
  // FILTER OPTION
  // =========================================================

  Widget _filterOption(
    BuildContext context,
    IconData icon,
    String title,
    String filterValue,
  ) {
    final bool isSelected = selectedFilter == filterValue;

    return ListTile(
      onTap: () {
        setState(() {
          selectedFilter = filterValue;
        });

        Navigator.pop(context);
      },

      leading: Container(
        padding: const EdgeInsets.all(9),

        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF1677FF).withValues(alpha: isDark ? 0.20 : 0.12)
              : const Color(0xFF1677FF).withValues(alpha: isDark ? 0.14 : 0.07),

          borderRadius: BorderRadius.circular(12),
        ),

        child: Icon(icon, color: const Color(0xFF1677FF)),
      ),

      title: Text(
        title,

        style: TextStyle(fontWeight: FontWeight.w600, color: primaryText),
      ),

      trailing: isSelected
          ? const Icon(Icons.check_circle, color: Color(0xFF1677FF))
          : Icon(Icons.radio_button_unchecked, color: secondaryText),
    );
  }
}
