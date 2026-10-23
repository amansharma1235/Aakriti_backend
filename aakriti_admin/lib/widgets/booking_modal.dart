import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

class BookingModal extends StatefulWidget {
  final VoidCallback? onBookingSuccess;

  const BookingModal({super.key, this.onBookingSuccess});

  static Future<void> show(BuildContext context, {VoidCallback? onSuccess}) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => BookingModal(onBookingSuccess: onSuccess),
    );
  }

  @override
  State<BookingModal> createState() => _BookingModalState();
}

class _BookingModalState extends State<BookingModal> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController nameCtrl = TextEditingController();
  final TextEditingController mobileCtrl = TextEditingController();
  final TextEditingController ageCtrl = TextEditingController(text: '26');
  final TextEditingController notesCtrl = TextEditingController();

  String selectedGender = 'Male';
  String selectedService = 'Ultrasound Whole Abdomen';
  String selectedDoctor = 'Dr. Rajesh Sharma';
  DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
  String selectedSlot = '10:30 AM';

  bool isSubmitting = false;
  String? errorMessage;

  final List<String> services = [
    'Ultrasound Whole Abdomen',
    'Obstetric Ultrasound (Level II / TIFFA Scan)',
    'Pelvic & Lower Abdomen Ultrasound',
    'Color Doppler - Lower Limb (Arterial/Venous)',
    'Thyroid & Neck Ultrasound with Doppler',
    'KUB & Prostate Ultrasound',
    'Bilateral Breast Sonomammography',
    'Scrotal & Testicular Color Doppler',
    'Early Pregnancy / Viability & NT/NB Scan',
    'Musculoskeletal (MSK) Ultrasound',
    'Follicular Monitoring Study',
    'Complete Blood Count (CBC)',
  ];

  final List<String> doctors = [
    'Dr. Rajesh Sharma',
    'Dr. Neha Verma',
    'Dr. Amit Gupta',
    'Dr. Priya Singh',
    'Dr. Ankit Verma',
  ];

  final List<String> timeSlots = [
    '10:00 AM',
    '10:30 AM',
    '11:00 AM',
    '11:30 AM',
    '12:00 PM',
    '12:30 PM',
    '01:00 PM',
    '01:30 PM',
    '02:00 PM',
    '02:30 PM',
    '03:00 PM',
    '03:30 PM',
    '04:00 PM',
  ];

  @override
  void initState() {
    super.initState();
    _loadDynamicServices();
  }

  Future<void> _loadDynamicServices() async {
    try {
      final list = await ApiService.getServices();
      if (list.isNotEmpty && mounted) {
        setState(() {
          for (final item in list) {
            final name = item['service_name']?.toString() ?? '';
            if (name.isNotEmpty && !services.contains(name)) {
              services.add(name);
            }
          }
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    mobileCtrl.dispose();
    ageCtrl.dispose();
    notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitBooking() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      isSubmitting = true;
      errorMessage = null;
    });

    final formattedDate =
        "${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}";

    final result = await ApiService.bookAppointment(
      patientName: nameCtrl.text.trim(),
      serviceName: selectedService,
      appointmentDate: formattedDate,
      appointmentTime: selectedSlot,
      mobile: mobileCtrl.text.trim(),
      age: int.tryParse(ageCtrl.text.trim()) ?? 25,
      gender: selectedGender,
      doctorName: selectedDoctor,
      note: notesCtrl.text.trim(),
    );

    if (!mounted) return;

    setState(() => isSubmitting = false);

    if (result['success'] == true) {
      final aptId = result['data']?['appointment_id'] ?? 'APT';
      Navigator.pop(context);
      widget.onBookingSuccess?.call();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Appointment request submitted successfully!\nID: $aptId',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      setState(() {
        errorMessage = result['message'] ?? 'Failed to book appointment.';
      });
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    if (picked != null) {
      setState(() => selectedDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        width: double.maxFinite,
        constraints: BoxConstraints(
          maxWidth: 520,
          maxHeight: MediaQuery.of(context).size.height * 0.88,
        ),
        decoration: BoxDecoration(
          color: AppTheme.cardBg(context),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppTheme.border(context)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 28,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: Column(
          children: [
            // Modal Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: const BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_month_rounded, color: Colors.white, size: 24),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Book Patient Appointment',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'Real-time slot validation with MySQL & WebSocket',
                          style: TextStyle(fontSize: 11, color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Modal Body
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (errorMessage != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.danger.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline, color: AppColors.danger, size: 20),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  errorMessage!,
                                  style: const TextStyle(color: AppColors.danger, fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Patient Information
                      Text('PATIENT INFORMATION', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppTheme.textSecondary(context))),
                      const SizedBox(height: 8),

                      TextFormField(
                        controller: nameCtrl,
                        style: TextStyle(color: AppTheme.textPrimary(context)),
                        decoration: const InputDecoration(
                          labelText: 'Patient Full Name *',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        validator: (v) => v == null || v.trim().isEmpty ? 'Please enter patient name' : null,
                      ),
                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: TextFormField(
                              controller: mobileCtrl,
                              keyboardType: TextInputType.phone,
                              style: TextStyle(color: AppTheme.textPrimary(context)),
                              decoration: const InputDecoration(
                                labelText: 'Mobile Number *',
                                prefixIcon: Icon(Icons.phone_outlined),
                              ),
                              validator: (v) => v == null || v.trim().length < 10 ? 'Enter valid mobile' : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              controller: ageCtrl,
                              keyboardType: TextInputType.number,
                              style: TextStyle(color: AppTheme.textPrimary(context)),
                              decoration: const InputDecoration(labelText: 'Age'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Gender Selector
                      DropdownButtonFormField<String>(
                        initialValue: selectedGender,
                        isExpanded: true,
                        items: ['Male', 'Female', 'Other']
                            .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                            .toList(),
                        onChanged: (v) => setState(() => selectedGender = v!),
                        decoration: const InputDecoration(
                          labelText: 'Gender',
                          prefixIcon: Icon(Icons.wc_outlined),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Procedure & Doctor
                      Text('PROCEDURE & CLINICAL DETAILS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppTheme.textSecondary(context))),
                      const SizedBox(height: 8),

                      DropdownButtonFormField<String>(
                        initialValue: selectedService,
                        isExpanded: true,
                        items: services
                            .map((s) => DropdownMenuItem(value: s, child: Text(s, maxLines: 1, overflow: TextOverflow.ellipsis)))
                            .toList(),
                        onChanged: (v) => setState(() => selectedService = v!),
                        decoration: const InputDecoration(
                          labelText: 'Diagnostic Service / Test *',
                          prefixIcon: Icon(Icons.medical_services_outlined),
                        ),
                      ),
                      const SizedBox(height: 12),

                      DropdownButtonFormField<String>(
                        initialValue: selectedDoctor,
                        isExpanded: true,
                        items: doctors
                            .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                            .toList(),
                        onChanged: (v) => setState(() => selectedDoctor = v!),
                        decoration: const InputDecoration(
                          labelText: 'Assigned Doctor / Radiologist',
                          prefixIcon: Icon(Icons.health_and_safety_outlined),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Schedule Slot
                      Text('DATE & PREFERRED TIME SLOT', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppTheme.textSecondary(context))),
                      const SizedBox(height: 8),

                      LayoutBuilder(
                        builder: (context, constraints) {
                          final isNarrow = constraints.maxWidth < 360;

                          final dateWidget = InkWell(
                            onTap: _selectDate,
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
                              decoration: BoxDecoration(
                                color: AppColors.inputFill(context),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.border(context)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.calendar_today, size: 18, color: AppColors.primaryBlue),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      "${selectedDate.day}-${selectedDate.month}-${selectedDate.year}",
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13,
                                        color: AppTheme.textPrimary(context),
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );

                          final slotWidget = DropdownButtonFormField<String>(
                            initialValue: selectedSlot,
                            isExpanded: true,
                            isDense: true,
                            items: timeSlots
                                .map((t) => DropdownMenuItem(
                                      value: t,
                                      child: Text(
                                        t,
                                        style: const TextStyle(fontSize: 13),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ))
                                .toList(),
                            onChanged: (v) => setState(() => selectedSlot = v!),
                            decoration: const InputDecoration(
                              labelText: 'Slot Time',
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                              prefixIcon: Icon(Icons.access_time, size: 20),
                            ),
                          );

                          if (isNarrow) {
                            return Column(
                              children: [
                                dateWidget,
                                const SizedBox(height: 10),
                                slotWidget,
                              ],
                            );
                          }

                          return Row(
                            children: [
                              Expanded(child: dateWidget),
                              const SizedBox(width: 8),
                              Expanded(child: slotWidget),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 12),

                      TextFormField(
                        controller: notesCtrl,
                        maxLines: 2,
                        style: TextStyle(color: AppTheme.textPrimary(context)),
                        decoration: const InputDecoration(
                          labelText: 'Clinical Notes / Instructions',
                          hintText: 'e.g. 6 hours fasting, drink 1L water',
                          prefixIcon: Icon(Icons.notes_rounded),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Modal Actions
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F1E2E) : const Color(0xFFF8FAFC),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
                border: Border(top: BorderSide(color: AppTheme.border(context))),
              ),
              child: Row(
                children: [
                  TextButton(
                    onPressed: isSubmitting ? null : () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: isSubmitting ? null : _submitBooking,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check_rounded, size: 18),
                              SizedBox(width: 8),
                              Text('Book Appointment', style: TextStyle(fontWeight: FontWeight.w700)),
                            ],
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
