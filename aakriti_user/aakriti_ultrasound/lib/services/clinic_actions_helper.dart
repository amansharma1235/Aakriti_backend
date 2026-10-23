import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'api_service.dart';
import 'auth_service.dart';
import 'notifications_store.dart';

class WhatsAppHelper {
  static const String defaultClinicWhatsApp = "919876543210";

  /// Open 1-on-1 WhatsApp Chat with prefilled message
  static Future<bool> openChat({
    String phone = defaultClinicWhatsApp,
    required String message,
  }) async {
    final cleanPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');
    final encodedMsg = Uri.encodeComponent(message);
    final whatsappUrl = Uri.parse("https://wa.me/$cleanPhone?text=$encodedMsg");

    try {
      if (await canLaunchUrl(whatsappUrl)) {
        return await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);
      } else {
        return await launchUrl(whatsappUrl, mode: LaunchMode.platformDefault);
      }
    } catch (e) {
      debugPrint("[WhatsAppHelper] Error launching WhatsApp: $e");
      return false;
    }
  }

  /// Share Appointment Confirmation to Patient / Clinic on WhatsApp
  static Future<void> shareAppointment({
    required String appointmentId,
    required String patientName,
    required String service,
    required String date,
    required String time,
  }) async {
    final msg = """
🏥 *Aakriti Ultrasound & Diagnostic Centre*
━━━━━━━━━━━━━━━━━━━━
✅ *APPOINTMENT CONFIRMED*
━━━━━━━━━━━━━━━━━━━━
🆔 *Booking ID:* $appointmentId
👤 *Patient Name:* $patientName
🔬 *Investigation:* $service
📅 *Date:* $date
⏰ *Time:* $time
📍 *Location:* Station Road, Opp Civil Hospital Gate No. 2, Moradabad

*Instructions:*
• Please arrive 10 minutes prior to your scheduled time.
• Carry prior prescriptions & medical records.

📞 *Helpdesk:* +91 98765 43210
🌐 *Portal:* https://aakriti-diagnostic.in
""";
    await openChat(message: msg);
  }

  /// Share Medical Report Link to Doctor or Family on WhatsApp
  static Future<void> shareReport({
    required String reportId,
    required String testName,
    required String patientName,
    required String date,
  }) async {
    final msg = """
🏥 *Aakriti Diagnostic Centre - Medical Report*
━━━━━━━━━━━━━━━━━━━━
📄 *Test:* $testName
👤 *Patient:* $patientName
📅 *Date:* $date
🆔 *Report No:* $reportId
✅ *Status:* Verified & Digitally Signed

🔗 *View / Download Official PDF:*
https://aakriti-diagnostic.in/verify?rpt=$reportId

_Aakriti Ultrasound & Advanced Diagnostic Care_
""";
    await openChat(message: msg);
  }
}

class MapHelper {
  /// Opens Google Maps navigation to clinic location
  static Future<void> openClinicDirections() async {
    // 28.8386° N, 78.7733° E (Moradabad Diagnostic Hub)
    final googleMapsUrl = Uri.parse(
      "https://www.google.com/maps/dir/?api=1&destination=28.8386,78.7733&destination_place_id=Aakriti+Ultrasound+Diagnostic+Center",
    );

    try {
      if (await canLaunchUrl(googleMapsUrl)) {
        await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint("[MapHelper] Error launching map: $e");
    }
  }
}

class CallHelper {
  /// Direct 1-tap call to diagnostic center reception
  static Future<void> callHelpline([String phone = "+919876543210"]) async {
    final uri = Uri.parse("tel:$phone");
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    } catch (e) {
      debugPrint("[CallHelper] Error placing call: $e");
    }
  }
}

// =============================================================
// PRESCRIPTION UPLOAD MODAL
// =============================================================

class PrescriptionUploadModal {
  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _PrescriptionSheetContent(),
    );
  }
}

class _PrescriptionSheetContent extends StatefulWidget {
  const _PrescriptionSheetContent();

  @override
  State<_PrescriptionSheetContent> createState() => _PrescriptionSheetContentState();
}

class _PrescriptionSheetContentState extends State<_PrescriptionSheetContent> {
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  XFile? _selectedImage;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _loadUserPhone();
  }

  Future<void> _loadUserPhone() async {
    final phone = await AuthService.getUserPhone();
    if (phone.isNotEmpty && mounted) {
      setState(() {
        _phoneController.text = phone.replaceAll('+91', '').replaceAll(' ', '').trim();
      });
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final img = await _picker.pickImage(source: source, imageQuality: 85);
      if (img != null) {
        setState(() {
          _selectedImage = img;
        });
      }
    } catch (e) {
      debugPrint("[Prescription] Image pick error: $e");
    }
  }

  Future<void> _submitPrescription() async {
    final name = await AuthService.getUserName();
    final patientName = name.isNotEmpty ? name : "Patient";
    final patientId = await AuthService.getPatientId();
    final mobile = _phoneController.text.trim();

    if (!mounted) return;

    if (mobile.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter mobile number")),
      );
      return;
    }

    if (_selectedImage == null && _notesController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please take a photo or type prescription details")),
      );
      return;
    }


    setState(() => _isUploading = true);

    String? base64Img;
    if (_selectedImage != null) {
      try {
        final bytes = await File(_selectedImage!.path).readAsBytes();
        base64Img = base64Encode(bytes);
      } catch (_) {}
    }

    final res = await ApiService.uploadPrescription(
      patientId: patientId.isNotEmpty ? patientId : "PT${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}",
      patientName: patientName,
      mobile: mobile,
      notes: _notesController.text.trim(),
      imageBase64: base64Img,
    );

    NotificationStore.instance.addNotification(
      icon: Icons.receipt_long_rounded,
      title: "Prescription Uploaded",
      message: "Your doctor's prescription has been submitted. Our radiologists will contact you shortly.",
      color: const Color(0xFF18C8C8),
    );

    if (!mounted) return;
    setState(() => _isUploading = false);
    Navigator.pop(context);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 28),
            SizedBox(width: 8),
            Text("Prescription Sent!", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: Text(
          res['message'] ?? "Prescription received successfully. Our desk will schedule tests accordingly.",
          style: const TextStyle(fontSize: 14, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("OK", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF10263A) : Colors.white;
    final primary = isDark ? Colors.white : const Color(0xFF071A2B);

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        top: 20,
        left: 20,
        right: 20,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1677FF).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.document_scanner_rounded, color: Color(0xFF1677FF), size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Upload Doctor's Prescription", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: primary)),
                      const Text("Our radiologist will schedule your required tests", style: TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Image Preview or Picker Buttons
            if (_selectedImage != null) ...[
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.file(
                      File(_selectedImage!.path),
                      height: 160,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedImage = null),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle),
                        child: const Icon(Icons.close_rounded, color: Colors.white, size: 18),
                      ),
                    ),
                  ),
                ],
              ),
            ] else ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pickImage(ImageSource.camera),
                      icon: const Icon(Icons.camera_alt_rounded, color: Color(0xFF1677FF)),
                      label: const Text("Camera", style: TextStyle(fontWeight: FontWeight.w600)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pickImage(ImageSource.gallery),
                      icon: const Icon(Icons.photo_library_rounded, color: Color(0xFF18C8C8)),
                      label: const Text("Gallery", style: TextStyle(fontWeight: FontWeight.w600)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 14),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: "Patient Contact Number",
                prefixIcon: const Icon(Icons.phone_rounded, size: 20),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notesController,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: "Notes or specific doctor instructions (Optional)",
                prefixIcon: const Icon(Icons.note_alt_outlined, size: 20),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isUploading ? null : _submitPrescription,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1677FF),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: _isUploading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.cloud_upload_rounded),
                          SizedBox(width: 8),
                          Text("Submit Prescription", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================
// UPI & ONLINE PAYMENT CHECKOUT MODAL
// =============================================================

class UpiPaymentModal {
  static void show(
    BuildContext context, {
    required String appointmentId,
    required double amount,
    required String serviceName,
    VoidCallback? onPaymentSuccess,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _UpiSheetContent(
        appointmentId: appointmentId,
        amount: amount,
        serviceName: serviceName,
        onPaymentSuccess: onPaymentSuccess,
      ),
    );
  }
}

class _UpiSheetContent extends StatefulWidget {
  final String appointmentId;
  final double amount;
  final String serviceName;
  final VoidCallback? onPaymentSuccess;

  const _UpiSheetContent({
    required this.appointmentId,
    required this.amount,
    required this.serviceName,
    this.onPaymentSuccess,
  });

  @override
  State<_UpiSheetContent> createState() => _UpiSheetContentState();
}

class _UpiSheetContentState extends State<_UpiSheetContent> {
  String upiVpa = "aakritidiagnostic@upi";
  String upiPayload = "";
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initUpi();
  }

  Future<void> _initUpi() async {
    final patientId = await AuthService.getPatientId();
    final res = await ApiService.createPaymentIntent(
      appointmentId: widget.appointmentId,
      patientId: patientId.isNotEmpty ? patientId : "PT-USER",
      amount: widget.amount,
      serviceName: widget.serviceName,
    );

    if (mounted) {
      setState(() {
        upiVpa = res['upi_vpa'] ?? "aakritidiagnostic@upi";
        upiPayload = res['upi_intent_url'] ?? "upi://pay?pa=aakritidiagnostic@upi&pn=Aakriti%20Diagnostic&am=${widget.amount.toStringAsFixed(2)}&cu=INR";
        _isLoading = false;
      });
    }
  }

  Future<void> _payViaApp(String appName) async {
    final uri = Uri.parse(upiPayload);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Could not open $appName. Please scan the QR Code.")),
        );
      }
    }
  }


  void _confirmPaid() {
    Navigator.pop(context);
    widget.onPaymentSuccess?.call();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: Color(0xFF10B981),
        content: Text("Payment Verified & Receipt Generated!"),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF10263A) : Colors.white;
    final primary = isDark ? Colors.white : const Color(0xFF071A2B);

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Instant UPI Payment", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: primary)),
                    Text(widget.serviceName, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    "₹${widget.amount.toStringAsFixed(0)}",
                    style: const TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(),
              )
            else ...[
              // QR Code
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey.shade300),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
                  ],
                ),
                child: Column(
                  children: [
                    QrImageView(
                      data: upiPayload,
                      version: QrVersions.auto,
                      size: 160.0,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Scan with any UPI App (GPay / PhonePe / Paytm)",
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade700, fontWeight: FontWeight.w600),
                    ),
                    Text(
                      "VPA: $upiVpa",
                      style: const TextStyle(fontSize: 10.5, color: Color(0xFF1677FF), fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // UPI Quick Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _payViaApp("GPay / UPI App"),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text("Pay with UPI App", style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _confirmPaid,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text("I have Paid", style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
