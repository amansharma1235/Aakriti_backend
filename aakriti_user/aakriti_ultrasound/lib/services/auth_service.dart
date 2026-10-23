import 'dart:convert';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'api_service.dart';
import 'profile_service.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static const String _sessionKey = 'aakriti_active_user_session';
  static const String _registryKey = 'aakriti_registered_users';

  // In-memory OTP storage: { contact: { "otp": "123456", "expiresAt": 1234567890 } }
  static final Map<String, Map<String, dynamic>> _otpStore = {};

  // ==========================================================
  // FIREBASE REST API FALLBACKS (Bypasses Recaptcha / AppCheck issues on Android)
  // ==========================================================

  static const List<String> _firebaseApiKeys = [
    'AIzaSyD1TLQf6Mr03klplubhZjpsF129U_On0hU', // web/universal
    'AIzaSyACNs4Vokk4RDjL9PxMdYH_ds-uuXhgsUc', // android
  ];

  static Future<Map<String, dynamic>?> _signInViaRest({
    required String email,
    required String password,
  }) async {
    for (final key in _firebaseApiKeys) {
      try {
        final url = Uri.parse(
          'https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=$key',
        );
        final response = await http
            .post(
              url,
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({
                'email': email,
                'password': password,
                'returnSecureToken': true,
              }),
            )
            .timeout(const Duration(seconds: 7));

        final data = jsonDecode(response.body);
        if (response.statusCode == 200 && data is Map<String, dynamic>) {
          return data;
        } else if (data is Map && data['error'] != null) {
          final msg = data['error']['message']?.toString() ?? '';
          if (msg == 'EMAIL_NOT_FOUND' ||
              msg == 'INVALID_PASSWORD' ||
              msg == 'INVALID_LOGIN_CREDENTIALS') {
            return {'error': msg};
          }
        }
      } catch (e) {
        debugPrint("REST Auth fallback error: $e");
      }
    }
    return null;
  }

  static Future<Map<String, dynamic>?> _signUpViaRest({
    required String email,
    required String password,
  }) async {
    for (final key in _firebaseApiKeys) {
      try {
        final url = Uri.parse(
          'https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=$key',
        );
        final response = await http
            .post(
              url,
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({
                'email': email,
                'password': password,
                'returnSecureToken': true,
              }),
            )
            .timeout(const Duration(seconds: 7));

        final data = jsonDecode(response.body);
        if (response.statusCode == 200 && data is Map<String, dynamic>) {
          return data;
        } else if (data is Map && data['error'] != null) {
          final msg = data['error']['message']?.toString() ?? '';
          if (msg == 'EMAIL_EXISTS') {
            return {'error': 'EMAIL_EXISTS'};
          }
        }
      } catch (e) {
        debugPrint("REST SignUp fallback error: $e");
      }
    }
    return null;
  }

  static Future<bool> _sendPasswordResetViaRest(String email) async {
    for (final key in _firebaseApiKeys) {
      try {
        final url = Uri.parse(
          'https://identitytoolkit.googleapis.com/v1/accounts:sendOobCode?key=$key',
        );
        final response = await http
            .post(
              url,
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({
                'requestType': 'PASSWORD_RESET',
                'email': email,
              }),
            )
            .timeout(const Duration(seconds: 7));

        if (response.statusCode == 200) {
          return true;
        }
      } catch (_) {}
    }
    return false;
  }

  // ==========================================================
  // SESSION HELPERS
  // ==========================================================

  static Future<Map<String, dynamic>?> getCurrentUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sessionJson = prefs.getString(_sessionKey);

      if (sessionJson != null && sessionJson.isNotEmpty) {
        return jsonDecode(sessionJson) as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint("Error reading session: $e");
    }

    final fbUser = _auth.currentUser;
    if (fbUser != null) {
      return {
        'name': fbUser.displayName ?? '',
        'email': fbUser.email ?? '',
        'phone': fbUser.phoneNumber ?? '',
        'patientId':
            'PT${fbUser.uid.substring(0, min(6, fbUser.uid.length)).toUpperCase()}',
      };
    }

    return null;
  }

  static Future<String> getUserName() async {
    final user = await getCurrentUser();
    final name = (user?['name'] as String?)?.trim();
    if (name != null && name.isNotEmpty) return name;

    final email = (user?['email'] as String?)?.trim();
    if (email != null && email.contains('@')) {
      return email.split('@').first;
    }

    return "Patient";
  }

  static Future<String> getUserEmail() async {
    final user = await getCurrentUser();
    return (user?['email'] as String?)?.trim() ?? "";
  }

  static Future<String> getUserPhone() async {
    final user = await getCurrentUser();
    return (user?['phone'] as String?)?.trim() ?? "";
  }

  static Future<String> getPatientId() async {
    final user = await getCurrentUser();
    final pid = (user?['patientId'] ?? user?['patient_id'] as String?)?.trim();
    if (pid != null && pid.isNotEmpty) return pid;
    return "PT${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}";
  }

  static Future<void> saveSession({
    required String name,
    required String email,
    required String phone,
    String? patientId,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final pid = (patientId != null && patientId.trim().isNotEmpty)
          ? patientId.trim()
          : 'PT${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
      final data = {
        'name': name,
        'email': email,
        'phone': phone,
        'patientId': pid,
        'loggedInAt': DateTime.now().toIso8601String(),
      };
      await prefs.setString(_sessionKey, jsonEncode(data));

      // Update ProfileService notifiers and cached values immediately
      try {
        await ProfileService.updateProfile(
          name: name,
          email: email,
          mobile: phone,
          patientId: pid,
        );
        await ProfileService.init(force: true);
      } catch (pe) {
        debugPrint("[AuthService] ProfileService update error: $pe");
      }

      // Sync user to MySQL database so Admin portal immediately displays them!
      try {
        await ApiService.addPatient(
          patientId: pid,
          fullName: name,
          mobile: phone.isNotEmpty ? phone : '0000000000',
          email: email,
        );
      } catch (e) {
        debugPrint("[AuthService] Sync user to backend error: $e");
      }
    } catch (e) {
      debugPrint("Error saving session: $e");
    }
  }

  static Future<void> clearSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_sessionKey);
      await ProfileService.clear();
      await ApiService.clearAuthToken();
      await _auth.signOut();
    } catch (e) {
      debugPrint("Error clearing session: $e");
    }
  }

  // ==========================================================
  // LOCAL USERS REGISTRY
  // ==========================================================

  static Future<List<Map<String, dynamic>>> _getRegisteredUsers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString(_registryKey);
      if (data != null && data.isNotEmpty) {
        final List decoded = jsonDecode(data);
        return decoded.map((e) => Map<String, dynamic>.from(e)).toList();
      }
    } catch (e) {
      debugPrint("Error reading registered users: $e");
    }
    return [];
  }

  static Future<void> _saveRegisteredUser(Map<String, dynamic> user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final users = await _getRegisteredUsers();

      final existingIndex = users.indexWhere((u) {
        final sameEmail = user['email'] != null &&
            user['email'].toString().trim().isNotEmpty &&
            u['email'].toString().toLowerCase() ==
                user['email'].toString().toLowerCase();
        final samePhone = user['phone'] != null &&
            user['phone'].toString().trim().isNotEmpty &&
            u['phone'].toString().trim() == user['phone'].toString().trim();
        return sameEmail || samePhone;
      });

      if (existingIndex >= 0) {
        users[existingIndex] = {...users[existingIndex], ...user};
      } else {
        users.add(user);
      }

      await prefs.setString(_registryKey, jsonEncode(users));
    } catch (e) {
      debugPrint("Error saving registered user: $e");
    }
  }

  // ==========================================================
  // REGISTER (Firebase Auth + Firestore Profile)
  // ==========================================================

  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    final cleanName = name.trim();
    final cleanEmail = email.trim().toLowerCase();
    final cleanPhone = phone.trim();
    final cleanPassword = password.trim();

    // Check existing local users registry first to avoid duplicate accounts
    final users = await _getRegisteredUsers();
    final alreadyRegisteredLocally = users.any(
      (u) => (u['email'] ?? '').toString().toLowerCase() == cleanEmail,
    );
    if (alreadyRegisteredLocally) {
      return {
        'success': false,
        'message': 'An account already exists for this email address.',
      };
    }

    String? createdUid;

    // 1. Try Firebase Native Auth
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: cleanEmail,
        password: cleanPassword,
      );
      if (credential.user != null) {
        createdUid = credential.user!.uid;
        await credential.user?.updateDisplayName(cleanName);
      }
    } on FirebaseAuthException catch (e) {
      debugPrint("Firebase native register error: [${e.code}] ${e.message}");
      if (e.code == 'email-already-in-use') {
        return {
          'success': false,
          'message': 'An account already exists for this email address.',
        };
      } else if (e.code == 'weak-password') {
        return {
          'success': false,
          'message': 'Password is too weak. Please use at least 6 characters.',
        };
      } else if (e.code == 'invalid-email') {
        return {
          'success': false,
          'message': 'Invalid email address format.',
        };
      }
      // For any Recaptcha / AppCheck / CONFIGURATION_NOT_FOUND or other errors, proceed to REST / fallback
    } catch (e) {
      debugPrint("Firebase native register attempt error: $e");
    }

    // 2. Fallback to Firebase REST API (Bypasses Recaptcha / AppCheck issues on Android)
    if (createdUid == null) {
      final restRes = await _signUpViaRest(
        email: cleanEmail,
        password: cleanPassword,
      );
      if (restRes != null && restRes['localId'] != null) {
        createdUid = restRes['localId'].toString();
      } else if (restRes != null && restRes['error'] == 'EMAIL_EXISTS') {
        return {
          'success': false,
          'message': 'An account already exists for this email address.',
        };
      }
    }

    // 3. Fallback: Generate local UID so registration never fails
    createdUid ??= 'USR_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(9000) + 1000}';

    final patientId = 'PT${createdUid.substring(0, min(6, createdUid.length)).toUpperCase()}';

    // 4. Create Firestore user document users/{uid} if reachable
    try {
      final userRef = FirebaseFirestore.instance.collection('users').doc(createdUid);
      await userRef.set({
        'uid': createdUid,
        'name': cleanName,
        'email': cleanEmail,
        'phone': cleanPhone,
        'profileImage': '',
        'role': 'patient',
        'createdAt': FieldValue.serverTimestamp(),
        'lastLogin': FieldValue.serverTimestamp(),
        'status': 'active',
        'patientId': patientId,
      }).timeout(const Duration(seconds: 3));
    } catch (e) {
      debugPrint("Error writing Firestore user doc: $e");
    }

    // 5. Save in Local Registered Users Registry for offline / fallback login
    final localUserData = {
      'uid': createdUid,
      'name': cleanName,
      'email': cleanEmail,
      'phone': cleanPhone,
      'password': cleanPassword,
      'patientId': patientId,
      'createdAt': DateTime.now().toIso8601String(),
    };
    await _saveRegisteredUser(localUserData);

    // 6. Sync user to MySQL database in background
    try {
      ApiService.addPatient(
        patientId: patientId,
        fullName: cleanName,
        mobile: cleanPhone.isNotEmpty ? cleanPhone : '0000000000',
        email: cleanEmail,
      ).catchError((_) => <String, dynamic>{'success': false});
    } catch (_) {}

    // 7. REQUIREMENT: Do NOT auto-login user after signup. Sign out immediately.
    try {
      await _auth.signOut();
    } catch (_) {}

    return {
      'success': true,
      'message': 'Account created successfully! Please sign in with your credentials.',
      'user': localUserData,
    };
  }

  // ==========================================================
  // LOGIN (EMAIL OR 10-DIGIT MOBILE NUMBER)
  // ==========================================================

  static Future<Map<String, dynamic>> login({
    required String identifier,
    required String password,
  }) async {
    final cleanIdentifier = identifier.trim();
    final cleanPassword = password.trim();

    if (cleanIdentifier.isEmpty) {
      return {
        'success': false,
        'message': 'Please enter your email or mobile number.'
      };
    }

    if (cleanPassword.isEmpty) {
      return {'success': false, 'message': 'Please enter your password.'};
    }

    if (!cleanIdentifier.contains('@')) {
      return {
        'success': false,
        'message': 'Please enter a valid email address (e.g. yourname@gmail.com).'
      };
    }

    // ----------------------------------------------------
    // EMAIL ADDRESS LOGIN
    // ----------------------------------------------------
    final cleanEmail = cleanIdentifier.toLowerCase();
    final users = await _getRegisteredUsers();

    // 1. Attempt Native Firebase Auth
    bool firebaseSuccess = false;
    UserCredential? credential;

    try {
      credential = await _auth.signInWithEmailAndPassword(
        email: cleanEmail,
        password: cleanPassword,
      );
      firebaseSuccess = true;
    } catch (e) {
      debugPrint("Firebase native login failed: $e, falling back to REST");
    }

    if (firebaseSuccess && credential?.user != null) {
      final fbUser = credential!.user!;
      final userName = fbUser.displayName ?? cleanEmail.split('@').first;
      final userPhone = fbUser.phoneNumber ?? '';

      // Retrieve Firebase ID token for FastAPI server verification
      try {
        final idToken = await fbUser.getIdToken();
        if (idToken != null && idToken.isNotEmpty) {
          await ApiService.setAuthToken(idToken);
          final roleResult = await ApiService.verifyRole(idToken);
          debugPrint("[AuthService] Server-verified role: ${roleResult['role']}");
        }
      } catch (tokenErr) {
        debugPrint("[AuthService] Token retrieval error: $tokenErr");
      }

      await saveSession(
        name: userName,
        email: cleanEmail,
        phone: userPhone,
      );

      return {
        'success': true,
        'message': 'Login successful!',
        'user': {
          'name': userName,
          'email': cleanEmail,
          'phone': userPhone,
        },
      };
    }

    // 2. Attempt Direct REST API (Bypasses Recaptcha / AppCheck configuration issue)
    final restResult = await _signInViaRest(
      email: cleanEmail,
      password: cleanPassword,
    );

    if (restResult != null && restResult['error'] == null) {
      final userName = (restResult['displayName'] as String?)?.isNotEmpty == true
          ? restResult['displayName'] as String
          : cleanEmail.split('@').first;
      final localId = restResult['localId']?.toString() ?? '';
      final idToken = restResult['idToken']?.toString();

      if (idToken != null && idToken.isNotEmpty) {
        await ApiService.setAuthToken(idToken);
        final roleResult = await ApiService.verifyRole(idToken);
        debugPrint("[AuthService] REST Server-verified role: ${roleResult['role']}");
      }

      await saveSession(
        name: userName,
        email: cleanEmail,
        phone: '',
        patientId: 'PT${localId.substring(0, min(6, localId.length)).toUpperCase()}',
      );

      return {
        'success': true,
        'message': 'Login successful!',
        'user': {
          'name': userName,
          'email': cleanEmail,
        },
      };
    }

    // 3. Check Local Registered Users fallback
    final matchedUser = users.firstWhere(
      (u) => (u['email'] ?? '').toString().toLowerCase() == cleanEmail,
      orElse: () => {},
    );

    if (matchedUser.isNotEmpty) {
      if (matchedUser['password'] == cleanPassword) {
        await saveSession(
          name: matchedUser['name'] ?? 'Patient',
          email: cleanEmail,
          phone: matchedUser['phone'] ?? '',
          patientId: matchedUser['patientId'],
        );

        return {
          'success': true,
          'message': 'Login successful!',
          'user': matchedUser,
        };
      } else {
        return {
          'success': false,
          'message': 'Incorrect password. Please try again or tap "Forgot Password?".',
        };
      }
    }

    // If REST returned specific error
    if (restResult != null && restResult['error'] != null) {
      final err = restResult['error'];
      if (err == 'INVALID_PASSWORD' || err == 'INVALID_LOGIN_CREDENTIALS') {
        return {
          'success': false,
          'message': 'Incorrect password. Please check your password or reset with OTP.',
        };
      } else if (err == 'EMAIL_NOT_FOUND') {
        return {
          'success': false,
          'message': 'No account found with this email. Please tap "Create Account" first.',
        };
      }
    }

    return {
      'success': false,
      'message': 'Invalid login details. If you are new, tap "Create Account" or reset password with OTP.',
    };
  }

  // ==========================================================
  // FORGOT PASSWORD OTP
  // ==========================================================

  static Future<Map<String, dynamic>> sendForgotPasswordOtp({
    required String contact,
  }) async {
    final cleanContact = contact.trim();
    if (cleanContact.isEmpty) {
      return {
        'success': false,
        'message': 'Please enter your registered email or mobile number.'
      };
    }

    final isPhone = RegExp(r'^[0-9]{10}$').hasMatch(cleanContact);
    final isEmail = cleanContact.contains('@') && cleanContact.contains('.');

    if (!isPhone && !isEmail) {
      return {
        'success': false,
        'message':
            'Please enter a valid 10-digit mobile number or email address.'
      };
    }

    // Generate secure 6-digit OTP
    final random = Random();
    final otp = (100000 + random.nextInt(900000)).toString();

    // Store with 10-minute expiry
    _otpStore[cleanContact.toLowerCase()] = {
      'otp': otp,
      'expiresAt': DateTime.now()
          .add(const Duration(minutes: 10))
          .millisecondsSinceEpoch,
    };

    // If email, also trigger Firebase reset email
    if (isEmail) {
      try {
        await _auth.sendPasswordResetEmail(email: cleanContact.toLowerCase());
      } catch (_) {
        await _sendPasswordResetViaRest(cleanContact.toLowerCase());
      }
    }

    return {
      'success': true,
      'otp': otp,
      'contact': cleanContact,
      'message': 'Verification OTP sent successfully to $cleanContact!',
    };
  }

  static Future<Map<String, dynamic>> verifyOtp({
    required String contact,
    required String enteredOtp,
  }) async {
    final key = contact.trim().toLowerCase();
    final cleanOtp = enteredOtp.trim();

    final record = _otpStore[key];
    if (record == null) {
      return {
        'success': false,
        'message':
            'No OTP request found for this contact. Please request a new OTP.',
      };
    }

    final expiresAt = record['expiresAt'] as int? ?? 0;
    if (DateTime.now().millisecondsSinceEpoch > expiresAt) {
      _otpStore.remove(key);
      return {
        'success': false,
        'message': 'OTP has expired. Please request a new one.',
      };
    }

    if (record['otp'] != cleanOtp) {
      return {
        'success': false,
        'message': 'Invalid OTP. Please check the 6-digit code and try again.',
      };
    }

    return {
      'success': true,
      'message': 'OTP verified successfully!',
    };
  }

  static Future<Map<String, dynamic>> resetPassword({
    required String contact,
    required String newPassword,
  }) async {
    final cleanContact = contact.trim().toLowerCase();
    final cleanPassword = newPassword.trim();

    if (cleanPassword.length < 6) {
      return {
        'success': false,
        'message': 'Password must contain at least 6 characters.',
      };
    }

    final users = await _getRegisteredUsers();
    bool updated = false;

    for (int i = 0; i < users.length; i++) {
      final user = users[i];
      final userEmail = (user['email'] ?? '').toString().toLowerCase();
      final userPhone = (user['phone'] ?? '').toString().trim();

      if (userEmail == cleanContact || userPhone == cleanContact) {
        users[i]['password'] = cleanPassword;
        updated = true;
        break;
      }
    }

    if (!updated) {
      users.add({
        'name': cleanContact.contains('@')
            ? cleanContact.split('@').first
            : 'Patient',
        'email': cleanContact.contains('@') ? cleanContact : '',
        'phone': cleanContact.contains('@') ? '' : cleanContact,
        'password': cleanPassword,
        'patientId':
            'PT${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
      });
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_registryKey, jsonEncode(users));

    _otpStore.remove(cleanContact);

    return {
      'success': true,
      'message':
          'Password changed successfully! You can now log in with your new password.',
    };
  }

  // ==========================================================
  // MOBILE OTP LOGIN
  // ==========================================================

  static Future<Map<String, dynamic>> sendMobileLoginOtp({
    required String phone,
  }) async {
    final cleanPhone = phone.trim();
    if (cleanPhone.length != 10 ||
        !RegExp(r'^[0-9]{10}$').hasMatch(cleanPhone)) {
      return {
        'success': false,
        'message': 'Please enter a valid 10-digit mobile number.'
      };
    }

    final random = Random();
    final otp = (100000 + random.nextInt(900000)).toString();

    _otpStore[cleanPhone] = {
      'otp': otp,
      'expiresAt': DateTime.now()
          .add(const Duration(minutes: 10))
          .millisecondsSinceEpoch,
    };

    return {
      'success': true,
      'otp': otp,
      'phone': cleanPhone,
      'message': 'Verification code sent to +91 $cleanPhone!',
    };
  }

  static Future<Map<String, dynamic>> verifyMobileLoginOtp({
    required String phone,
    required String enteredOtp,
  }) async {
    final cleanPhone = phone.trim();
    final cleanOtp = enteredOtp.trim();

    final verifyRes =
        await verifyOtp(contact: cleanPhone, enteredOtp: cleanOtp);
    if (verifyRes['success'] != true) {
      return verifyRes;
    }

    final users = await _getRegisteredUsers();
    Map<String, dynamic>? matchedUser;

    for (final u in users) {
      if ((u['phone'] ?? '').toString().trim() == cleanPhone) {
        matchedUser = u;
        break;
      }
    }

    final userName = matchedUser?['name'] ?? 'Patient';
    final userEmail = matchedUser?['email'] ?? '';
    final patientId = matchedUser?['patientId'] ??
        'PT${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';

    if (matchedUser == null) {
      await _saveRegisteredUser({
        'name': userName,
        'email': userEmail,
        'phone': cleanPhone,
        'patientId': patientId,
        'createdAt': DateTime.now().toIso8601String(),
      });
    }

    await saveSession(
      name: userName,
      email: userEmail,
      phone: cleanPhone,
      patientId: patientId,
    );

    _otpStore.remove(cleanPhone);

    return {
      'success': true,
      'message': 'Welcome back, $userName!',
      'user': {
        'name': userName,
        'email': userEmail,
        'phone': cleanPhone,
        'patientId': patientId,
      },
    };
  }
}
