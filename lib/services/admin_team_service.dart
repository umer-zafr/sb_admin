import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/config/supabase_config.dart';
import '../models/admin_user.dart';
import '../models/staff_invitation_model.dart';

enum TeamAccessResultType {
  instantGranted,
  invitationCreated,
}

class TeamAccessResult {
  const TeamAccessResult({
    required this.type,
    required this.email,
    required this.role,
    required this.message,
    this.user,
    this.invitation,
    this.inviteLink,
    this.emailSent = false,
    this.password,
    this.fullName,
  });

  final TeamAccessResultType type;
  final String email;
  final String role;
  final String message;
  final AdminUserProfile? user;
  final StaffInvitation? invitation;
  final String? inviteLink;
  final bool emailSent;
  final String? password;
  final String? fullName;

  bool get isInstant => type == TeamAccessResultType.instantGranted;
}

class AdminTeamService {
  AdminTeamService._();
  static final instance = AdminTeamService._();

  SupabaseClient get _client => SupabaseConfig.client;

  /// Fetch all active administrative and staff members (role = 'admin' or 'consultant')
  Future<List<AdminUserProfile>> getTeamMembers({
    String? searchQuery,
    String? roleFilter,
  }) async {
    var query = _client.from('profiles').select('*');

    if (roleFilter != null && roleFilter.isNotEmpty && roleFilter != 'all') {
      query = query.eq('role', roleFilter);
    } else {
      query = query.inFilter('role', ['admin', 'consultant']);
    }

    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final q = searchQuery.trim();
      query = query.or('full_name.ilike.%$q%,email.ilike.%$q%,phone.ilike.%$q%');
    }

    final res = await query.order('created_at', ascending: false);
    final rows = List<Map<String, dynamic>>.from(res);

    // Sort to keep admins first, then consultants
    final members = rows.map((r) => AdminUserProfile.fromMap(r)).toList();
    members.sort((a, b) {
      if (a.isAdmin && !b.isAdmin) return -1;
      if (!a.isAdmin && b.isAdmin) return 1;
      return a.createdAt.compareTo(b.createdAt);
    });

    return members;
  }

  /// Fetch all pending, pre-provisioned invitations
  Future<List<StaffInvitation>> getPendingInvitations() async {
    final res = await _client
        .from('staff_invitations')
        .select('*')
        .eq('status', 'pending')
        .order('created_at', ascending: false);
    final rows = List<Map<String, dynamic>>.from(res);
    return rows.map((r) => StaffInvitation.fromMap(r)).toList();
  }

  /// Direct Staff Account Provisioning (Option 1 - No Email Server Required):
  /// Creates active user credentials immediately with password and pre-confirmed email.
  Future<TeamAccessResult> createStaffDirect({
    required String fullName,
    required String email,
    required String password,
    required String role,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    final cleanName = fullName.trim();
    final cleanPass = password.trim();

    if (cleanEmail.isEmpty || !cleanEmail.contains('@')) {
      throw Exception('Please enter a valid email address.');
    }
    if (cleanPass.length < 6) {
      throw Exception('Password must be at least 6 characters long.');
    }
    if (role != 'admin' && role != 'consultant') {
      throw Exception('Invalid role specified.');
    }

    final response = await _client.functions.invoke(
      'invite-staff',
      body: {
        'email': cleanEmail,
        'role': role,
        'full_name': cleanName,
        'password': cleanPass,
      },
    );

    final data = response.data is Map<String, dynamic>
        ? response.data as Map<String, dynamic>
        : <String, dynamic>{};

    if (data['error'] != null) {
      throw Exception(data['error'].toString());
    }

    final updated = await _client
        .from('profiles')
        .select('*')
        .ilike('email', cleanEmail)
        .maybeSingle();

    return TeamAccessResult(
      type: TeamAccessResultType.instantGranted,
      email: cleanEmail,
      role: role,
      password: cleanPass,
      fullName: cleanName,
      user: updated != null ? AdminUserProfile.fromMap(updated) : null,
      message: 'Staff account successfully created and activated immediately!',
    );
  }

  /// Industry-Standard Team Access Provisioning:
  /// Uses Supabase Edge Function 'invite-staff' to generate direct auth activation link,
  /// trigger outgoing email dispatch, and auto-provision in PostgreSQL.
  Future<TeamAccessResult> inviteOrGrantAccess({
    required String email,
    required String role,
    String? fullName,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    if (cleanEmail.isEmpty) {
      throw Exception('Please enter a valid email address.');
    }
    if (role != 'admin' && role != 'consultant') {
      throw Exception('Invalid role specified. Must be either Administrator or Consultant.');
    }

    final currentAdminId = _client.auth.currentUser?.id;

    // Call the invite-staff Edge Function for auth provisioning and email dispatch
    try {
      final response = await _client.functions.invoke(
        'invite-staff',
        body: {
          'email': cleanEmail,
          'role': role,
          'full_name': fullName?.trim(),
          'redirect_url': 'sbconsultants://login-callback',
        },
      );

      final data = response.data is Map<String, dynamic>
          ? response.data as Map<String, dynamic>
          : <String, dynamic>{};

      final isInstant = data['is_instant'] == true;
      final inviteLink = data['invite_link']?.toString();
      final emailSent = data['email_sent'] == true;
      final message = data['message']?.toString() ??
          (isInstant
              ? 'Successfully granted $role privileges to $cleanEmail.'
              : 'Invitation created for $cleanEmail.');

      if (isInstant) {
        final updated = await _client
            .from('profiles')
            .select('*')
            .ilike('email', cleanEmail)
            .maybeSingle();

        return TeamAccessResult(
          type: TeamAccessResultType.instantGranted,
          email: cleanEmail,
          role: role,
          user: updated != null ? AdminUserProfile.fromMap(updated) : null,
          message: message,
          inviteLink: inviteLink,
          emailSent: emailSent,
        );
      }

      // Invitation created
      final savedInvite = await _client
          .from('staff_invitations')
          .select('*')
          .ilike('email', cleanEmail)
          .eq('status', 'pending')
          .maybeSingle();

      return TeamAccessResult(
        type: TeamAccessResultType.invitationCreated,
        email: cleanEmail,
        role: role,
        invitation:
            savedInvite != null ? StaffInvitation.fromMap(savedInvite) : null,
        message: message,
        inviteLink: inviteLink,
        emailSent: emailSent,
      );
    } catch (e) {
      // Fallback: If edge function invoke fails, perform database fallback
      return _fallbackDbInvite(
        cleanEmail: cleanEmail,
        role: role,
        currentAdminId: currentAdminId,
      );
    }
  }

  Future<TeamAccessResult> _fallbackDbInvite({
    required String cleanEmail,
    required String role,
    required String? currentAdminId,
  }) async {
    final existingUser = await _client
        .from('profiles')
        .select('*')
        .ilike('email', cleanEmail)
        .maybeSingle();

    if (existingUser != null) {
      final userId = existingUser['id']?.toString() ?? '';
      await _client.from('profiles').update({
        'role': role,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', userId);

      final updated = await _client.from('profiles').select('*').eq('id', userId).single();
      return TeamAccessResult(
        type: TeamAccessResultType.instantGranted,
        email: cleanEmail,
        role: role,
        user: AdminUserProfile.fromMap(updated),
        message: 'Successfully elevated $cleanEmail to ${role.toUpperCase()}.',
      );
    }

    final existingInvite = await _client
        .from('staff_invitations')
        .select('*')
        .ilike('email', cleanEmail)
        .eq('status', 'pending')
        .maybeSingle();

    Map<String, dynamic> savedInvite;
    if (existingInvite != null) {
      final res = await _client
          .from('staff_invitations')
          .update({
            'role': role,
            'invited_by': currentAdminId,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', existingInvite['id'])
          .select('*')
          .single();
      savedInvite = Map<String, dynamic>.from(res);
    } else {
      final res = await _client
          .from('staff_invitations')
          .insert({
            'email': cleanEmail,
            'role': role,
            'invited_by': currentAdminId,
            'status': 'pending',
          })
          .select('*')
          .single();
      savedInvite = Map<String, dynamic>.from(res);
    }

    return TeamAccessResult(
      type: TeamAccessResultType.invitationCreated,
      email: cleanEmail,
      role: role,
      invitation: StaffInvitation.fromMap(savedInvite),
      message: 'Invitation pre-provisioned for $cleanEmail. As soon as they register or log in, their permissions activate.',
    );
  }

  /// Cancel or revoke a pending invitation
  Future<void> cancelInvitation(String invitationId) async {
    final currentAdminId = _client.auth.currentUser?.id;

    await _client.from('staff_invitations').update({
      'status': 'revoked',
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', invitationId);

    try {
      await _client.from('admin_audit_logs').insert({
        'admin_id': currentAdminId,
        'action': 'cancel_staff_invitation',
        'entity_type': 'staff_invitation',
        'entity_id': invitationId,
        'details': {
          'timestamp': DateTime.now().toIso8601String(),
        },
      });
    } catch (_) {}
  }

  /// Update an existing team member's role (e.g. promote consultant to admin or vice versa)
  Future<void> updateMemberRole({
    required String userId,
    required String newRole,
  }) async {
    if (newRole != 'admin' && newRole != 'consultant') {
      throw Exception('Invalid role specified.');
    }

    final currentAdminId = _client.auth.currentUser?.id;
    if (userId == currentAdminId && newRole != 'admin') {
      throw Exception('Security Restriction: You cannot demote your own administrator account.');
    }

    await _client.from('profiles').update({
      'role': newRole,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', userId);

    try {
      await _client.from('admin_audit_logs').insert({
        'admin_id': currentAdminId,
        'action': 'update_member_role',
        'entity_type': 'user_role',
        'entity_id': userId,
        'details': {
          'new_role': newRole,
          'timestamp': DateTime.now().toIso8601String(),
        },
      });
    } catch (_) {}
  }

  /// Revoke administrative/consultant dashboard access (downgrades user back to regular client)
  Future<void> revokeAccess({
    required String userId,
  }) async {
    final currentAdminId = _client.auth.currentUser?.id;
    if (userId == currentAdminId) {
      throw Exception('Security Restriction: You cannot revoke dashboard access from your own account.');
    }

    await _client.from('profiles').update({
      'role': 'user',
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', userId);

    try {
      await _client.from('admin_audit_logs').insert({
        'admin_id': currentAdminId,
        'action': 'revoke_team_access',
        'entity_type': 'user_role',
        'entity_id': userId,
        'details': {
          'action': 'revoked_to_regular_user',
          'timestamp': DateTime.now().toIso8601String(),
        },
      });
    } catch (_) {}
  }
}
