enum AppointmentStatus {
  pending,
  confirmed,
  checkedIn,
  inProgress,
  completed,
  cancelled,
  rescheduled,
  noShow,
}

class AppointmentModel {
  final String id;
  final int? databaseId;
  final String patientId;
  final String scanName;
  final String testId;
  final String testName;
  final String patientName;
  final String mobile;
  final String? age;
  final String? gender;
  final String? doctorName;

  String date;
  String time;

  final String note;
  final double price;
  final bool isForFamilyMember;
  final String? familyMemberId;

  AppointmentStatus status;

  AppointmentModel({
    required this.id,
    this.databaseId,
    required this.patientId,
    required this.scanName,
    this.testId = '',
    String? testName,
    required this.patientName,
    required this.mobile,
    this.age,
    this.gender,
    this.doctorName,
    required this.date,
    required this.time,
    this.note = "",
    this.price = 0.0,
    this.isForFamilyMember = false,
    this.familyMemberId,
    this.status = AppointmentStatus.pending,
  }) : testName = testName ?? scanName;

  String get notes => note;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'databaseId': databaseId,
      'patientId': patientId,
      'scanName': scanName,
      'testId': testId,
      'testName': testName,
      'patientName': patientName,
      'mobile': mobile,
      'age': age,
      'gender': gender,
      'doctorName': doctorName,
      'date': date,
      'time': time,
      'note': note,
      'price': price,
      'isForFamilyMember': isForFamilyMember,
      'familyMemberId': familyMemberId,
      'status': status.name,
    };
  }

  factory AppointmentModel.fromJson(Map<String, dynamic> json) {
    AppointmentStatus st = AppointmentStatus.pending;
    try {
      final statusStr = (json['status'] ?? '').toString().replaceAll('_', '').toLowerCase();
      st = AppointmentStatus.values.firstWhere(
        (e) => e.name.toLowerCase() == statusStr,
        orElse: () => AppointmentStatus.pending,
      );
    } catch (_) {}

    final scan = (json['scanName'] ?? json['testName'] ?? json['test_name'] ?? '').toString();

    return AppointmentModel(
      id: (json['id'] ?? json['appointmentId'] ?? json['appointment_id'] ?? '').toString(),
      databaseId: json['databaseId'] as int?,
      patientId: (json['patientId'] ?? json['userId'] ?? json['patient_id'] ?? '').toString(),
      scanName: scan,
      testId: (json['testId'] ?? json['test_id'] ?? '').toString(),
      testName: scan,
      patientName: (json['patientName'] ?? json['patient_name'] ?? '').toString(),
      mobile: (json['mobile'] ?? '').toString(),
      age: json['age']?.toString(),
      gender: json['gender']?.toString(),
      doctorName: (json['doctorName'] ?? json['doctor_name'])?.toString(),
      date: (json['date'] ?? json['appointment_date'] ?? '').toString(),
      time: (json['time'] ?? json['appointment_time'] ?? '').toString(),
      note: (json['note'] ?? json['notes'] ?? '').toString(),
      price: (json['price'] as num?)?.toDouble() ?? (json['amount'] as num?)?.toDouble() ?? 0.0,
      isForFamilyMember: json['isForFamilyMember'] == true,
      familyMemberId: json['familyMemberId']?.toString(),
      status: st,
    );
  }

  String get statusText {
    switch (status) {
      case AppointmentStatus.pending:
        return "Pending";
      case AppointmentStatus.confirmed:
        return "Confirmed";
      case AppointmentStatus.checkedIn:
        return "Checked-In";
      case AppointmentStatus.inProgress:
        return "In Progress";
      case AppointmentStatus.completed:
        return "Completed";
      case AppointmentStatus.cancelled:
        return "Cancelled";
      case AppointmentStatus.rescheduled:
        return "Rescheduled";
      case AppointmentStatus.noShow:
        return "No Show";
    }
  }
}
