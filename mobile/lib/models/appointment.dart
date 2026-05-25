import 'doctor_appointment.dart';

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
  final DateTime? preferredDate;
  final String? preferredTimeSlot;
  final AppointmentStatus status;
  final double fee;
  final String? meetingLink;
  final String? prescriptionUrl;
  final PaymentInfo? payment;
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
    this.preferredDate,
    this.preferredTimeSlot,
    required this.status,
    this.fee = 0,
    this.meetingLink,
    this.prescriptionUrl,
    this.payment,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory AppointmentModel.fromJson(Map<String, dynamic> json) {
    PaymentInfo? payment;
    if (json['payment'] != null) {
      payment = PaymentInfo.fromJson(json['payment']);
    }
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
      preferredDate: json['preferredDate'] != null
          ? DateTime.parse(json['preferredDate'])
          : null,
      preferredTimeSlot: json['preferredTimeSlot'],
      status: AppointmentStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => AppointmentStatus.pending,
      ),
      fee: (json['fee'] ?? 0).toDouble(),
      meetingLink: json['meetingLink'],
      prescriptionUrl: json['prescriptionUrl'],
      payment: payment,
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
        'preferredDate': preferredDate?.toIso8601String(),
        'preferredTimeSlot': preferredTimeSlot,
        'status': status.name,
        'fee': fee,
        'meetingLink': meetingLink,
        'prescriptionUrl': prescriptionUrl,
        'payment': payment?.toJson(),
        'createdAt': createdAt.toIso8601String(),
      };
}
