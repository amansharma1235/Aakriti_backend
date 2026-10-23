import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

class CommunicationService {
  /// Format standard WhatsApp direct URL
  static String getWhatsAppUrl({
    required String mobile,
    required String message,
  }) {
    String cleanMobile = mobile.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanMobile.length == 10) {
      cleanMobile = '91$cleanMobile';
    }
    final encodedMessage = Uri.encodeComponent(message);
    return 'https://wa.me/$cleanMobile?text=$encodedMessage';
  }

  /// Template for Patient Appointment Confirmation
  static String buildAppointmentWhatsAppMessage({
    required String patientName,
    required String appointmentId,
    required String testName,
    required String doctorName,
    required String date,
    required String time,
  }) {
    return '''🏥 *AAKRITI ULTRASOUND & DIAGNOSTIC CENTER*
------------------------------------------------
Dear *$patientName*,
Your appointment has been confirmed!

📋 *Appointment Details:*
• *Token / ID:* $appointmentId
• *Test / Procedure:* $testName
• *Consultant:* $doctorName
• *Date:* $date
• *Time:* $time

📍 *Location:* Main Road, Lar, Deoria (U.P.)
📞 *Helpline:* +91 9519701963

⚠️ *Instructions:* Please arrive 15 minutes before your scheduled slot. For abdominal scans, please follow fasting / hydration guidelines as advised.
Thank you for trusting Aakriti Diagnostics!''';
  }

  /// Template for Diagnostic Report Ready notification
  static String buildReportReadyWhatsAppMessage({
    required String patientName,
    required String reportId,
    required String testName,
    required String date,
  }) {
    return '''🔬 *AAKRITI ULTRASOUND & DIAGNOSTIC CENTER*
------------------------------------------------
Dear *$patientName*,
Your investigation report for *$testName* is now READY!

📄 *Report Summary:*
• *Report No:* $reportId
• *Investigation:* $testName
• *Exam Date:* $date
• *Status:* Verified & Digitally Signed

📲 You can collect your printed report and films directly from our reception counter or view it online using your Patient ID.

📞 *Need help?* Call us at +91 9519701963
Wishing you good health!''';
  }

  /// Template for Payment / Bill Invoice Receipt
  static String buildPaymentReceiptWhatsAppMessage({
    required String patientName,
    required String receiptId,
    required String testName,
    required double totalAmount,
    required double paidAmount,
    required double balanceDue,
    required String paymentMode,
    required String date,
  }) {
    return '''💳 *AAKRITI ULTRASOUND & DIAGNOSTIC CENTER*
------------------------------------------------
*Official Payment Receipt*

Dear *$patientName*,
We have received your payment. Details are as follows:

🧾 *Receipt No:* $receiptId
🧪 *Investigation:* $testName
💰 *Total Bill:* ₹${totalAmount.toStringAsFixed(2)}
✅ *Paid Amount:* ₹${paidAmount.toStringAsFixed(2)}
${balanceDue > 0 ? '⚠️ *Balance Due:* ₹${balanceDue.toStringAsFixed(2)}\n' : '🎉 *Status:* FULLY PAID\n'}• *Payment Mode:* $paymentMode
• *Date:* $date

Thank you! For billing queries, contact our accounts desk at +91 9519701963.''';
  }

  /// Copy text to clipboard
  static Future<void> copyToClipboard(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
  }

  /// Share message or text using system share sheet
  static Future<void> shareMessage(String message, {String? subject}) async {
    await SharePlus.instance.share(
      ShareParams(
        text: message,
        subject: subject ?? 'Aakriti Diagnostic Center Notification',
      ),
    );
  }
}
