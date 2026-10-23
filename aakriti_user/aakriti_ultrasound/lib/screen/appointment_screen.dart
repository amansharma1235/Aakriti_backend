import 'package:flutter/material.dart';

import '../models/appointment_model.dart';
import '../services/appointments_store.dart';
import '../services/family_members_store.dart';
import '../services/notifications_store.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/clinic_actions_helper.dart';
import '../widgets/whatsapp_logo.dart';

class AppointmentScreen extends StatefulWidget {
  final String scanName;
  final int? scanPrice;
  final int? originalPrice;
  final String? preparation;
  final String? doctorName;

  const AppointmentScreen({
    super.key,
    this.scanName = "Ultrasound Scan",
    this.scanPrice,
    this.originalPrice,
    this.preparation,
    this.doctorName,
  });

  @override
  State<AppointmentScreen> createState() => _AppointmentScreenState();
}

class _AppointmentScreenState extends State<AppointmentScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController nameController = TextEditingController();
  final TextEditingController mobileController = TextEditingController();
  final TextEditingController noteController = TextEditingController();

  String selectedPatient = "Myself";
  String selectedDate = "Select Date";
  String selectedTime = "Select Time";

  String selectedDoctor = "Dr. Rajesh Sharma (Radiologist)";

  final List<String> availableDoctors = [
    "Dr. Rajesh Sharma (Radiologist)",
    "Dr. Neha Verma (Sonologist)",
    "Dr. Amit Gupta (Radiologist)",
    "Dr. Priya Singh (Pathologist)",
    "Dr. Ankit Verma (General Physician)",
    "Dr. Sunita Rao (Gynecologist)",
    "Dr. Vikram Malhotra (Cardiologist)",
    "Dr. Rohit Saxena (Orthopedic)",
  ];

  bool isBooking = false;

  final FamilyMembersStore familyStore = FamilyMembersStore.instance;

  // ============================================================
  // THEME COLORS
  // ============================================================

  Color get backgroundColor => Theme.of(context).scaffoldBackgroundColor;

  Color get cardColor => Theme.of(context).cardColor;

  Color get primaryText => Theme.of(context).brightness == Brightness.dark
      ? Colors.white
      : const Color(0xFF071A2B);

  Color get secondaryText => Theme.of(context).brightness == Brightness.dark
      ? Colors.white70
      : Colors.grey.shade600;

  Color get borderColor => Theme.of(context).brightness == Brightness.dark
      ? Colors.white.withValues(alpha: 0.10)
      : Colors.grey.shade200;

  Color get inputColor => Theme.of(context).brightness == Brightness.dark
      ? const Color(0xFF10263A)
      : Colors.white;

  // ============================================================
  // CURRENT USER STATE
  // ============================================================
  String _mySelfName = "Patient";
  final String _mySelfAge = "24 Years";
  String _myPatientId = "";

  // ============================================================
  // FAMILY MEMBERS
  // ============================================================

  List<Map<String, String>> get familyMembers => [
    {
      "name": _mySelfName,
      "relation": "Myself",
      "age": _mySelfAge,
      "gender": "Self",
    },
    ...familyStore.getMembers(),
  ];

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();
    if (widget.doctorName != null && widget.doctorName!.trim().isNotEmpty) {
      selectedDoctor = widget.doctorName!.trim();
      if (!availableDoctors.contains(selectedDoctor)) {
        availableDoctors.insert(0, selectedDoctor);
      }
    }
    _loadUserInfo();
    _loadDoctorsFromBackend();
  }

  Future<void> _loadDoctorsFromBackend() async {
    try {
      final docs = await ApiService.getDoctors();
      if (docs.isNotEmpty && mounted) {
        final List<String> list = [];
        for (final d in docs) {
          final name = (d['doctor_name'] ?? d['name'] ?? '').toString().trim();
          final spec = (d['specialization'] ?? '').toString().trim();
          if (name.isNotEmpty) {
            final formatted = spec.isNotEmpty ? '$name ($spec)' : name;
            list.add(formatted);
          }
        }
        if (list.isNotEmpty) {
          setState(() {
            availableDoctors.clear();
            availableDoctors.addAll(list);
            if (!availableDoctors.contains(selectedDoctor)) {
              selectedDoctor = availableDoctors.first;
            }
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _loadUserInfo() async {
    final name = await AuthService.getUserName();
    final phone = await AuthService.getUserPhone();
    final pid = await AuthService.getPatientId();
    if (mounted) {
      setState(() {
        _mySelfName = name.isNotEmpty ? name : "Patient";
        _myPatientId = pid;
        nameController.text = _mySelfName;
        if (phone.isNotEmpty) {
          mobileController.text = phone.replaceAll('+91', '').replaceAll(' ', '').trim();
        }
      });
    }
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    nameController.dispose();
    mobileController.dispose();
    noteController.dispose();

    super.dispose();
  }

  // ============================================================
  // PATIENT ID
  // ============================================================

  String getCurrentPatientId() {
    if (selectedPatient == "Myself") {
      if (_myPatientId.isNotEmpty) {
        return _myPatientId;
      }
      return "PT${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}";
    }

    final mobile = mobileController.text.trim();
    if (mobile.length >= 6) {
      return "PT${mobile.substring(mobile.length - 6)}";
    }

    return "PT$mobile";
  }

  // ============================================================
  // DATE FOR BACKEND
  // ============================================================

  String getBackendDate() {
    // UI date:
    // 20/09/2026
    //
    // Backend date:
    // 2026-09-20

    if (selectedDate == "Select Date") {
      return "";
    }

    final parts = selectedDate.split("/");

    if (parts.length != 3) {
      return "";
    }

    final day = parts[0];
    final month = parts[1];
    final year = parts[2];

    return "$year-$month-$day";
  }

  // ============================================================
  // PATIENT SELECTOR
  // ============================================================

  Widget patientSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Select Patient",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: primaryText,
          ),
        ),

        const SizedBox(height: 12),

        SizedBox(
          height: 55,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: familyMembers.length,
            itemBuilder: (context, index) {
              final patient = familyMembers[index];

              final bool selected = selectedPatient == patient["relation"];

              return GestureDetector(
                onTap: () {
                  setState(() {
                    selectedPatient = patient["relation"] ?? "Myself";

                    nameController.text = patient["name"] ?? "";
                  });
                },
                child: Container(
                  margin: const EdgeInsets.only(right: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: selected ? const Color(0xFF1677FF) : cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: selected ? const Color(0xFF1677FF) : borderColor,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        patient["gender"] == "Female"
                            ? Icons.woman_outlined
                            : Icons.person_outline,
                        color: selected
                            ? Colors.white
                            : const Color(0xFF1677FF),
                      ),

                      const SizedBox(width: 8),

                      Text(
                        patient["name"] ?? "",
                        style: TextStyle(
                          color: selected ? Colors.white : primaryText,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ============================================================
  // DOCTOR SELECTOR
  // ============================================================

  Widget doctorSelector() {
    final String currentVal = availableDoctors.contains(selectedDoctor)
        ? selectedDoctor
        : availableDoctors.first;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.medical_information_outlined, color: Color(0xFF1677FF), size: 19),
            const SizedBox(width: 8),
            Text(
              "Consulting Doctor",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: primaryText,
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),

        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: inputColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: currentVal,
              isExpanded: true,
              dropdownColor: cardColor,
              style: TextStyle(color: primaryText, fontSize: 13.5, fontWeight: FontWeight.w600),
              icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF1677FF)),
              items: availableDoctors.map((doc) {
                return DropdownMenuItem<String>(
                  value: doc,
                  child: Text(
                    doc,
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    selectedDoctor = val;
                  });
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // DATE PICKER
  // ============================================================

  Future<void> selectDate() async {
    final DateTime now = DateTime.now();

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 90)),
    );

    if (picked != null) {
      setState(() {
        selectedDate =
            "${picked.day.toString().padLeft(2, '0')}/"
            "${picked.month.toString().padLeft(2, '0')}/"
            "${picked.year}";
      });
    }
  }

  // ============================================================
  // TIME PICKER (10:00 AM - 04:00 PM)
  // ============================================================

  static const List<String> clinicTimeSlots = [
    "10:00 AM",
    "10:30 AM",
    "11:00 AM",
    "11:30 AM",
    "12:00 PM",
    "12:30 PM",
    "01:00 PM",
    "01:30 PM",
    "02:00 PM",
    "02:30 PM",
    "03:00 PM",
    "03:30 PM",
    "04:00 PM",
  ];

  Future<void> selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 10, minute: 0),
    );

    if (picked != null) {
      if (picked.hour < 10 || picked.hour > 16 || (picked.hour == 16 && picked.minute > 0)) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Clinic timing is 10:00 AM - 04:00 PM. Please select within clinic hours."),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }
      setState(() {
        selectedTime = picked.format(context);
      });
    }
  }

  // ============================================================
  // BOOK APPOINTMENT
  // ============================================================

  Future<void> bookAppointment() async {
    if (isBooking) {
      return;
    }

    // Validate form
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Validate date
    if (selectedDate == "Select Date") {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select appointment date")),
      );
      return;
    }

    // Validate time
    if (selectedTime == "Select Time") {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select appointment time")),
      );
      return;
    }

    final String patientName = nameController.text.trim();

    final String mobile = mobileController.text.trim();

    final String patientId = getCurrentPatientId();

    final String backendDate = getBackendDate();

    final String appointmentId = "APT-${DateTime.now().millisecondsSinceEpoch}";

    setState(() {
      isBooking = true;
    });

    // 1. Create appointment object immediately
    final appointment = AppointmentModel(
      id: appointmentId,
      patientId: patientId,
      scanName: widget.scanName,
      patientName: patientName,
      mobile: mobile,
      doctorName: selectedDoctor,
      date: selectedDate,
      time: selectedTime,
      note: noteController.text.trim(),
      status: AppointmentStatus.pending,
    );

    try {
      // 2. Persist appointment to MySQL backend API
      final apiResult = await ApiService.addAppointment(
        appointmentId: appointmentId,
        patientId: patientId,
        patientName: patientName,
        serviceName: widget.scanName,
        appointmentDate: backendDate,
        mobile: mobile,
        appointmentTime: selectedTime,
        doctorName: selectedDoctor,
        note: noteController.text.trim(),
        status: "Pending",
      );

      if (apiResult['success'] != true) {
        if (!mounted) return;
        setState(() => isBooking = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(apiResult['message'] ?? 'Unable to confirm appointment on server. Please try again.'),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }

      // 3. Save locally after confirmed backend creation
      AppointmentStore.instance.addAppointment(appointment);

      // ========================================================
      // NOTIFICATION
      // ========================================================

      NotificationStore.instance.addNotification(
        icon: Icons.calendar_month_outlined,
        title: "Appointment Booked",
        message:
            "${widget.scanName} appointment booked with $selectedDoctor for "
            "$patientName on "
            "$selectedDate at $selectedTime.",
        color: const Color(0xFF1677FF),
      );

      if (!mounted) return;

      setState(() {
        isBooking = false;
      });

      // ========================================================
      // SUCCESS DIALOG
      // ========================================================

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          final bool isDark = Theme.of(context).brightness == Brightness.dark;

          return AlertDialog(
            backgroundColor: isDark ? const Color(0xFF10263A) : Colors.white,

            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),

            contentPadding: const EdgeInsets.all(24),

            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF18C8C8).withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle_outline,
                    color: Color(0xFF18C8C8),
                    size: 55,
                  ),
                ),

                const SizedBox(height: 18),

                Text(
                  "Appointment Booked!",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF071A2B),
                  ),
                ),

                const SizedBox(height: 10),

                Text(
                  "Your ${widget.scanName} "
                  "appointment has been "
                  "successfully booked.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  "$selectedDate • $selectedTime",
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1677FF),
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  "Patient ID: $patientId",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white60 : Colors.black54,
                  ),
                ),

                const SizedBox(height: 18),

                // WhatsApp Confirmation Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      WhatsAppHelper.shareAppointment(
                        appointmentId: appointmentId,
                        patientName: patientName,
                        service: widget.scanName,
                        date: selectedDate,
                        time: selectedTime,
                      );
                    },
                    icon: const WhatsAppLogo(size: 20, color: Colors.white),
                    label: const Text(
                      "Share on WhatsApp",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF25D366),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),

                if (widget.scanPrice != null && widget.scanPrice! > 0) ...[
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        UpiPaymentModal.show(
                          context,
                          appointmentId: appointmentId,
                          amount: widget.scanPrice!.toDouble(),
                          serviceName: widget.scanName,
                          onPaymentSuccess: () {
                            if (mounted) {
                              Navigator.pop(context);
                            }
                          },
                        );
                      },
                      icon: const Icon(Icons.qr_code_2_rounded, size: 20),
                      label: Text(
                        "Pay ₹${widget.scanPrice} via UPI",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF1677FF),
                        side: const BorderSide(color: Color(0xFF1677FF), width: 1.5),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 10),

                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.pop(context);
                    },
                    child: Text(
                      "Done & View Appointments",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );

    } catch (e) {
      if (!mounted) return;

      setState(() {
        isBooking = false;
      });

      // ========================================================
      // BACKEND ERROR
      // ========================================================

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red.shade700,
          duration: const Duration(seconds: 6),
          content: Text("Appointment save failed:\n$e"),
        ),
      );
    }
  }

  // ============================================================
  // INPUT FIELD
  // ============================================================

  Widget inputField({
    required String label,
    required String hint,
    required IconData icon,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: primaryText,
          ),
        ),

        const SizedBox(height: 8),

        TextFormField(
          controller: controller,
          keyboardType: keyboardType,

          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return "$label is required";
            }

            return null;
          },

          style: TextStyle(color: primaryText),

          decoration: InputDecoration(
            hintText: hint,

            hintStyle: TextStyle(color: secondaryText),

            prefixIcon: const Icon(
              Icons.person_outline,
              color: Color(0xFF1677FF),
            ),

            filled: true,

            fillColor: inputColor,

            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide.none,
            ),

            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide(color: borderColor),
            ),

            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: const BorderSide(color: Color(0xFF1677FF)),
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // DATE/TIME CARD
  // ============================================================

  Widget dateTimeCard({
    required String title,
    required String value,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),

          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
          ),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: const Color(0xFF1677FF)),

              const SizedBox(height: 10),

              Text(title, style: TextStyle(fontSize: 12, color: secondaryText)),

              const SizedBox(height: 4),

              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: primaryText,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,

      appBar: AppBar(
        elevation: 0,

        backgroundColor: const Color(0xFF071A2B),

        foregroundColor: Colors.white,

        title: const Text(
          "Book Appointment",
          style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
        ),
      ),

      body: Form(
        key: _formKey,

        child: SingleChildScrollView(
          padding: const EdgeInsets.all(18),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              // ==================================================
              // HERO
              // ==================================================

              Container(
                width: double.infinity,

                padding: const EdgeInsets.all(20),

                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF071A2B), Color(0xFF123A5A)],
                  ),

                  borderRadius: BorderRadius.circular(22),
                ),

                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),

                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.10),

                        borderRadius: BorderRadius.circular(16),
                      ),

                      child: const Icon(
                        Icons.medical_services_outlined,
                        color: Color(0xFF18C8C8),
                        size: 30,
                      ),
                    ),

                    const SizedBox(width: 14),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,

                        children: [
                          const Text(
                            "Appointment",
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),

                          const SizedBox(height: 4),

                          Text(
                            widget.scanName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 19,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (widget.scanPrice != null) ...[
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Text(
                                  "₹${widget.scanPrice}",
                                  style: const TextStyle(
                                    color: Color(0xFF18C8C8),
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                if (widget.originalPrice != null &&
                                    widget.originalPrice! > widget.scanPrice!) ...[
                                  const SizedBox(width: 8),
                                  Text(
                                    "₹${widget.originalPrice}",
                                    style: const TextStyle(
                                      decoration: TextDecoration.lineThrough,
                                      color: Colors.white54,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              if (widget.preparation != null &&
                  widget.preparation!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF18C8C8).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: const Color(0xFF18C8C8).withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline_rounded,
                          color: Color(0xFF18C8C8), size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "Preparation: ${widget.preparation}",
                          style: const TextStyle(
                            color: Color(0xFF18C8C8),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 24),

              patientSelector(),

              const SizedBox(height: 20),

              doctorSelector(),

              const SizedBox(height: 22),

              inputField(
                label: "Patient Name",
                hint: "Enter patient name",
                icon: Icons.person_outline,
                controller: nameController,
              ),

              const SizedBox(height: 18),

              inputField(
                label: "Mobile Number",
                hint: "Enter mobile number",
                icon: Icons.phone_outlined,
                controller: mobileController,
                keyboardType: TextInputType.phone,
              ),

              const SizedBox(height: 20),

              Text(
                "Select Date & Time",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: primaryText,
                ),
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  dateTimeCard(
                    title: "Appointment Date",
                    value: selectedDate,
                    icon: Icons.calendar_month_outlined,
                    onTap: selectDate,
                  ),

                  const SizedBox(width: 12),

                  dateTimeCard(
                    title: "Appointment Time",
                    value: selectedTime,
                    icon: Icons.access_time_outlined,
                    onTap: selectTime,
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // Quick slot pills
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Available Slots (10:00 AM - 04:00 PM)",
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: secondaryText,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF18C8C8).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      "10 AM - 4 PM",
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF18C8C8),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              SizedBox(
                height: 38,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: clinicTimeSlots.length,
                  itemBuilder: (context, idx) {
                    final slot = clinicTimeSlots[idx];
                    final isSel = selectedTime == slot;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(slot),
                        selected: isSel,
                        selectedColor: const Color(0xFF1677FF),
                        backgroundColor: cardColor,
                        labelStyle: TextStyle(
                          fontSize: 12,
                          fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                          color: isSel ? Colors.white : primaryText,
                        ),
                        side: BorderSide(
                          color: isSel ? const Color(0xFF1677FF) : borderColor,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              selectedTime = slot;
                            });
                          }
                        },
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 20),

              Text(
                "Additional Note",
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: primaryText,
                ),
              ),

              const SizedBox(height: 8),

              TextFormField(
                controller: noteController,

                maxLines: 4,

                style: TextStyle(color: primaryText),

                decoration: InputDecoration(
                  hintText: "Any special instruction or note...",

                  hintStyle: TextStyle(color: secondaryText),

                  filled: true,

                  fillColor: inputColor,

                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none,
                  ),

                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide(color: borderColor),
                  ),

                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: const BorderSide(color: Color(0xFF1677FF)),
                  ),
                ),
              ),

              const SizedBox(height: 18),

              // Upload Prescription Button
              OutlinedButton.icon(
                onPressed: () {
                  PrescriptionUploadModal.show(context);
                },
                icon: const Icon(Icons.upload_file_rounded, color: Color(0xFF1677FF), size: 20),
                label: const Text(
                  "Attach Doctor's Prescription / Referral Slip",
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 16),
                  side: BorderSide(color: const Color(0xFF1677FF).withValues(alpha: 0.5)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),

              const SizedBox(height: 22),

              // ==================================================
              // BOOK BUTTON
              // ==================================================

              SizedBox(
                width: double.infinity,

                height: 56,

                child: ElevatedButton(
                  onPressed: isBooking ? null : bookAppointment,

                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1677FF),

                    foregroundColor: Colors.white,

                    disabledBackgroundColor: const Color(0xFF1677FF)
                        .withValues(alpha: 0.6),

                    elevation: 0,

                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(17),
                    ),
                  ),

                  child: isBooking
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.calendar_month_outlined),

                            SizedBox(width: 10),

                            Text(
                              "Confirm Appointment",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                ),
              ),

              const SizedBox(height: 15),

              Center(
                child: Text(
                  "Your appointment details are securely handled.",
                  style: TextStyle(fontSize: 11.5, color: secondaryText),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
