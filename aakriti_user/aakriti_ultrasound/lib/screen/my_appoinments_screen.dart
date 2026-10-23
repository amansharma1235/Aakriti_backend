import 'package:flutter/material.dart';

import '../models/appointment_model.dart';
import '../services/appointments_store.dart';
import '../services/notifications_store.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/profile_service.dart';
import '../widgets/notification_app_bar_button.dart';

class MyAppointmentsScreen extends StatefulWidget {
  const MyAppointmentsScreen({super.key});

  @override
  State<MyAppointmentsScreen> createState() => _MyAppointmentsScreenState();
}

class _MyAppointmentsScreenState extends State<MyAppointmentsScreen> {
  List<AppointmentModel> appointments = [];

  bool isLoading = true;
  String? errorMessage;

  // =========================================================
  // CURRENT PATIENT
  // =========================================================

  // Logged-in Patient details
  String currentPatientId = "";
  String currentPatientName = "Patient";

  // =========================================================
  // THEME
  // =========================================================

  bool get isDark => Theme.of(context).brightness == Brightness.dark;

  Color get backgroundColor => Theme.of(context).scaffoldBackgroundColor;

  Color get cardColor => Theme.of(context).cardColor;

  Color get primaryText => isDark ? Colors.white : const Color(0xFF071A2B);

  Color get secondaryText => isDark ? Colors.white70 : Colors.black54;

  Color get borderColor =>
      isDark ? Colors.white.withValues(alpha: 0.10) : Colors.grey.shade200;

  Color get detailCardColor =>
      isDark ? const Color(0xFF10263A) : const Color(0xFFF7F9FC);

  // =========================================================
  // INIT
  // =========================================================

  @override
  void initState() {
    super.initState();
    loadAppointments();
  }

  // =========================================================
  // LOAD APPOINTMENTS
  // =========================================================

  Future<void> loadAppointments() async {
    final sessionUser = await AuthService.getCurrentUser();
    final activePid = await AuthService.getPatientId();
    final activeName = (sessionUser?['name'] ?? ProfileService.userNameNotifier.value).toString().trim();
    final activePhone = (sessionUser?['phone'] ?? ProfileService.userMobileNotifier.value).toString().replaceAll('+91', '').replaceAll(' ', '').trim();

    if (mounted) {
      setState(() {
        currentPatientId = activePid;
        currentPatientName = activeName.isNotEmpty ? activeName : "Patient";
      });
    }

    await AppointmentStore.instance.loadAppointments();
    final rawLocalList = AppointmentStore.instance.getAppointments();

    // Filter local appointments so only the logged in user's appointments are displayed
    final localList = rawLocalList.where((appt) {
      final pid = appt.patientId.trim().toLowerCase();
      final name = appt.patientName.trim().toLowerCase();
      final phone = appt.mobile.replaceAll('+91', '').replaceAll(' ', '').trim();

      final matchesPid = activePid.isNotEmpty && pid.isNotEmpty && pid == activePid.toLowerCase();
      final matchesName = activeName.isNotEmpty && name.isNotEmpty && name == activeName.toLowerCase();
      final matchesPhone = activePhone.isNotEmpty && phone.isNotEmpty && phone == activePhone;

      return matchesPid || matchesName || matchesPhone;
    }).toList();

    if (mounted) {
      setState(() {
        if (localList.isNotEmpty) {
          appointments = List.from(localList);
          isLoading = false;
        } else {
          isLoading = true;
        }
        errorMessage = null;
      });
    }

    try {
      final List<Map<String, dynamic>> combinedApiList = [];

      // Fetch appointments strictly by patient ID (authenticated & authorized)
      final byPatientId = await ApiService.getPatientAppointments(
        patientId: activePid,
      );
      combinedApiList.addAll(byPatientId);

      final List<AppointmentModel> apiAppointments = combinedApiList.map((
        data,
      ) {
        return _appointmentFromApi(data);
      }).toList();

      if (!mounted) return;

      // Merge backend and local appointments by ID
      final Map<String, AppointmentModel> mergedMap = {};
      for (var appt in localList) {
        mergedMap[appt.id] = appt;
      }
      for (var appt in apiAppointments) {
        mergedMap[appt.id] = appt;
      }

      final combined = mergedMap.values.toList();
      combined.sort((a, b) => b.id.compareTo(a.id));

      setState(() {
        appointments = combined;
        isLoading = false;
        errorMessage = combined.isEmpty
            ? "No appointments found. Tap 'Book Appointment' to schedule a test."
            : null;
      });
    } catch (e) {
      if (!mounted) return;

      if (localList.isNotEmpty) {
        setState(() {
          appointments = List.from(localList);
          isLoading = false;
          errorMessage = null;
        });
      } else {
        setState(() {
          isLoading = false;
          errorMessage = "No appointments found. Tap 'Book Appointment' to schedule a test.";
        });
      }
    }
  }

  // =========================================================
  // API → MODEL
  // =========================================================

  AppointmentModel _appointmentFromApi(Map<String, dynamic> data) {
    return AppointmentModel(
      id: (data['appointment_id'] ?? data['id'] ?? '').toString(),
      databaseId: int.tryParse((data['id'] ?? '').toString()),
      patientId: (data['patient_id'] ?? currentPatientId).toString(),
      scanName: (data['service_name'] ?? 'Ultrasound Scan').toString(),
      patientName: (data['patient_name'] ?? 'Patient').toString(),
      mobile: (data['mobile'] ?? '').toString(),
      doctorName: data['doctor_name']?.toString() ?? data['doctorName']?.toString(),
      date: _formatDate((data['appointment_date'] ?? '').toString()),
      time: (data['appointment_time'] ?? 'Not specified').toString(),
      note: (data['note'] ?? '').toString(),
      status: _statusFromApi((data['status'] ?? 'Pending').toString()),
    );
  }

  // =========================================================
  // DATE FORMAT
  // =========================================================

  String _formatDate(String date) {
    if (date.isEmpty) {
      return "Not specified";
    }

    try {
      final parsedDate = DateTime.parse(date);

      return "${parsedDate.day.toString().padLeft(2, '0')}/"
          "${parsedDate.month.toString().padLeft(2, '0')}/"
          "${parsedDate.year}";
    } catch (_) {
      return date;
    }
  }

  // =========================================================
  // STATUS
  // =========================================================

  AppointmentStatus _statusFromApi(String status) {
    switch (status.toLowerCase().trim()) {
      case "confirmed":
        return AppointmentStatus.confirmed;

      case "completed":
        return AppointmentStatus.completed;

      case "cancelled":
      case "canceled":
        return AppointmentStatus.cancelled;

      case "pending":
      default:
        return AppointmentStatus.pending;
    }
  }

  // =========================================================
  // STATUS COLOR
  // =========================================================

  Color statusColor(AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.pending:
        return Colors.orange;
      case AppointmentStatus.confirmed:
        return const Color(0xFF1677FF);
      case AppointmentStatus.checkedIn:
        return Colors.teal;
      case AppointmentStatus.inProgress:
        return Colors.purple;
      case AppointmentStatus.completed:
        return Colors.green;
      case AppointmentStatus.cancelled:
        return Colors.red;
      case AppointmentStatus.rescheduled:
        return Colors.amber;
      case AppointmentStatus.noShow:
        return Colors.grey;
    }
  }

  // =========================================================
  // STATUS ICON
  // =========================================================

  IconData statusIcon(AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.pending:
        return Icons.access_time_outlined;
      case AppointmentStatus.confirmed:
        return Icons.check_circle_outline;
      case AppointmentStatus.checkedIn:
        return Icons.how_to_reg_outlined;
      case AppointmentStatus.inProgress:
        return Icons.hourglass_top_outlined;
      case AppointmentStatus.completed:
        return Icons.verified_outlined;
      case AppointmentStatus.cancelled:
        return Icons.cancel_outlined;
      case AppointmentStatus.rescheduled:
        return Icons.update_outlined;
      case AppointmentStatus.noShow:
        return Icons.person_off_outlined;
    }
  }

  // =========================================================
  // CANCEL
  // =========================================================

  void cancelAppointment(AppointmentModel appointment) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF10263A) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: Text(
            "Cancel Appointment?",
            style: TextStyle(fontWeight: FontWeight.bold, color: primaryText),
          ),
          content: Text(
            "Are you sure you want to cancel your "
            "${appointment.scanName} appointment?",
            style: TextStyle(color: secondaryText),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text("No"),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(dialogContext);

                if (appointment.databaseId != null) {
                  await ApiService.cancelAppointment(
                    appointmentId: appointment.databaseId!,
                  );
                }

                AppointmentStore.instance.cancelAppointment(appointment.id);

                NotificationStore.instance.addNotification(
                  icon: Icons.cancel_outlined,
                  title: "Appointment Cancelled",
                  message:
                      "Your ${appointment.scanName} "
                      "appointment for "
                      "${appointment.patientName} "
                      "has been cancelled.",
                  color: Colors.red,
                );

                loadAppointments();

                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Appointment cancelled")),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text("Cancel"),
            ),
          ],
        );
      },
    );
  }

  // =========================================================
  // DELETE APPOINTMENT
  // =========================================================

  void deleteAppointment(AppointmentModel appointment) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF10263A) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: Row(
            children: [
              const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 24),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  "Delete Appointment?",
                  style: TextStyle(fontWeight: FontWeight.bold, color: primaryText, fontSize: 18),
                ),
              ),
            ],
          ),
          content: Text(
            "Are you sure you want to permanently delete this ${appointment.scanName} appointment record?",
            style: TextStyle(color: secondaryText, fontSize: 13.5),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(dialogContext);

                final String targetId = appointment.databaseId != null
                    ? appointment.databaseId.toString()
                    : appointment.id;

                await ApiService.deleteAppointment(
                  appointmentId: targetId,
                );

                AppointmentStore.instance.deleteAppointment(appointment.id);

                NotificationStore.instance.addNotification(
                  icon: Icons.delete_sweep_outlined,
                  title: "Appointment Deleted",
                  message:
                      "Your ${appointment.scanName} appointment record has been deleted.",
                  color: Colors.redAccent,
                );

                loadAppointments();

                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Appointment deleted successfully"),
                    backgroundColor: Colors.redAccent,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text("Delete"),
            ),
          ],
        );
      },
    );
  }

  // =========================================================
  // RESCHEDULE
  // =========================================================

  Future<void> rescheduleAppointment(AppointmentModel appointment) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );

    if (pickedDate == null || !mounted) {
      return;
    }

    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 10, minute: 0),
    );

    if (pickedTime == null || !mounted) {
      return;
    }

    if (pickedTime.hour < 10 || pickedTime.hour > 16 || (pickedTime.hour == 16 && pickedTime.minute > 0)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Clinic timing is 10:00 AM - 04:00 PM. Please choose within these hours."),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final String newDate =
        "${pickedDate.day.toString().padLeft(2, '0')}/"
        "${pickedDate.month.toString().padLeft(2, '0')}/"
        "${pickedDate.year}";

    final String newTime = pickedTime.format(context);

    if (appointment.databaseId != null) {
      final backendDate =
          "${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')}";
      await ApiService.rescheduleAppointment(
        appointmentId: appointment.databaseId!,
        newDate: backendDate,
        newTime: newTime,
      );
    }

    AppointmentStore.instance.rescheduleAppointment(
      id: appointment.id,
      newDate: newDate,
      newTime: newTime,
    );

    NotificationStore.instance.addNotification(
      icon: Icons.update_outlined,
      title: "Appointment Rescheduled",
      message:
          "Your ${appointment.scanName} "
          "appointment has been rescheduled "
          "to $newDate at $newTime.",
      color: Colors.orange,
    );

    await loadAppointments();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Appointment rescheduled successfully")),
    );
  }

  // =========================================================
  // APPOINTMENT DETAILS
  // =========================================================

  void showAppointmentDetails(AppointmentModel appointment) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Container(
          height: MediaQuery.of(sheetContext).size.height * 0.88,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF06121F) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 10),

                Container(
                  width: 45,
                  height: 5,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),

                const SizedBox(height: 18),

                Text(
                  "Appointment Details",
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                    color: primaryText,
                  ),
                ),

                const SizedBox(height: 20),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // HERO
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF071A2B), Color(0xFF123A5A)],
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.medical_services_outlined,
                                color: Color(0xFF18C8C8),
                                size: 32,
                              ),

                              const SizedBox(height: 12),

                              Text(
                                appointment.scanName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),

                              const SizedBox(height: 6),

                              Text(
                                "Appointment ID: "
                                "${appointment.id}",
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 18),

                        appointmentTimeline(appointment.status),

                        const SizedBox(height: 6),

                        detailCard(
                          icon: Icons.badge_outlined,
                          title: "Patient ID",
                          value: appointment.patientId,
                        ),

                        detailCard(
                          icon: Icons.person_outline,
                          title: "Patient",
                          value: appointment.patientName,
                        ),

                        detailCard(
                          icon: Icons.phone_outlined,
                          title: "Mobile",
                          value: appointment.mobile,
                        ),

                        if (appointment.doctorName != null && appointment.doctorName!.isNotEmpty)
                          detailCard(
                            icon: Icons.medical_information_outlined,
                            title: "Doctor",
                            value: appointment.doctorName!,
                          ),

                        detailCard(
                          icon: Icons.calendar_month_outlined,
                          title: "Date",
                          value: appointment.date,
                        ),

                        detailCard(
                          icon: Icons.access_time_outlined,
                          title: "Time",
                          value: appointment.time,
                        ),

                        detailCard(
                          icon: Icons.info_outline,
                          title: "Status",
                          value: appointment.statusText,
                          valueColor: statusColor(appointment.status),
                        ),

                        if (appointment.note.isNotEmpty)
                          detailCard(
                            icon: Icons.notes_outlined,
                            title: "Note",
                            value: appointment.note,
                          ),

                        const SizedBox(height: 20),

                        if (appointment.status != AppointmentStatus.cancelled)
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () {
                                    Navigator.pop(sheetContext);

                                    rescheduleAppointment(appointment);
                                  },
                                  icon: const Icon(Icons.update_outlined),
                                  label: const Text("Reschedule"),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: const Color(0xFF1677FF),
                                    side: const BorderSide(
                                      color: Color(0xFF1677FF),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(width: 12),

                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    Navigator.pop(sheetContext);

                                    cancelAppointment(appointment);
                                  },
                                  icon: const Icon(Icons.cancel_outlined),
                                  label: const Text("Cancel"),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),

                        const SizedBox(height: 12),

                        SizedBox(
                          width: double.infinity,
                          child: TextButton.icon(
                            onPressed: () {
                              Navigator.pop(sheetContext);
                              deleteAppointment(appointment);
                            },
                            icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                            label: const Text(
                              "Delete Appointment",
                              style: TextStyle(
                                color: Colors.redAccent,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            style: TextButton.styleFrom(
                              backgroundColor: Colors.red.withValues(alpha: 0.08),
                              padding: const EdgeInsets.symmetric(vertical: 13),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // =========================================================
  // TIMELINE WIDGET
  // =========================================================

  Widget appointmentTimeline(AppointmentStatus status) {
    if (status == AppointmentStatus.cancelled) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.red.withValues(alpha: 0.25)),
        ),
        child: const Row(
          children: [
            Icon(Icons.cancel_rounded, color: Colors.red, size: 20),
            SizedBox(width: 10),
            Text(
              "Appointment Cancelled",
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ],
        ),
      );
    }

    final int step = status == AppointmentStatus.pending
        ? 1
        : status == AppointmentStatus.confirmed
            ? 2
            : 3;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: detailCardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Appointment Status Flow",
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: primaryText),
              ),
              Text(
                step == 1
                    ? "Pending Admin Confirmation"
                    : step == 2
                        ? "Confirmed & Scheduled"
                        : "Completed",
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: step == 1
                      ? Colors.orange
                      : step == 2
                          ? const Color(0xFF1677FF)
                          : Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _timelineStep(title: "Booked", done: step >= 1, active: step == 1),
              _timelineLine(done: step >= 2),
              _timelineStep(title: "Confirmed", done: step >= 2, active: step == 2),
              _timelineLine(done: step >= 3),
              _timelineStep(title: "Completed", done: step >= 3, active: step == 3),
            ],
          ),
        ],
      ),
    );
  }

  Widget _timelineStep({required String title, required bool done, required bool active}) {
    final color = done ? const Color(0xFF1677FF) : Colors.grey.shade400;
    return Column(
      children: [
        Container(
          height: 22,
          width: 22,
          decoration: BoxDecoration(
            color: done ? const Color(0xFF1677FF) : Colors.transparent,
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 2),
          ),
          child: Center(
            child: done
                ? const Icon(Icons.check, size: 14, color: Colors.white)
                : Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          ),
        ),
        const SizedBox(height: 5),
        Text(
          title,
          style: TextStyle(
            fontSize: 10,
            fontWeight: active ? FontWeight.bold : FontWeight.w500,
            color: active ? primaryText : secondaryText,
          ),
        ),
      ],
    );
  }

  Widget _timelineLine({required bool done}) {
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: 14),
        color: done ? const Color(0xFF1677FF) : Colors.grey.withValues(alpha: 0.25),
      ),
    );
  }

  // =========================================================
  // DETAIL CARD
  // =========================================================

  Widget detailCard({
    required IconData icon,
    required String title,
    required String value,
    Color? valueColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: detailCardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Container(
            height: 42,
            width: 42,
            decoration: BoxDecoration(
              color: const Color(0xFF1677FF).withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: const Color(0xFF1677FF)),
          ),

          const SizedBox(width: 13),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontSize: 11.5, color: secondaryText),
                ),

                const SizedBox(height: 3),

                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    color: valueColor ?? primaryText,
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
  // APPOINTMENT CARD
  // =========================================================

  Widget appointmentCard(AppointmentModel appointment) {
    final color = statusColor(appointment.status);

    return GestureDetector(
      onTap: () {
        showAppointmentDetails(appointment);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(17),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.04),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 52,
                  width: 52,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1677FF).withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: const Icon(
                    Icons.medical_services_outlined,
                    color: Color(0xFF1677FF),
                  ),
                ),

                const SizedBox(width: 13),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        appointment.scanName,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: primaryText,
                        ),
                      ),

                      const SizedBox(height: 6),

                      Text(
                        appointment.patientName,
                        style: TextStyle(fontSize: 13, color: secondaryText),
                      ),
                    ],
                  ),
                ),

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        statusIcon(appointment.status),
                        size: 14,
                        color: color,
                      ),

                      const SizedBox(width: 4),

                      Text(
                        appointment.statusText,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: _smallInfo(
                    Icons.calendar_month_outlined,
                    appointment.date,
                  ),
                ),

                Expanded(
                  child: _smallInfo(
                    Icons.access_time_outlined,
                    appointment.time,
                  ),
                ),
              ],
            ),

            Padding(
              padding: const EdgeInsets.only(top: 14),
              child: Row(
                children: [
                  if (appointment.status != AppointmentStatus.cancelled) ...[
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          rescheduleAppointment(appointment);
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF1677FF),
                          side: const BorderSide(color: Color(0xFF1677FF)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        child: const Text("Reschedule", style: TextStyle(fontSize: 12.5)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          cancelAppointment(appointment);
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.orange.shade800,
                          side: BorderSide(color: Colors.orange.shade400),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        child: const Text("Cancel", style: TextStyle(fontSize: 12.5)),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  InkWell(
                    onTap: () => deleteAppointment(appointment),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red.withValues(alpha: 0.25)),
                      ),
                      child: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // SMALL INFO
  // =========================================================

  Widget _smallInfo(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF1677FF)),

        const SizedBox(width: 7),

        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: secondaryText,
            ),
          ),
        ),
      ],
    );
  }

  // =========================================================
  // EMPTY STATE
  // =========================================================

  Widget emptyState() {
    final bool hasError =
        errorMessage != null && errorMessage!.startsWith("Backend Error:");

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(25),
              decoration: BoxDecoration(
                color: const Color(0xFF1677FF).withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                hasError
                    ? Icons.cloud_off_outlined
                    : Icons.calendar_month_outlined,
                size: 65,
                color: hasError ? Colors.orange : const Color(0xFF1677FF),
              ),
            ),

            const SizedBox(height: 22),

            Text(
              hasError ? "Backend Connection Error" : "No Appointments",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.bold,
                color: primaryText,
              ),
            ),

            const SizedBox(height: 10),

            if (hasError)
              Text(
                errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: secondaryText),
              )
            else
              Text(
                "No appointment found for $currentPatientName.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: secondaryText),
              ),

            const SizedBox(height: 18),

            OutlinedButton.icon(
              onPressed: loadAppointments,
              icon: const Icon(Icons.refresh),
              label: const Text("Refresh"),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // ERROR BANNER
  // =========================================================

  Widget errorBanner() {
    if (errorMessage == null) {
      return const SizedBox.shrink();
    }

    final bool isBackendError = errorMessage!.startsWith("Backend Error:");

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isBackendError
            ? Colors.red.withValues(alpha: 0.08)
            : Colors.orange.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isBackendError ? Icons.error_outline : Icons.info_outline,
            color: isBackendError ? Colors.red : Colors.orange,
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Text(
              errorMessage!,
              style: TextStyle(color: primaryText, fontSize: 12),
            ),
          ),

          IconButton(
            onPressed: loadAppointments,
            icon: Icon(
              Icons.refresh,
              color: isBackendError ? Colors.red : Colors.orange,
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,

      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF071A2B),
        foregroundColor: Colors.white,

        title: const Text(
          "My Appointments",
          style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
        ),

        actions: [
          const NotificationAppBarButton(),
          IconButton(
            onPressed: isLoading ? null : loadAppointments,
            icon: const Icon(Icons.refresh),
            tooltip: "Refresh",
          ),
        ],
      ),

      body: Column(
        children: [
          errorBanner(),

          Expanded(
            child: isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF1677FF)),
                  )
                : appointments.isEmpty
                ? emptyState()
                : RefreshIndicator(
                    color: const Color(0xFF1677FF),
                    onRefresh: loadAppointments,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: appointments.length,
                      itemBuilder: (context, index) {
                        return appointmentCard(appointments[index]);
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
