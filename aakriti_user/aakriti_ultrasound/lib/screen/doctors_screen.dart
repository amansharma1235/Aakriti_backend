import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/api_service.dart';
import '../widgets/notification_app_bar_button.dart';
import 'appointment_screen.dart';

class DoctorsScreen extends StatefulWidget {
  final bool isEmbedded;

  const DoctorsScreen({super.key, this.isEmbedded = false});

  @override
  State<DoctorsScreen> createState() => _DoctorsScreenState();
}

class _DoctorsScreenState extends State<DoctorsScreen> {
  static const Color navy = Color(0xFF071A2B);
  static const Color blue = Color(0xFF1677FF);
  static const Color teal = Color(0xFF18C8C8);

  bool isLoading = true;
  String selectedDepartment = "All";
  String searchQuery = "";

  List<Map<String, dynamic>> doctors = [];

  final List<Map<String, dynamic>> defaultDoctors = [
    {
      "doctor_id": "DOC001",
      "doctor_name": "Dr. Rajesh Sharma",
      "department": "Radiologist",
      "specialization": "Senior Radiologist & Ultrasonography Specialist",
      "mobile": "+91 98765 43210",
      "experience": "14+ Years",
      "qualification": "MBBS, MD (Radiology)",
      "status": "Available Today",
      "timing": "10:00 AM - 01:00 PM",
      "avatar_url": "",
    },
    {
      "doctor_id": "DOC002",
      "doctor_name": "Dr. Neha Verma",
      "department": "Sonologist",
      "specialization": "Fetal Medicine & Obstetric Sonology Specialist",
      "mobile": "+91 91234 56780",
      "experience": "10+ Years",
      "qualification": "MBBS, DMRD (Sonology)",
      "status": "Available Today",
      "timing": "10:00 AM - 04:00 PM",
      "avatar_url": "",
    },
    {
      "doctor_id": "DOC003",
      "doctor_name": "Dr. Amit Gupta",
      "department": "Radiologist",
      "specialization": "Consultant Radiologist & CT/MRI Specialist",
      "mobile": "+91 99887 76655",
      "experience": "12+ Years",
      "qualification": "MBBS, DNB (Radio-Diagnosis)",
      "status": "On Duty",
      "timing": "01:00 PM - 04:00 PM",
      "avatar_url": "",
    },
    {
      "doctor_id": "DOC004",
      "doctor_name": "Dr. Priya Singh",
      "department": "Pathologist",
      "specialization": "Chief Pathologist & Hematology Expert",
      "mobile": "+91 98765 01234",
      "experience": "8+ Years",
      "qualification": "MBBS, MD (Pathology)",
      "status": "Available Today",
      "timing": "10:00 AM - 03:30 PM",
      "avatar_url": "",
    },
    {
      "doctor_id": "DOC005",
      "doctor_name": "Dr. Ankit Verma",
      "department": "General Physician",
      "specialization": "Consultant General Physician & Internal Medicine",
      "mobile": "+91 90011 22334",
      "experience": "9+ Years",
      "qualification": "MBBS, MD (Internal Medicine)",
      "status": "Available Today",
      "timing": "11:00 AM - 05:00 PM",
      "avatar_url": "",
    },
    {
      "doctor_id": "DOC006",
      "doctor_name": "Dr. Sunita Rao",
      "department": "Gynecologist",
      "specialization": "Obstetrician, Gynecologist & Fetal Imaging",
      "mobile": "+91 98112 23344",
      "experience": "15+ Years",
      "qualification": "MBBS, MS (Obstetrics & Gynecology)",
      "status": "Available Today",
      "timing": "10:00 AM - 02:00 PM",
      "avatar_url": "",
    },
    {
      "doctor_id": "DOC007",
      "doctor_name": "Dr. Vikram Malhotra",
      "department": "Cardiologist",
      "specialization": "Consultant Cardiologist & Echocardiography Specialist",
      "mobile": "+91 97654 32109",
      "experience": "11+ Years",
      "qualification": "MBBS, MD, DM (Cardiology)",
      "status": "Available Today",
      "timing": "02:00 PM - 06:00 PM",
      "avatar_url": "",
    },
    {
      "doctor_id": "DOC008",
      "doctor_name": "Dr. Rohit Saxena",
      "department": "Orthopedic",
      "specialization": "Consultant Orthopedic Surgeon & Musculoskeletal Imaging",
      "mobile": "+91 96543 21098",
      "experience": "13+ Years",
      "qualification": "MBBS, MS (Orthopedics)",
      "status": "On Duty",
      "timing": "11:30 AM - 04:30 PM",
      "avatar_url": "",
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadDoctors();
  }

  Future<void> _loadDoctors() async {
    if (!mounted) return;
    setState(() => isLoading = true);

    try {
      // 1. Fetch live doctors from FastAPI / MySQL Backend
      final apiDoctors = await ApiService.getDoctors();
      if (apiDoctors.isNotEmpty && mounted) {
        final parsed = apiDoctors.map((d) {
          final id = (d['doctor_id'] ?? '').toString();
          final name = (d['doctor_name'] ?? d['name'] ?? 'Doctor').toString();
          final spec = (d['specialization'] ?? 'Radiologist').toString();
          final mobile = (d['mobile'] ?? d['phone'] ?? '').toString();
          final exp = (d['experience'] ?? '8+ Years').toString();
          final status = (d['status'] ?? 'Active').toString();
          final dept = spec.contains('Sonolog')
              ? 'Sonologist'
              : (spec.contains('Patholog')
                  ? 'Pathologist'
                  : (spec.contains('Radio')
                      ? 'Radiologist'
                      : (spec.contains('Gynec')
                          ? 'Gynecologist'
                          : (spec.contains('Cardio')
                              ? 'Cardiologist'
                              : (spec.contains('Ortho')
                                  ? 'Orthopedic'
                                  : spec)))));

          return {
            "doctor_id": id,
            "doctor_name": name,
            "department": dept,
            "specialization": spec,
            "mobile": mobile,
            "experience": exp,
            "qualification": "MBBS, MD",
            "status": status.toLowerCase() == 'active' ? 'Available Today' : status,
            "timing": "10:00 AM - 04:00 PM",
            "consultation_fee": 500,
            "rating": 4.9,
          };
        }).toList();

        setState(() {
          doctors = parsed;
          isLoading = false;
        });
        return;
      }
    } catch (apiErr) {
      debugPrint("[DoctorsScreen] API fetch error: $apiErr");
    }

    // 2. Firestore fallback if API temporarily unavailable
    try {
      final snap = await FirebaseFirestore.instance
          .collection('doctors')
          .where('status', isEqualTo: 'active')
          .get();

      if (snap.docs.isNotEmpty && mounted) {
        _parseAndSetDoctors(snap.docs);
        return;
      }
    } catch (_) {}

    // 3. Robust default doctors fallback
    if (mounted) {
      setState(() {
        doctors = List<Map<String, dynamic>>.from(defaultDoctors);
        isLoading = false;
      });
    }
  }

  void _parseAndSetDoctors(List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    if (!mounted) return;
    final parsed = docs.map((doc) {
      final d = doc.data();
      final spec = (d['specialization'] ?? 'Senior Radiologist').toString();
      final name = (d['name'] ?? 'Doctor').toString();
      final dept = (d['department'] ?? 'Radiology').toString();
      final exp = (d['experience'] ?? '10+ Years').toString();
      final qual = (d['qualification'] ?? 'MD, MBBS').toString();
      final timing = (d['workingHours'] ?? '09:00 AM - 05:00 PM').toString();

      return {
        "doctor_id": doc.id,
        "doctor_name": name,
        "department": dept,
        "specialization": spec,
        "experience": exp,
        "qualification": qual,
        "status": "Available Today",
        "timing": timing,
        "consultation_fee": d['consultationFee'] ?? 500,
        "rating": d['rating'] ?? 4.9,
      };
    }).toList();

    setState(() {
      doctors = parsed.isNotEmpty ? parsed : List<Map<String, dynamic>>.from(defaultDoctors);
      isLoading = false;
    });
  }

  List<String> get departments {
    final set = <String>{"All"};
    for (final doc in doctors) {
      final d = doc["department"]?.toString() ?? "Radiologist";
      if (d.isNotEmpty) set.add(d);
    }
    return set.toList();
  }

  List<Map<String, dynamic>> get filteredDoctors {
    final q = searchQuery.trim().toLowerCase();
    return doctors.where((doc) {
      final name = doc["doctor_name"].toString().toLowerCase();
      final dept = doc["department"].toString().toLowerCase();
      final spec = doc["specialization"].toString().toLowerCase();

      final matchesSearch = q.isEmpty || name.contains(q) || dept.contains(q) || spec.contains(q);
      final matchesDept = selectedDepartment == "All" || doc["department"] == selectedDepartment;

      return matchesSearch && matchesDept;
    }).toList();
  }

  Map<String, List<Map<String, dynamic>>> get groupedDoctors {
    final map = <String, List<Map<String, dynamic>>>{};
    for (final doc in filteredDoctors) {
      final dept = (doc["department"] ?? "Radiologist").toString();
      map.putIfAbsent(dept, () => []).add(doc);
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color bgColor = Theme.of(context).scaffoldBackgroundColor;
    final Color cardColor = Theme.of(context).cardColor;
    final Color primaryText = isDark ? Colors.white : navy;
    final Color secondaryText = isDark ? Colors.white70 : Colors.grey.shade600;
    final Color borderColor = isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE8EEF5);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: navy,
        elevation: 0,
        automaticallyImplyLeading: !widget.isEmbedded,
        leading: widget.isEmbedded
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
        title: const Text(
          "Our Doctors",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
        ),
        actions: const [
          NotificationAppBarButton(),
          SizedBox(width: 8),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: blue))
          : RefreshIndicator(
              onRefresh: _loadDoctors,
              color: blue,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                padding: const EdgeInsets.all(18),
                children: [
                  // Banner Header
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [navy, Color(0xFF0D3E64), Color(0xFF1677FF)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: blue.withValues(alpha: 0.20),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          height: 56,
                          width: 56,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: const Icon(Icons.medical_information_rounded, color: teal, size: 32),
                        ),
                        const SizedBox(width: 15),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Specialist Medical Team",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 19,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                "Certified Radiologists, Sonologists & Pathologists available for consultations & diagnostic reporting.",
                                style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.35),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Search Bar
                  Container(
                    height: 52,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: borderColor),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: TextField(
                      textAlignVertical: TextAlignVertical.center,
                      style: TextStyle(color: primaryText, fontSize: 13.5),
                      onChanged: (val) {
                        setState(() {
                          searchQuery = val;
                        });
                      },
                      decoration: InputDecoration(
                        isDense: true,
                        hintText: "Search doctor name or department...",
                        hintStyle: TextStyle(color: secondaryText, fontSize: 13),
                        prefixIcon: const Icon(Icons.search_rounded, color: blue, size: 22),
                        border: InputBorder.none,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Department Filter Pills
                  SizedBox(
                    height: 40,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: departments.length,
                      itemBuilder: (context, idx) {
                        final dept = departments[idx];
                        final isSelected = selectedDepartment == dept;

                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              selectedDepartment = dept;
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.only(right: 10),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                            decoration: BoxDecoration(
                              color: isSelected ? blue : (isDark ? Colors.white.withValues(alpha: 0.08) : Colors.white),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected ? blue : borderColor,
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: blue.withValues(alpha: 0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 3),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Text(
                              dept,
                              style: TextStyle(
                                color: isSelected ? Colors.white : primaryText,
                                fontSize: 12.5,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 22),

                  if (groupedDoctors.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: borderColor),
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.person_off_rounded, size: 48, color: Colors.grey),
                          const SizedBox(height: 12),
                          Text(
                            "No Doctors Found",
                            style: TextStyle(color: primaryText, fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Try searching another department or doctor name.",
                            style: TextStyle(color: secondaryText, fontSize: 12),
                          ),
                        ],
                      ),
                    )
                  else
                    ...groupedDoctors.entries.map((entry) {
                      final deptName = entry.key;
                      final deptDocs = entry.value;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12, top: 6),
                            child: Row(
                              children: [
                                Container(
                                  width: 4,
                                  height: 18,
                                  decoration: BoxDecoration(
                                    color: teal,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    deptName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: primaryText,
                                      fontSize: 17,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: blue.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    "${deptDocs.length} Specialists",
                                    style: const TextStyle(
                                      color: blue,
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ...deptDocs.map((doc) => _buildDoctorCard(context, doc)),
                          const SizedBox(height: 12),
                        ],
                      );
                    }),
                ],
              ),
            ),
    );
  }

  Widget _buildDoctorCard(BuildContext context, Map<String, dynamic> doc) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color cardColor = Theme.of(context).cardColor;
    final Color primaryText = isDark ? Colors.white : navy;
    final Color secondaryText = isDark ? Colors.white70 : Colors.grey.shade600;
    final Color borderColor = isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE8EEF5);

    final name = (doc['doctor_name'] ?? 'Doctor').toString();
    final dept = (doc['department'] ?? 'Specialist').toString();
    final spec = (doc['specialization'] ?? dept).toString();
    final exp = (doc['experience'] ?? '8+ Years').toString();
    final qual = (doc['qualification'] ?? 'MBBS, MD').toString();
    final status = (doc['status'] ?? 'Available Today').toString();
    final timing = (doc['timing'] ?? '10:00 AM - 04:00 PM').toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar
              Container(
                height: 60,
                width: 60,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [navy, blue],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: blue.withValues(alpha: 0.22),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(Icons.person_rounded, color: Colors.white, size: 34),
                ),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: primaryText,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.green.withValues(alpha: 0.25)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  color: Colors.green,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                status,
                                style: const TextStyle(
                                  color: Colors.green,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 3),

                    Text(
                      spec,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: blue,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 5),

                    Text(
                      qual,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: secondaryText,
                        fontSize: 11.5,
                      ),
                    ),

                    const SizedBox(height: 6),

                    Wrap(
                      spacing: 12,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.workspace_premium_rounded, size: 14, color: Colors.amber.shade700),
                            const SizedBox(width: 4),
                            Text(
                              "Exp: $exp",
                              style: TextStyle(color: secondaryText, fontSize: 11, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.access_time_rounded, size: 13, color: secondaryText),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                timing,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(color: secondaryText, fontSize: 11),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Divider(height: 1, color: borderColor),

          const SizedBox(height: 14),

          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("$name ($dept) - Available for Diagnostic Consultation."),
                        behavior: SnackBarBehavior.floating,
                        backgroundColor: navy,
                      ),
                    );
                  },
                  icon: const Icon(Icons.info_outline_rounded, size: 15),
                  label: const FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text("View Profile", style: TextStyle(fontSize: 12)),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: primaryText,
                    side: BorderSide(color: borderColor),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                  ),
                ),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AppointmentScreen(
                          doctorName: name,
                          scanName: "$dept Consultation",
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.calendar_month_rounded, size: 15),
                  label: const FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text("Book Appointment", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: blue,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
