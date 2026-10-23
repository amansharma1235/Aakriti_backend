import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/appointment_model.dart';

class FirestoreService {
  FirestoreService._();
  static final FirestoreService instance = FirestoreService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // =========================================================
  // USERS COLLECTION
  // =========================================================

  Future<void> createUserProfile({
    required String uid,
    required String name,
    required String email,
    required String phone,
    String role = 'patient',
  }) async {
    final patientId = 'PT${uid.substring(0, min(6, uid.length)).toUpperCase()}';
    final userRef = _db.collection('users').doc(uid);

    final docSnap = await userRef.get();
    if (!docSnap.exists) {
      await userRef.set({
        'uid': uid,
        'name': name.trim(),
        'email': email.trim().toLowerCase(),
        'phone': phone.trim(),
        'profileImage': '',
        'role': role,
        'createdAt': FieldValue.serverTimestamp(),
        'lastLogin': FieldValue.serverTimestamp(),
        'status': 'active',
        'patientId': patientId,
      });
    } else {
      await userRef.update({
        'lastLogin': FieldValue.serverTimestamp(),
        if (name.isNotEmpty) 'name': name.trim(),
        if (phone.isNotEmpty) 'phone': phone.trim(),
      });
    }
  }

  Future<void> updateLastLogin(String uid) async {
    try {
      await _db.collection('users').doc(uid).update({
        'lastLogin': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('[FirestoreService] updateLastLogin error: $e');
    }
  }

  Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    try {
      final doc = await _db.collection('users').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        return doc.data();
      }
    } catch (e) {
      debugPrint('[FirestoreService] getUserProfile error: $e');
    }
    return null;
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> streamUserProfile(String uid) {
    return _db.collection('users').doc(uid).snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getAllUsersStream() {
    return _db.collection('users').orderBy('createdAt', descending: true).snapshots();
  }

  Future<List<Map<String, dynamic>>> getAllUsers() async {
    try {
      final snap = await _db.collection('users').orderBy('createdAt', descending: true).get();
      return snap.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
    } catch (e) {
      debugPrint('[FirestoreService] getAllUsers error: $e');
      return [];
    }
  }

  // =========================================================
  // APPOINTMENTS COLLECTION
  // =========================================================

  Future<String> createAppointment(AppointmentModel appointment) async {
    final docRef = _db.collection('appointments').doc();
    final appointmentId = 'APT-${DateTime.now().year}-${(Random().nextInt(90000) + 10000)}';

    final data = {
      'appointmentId': appointmentId,
      'userId': appointment.patientId, // Firebase Auth UID
      'patientId': appointment.patientId,
      'patientName': appointment.patientName,
      'mobile': appointment.mobile,
      'age': appointment.age,
      'gender': appointment.gender,
      'testId': appointment.testId,
      'testName': appointment.testName,
      'date': appointment.date,
      'time': appointment.time,
      'status': appointment.status.name,
      'notes': appointment.notes,
      'createdAt': FieldValue.serverTimestamp(),
      'assignedDoctorId': (appointment.doctorName?.isNotEmpty == true) ? 'DOC1' : '',
      'assignedDoctorName': appointment.doctorName,
      'amount': appointment.price,
      'isForFamilyMember': appointment.isForFamilyMember,
      'familyMemberId': appointment.familyMemberId,
    };

    await docRef.set(data);

    // Send notification to user
    await sendNotification(
      userId: appointment.patientId,
      title: "Appointment Booked",
      message: "Your appointment request for ${appointment.testName} on ${appointment.date} at ${appointment.time} has been received and is awaiting confirmation.",
      type: "appointment_pending",
      relatedId: docRef.id,
    );

    return docRef.id;
  }

  Stream<List<AppointmentModel>> getUserAppointmentsStream(String userId) {
    if (userId.isEmpty) return Stream.value([]);
    return _db
        .collection('appointments')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snap) {
          final list = snap.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return AppointmentModel.fromJson(data);
          }).toList();
          list.sort((a, b) => b.id.compareTo(a.id));
          return list;
        });
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getAllAppointmentsStream() {
    return _db.collection('appointments').snapshots();
  }

  Future<void> updateAppointmentStatus({
    required String docId,
    required String userId,
    required String newStatus,
    String? assignedDoctorId,
    String? assignedDoctorName,
  }) async {
    final Map<String, dynamic> updateData = {'status': newStatus};
    if (assignedDoctorId != null) updateData['assignedDoctorId'] = assignedDoctorId;
    if (assignedDoctorName != null) updateData['assignedDoctorName'] = assignedDoctorName;

    await _db.collection('appointments').doc(docId).update(updateData);

    // Generate appropriate notification
    String title = "Appointment Update";
    String message = "Your appointment status has been updated to $newStatus.";
    String type = "general";

    switch (newStatus) {
      case 'confirmed':
        title = "Appointment Confirmed";
        message = "Your appointment has been confirmed. Please reach 10 mins before time.";
        type = "appointment_confirmed";
        break;
      case 'checked_in':
        title = "Checked-In";
        message = "You have been checked in successfully.";
        type = "appointment_checked_in";
        break;
      case 'in_progress':
        title = "Test In Progress";
        message = "Your diagnostic test is currently in progress.";
        type = "test_started";
        break;
      case 'completed':
        title = "Test Completed";
        message = "Your diagnostic test has been completed. Report generation in progress.";
        type = "test_completed";
        break;
      case 'cancelled':
        title = "Appointment Cancelled";
        message = "Your appointment has been cancelled.";
        type = "appointment_cancelled";
        break;
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
  // REPORTS COLLECTION
  // =========================================================

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

    // Update appointment status to completed if applicable
    if (appointmentId.isNotEmpty) {
      try {
        final apptSnap = await _db.collection('appointments').doc(appointmentId).get();
        if (apptSnap.exists) {
          await _db.collection('appointments').doc(appointmentId).update({
            'status': 'completed',
          });
        }
      } catch (_) {}
    }

    // Send notification
    await sendNotification(
      userId: userId,
      title: "Report Ready",
      message: "Your diagnostic report for $testName is now available to view and download.",
      type: "report_uploaded",
      relatedId: docRef.id,
    );

    return docRef.id;
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getUserReportsStream(String userId) {
    if (userId.isEmpty) return const Stream.empty();
    return _db.collection('reports').where('userId', isEqualTo: userId).snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getAllReportsStream() {
    return _db.collection('reports').snapshots();
  }

  // =========================================================
  // BILLS & PAYMENTS COLLECTIONS
  // =========================================================

  Future<String> generateBill({
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

    await sendNotification(
      userId: userId,
      title: "Bill Generated",
      message: "A bill of ₹${finalAmount.toStringAsFixed(0)} has been generated for $testName.",
      type: "bill_generated",
      relatedId: docRef.id,
    );

    return docRef.id;
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getUserBillsStream(String userId) {
    if (userId.isEmpty) return const Stream.empty();
    return _db.collection('bills').where('userId', isEqualTo: userId).snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getAllBillsStream() {
    return _db.collection('bills').snapshots();
  }

  Future<String> recordPayment({
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

    await sendNotification(
      userId: userId,
      title: "Payment Received",
      message: "Payment of ₹${amount.toStringAsFixed(0)} (Txn ID: $txId) was received successfully.",
      type: "payment_success",
      relatedId: docRef.id,
    );

    return docRef.id;
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getUserPaymentsStream(String userId) {
    if (userId.isEmpty) return const Stream.empty();
    return _db.collection('payments').where('userId', isEqualTo: userId).snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getAllPaymentsStream() {
    return _db.collection('payments').snapshots();
  }

  // =========================================================
  // NOTIFICATIONS COLLECTION
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
      debugPrint('[FirestoreService] sendNotification error: $e');
    }
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getUserNotificationsStream(String userId) {
    if (userId.isEmpty) return const Stream.empty();
    return _db.collection('notifications').where('userId', isEqualTo: userId).snapshots();
  }

  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      await _db.collection('notifications').doc(notificationId).update({'read': true});
    } catch (e) {
      debugPrint('[FirestoreService] markNotificationAsRead error: $e');
    }
  }

  // =========================================================
  // FAMILY MEMBERS COLLECTION
  // =========================================================

  Future<String> addFamilyMember({
    required String userId,
    required String name,
    required String relationship,
    required String dob,
    required String gender,
    String? phone,
    String? notes,
  }) async {
    final docRef = _db.collection('family_members').doc();
    await docRef.set({
      'id': docRef.id,
      'userId': userId,
      'name': name.trim(),
      'relationship': relationship,
      'dob': dob,
      'gender': gender,
      'phone': phone ?? '',
      'notes': notes ?? '',
      'createdAt': FieldValue.serverTimestamp(),
    });
    return docRef.id;
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getUserFamilyMembersStream(String userId) {
    if (userId.isEmpty) return const Stream.empty();
    return _db.collection('family_members').where('userId', isEqualTo: userId).snapshots();
  }

  Future<void> deleteFamilyMember(String memberId) async {
    await _db.collection('family_members').doc(memberId).delete();
  }

  // =========================================================
  // DOCTORS COLLECTION
  // =========================================================

  Stream<QuerySnapshot<Map<String, dynamic>>> getActiveDoctorsStream() {
    return _db.collection('doctors').where('status', isEqualTo: 'active').snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getAllDoctorsStream() {
    return _db.collection('doctors').snapshots();
  }

  Future<void> addDoctor(Map<String, dynamic> doctorData) async {
    final docRef = _db.collection('doctors').doc();
    await docRef.set({
      'doctorId': docRef.id,
      ...doctorData,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateDoctor(String doctorId, Map<String, dynamic> doctorData) async {
    await _db.collection('doctors').doc(doctorId).update(doctorData);
  }

  Future<void> toggleDoctorStatus(String doctorId, String currentStatus) async {
    final newStatus = currentStatus == 'active' ? 'inactive' : 'active';
    await _db.collection('doctors').doc(doctorId).update({'status': newStatus});
  }

  // Seed default doctors if collection is empty
  Future<void> seedInitialDoctorsIfEmpty() async {
    final snap = await _db.collection('doctors').limit(1).get();
    if (snap.docs.isEmpty) {
      final initialDoctors = [
        {
          'name': 'Dr. Ananya Sharma',
          'specialization': 'Senior Radiologist & Sonologist',
          'qualification': 'MD (Radiodiagnosis), MBBS',
          'experience': '14+ Years',
          'registrationNumber': 'MCI-45892',
          'department': 'Ultrasound & Color Doppler',
          'workingDays': ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'],
          'workingHours': '09:00 AM - 05:00 PM',
          'consultationFee': 800.0,
          'status': 'active',
          'profileImage': '',
          'rating': 4.9,
          'totalReviews': 312,
        },
        {
          'name': 'Dr. Vikram Malhotra',
          'specialization': 'Consultant Radiologist',
          'qualification': 'DNB (Radiology), MBBS',
          'experience': '10+ Years',
          'registrationNumber': 'MCI-52104',
          'department': 'Fetal Medicine & Doppler',
          'workingDays': ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'],
          'workingHours': '10:00 AM - 06:00 PM',
          'consultationFee': 750.0,
          'status': 'active',
          'profileImage': '',
          'rating': 4.8,
          'totalReviews': 245,
        },
      ];

      for (final doc in initialDoctors) {
        await addDoctor(doc);
      }
    }
  }

  // =========================================================
  // SERVICES / DIAGNOSTIC TESTS COLLECTION
  // =========================================================

  Stream<QuerySnapshot<Map<String, dynamic>>> getActiveServicesStream() {
    return _db.collection('services').where('status', isEqualTo: 'active').snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getAllServicesStream() {
    return _db.collection('services').snapshots();
  }

  Future<void> addService(Map<String, dynamic> serviceData) async {
    final docRef = _db.collection('services').doc();
    await docRef.set({
      'serviceId': docRef.id,
      ...serviceData,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateService(String serviceId, Map<String, dynamic> serviceData) async {
    await _db.collection('services').doc(serviceId).update(serviceData);
  }

  Future<void> toggleServiceStatus(String serviceId, String currentStatus) async {
    final newStatus = currentStatus == 'active' ? 'inactive' : 'active';
    await _db.collection('services').doc(serviceId).update({'status': newStatus});
  }
}
