import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/config/supabase_config.dart';
import '../models/admin_user.dart';
import '../models/application_model.dart';
import '../models/audit_log_model.dart';
import '../models/booking_model.dart';
import '../models/document_model.dart';
import '../models/payment_model.dart';

class UserDetailData {
  const UserDetailData({
    required this.profile,
    required this.applications,
    required this.bookings,
    required this.payments,
    required this.documents,
    required this.notes,
  });

  final AdminUserProfile profile;
  final List<ApplicationItem> applications;
  final List<ConsultancyBookingItem> bookings;
  final List<AdminPaymentItem> payments;
  final List<UserDocumentItem> documents;
  final List<AdminInternalNoteItem> notes;
}

class AdminUserService {
  AdminUserService._();
  static final instance = AdminUserService._();

  SupabaseClient get _client => SupabaseConfig.client;

  /// Fetch registered user profiles with their applications count
  Future<List<AdminUserProfile>> getUsers({
    String? searchQuery,
    String? roleFilter,
  }) async {
    var query = _client.from('profiles').select('*');

    if (roleFilter != null && roleFilter.isNotEmpty && roleFilter != 'all') {
      query = query.eq('role', roleFilter);
    } else {
      // By default, the registered clients view shows CLIENTS only (admins and staff are in Manage Team)
      query = query.neq('role', 'admin').neq('role', 'staff');
    }

    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final q = searchQuery.trim();
      query = query.or('full_name.ilike.%$q%,email.ilike.%$q%,phone.ilike.%$q%');
    }

    final res = await query.order('created_at', ascending: false);
    final rows = List<Map<String, dynamic>>.from(res);

    // Get application counts for users efficiently
    final users = <AdminUserProfile>[];
    for (final row in rows) {
      final uid = row['id']?.toString() ?? '';
      final appRows = await _client
          .from('applications')
          .select('id')
          .eq('user_id', uid);

      users.add(AdminUserProfile.fromMap(
        row,
        applicationsCount: (appRows as List).length,
        bookingsCount: 0,
      ));
    }
    return users;
  }

  /// Fetch complete dossier for a specific client
  Future<UserDetailData> getUserDetail(String userId) async {
    final profileRes =
        await _client.from('profiles').select('*').eq('id', userId).single();
    final profile = AdminUserProfile.fromMap(profileRes);

    final appsRes = await _client
        .from('applications')
        .select('*')
        .eq('user_id', userId)
        .order('applied_at', ascending: false);
    final applications = List<Map<String, dynamic>>.from(appsRes)
        .map(ApplicationItem.fromMap)
        .toList();

    // Payments guarded by RBAC
    List<AdminPaymentItem> payments = [];
    try {
      final paymentsRes = await _client
          .from('payments')
          .select('*')
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      payments = List<Map<String, dynamic>>.from(paymentsRes)
          .map(AdminPaymentItem.fromMap)
          .toList();
    } catch (_) {
      payments = [];
    }

    final docsRes = await _client
        .from('user_documents')
        .select('*')
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    final documents = List<Map<String, dynamic>>.from(docsRes)
        .map(UserDocumentItem.fromMap)
        .toList();

    final notesRes = await _client
        .from('admin_notes')
        .select('*')
        .eq('entity_type', 'user')
        .eq('entity_id', userId)
        .order('created_at', ascending: false);
    final notes = List<Map<String, dynamic>>.from(notesRes)
        .map(AdminInternalNoteItem.fromMap)
        .toList();

    return UserDetailData(
      profile: profile,
      applications: applications,
      bookings: const [],
      payments: payments,
      documents: documents,
      notes: notes,
    );
  }

  Future<void> updateUserRole(String userId, String newRole) async {
    await _client.from('profiles').update({
      'role': newRole,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', userId);
  }

  Future<void> toggleUserVerification(String userId, bool isVerified) async {
    await _client.from('profiles').update({
      'is_verified': isVerified,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', userId);
  }

  Future<void> addAdminNote(String userId, String noteText) async {
    final adminId = _client.auth.currentUser?.id;
    await _client.from('admin_notes').insert({
      'entity_type': 'user',
      'entity_id': userId,
      'author_id': adminId,
      'note': noteText,
    });
  }
}
