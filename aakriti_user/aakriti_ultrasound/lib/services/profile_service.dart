import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_service.dart';

class ProfileService {
  static const String photoPathKey = "profile_photo_path";
  static const String userNameKey = "user_name_key";
  static const String userMobileKey = "user_mobile_key";
  static const String userEmailKey = "user_email_key";
  static const String userAgeKey = "user_age_key";
  static const String userAddressKey = "user_address_key";
  static const String patientIdKey = "patient_id_key";

  // Global notifiers that any widget in the app can listen to
  static final ValueNotifier<String?> profilePhotoNotifier = ValueNotifier<String?>(null);
  static final ValueNotifier<String> userNameNotifier = ValueNotifier<String>("");
  static final ValueNotifier<String> userMobileNotifier = ValueNotifier<String>("");
  static final ValueNotifier<String> userEmailNotifier = ValueNotifier<String>("");
  static final ValueNotifier<String> userAgeNotifier = ValueNotifier<String>("");
  static final ValueNotifier<String> userAddressNotifier = ValueNotifier<String>("");
  static final ValueNotifier<String> patientIdNotifier = ValueNotifier<String>("");

  static bool _initialized = false;

  /// Load persisted profile photo path and all patient details
  static Future<void> init({bool force = false}) async {
    if (_initialized && !force) return;
    _initialized = true;

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (doc.exists && doc.data() != null) {
          final data = doc.data()!;
          userNameNotifier.value = (data['name'] ?? user.displayName ?? '').toString().trim();
          userEmailNotifier.value = (data['email'] ?? user.email ?? '').toString().trim();
          userMobileNotifier.value = (data['phone'] ?? user.phoneNumber ?? '').toString().trim();
          patientIdNotifier.value = (data['patientId'] ?? 'PT${user.uid.substring(0, 6).toUpperCase()}').toString().trim();
          return;
        }
      }

      final prefs = await SharedPreferences.getInstance();
      final sessionUser = await AuthService.getCurrentUser();

      String? userKey = sessionUser?['patientId'] ?? user?.uid;
      final specificKey = userKey != null && userKey.trim().isNotEmpty
          ? "${photoPathKey}_${userKey.trim().replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_')}"
          : photoPathKey;

      final savedPath = prefs.getString(specificKey);
      profilePhotoNotifier.value = savedPath;

      userNameNotifier.value = (sessionUser?['name'] ?? user?.displayName ?? '').toString().trim();
      userEmailNotifier.value = (sessionUser?['email'] ?? user?.email ?? '').toString().trim();
      userMobileNotifier.value = (sessionUser?['phone'] ?? user?.phoneNumber ?? '').toString().trim();
      if (user != null) {
        patientIdNotifier.value = 'PT${user.uid.substring(0, 6).toUpperCase()}';
      }
    } catch (e) {
      debugPrint('[ProfileService] init error: $e');
    }
  }

  /// Populate profile from an active session
  static Future<void> loadFromSession(Map<String, dynamic> user) async {
    final name = (user['name'] ?? '').toString().trim();
    final email = (user['email'] ?? '').toString().trim();
    final phone = (user['phone'] ?? '').toString().trim();
    final pid = (user['patientId'] ?? user['patient_id'] ?? '').toString().trim();

    await updateProfile(
      name: name,
      email: email,
      mobile: phone,
      patientId: pid,
    );
    await init(force: true);
  }

  /// Update profile photo across the whole app for current user
  static Future<void> updatePhoto(String newPath) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sessionUser = await AuthService.getCurrentUser();
      String? userKey;
      if (sessionUser != null) {
        userKey = (sessionUser['patientId'] ?? sessionUser['email'] ?? sessionUser['phone'])?.toString();
      }
      if (userKey == null || userKey.isEmpty) {
        userKey = FirebaseAuth.instance.currentUser?.uid;
      }
      final specificKey = userKey != null && userKey.trim().isNotEmpty
          ? "${photoPathKey}_${userKey.trim().replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_')}"
          : photoPathKey;

      await prefs.setString(specificKey, newPath);
      await prefs.setString(photoPathKey, newPath);
      profilePhotoNotifier.value = newPath;
      debugPrint("[ProfileService] Photo updated to: $newPath for $specificKey");
    } catch (e) {
      debugPrint("[ProfileService] updatePhoto error: $e");
    }
  }

  /// Remove profile photo across the whole app
  static Future<void> removePhoto() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sessionUser = await AuthService.getCurrentUser();
      String? userKey;
      if (sessionUser != null) {
        userKey = (sessionUser['patientId'] ?? sessionUser['email'] ?? sessionUser['phone'])?.toString();
      }
      if (userKey == null || userKey.isEmpty) {
        userKey = FirebaseAuth.instance.currentUser?.uid;
      }
      final specificKey = userKey != null && userKey.trim().isNotEmpty
          ? "${photoPathKey}_${userKey.trim().replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_')}"
          : photoPathKey;

      final currentPath = prefs.getString(specificKey);
      if (currentPath != null && !kIsWeb && !currentPath.startsWith('data:image') && !currentPath.startsWith('http')) {
        final file = File(currentPath);
        if (await file.exists()) {
          await file.delete();
        }
      }
      await prefs.remove(specificKey);
      await prefs.remove(photoPathKey);
      profilePhotoNotifier.value = null;
      debugPrint("[ProfileService] Photo removed for $specificKey.");
    } catch (e) {
      debugPrint("[ProfileService] removePhoto error: $e");
    }
  }

  /// Comprehensive profile update (Full Name, Mobile, Email, Age, Address, Patient ID)
  static Future<void> updateProfile({
    required String name,
    String? mobile,
    String? email,
    String? age,
    String? address,
    String? patientId,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final trimmedName = name.trim();

      if (trimmedName.isNotEmpty) {
        await prefs.setString(userNameKey, trimmedName);
        userNameNotifier.value = trimmedName;
      }

      if (mobile != null && mobile.trim().isNotEmpty) {
        final cleanMobile = mobile.trim();
        await prefs.setString(userMobileKey, cleanMobile);
        userMobileNotifier.value = cleanMobile;
      }

      if (email != null && email.trim().isNotEmpty) {
        final cleanEmail = email.trim();
        await prefs.setString(userEmailKey, cleanEmail);
        userEmailNotifier.value = cleanEmail;
      }

      if (age != null && age.trim().isNotEmpty) {
        final cleanAge = age.trim();
        await prefs.setString(userAgeKey, cleanAge);
        userAgeNotifier.value = cleanAge;
      }

      if (address != null && address.trim().isNotEmpty) {
        final cleanAddress = address.trim();
        await prefs.setString(userAddressKey, cleanAddress);
        userAddressNotifier.value = cleanAddress;
      }

      if (patientId != null && patientId.trim().isNotEmpty) {
        final cleanPid = patientId.trim();
        await prefs.setString(patientIdKey, cleanPid);
        patientIdNotifier.value = cleanPid;
      }

      // Try updating FirebaseAuth user display name as well
      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null && trimmedName.isNotEmpty && trimmedName != user.displayName) {
          await user.updateDisplayName(trimmedName);
          await user.reload();
        }
      } catch (_) {}

      debugPrint("[ProfileService] Profile successfully updated and persisted: $trimmedName");
    } catch (e) {
      debugPrint("[ProfileService] updateProfile error: $e");
    }
  }

  /// Clear profile upon logout
  static Future<void> clear() async {
    userNameNotifier.value = "";
    userEmailNotifier.value = "";
    userMobileNotifier.value = "";
    userAgeNotifier.value = "";
    userAddressNotifier.value = "";
    patientIdNotifier.value = "";
    profilePhotoNotifier.value = null;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(userNameKey);
      await prefs.remove(userEmailKey);
      await prefs.remove(userMobileKey);
      await prefs.remove(userAgeKey);
      await prefs.remove(userAddressKey);
      await prefs.remove(patientIdKey);
      await prefs.remove(photoPathKey);
    } catch (_) {}
  }

  /// Update patient name only
  static Future<void> updateName(String name) async {
    await updateProfile(name: name);
  }
}
