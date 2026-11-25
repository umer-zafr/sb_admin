class StaffInvitation {
  const StaffInvitation({
    required this.id,
    required this.email,
    required this.role,
    this.invitedBy,
    this.inviteLink,
    required this.status,
    required this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String email;
  final String role; // 'admin' or 'consultant'
  final String? invitedBy;
  final String? inviteLink;
  final String status; // 'pending', 'accepted', 'revoked'
  final DateTime createdAt;
  final DateTime? updatedAt;

  bool get isPending => status == 'pending';
  bool get isAdmin => role == 'admin';
  bool get isConsultant => role == 'consultant';

  factory StaffInvitation.fromMap(Map<String, dynamic> map) {
    return StaffInvitation(
      id: map['id']?.toString() ?? '',
      email: map['email']?.toString() ?? '',
      role: map['role']?.toString() ?? 'consultant',
      invitedBy: map['invited_by']?.toString(),
      inviteLink: map['invite_link']?.toString(),
      status: map['status']?.toString() ?? 'pending',
      createdAt: map['created_at'] != null
          ? (DateTime.tryParse(map['created_at'].toString())?.toLocal() ?? DateTime.now())
          : DateTime.now(),
      updatedAt: map['updated_at'] != null
          ? DateTime.tryParse(map['updated_at'].toString())?.toLocal()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'role': role,
      'invited_by': invitedBy,
      'invite_link': inviteLink,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}
