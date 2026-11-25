class AdminBannerItem {
  const AdminBannerItem({
    required this.id,
    required this.title,
    this.subtitle = '',
    this.badge = '',
    this.actionText = 'Apply Now',
    this.actionUrl,
    this.gradientStart = '0xFF1B3A5C',
    this.gradientEnd = '0xFF2A5A8C',
    this.displayOrder = 0,
    this.isActive = true,
    this.placement = 'all',
    this.categoryName = 'All Pages',
    this.imageUrl,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String title;
  final String subtitle;
  final String badge;
  final String actionText;
  final String? actionUrl;
  final String gradientStart;
  final String gradientEnd;
  final int displayOrder;
  final bool isActive;
  final String placement;
  final String categoryName;
  final String? imageUrl;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory AdminBannerItem.fromMap(Map<String, dynamic> map) {
    return AdminBannerItem(
      id: map['id']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      subtitle: map['subtitle']?.toString() ?? '',
      badge: map['badge']?.toString() ?? '',
      actionText: map['action_text']?.toString() ?? 'Apply Now',
      actionUrl: map['action_url']?.toString(),
      gradientStart: map['gradient_start']?.toString() ?? '0xFF1B3A5C',
      gradientEnd: map['gradient_end']?.toString() ?? '0xFF2A5A8C',
      displayOrder: map['display_order'] is num
          ? (map['display_order'] as num).toInt()
          : int.tryParse(map['display_order']?.toString() ?? '') ?? 0,
      isActive: map['is_active'] as bool? ?? true,
      placement: map['placement']?.toString() ?? 'all',
      categoryName: map['category_name']?.toString() ?? 'All Pages',
      imageUrl: map['image_url']?.toString(),
      createdAt: map['created_at'] != null ? DateTime.tryParse(map['created_at'].toString()) : null,
      updatedAt: map['updated_at'] != null ? DateTime.tryParse(map['updated_at'].toString()) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'subtitle': subtitle,
      'badge': badge,
      'action_text': actionText,
      'action_url': actionUrl,
      'gradient_start': gradientStart,
      'gradient_end': gradientEnd,
      'display_order': displayOrder,
      'is_active': isActive,
      'placement': placement,
      'category_name': categoryName,
      'image_url': imageUrl,
    };
  }

  AdminBannerItem copyWith({
    String? id,
    String? title,
    String? subtitle,
    String? badge,
    String? actionText,
    String? actionUrl,
    String? gradientStart,
    String? gradientEnd,
    int? displayOrder,
    bool? isActive,
    String? placement,
    String? categoryName,
    String? imageUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AdminBannerItem(
      id: id ?? this.id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      badge: badge ?? this.badge,
      actionText: actionText ?? this.actionText,
      actionUrl: actionUrl ?? this.actionUrl,
      gradientStart: gradientStart ?? this.gradientStart,
      gradientEnd: gradientEnd ?? this.gradientEnd,
      displayOrder: displayOrder ?? this.displayOrder,
      isActive: isActive ?? this.isActive,
      placement: placement ?? this.placement,
      categoryName: categoryName ?? this.categoryName,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
