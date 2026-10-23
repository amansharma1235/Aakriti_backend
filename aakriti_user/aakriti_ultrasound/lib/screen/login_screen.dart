import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/auth_service.dart';
import 'home_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool obscurePassword = true;
  bool isLoading = false;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  // =========================
  // SHOW SNACKBAR MESSAGE
  // =========================

  void showMessage(String message, {bool success = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              success ? Icons.check_circle_rounded : Icons.error_outline_rounded,
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
        backgroundColor: success ? const Color(0xFF159A8C) : const Color(0xFFD64545),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  // =========================
  // IN-APP OTP POPUP BANNER
  // Guaranteed delivery of OTP to the user
  // =========================

  void _showOtpBanner({
    required String otp,
    required String title,
    required String recipient,
    VoidCallback? onAutoFill,
  }) {
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF071A2B), Color(0xFF0F3657)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFF18C8C8).withValues(alpha: 0.4), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF18C8C8).withValues(alpha: 0.25),
                  blurRadius: 30,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF18C8C8).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.mark_email_read_rounded, color: Color(0xFF18C8C8), size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "AAKRITI VERIFICATION OTP",
                            style: TextStyle(
                              color: Color(0xFF18C8C8),
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
                            ),
                          ),
                          Text(
                            title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  "Sent to: $recipient",
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
                const SizedBox(height: 14),
                // OTP Code Display Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 32),
                      Expanded(
                        child: Center(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              otp.split('').join('  '),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 3,
                              ),
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: "Copy OTP",
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                        icon: const Icon(Icons.copy_rounded, color: Color(0xFF18C8C8), size: 20),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: otp));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("OTP copied to clipboard!"),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  "Valid for 10 minutes. Do not share this code.",
                  style: TextStyle(color: Colors.white54, fontSize: 11),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text("Dismiss", style: TextStyle(color: Colors.white70)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          if (onAutoFill != null) onAutoFill();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1677FF),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text("Auto Fill", style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // =========================
  // LOGIN (EMAIL OR MOBILE)
  // =========================

  Future<void> login() async {
    FocusScope.of(context).unfocus();

    final identifier = emailController.text.trim();
    final password = passwordController.text.trim();

    if (identifier.isEmpty) {
      showMessage("Please enter your registered email address.");
      return;
    }

    if (!identifier.contains('@') || !identifier.contains('.')) {
      showMessage("Please enter a valid email address (e.g. yourname@gmail.com).");
      return;
    }

    if (password.isEmpty) {
      showMessage("Please enter your password.");
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final res = await AuthService.login(identifier: identifier, password: password);

      if (!mounted) return;

      if (res['success'] == true) {
        showMessage(res['message'] ?? "Login successful!", success: true);
        await Future.delayed(const Duration(milliseconds: 300));

        if (!mounted) return;
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
          (route) => false,
        );
      } else {
        showMessage(res['message'] ?? "Login failed. Please check credentials.");
      }
    } catch (e) {
      showMessage("Something went wrong during login. Please try again.");
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  // ==========================================================
  // FORGOT PASSWORD WITH OTP (STEP 1 -> STEP 2 -> STEP 3)
  // ==========================================================

  void _openForgotPasswordSheet() {
    final contactCtrl = TextEditingController(text: emailController.text.trim());
    final otpCtrl = TextEditingController();
    final newPassCtrl = TextEditingController();
    final confirmPassCtrl = TextEditingController();

    int currentStep = 1; // 1: Input Contact, 2: Enter OTP, 3: Set New Password
    bool isProcessing = false;
    bool obscureNew = true;
    bool obscureConfirm = true;
    int resendCountdown = 30;
    Timer? countdownTimer;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            final bg = Theme.of(context).cardColor;
            final pText = isDark ? Colors.white : const Color(0xFF071A2B);
            final sText = isDark ? Colors.white70 : Colors.grey.shade600;
            final inputBg = isDark ? const Color(0xFF132A3E) : const Color(0xFFF1F6FB);

            void startCountdown() {
              countdownTimer?.cancel();
              resendCountdown = 30;
              countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
                if (!context.mounted) {
                  timer.cancel();
                  return;
                }
                if (resendCountdown > 0) {
                  setModalState(() => resendCountdown--);
                } else {
                  timer.cancel();
                }
              });
            }

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 44,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.grey.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // HEADER
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1677FF).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            currentStep == 1
                                ? Icons.lock_reset_rounded
                                : (currentStep == 2 ? Icons.pin_rounded : Icons.verified_user_rounded),
                            color: const Color(0xFF1677FF),
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                currentStep == 1
                                    ? "Reset Password"
                                    : (currentStep == 2 ? "Enter Verification OTP" : "Create New Password"),
                                style: TextStyle(
                                  fontSize: 19,
                                  fontWeight: FontWeight.bold,
                                  color: pText,
                                ),
                              ),
                              Text(
                                currentStep == 1
                                    ? "We'll send a 6-digit OTP code to reset your password"
                                    : (currentStep == 2
                                        ? "Enter the code sent to ${contactCtrl.text.trim()}"
                                        : "Enter a strong password with at least 6 characters"),
                                style: TextStyle(color: sText, fontSize: 12.5),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 22),

                    // ==========================================
                    // STEP 1: ENTER CONTACT & SEND OTP
                    // ==========================================
                    if (currentStep == 1) ...[
                      TextField(
                        controller: contactCtrl,
                        style: TextStyle(color: pText),
                        decoration: InputDecoration(
                          labelText: "Registered Mobile or Email",
                          hintText: "Enter 10-digit mobile or email",
                          prefixIcon: const Icon(Icons.contact_mail_outlined, color: Color(0xFF1677FF)),
                          filled: true,
                          fillColor: inputBg,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: isProcessing
                              ? null
                              : () async {
                                  final contact = contactCtrl.text.trim();
                                  if (contact.isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text("Please enter mobile number or email.")),
                                    );
                                    return;
                                  }

                                  setModalState(() => isProcessing = true);
                                  final res = await AuthService.sendForgotPasswordOtp(contact: contact);
                                  setModalState(() => isProcessing = false);

                                  if (res['success'] == true) {
                                    final otpCode = res['otp'] as String;
                                    setModalState(() {
                                      currentStep = 2;
                                      startCountdown();
                                    });

                                    // Display guaranteed OTP popup
                                    _showOtpBanner(
                                      otp: otpCode,
                                      title: "Password Reset Verification",
                                      recipient: contact,
                                      onAutoFill: () {
                                        otpCtrl.text = otpCode;
                                        setModalState(() {});
                                      },
                                    );
                                  } else {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text(res['message'] ?? "Error sending OTP")),
                                      );
                                    }
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1677FF),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                          ),
                          child: isProcessing
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.2),
                                )
                              : const Text("Send Verification OTP", style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ]

                    // ==========================================
                    // STEP 2: VERIFY OTP
                    // ==========================================
                    else if (currentStep == 2) ...[
                      TextField(
                        controller: otpCtrl,
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: pText,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 10,
                        ),
                        decoration: InputDecoration(
                          hintText: "••••••",
                          counterText: "",
                          filled: true,
                          fillColor: inputBg,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton.icon(
                            onPressed: () {
                              setModalState(() => currentStep = 1);
                            },
                            icon: const Icon(Icons.arrow_back_rounded, size: 16),
                            label: const Text("Change Contact", style: TextStyle(fontSize: 12)),
                          ),
                          TextButton(
                            onPressed: resendCountdown > 0
                                ? null
                                : () async {
                                    final contact = contactCtrl.text.trim();
                                    final res = await AuthService.sendForgotPasswordOtp(contact: contact);
                                    if (res['success'] == true) {
                                      startCountdown();
                                      _showOtpBanner(
                                        otp: res['otp'] as String,
                                        title: "Resent Password Reset OTP",
                                        recipient: contact,
                                        onAutoFill: () {
                                          otpCtrl.text = res['otp'] as String;
                                          setModalState(() {});
                                        },
                                      );
                                    }
                                  },
                            child: Text(
                              resendCountdown > 0 ? "Resend in ${resendCountdown}s" : "Resend OTP",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: resendCountdown > 0 ? Colors.grey : const Color(0xFF1677FF),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: isProcessing
                              ? null
                              : () async {
                                  final otp = otpCtrl.text.trim();
                                  if (otp.length < 6) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text("Please enter full 6-digit OTP.")),
                                    );
                                    return;
                                  }

                                  setModalState(() => isProcessing = true);
                                  final res = await AuthService.verifyOtp(
                                    contact: contactCtrl.text.trim(),
                                    enteredOtp: otp,
                                  );
                                  setModalState(() => isProcessing = false);

                                  if (res['success'] == true) {
                                    setModalState(() {
                                      currentStep = 3;
                                    });
                                  } else {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text(res['message'] ?? "Invalid OTP.")),
                                      );
                                    }
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF159A8C),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                          ),
                          child: isProcessing
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.2),
                                )
                              : const Text("Verify OTP & Proceed", style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ]

                    // ==========================================
                    // STEP 3: CREATE NEW PASSWORD
                    // ==========================================
                    else if (currentStep == 3) ...[
                      TextField(
                        controller: newPassCtrl,
                        obscureText: obscureNew,
                        style: TextStyle(color: pText),
                        decoration: InputDecoration(
                          labelText: "New Password",
                          prefixIcon: const Icon(Icons.lock_outline_rounded, color: Color(0xFF1677FF)),
                          suffixIcon: IconButton(
                            icon: Icon(obscureNew ? Icons.visibility_off : Icons.visibility),
                            onPressed: () => setModalState(() => obscureNew = !obscureNew),
                          ),
                          filled: true,
                          fillColor: inputBg,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: confirmPassCtrl,
                        obscureText: obscureConfirm,
                        style: TextStyle(color: pText),
                        decoration: InputDecoration(
                          labelText: "Confirm New Password",
                          prefixIcon: const Icon(Icons.lock_reset_rounded, color: Color(0xFF1677FF)),
                          suffixIcon: IconButton(
                            icon: Icon(obscureConfirm ? Icons.visibility_off : Icons.visibility),
                            onPressed: () => setModalState(() => obscureConfirm = !obscureConfirm),
                          ),
                          filled: true,
                          fillColor: inputBg,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: isProcessing
                              ? null
                              : () async {
                                  final newPass = newPassCtrl.text.trim();
                                  final confirmPass = confirmPassCtrl.text.trim();

                                  if (newPass.length < 6) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text("Password must contain at least 6 characters.")),
                                    );
                                    return;
                                  }

                                  if (newPass != confirmPass) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text("Passwords do not match.")),
                                    );
                                    return;
                                  }

                                  setModalState(() => isProcessing = true);
                                  final res = await AuthService.resetPassword(
                                    contact: contactCtrl.text.trim(),
                                    newPassword: newPass,
                                  );
                                  setModalState(() => isProcessing = false);

                                  if (res['success'] == true) {
                                    if (context.mounted) {
                                      Navigator.pop(ctx);
                                      // Pre-fill login fields for immediate ease
                                      emailController.text = contactCtrl.text.trim();
                                      passwordController.text = newPass;
                                      showMessage("Password updated successfully! You can now log in.", success: true);
                                    }
                                  } else {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text(res['message'] ?? "Error resetting password")),
                                      );
                                    }
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1677FF),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                          ),
                          child: isProcessing
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.2),
                                )
                              : const Text("Save New Password", style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],

                    const SizedBox(height: 12),
                  ],
                ),
              ),
            );
          },
        );
      },
    ).whenComplete(() {
      countdownTimer?.cancel();
    });
  }



  // =========================
  // BUILD
  // =========================

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? Colors.white : const Color(0xFF071A2B);
    final secondaryTextColor = isDark ? Colors.white70 : Colors.black54;
    final inputFill = isDark ? const Color(0xFF132A3E) : const Color(0xFFF1F6FB);
    final cardBg = Theme.of(context).cardColor;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: GestureDetector(
          onTap: () {
            FocusScope.of(context).unfocus();
          },
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight,
                  ),
                  child: IntrinsicHeight(
                    child: Column(
                      children: [
                        // ==========================================
                        // TOP HEADER
                        // ==========================================
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.fromLTRB(24, 24, 24, 36),
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
                              bottomLeft: Radius.circular(36),
                              bottomRight: Radius.circular(36),
                            ),
                          ),
                  child: Column(
                    children: [
                      // Logo
                      Container(
                        height: 88,
                        width: 88,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(
                            color: const Color(0xFF18C8C8).withValues(alpha: 0.35),
                            width: 1.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF18C8C8).withValues(alpha: 0.15),
                              blurRadius: 25,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.monitor_heart_rounded,
                          color: Color(0xFF18C8C8),
                          size: 48,
                        ),
                      ),

                      const SizedBox(height: 22),

                      const Text(
                        "AAKRITI",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 29,
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

                      const SizedBox(height: 14),

                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: const Text(
                          "Advanced Diagnostic Centre",
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // ==========================================
                // LOGIN CARD
                // ==========================================
                Transform.translate(
                  offset: const Offset(0, -22),
                  child: Container(
                    width: double.infinity,
                    margin: const EdgeInsets.symmetric(horizontal: 18),
                    padding: const EdgeInsets.fromLTRB(22, 28, 22, 30),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.transparent,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF071A2B).withValues(alpha: isDark ? 0.25 : 0.08),
                          blurRadius: 30,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Welcome Back",
                          style: TextStyle(
                            color: primaryTextColor,
                            fontSize: 27,
                            fontWeight: FontWeight.w800,
                          ),
                        ),

                        const SizedBox(height: 7),

                        Text(
                          "Sign in with your Email & Password to access your reports and appointments.",
                          style: TextStyle(
                            color: secondaryTextColor,
                            fontSize: 13.5,
                            height: 1.5,
                          ),
                        ),

                        const SizedBox(height: 28),

                        // USERNAME / IDENTIFIER LABEL
                        Text(
                          "Email Address",
                          style: TextStyle(
                            color: primaryTextColor,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),

                        const SizedBox(height: 9),

                        // USERNAME / IDENTIFIER FIELD
                        TextField(
                          controller: emailController,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          style: TextStyle(color: primaryTextColor),
                          decoration: InputDecoration(
                            hintText: "Enter your email address (e.g. name@gmail.com)",
                            hintStyle: TextStyle(
                              color: secondaryTextColor.withValues(alpha: 0.6),
                              fontSize: 14,
                            ),
                            prefixIcon: const Icon(
                              Icons.email_outlined,
                              color: Color(0xFF1677FF),
                            ),
                            filled: true,
                            fillColor: inputFill,
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 18,
                              horizontal: 16,
                            ),
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
                              borderSide: const BorderSide(
                                color: Color(0xFF1677FF),
                                width: 1.2,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // PASSWORD LABEL
                        Text(
                          "Password",
                          style: TextStyle(
                            color: primaryTextColor,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),

                        const SizedBox(height: 9),

                        // PASSWORD FIELD
                        TextField(
                          controller: passwordController,
                          obscureText: obscurePassword,
                          textInputAction: TextInputAction.done,
                          style: TextStyle(color: primaryTextColor),
                          onSubmitted: (_) {
                            if (!isLoading) {
                              login();
                            }
                          },
                          decoration: InputDecoration(
                            hintText: "Enter your password",
                            hintStyle: TextStyle(
                              color: secondaryTextColor.withValues(alpha: 0.6),
                              fontSize: 14,
                            ),
                            prefixIcon: const Icon(
                              Icons.lock_outline_rounded,
                              color: Color(0xFF1677FF),
                            ),
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
                            filled: true,
                            fillColor: inputFill,
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 18,
                              horizontal: 16,
                            ),
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
                              borderSide: const BorderSide(
                                color: Color(0xFF1677FF),
                                width: 1.2,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 6),

                        // FORGOT PASSWORD BUTTON (OPENS OTP SHEET)
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: _openForgotPasswordSheet,
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                            ),
                            child: const Text(
                              "Forgot Password? (Get OTP)",
                              style: TextStyle(
                                color: Color(0xFF1677FF),
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        // LOGIN BUTTON
                        SizedBox(
                          width: double.infinity,
                          height: 58,
                          child: ElevatedButton(
                            onPressed: isLoading ? null : login,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1677FF),
                              disabledBackgroundColor: const Color(0xFF8EB8F5),
                              foregroundColor: Colors.white,
                              elevation: 7,
                              shadowColor: const Color(0xFF1677FF).withValues(alpha: 0.28),
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
                                        "Sign In",
                                        style: TextStyle(
                                          fontSize: 16,
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

                        const SizedBox(height: 26),

                        // REGISTER
                        Center(
                          child: Wrap(
                            alignment: WrapAlignment.center,
                            children: [
                              Text(
                                "Don't have an account? ",
                                style: TextStyle(
                                  color: secondaryTextColor,
                                  fontSize: 13.5,
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const RegisterScreen(),
                                    ),
                                  );
                                },
                                child: const Text(
                                  "Create Account",
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

                        // SECURITY NOTE
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(13),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF0F2C3A) : const Color(0xFFF0FAFA),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: const Color(0xFF18C8C8).withValues(alpha: 0.18),
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
                                  "Your health data is protected with secure multi-factor authentication.",
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
      );
    },
  ),
),
),
);
}
}
