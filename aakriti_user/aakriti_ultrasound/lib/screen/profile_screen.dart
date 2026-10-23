import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import 'settings_screen.dart';
import 'family_members_screen.dart';
import 'edit_profile_screen.dart';
import 'notifications_screen.dart';
import 'my_appoinments_screen.dart';
import 'reports_screen.dart';
import 'login_screen.dart';
import '../admin/screens/login/login_screen.dart' as admin_login;
import '../services/auth_service.dart';
import '../services/profile_service.dart';
import '../widgets/notification_app_bar_button.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String? _customMobile;
  String? _customAge;
  String? _customAddress;
  String? _customName;
  String? _customEmail;

  String? _localPhotoPath;
  bool _isUploadingPhoto = false;

  final ImagePicker _imagePicker = ImagePicker();

  User? get currentUser => FirebaseAuth.instance.currentUser;
  Map<String, dynamic>? _sessionUser;

  String get name {
    if (_customName != null && _customName!.trim().isNotEmpty && _customName != 'User') {
      return _customName!.trim();
    }

    final serviceName = ProfileService.userNameNotifier.value.trim();
    if (serviceName.isNotEmpty && serviceName != 'Patient' && serviceName != 'User') {
      return serviceName;
    }

    final firebaseName = currentUser?.displayName?.trim();
    if (firebaseName != null && firebaseName.isNotEmpty) {
      return firebaseName;
    }

    final sessionName = _sessionUser?['name']?.toString().trim();
    if (sessionName != null && sessionName.isNotEmpty && sessionName != 'Patient') {
      return sessionName;
    }

    final userEmail = currentUser?.email ?? _sessionUser?['email'];
    if (userEmail != null && userEmail.contains('@')) {
      final part = userEmail.split('@').first;
      return part.isNotEmpty ? part[0].toUpperCase() + part.substring(1) : "User";
    }

    return "User";
  }

  String get email {
    if (_customEmail != null && _customEmail!.trim().isNotEmpty) {
      return _customEmail!.trim();
    }

    final serviceEmail = ProfileService.userEmailNotifier.value.trim();
    if (serviceEmail.isNotEmpty) {
      return serviceEmail;
    }

    return currentUser?.email ?? _sessionUser?['email'] ?? "";
  }

  String get patientId {
    final pid = ProfileService.patientIdNotifier.value.trim();
    if (pid.isNotEmpty) return pid;
    final sPid = _sessionUser?['patientId']?.toString().trim();
    if (sPid != null && sPid.isNotEmpty) return sPid;
    return "PT101";
  }

  String get mobile {
    if (_customMobile != null && _customMobile!.trim().isNotEmpty) {
      final m = _customMobile!.trim();
      return m.startsWith('+') ? m : "+91 $m";
    }
    final serviceMobile = ProfileService.userMobileNotifier.value.trim();
    if (serviceMobile.isNotEmpty) {
      return serviceMobile.startsWith('+') ? serviceMobile : "+91 $serviceMobile";
    }
    final sPhone = _sessionUser?['phone']?.toString().trim();
    if (sPhone != null && sPhone.isNotEmpty) {
      return sPhone.startsWith('+') ? sPhone : "+91 $sPhone";
    }
    return "Not Provided";
  }

  String get age {
    if (_customAge != null && _customAge!.trim().isNotEmpty) {
      final a = _customAge!.trim();
      return a.contains('Year') ? a : "$a Years";
    }
    final serviceAge = ProfileService.userAgeNotifier.value.trim();
    if (serviceAge.isNotEmpty) {
      return serviceAge.contains('Year') ? serviceAge : "$serviceAge Years";
    }
    final sAge = _sessionUser?['age']?.toString().trim();
    if (sAge != null && sAge.isNotEmpty) {
      return sAge.contains('Year') ? sAge : "$sAge Years";
    }
    return "Not Specified";
  }

  String get address {
    if (_customAddress != null && _customAddress!.trim().isNotEmpty) {
      return _customAddress!.trim();
    }
    final serviceAddr = ProfileService.userAddressNotifier.value.trim();
    if (serviceAddr.isNotEmpty) {
      return serviceAddr;
    }
    final sAddr = _sessionUser?['address']?.toString().trim();
    if (sAddr != null && sAddr.isNotEmpty) {
      return sAddr;
    }
    return "Not Specified";
  }

  String? get profilePhoto {
    final photo = currentUser?.photoURL?.trim();

    if (photo != null && photo.isNotEmpty) {
      return photo;
    }

    return null;
  }

  String get initials {
    final userName = name.trim();

    if (userName.isEmpty || userName == "User") {
      return "U";
    }

    final parts = userName.split(RegExp(r'\s+'));

    if (parts.length >= 2) {
      return "${parts.first[0]}${parts.last[0]}".toUpperCase();
    }

    return parts.first[0].toUpperCase();
  }

  Color get bgColor {
    return Theme.of(context).scaffoldBackgroundColor;
  }

  Color get cardColor {
    return Theme.of(context).cardColor;
  }

  Color get primaryText {
    return Theme.of(context).brightness == Brightness.dark
        ? Colors.white
        : const Color(0xFF071A2B);
  }

  Color get secondaryText {
    return Theme.of(context).brightness == Brightness.dark
        ? Colors.white70
        : Colors.grey.shade600;
  }

  Color get smallText {
    return Theme.of(context).brightness == Brightness.dark
        ? Colors.white54
        : Colors.grey.shade500;
  }

  Color get borderColor {
    return Theme.of(context).brightness == Brightness.dark
        ? Colors.white.withValues(alpha: 0.08)
        : const Color(0xFFE8EEF5);
  }

  Color get iconBackground {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF102A40)
        : const Color(0xFFEAF4FF);
  }

  @override
  void initState() {
    super.initState();
    _customMobile = ProfileService.userMobileNotifier.value;
    _customAge = ProfileService.userAgeNotifier.value;
    _customAddress = ProfileService.userAddressNotifier.value;
    _customName = ProfileService.userNameNotifier.value;
    _customEmail = ProfileService.userEmailNotifier.value;
    _loadSavedPhoto();
    _loadSessionUser();
  }

  Future<void> _loadSessionUser() async {
    final user = await AuthService.getCurrentUser();
    if (mounted && user != null) {
      setState(() {
        _sessionUser = user;
        if (user['phone'] != null && user['phone'].toString().trim().isNotEmpty) {
          _customMobile = user['phone'].toString().trim();
        }
        if (user['name'] != null && user['name'].toString().trim().isNotEmpty) {
          _customName = user['name'].toString().trim();
        }
        if (user['email'] != null && user['email'].toString().trim().isNotEmpty) {
          _customEmail = user['email'].toString().trim();
        }
      });
    }
  }

  Future<void> _loadSavedPhoto() async {
    try {
      await ProfileService.init(force: true);
      if (mounted) {
        setState(() {
          _localPhotoPath = ProfileService.profilePhotoNotifier.value;
        });
      }
    } catch (_) {}
  }

  Future<void> _pickProfilePhoto() async {
    if (_isUploadingPhoto) return;

    try {
      final XFile? pickedImage = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1200,
        maxHeight: 1200,
      );

      if (pickedImage == null) {
        return;
      }

      if (!mounted) return;

      setState(() {
        _isUploadingPhoto = true;
      });

      String finalPhotoPath;

      if (kIsWeb) {
        final bytes = await pickedImage.readAsBytes();
        final base64String = base64Encode(bytes);
        finalPhotoPath = 'data:image/jpeg;base64,$base64String';
      } else {
        final directory = await getApplicationDocumentsDirectory();
        final user = await AuthService.getCurrentUser();
        final userKey = (user?['patientId'] ?? user?['email'] ?? user?['phone'] ?? currentUser?.uid ?? 'user')
            .toString()
            .replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_');
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final savedFile = File('${directory.path}/profile_${userKey}_$timestamp.jpg');
        final bytes = await pickedImage.readAsBytes();
        await savedFile.writeAsBytes(bytes);
        finalPhotoPath = savedFile.path;
      }

      await ProfileService.updatePhoto(finalPhotoPath);

      if (!mounted) return;

      setState(() {
        _localPhotoPath = finalPhotoPath;
        _isUploadingPhoto = false;
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Profile photo updated successfully."),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isUploadingPhoto = false;
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Photo error: $e"),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _removeProfilePhoto() async {
    try {
      await ProfileService.removePhoto();

      if (!mounted) return;

      setState(() {
        _localPhotoPath = null;
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Profile photo removed."),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (_) {}
  }

  void _showPhotoOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 45,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),

                const SizedBox(height: 22),

                Text(
                  "Profile Photo",
                  style: TextStyle(
                    color: primaryText,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 18),

                ListTile(
                  leading: Container(
                    width: 45,
                    height: 45,
                    decoration: BoxDecoration(
                      color: iconBackground,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.photo_library_outlined,
                      color: Color(0xFF1677FF),
                    ),
                  ),
                  title: Text(
                    "Choose from Gallery",
                    style: TextStyle(
                      color: primaryText,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _pickProfilePhoto();
                  },
                ),

                if (_localPhotoPath != null)
                  ListTile(
                    leading: Container(
                      width: 45,
                      height: 45,
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.delete_outline,
                        color: Colors.red,
                      ),
                    ),
                    title: const Text(
                      "Remove Photo",
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(sheetContext);
                      _removeProfilePhoto();
                    },
                  ),

                const SizedBox(height: 10),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> editProfile() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditProfileScreen(
          name: name,
          mobile: mobile.replaceAll("+91 ", ""),
          email: email,
          age: age.replaceAll(" Years", ""),
          address: address,
        ),
      ),
    );

    if (!mounted || result == null || result is! Map<String, dynamic>) return;

    final newName = (result["name"] ?? name).toString().trim();
    final newMobile = (result["mobile"] ?? "").toString().trim();
    final newEmail = (result["email"] ?? "").toString().trim();
    final newAge = (result["age"] ?? "").toString().trim();
    final newAddress = (result["address"] ?? "").toString().trim();

    // Persist all fields to ProfileService and SharedPreferences
    await ProfileService.updateProfile(
      name: newName.isNotEmpty ? newName : name,
      mobile: newMobile.isNotEmpty ? "+91 $newMobile" : mobile,
      email: newEmail.isNotEmpty ? newEmail : email,
      age: newAge.isNotEmpty ? "$newAge Years" : age,
      address: newAddress.isNotEmpty ? newAddress : address,
    );

    // Also update FirebaseAuth displayName if available
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && newName.isNotEmpty && newName != user.displayName) {
        await user.updateDisplayName(newName);
        await user.reload();
      }
    } catch (_) {}

    if (!mounted) return;

    setState(() {
      if (newName.isNotEmpty) _customName = newName;
      if (newEmail.isNotEmpty) _customEmail = newEmail;
      if (newMobile.isNotEmpty) _customMobile = newMobile;
      if (newAge.isNotEmpty) _customAge = newAge;
      if (newAddress.isNotEmpty) _customAddress = newAddress;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Profile updated and saved successfully!"),
        backgroundColor: Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,

      appBar: AppBar(
        backgroundColor: const Color(0xFF071A2B),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          "My Profile",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: const [
          NotificationAppBarButton(),
          SizedBox(width: 6),
        ],
      ),

      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF071A2B),
                  Color(0xFF123D61),
                  Color(0xFF1677FF),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(26),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1677FF).withValues(alpha: 0.18),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 96,
                      height: 96,
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.18),
                            blurRadius: 15,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: ValueListenableBuilder<String?>(
                          valueListenable: ProfileService.profilePhotoNotifier,
                          builder: (context, photoPath, _) {
                            if (photoPath != null && photoPath.isNotEmpty) {
                              if (photoPath.startsWith('data:image')) {
                                try {
                                  final bytes = base64Decode(photoPath.split(',').last);
                                  return Image.memory(
                                    bytes,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) =>
                                        _defaultAvatar(),
                                  );
                                } catch (_) {}
                              } else if (!kIsWeb) {
                                final file = File(photoPath);
                                if (file.existsSync()) {
                                  return Image.file(
                                    file,
                                    key: ValueKey(photoPath),
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) =>
                                        _defaultAvatar(),
                                  );
                                }
                              }
                            }

                            if (profilePhoto != null && profilePhoto!.isNotEmpty) {
                              return Image.network(
                                profilePhoto!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return _defaultAvatar();
                                },
                              );
                            }

                            return _defaultAvatar();
                          },
                        ),
                      ),
                    ),

                    Positioned(
                      right: -3,
                      bottom: -3,
                      child: GestureDetector(
                        onTap: _showPhotoOptions,
                        child: Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: const Color(0xFF18C8C8),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: _isUploadingPhoto
                              ? const Padding(
                                  padding: EdgeInsets.all(8),
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(
                                  Icons.camera_alt_rounded,
                                  color: Colors.white,
                                  size: 17,
                                ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 15),

                Text(
                  name,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 23,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  "Patient ID: $patientId",
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),

                const SizedBox(height: 14),

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.verified_rounded,
                        color: Color(0xFF18C8C8),
                        size: 16,
                      ),
                      SizedBox(width: 6),
                      Text(
                        "Verified Patient",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 22),

          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: editProfile,
              icon: const Icon(Icons.edit_outlined),
              label: const Text(
                "Edit Profile",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1677FF),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ),
          ),

          const SizedBox(height: 25),

          Text(
            "Personal Information",
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
              color: primaryText,
            ),
          ),

          const SizedBox(height: 13),

          _infoCard(
            icon: Icons.phone_outlined,
            title: "Mobile Number",
            value: mobile,
          ),

          _infoCard(
            icon: Icons.email_outlined,
            title: "Email Address",
            value: email,
          ),

          _infoCard(icon: Icons.cake_outlined, title: "Age", value: age),

          _infoCard(
            icon: Icons.location_on_outlined,
            title: "Address",
            value: address,
          ),

          const SizedBox(height: 20),

          Text(
            "Account",
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
              color: primaryText,
            ),
          ),

          const SizedBox(height: 13),

          _menuCard(
            icon: Icons.calendar_month_outlined,
            title: "My Appointments",
            subtitle: "View your appointments",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const MyAppointmentsScreen(),
                ),
              );
            },
          ),

          _menuCard(
            icon: Icons.description_outlined,
            title: "My Reports",
            subtitle: "View your diagnostic reports",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ReportsScreen()),
              );
            },
          ),

          _menuCard(
            icon: Icons.group_outlined,
            title: "Family Members",
            subtitle: "Manage family patient profiles",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const FamilyMembersScreen(),
                ),
              );
            },
          ),

          _menuCard(
            icon: Icons.notifications_none_rounded,
            title: "Notifications",
            subtitle: "View your notifications",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NotificationsScreen(),
                ),
              );
            },
          ),

          _menuCard(
            icon: Icons.settings_outlined,
            title: "Settings",
            subtitle: "App preferences and security",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),

          _menuCard(
            icon: Icons.admin_panel_settings_outlined,
            title: "Admin Panel",
            subtitle: "Staff & management dashboard",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const admin_login.LoginScreen(isFromUserApp: true),
                ),
              );
            },
          ),

          const SizedBox(height: 15),

          SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton.icon(
              onPressed: _logoutDialog,
              icon: const Icon(Icons.logout_rounded, color: Colors.red),
              label: const Text(
                "Logout",
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: OutlinedButton.styleFrom(
                backgroundColor: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF29181B)
                    : const Color(0xFFFFF7F7),
                side: BorderSide(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.red.withValues(alpha: 0.25)
                      : const Color(0xFFFFD4D4),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),

          const SizedBox(height: 25),

          const Center(
            child: Column(
              children: [
                Text(
                  "AAKRITI",
                  style: TextStyle(
                    color: Color(0xFF1677FF),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  "ULTRASOUND & DIAGNOSTICS",
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 9,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 25),
        ],
      ),
    );
  }

  Widget _defaultAvatar() {
    return Container(
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1677FF), Color(0xFF18C8C8)],
        ),
      ),
      child: Center(
        child: Text(
          initials,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }

  Widget _infoCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.black.withValues(alpha: 0.15)
                : Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 43,
            height: 43,
            decoration: BoxDecoration(
              color: iconBackground,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: const Color(0xFF1677FF), size: 21),
          ),

          const SizedBox(width: 13),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: smallText, fontSize: 11)),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    color: primaryText,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _menuCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 11),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: borderColor),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.black.withValues(alpha: 0.15)
                  : Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 45,
              height: 45,
              decoration: BoxDecoration(
                color: iconBackground,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: const Color(0xFF1677FF), size: 22),
            ),

            const SizedBox(width: 13),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: primaryText,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    subtitle,
                    style: TextStyle(color: secondaryText, fontSize: 11),
                  ),
                ],
              ),
            ),

            Icon(
              Icons.arrow_forward_ios_rounded,
              color: secondaryText,
              size: 15,
            ),
          ],
        ),
      ),
    );
  }

  void _logoutDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            "Logout",
            style: TextStyle(fontWeight: FontWeight.bold, color: primaryText),
          ),
          content: Text(
            "Are you sure you want to logout from your account?",
            style: TextStyle(color: secondaryText),
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

                try {
                  await AuthService.clearSession();
                  await FirebaseAuth.instance.signOut();

                  if (!mounted) return;

                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LoginScreen(),
                    ),
                    (route) => false,
                  );
                } catch (e) {
                  if (!mounted) return;

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Logout failed. Please try again."),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text("Logout"),
            ),
          ],
        );
      },
    );
  }
}
