enum AppointmentStatus { pending, confirmed, cancelled, completed }

class AppointmentModel {
  final String id;
  final String patientId;
  final String doctorId;
  final String doctorName;
  final String? doctorAvatar;
  final String specialty;
  final String? hospitalName;
  final DateTime date;
  final String timeSlot;
  final AppointmentStatus status;
  final double fee;
  final String? meetingLink;
  final String? prescriptionUrl;
  final DateTime createdAt;

  AppointmentModel({
    required this.id,
    required this.patientId,
    required this.doctorId,
    required this.doctorName,
    this.doctorAvatar,
    required this.specialty,
    this.hospitalName,
    required this.date,
    required this.timeSlot,
    required this.status,
    this.fee = 0,
    this.meetingLink,
    this.prescriptionUrl,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory AppointmentModel.fromJson(Map<String, dynamic> json) {
    return AppointmentModel(
      id: json['id'],
      patientId: json['patientId'],
      doctorId: json['doctorId'],
      doctorName: json['doctorName'] ?? '',
      doctorAvatar: json['doctorAvatar'],
      specialty: json['specialty'] ?? '',
      hospitalName: json['hospitalName'],
      date: DateTime.parse(json['date']),
      timeSlot: json['timeSlot'] ?? '',
      status: AppointmentStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => AppointmentStatus.pending,
      ),
      fee: (json['fee'] ?? 0).toDouble(),
      meetingLink: json['meetingLink'],
      prescriptionUrl: json['prescriptionUrl'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'patientId': patientId,
        'doctorId': doctorId,
        'doctorName': doctorName,
        'doctorAvatar': doctorAvatar,
        'specialty': specialty,
        'hospitalName': hospitalName,
        'date': date.toIso8601String(),
        'timeSlot': timeSlot,
        'status': status.name,
        'fee': fee,
        'meetingLink': meetingLink,
        'prescriptionUrl': prescriptionUrl,
        'createdAt': createdAt.toIso8601String(),
      };
}
