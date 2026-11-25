import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/config/supabase_config.dart';
import '../models/admin_success_story_model.dart';

class AdminSuccessStoryService {
  AdminSuccessStoryService._();
  static final instance = AdminSuccessStoryService._();

  SupabaseClient get _client => SupabaseConfig.client;

  Future<String> uploadStoryAvatar(
    Uint8List bytes,
    String fileName,
    String mimeType,
  ) async {
    final path = 'stories/${DateTime.now().millisecondsSinceEpoch}_$fileName';
    await _client.storage.from('public-assets').uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(contentType: mimeType),
        );
    return _client.storage.from('public-assets').getPublicUrl(path);
  }

  Future<List<AdminSuccessStoryItem>> getStories({
    String? searchQuery,
    bool? isPublished,
  }) async {
    var query = _client.from('success_stories').select('*');

    if (isPublished != null) {
      query = query.eq('is_published', isPublished);
    }

    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final q = searchQuery.trim();
      query = query.or('client_name.ilike.%$q%,visa_type.ilike.%$q%,country_name.ilike.%$q%');
    }

    final res = await query
        .order('display_order', ascending: true)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(res)
        .map(AdminSuccessStoryItem.fromMap)
        .toList();
  }

  Future<void> createStory(Map<String, dynamic> data) async {
    final cleanId = data['id'] ?? 'story-${DateTime.now().millisecondsSinceEpoch}';
    final payload = Map<String, dynamic>.from(data)
      ..['id'] = cleanId
      ..['created_at'] = DateTime.now().toIso8601String()
      ..['updated_at'] = DateTime.now().toIso8601String();

    await _client.from('success_stories').insert(payload);
    await _logAudit('create_success_story', 'success_story', cleanId, {
      'client_name': data['client_name'],
      'visa_type': data['visa_type'],
    });
  }

  Future<void> updateStory(String id, Map<String, dynamic> data) async {
    final payload = Map<String, dynamic>.from(data)
      ..['updated_at'] = DateTime.now().toIso8601String();

    await _client.from('success_stories').update(payload).eq('id', id);
    await _logAudit('update_success_story', 'success_story', id, {
      'client_name': data['client_name'],
      'visa_type': data['visa_type'],
    });
  }

  Future<void> togglePublish(String id, bool isPublished) async {
    await _client.from('success_stories').update({
      'is_published': isPublished,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', id);

    await _logAudit(
      isPublished ? 'publish_success_story' : 'unpublish_success_story',
      'success_story',
      id,
      {'is_published': isPublished},
    );
  }

  Future<void> deleteStory(String id) async {
    await _client.from('success_stories').delete().eq('id', id);
    await _logAudit('delete_success_story', 'success_story', id, {});
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
