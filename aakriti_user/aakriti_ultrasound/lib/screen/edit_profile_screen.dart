import 'package:flutter/material.dart';
import 'package:aakriti_ultrasound/services/profile_service.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({
    super.key,
    this.name = "",
    this.mobile = "",
    this.email = "",
    this.age = "",
    this.address = "",
  });

  final String name;
  final String mobile;
  final String email;
  final String age;
  final String address;

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController nameController;
  late TextEditingController mobileController;
  late TextEditingController emailController;
  late TextEditingController ageController;
  late TextEditingController addressController;

  @override
  void initState() {
    super.initState();

    nameController = TextEditingController(text: widget.name);
    mobileController = TextEditingController(text: widget.mobile);
    emailController = TextEditingController(text: widget.email);
    ageController = TextEditingController(text: widget.age);
    addressController = TextEditingController(text: widget.address);
  }

  @override
  void dispose() {
    nameController.dispose();
    mobileController.dispose();
    emailController.dispose();
    ageController.dispose();
    addressController.dispose();
    super.dispose();
  }

  Future<void> saveProfile() async {
    final trimmedName = nameController.text.trim();
    if (trimmedName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please enter your full name."),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final newMobile = mobileController.text.trim();
    final newEmail = emailController.text.trim();
    final newAge = ageController.text.trim();
    final newAddress = addressController.text.trim();

    // Persist immediately in ProfileService so all notifiers and SharedPreferences are updated
    await ProfileService.updateProfile(
      name: trimmedName,
      mobile: newMobile.isNotEmpty ? "+91 $newMobile" : null,
      email: newEmail.isNotEmpty ? newEmail : null,
      age: newAge.isNotEmpty ? "$newAge Years" : null,
      address: newAddress.isNotEmpty ? newAddress : null,
    );

    if (!mounted) return;

    Navigator.pop(context, {
      "name": trimmedName,
      "mobile": newMobile,
      "email": newEmail,
      "age": newAge,
      "address": newAddress,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8FC),

      appBar: AppBar(
        backgroundColor: const Color(0xFF071A2B),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          "Edit Profile",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),

      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // ================= PROFILE ICON =================

          Center(
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1677FF), Color(0xFF18C8C8)],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1677FF).withValues(alpha: 0.20),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(
                Icons.person_rounded,
                color: Colors.white,
                size: 52,
              ),
            ),
          ),

          const SizedBox(height: 12),

          const Center(
            child: Text(
              "Update Your Information",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF071A2B),
              ),
            ),
          ),

          const SizedBox(height: 25),

          // ================= NAME =================
          _inputField(
            controller: nameController,
            label: "Full Name",
            hint: "Enter your full name",
            icon: Icons.person_outline_rounded,
            keyboardType: TextInputType.name,
          ),

          // ================= MOBILE =================
          _inputField(
            controller: mobileController,
            label: "Mobile Number",
            hint: "Enter mobile number",
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
          ),

          // ================= EMAIL =================
          _inputField(
            controller: emailController,
            label: "Email Address",
            hint: "Enter email address",
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
          ),

          // ================= AGE =================
          _inputField(
            controller: ageController,
            label: "Age",
            hint: "Enter your age",
            icon: Icons.cake_outlined,
            keyboardType: TextInputType.number,
          ),

          // ================= ADDRESS =================
          _inputField(
            controller: addressController,
            label: "Address",
            hint: "Enter your address",
            icon: Icons.location_on_outlined,
            keyboardType: TextInputType.streetAddress,
            maxLines: 3,
          ),

          const SizedBox(height: 10),

          // ================= SAVE BUTTON =================
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton.icon(
              onPressed: saveProfile,
              icon: const Icon(Icons.save_outlined),
              label: const Text(
                "Save Changes",
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1677FF),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // ================= INFO =================
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: const Color(0xFFEAF4FF),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFD6EAFF)),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline_rounded, color: Color(0xFF1677FF)),

                SizedBox(width: 10),

                Expanded(
                  child: Text(
                    "Your profile information is saved securely on this device. Changes take effect immediately.",
                    style: TextStyle(
                      color: Color(0xFF123D61),
                      fontSize: 12,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ================= INPUT FIELD =================

  Widget _inputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required TextInputType keyboardType,
    int maxLines = 1,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon, color: const Color(0xFF1677FF)),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 17,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFE3EAF2)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFF1677FF), width: 1.5),
          ),
        ),
      ),
    );
  }
}
