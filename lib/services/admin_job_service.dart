import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/config/supabase_config.dart';
import '../models/job_model.dart';

class AdminJobService {
  AdminJobService._();
  static final instance = AdminJobService._();

  SupabaseClient get _client => SupabaseConfig.client;

  Future<List<SponsoredJobItem>> getJobs({
    String? searchQuery,
    bool? isActive,
  }) async {
    var query = _client.from('sponsored_jobs').select('*').eq('type', 'job');

    if (isActive != null) {
      query = query.eq('is_active', isActive);
    }
    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final q = searchQuery.trim();
      query = query.or('title.ilike.%$q%,company_or_institution.ilike.%$q%,location.ilike.%$q%');
    }

    final res = await query.order('is_featured', ascending: false).order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(res)
        .map(SponsoredJobItem.fromMap)
        .toList();
  }

  Future<List<SponsoredJobItem>> getScholarships({
    String? searchQuery,
    bool? isActive,
  }) async {
    var query = _client.from('sponsored_jobs').select('*').eq('type', 'scholarship');

    if (isActive != null) {
      query = query.eq('is_active', isActive);
    }
    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final q = searchQuery.trim();
      query = query.or('title.ilike.%$q%,company_or_institution.ilike.%$q%,location.ilike.%$q%');
    }

    final res = await query.order('is_featured', ascending: false).order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(res)
        .map(SponsoredJobItem.fromMap)
        .toList();
  }

  Future<void> createItem(Map<String, dynamic> data) async {
    final cleanId = data['id'] ??
        '${data['type']}-${DateTime.now().millisecondsSinceEpoch}';
    final payload = Map<String, dynamic>.from(data)..['id'] = cleanId;

    await _client.from('sponsored_jobs').insert(payload);

    await _logAudit(
      'create_${data['type']}',
      'sponsored_jobs',
      cleanId,
      {'title': data['title']},
    );
  }

  Future<void> updateItem(String id, Map<String, dynamic> data) async {
    final payload = Map<String, dynamic>.from(data)
      ..['updated_at'] = DateTime.now().toIso8601String();
    await _client.from('sponsored_jobs').update(payload).eq('id', id);

    await _logAudit(
      'update_${data['type'] ?? 'item'}',
      'sponsored_jobs',
      id,
      {'title': data['title']},
    );
  }

  Future<void> toggleStatus(String id, bool isActive, String type) async {
    await _client.from('sponsored_jobs').update({
      'is_active': isActive,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', id);

    await _logAudit(
      isActive ? 'publish_$type' : 'unpublish_$type',
      'sponsored_jobs',
      id,
      {'is_active': isActive},
    );
  }

  Future<void> deleteItem(String id, String type) async {
    await _client.from('sponsored_jobs').delete().eq('id', id);
    await _logAudit('delete_$type', 'sponsored_jobs', id, {});
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
