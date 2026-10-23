import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class FirestoreService {
  FirestoreService._();
  static final FirestoreService instance = FirestoreService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // =========================================================
  // DASHBOARD CALCULATIONS
  // =========================================================

  Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      final usersSnap = await _db.collection('users').get();
      final apptsSnap = await _db.collection('appointments').get();
      final reportsSnap = await _db.collection('reports').get();
      final billsSnap = await _db.collection('bills').get();
      final paymentsSnap = await _db.collection('payments').get();

      final totalUsers = usersSnap.docs.length;
      final totalAppts = apptsSnap.docs.length;

      int todayAppts = 0;
      int pendingAppts = 0;
      int confirmedAppts = 0;
      int checkedInAppts = 0;
      int inProgressAppts = 0;
      int completedAppts = 0;
      int cancelledAppts = 0;

      final todayStr = DateTime.now().toIso8601String().substring(0, 10);

      for (final doc in apptsSnap.docs) {
        final data = doc.data();
        final status = (data['status'] ?? '').toString().toLowerCase();
        final date = (data['date'] ?? '').toString();

        if (date == todayStr) {
          todayAppts++;
        }

        if (status == 'pending') {
          pendingAppts++;
        } else if (status == 'confirmed') {
          confirmedAppts++;
        } else if (status == 'checked_in') {
          checkedInAppts++;
        } else if (status == 'in_progress') {
          inProgressAppts++;
        } else if (status == 'completed') {
          completedAppts++;
        } else if (status == 'cancelled') {
          cancelledAppts++;
        }
      }

      int totalReports = reportsSnap.docs.length;
      int pendingReports = apptsSnap.docs.where((d) => (d.data()['status'] ?? '') == 'completed').length - totalReports;
      if (pendingReports < 0) pendingReports = 0;

      double totalRevenue = 0.0;
      for (final doc in paymentsSnap.docs) {
        final amt = (doc.data()['amount'] ?? 0.0);
        if (amt is num) totalRevenue += amt.toDouble();
      }

      return {
        'total_patients': totalUsers,
        'total_appointments': totalAppts,
        'today_appointments': todayAppts,
        'pending_appointments': pendingAppts,
        'confirmed_appointments': confirmedAppts,
        'checked_in_appointments': checkedInAppts,
        'in_progress_appointments': inProgressAppts,
        'completed_appointments': completedAppts,
        'cancelled_appointments': cancelledAppts,
        'total_reports': totalReports,
        'pending_reports': pendingReports,
        'total_revenue': totalRevenue,
        'total_bills': billsSnap.docs.length,
        'total_payments': paymentsSnap.docs.length,
      };
    } catch (e) {
      debugPrint('[Admin FirestoreService] getDashboardStats error: $e');
      return {
        'total_patients': 0,
        'total_appointments': 0,
        'today_appointments': 0,
        'pending_appointments': 0,
        'confirmed_appointments': 0,
        'checked_in_appointments': 0,
        'in_progress_appointments': 0,
        'completed_appointments': 0,
        'cancelled_appointments': 0,
        'total_reports': 0,
        'pending_reports': 0,
        'total_revenue': 0.0,
        'total_bills': 0,
        'total_payments': 0,
      };
    }
  }

  // =========================================================
  // USERS / PATIENTS
  // =========================================================

  Stream<QuerySnapshot<Map<String, dynamic>>> getUsersStream() {
    return _db.collection('users').snapshots();
  }

  Future<List<Map<String, dynamic>>> getUsersList() async {
    final snap = await _db.collection('users').get();
    return snap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
  }

  // =========================================================
  // APPOINTMENTS
  // =========================================================

  Stream<QuerySnapshot<Map<String, dynamic>>> getAppointmentsStream() {
    return _db.collection('appointments').snapshots();
  }

  Future<void> updateAppointmentStatus({
    required String docId,
    required String userId,
    required String status,
    String? assignedDoctorId,
    String? assignedDoctorName,
  }) async {
    final Map<String, dynamic> data = {'status': status};
    if (assignedDoctorId != null) data['assignedDoctorId'] = assignedDoctorId;
    if (assignedDoctorName != null) data['assignedDoctorName'] = assignedDoctorName;

    await _db.collection('appointments').doc(docId).update(data);

    // Notify user
    String title = "Appointment Status Changed";
    String message = "Your appointment status was updated to $status.";
    String type = "general";

    if (status == 'confirmed') {
      title = "Appointment Confirmed";
      message = "Your appointment has been confirmed by our staff.";
      type = "appointment_confirmed";
    } else if (status == 'checked_in') {
      title = "Checked In";
      message = "You have been checked in successfully.";
      type = "appointment_checked_in";
    } else if (status == 'in_progress') {
      title = "Test In Progress";
      message = "Your diagnostic scan/test is now in progress.";
      type = "test_started";
    } else if (status == 'completed') {
      title = "Test Completed";
      message = "Your test is complete. The report will be uploaded shortly.";
      type = "test_completed";
    } else if (status == 'cancelled') {
      title = "Appointment Cancelled";
      message = "Your appointment has been cancelled by the center.";
      type = "appointment_cancelled";
    }

    if (userId.isNotEmpty) {
      await sendNotification(
        userId: userId,
        title: title,
        message: message,
        type: type,
        relatedId: docId,
      );
    }
  }

  // =========================================================
  // REPORTS
  // =========================================================

  Stream<QuerySnapshot<Map<String, dynamic>>> getReportsStream() {
    return _db.collection('reports').snapshots();
  }

  Future<String> uploadReport({
    required String userId,
    required String patientId,
    required String patientName,
    required String appointmentId,
    required String testName,
    required String reportUrl,
    String? reportingDoctorId,
    String? reportingDoctorName,
    String? fileName,
    String? fileSize,
  }) async {
    final docRef = _db.collection('reports').doc();
    final reportId = 'REP-${DateTime.now().year}-${(Random().nextInt(90000) + 10000)}';

    await docRef.set({
      'reportId': reportId,
      'userId': userId,
      'patientId': patientId,
      'patientName': patientName,
      'appointmentId': appointmentId,
      'testName': testName,
      'reportUrl': reportUrl,
      'reportStatus': 'available',
      'reportingDoctorId': reportingDoctorId ?? '',
      'reportingDoctorName': reportingDoctorName ?? 'Dr. Ananya Sharma',
      'uploadedAt': FieldValue.serverTimestamp(),
      'fileName': fileName ?? '$testName Report.pdf',
      'fileSize': fileSize ?? '1.2 MB',
    });

    if (appointmentId.isNotEmpty) {
      try {
        await _db.collection('appointments').doc(appointmentId).update({'status': 'completed'});
      } catch (_) {}
    }

    if (userId.isNotEmpty) {
      await sendNotification(
        userId: userId,
        title: "Report Uploaded",
        message: "Your diagnostic report for $testName is now available in My Reports.",
        type: "report_uploaded",
        relatedId: docRef.id,
      );
    }

    return docRef.id;
  }

  // =========================================================
  // BILLS & PAYMENTS
  // =========================================================

  Stream<QuerySnapshot<Map<String, dynamic>>> getBillsStream() {
    return _db.collection('bills').snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getPaymentsStream() {
    return _db.collection('payments').snapshots();
  }

  Future<String> createBill({
    required String userId,
    required String appointmentId,
    required String patientName,
    required String testName,
    required double amount,
    double discount = 0.0,
  }) async {
    final docRef = _db.collection('bills').doc();
    final billId = 'BILL-${DateTime.now().year}-${(Random().nextInt(90000) + 10000)}';
    final finalAmount = amount - discount;

    await docRef.set({
      'billId': billId,
      'userId': userId,
      'appointmentId': appointmentId,
      'patientName': patientName,
      'testName': testName,
      'amount': amount,
      'discount': discount,
      'finalAmount': finalAmount,
      'paymentStatus': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });

    if (userId.isNotEmpty) {
      await sendNotification(
        userId: userId,
        title: "New Bill Generated",
        message: "A bill of ₹${finalAmount.toStringAsFixed(0)} has been issued for $testName.",
        type: "bill_generated",
        relatedId: docRef.id,
      );
    }

    return docRef.id;
  }

  Future<void> recordPayment({
    required String userId,
    required String billId,
    required String appointmentId,
    required double amount,
    required String paymentMethod,
    String? transactionId,
  }) async {
    final docRef = _db.collection('payments').doc();
    final txId = transactionId ?? 'TXN${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}';

    await docRef.set({
      'paymentId': docRef.id,
      'userId': userId,
      'billId': billId,
      'appointmentId': appointmentId,
      'amount': amount,
      'paymentMethod': paymentMethod,
      'transactionId': txId,
      'paymentStatus': 'success',
      'createdAt': FieldValue.serverTimestamp(),
    });

    if (billId.isNotEmpty) {
      try {
        await _db.collection('bills').doc(billId).update({'paymentStatus': 'paid'});
      } catch (_) {}
    }

    if (userId.isNotEmpty) {
      await sendNotification(
        userId: userId,
        title: "Payment Received",
        message: "Payment of ₹${amount.toStringAsFixed(0)} (Txn ID: $txId) confirmed.",
        type: "payment_success",
        relatedId: docRef.id,
      );
    }
  }

  // =========================================================
  // DOCTORS
  // =========================================================

  Stream<QuerySnapshot<Map<String, dynamic>>> getDoctorsStream() {
    return _db.collection('doctors').snapshots();
  }

  Future<void> addDoctor(Map<String, dynamic> data) async {
    final docRef = _db.collection('doctors').doc();
    await docRef.set({
      'doctorId': docRef.id,
      ...data,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateDoctor(String doctorId, Map<String, dynamic> data) async {
    await _db.collection('doctors').doc(doctorId).update(data);
  }

  Future<void> seedInitialDoctorsIfEmpty() async {
    try {
      final snap = await _db.collection('doctors').get();
      if (snap.docs.isEmpty) {
        final initialDoctors = [
          {
            'doctorId': 'DOC101',
            'name': 'Dr. Rajesh Sharma',
            'doctor_name': 'Dr. Rajesh Sharma',
            'specialization': 'Senior Radiologist',
            'qualification': 'MD (Radiodiagnosis), MBBS',
            'experience': '15+ Years',
            'registrationNumber': 'DMC/2008/4589',
            'department': 'Ultrasound & Color Doppler',
            'consultationFee': 800.0,
            'status': 'active',
            'workingDays': 'Mon - Sat',
            'workingHours': '09:00 AM - 05:00 PM',
          },
          {
            'doctorId': 'DOC102',
            'name': 'Dr. Neha Verma',
            'doctor_name': 'Dr. Neha Verma',
            'specialization': 'Fetal Medicine Specialist',
            'qualification': 'DNB (Radiology), Fellowship in Fetal Medicine',
            'experience': '10+ Years',
            'registrationNumber': 'DMC/2012/9812',
            'department': 'Obstetric Scan & TIFFA',
            'consultationFee': 1200.0,
            'status': 'active',
            'workingDays': 'Mon - Sat',
            'workingHours': '10:00 AM - 04:00 PM',
          },
        ];
        for (final doc in initialDoctors) {
          await _db.collection('doctors').doc(doc['doctorId'].toString()).set({
            ...doc,
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
      }
    } catch (e) {
      debugPrint('[Admin FirestoreService] seedInitialDoctorsIfEmpty error: $e');
    }
  }

  Future<void> toggleDoctorStatus(String doctorId, String currentStatus) async {
    final newStatus = currentStatus == 'active' ? 'inactive' : 'active';
    await _db.collection('doctors').doc(doctorId).update({'status': newStatus});
  }

  // =========================================================
  // SERVICES
  // =========================================================

  Stream<QuerySnapshot<Map<String, dynamic>>> getServicesStream() {
    return _db.collection('services').snapshots();
  }

  Future<void> addService(Map<String, dynamic> data) async {
    final docRef = _db.collection('services').doc();
    await docRef.set({
      'serviceId': docRef.id,
      ...data,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateService(String serviceId, Map<String, dynamic> data) async {
    await _db.collection('services').doc(serviceId).update(data);
  }

  Future<void> toggleServiceStatus(String serviceId, String currentStatus) async {
    final newStatus = currentStatus == 'active' ? 'inactive' : 'active';
    await _db.collection('services').doc(serviceId).update({'status': newStatus});
  }

  // =========================================================
  // NOTIFICATIONS
  // =========================================================

  Future<void> sendNotification({
    required String userId,
    required String title,
    required String message,
    required String type,
    String? relatedId,
  }) async {
    if (userId.isEmpty) return;
    try {
      await _db.collection('notifications').add({
        'userId': userId,
        'title': title,
        'message': message,
        'type': type,
        'relatedId': relatedId ?? '',
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('[Admin FirestoreService] sendNotification error: $e');
    }
  }
}
