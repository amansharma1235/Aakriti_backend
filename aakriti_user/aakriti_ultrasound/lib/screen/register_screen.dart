import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  bool obscurePassword = true;
  bool obscureConfirmPassword = true;
  bool isLoading = false;

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  void showMessage(String message, {bool success = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              success
                  ? Icons.check_circle_rounded
                  : Icons.error_outline_rounded,
              color: Colors.white,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: success
            ? const Color(0xFF159A8C)
            : const Color(0xFFD64545),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  Future<void> register() async {
    FocusScope.of(context).unfocus();

    final name = nameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    final confirmPassword = confirmPasswordController.text.trim();

    if (name.isEmpty) {
      showMessage("Please enter your full name.");
      return;
    }

    if (name.length < 2) {
      showMessage("Please enter a valid name.");
      return;
    }

    if (email.isEmpty) {
      showMessage("Please enter your email address.");
      return;
    }

    if (!email.contains("@") || !email.contains(".")) {
      showMessage("Please enter a valid email address.");
      return;
    }

    if (password.isEmpty) {
      showMessage("Please create a password.");
      return;
    }

    if (password.length < 6) {
      showMessage("Password must contain at least 6 characters.");
      return;
    }

    if (confirmPassword.isEmpty) {
      showMessage("Please confirm your password.");
      return;
    }

    if (password != confirmPassword) {
      showMessage("Passwords do not match.");
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final phone = phoneController.text.trim();
      final res = await AuthService.register(
        name: name,
        email: email,
        phone: phone,
        password: password,
      );

      if (!mounted) return;

      if (res['success'] == true) {
        showMessage("Account created successfully! Please sign in.", success: true);

        await Future.delayed(const Duration(milliseconds: 700));

        if (!mounted) return;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      } else {
        showMessage(res['message'] ?? "Registration failed. Please try again.");
      }
    } catch (e) {
      showMessage("Something went wrong during registration. Please try again.");
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  InputDecoration fieldDecoration({
    required String hint,
    required IconData icon,
    Widget? suffixIcon,
    required bool isDark,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        color: isDark ? Colors.white38 : Colors.black38,
        fontSize: 14,
      ),
      prefixIcon: Icon(icon, color: const Color(0xFF1677FF)),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: isDark ? const Color(0xFF132A3E) : const Color(0xFFF1F6FB),
      contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFF1677FF), width: 1.2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? Colors.white : const Color(0xFF071A2B);
    final secondaryTextColor = isDark ? Colors.white70 : Colors.black54;
    final cardBg = Theme.of(context).cardColor;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: GestureDetector(
          onTap: () {
            FocusScope.of(context).unfocus();
          },
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                // ==========================================
                // PREMIUM HEADER
                // ==========================================

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(28, 32, 28, 48),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF061827),
                        Color(0xFF0B3150),
                        Color(0xFF123D61),
                      ],
                    ),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(42),
                      bottomRight: Radius.circular(42),
                    ),
                  ),
                  child: Column(
                    children: [
                      // AAKRITI LOGO
                      Container(
                        height: 82,
                        width: 82,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(27),
                          border: Border.all(
                            color: const Color(0xFF18C8C8)
                                .withValues(alpha: 0.38),
                            width: 1.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF18C8C8)
                                  .withValues(alpha: 0.16),
                              blurRadius: 25,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.monitor_heart_rounded,
                          color: Color(0xFF18C8C8),
                          size: 45,
                        ),
                      ),

                      const SizedBox(height: 19),

                      const Text(
                        "AAKRITI",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 5,
                        ),
                      ),

                      const SizedBox(height: 4),

                      const Text(
                        "ULTRASOUND",
                        style: TextStyle(
                          color: Color(0xFF18C8C8),
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 4,
                        ),
                      ),
                    ],
                  ),
                ),

                // ==========================================
                // REGISTER CARD
                // ==========================================
                Transform.translate(
                  offset: const Offset(0, -22),
                  child: Container(
                    width: double.infinity,
                    margin: const EdgeInsets.symmetric(horizontal: 18),
                    padding: const EdgeInsets.fromLTRB(22, 27, 22, 30),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : Colors.transparent,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF071A2B)
                              .withValues(alpha: isDark ? 0.25 : 0.08),
                          blurRadius: 30,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Create Account",
                          style: TextStyle(
                            color: primaryTextColor,
                            fontSize: 27,
                            fontWeight: FontWeight.w800,
                          ),
                        ),

                        const SizedBox(height: 7),

                        Text(
                          "Create your secure Aakriti account to manage "
                          "your appointments and reports.",
                          style: TextStyle(
                            color: secondaryTextColor,
                            fontSize: 13.5,
                            height: 1.5,
                          ),
                        ),

                        const SizedBox(height: 27),

                        // FULL NAME
                        Text(
                          "Full Name",
                          style: TextStyle(
                            color: primaryTextColor,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),

                        const SizedBox(height: 9),

                        TextField(
                          controller: nameController,
                          textCapitalization: TextCapitalization.words,
                          textInputAction: TextInputAction.next,
                          style: TextStyle(color: primaryTextColor),
                          decoration: fieldDecoration(
                            hint: "Enter your full name",
                            icon: Icons.person_outline_rounded,
                            isDark: isDark,
                          ),
                        ),

                        const SizedBox(height: 19),

                        // EMAIL
                        Text(
                          "Email Address",
                          style: TextStyle(
                            color: primaryTextColor,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),

                        const SizedBox(height: 9),

                        TextField(
                          controller: emailController,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          style: TextStyle(color: primaryTextColor),
                          decoration: fieldDecoration(
                            hint: "Enter your email",
                            icon: Icons.email_outlined,
                            isDark: isDark,
                          ),
                        ),

                        const SizedBox(height: 19),

                        // PHONE NUMBER (OPTIONAL)
                        Text(
                          "Mobile Number (Optional)",
                          style: TextStyle(
                            color: primaryTextColor,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),

                        const SizedBox(height: 9),

                        TextField(
                          controller: phoneController,
                          keyboardType: TextInputType.phone,
                          textInputAction: TextInputAction.next,
                          style: TextStyle(color: primaryTextColor),
                          decoration: fieldDecoration(
                            hint: "10-digit mobile number",
                            icon: Icons.phone_iphone_rounded,
                            isDark: isDark,
                          ),
                        ),

                        const SizedBox(height: 19),

                        // PASSWORD
                        Text(
                          "Password",
                          style: TextStyle(
                            color: primaryTextColor,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),

                        const SizedBox(height: 9),

                        TextField(
                          controller: passwordController,
                          obscureText: obscurePassword,
                          textInputAction: TextInputAction.next,
                          style: TextStyle(color: primaryTextColor),
                          decoration: fieldDecoration(
                            hint: "Create a password",
                            icon: Icons.lock_outline_rounded,
                            isDark: isDark,
                            suffixIcon: IconButton(
                              onPressed: () {
                                setState(() {
                                  obscurePassword = !obscurePassword;
                                });
                              },
                              icon: Icon(
                                obscurePassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: secondaryTextColor,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 19),

                        // CONFIRM PASSWORD
                        Text(
                          "Confirm Password",
                          style: TextStyle(
                            color: primaryTextColor,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),

                        const SizedBox(height: 9),

                        TextField(
                          controller: confirmPasswordController,
                          obscureText: obscureConfirmPassword,
                          textInputAction: TextInputAction.done,
                          style: TextStyle(color: primaryTextColor),
                          onSubmitted: (_) {
                            if (!isLoading) {
                              register();
                            }
                          },
                          decoration: fieldDecoration(
                            hint: "Confirm your password",
                            icon: Icons.verified_user_outlined,
                            isDark: isDark,
                            suffixIcon: IconButton(
                              onPressed: () {
                                setState(() {
                                  obscureConfirmPassword =
                                      !obscureConfirmPassword;
                                });
                              },
                              icon: Icon(
                                obscureConfirmPassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: secondaryTextColor,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        // PASSWORD INFO
                        Row(
                          children: [
                            const Icon(
                              Icons.info_outline_rounded,
                              size: 16,
                              color: Color(0xFF1677FF),
                            ),
                            const SizedBox(width: 7),
                            Text(
                              "Password must contain at least 6 characters",
                              style: TextStyle(
                                color: secondaryTextColor,
                                fontSize: 11.5,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 23),

                        // REGISTER BUTTON
                        SizedBox(
                          width: double.infinity,
                          height: 58,
                          child: ElevatedButton(
                            onPressed: isLoading ? null : register,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1677FF),
                              disabledBackgroundColor: const Color(0xFF8EB8F5),
                              foregroundColor: Colors.white,
                              elevation: 7,
                              shadowColor: const Color(0xFF1677FF)
                                  .withValues(alpha: 0.28),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(17),
                              ),
                            ),
                            child: isLoading
                                ? const SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        "Create Account",
                                        style: TextStyle(
                                          fontSize: 15.5,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      SizedBox(width: 10),
                                      Icon(
                                        Icons.arrow_forward_rounded,
                                        size: 21,
                                      ),
                                    ],
                                  ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // LOGIN LINK
                        Center(
                          child: Wrap(
                            alignment: WrapAlignment.center,
                            children: [
                              Text(
                                "Already have an account? ",
                                style: TextStyle(
                                  color: secondaryTextColor,
                                  fontSize: 13.5,
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const LoginScreen(),
                                    ),
                                  );
                                },
                                child: const Text(
                                  "Sign In",
                                  style: TextStyle(
                                    color: Color(0xFF1677FF),
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 22),

                        // SECURITY CARD
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(13),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF0F2C3A)
                                : const Color(0xFFF0FAFA),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: const Color(0xFF18C8C8)
                                  .withValues(alpha: 0.18),
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.verified_user_outlined,
                                color: Color(0xFF159A8C),
                                size: 19,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  "Your account information is protected "
                                  "with secure Firebase authentication.",
                                  style: TextStyle(
                                    color: secondaryTextColor,
                                    fontSize: 11.5,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 2),

                const Padding(
                  padding: EdgeInsets.only(left: 30, right: 30, bottom: 20),
                  child: Text(
                    "© Aakriti Ultrasound & Diagnostic Centre",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.black38, fontSize: 10.5),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
