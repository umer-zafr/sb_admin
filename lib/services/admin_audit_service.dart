import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/config/supabase_config.dart';
import '../models/audit_log_model.dart';

class AdminAuditService {
  AdminAuditService._();
  static final instance = AdminAuditService._();

  SupabaseClient get _client => SupabaseConfig.client;

  Future<List<AdminAuditLogItem>> getAuditLogs({int limit = 60}) async {
    final res = await _client
        .from('admin_audit_logs')
        .select('*')
        .order('created_at', ascending: false)
        .limit(limit);
    final rows = List<Map<String, dynamic>>.from(res);

    final logs = <AdminAuditLogItem>[];
    for (final row in rows) {
      final aid = row['admin_id']?.toString() ?? '';
      String? adminEmail;
      if (aid.isNotEmpty) {
        final profile = await _client
            .from('profiles')
            .select('email')
            .eq('id', aid)
            .maybeSingle();
        adminEmail = profile?['email']?.toString();
      }
      logs.add(AdminAuditLogItem.fromMap(row, adminEmail: adminEmail));
    }
    return logs;
  }

  Future<List<AdminInternalNoteItem>> getNotes({
    required String entityType,
    required String entityId,
  }) async {
    final res = await _client
        .from('admin_notes')
        .select('*')
        .eq('entity_type', entityType)
        .eq('entity_id', entityId)
        .order('created_at', ascending: false);
    final rows = List<Map<String, dynamic>>.from(res);

    final notes = <AdminInternalNoteItem>[];
    for (final row in rows) {
      final aid = row['author_id']?.toString() ?? '';
      String? authorName;
      if (aid.isNotEmpty) {
        final profile = await _client
            .from('profiles')
            .select('full_name, email')
            .eq('id', aid)
            .maybeSingle();
        authorName =
            profile?['full_name']?.toString() ?? profile?['email']?.toString();
      }
      notes.add(AdminInternalNoteItem.fromMap(row, authorName: authorName));
    }
    return notes;
  }

  Future<void> addNote({
    required String entityType,
    required String entityId,
    required String note,
  }) async {
    final adminId = _client.auth.currentUser?.id;
    await _client.from('admin_notes').insert({
      'entity_type': entityType,
      'entity_id': entityId,
      'author_id': adminId,
      'note': note,
    });
  }
}
