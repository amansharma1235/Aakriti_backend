import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/appointment_model.dart';

class AppointmentStore {
  AppointmentStore._() {
    loadAppointments();
  }

  static final AppointmentStore instance = AppointmentStore._();
  static const String _storageKey = 'user_appointments_list_v2';

  final List<AppointmentModel> _appointments = [];

  // ================= LOAD APPOINTMENTS =================
  Future<void> loadAppointments() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw != null && raw.isNotEmpty) {
        final List decoded = jsonDecode(raw);
        _appointments.clear();
        for (var item in decoded) {
          try {
            _appointments.add(AppointmentModel.fromJson(Map<String, dynamic>.from(item)));
          } catch (_) {}
        }
      }
    } catch (e) {
      debugPrint('[AppointmentStore] load error: $e');
    }
  }

  // ================= SAVE APPOINTMENTS =================
  Future<void> _saveToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = _appointments.map((a) => a.toJson()).toList();
      await prefs.setString(_storageKey, jsonEncode(list));
    } catch (e) {
      debugPrint('[AppointmentStore] save error: $e');
    }
  }

  // ================= ADD APPOINTMENT =================
  void addAppointment(AppointmentModel appointment) {
    _appointments.removeWhere((item) => item.id == appointment.id);
    _appointments.insert(0, appointment);
    _saveToPrefs();
  }

  // ================= GET APPOINTMENTS =================
  List<AppointmentModel> getAppointments() {
    return List.unmodifiable(_appointments);
  }

  // ================= CANCEL APPOINTMENT =================
  void cancelAppointment(String id) {
    final index = _appointments.indexWhere((item) => item.id == id);
    if (index != -1) {
      _appointments[index].status = AppointmentStatus.cancelled;
      _saveToPrefs();
    }
  }

  // ================= DELETE APPOINTMENT =================
  void deleteAppointment(String id) {
    _appointments.removeWhere((item) => item.id == id);
    _saveToPrefs();
  }

  // ================= RESCHEDULE APPOINTMENT =================
  void rescheduleAppointment({
    required String id,
    required String newDate,
    required String newTime,
  }) {
    final index = _appointments.indexWhere((item) => item.id == id);
    if (index != -1) {
      _appointments[index].date = newDate;
      _appointments[index].time = newTime;
      _appointments[index].status = AppointmentStatus.pending;
      _saveToPrefs();
    }
  }
}
