class AdminUserProfile {
  const AdminUserProfile({
    required this.id,
    required this.email,
    this.fullName,
    this.phone,
    this.city,
    this.passportNumber,
    this.nationality,
    this.dob,
    this.avatarUrl,
    required this.role,
    this.isVerified = false,
    required this.createdAt,
    this.applicationsCount = 0,
    this.bookingsCount = 0,
  });

  final String id;
  final String email;
  final String? fullName;
  final String? phone;
  final String? city;
  final String? passportNumber;
  final String? nationality;
  final String? dob;
  final String? avatarUrl;
  final String role;
  final bool isVerified;
  final DateTime createdAt;
  final int applicationsCount;
  final int bookingsCount;

  bool get isAdmin => role == 'admin';
  bool get isConsultant => role == 'consultant';
  bool get isStaff => isAdmin || isConsultant;

  factory AdminUserProfile.fromMap(Map<String, dynamic> map,
      {int applicationsCount = 0, int bookingsCount = 0}) {
    return AdminUserProfile(
      id: map['id']?.toString() ?? '',
      email: map['email']?.toString() ?? '',
      fullName: map['full_name']?.toString(),
      phone: map['phone']?.toString(),
      city: map['city']?.toString(),
      passportNumber: map['passport_number']?.toString(),
      nationality: map['nationality']?.toString(),
      dob: map['dob']?.toString(),
      avatarUrl: map['avatar_url']?.toString(),
      role: map['role']?.toString() ?? 'user',
      isVerified: map['is_verified'] == true,
      createdAt: map['created_at'] != null
          ? (DateTime.tryParse(map['created_at'].toString())?.toLocal() ?? DateTime.now())
          : DateTime.now(),
      applicationsCount: applicationsCount,
      bookingsCount: bookingsCount,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'phone': phone,
      'city': city,
      'passport_number': passportNumber,
      'nationality': nationality,
      'dob': dob,
      'avatar_url': avatarUrl,
      'role': role,
      'is_verified': isVerified,
    };
  }
}
