import 'package:flutter/material.dart';
import 'package:aakriti_ultrasound/admin/services/communication_service.dart';
import 'package:aakriti_ultrasound/admin/screens/services/api_service.dart';
import 'package:aakriti_ultrasound/admin/theme/app_colors.dart';
import '../../../widgets/whatsapp_logo.dart';

class AppointmentDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> appointmentData;

  const AppointmentDetailsScreen({
    super.key,
    required this.appointmentData,
  });

  @override
  State<AppointmentDetailsScreen> createState() => _AppointmentDetailsScreenState();
}

class _AppointmentDetailsScreenState extends State<AppointmentDetailsScreen> {
  late Map<String, dynamic> _appointment;

  @override
  void initState() {
    super.initState();
    _appointment = Map<String, dynamic>.from(widget.appointmentData);
  }

  void _sendWhatsAppConfirmation() {
    final patientName = _appointment['patientName'] ?? _appointment['patient_name'] ?? 'Patient';
    final token = _appointment['id'] ?? _appointment['appointment_id'] ?? 'APT';
    final testName = _appointment['testName'] ?? _appointment['service_name'] ?? 'Ultrasound';
    final doctor = _appointment['doctor'] ?? _appointment['doctor_name'] ?? 'Dr. S. K. Sharma';
    final date = _appointment['date'] ?? _appointment['appointment_date'] ?? 'Today';
    final time = _appointment['time'] ?? _appointment['time_slot'] ?? '10:00 AM';
    final mobile = _appointment['mobile'] ?? '9519701963';

    final message = CommunicationService.buildAppointmentWhatsAppMessage(
      patientName: patientName,
      appointmentId: token,
      testName: testName,
      doctorName: doctor,
      date: date,
      time: time,
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF25D366).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.mark_chat_unread_rounded, color: Color(0xFF25D366), size: 22),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'WhatsApp Alert',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 380,
            maxHeight: MediaQuery.of(context).size.height * 0.42,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Patient: $patientName (+91 $mobile)',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.lightTextSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFBBF7D0)),
                  ),
                  child: Text(
                    message,
                    style: const TextStyle(fontSize: 12, height: 1.4, fontFamily: 'monospace', color: Colors.black87),
                  ),
                ),
              ],
            ),
          ),
        ),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          OutlinedButton.icon(
            onPressed: () {
              CommunicationService.copyToClipboard(message);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Message copied to clipboard!'),
                  backgroundColor: AppColors.accentTeal,
                ),
              );
            },
            icon: const Icon(Icons.copy_rounded, size: 15),
            label: const Text('Copy'),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF25D366),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              CommunicationService.shareMessage(message, subject: 'Appointment Confirmation');
              Navigator.pop(ctx);
            },
            icon: const Icon(Icons.share_rounded, size: 15),
            label: const Text('Send'),
          ),
        ],
      ),
    );
  }

  void _showStatusDialog() {
    final currentStatus = _appointment['status'] ?? 'Scheduled';
    final statuses = ['Scheduled', 'Confirmed', 'In-Progress', 'Completed', 'Cancelled'];

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Update Status'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: statuses.map((status) {
            return ListTile(
              title: Text(status),
              leading: Icon(
                status == currentStatus ? Icons.check_circle : Icons.circle_outlined,
                color: status == currentStatus ? AppColors.accentTeal : Colors.grey,
              ),
              onTap: () async {
                Navigator.pop(ctx);
                setState(() {
                  _appointment['status'] = status;
                });
                final dbId = _appointment['dbId'] ?? _appointment['id'];
                final idInt = int.tryParse(dbId.toString());
                if (idInt != null) {
                  try {
                    await ApiService.updateAppointmentStatus(id: idInt, status: status);
                  } catch (e) {
                    debugPrint('[AppointmentDetails] status update error: $e');
                  }
                }
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Status updated to $status & user app synced!'),
                    backgroundColor: status == 'Confirmed' ? const Color(0xFF10B981) : AppColors.accentTeal,
                  ),
                );
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final status = _appointment['status'] ?? 'Scheduled';
    final patientName = _appointment['patientName'] ?? _appointment['patient_name'] ?? 'Patient';
    final patientId = _appointment['patientId'] ?? _appointment['patient_id'] ?? 'AKR1001';
    final appointmentId = _appointment['id'] ?? _appointment['appointment_id'] ?? 'APT001';
    final testName = _appointment['testName'] ?? _appointment['service_name'] ?? 'Ultrasound Abdomen';
    final doctor = _appointment['doctor'] ?? _appointment['doctor_name'] ?? 'Dr. Sharma';
    final date = _appointment['date'] ?? _appointment['appointment_date'] ?? '18 Sep 2026';
    final time = _appointment['time'] ?? _appointment['time_slot'] ?? '10:00 AM';
    final mobile = _appointment['mobile'] ?? '9519701963';

    Color statusColor = AppColors.accentTeal;
    if (status == 'Confirmed' || status == 'Completed') {
      statusColor = AppColors.success;
    } else if (status == 'Cancelled') {
      statusColor = AppColors.danger;
    } else if (status == 'In-Progress') {
      statusColor = AppColors.warning;
    }

    return Scaffold(
      backgroundColor: AppColors.lightScaffold,
      appBar: AppBar(
        title: Text('Appointment #$appointmentId', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.primaryDarkBlue,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'WhatsApp Confirmation',
            onPressed: _sendWhatsAppConfirmation,
            icon: const WhatsAppLogo(size: 20),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Patient Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha:0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 26,
                            backgroundColor: AppColors.primaryDarkBlue.withValues(alpha: 0.1),
                            child: Text(
                              patientName.isNotEmpty ? patientName[0].toUpperCase() : 'P',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryDarkBlue,
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Wrap(
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  spacing: 8,
                                  runSpacing: 4,
                                  children: [
                                    Text(
                                      patientName,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.lightTextPrimary,
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: _showStatusDialog,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: statusColor.withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(16),
                                          border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              status,
                                              style: TextStyle(
                                                color: statusColor,
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(width: 3),
                                            Icon(Icons.arrow_drop_down_rounded, color: statusColor, size: 16),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'UHID: $patientId • Mobile: +91 $mobile',
                                  style: const TextStyle(fontSize: 12.5, color: AppColors.lightTextSecondary),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF25D366),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: _sendWhatsAppConfirmation,
                          icon: const WhatsAppLogo(size: 16, color: Colors.white),
                          label: const Text('Send WhatsApp Slip', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Divider(height: 1),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 20,
                        runSpacing: 12,
                        children: [
                          _buildDetailItem('Slot Time', '$date, $time', Icons.access_time_filled_rounded),
                          _buildDetailItem('Investigation', testName, Icons.biotech_rounded),
                          _buildDetailItem('Consultant Doctor', doctor, Icons.medical_services_rounded),
                          _buildDetailItem('Booking Type', 'Online / Walk-in', Icons.phone_iphone_rounded),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Clinical Notes & Preparation Info
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha:0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.info_outline_rounded, color: AppColors.accentTeal, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Patient Clinical Preparation',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.lightTextPrimary),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.lightScaffold,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('• Ultrasound Whole Abdomen: Overnight or 4-6 hours fasting required.', style: TextStyle(fontSize: 13, height: 1.4)),
                            SizedBox(height: 4),
                            Text('• Ultrasound Pelvis / KUB: Full bladder required (drink 4-5 glasses of water 1 hour prior).', style: TextStyle(fontSize: 13, height: 1.4)),
                            SizedBox(height: 4),
                            Text('• Carry all previous investigation reports & prescription slips.', style: TextStyle(fontSize: 13, height: 1.4)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.accentTeal),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 11, color: AppColors.lightTextSecondary)),
            const SizedBox(height: 2),
            Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.lightTextPrimary)),
          ],
        ),
      ],
    );
  }
}
