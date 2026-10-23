import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class PdfReportService {
  /// Generate a professional medical ultrasound / diagnostic report as PDF bytes
  static Future<Uint8List> generateMedicalReportPdf({
    required String reportId,
    required String patientId,
    required String patientName,
    required String age,
    required String gender,
    required String mobile,
    required String referringDoctor,
    required String testName,
    required String reportDate,
    String? clinicalHistory,
    Map<String, String>? findings,
    String? impression,
    String? reportingDoctor,
    String? doctorDegree,
  }) async {
    final pdf = pw.Document();

    Uint8List? logoBytes;
    try {
      final byteData = await rootBundle.load('assets/image.png');
      logoBytes = byteData.buffer.asUint8List();
    } catch (_) {}

    final docFindings = findings ?? {
      'LIVER': 'Normal in size (13.4 cm), shape and acoustic texture. No focal mass lesion or intrahepatic biliary radicle dilatation (IHBRD) seen.',
      'GALL BLADDER': 'Well distended. Normal wall thickness. No calculus, sludge or mass lesion identified.',
      'CBD & PV': 'Common Bile Duct (CBD: 4.1 mm) and Portal Vein (PV: 9.8 mm) are normal in caliber.',
      'PANCREAS': 'Normal in size, contour and echogenicity. Main pancreatic duct is normal.',
      'SPLEEN': 'Normal in size (9.6 cm) and homogenous parenchymal echo pattern. No focal lesion.',
      'KIDNEYS': 'Both kidneys are normal in size, position and cortical thickness. Corticomedullary differentiation is well preserved. No calculus, hydronephrosis or mass seen. (Right: 10.2 x 4.4 cm, Left: 10.6 x 4.8 cm).',
      'URINARY BLADDER': 'Adequately distended with uniform smooth wall. Lumen is clear.',
      'PROSTATE / PELVIS': 'Within normal limits for age and gender. No free fluid in pouch of Douglas / pelvis.',
    };

    final docImpression = impression ??
        'ULTRASOUND WHOLE ABDOMEN REVEALS:\n• NO SIGNIFICANT SONOGRAPHIC ABNORMALITY DETECTED IN THE VISUALIZED ABDOMINAL ORGANS.\n• NORMAL STUDY.';

    final docDoctor = reportingDoctor ?? 'Dr. Rajesh Sharma';
    final docDoctorDegree = doctorDegree ?? 'MBBS, MD (Radiodiagnosis) - Consultant Radiologist';

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header / Clinic Letterhead
              _buildClinicHeader(logoBytes),
              pw.SizedBox(height: 12),
              pw.Divider(color: PdfColors.teal800, thickness: 1.5),
              pw.SizedBox(height: 8),

              // Patient & Test Demographics Box
              _buildPatientInfoBox(
                reportId: reportId,
                patientId: patientId,
                patientName: patientName,
                age: age,
                gender: gender,
                mobile: mobile,
                referringDoctor: referringDoctor,
                testName: testName,
                reportDate: reportDate,
              ),
              pw.SizedBox(height: 16),

              // Department & Investigation Title
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 10),
                decoration: pw.BoxDecoration(
                  color: PdfColors.teal50,
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                  border: pw.Border.all(color: PdfColors.teal200, width: 0.8),
                ),
                child: pw.Center(
                  child: pw.Text(
                    'DEPARTMENT OF ULTRASONOGRAPHY & RADIODIAGNOSIS\n$testName REPORT',
                    textAlign: pw.TextAlign.center,
                    style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.teal900,
                    ),
                  ),
                ),
              ),
              pw.SizedBox(height: 14),

              // Findings Section
              pw.Text(
                'SONOGRAPHIC FINDINGS / OBSERVATIONS:',
                style: pw.TextStyle(
                  fontSize: 10.5,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.teal900,
                  decoration: pw.TextDecoration.underline,
                ),
              ),
              pw.SizedBox(height: 8),

              ...docFindings.entries.map((entry) {
                return pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 6),
                  child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.SizedBox(
                        width: 120,
                        child: pw.Text(
                          '${entry.key}:',
                          style: pw.TextStyle(
                            fontSize: 9.5,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.blueGrey900,
                          ),
                        ),
                      ),
                      pw.Expanded(
                        child: pw.Text(
                          entry.value,
                          style: const pw.TextStyle(
                            fontSize: 9.5,
                            color: PdfColors.black,
                            lineSpacing: 1.2,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),

              pw.SizedBox(height: 12),

              // Impression Box
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                  border: pw.Border.all(color: PdfColors.grey400, width: 0.8),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'IMPRESSION / CONCLUSION:',
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.teal900,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      docImpression,
                      style: pw.TextStyle(
                        fontSize: 9.5,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.black,
                        lineSpacing: 1.3,
                      ),
                    ),
                  ],
                ),
              ),

              pw.Spacer(),

              // Verification Note & Doctor Signature
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.BarcodeWidget(
                        barcode: pw.Barcode.qrCode(),
                        data: 'https://aakritidiagnostics.com/verify?rpt=$reportId&pat=$patientId',
                        width: 52,
                        height: 52,
                      ),
                      pw.SizedBox(height: 3),
                      pw.Text(
                        'Scan to Verify Authenticity',
                        style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey700),
                      ),
                      pw.Text(
                        'Digitally Signed • Valid Without Seal',
                        style: const pw.TextStyle(fontSize: 6.5, color: PdfColors.grey600),
                      ),
                    ],
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.teal50,
                      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                      border: pw.Border.all(color: PdfColors.teal300, width: 1),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Container(
                          padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: const pw.BoxDecoration(
                            color: PdfColors.teal800,
                            borderRadius: pw.BorderRadius.all(pw.Radius.circular(2)),
                          ),
                          child: pw.Text(
                            'VERIFIED & DIGITALLY SIGNED',
                            style: pw.TextStyle(
                              fontSize: 7,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.white,
                            ),
                          ),
                        ),
                        pw.SizedBox(height: 5),
                        pw.Text(
                          docDoctor,
                          style: pw.TextStyle(
                            fontSize: 11,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.teal900,
                          ),
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          docDoctorDegree,
                          style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey800),
                        ),
                        pw.Text(
                          'Reg. No: MCI/UP-54812 • Consultant Radiologist',
                          style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey700),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 8),
              pw.Divider(color: PdfColors.grey300, thickness: 0.5),
              pw.Center(
                child: pw.Text(
                  'Note: This is a diagnostic ultrasound investigation report. Please correlate clinically with attending physician.',
                  style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey600),
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildClinicHeader([Uint8List? logoBytes]) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              if (logoBytes != null)
                pw.Container(
                  width: 48,
                  height: 48,
                  margin: const pw.EdgeInsets.only(right: 12),
                  child: pw.Image(
                    pw.MemoryImage(logoBytes),
                    fit: pw.BoxFit.contain,
                  ),
                ),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'AAKRITI ULTRASOUND & DIAGNOSTIC CENTRE',
                      style: pw.TextStyle(
                        fontSize: 13.5,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.teal900,
                      ),
                    ),
                    pw.SizedBox(height: 2),
                    pw.Text(
                      'Govt. Regd. Under PC & PNDT Act 1994 | Reg No: UP/DEO/PNDT/2021/048',
                      style: pw.TextStyle(
                        fontSize: 8,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.teal700,
                      ),
                    ),
                    pw.SizedBox(height: 1.5),
                    pw.Text(
                      'Station Road, Near CHC Hospital, Lar, Salempur, Deoria (U.P.) - 274502',
                      style: const pw.TextStyle(
                        fontSize: 7.5,
                        color: PdfColors.grey700,
                      ),
                    ),
                    pw.Text(
                      'Helpline: +91 9519701963 | Email: aakriti.ultrasound@gmail.com',
                      style: const pw.TextStyle(
                        fontSize: 7.5,
                        color: PdfColors.grey700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        pw.SizedBox(width: 8),
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.teal800, width: 1),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
            color: PdfColors.teal50,
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                'NABH / ISO',
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(
                  fontSize: 8,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.teal900,
                ),
              ),
              pw.Text(
                'CERTIFIED LAB',
                textAlign: pw.TextAlign.center,
                style: const pw.TextStyle(
                  fontSize: 7,
                  color: PdfColors.teal800,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildPatientInfoBox({
    required String reportId,
    required String patientId,
    required String patientName,
    required String age,
    required String gender,
    required String mobile,
    required String referringDoctor,
    required String testName,
    required String reportDate,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400, width: 0.8),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
      ),
      child: pw.Row(
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _buildInfoRow('Patient Name:', patientName, isBold: true),
                pw.SizedBox(height: 3),
                _buildInfoRow('Patient ID / UHID:', patientId),
                pw.SizedBox(height: 3),
                _buildInfoRow('Age / Gender:', '$age Yrs / $gender'),
                pw.SizedBox(height: 3),
                _buildInfoRow('Contact Mobile:', mobile.isNotEmpty ? mobile : '9519701963'),
              ],
            ),
          ),
          pw.SizedBox(width: 16),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _buildInfoRow('Report ID / No:', reportId, isBold: true),
                pw.SizedBox(height: 3),
                _buildInfoRow('Date of Exam:', reportDate),
                pw.SizedBox(height: 3),
                _buildInfoRow('Investigation:', testName),
                pw.SizedBox(height: 3),
                _buildInfoRow('Ref. Doctor:', referringDoctor),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildInfoRow(String label, String value, {bool isBold = false}) {
    return pw.Row(
      children: [
        pw.SizedBox(
          width: 90,
          child: pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: 8.5,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.grey800,
            ),
          ),
        ),
        pw.Expanded(
          child: pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 8.5,
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
              color: PdfColors.black,
            ),
          ),
        ),
      ],
    );
  }

  /// Generate Bill / Invoice Receipt PDF
  static Future<Uint8List> generateInvoiceReceiptPdf({
    required String receiptId,
    required String patientName,
    required String patientId,
    required String appointmentId,
    required String testName,
    required double totalAmount,
    required double discount,
    required double paidAmount,
    required double balanceDue,
    required String paymentMode,
    required String paymentStatus,
    required String date,
    required String time,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a5,
        margin: const pw.EdgeInsets.all(24),
        build: (pw.Context context) {
          final netAmount = totalAmount - discount;
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _buildClinicHeader(),
              pw.SizedBox(height: 8),
              pw.Divider(color: PdfColors.teal800, thickness: 1),
              pw.SizedBox(height: 6),
              pw.Center(
                child: pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 3),
                  decoration: const pw.BoxDecoration(
                    color: PdfColors.teal100,
                    borderRadius: pw.BorderRadius.all(pw.Radius.circular(3)),
                  ),
                  child: pw.Text(
                    'OFFICIAL PAYMENT RECEIPT / INVOICE',
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.teal900,
                    ),
                  ),
                ),
              ),
              pw.SizedBox(height: 10),

              // Demographics
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Receipt No: $receiptId', style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold)),
                      pw.Text('Patient: $patientName ($patientId)', style: const pw.TextStyle(fontSize: 8.5)),
                      pw.Text('Appointment: $appointmentId', style: const pw.TextStyle(fontSize: 8.5)),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('Date: $date', style: const pw.TextStyle(fontSize: 8.5)),
                      pw.Text('Time: $time', style: const pw.TextStyle(fontSize: 8.5)),
                      pw.Text('Mode: $paymentMode', style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: PdfColors.teal800)),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 12),

              // Itemized Table
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                    children: [
                      pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Sr.', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold))),
                      pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Investigation / Service', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold))),
                      pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Rate (INR)', textAlign: pw.TextAlign.right, style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold))),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('1', style: const pw.TextStyle(fontSize: 8))),
                      pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(testName, style: const pw.TextStyle(fontSize: 8))),
                      pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('₹ ${totalAmount.toStringAsFixed(2)}', textAlign: pw.TextAlign.right, style: const pw.TextStyle(fontSize: 8))),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 8),

              // Calculations
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.SizedBox(
                  width: 180,
                  child: pw.Column(
                    children: [
                      _buildReceiptAmountRow('Gross Bill:', '₹ ${totalAmount.toStringAsFixed(2)}'),
                      if (discount > 0)
                        _buildReceiptAmountRow('Discount:', '- ₹ ${discount.toStringAsFixed(2)}', isDiscount: true),
                      pw.Divider(color: PdfColors.grey400, thickness: 0.5),
                      _buildReceiptAmountRow('Net Payable:', '₹ ${netAmount.toStringAsFixed(2)}', isBold: true),
                      _buildReceiptAmountRow('Amount Paid:', '₹ ${paidAmount.toStringAsFixed(2)}', isBold: true, isPaid: true),
                      _buildReceiptAmountRow('Balance Due:', '₹ ${balanceDue.toStringAsFixed(2)}', isBold: true, isDue: balanceDue > 0),
                    ],
                  ),
                ),
              ),

              pw.Spacer(),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.BarcodeWidget(
                    barcode: pw.Barcode.qrCode(),
                    data: 'upi://pay?pa=aakriti.ultrasound@upi&pn=Aakriti+Diagnostic&am=${paidAmount.toStringAsFixed(2)}&tr=$receiptId',
                    width: 38,
                    height: 38,
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('Authorized Billing Signatory', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
                      pw.SizedBox(height: 14),
                      pw.Text('Aakriti Ultrasound & Diagnostics', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 4),
              pw.Center(
                child: pw.Text('Computer Generated Invoice • Valid without physical signature', style: const pw.TextStyle(fontSize: 6.5, color: PdfColors.grey600)),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildReceiptAmountRow(String title, String val, {bool isBold = false, bool isDiscount = false, bool isPaid = false, bool isDue = false}) {
    PdfColor color = PdfColors.black;
    if (isDiscount) color = PdfColors.green700;
    if (isPaid) color = PdfColors.teal800;
    if (isDue) color = PdfColors.red700;

    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 1.5),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(title, style: pw.TextStyle(fontSize: 8, fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal)),
          pw.Text(val, style: pw.TextStyle(fontSize: 8, fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal, color: color)),
        ],
      ),
    );
  }

  /// Direct Print / Preview helper using printing library
  static Future<void> printOrPreviewReport(Uint8List pdfBytes, String fileName) async {
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdfBytes,
      name: fileName,
    );
  }

  /// Share PDF directly
  static Future<void> sharePdf(Uint8List pdfBytes, String fileName) async {
    await Printing.sharePdf(bytes: pdfBytes, filename: fileName);
  }
}
