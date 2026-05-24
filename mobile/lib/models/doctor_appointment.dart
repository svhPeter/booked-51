class DoctorAppointmentModel {
  final String id;
  final String patientId;
  final String doctorId;
  final String patientName;
  final String patientEmail;
  final String patientPhone;
  final String? patientAvatar;
  final DateTime date;
  final String timeSlot;
  final DateTime? preferredDate;
  final String? preferredTimeSlot;
  final String status;
  final String? meetingLink;
  final String? notes;
  final String? hospitalName;
  final PaymentInfo? payment;
  final DateTime createdAt;

  DoctorAppointmentModel({
    required this.id,
    required this.patientId,
    required this.doctorId,
    required this.patientName,
    this.patientEmail = '',
    this.patientPhone = '',
    this.patientAvatar,
    required this.date,
    required this.timeSlot,
    this.preferredDate,
    this.preferredTimeSlot,
    required this.status,
    this.meetingLink,
    this.notes,
    this.hospitalName,
    this.payment,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory DoctorAppointmentModel.fromJson(Map<String, dynamic> json) {
    PaymentInfo? payment;
    if (json['payment'] != null) {
      payment = PaymentInfo.fromJson(json['payment']);
    }
    return DoctorAppointmentModel(
      id: json['id'],
      patientId: json['patientId'],
      doctorId: json['doctorId'],
      patientName: json['patientName'] ?? '',
      patientEmail: json['patientEmail'] ?? '',
      patientPhone: json['patientPhone'] ?? '',
      patientAvatar: json['patientAvatar'],
      date: DateTime.parse(json['date']),
      timeSlot: json['timeSlot'] ?? '',
      preferredDate: json['preferredDate'] != null
          ? DateTime.parse(json['preferredDate'])
          : null,
      preferredTimeSlot: json['preferredTimeSlot'],
      status: json['status'] ?? '',
      meetingLink: json['meetingLink'],
      notes: json['notes'],
      hospitalName: json['hospitalName'],
      payment: payment,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }
}

class PaymentInfo {
  final String id;
  final double amount;
  final String currency;
  final String provider;
  final String status;
  final String? providerTxnId;
  final DateTime? createdAt;

  PaymentInfo({
    required this.id,
    required this.amount,
    this.currency = 'PKR',
    this.provider = 'mock',
    this.status = 'pending',
    this.providerTxnId,
    this.createdAt,
  });

  factory PaymentInfo.fromJson(Map<String, dynamic> json) {
    return PaymentInfo(
      id: json['id'],
      amount: (json['amount'] ?? 0).toDouble(),
      currency: json['currency'] ?? 'PKR',
      provider: json['provider'] ?? 'mock',
      status: json['status'] ?? 'pending',
      providerTxnId: json['providerTxnId'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
    );
  }
}

class DashboardSummary {
  final int todayCount;
  final int upcomingCount;
  final int completedCount;
  final int cancelledCount;
  final int totalPatients;
  final int paidPaymentsCount;
  final int pendingPaymentsCount;
  final double totalRevenue;

  DashboardSummary({
    this.todayCount = 0,
    this.upcomingCount = 0,
    this.completedCount = 0,
    this.cancelledCount = 0,
    this.totalPatients = 0,
    this.paidPaymentsCount = 0,
    this.pendingPaymentsCount = 0,
    this.totalRevenue = 0,
  });

  factory DashboardSummary.fromJson(Map<String, dynamic> json) {
    return DashboardSummary(
      todayCount: json['todayCount'] ?? 0,
      upcomingCount: json['upcomingCount'] ?? 0,
      completedCount: json['completedCount'] ?? 0,
      cancelledCount: json['cancelledCount'] ?? 0,
      totalPatients: json['totalPatients'] ?? 0,
      paidPaymentsCount: json['paidPaymentsCount'] ?? 0,
      pendingPaymentsCount: json['pendingPaymentsCount'] ?? 0,
      totalRevenue: (json['totalRevenue'] ?? 0).toDouble(),
    );
  }
}
