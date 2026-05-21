class AdminSummary {
  final int totalDoctors;
  final int totalPatients;
  final int totalAppointments;
  final int completedAppointments;
  final int cancelledAppointments;
  final int paidPaymentsCount;
  final int pendingPaymentsCount;
  final double totalRevenue;

  AdminSummary({
    required this.totalDoctors,
    required this.totalPatients,
    required this.totalAppointments,
    required this.completedAppointments,
    required this.cancelledAppointments,
    required this.paidPaymentsCount,
    required this.pendingPaymentsCount,
    required this.totalRevenue,
  });

  factory AdminSummary.fromJson(Map<String, dynamic> json) {
    return AdminSummary(
      totalDoctors: json['totalDoctors'] ?? 0,
      totalPatients: json['totalPatients'] ?? 0,
      totalAppointments: json['totalAppointments'] ?? 0,
      completedAppointments: json['completedAppointments'] ?? 0,
      cancelledAppointments: json['cancelledAppointments'] ?? 0,
      paidPaymentsCount: json['paidPaymentsCount'] ?? 0,
      pendingPaymentsCount: json['pendingPaymentsCount'] ?? 0,
      totalRevenue: (json['totalRevenue'] ?? 0).toDouble(),
    );
  }
}

class AdminDoctor {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String? avatarUrl;
  final bool isActive;
  final bool isVerified;
  final bool isApproved;
  final String specialty;
  final String qualification;
  final String experience;
  final double consultationFee;
  final int yearsOfExperience;
  final double averageRating;
  final int totalReviews;
  final List<String> availableDays;
  final String hospitalName;
  final String hospitalCity;
  final String createdAt;

  AdminDoctor({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    this.avatarUrl,
    required this.isActive,
    required this.isVerified,
    required this.isApproved,
    required this.specialty,
    required this.qualification,
    required this.experience,
    required this.consultationFee,
    required this.yearsOfExperience,
    required this.averageRating,
    required this.totalReviews,
    required this.availableDays,
    required this.hospitalName,
    required this.hospitalCity,
    required this.createdAt,
  });

  factory AdminDoctor.fromJson(Map<String, dynamic> json) {
    return AdminDoctor(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      avatarUrl: json['avatarUrl'],
      isActive: json['isActive'] ?? true,
      isVerified: json['isVerified'] ?? false,
      isApproved: json['isApproved'] ?? false,
      specialty: json['specialty'] ?? '',
      qualification: json['qualification'] ?? '',
      experience: json['experience'] ?? '',
      consultationFee: (json['consultationFee'] ?? 0).toDouble(),
      yearsOfExperience: json['yearsOfExperience'] ?? 0,
      averageRating: (json['averageRating'] ?? 0).toDouble(),
      totalReviews: json['totalReviews'] ?? 0,
      availableDays: List<String>.from(json['availableDays'] ?? []),
      hospitalName: json['hospitalName'] ?? '',
      hospitalCity: json['hospitalCity'] ?? '',
      createdAt: json['createdAt'] ?? '',
    );
  }
}

class AdminPatient {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String? avatarUrl;
  final bool isActive;
  final bool isVerified;
  final String? dob;
  final String gender;
  final String bloodGroup;
  final String createdAt;

  AdminPatient({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    this.avatarUrl,
    required this.isActive,
    required this.isVerified,
    this.dob,
    required this.gender,
    required this.bloodGroup,
    required this.createdAt,
  });

  factory AdminPatient.fromJson(Map<String, dynamic> json) {
    return AdminPatient(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      avatarUrl: json['avatarUrl'],
      isActive: json['isActive'] ?? true,
      isVerified: json['isVerified'] ?? false,
      dob: json['dob'],
      gender: json['gender'] ?? '',
      bloodGroup: json['bloodGroup'] ?? '',
      createdAt: json['createdAt'] ?? '',
    );
  }
}

class AdminAppointment {
  final String id;
  final String patientId;
  final String doctorId;
  final String date;
  final String timeSlot;
  final String status;
  final String? meetingLink;
  final String? notes;
  final String createdAt;
  final String patientName;
  final String patientEmail;
  final String patientPhone;
  final String doctorName;
  final String doctorEmail;
  final String hospitalName;
  final AdminPaymentInfo? payment;

  AdminAppointment({
    required this.id,
    required this.patientId,
    required this.doctorId,
    required this.date,
    required this.timeSlot,
    required this.status,
    this.meetingLink,
    this.notes,
    required this.createdAt,
    required this.patientName,
    required this.patientEmail,
    required this.patientPhone,
    required this.doctorName,
    required this.doctorEmail,
    required this.hospitalName,
    this.payment,
  });

  factory AdminAppointment.fromJson(Map<String, dynamic> json) {
    return AdminAppointment(
      id: json['id'] ?? '',
      patientId: json['patientId'] ?? '',
      doctorId: json['doctorId'] ?? '',
      date: json['date'] ?? '',
      timeSlot: json['timeSlot'] ?? '',
      status: json['status'] ?? '',
      meetingLink: json['meetingLink'],
      notes: json['notes'],
      createdAt: json['createdAt'] ?? '',
      patientName: json['patientName'] ?? '',
      patientEmail: json['patientEmail'] ?? '',
      patientPhone: json['patientPhone'] ?? '',
      doctorName: json['doctorName'] ?? '',
      doctorEmail: json['doctorEmail'] ?? '',
      hospitalName: json['hospitalName'] ?? '',
      payment: json['payment'] != null ? AdminPaymentInfo.fromJson(json['payment']) : null,
    );
  }
}

class AdminPaymentInfo {
  final String id;
  final double amount;
  final String currency;
  final String provider;
  final String status;
  final String? createdAt;

  AdminPaymentInfo({
    required this.id,
    required this.amount,
    required this.currency,
    required this.provider,
    required this.status,
    this.createdAt,
  });

  factory AdminPaymentInfo.fromJson(Map<String, dynamic> json) {
    return AdminPaymentInfo(
      id: json['id'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      currency: json['currency'] ?? 'PKR',
      provider: json['provider'] ?? '',
      status: json['status'] ?? '',
      createdAt: json['createdAt'],
    );
  }
}

class AdminPayment {
  final String id;
  final String appointmentId;
  final String userId;
  final double amount;
  final String currency;
  final String provider;
  final String? providerTxnId;
  final String status;
  final String createdAt;
  final String userName;
  final String userEmail;
  final String? appointmentDate;
  final String appointmentTimeSlot;
  final String appointmentStatus;

  AdminPayment({
    required this.id,
    required this.appointmentId,
    required this.userId,
    required this.amount,
    required this.currency,
    required this.provider,
    this.providerTxnId,
    required this.status,
    required this.createdAt,
    required this.userName,
    required this.userEmail,
    this.appointmentDate,
    required this.appointmentTimeSlot,
    required this.appointmentStatus,
  });

  factory AdminPayment.fromJson(Map<String, dynamic> json) {
    return AdminPayment(
      id: json['id'] ?? '',
      appointmentId: json['appointmentId'] ?? '',
      userId: json['userId'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      currency: json['currency'] ?? 'PKR',
      provider: json['provider'] ?? '',
      providerTxnId: json['providerTxnId'],
      status: json['status'] ?? '',
      createdAt: json['createdAt'] ?? '',
      userName: json['userName'] ?? '',
      userEmail: json['userEmail'] ?? '',
      appointmentDate: json['appointmentDate'],
      appointmentTimeSlot: json['appointmentTimeSlot'] ?? '',
      appointmentStatus: json['appointmentStatus'] ?? '',
    );
  }
}
