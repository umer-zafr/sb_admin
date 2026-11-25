class AdminSuccessStoryItem {
  const AdminSuccessStoryItem({
    required this.id,
    required this.clientName,
    this.avatarUrl,
    required this.visaType,
    required this.countryName,
    this.countryFlag = '🌍',
    this.processingTime,
    this.rating = 5.0,
    required this.quote,
    this.universityOrEmployer,
    this.approvedDate,
    this.badgeText = 'Verified Approval',
    this.displayOrder = 0,
    this.isPublished = true,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String clientName;
  final String? avatarUrl;
  final String visaType;
  final String countryName;
  final String countryFlag;
  final String? processingTime;
  final double rating;
  final String quote;
  final String? universityOrEmployer;
  final String? approvedDate;
  final String badgeText;
  final int displayOrder;
  final bool isPublished;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory AdminSuccessStoryItem.fromMap(Map<String, dynamic> map) {
    return AdminSuccessStoryItem(
      id: map['id']?.toString() ?? '',
      clientName: map['client_name']?.toString() ?? '',
      avatarUrl: map['avatar_url']?.toString(),
      visaType: map['visa_type']?.toString() ?? '',
      countryName: map['country_name']?.toString() ?? '',
      countryFlag: map['country_flag']?.toString() ?? '🌍',
      processingTime: map['processing_time']?.toString(),
      rating: map['rating'] is num
          ? (map['rating'] as num).toDouble()
          : (double.tryParse(map['rating']?.toString() ?? '') ?? 5.0),
      quote: map['quote']?.toString() ?? '',
      universityOrEmployer: map['university_or_employer']?.toString(),
      approvedDate: map['approved_date']?.toString(),
      badgeText: map['badge_text']?.toString() ?? 'Verified Approval',
      displayOrder: (map['display_order'] as num?)?.toInt() ?? 0,
      isPublished: map['is_published'] as bool? ?? true,
      createdAt: map['created_at'] != null ? DateTime.tryParse(map['created_at'].toString()) : null,
      updatedAt: map['updated_at'] != null ? DateTime.tryParse(map['updated_at'].toString()) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'client_name': clientName,
      'avatar_url': avatarUrl,
      'visa_type': visaType,
      'country_name': countryName,
      'country_flag': countryFlag,
      'processing_time': processingTime,
      'rating': rating,
      'quote': quote,
      'university_or_employer': universityOrEmployer,
      'approved_date': approvedDate,
      'badge_text': badgeText,
      'display_order': displayOrder,
      'is_published': isPublished,
    };
  }
}
