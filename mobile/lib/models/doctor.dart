class DoctorModel {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final String? avatarUrl;
  final String specialty;
  final String? qualification;
  final String? experience;
  final String? bio;
  final double consultationFee;
  final double averageRating;
  final int totalReviews;
  final String? hospitalName;
  final String? hospitalAddress;
  final double? latitude;
  final double? longitude;
  final List<String> availableDays;
  final bool isAvailable;
  final int yearsOfExperience;

  DoctorModel({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.avatarUrl,
    required this.specialty,
    this.qualification,
    this.experience,
    this.bio,
    this.consultationFee = 0,
    this.averageRating = 0,
    this.totalReviews = 0,
    this.hospitalName,
    this.hospitalAddress,
    this.latitude,
    this.longitude,
    this.availableDays = const [],
    this.isAvailable = true,
    this.yearsOfExperience = 0,
  });

  factory DoctorModel.fromJson(Map<String, dynamic> json) {
    return DoctorModel(
      id: json['id'],
      name: json['name'],
      email: json['email'] ?? '',
      phone: json['phone'],
      avatarUrl: json['avatarUrl'],
      specialty: json['specialty'] ?? 'General',
      qualification: json['qualification'],
      experience: json['experience'],
      bio: json['bio'],
      consultationFee: (json['consultationFee'] ?? 0).toDouble(),
      averageRating: (json['averageRating'] ?? 0).toDouble(),
      totalReviews: json['totalReviews'] ?? 0,
      hospitalName: json['hospitalName'],
      hospitalAddress: json['hospitalAddress'],
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
      availableDays: json['availableDays'] != null
          ? List<String>.from(json['availableDays'])
          : [],
      isAvailable: json['isAvailable'] ?? true,
      yearsOfExperience: json['yearsOfExperience'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'phone': phone,
        'avatarUrl': avatarUrl,
        'specialty': specialty,
        'qualification': qualification,
        'experience': experience,
        'bio': bio,
        'consultationFee': consultationFee,
        'averageRating': averageRating,
        'totalReviews': totalReviews,
        'hospitalName': hospitalName,
        'hospitalAddress': hospitalAddress,
        'latitude': latitude,
        'longitude': longitude,
        'availableDays': availableDays,
        'isAvailable': isAvailable,
        'yearsOfExperience': yearsOfExperience,
      };
}
