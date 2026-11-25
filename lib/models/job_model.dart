class SponsoredJobItem {
  const SponsoredJobItem({
    required this.id,
    this.countryId,
    required this.type, // 'job' or 'scholarship'
    required this.title,
    required this.companyOrInstitution,
    required this.location,
    this.countryFlag,
    this.avatarInitials,
    this.avatarBgColor,
    this.salaryOrFunding,
    this.salaryPeriod,
    this.employmentType,
    this.degreeLevel,
    this.description,
    this.requirements,
    this.postedTime,
    this.externalUrl,
    this.isFeatured = false,
    this.isActive = true,
    this.displayOrder = 1,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String? countryId;
  final String type;
  final String title;
  final String companyOrInstitution;
  final String location;
  final String? countryFlag;
  final String? avatarInitials;
  final int? avatarBgColor;
  final String? salaryOrFunding;
  final String? salaryPeriod;
  final String? employmentType;
  final String? degreeLevel;
  final String? description;
  final dynamic requirements;
  final String? postedTime;
  final String? externalUrl;
  final bool isFeatured;
  final bool isActive;
  final int displayOrder;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isJob => type.toLowerCase() == 'job';
  bool get isScholarship => type.toLowerCase() == 'scholarship';

  factory SponsoredJobItem.fromMap(Map<String, dynamic> map) {
    return SponsoredJobItem(
      id: map['id']?.toString() ?? '',
      countryId: map['country_id']?.toString(),
      type: map['type']?.toString() ?? 'job',
      title: map['title']?.toString() ?? '',
      companyOrInstitution: map['company_or_institution']?.toString() ?? '',
      location: map['location']?.toString() ?? '',
      countryFlag: map['country_flag']?.toString(),
      avatarInitials: map['avatar_initials']?.toString(),
      avatarBgColor: (map['avatar_bg_color'] as num?)?.toInt(),
      salaryOrFunding: map['salary_or_funding']?.toString(),
      salaryPeriod: map['salary_period']?.toString(),
      employmentType: map['employment_type']?.toString(),
      degreeLevel: map['degree_level']?.toString(),
      description: map['description']?.toString(),
      requirements: map['requirements'],
      postedTime: map['posted_time']?.toString(),
      externalUrl: map['external_url']?.toString(),
      isFeatured: map['is_featured'] == true,
      isActive: map['is_active'] != false,
      displayOrder: (map['display_order'] as num?)?.toInt() ?? 1,
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString())
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.tryParse(map['updated_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'country_id': countryId,
        'type': type,
        'title': title,
        'company_or_institution': companyOrInstitution,
        'location': location,
        'country_flag': countryFlag,
        'avatar_initials': avatarInitials,
        'avatar_bg_color': avatarBgColor,
        'salary_or_funding': salaryOrFunding,
        'salary_period': salaryPeriod,
        'employment_type': employmentType,
        'degree_level': degreeLevel,
        'description': description,
        'requirements': requirements,
        'posted_time': postedTime,
        'external_url': externalUrl,
        'is_featured': isFeatured,
        'is_active': isActive,
        'display_order': displayOrder,
      };
}
