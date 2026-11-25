class AdminFeedbackItem {
  const AdminFeedbackItem({
    required this.id,
    this.applicationId,
    required this.userId,
    required this.rating,
    required this.standoutTag,
    required this.comments,
    required this.createdAt,
    this.userName,
    this.userEmail,
    this.userPhone,
    this.appReference,
    this.visaTitle,
    this.applicantName,
    this.applicantEmail,
    this.applicantPhone,
  });

  final String id;
  final String? applicationId;
  final String userId;
  final int rating;
  final String standoutTag;
  final String comments;
  final DateTime createdAt;
  final String? userName;
  final String? userEmail;
  final String? userPhone;
  final String? appReference;
  final String? visaTitle;
  final String? applicantName;
  final String? applicantEmail;
  final String? applicantPhone;

  String get effectiveName =>
      (applicantName?.isNotEmpty == true ? applicantName : userName) ??
      'Client User';

  String get effectiveEmail =>
      (applicantEmail?.isNotEmpty == true ? applicantEmail : userEmail) ??
      'No email provided';

  String get effectivePhone =>
      (applicantPhone?.isNotEmpty == true ? applicantPhone : userPhone) ??
      'No phone';

  factory AdminFeedbackItem.fromMap(Map<String, dynamic> map) {
    final profile = map['profiles'] as Map<String, dynamic>?;
    final app = map['applications'] as Map<String, dynamic>?;

    return AdminFeedbackItem(
      id: map['id']?.toString() ?? '',
      applicationId: map['application_id']?.toString(),
      userId: map['user_id']?.toString() ?? '',
      rating: (map['rating'] as num?)?.toInt() ?? 5,
      standoutTag: map['standout_tag']?.toString() ?? 'Accurate Guidance',
      comments: map['comments']?.toString() ?? '',
      createdAt: map['created_at'] != null
          ? (DateTime.tryParse(map['created_at'].toString())?.toLocal() ?? DateTime.now())
          : DateTime.now(),
      userName: profile?['full_name']?.toString() ?? map['user_name']?.toString(),
      userEmail: profile?['email']?.toString() ?? map['user_email']?.toString(),
      userPhone: profile?['phone']?.toString() ?? map['user_phone']?.toString(),
      appReference: app?['reference_number']?.toString() ?? map['app_reference']?.toString(),
      visaTitle: app?['title']?.toString() ?? map['visa_title']?.toString(),
      applicantName: app?['applicant_name']?.toString() ?? map['applicant_name']?.toString(),
      applicantEmail: app?['applicant_email']?.toString() ?? map['applicant_email']?.toString(),
      applicantPhone: app?['applicant_phone']?.toString() ?? map['applicant_phone']?.toString(),
    );
  }
}
