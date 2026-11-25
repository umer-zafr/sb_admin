class AffiliateItem {
  const AffiliateItem({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.city,
    this.platforms = const [],
    this.profileLinks = const {},
    this.totalFollowers = 0,
    this.status = 'pending',
    this.promoCode,
    this.discountType = 'percentage',
    this.discountValue = 10.0,
    this.commissionPerReferral = 1000.0,
    this.referralCount = 0,
    this.notes,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String name;
  final String email;
  final String phone;
  final String city;
  final List<String> platforms;
  final Map<String, String> profileLinks;
  final int totalFollowers;
  final String status; // 'pending', 'approved', 'rejected'
  final String? promoCode;
  final String discountType; // 'percentage' or 'fixed'
  final double discountValue;
  final double commissionPerReferral;
  final int referralCount;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isApproved => status.toLowerCase() == 'approved';
  bool get isPending => status.toLowerCase() == 'pending';
  bool get isRejected => status.toLowerCase() == 'rejected';

  double get totalEarnings => referralCount * commissionPerReferral;

  factory AffiliateItem.fromMap(Map<String, dynamic> map, {int referralCount = 0}) {
    List<String> parsedPlatforms = [];
    if (map['platforms'] != null) {
      if (map['platforms'] is List) {
        parsedPlatforms =
            List<String>.from((map['platforms'] as List).map((e) => e.toString()));
      }
    }

    Map<String, String> parsedProfileLinks = {};
    if (map['profile_links'] != null && map['profile_links'] is Map) {
      final m = map['profile_links'] as Map;
      m.forEach((k, v) {
        if (v != null) parsedProfileLinks[k.toString()] = v.toString();
      });
    }

    return AffiliateItem(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      email: map['email']?.toString() ?? '',
      phone: map['phone']?.toString() ?? '',
      city: map['city']?.toString() ?? '',
      platforms: parsedPlatforms,
      profileLinks: parsedProfileLinks,
      totalFollowers: (map['total_followers'] as num?)?.toInt() ?? 0,
      status: map['status']?.toString() ?? 'pending',
      promoCode: map['promo_code']?.toString(),
      discountType: map['discount_type']?.toString() ?? 'percentage',
      discountValue: (map['discount_value'] as num?)?.toDouble() ?? 10.0,
      commissionPerReferral:
          (map['commission_per_referral'] as num?)?.toDouble() ?? 1000.0,
      referralCount: referralCount,
      notes: map['notes']?.toString(),
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString())?.toLocal()
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.tryParse(map['updated_at'].toString())?.toLocal()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'city': city,
      'platforms': platforms,
      'profile_links': profileLinks,
      'total_followers': totalFollowers,
      'status': status,
      'promo_code': promoCode,
      'discount_type': discountType,
      'discount_value': discountValue,
      'commission_per_referral': commissionPerReferral,
      'notes': notes,
    };
  }
}

