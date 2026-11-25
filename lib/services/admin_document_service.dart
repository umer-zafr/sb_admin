import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/config/supabase_config.dart';
import '../models/document_model.dart';

class AdminDocumentService {
  AdminDocumentService._();
  static final instance = AdminDocumentService._();

  SupabaseClient get _client => SupabaseConfig.client;

  Future<List<UserDocumentItem>> getDocuments({
    String? searchQuery,
    String? statusFilter,
    String? typeFilter,
  }) async {
    var query = _client.from('user_documents').select('*');

    if (statusFilter != null && statusFilter.isNotEmpty && statusFilter != 'all') {
      query = query.eq('status', statusFilter);
    }
    if (typeFilter != null && typeFilter.isNotEmpty && typeFilter != 'all') {
      query = query.eq('document_type', typeFilter);
    }
    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final q = searchQuery.trim();
      query = query.or('title.ilike.%$q%,file_name.ilike.%$q%');
    }

    final res = await query.order('created_at', ascending: false);
    final rows = List<Map<String, dynamic>>.from(res);

    final documents = <UserDocumentItem>[];
    for (final row in rows) {
      final uid = row['user_id']?.toString() ?? '';
      String? userName;
      String? userEmail;

      if (uid.isNotEmpty) {
        final profile = await _client
            .from('profiles')
            .select('full_name, email')
            .eq('id', uid)
            .maybeSingle();
        userName = profile?['full_name']?.toString();
        userEmail = profile?['email']?.toString();
      }

      documents.add(UserDocumentItem.fromMap(
        row,
        userName: userName,
        userEmail: userEmail,
      ));
    }
    return documents;
  }

  Future<void> updateDocumentVerification(
    String documentId,
    String status,
    String? verificationNotes,
  ) async {
    await _client.from('user_documents').update({
      'status': status,
      'verification_notes': verificationNotes,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', documentId);

    await _logAudit('verify_document', 'user_document', documentId, {
      'status': status,
      'notes': verificationNotes,
    });
  }

  /// Secure signed URL generator for non-public storage buckets (expires in 60 minutes)
  Future<String> getSignedDownloadUrl(String storagePath) async {
    return _client.storage
        .from('app-documents')
        .createSignedUrl(storagePath, 3600);
  }

  Future<void> _logAudit(
    String action,
    String entityType,
    String entityId,
    Map<String, dynamic> details,
  ) async {
    try {
      final adminId = _client.auth.currentUser?.id;
      await _client.from('admin_audit_logs').insert({
        'admin_id': adminId,
        'action': action,
        'entity_type': entityType,
        'entity_id': entityId,
        'details': details,
      });
    } catch (_) {}
  }
}
