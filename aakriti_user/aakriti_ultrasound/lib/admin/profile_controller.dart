import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileController {
  ProfileController._();

  static final ProfileController instance = ProfileController._();

  static const String _keyName = 'admin_profile_name';
  static const String _keyEmail = 'admin_profile_email';
  static const String _keyMobile = 'admin_profile_mobile';
  static const String _keyRole = 'admin_profile_role';
  static const String _keyPhotoB64 = 'admin_profile_photo_b64';

  /// Profile image bytes (null if using default asset image)
  final ValueNotifier<Uint8List?> profileImageBytes = ValueNotifier<Uint8List?>(null);

  /// Admin Full Name
  final ValueNotifier<String> adminName = ValueNotifier<String>('Aman Sharma');

  /// Admin Email
  final ValueNotifier<String> adminEmail = ValueNotifier<String>('amansharma274502@gmail.com');

  /// Admin Mobile
  final ValueNotifier<String> adminMobile = ValueNotifier<String>('9519701963');

  /// Admin Role / Subtitle
  final ValueNotifier<String> adminRole = ValueNotifier<String>('Administrator • Centre #01');

  bool _initialized = false;

  /// Load persisted profile details from SharedPreferences
  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    try {
      final prefs = await SharedPreferences.getInstance();

      final savedName = prefs.getString(_keyName);
      if (savedName != null && savedName.trim().isNotEmpty) {
        adminName.value = savedName.trim();
      }

      final savedEmail = prefs.getString(_keyEmail);
      if (savedEmail != null && savedEmail.trim().isNotEmpty) {
        adminEmail.value = savedEmail.trim();
      }

      final savedMobile = prefs.getString(_keyMobile);
      if (savedMobile != null && savedMobile.trim().isNotEmpty) {
        adminMobile.value = savedMobile.trim();
      }

      final savedRole = prefs.getString(_keyRole);
      if (savedRole != null && savedRole.trim().isNotEmpty) {
        adminRole.value = savedRole.trim();
      }

      final savedPhotoB64 = prefs.getString(_keyPhotoB64);
      if (savedPhotoB64 != null && savedPhotoB64.isNotEmpty) {
        try {
          profileImageBytes.value = base64Decode(savedPhotoB64);
        } catch (_) {}
      }
    } catch (e) {
      debugPrint('[ProfileController] init error: $e');
    }
  }

  /// Update the profile picture across the entire application (Top Bar, Drawer, Settings)
  Future<void> setProfilePhoto(Uint8List bytes) async {
    profileImageBytes.value = bytes;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyPhotoB64, base64Encode(bytes));
    } catch (_) {}
  }

  /// Remove custom photo and restore default
  Future<void> resetToDefaultPhoto() async {
    profileImageBytes.value = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyPhotoB64);
    } catch (_) {}
  }

  /// Update admin name, email, mobile, and role with persistent storage
  Future<void> updateAdminInfo({
    String? name,
    String? email,
    String? mobile,
    String? role,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    if (name != null && name.trim().isNotEmpty) {
      final val = name.trim();
      adminName.value = val;
      await prefs.setString(_keyName, val);
    }
    if (email != null && email.trim().isNotEmpty) {
      final val = email.trim();
      adminEmail.value = val;
      await prefs.setString(_keyEmail, val);
    }
    if (mobile != null && mobile.trim().isNotEmpty) {
      final val = mobile.trim();
      adminMobile.value = val;
      await prefs.setString(_keyMobile, val);
    }
    if (role != null && role.trim().isNotEmpty) {
      final val = role.trim();
      adminRole.value = val;
      await prefs.setString(_keyRole, val);
    }
  }
}
