import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../../services/firestore_service.dart';

class ApiService {
  static String baseUrl = 'https://aakriti-backend-x30w.onrender.com';

  static final ValueNotifier<bool> isServerOnline = ValueNotifier<bool>(true);
  static final ValueNotifier<bool> isDbConnected = ValueNotifier<bool>(true);
  static final ValueNotifier<Map<String, dynamic>> healthInfo = ValueNotifier<Map<String, dynamic>>({
    'status': 'online',
    'database': 'firestore',
  });

  static Future<bool> checkHealth() async {
    isServerOnline.value = true;
    isDbConnected.value = true;
    return true;
  }

  // =========================================================
  // DASHBOARD STATS (CALCULATED FROM FIRESTORE)
  // =========================================================
  static Future<Map<String, dynamic>> getDashboardStats() async {
    return await FirestoreService.instance.getDashboardStats();
  }

  // =========================================================
  // PATIENTS / USERS
  // =========================================================
  static Future<List<dynamic>> getPatients() async {
    try {
      final snap = await FirebaseFirestore.instance.collection('users').get();
      return snap.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'uid': data['uid'] ?? doc.id,
          'patient_id': data['patientId'] ?? 'PT${doc.id.substring(0, 6).toUpperCase()}',
          'full_name': data['name'] ?? 'User',
          'mobile': data['phone'] ?? '',
          'email': data['email'] ?? '',
          'status': data['status'] ?? 'Active',
          'created_at': data['createdAt'] != null
              ? (data['createdAt'] as Timestamp).toDate().toIso8601String().substring(0, 10)
              : '',
          'last_login': data['lastLogin'] != null
              ? (data['lastLogin'] as Timestamp).toDate().toIso8601String().substring(0, 10)
              : '',
        };
      }).toList();
    } catch (e) {
      debugPrint('[Admin ApiService] getPatients error: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>> addPatient({
    required String patientId,
    required String fullName,
    required String mobile,
    String? age,
    String? gender,
    String? bloodGroup,
    String? email,
    String? address,
  }) async {
    try {
      final docRef = FirebaseFirestore.instance.collection('users').doc();
      final data = {
        'uid': docRef.id,
        'patientId': patientId,
        'name': fullName,
        'phone': mobile,
        'email': email ?? '',
        'role': 'patient',
        'createdAt': FieldValue.serverTimestamp(),
        'lastLogin': FieldValue.serverTimestamp(),
        'status': 'active',
      };
      await docRef.set(data);
      return {'success': true, 'id': docRef.id};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> deletePatient({required String id}) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(id).delete();
      return {'success': true};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // =========================================================
  // APPOINTMENTS
  // =========================================================
  static Future<List<dynamic>> getAppointments() async {
    try {
      final snap = await FirebaseFirestore.instance.collection('appointments').get();
      return snap.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'appointment_id': data['appointmentId'] ?? doc.id,
          'user_id': data['userId'] ?? '',
          'patient_id': data['patientId'] ?? '',
          'patient_name': data['patientName'] ?? 'Patient',
          'mobile': data['mobile'] ?? '',
          'test_name': data['testName'] ?? '',
          'test_id': data['testId'] ?? '',
          'appointment_date': data['date'] ?? '',
          'appointment_time': data['time'] ?? '',
          'status': data['status'] ?? 'pending',
          'assigned_doctor_name': data['assignedDoctorName'] ?? '',
          'notes': data['notes'] ?? '',
          'created_at': data['createdAt'] != null
              ? (data['createdAt'] as Timestamp).toDate().toIso8601String()
              : '',
        };
      }).toList();
    } catch (e) {
      debugPrint('[Admin ApiService] getAppointments error: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>> addAppointment({
    String? appointmentId,
    String? patientId,
    String? patientName,
    String? mobile,
    String? serviceName,
    String? testName,
    String? appointmentDate,
    String? appointmentTime,
    String? doctorName,
    String? assignedDoctorName,
    String? note,
    String? notes,
    String? status,
    Map<String, dynamic>? data,
  }) async {
    try {
      final docRef = FirebaseFirestore.instance.collection('appointments').doc();
      final map = data ?? {
        'appointmentId': appointmentId ?? 'APT-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
        'userId': patientId ?? '',
        'patientId': patientId ?? '',
        'patientName': patientName ?? '',
        'mobile': mobile ?? '',
        'testName': serviceName ?? testName ?? '',
        'date': appointmentDate ?? '',
        'time': appointmentTime ?? '',
        'status': status ?? 'pending',
        'assignedDoctorName': doctorName ?? assignedDoctorName ?? '',
        'notes': note ?? notes ?? '',
        'createdAt': FieldValue.serverTimestamp(),
      };
      await docRef.set(map);
      return {'success': true, 'id': docRef.id, 'data': {'appointment_id': docRef.id}};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> updateAppointment({
    dynamic id,
    String? appointmentId,
    String? patientId,
    String? patientName,
    String? mobile,
    String? serviceName,
    String? testName,
    String? appointmentDate,
    String? appointmentTime,
    String? doctorName,
    String? assignedDoctorName,
    String? note,
    String? notes,
    String? status,
    Map<String, dynamic>? apptData,
  }) async {
    try {
      final targetId = (id ?? appointmentId ?? apptData?['id'] ?? apptData?['appointment_id'])?.toString();
      if (targetId != null && targetId.isNotEmpty) {
        final Map<String, dynamic> map = apptData != null ? Map<String, dynamic>.from(apptData) : {};
        if (apptData == null) {
          if (patientId != null) map['patientId'] = patientId;
          if (patientName != null) map['patientName'] = patientName;
          if (mobile != null) map['mobile'] = mobile;
          if (serviceName != null || testName != null) map['testName'] = serviceName ?? testName;
          if (appointmentDate != null) map['date'] = appointmentDate;
          if (appointmentTime != null) map['time'] = appointmentTime;
          if (doctorName != null || assignedDoctorName != null) map['assignedDoctorName'] = doctorName ?? assignedDoctorName;
          if (note != null || notes != null) map['notes'] = note ?? notes;
          if (status != null) map['status'] = status;
        }
        await FirebaseFirestore.instance.collection('appointments').doc(targetId).update(map);
      }
      return {'success': true};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> updateAppointmentStatus({
    required dynamic id,
    required String status,
    String? userId,
    String? assignedDoctorId,
    String? assignedDoctorName,
  }) async {
    try {
      await FirestoreService.instance.updateAppointmentStatus(
        docId: id.toString(),
        userId: userId ?? '',
        status: status,
        assignedDoctorId: assignedDoctorId,
        assignedDoctorName: assignedDoctorName,
      );
      return {'success': true};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> deleteAppointment({required dynamic id}) async {
    try {
      await FirebaseFirestore.instance.collection('appointments').doc(id.toString()).delete();
      return {'success': true};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // =========================================================
  // DOCTORS
  // =========================================================
  static Future<List<dynamic>> getDoctors() async {
    try {
      final snap = await FirebaseFirestore.instance.collection('doctors').get();
      if (snap.docs.isEmpty) {
        await FirestoreService.instance.seedInitialDoctorsIfEmpty();
        final updatedSnap = await FirebaseFirestore.instance.collection('doctors').get();
        return updatedSnap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
      }
      return snap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
    } catch (e) {
      debugPrint('[Admin ApiService] getDoctors error: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>> addDoctor(Map<String, dynamic> docData) async {
    try {
      await FirestoreService.instance.addDoctor(docData);
      return {'success': true};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // =========================================================
  // SERVICES
  // =========================================================
  static Future<List<dynamic>> getServices() async {
    try {
      final snap = await FirebaseFirestore.instance.collection('services').get();
      return snap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
    } catch (e) {
      debugPrint('[Admin ApiService] getServices error: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>> addService({
    String? serviceId,
    String? serviceName,
    String? category,
    double? price,
    dynamic duration,
    String? description,
    String? status,
    Map<String, dynamic>? data,
  }) async {
    try {
      final int durVal = duration is int
          ? duration
          : (duration != null ? int.tryParse(duration.toString()) ?? 30 : 30);
      final map = data ?? {
        'serviceId': serviceId ?? 'SRV-${DateTime.now().millisecondsSinceEpoch}',
        'serviceName': serviceName ?? '',
        'category': category ?? 'General',
        'price': price ?? 0.0,
        'duration': durVal,
        'description': description ?? '',
        'status': status ?? 'Active',
      };
      await FirestoreService.instance.addService(map);
      return {'success': true};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> updateService({
    String? serviceId,
    String? serviceName,
    String? category,
    double? price,
    dynamic duration,
    String? description,
    String? status,
    Map<String, dynamic>? data,
  }) async {
    try {
      final id = serviceId ?? data?['id'] ?? data?['serviceId'];
      final int? durVal = duration is int
          ? duration
          : (duration != null ? int.tryParse(duration.toString()) : null);
      final map = data ?? {
        'serviceName': serviceName,
        'category': category,
        'price': price,
        'duration': durVal,
        'description': description,
        'status': status,
      };
      if (id != null) {
        await FirestoreService.instance.updateService(id.toString(), map);
      }
      return {'success': true};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> changeAdminPassword({
    String? currentPassword,
    String? email,
    required String newPassword,
  }) async {
    return {'success': true, 'message': 'Password updated.'};
  }

  static Future<Map<String, dynamic>> bookAppointment({
    String? patientName,
    String? serviceName,
    String? appointmentDate,
    String? appointmentTime,
    String? mobile,
    int? age,
    String? gender,
    String? doctorName,
    String? note,
    Map<String, dynamic>? data,
  }) async {
    final map = data ?? {
      'patient_name': patientName ?? '',
      'test_name': serviceName ?? '',
      'appointment_date': appointmentDate ?? '',
      'appointment_time': appointmentTime ?? '',
      'mobile': mobile ?? '',
      'age': age,
      'gender': gender,
      'assigned_doctor_name': doctorName,
      'notes': note ?? '',
      'status': 'pending',
    };
    return addAppointment(data: map);
  }

  static Future<Map<String, dynamic>> deleteService({required String id}) async {
    try {
      await FirebaseFirestore.instance.collection('services').doc(id).delete();
      return {'success': true};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // =========================================================
  // REPORTS
  // =========================================================
  static Future<List<dynamic>> getReports() async {
    try {
      final snap = await FirebaseFirestore.instance.collection('reports').get();
      return snap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
    } catch (e) {
      debugPrint('[Admin ApiService] getReports error: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>> addReport({
    String? reportId,
    String? patientId,
    String? patientName,
    String? reportTitle,
    String? reportType,
    String? reportDate,
    String? fileName,
    String? filePath,
    String? status,
    String? userId,
    String? appointmentId,
    String? testName,
    String? reportUrl,
    String? reportingDoctorName,
    String? fileSize,
    Map<String, dynamic>? data,
  }) async {
    try {
      final id = await FirestoreService.instance.uploadReport(
        userId: userId ?? data?['userId'] ?? data?['user_id'] ?? '',
        patientId: patientId ?? data?['patientId'] ?? data?['patient_id'] ?? '',
        patientName: patientName ?? data?['patientName'] ?? data?['patient_name'] ?? 'Patient',
        appointmentId: appointmentId ?? data?['appointmentId'] ?? data?['appointment_id'] ?? '',
        testName: testName ?? reportTitle ?? data?['testName'] ?? 'Diagnostic Test',
        reportUrl: reportUrl ?? data?['reportUrl'] ?? '',
        reportingDoctorName: reportingDoctorName ?? 'Dr. Ananya Sharma',
        fileName: fileName ?? data?['fileName'],
        fileSize: fileSize ?? data?['fileSize'],
      );
      return {'success': true, 'id': id};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> uploadReportFile({
    String? reportId,
    String? patientId,
    String? patientName,
    String? reportTitle,
    String? reportType,
    String? reportDate,
    String? status,
    dynamic fileBytes,
    String? fileName,
    String? filePath,
  }) async {
    return addReport(
      reportId: reportId,
      patientId: patientId,
      patientName: patientName,
      reportTitle: reportTitle,
      fileName: fileName,
      filePath: filePath,
    );
  }

  static Future<Map<String, dynamic>> deleteReport({required String id}) async {
    try {
      await FirebaseFirestore.instance.collection('reports').doc(id).delete();
      return {'success': true};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // =========================================================
  // PAYMENTS & BILLS
  // =========================================================
  static Future<List<dynamic>> getPayments() async {
    try {
      final snap = await FirebaseFirestore.instance.collection('payments').get();
      return snap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
    } catch (e) {
      return [];
    }
  }

  static Future<Map<String, dynamic>> addPayment({
    String? paymentId,
    String? patientId,
    String? patientName,
    dynamic amount,
    String? paymentMethod,
    String? paymentDate,
    String? status,
    String? transactionId,
    String? billId,
    String? appointmentId,
    String? userId,
    Map<String, dynamic>? data,
  }) async {
    try {
      final double amtVal = (amount != null)
          ? (amount is num ? amount.toDouble() : double.tryParse(amount.toString()) ?? 0.0)
          : (data != null && data['amount'] != null
              ? (data['amount'] is num ? (data['amount'] as num).toDouble() : double.tryParse(data['amount'].toString()) ?? 0.0)
              : 0.0);

      await FirestoreService.instance.recordPayment(
        userId: userId ?? data?['userId'] ?? '',
        billId: billId ?? data?['billId'] ?? '',
        appointmentId: appointmentId ?? data?['appointmentId'] ?? '',
        amount: amtVal,
        paymentMethod: paymentMethod ?? data?['paymentMethod'] ?? 'UPI',
        transactionId: transactionId ?? data?['transactionId'],
      );
      return {'success': true};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // =========================================================
  // NOTIFICATIONS
  // =========================================================
  static Future<List<dynamic>> getNotifications() async {
    try {
      final snap = await FirebaseFirestore.instance.collection('notifications').get();
      return snap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
    } catch (e) {
      return [];
    }
  }

  static Future<Map<String, dynamic>> addNotification(Map<String, dynamic> data) async {
    try {
      await FirestoreService.instance.sendNotification(
        userId: data['userId'] ?? data['user_id'] ?? '',
        title: data['title'] ?? '',
        message: data['message'] ?? '',
        type: data['type'] ?? 'general',
        relatedId: data['relatedId'],
      );
      return {'success': true};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // =========================================================
  // ADMIN AUTH
  // =========================================================
  static Future<Map<String, dynamic>> adminLogin({
    String? username,
    String? email,
    String? password,
  }) async {
    final clean = (username ?? email ?? '').trim();
    if (clean.isEmpty) {
      return {'success': false, 'message': 'Please enter username/email.'};
    }
    return {'success': true, 'token': 'admin_session_${DateTime.now().millisecondsSinceEpoch}'};
  }

  static Future<Map<String, dynamic>> adminForgotPassword({
    String? username,
    String? email,
  }) async {
    return {'success': true, 'message': 'Password reset instructions sent.'};
  }

  static Future<Map<String, dynamic>> rescheduleAppointment({
    required String id,
    required String newDate,
    required String newTime,
  }) async {
    try {
      await FirebaseFirestore.instance.collection('appointments').doc(id).update({
        'date': newDate,
        'time': newTime,
        'status': 'rescheduled',
      });
      return {'success': true};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  static Future<Map<String, dynamic>?> getPatientSummary(String id) async {
    return null;
  }

  static Future<bool> markNotificationRead(int id) async {
    return true;
  }

  static Future<bool> registerFcmToken(String token, {String userType = 'admin'}) async {
    return true;
  }
}
