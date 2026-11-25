class VisaCategoryItem {
  const VisaCategoryItem({
    required this.id,
    required this.label,
    this.slug,
    this.description,
    this.iconName,
    this.colorHex,
    this.rowNumber = 1,
    this.displayOrder = 1,
    this.isActive = true,
  });

  final String id;
  final String label;
  final String? slug;
  final String? description;
  final String? iconName;
  final String? colorHex;
  final int rowNumber;
  final int displayOrder;
  final bool isActive;

  factory VisaCategoryItem.fromMap(Map<String, dynamic> map) {
    return VisaCategoryItem(
      id: map['id']?.toString() ?? '',
      label: map['label']?.toString() ?? '',
      slug: map['slug']?.toString(),
      description: map['description']?.toString(),
      iconName: map['icon_name']?.toString(),
      colorHex: map['color_hex']?.toString(),
      rowNumber: (map['row_number'] as num?)?.toInt() ?? 1,
      displayOrder: (map['display_order'] as num?)?.toInt() ?? 1,
      isActive: map['is_active'] != false,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'label': label,
        'slug': slug,
        'description': description,
        'icon_name': iconName,
        'color_hex': colorHex,
        'row_number': rowNumber,
        'display_order': displayOrder,
        'is_active': isActive,
      };
}

class CountryItem {
  const CountryItem({
    required this.id,
    required this.name,
    this.code,
    this.flagEmoji,
    this.flagImageUrl,
    this.displayOrder = 1,
    this.isActive = true,
  });

  final String id;
  final String name;
  final String? code;
  final String? flagEmoji;
  final String? flagImageUrl;
  final int displayOrder;
  final bool isActive;

  factory CountryItem.fromMap(Map<String, dynamic> map) {
    return CountryItem(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      code: map['code']?.toString(),
      flagEmoji: map['flag_emoji']?.toString(),
      flagImageUrl: map['flag_image_url']?.toString(),
      displayOrder: (map['display_order'] as num?)?.toInt() ?? 1,
      isActive: map['is_active'] != false,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'code': code,
        'flag_emoji': flagEmoji,
        'flag_image_url': flagImageUrl,
        'display_order': displayOrder,
        'is_active': isActive,
      };
}

class VisaListingItem {
  const VisaListingItem({
    required this.id,
    required this.categoryId,
    required this.countryId,
    required this.title,
    this.subtitle,
    required this.countryName,
    required this.categoryName,
    required this.processingTime,
    required this.fee,
    this.feeNumeric,
    this.currency = 'PKR',
    this.rating = 4.8,
    this.reviewsCount = 120,
    required this.imageUrl,
    this.isFeatured = false,
    this.isActive = true,
    this.aboutTitle,
    this.aboutDescription,
    this.validity,
    this.successRate,
    this.applicantsCount,
    this.serviceFeeLabel,
    this.serviceFeeValue,
    this.totalPayable,
    this.timelineSteps,
    this.eligibilityCriteria,
    this.mandatoryDocuments,
    this.feeBreakdown,
    this.statusBadge,
    this.externalUrl,
    this.applicationRequirements,
    this.salary,
    this.salaryOrFunding,
    this.createdAt,
    this.updatedAt,
  });

  final String? salary;
  final String? salaryOrFunding;

  final String id;
  final String categoryId;
  final String countryId;
  final String title;
  final String? subtitle;
  final String countryName;
  final String categoryName;
  final String processingTime;
  final String fee;
  final double? feeNumeric;
  final String currency;
  final double rating;
  final int reviewsCount;
  final String imageUrl;
  final bool isFeatured;
  final bool isActive;
  final String? aboutTitle;
  final String? aboutDescription;
  final String? validity;
  final String? successRate;
  final String? applicantsCount;
  final String? serviceFeeLabel;
  final String? serviceFeeValue;
  final String? totalPayable;
  final dynamic timelineSteps;
  final dynamic eligibilityCriteria;
  final dynamic mandatoryDocuments;
  final dynamic feeBreakdown;
  final String? statusBadge;
  final String? externalUrl;
  final dynamic applicationRequirements;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory VisaListingItem.fromMap(Map<String, dynamic> map) {
    return VisaListingItem(
      id: map['id']?.toString() ?? '',
      categoryId: map['category_id']?.toString() ?? '',
      countryId: map['country_id']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      subtitle: map['subtitle']?.toString(),
      countryName: map['country_name']?.toString() ?? '',
      categoryName: map['category_name']?.toString() ?? '',
      processingTime: map['processing_time']?.toString() ?? '2-4 Weeks',
      fee: map['fee']?.toString() ?? 'PKR 30,000',
      feeNumeric: (map['fee_numeric'] as num?)?.toDouble(),
      currency: map['currency']?.toString() ?? 'PKR',
      rating: (map['rating'] as num?)?.toDouble() ?? 4.8,
      reviewsCount: (map['reviews_count'] as num?)?.toInt() ?? 100,
      imageUrl: map['image_url']?.toString() ?? '',
      isFeatured: map['is_featured'] == true,
      isActive: map['is_active'] != false,
      aboutTitle: map['about_title']?.toString(),
      aboutDescription: map['about_description']?.toString(),
      validity: map['validity']?.toString(),
      successRate: map['success_rate']?.toString(),
      applicantsCount: map['applicants_count']?.toString(),
      serviceFeeLabel: map['service_fee_label']?.toString(),
      serviceFeeValue: map['service_fee_value']?.toString(),
      totalPayable: map['total_payable']?.toString(),
      timelineSteps: map['timeline_steps'],
      eligibilityCriteria: map['eligibility_criteria'],
      mandatoryDocuments: map['mandatory_documents'],
      feeBreakdown: map['fee_breakdown'],
      statusBadge: map['status_badge']?.toString(),
      externalUrl: map['external_url']?.toString(),
      applicationRequirements: map['application_requirements'],
      salary: (map['salary'] ?? map['salary_or_funding'] ?? map['salary_range'])?.toString(),
      salaryOrFunding: (map['salary_or_funding'] ?? map['salary'])?.toString(),
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
        'category_id': categoryId,
        'country_id': countryId,
        'title': title,
        'subtitle': subtitle,
        'country_name': countryName,
        'category_name': categoryName,
        'processing_time': processingTime,
        'fee': fee,
        'fee_numeric': feeNumeric,
        'currency': currency,
        'rating': rating,
        'reviews_count': reviewsCount,
        'image_url': imageUrl,
        'is_featured': isFeatured,
        'is_active': isActive,
        'about_title': aboutTitle,
        'about_description': aboutDescription,
        'validity': validity,
        'success_rate': successRate,
        'applicants_count': applicantsCount,
        'service_fee_label': serviceFeeLabel,
        'service_fee_value': serviceFeeValue,
        'total_payable': totalPayable,
        'timeline_steps': timelineSteps,
        'eligibility_criteria': eligibilityCriteria,
        'mandatory_documents': mandatoryDocuments,
        'fee_breakdown': feeBreakdown,
        'status_badge': statusBadge,
        'external_url': externalUrl,
        'application_requirements': applicationRequirements,
        'salary': salary,
        'salary_or_funding': salaryOrFunding,
      };
}
