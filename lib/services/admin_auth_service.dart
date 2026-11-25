import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/config/supabase_config.dart';
import '../models/admin_user.dart';

class AdminAuthService {
  AdminAuthService._();
  static final instance = AdminAuthService._();

  SupabaseClient get _client => SupabaseConfig.client;

  User? get currentUser => _client.auth.currentUser;
  bool get isAuthenticated => currentUser != null;

  /// Sign in with email and password, then strictly verify that the user's role is 'admin'.
  /// If the role is not 'admin', the session is immediately terminated and access is denied.
  Future<AdminUserProfile> signIn({
    required String email,
    required String password,
  }) async {
    final authResponse = await _client.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );

    final user = authResponse.user;
    if (user == null) {
      throw Exception('Authentication failed: No user record returned.');
    }

    // Query profiles table to verify role
    final profileData = await _client
        .from('profiles')
        .select('*')
        .eq('id', user.id)
        .maybeSingle();

    if (profileData == null) {
      await _client.auth.signOut();
      throw Exception(
        'Access Denied: No profile found for this account. Only authorized administrative personnel may enter.',
      );
    }

    final profile = AdminUserProfile.fromMap(profileData);

    if (!profile.isStaff) {
      // User is not an admin or staff consultant! Sign out immediately to prevent unauthorized access.
      await _client.auth.signOut();
      throw Exception(
        'Access Denied: Your account (${profile.role.toUpperCase()}) does not have administrative dashboard privileges. Please contact your system administrator.',
      );
    }

    // Log the successful staff/admin login into audit logs
    try {
      await _client.from('admin_audit_logs').insert({
        'admin_id': user.id,
        'action': profile.isAdmin ? 'admin_login' : 'staff_login',
        'entity_type': 'auth',
        'entity_id': user.id,
        'details': {
          'email': user.email,
          'role': profile.role,
          'timestamp': DateTime.now().toIso8601String(),
        },
      });
    } catch (_) {
      // Audit log non-blocking
    }

    return profile;
  }

  /// Get current user profile and verify active administrative or staff role.
  Future<AdminUserProfile?> getCurrentProfile() async {
    final user = currentUser;
    if (user == null) return null;

    final profileData = await _client
        .from('profiles')
        .select('*')
        .eq('id', user.id)
        .maybeSingle();

    if (profileData == null) return null;
    final profile = AdminUserProfile.fromMap(profileData);

    if (!profile.isStaff) {
      await _client.auth.signOut();
      return null;
    }

    return profile;
  }

  Future<void> signOut() async {
    try {
      final user = currentUser;
      if (user != null) {
        await _client.from('admin_audit_logs').insert({
          'admin_id': user.id,
          'action': 'admin_logout',
          'entity_type': 'auth',
          'entity_id': user.id,
        });
      }
    } catch (_) {}
    await _client.auth.signOut();
  }
}
