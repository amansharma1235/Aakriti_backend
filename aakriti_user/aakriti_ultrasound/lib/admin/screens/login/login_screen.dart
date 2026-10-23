import 'package:flutter/material.dart';

import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/admin_shell.dart';

class LoginScreen extends StatefulWidget {
  final bool isFromUserApp;
  const LoginScreen({super.key, this.isFromUserApp = false});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController emailController = TextEditingController();

  final TextEditingController passwordController = TextEditingController();

  bool obscurePassword = true;
  bool rememberMe = true;
  bool isLoading = false;
  String? errorMessage;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  // =========================================================
  // LOGIN
  // =========================================================

  Future<void> login() async {
    if (!mounted) return;

    setState(() {
      errorMessage = null;
    });

    if (!_formKey.currentState!.validate()) return;

    final email = emailController.text.trim().toLowerCase();
    final password = passwordController.text.trim();

    setState(() {
      isLoading = true;
    });

    try {
      final result = await ApiService.adminLogin(
        email: email,
        password: password,
      );

      if (!mounted) return;

      if (result['success'] == true) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => AdminShell(isFromUserApp: widget.isFromUserApp),
          ),
        );
      } else {
        setState(() {
          isLoading = false;
          errorMessage = result['message'] ?? 'Invalid email or password';
        });
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
        errorMessage = 'Unable to connect to backend server.';
      });
    }
  }

  // =========================================================
  // =========================================================
  // FORGOT PASSWORD
  // =========================================================

  void _showForgotPasswordDialog() {
    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => const _ForgotPasswordDialog(),
    );
  }

  // =========================================================
  // BACKEND CONFIG
  // =========================================================

  void _showBackendConfigDialog() {
    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => const _BackendConfigDialog(),
    );
  }

  // =========================================================
  // UI
  // =========================================================

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 600;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,

      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,

            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 20 : 40,
              vertical: 24,
            ),

            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),

              child: Form(
                key: _formKey,

                child: Column(
                  mainAxisSize: MainAxisSize.min,

                  children: [
                    if (widget.isFromUserApp) ...[
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.arrow_back_rounded, size: 18),
                          label: const Text("Back to Patient App", style: TextStyle(fontWeight: FontWeight.w600)),
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFF1677FF),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],

                    // =================================================
                    // LOGO
                    // =================================================

                    Container(
                      width: 80,
                      height: 80,

                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF071A2B), Color(0xFF1677FF)],

                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),

                        borderRadius: BorderRadius.circular(22),

                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF1677FF)
                                .withValues(alpha: 0.28),

                            blurRadius: 20,

                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),

                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(22),

                        child: Image.asset(
                          'assets/image.png',

                          fit: BoxFit.cover,

                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(
                                Icons.local_hospital_rounded,
                                color: Colors.white,
                                size: 44,
                              ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),

                    Text(
                      "AAKRITI",
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                        color: AppTheme.textPrimary(context),
                      ),
                    ),

                    const Text(
                      "ULTRASOUND & DIAGNOSTIC CENTRE",

                      textAlign: TextAlign.center,

                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2,
                        color: Color(0xFF1677FF),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // =================================================
                    // LOGIN CARD
                    // =================================================
                    Container(
                      padding: EdgeInsets.all(isMobile ? 20 : 28),
                      decoration: BoxDecoration(
                        color: AppTheme.cardBg(context),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: AppTheme.border(context)),
                        boxShadow: AppTheme.subtleShadow,
                      ),

                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,

                        children: [
                          // =================================================
                          // TITLE
                          // =================================================

                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,

                            children: [
                              Expanded(
                                child: Text(
                                  "Admin Sign In",
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                    color: AppTheme.textPrimary(context),
                                  ),
                                ),
                              ),

                              IconButton(
                                tooltip: 'Configure Server IP',

                                onPressed: _showBackendConfigDialog,

                                icon: const Icon(
                                  Icons.settings_ethernet_rounded,

                                  color: Color(0xFF64748B),

                                  size: 20,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 4),

                          Text(
                            "Secure access to patient & imaging records",
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondary(context),
                            ),
                          ),

                          const SizedBox(height: 20),

                          // =================================================
                          // ERROR
                          // =================================================
                          if (errorMessage != null) ...[
                            Container(
                              padding: const EdgeInsets.all(12),

                              decoration: BoxDecoration(
                                color: const Color(0xFFFEE2E2),

                                borderRadius: BorderRadius.circular(12),

                                border: Border.all(
                                  color: const Color(0xFFFCA5A5),
                                ),
                              ),

                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,

                                children: [
                                  const Icon(
                                    Icons.error_outline_rounded,

                                    color: Color(0xFFDC2626),

                                    size: 18,
                                  ),

                                  const SizedBox(width: 8),

                                  Expanded(
                                    child: Text(
                                      errorMessage!,

                                      style: const TextStyle(
                                        color: Color(0xFFB91C1C),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 16),
                          ],

                          // =================================================
                          // EMAIL
                          // =================================================
                          TextFormField(
                            controller: emailController,

                            keyboardType: TextInputType.emailAddress,

                            decoration: InputDecoration(
                              labelText: "Admin Email",

                              hintText: "admin@aakriti.com",

                              prefixIcon: const Icon(
                                Icons.mail_outline_rounded,
                                color: Color(0xFF1677FF),
                              ),

                              filled: true,
                              fillColor: AppTheme.inputBg(context),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(
                                  color: AppTheme.border(context),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(
                                  color: AppTheme.border(context),
                                ),
                              ),

                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),

                                borderSide: const BorderSide(
                                  color: Color(0xFF1677FF),
                                  width: 1.8,
                                ),
                              ),
                            ),

                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return "Email is required";
                              }

                              if (!value.contains("@")) {
                                return "Please enter a valid email address";
                              }

                              return null;
                            },
                          ),

                          const SizedBox(height: 16),

                          // =================================================
                          // PASSWORD
                          // =================================================
                          TextFormField(
                            controller: passwordController,

                            obscureText: obscurePassword,

                            decoration: InputDecoration(
                              labelText: "Password",

                              hintText: "Enter admin password",

                              prefixIcon: const Icon(
                                Icons.lock_outline_rounded,
                                color: Color(0xFF1677FF),
                              ),

                              suffixIcon: IconButton(
                                onPressed: () {
                                  if (!mounted) return;

                                  setState(() {
                                    obscurePassword = !obscurePassword;
                                  });
                                },

                                icon: Icon(
                                  obscurePassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,

                                  color: const Color(0xFF64748B),

                                  size: 20,
                                ),
                              ),

                              filled: true,
                              fillColor: AppTheme.inputBg(context),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(
                                  color: AppTheme.border(context),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(
                                  color: AppTheme.border(context),
                                ),
                              ),

                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),

                                borderSide: const BorderSide(
                                  color: Color(0xFF1677FF),
                                  width: 1.8,
                                ),
                              ),
                            ),

                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return "Password is required";
                              }

                              if (value.length < 4) {
                                return "Password must be at least 4 characters";
                              }

                              return null;
                            },
                          ),

                          const SizedBox(height: 10),

                          // =================================================
                          // REMEMBER + FORGOT PASSWORD
                          // =================================================
                          SizedBox(
                            width: double.infinity,
                            child: Wrap(
                              alignment: WrapAlignment.spaceBetween,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              runSpacing: 4,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: Checkbox(
                                        value: rememberMe,
                                        activeColor: const Color(0xFF1677FF),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(5),
                                        ),
                                        onChanged: (val) {
                                          if (!mounted) return;
                                          setState(() {
                                            rememberMe = val ?? true;
                                          });
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      "Remember",
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppTheme.textSecondary(context),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),

                                // FORGOT PASSWORD
                                TextButton(
                                  onPressed: _showForgotPasswordDialog,
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                    ),
                                  ),
                                  child: const Text(
                                    "Forgot Password?",
                                    style: TextStyle(
                                      color: Color(0xFF1677FF),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 18),

                          // =================================================
                          // LOGIN BUTTON
                          // =================================================
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              onPressed: isLoading ? null : login,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1677FF),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: isLoading
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            "Access Admin Dashboard",
                                            style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          SizedBox(width: 8),
                                          Icon(
                                            Icons.arrow_forward_rounded,
                                            size: 18,
                                          ),
                                        ],
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 22),

                    // =================================================
                    // SECURITY FOOTER
                    // =================================================
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,

                      children: [
                        Icon(
                          Icons.verified_user_rounded,
                          size: 15,
                          color: Color(0xFF10B981),
                        ),

                        SizedBox(width: 6),

                        Flexible(
                          child: Text(
                            "256-Bit Encrypted Healthcare Portal",

                            textAlign: TextAlign.center,

                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF64748B),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// =============================================================
// SAFE FORGOT PASSWORD DIALOG (NO CONTROLLER LEAK OR POP CRASH)
// =============================================================
class _ForgotPasswordDialog extends StatefulWidget {
  const _ForgotPasswordDialog();

  @override
  State<_ForgotPasswordDialog> createState() => _ForgotPasswordDialogState();
}

class _ForgotPasswordDialogState extends State<_ForgotPasswordDialog> {
  late final TextEditingController _emailController;
  bool _isSending = false;
  String? _statusMsg;
  bool _isSuccess = false;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() {
        _statusMsg = 'Please enter a valid email address';
        _isSuccess = false;
      });
      return;
    }

    setState(() {
      _isSending = true;
      _statusMsg = null;
    });

    final res = await ApiService.adminForgotPassword(email: email);

    if (!mounted) return;

    setState(() {
      _isSending = false;
      _isSuccess = res['success'] == true;
      _statusMsg = res['message'] ?? 'Password reset request processed.';
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      scrollable: true,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Row(
        children: [
          Icon(Icons.lock_reset_rounded, color: Color(0xFF1677FF), size: 26),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Forgot Password',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 19),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Enter your registered admin email address to restore credentials.',
            style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: 'Admin Email',
              hintText: 'admin@aakriti.com',
              prefixIcon: const Icon(Icons.email_outlined, color: Color(0xFF1677FF), size: 20),
              filled: true,
              fillColor: AppTheme.inputBg(context),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          if (_statusMsg != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _isSuccess ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _isSuccess ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _isSuccess ? Icons.check_circle_outline : Icons.error_outline,
                    color: _isSuccess ? const Color(0xFF059669) : const Color(0xFFDC2626),
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _statusMsg!,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _isSuccess ? const Color(0xFF047857) : const Color(0xFFB91C1C),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(_isSuccess ? 'Close' : 'Cancel'),
        ),
        if (!_isSuccess)
          ElevatedButton(
            onPressed: _isSending ? null : _handleSubmit,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1677FF),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: _isSending
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Reset Access', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
      ],
    );
  }
}

// =============================================================
// SAFE BACKEND CONFIG DIALOG
// =============================================================
class _BackendConfigDialog extends StatefulWidget {
  const _BackendConfigDialog();

  @override
  State<_BackendConfigDialog> createState() => _BackendConfigDialogState();
}

class _BackendConfigDialogState extends State<_BackendConfigDialog> {
  late final TextEditingController _ipController;

  @override
  void initState() {
    super.initState();
    _ipController = TextEditingController(text: ApiService.baseUrl);
  }

  @override
  void dispose() {
    _ipController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      scrollable: true,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        'Backend Server URL',
        style: TextStyle(fontWeight: FontWeight.w800, color: AppTheme.textPrimary(context)),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Enter your FastAPI backend URL (e.g. http://127.0.0.1:8000).',
            style: TextStyle(fontSize: 12, color: AppTheme.textSecondary(context)),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _ipController,
            keyboardType: TextInputType.url,
            decoration: InputDecoration(
              labelText: 'Backend URL',
              prefixIcon: const Icon(Icons.dns_outlined, color: Color(0xFF1677FF)),
              filled: true,
              fillColor: AppTheme.inputBg(context),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            final url = _ipController.text.trim();
            if (url.isNotEmpty) {
              ApiService.baseUrl = url;
              ApiService.checkHealth();
            }
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Backend URL set to ${ApiService.baseUrl}'),
                backgroundColor: const Color(0xFF1677FF),
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1677FF),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: const Text('Save & Test', style: TextStyle(fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }
}
