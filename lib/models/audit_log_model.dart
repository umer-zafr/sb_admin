class AdminAuditLogItem {
  const AdminAuditLogItem({
    required this.id,
    this.adminId,
    required this.action,
    required this.entityType,
    required this.entityId,
    this.details,
    this.ipAddress,
    required this.createdAt,
    this.adminEmail,
  });

  final String id;
  final String? adminId;
  final String action;
  final String entityType;
  final String entityId;
  final dynamic details;
  final String? ipAddress;
  final DateTime createdAt;
  final String? adminEmail;

  factory AdminAuditLogItem.fromMap(
    Map<String, dynamic> map, {
    String? adminEmail,
  }) {
    return AdminAuditLogItem(
      id: map['id']?.toString() ?? '',
      adminId: map['admin_id']?.toString(),
      action: map['action']?.toString() ?? '',
      entityType: map['entity_type']?.toString() ?? '',
      entityId: map['entity_id']?.toString() ?? '',
      details: map['details'],
      ipAddress: map['ip_address']?.toString(),
      createdAt: map['created_at'] != null
          ? (DateTime.tryParse(map['created_at'].toString())?.toLocal() ?? DateTime.now())
          : DateTime.now(),
      adminEmail: adminEmail,
    );
  }
}

class AdminInternalNoteItem {
  const AdminInternalNoteItem({
    required this.id,
    required this.entityType,
    required this.entityId,
    this.authorId,
    required this.note,
    required this.createdAt,
    this.authorName,
  });

  final String id;
  final String entityType;
  final String entityId;
  final String? authorId;
  final String note;
  final DateTime createdAt;
  final String? authorName;

  factory AdminInternalNoteItem.fromMap(
    Map<String, dynamic> map, {
    String? authorName,
  }) {
    return AdminInternalNoteItem(
      id: map['id']?.toString() ?? '',
      entityType: map['entity_type']?.toString() ?? '',
      entityId: map['entity_id']?.toString() ?? '',
      authorId: map['author_id']?.toString(),
      note: map['note']?.toString() ?? '',
      createdAt: map['created_at'] != null
          ? (DateTime.tryParse(map['created_at'].toString())?.toLocal() ?? DateTime.now())
          : DateTime.now(),
      authorName: authorName,
    );
  }
}
