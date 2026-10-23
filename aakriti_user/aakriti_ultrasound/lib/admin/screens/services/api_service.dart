import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static final List<String> candidateUrls = [
    'https://aakriti-backend-x30w.onrender.com',
    'http://127.0.0.1:8000',
    'http://10.178.238.51:8000',
    'http://10.0.2.2:8000',
  ];

  static String baseUrl = 'https://aakriti-backend-x30w.onrender.com';

  static final ValueNotifier<bool> isServerOnline = ValueNotifier<bool>(false);
  static final ValueNotifier<bool> isDbConnected = ValueNotifier<bool>(false);
  static final ValueNotifier<Map<String, dynamic>> healthInfo = ValueNotifier<Map<String, dynamic>>({});

  static const String _adminTokenKey = 'aakriti_admin_bearer_token';
  static String? _cachedAdminToken;

  // ================= ADMIN TOKEN MANAGEMENT =================

  static Future<void> setAdminToken(String token) async {
    _cachedAdminToken = token.trim();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_adminTokenKey, _cachedAdminToken!);
    } catch (_) {}
  }

  static Future<String?> getAdminToken() async {
    if (_cachedAdminToken != null && _cachedAdminToken!.isNotEmpty) {
      return _cachedAdminToken;
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      _cachedAdminToken = prefs.getString(_adminTokenKey);
      return _cachedAdminToken;
    } catch (_) {}
    return null;
  }

  static Future<void> clearAdminToken() async {
    _cachedAdminToken = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_adminTokenKey);
    } catch (_) {}
  }

  static Future<Map<String, String>> getAdminHeaders([Map<String, String>? extra]) async {
    final token = await getAdminToken();
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    if (extra != null) {
      headers.addAll(extra);
    }
    return headers;
  }

  static DateTime? _lastHealthCheckTime;
  static bool _lastHealthStatus = false;

  // Health check: queries real-time status of backend, database, and firebase (45-sec cache)
  static Future<bool> checkHealth({bool force = false}) async {
    if (!force && _lastHealthCheckTime != null && DateTime.now().difference(_lastHealthCheckTime!) < const Duration(seconds: 45)) {
      return _lastHealthStatus;
    }

    // 1. Try current baseUrl
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/api/health'))
          .timeout(const Duration(seconds: 3));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        healthInfo.value = data;
        isServerOnline.value = true;
        isDbConnected.value = data['database'] == 'connected';
        _lastHealthCheckTime = DateTime.now();
        _lastHealthStatus = true;
        return true;
      }
    } catch (_) {}

    // 2. Probe candidates to find reachable backend
    for (final candidate in candidateUrls) {
      if (candidate == baseUrl) continue;
      try {
        final response = await http
            .get(Uri.parse('$candidate/api/health'))
            .timeout(const Duration(seconds: 2));
        if (response.statusCode == 200) {
          baseUrl = candidate;
          final data = jsonDecode(response.body);
          healthInfo.value = data;
          isServerOnline.value = true;
          isDbConnected.value = data['database'] == 'connected';
          _lastHealthCheckTime = DateTime.now();
          _lastHealthStatus = true;
          debugPrint('[ApiService Admin] Switched baseUrl to $baseUrl');
          return true;
        }
      } catch (_) {}
    }

    isServerOnline.value = false;
    isDbConnected.value = false;
    _lastHealthCheckTime = DateTime.now();
    _lastHealthStatus = false;
    return false;
  }


  // =========================================================
  // DASHBOARD STATS (STRICTLY FROM MYSQL)
  // =========================================================
  static Future<Map<String, dynamic>> getDashboardStats() async {
    await checkHealth();
    try {
      final headers = await getAdminHeaders();
      final response = await http
          .get(Uri.parse('$baseUrl/dashboard/stats'), headers: headers)
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        isServerOnline.value = true;
        final data = jsonDecode(response.body);
        return data['data'] is Map<String, dynamic> ? data['data'] : data;
      } else {
        debugPrint('[ApiService Admin] Dashboard returned status ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('[ApiService Admin] getDashboardStats error: $e');
      isServerOnline.value = false;
    }

    return {
      'total_patients': 0,
      'total_appointments': 0,
      'pending_reports': 0,
      'total_revenue': 0.0,
    };
  }

  // =========================================================
  // PATIENTS
  // =========================================================
  static Future<List<dynamic>> getPatients() async {
    await checkHealth();
    try {
      final headers = await getAdminHeaders();
      final response = await http
          .get(Uri.parse('$baseUrl/patients'), headers: headers)
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        isServerOnline.value = true;
        final data = jsonDecode(response.body);
        return data['patients'] ?? [];
      } else {
        debugPrint('[ApiService Admin] getPatients status: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('[ApiService Admin] getPatients error: $e');
      isServerOnline.value = false;
    }
    return [];
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
    await checkHealth();
    try {
      final uri = Uri.parse('$baseUrl/patients').replace(
        queryParameters: {
          'patient_id': patientId,
          'full_name': fullName,
          'mobile': mobile,
          if (age != null && age.isNotEmpty) 'age': age,
          if (gender != null && gender.isNotEmpty) 'gender': gender,
          if (bloodGroup != null && bloodGroup.isNotEmpty)
            'blood_group': bloodGroup,
          if (email != null && email.isNotEmpty) 'email': email,
          if (address != null && address.isNotEmpty) 'address': address,
        },
      );

      final headers = await getAdminHeaders();
      final response = await http.post(uri, headers: headers).timeout(const Duration(seconds: 6));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        isServerOnline.value = true;
        return jsonDecode(response.body);
      }
    } catch (e) {
      debugPrint('[ApiService Admin] addPatient error: $e');
      isServerOnline.value = false;
    }

    return {
      'success': false,
      'message': 'Failed to add patient to database. Please check connection.',
      'patient_id': patientId,
    };
  }

  static Future<Map<String, dynamic>> deletePatient({
    required dynamic id,
  }) async {
    await checkHealth();
    try {
      final headers = await getAdminHeaders();
      final response = await http
          .delete(Uri.parse('$baseUrl/patients/$id'), headers: headers)
          .timeout(const Duration(seconds: 6));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        isServerOnline.value = true;
        return jsonDecode(response.body);
      }
    } catch (e) {
      debugPrint('[ApiService Admin] deletePatient error: $e');
      isServerOnline.value = false;
    }

    return {'success': false, 'message': 'Failed to delete patient from database'};
  }

  // =========================================================
  // APPOINTMENTS
  // =========================================================
  static Future<List<dynamic>> getAppointments() async {
    await checkHealth();
    try {
      final headers = await getAdminHeaders();
      final response = await http
          .get(Uri.parse('$baseUrl/appointments'), headers: headers)
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        isServerOnline.value = true;
        final data = jsonDecode(response.body);
        return data['appointments'] ?? [];
      } else {
        debugPrint('[ApiService Admin] getAppointments status: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('[ApiService Admin] getAppointments error: $e');
      isServerOnline.value = false;
    }
    return [];
  }

  static Future<Map<String, dynamic>> addAppointment({
    required String appointmentId,
    required String patientId,
    required String patientName,
    required String serviceName,
    required String appointmentDate,
    String? mobile,
    String? appointmentTime,
    String? doctorName,
    String? note,
    String status = 'Pending',
  }) async {
    await checkHealth();
    try {
      final uri = Uri.parse('$baseUrl/appointments').replace(
        queryParameters: {
          'appointment_id': appointmentId,
          'patient_id': patientId,
          'patient_name': patientName,
          'service_name': serviceName,
          'appointment_date': appointmentDate,
          if (mobile != null && mobile.isNotEmpty) 'mobile': mobile,
          if (appointmentTime != null && appointmentTime.isNotEmpty)
            'appointment_time': appointmentTime,
          if (doctorName != null && doctorName.isNotEmpty)
            'doctor_name': doctorName,
          if (note != null && note.isNotEmpty) 'note': note,
          'status': status,
        },
      );

      final headers = await getAdminHeaders();
      final response = await http.post(uri, headers: headers).timeout(const Duration(seconds: 6));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        isServerOnline.value = true;
        return jsonDecode(response.body);
      }
    } catch (e) {
      debugPrint('[ApiService Admin] addAppointment error: $e');
      isServerOnline.value = false;
    }

    return {
      'success': false,
      'message': 'Failed to schedule appointment in database',
      'appointment_id': appointmentId,
    };
  }

  static Future<Map<String, dynamic>> updateAppointment({
    required int id,
    String? patientId,
    String? patientName,
    String? mobile,
    String? serviceName,
    String? appointmentDate,
    String? appointmentTime,
    String? doctorName,
    String? note,
    String? status,
  }) async {
    await checkHealth();
    try {
      final params = <String, String>{};
      if (patientId != null) params['patient_id'] = patientId;
      if (patientName != null) params['patient_name'] = patientName;
      if (mobile != null) params['mobile'] = mobile;
      if (serviceName != null) params['service_name'] = serviceName;
      if (appointmentDate != null) params['appointment_date'] = appointmentDate;
      if (appointmentTime != null) params['appointment_time'] = appointmentTime;
      if (doctorName != null) params['doctor_name'] = doctorName;
      if (note != null) params['note'] = note;
      if (status != null) params['status'] = status;

      final uri = Uri.parse('$baseUrl/appointments/$id')
          .replace(queryParameters: params);

      final headers = await getAdminHeaders();
      final response = await http.put(uri, headers: headers).timeout(const Duration(seconds: 6));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        isServerOnline.value = true;
        return jsonDecode(response.body);
      }
    } catch (e) {
      debugPrint('[ApiService Admin] updateAppointment error: $e');
      isServerOnline.value = false;
    }

    return {'success': false, 'message': 'Failed to update appointment in database'};
  }

  static Future<Map<String, dynamic>> deleteAppointment({
    required dynamic id,
  }) async {
    await checkHealth();
    try {
      final headers = await getAdminHeaders();
      final response = await http
          .delete(Uri.parse('$baseUrl/appointments/$id'), headers: headers)
          .timeout(const Duration(seconds: 6));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        isServerOnline.value = true;
        return jsonDecode(response.body);
      }
    } catch (e) {
      debugPrint('[ApiService Admin] deleteAppointment error: $e');
      isServerOnline.value = false;
    }

    return {'success': false, 'message': 'Failed to delete appointment from database'};
  }

  // =========================================================
  // DOCTORS
  // =========================================================
  static Future<List<dynamic>> getDoctors() async {
    await checkHealth();
    try {
      final headers = await getAdminHeaders();
      final response = await http
          .get(Uri.parse('$baseUrl/doctors'), headers: headers)
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        isServerOnline.value = true;
        final data = jsonDecode(response.body);
        return data['doctors'] ?? [];
      }
    } catch (e) {
      debugPrint('[ApiService Admin] getDoctors error: $e');
      isServerOnline.value = false;
    }
    return [];
  }

  static Future<Map<String, dynamic>> addDoctor({
    required String doctorId,
    required String doctorName,
    required String specialization,
    required String mobile,
    required String experience,
    String status = 'Active',
  }) async {
    await checkHealth();
    try {
      final uri = Uri.parse('$baseUrl/doctors').replace(
        queryParameters: {
          'doctor_id': doctorId,
          'doctor_name': doctorName,
          'specialization': specialization,
          'mobile': mobile,
          'experience': experience,
          'status': status,
        },
      );
      final headers = await getAdminHeaders();
      final response = await http.post(uri, headers: headers).timeout(const Duration(seconds: 6));
      if (response.statusCode >= 200 && response.statusCode < 300) {
        isServerOnline.value = true;
        return jsonDecode(response.body);
      }
    } catch (e) {
      debugPrint('[ApiService Admin] addDoctor error: $e');
      isServerOnline.value = false;
    }
    return {'success': false, 'message': 'Failed to add doctor to database'};
  }

  static Future<Map<String, dynamic>> updateDoctor({
    required String doctorId,
    required String doctorName,
    required String specialization,
    required String mobile,
    required String experience,
    String status = 'Active',
  }) async {
    await checkHealth();
    try {
      final headers = await getAdminHeaders();
      final uri = Uri.parse('$baseUrl/doctors/$doctorId').replace(
        queryParameters: {
          'doctor_name': doctorName,
          'specialization': specialization,
          'mobile': mobile,
          'experience': experience,
          'status': status,
        },
      );
      final body = jsonEncode({
        'doctor_name': doctorName,
        'specialization': specialization,
        'mobile': mobile,
        'experience': experience,
        'status': status,
      });
      final response = await http.put(uri, headers: headers, body: body).timeout(const Duration(seconds: 6));
      if (response.statusCode >= 200 && response.statusCode < 300) {
        isServerOnline.value = true;
        return jsonDecode(response.body);
      }
    } catch (e) {
      debugPrint('[ApiService Admin] updateDoctor error: $e');
    }
    return {'success': false, 'message': 'Failed to update doctor in database'};
  }

  static Future<bool> deleteDoctor({required String doctorId}) async {
    await checkHealth();
    try {
      final headers = await getAdminHeaders();
      final response = await http
          .delete(Uri.parse('$baseUrl/doctors/$doctorId'), headers: headers)
          .timeout(const Duration(seconds: 6));
      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (e) {
      debugPrint('[ApiService Admin] deleteDoctor error: $e');
      return false;
    }
  }

  // =========================================================
  // SERVICES
  // =========================================================
  static Future<List<dynamic>> getServices() async {
    await checkHealth();
    try {
      final headers = await getAdminHeaders();
      final response = await http
          .get(Uri.parse('$baseUrl/services'), headers: headers)
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        isServerOnline.value = true;
        final data = jsonDecode(response.body);
        return data['services'] ?? [];
      }
    } catch (e) {
      debugPrint('[ApiService Admin] getServices error: $e');
      isServerOnline.value = false;
    }
    return [];
  }

  static Future<Map<String, dynamic>> addService({
    required String serviceId,
    required String serviceName,
    required String category,
    required double price,
    required String duration,
    String description = '',
    String status = 'Active',
  }) async {
    await checkHealth();
    try {
      final headers = await getAdminHeaders();
      final response = await http
          .post(
            Uri.parse('$baseUrl/services'),
            headers: headers,
            body: jsonEncode({
              'service_id': serviceId,
              'service_name': serviceName,
              'category': category,
              'price': price,
              'duration': duration,
              'description': description,
              'status': status,
            }),
          )
          .timeout(const Duration(seconds: 6));
      if (response.statusCode >= 200 && response.statusCode < 300) {
        isServerOnline.value = true;
        return jsonDecode(response.body);
      }
    } catch (e) {
      debugPrint('[ApiService Admin] addService error: $e');
      isServerOnline.value = false;
    }
    return {'success': false, 'message': 'Failed to add service to database'};
  }

  static Future<Map<String, dynamic>> updateService({
    required String serviceId,
    required String serviceName,
    required String category,
    required double price,
    required String duration,
    String description = '',
    String status = 'Active',
  }) async {
    await checkHealth();
    try {
      final headers = await getAdminHeaders();
      final response = await http
          .put(
            Uri.parse('$baseUrl/services/$serviceId'),
            headers: headers,
            body: jsonEncode({
              'service_name': serviceName,
              'category': category,
              'price': price,
              'duration': duration,
              'description': description,
              'status': status,
            }),
          )
          .timeout(const Duration(seconds: 6));
      if (response.statusCode >= 200 && response.statusCode < 300) {
        isServerOnline.value = true;
        return jsonDecode(response.body);
      }
    } catch (e) {
      debugPrint('[ApiService Admin] updateService error: $e');
      isServerOnline.value = false;
    }
    return {'success': false, 'message': 'Failed to update service in database'};
  }

  static Future<Map<String, dynamic>> deleteService({
    required dynamic id,
  }) async {
    await checkHealth();
    try {
      final headers = await getAdminHeaders();
      final response = await http
          .delete(Uri.parse('$baseUrl/services/$id'), headers: headers)
          .timeout(const Duration(seconds: 6));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        isServerOnline.value = true;
        return jsonDecode(response.body);
      }
    } catch (e) {
      debugPrint('[ApiService Admin] deleteService error: $e');
      isServerOnline.value = false;
    }
    return {'success': false, 'message': 'Failed to delete service from database'};
  }

  // =========================================================
  // REPORTS
  // =========================================================
  static Future<List<dynamic>> getReports() async {
    await checkHealth();
    try {
      final headers = await getAdminHeaders();
      final response = await http
          .get(Uri.parse('$baseUrl/reports'), headers: headers)
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        isServerOnline.value = true;
        final data = jsonDecode(response.body);
        return data['reports'] ?? [];
      }
    } catch (e) {
      debugPrint('[ApiService Admin] getReports error: $e');
      isServerOnline.value = false;
    }
    return [];
  }

  static Future<Map<String, dynamic>> addReport({
    required String reportId,
    required String patientId,
    required String patientName,
    required String reportTitle,
    required String reportType,
    required String reportDate,
    String fileName = '',
    String filePath = '',
    String status = 'Ready',
  }) async {
    await checkHealth();
    try {
      final uri = Uri.parse('$baseUrl/reports').replace(
        queryParameters: {
          'report_id': reportId,
          'patient_id': patientId,
          'patient_name': patientName,
          'report_title': reportTitle,
          'report_type': reportType,
          'report_date': reportDate,
          'file_name': fileName,
          'file_path': filePath,
          'status': status,
        },
      );
      final headers = await getAdminHeaders();
      final response = await http.post(uri, headers: headers).timeout(const Duration(seconds: 6));
      if (response.statusCode >= 200 && response.statusCode < 300) {
        isServerOnline.value = true;
        return jsonDecode(response.body);
      }
    } catch (e) {
      debugPrint('[ApiService Admin] addReport error: $e');
      isServerOnline.value = false;
    }
    return {'success': false, 'message': 'Failed to upload report to database'};
  }

  static Future<Map<String, dynamic>> deleteReport({
    required dynamic id,
  }) async {
    await checkHealth();
    try {
      final headers = await getAdminHeaders();
      final response = await http
          .delete(Uri.parse('$baseUrl/reports/$id'), headers: headers)
          .timeout(const Duration(seconds: 6));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        isServerOnline.value = true;
        return jsonDecode(response.body);
      }
    } catch (e) {
      debugPrint('[ApiService Admin] deleteReport error: $e');
      isServerOnline.value = false;
    }
    return {'success': false, 'message': 'Failed to delete report from database'};
  }

  // =========================================================
  // PAYMENTS
  // =========================================================
  static Future<List<dynamic>> getPayments() async {
    await checkHealth();
    try {
      final headers = await getAdminHeaders();
      final response = await http
          .get(Uri.parse('$baseUrl/payments'), headers: headers)
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        isServerOnline.value = true;
        final data = jsonDecode(response.body);
        return data['payments'] ?? [];
      }
    } catch (e) {
      debugPrint('[ApiService Admin] getPayments error: $e');
      isServerOnline.value = false;
    }
    return [];
  }

  static Future<Map<String, dynamic>> addPayment({
    required String paymentId,
    required String patientId,
    required String patientName,
    required double amount,
    required String paymentMethod,
    required String paymentDate,
    String status = 'Paid',
    String transactionId = '',
    String notes = '',
  }) async {
    await checkHealth();
    try {
      final uri = Uri.parse('$baseUrl/payments').replace(
        queryParameters: {
          'payment_id': paymentId,
          'patient_id': patientId,
          'patient_name': patientName,
          'amount': amount.toString(),
          'payment_method': paymentMethod,
          'payment_date': paymentDate,
          'status': status,
          'transaction_id': transactionId,
          'notes': notes,
        },
      );
      final headers = await getAdminHeaders();
      final response = await http.post(uri, headers: headers).timeout(const Duration(seconds: 6));
      if (response.statusCode >= 200 && response.statusCode < 300) {
        isServerOnline.value = true;
        return jsonDecode(response.body);
      }
    } catch (e) {
      debugPrint('[ApiService Admin] addPayment error: $e');
      isServerOnline.value = false;
    }
    return {'success': false, 'message': 'Failed to record payment in database'};
  }

  // =========================================================
  // NOTIFICATIONS
  // =========================================================
  static Future<List<dynamic>> getNotifications() async {
    await checkHealth();
    try {
      final headers = await getAdminHeaders();
      final response = await http
          .get(Uri.parse('$baseUrl/notifications'), headers: headers)
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        isServerOnline.value = true;
        final data = jsonDecode(response.body);
        return data['notifications'] ?? [];
      }
    } catch (e) {
      debugPrint('[ApiService Admin] getNotifications error: $e');
      isServerOnline.value = false;
    }
    return [];
  }

  static Future<Map<String, dynamic>> addNotification({
    required String notificationId,
    required String patientId,
    required String patientName,
    required String title,
    required String message,
    String notificationType = 'General',
    String status = 'Sent',
  }) async {
    await checkHealth();
    try {
      final uri = Uri.parse('$baseUrl/notifications').replace(
        queryParameters: {
          'notification_id': notificationId,
          'patient_id': patientId,
          'patient_name': patientName,
          'title': title,
          'message': message,
          'notification_type': notificationType,
          'status': status,
        },
      );
      final headers = await getAdminHeaders();
      final response = await http.post(uri, headers: headers).timeout(const Duration(seconds: 6));
      if (response.statusCode >= 200 && response.statusCode < 300) {
        isServerOnline.value = true;
        return jsonDecode(response.body);
      }
    } catch (e) {
      debugPrint('[ApiService Admin] addNotification error: $e');
      isServerOnline.value = false;
    }
    return {'success': false, 'message': 'Failed to dispatch notification'};
  }

  // =========================================================
  // ADMIN LOGIN (VALIDATED STRICTLY AGAINST MYSQL BACKEND)
  // =========================================================
  static Future<Map<String, dynamic>> adminLogin({
    required String email,
    required String password,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    final cleanPassword = password.trim();

    try {
      final uri = Uri.parse('$baseUrl/admin/login');
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': cleanEmail,
          'password': cleanPassword,
        }),
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        isServerOnline.value = true;
        final data = jsonDecode(response.body);

        if (data['success'] == true) {
          final token = data['access_token'] ?? data['token'] ?? data['data']?['access_token'];
          if (token != null) {
            await setAdminToken(token.toString());
          }
          return data;
        }
      } else {
        try {
          final errData = jsonDecode(response.body);
          return {
            'success': false,
            'message': errData['detail'] ?? errData['message'] ?? 'Authentication failed',
          };
        } catch (_) {}
      }
    } catch (e) {
      debugPrint('[ApiService Admin] Login error: $e');
      isServerOnline.value = false;
      return {
        'success': false,
        'message': 'Cannot connect to diagnostic backend. Please check server status.',
      };
    }

    return {'success': false, 'message': 'Invalid email or password'};
  }

  static Future<Map<String, dynamic>> changeAdminPassword({
    required String email,
    required String newPassword,
  }) async {
    await checkHealth();
    try {
      final uri = Uri.parse('$baseUrl/admin/change-password');
      final headers = await getAdminHeaders();
      final response = await http.post(
        uri,
        headers: headers,
        body: jsonEncode({
          'email': email.trim().toLowerCase(),
          'new_password': newPassword.trim(),
        }),
      ).timeout(const Duration(seconds: 6));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      debugPrint('[ApiService Admin] changePassword error: $e');
    }

    return {'success': false, 'message': 'Failed to update password in database'};
  }

  static Future<Map<String, dynamic>> adminForgotPassword({
    required String email,
  }) async {
    await checkHealth();
    try {
      final uri = Uri.parse('$baseUrl/admin/forgot-password');
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email.trim().toLowerCase()}),
      ).timeout(const Duration(seconds: 6));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      debugPrint('[ApiService Admin] adminForgotPassword error: $e');
    }

    return {
      'success': true,
      'message': 'Password reset request submitted to diagnostic administrator.',
    };
  }

  // =========================================================
  // REAL-TIME APPOINTMENT BOOKING (POST /api/appointments)
  // =========================================================
  static Future<Map<String, dynamic>> bookAppointment({
    required String patientName,
    required String serviceName,
    required String appointmentDate,
    required String appointmentTime,
    String? mobile,
    String? patientId,
    int? age,
    String? gender,
    String? doctorName,
    String? note,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/api/appointments'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'patient_name': patientName,
              'service_name': serviceName,
              'appointment_date': appointmentDate,
              'appointment_time': appointmentTime,
              'mobile': mobile,
              'patient_id': patientId,
              'age': age,
              'gender': gender ?? 'Male',
              'doctor_name': doctorName,
              'note': note,
            }),
          )
          .timeout(const Duration(seconds: 5));

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return data;
      } else {
        return {
          'success': false,
          'message': data['detail'] ?? data['message'] ?? 'Booking failed',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // =========================================================
  // UPDATE APPOINTMENT STATUS (PATCH /api/appointments/{id}/status)
  // =========================================================
  static Future<Map<String, dynamic>> updateAppointmentStatus({
    required int id,
    required String status,
    String? note,
  }) async {
    try {
      final response = await http
          .patch(
            Uri.parse('$baseUrl/api/appointments/$id/status'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'status': status, 'note': note}),
          )
          .timeout(const Duration(seconds: 4));

      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Failed to update status: $e'};
    }
  }

  // =========================================================
  // RESCHEDULE APPOINTMENT (POST /api/appointments/{id}/reschedule)
  // =========================================================
  static Future<Map<String, dynamic>> rescheduleAppointment({
    required int id,
    required String newDate,
    required String newTime,
    String? note,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/api/appointments/$id/reschedule'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'new_date': newDate,
              'new_time': newTime,
              'note': note,
            }),
          )
          .timeout(const Duration(seconds: 4));

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return data;
      } else {
        return {'success': false, 'message': data['detail'] ?? 'Reschedule failed'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // =========================================================
  // PATIENT 360° SUMMARY & QR CODE DOSSIER (GET /api/patients/{id}/summary)
  // =========================================================
  static Future<Map<String, dynamic>?> getPatientSummary(String id) async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/api/patients/$id/summary'))
          .timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      debugPrint('[ApiService] Failed to get patient summary: $e');
    }
    return null;
  }

  // =========================================================
  // MARK NOTIFICATION READ (PATCH /api/notifications/{id}/read)
  // =========================================================
  static Future<bool> markNotificationRead(int id) async {
    try {
      final response = await http
          .patch(Uri.parse('$baseUrl/api/notifications/$id/read'))
          .timeout(const Duration(seconds: 3));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // =========================================================
  // REGISTER FCM TOKEN (POST /api/fcm/register-token)
  // =========================================================
  static Future<bool> registerFcmToken(String token, {String userType = 'admin'}) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/api/fcm/register-token'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'token': token,
              'user_type': userType,
              'device_type': defaultTargetPlatform.name,
            }),
          )
          .timeout(const Duration(seconds: 4));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}


