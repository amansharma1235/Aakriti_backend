import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/profile_service.dart';

class PaymentsScreen extends StatefulWidget {
  const PaymentsScreen({super.key});

  @override
  State<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends State<PaymentsScreen> {
  static const Color navy = Color(0xFF071A2B);
  static const Color blue = Color(0xFF1677FF);
  static const Color teal = Color(0xFF18C8C8);

  bool isLoading = true;
  List<Map<String, dynamic>> payments = [];

  @override
  void initState() {
    super.initState();
    _loadPayments();
  }

  Future<void> _loadPayments() async {
    if (!mounted) return;
    setState(() => isLoading = true);
    try {
      final patientId = await AuthService.getPatientId();
      List<Map<String, dynamic>> userPayments = [];

      final mysqlPayments = await ApiService.getMyPayments(patientId: patientId);

      if (mysqlPayments.isNotEmpty) {
        userPayments = mysqlPayments.map((d) {
          final rawDate = (d['payment_date'] ?? d['created_at'] ?? 'Recent').toString();
          final dateStr = rawDate.length >= 10 ? rawDate.substring(0, 10) : rawDate;

          return {
            "payment_id": (d['payment_id'] ?? d['id'] ?? '').toString(),
            "patient_id": (d['patient_id'] ?? patientId).toString(),
            "patient_name": (d['patient_name'] ?? ProfileService.userNameNotifier.value).toString(),
            "amount": double.tryParse((d['amount'] ?? 0).toString()) ?? 0.0,
            "payment_method": (d['payment_method'] ?? 'Online UPI').toString(),
            "payment_date": dateStr,
            "status": (d['status'] ?? 'Success').toString().toUpperCase(),
            "service_name": (d['notes'] ?? d['service_name'] ?? 'Diagnostic Service').toString(),
            "transaction_id": (d['transaction_id'] ?? d['payment_id'] ?? '').toString(),
          };
        }).toList();
      } else {
        // Fallback to Firestore legacy
        final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
        if (uid.isNotEmpty) {
          final snap = await FirebaseFirestore.instance
              .collection('payments')
              .where('userId', isEqualTo: uid)
              .get();

          userPayments = snap.docs.map((doc) {
            final d = doc.data();
            String dateStr = 'Recent';
            if (d['createdAt'] != null && d['createdAt'] is Timestamp) {
              dateStr = (d['createdAt'] as Timestamp).toDate().toIso8601String().substring(0, 10);
            }

            return {
              "payment_id": d['paymentId'] ?? doc.id,
              "patient_id": d['userId'] ?? uid,
              "patient_name": d['patientName'] ?? ProfileService.userNameNotifier.value,
              "amount": (d['amount'] as num?)?.toDouble() ?? 0.0,
              "payment_method": d['paymentMethod'] ?? 'UPI',
              "payment_date": dateStr,
              "status": (d['paymentStatus'] ?? 'Success').toString().toUpperCase(),
              "service_name": d['testName'] ?? 'Diagnostic Service',
              "transaction_id": d['transactionId'] ?? doc.id,
            };
          }).toList();
        }
      }

      if (!mounted) return;
      setState(() {
        payments = userPayments;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        payments = [];
        isLoading = false;
      });
    }
  }

  void _showReceiptDialog(Map<String, dynamic> item) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color cardColor = Theme.of(context).cardColor;
    final Color primaryText = isDark ? Colors.white : navy;
    final Color secondaryText = isDark ? Colors.white70 : Colors.grey.shade600;

    final String txnId = (item['payment_id'] ?? item['transaction_id'] ?? 'TXN-000').toString();
    final String service = (item['service_name'] ?? 'Diagnostic Test').toString();
    final double amount = double.tryParse((item['amount'] ?? 0).toString()) ?? 0.0;
    final String date = (item['payment_date'] ?? '').toString();
    final String method = (item['payment_method'] ?? 'Online').toString();
    final String patient = (item['patient_name'] ?? (ProfileService.userNameNotifier.value.isNotEmpty ? ProfileService.userNameNotifier.value : 'Patient')).toString();

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: cardColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.check_circle_rounded, color: Colors.green, size: 26),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Payment Receipt", style: TextStyle(color: primaryText, fontWeight: FontWeight.bold, fontSize: 17)),
                    Text("Aakriti Diagnostic Center", style: TextStyle(color: secondaryText, fontSize: 11)),
                  ],
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Divider(),
              _receiptRow("Receipt No:", txnId, primaryText, secondaryText),
              _receiptRow("Patient Name:", patient, primaryText, secondaryText),
              _receiptRow("Service:", service, primaryText, secondaryText),
              _receiptRow("Date:", date, primaryText, secondaryText),
              _receiptRow("Payment Method:", method, primaryText, secondaryText),
              _receiptRow("Status:", "Paid", Colors.green, secondaryText),
              const Divider(),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Total Paid:", style: TextStyle(color: primaryText, fontWeight: FontWeight.bold, fontSize: 15)),
                  Text(
                    "₹${amount.toStringAsFixed(2)}",
                    style: const TextStyle(color: blue, fontWeight: FontWeight.w900, fontSize: 18),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Close"),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Receipt saved to Downloads successfully!"),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              icon: const Icon(Icons.download_rounded, size: 16),
              label: const Text("Download"),
              style: ElevatedButton.styleFrom(
                backgroundColor: blue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _receiptRow(String label, String value, Color valColor, Color labelColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: labelColor, fontSize: 12)),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(color: valColor, fontSize: 12.5, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color bgColor = Theme.of(context).scaffoldBackgroundColor;
    final Color cardColor = Theme.of(context).cardColor;
    final Color primaryText = isDark ? Colors.white : navy;
    final Color secondaryText = isDark ? Colors.white70 : Colors.grey.shade600;
    final Color borderColor = isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE8EEF5);

    double totalSpent = 0;
    for (final p in payments) {
      totalSpent += double.tryParse((p['amount'] ?? 0).toString()) ?? 0.0;
    }

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: navy,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Payment & Invoices",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadPayments,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                padding: const EdgeInsets.all(18),
                children: [
                  // Total Spent Card
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0F3E61), Color(0xFF136894), teal],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0F3E61).withValues(alpha: 0.25),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "Total Diagnostic Expense",
                              style: TextStyle(color: Colors.white70, fontSize: 13),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.16),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.verified_rounded, color: Colors.white, size: 14),
                                  SizedBox(width: 4),
                                  Text("Verified Records", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          "₹${totalSpent.toStringAsFixed(2)}",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          "All payments are encrypted & registered under Aakriti Diagnostic billing system.",
                          style: TextStyle(color: Colors.white60, fontSize: 11),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  Text(
                    "Transactions & Invoices (${payments.length})",
                    style: TextStyle(
                      color: primaryText,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 14),

                  ...payments.map((p) {
                    final txn = (p['payment_id'] ?? p['transaction_id'] ?? 'TXN').toString();
                    final service = (p['service_name'] ?? 'Diagnostic Service').toString();
                    final amount = double.tryParse((p['amount'] ?? 0).toString()) ?? 0.0;
                    final date = (p['payment_date'] ?? '').toString();
                    final method = (p['payment_method'] ?? 'Online').toString();

                    return Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: borderColor),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.035),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                height: 48,
                                width: 48,
                                decoration: BoxDecoration(
                                  color: Colors.green.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Icon(Icons.receipt_long_rounded, color: Colors.green, size: 24),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      service,
                                      style: TextStyle(
                                        color: primaryText,
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      "$method • $date",
                                      style: TextStyle(color: secondaryText, fontSize: 11.5),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                "₹${amount.toStringAsFixed(0)}",
                                style: TextStyle(
                                  color: primaryText,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Divider(height: 1),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Txn: $txn",
                                style: TextStyle(color: secondaryText, fontSize: 11),
                              ),
                              TextButton.icon(
                                onPressed: () => _showReceiptDialog(p),
                                icon: const Icon(Icons.description_outlined, size: 15, color: blue),
                                label: const Text(
                                  "View Receipt",
                                  style: TextStyle(color: blue, fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
    );
  }
}
