import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/config/supabase_config.dart';
import '../models/admin_banner_model.dart';

class AdminBannerService {
  AdminBannerService._();
  static final instance = AdminBannerService._();

  SupabaseClient get _client => SupabaseConfig.client;

  Future<String> uploadBannerImage(
    Uint8List bytes,
    String fileName,
    String mimeType,
  ) async {
    final path = 'banners/${DateTime.now().millisecondsSinceEpoch}_$fileName';
    await _client.storage.from('public-assets').uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(contentType: mimeType),
        );
    return _client.storage.from('public-assets').getPublicUrl(path);
  }

  Future<List<AdminBannerItem>> getBanners({
    String? placement,
    bool? isActive,
    String? searchQuery,
  }) async {
    var query = _client.from('promotional_banners').select('*');

    if (placement != null && placement != 'all' && placement.isNotEmpty) {
      query = query.eq('placement', placement);
    }

    if (isActive != null) {
      query = query.eq('is_active', isActive);
    }

    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final q = searchQuery.trim();
      query = query.or('title.ilike.%$q%,subtitle.ilike.%$q%,category_name.ilike.%$q%,badge.ilike.%$q%');
    }

    final res = await query
        .order('display_order', ascending: true)
        .order('created_at', ascending: false);

    final items = List<Map<String, dynamic>>.from(res)
        .map(AdminBannerItem.fromMap)
        .toList();
    items.sort((a, b) {
      if (a.displayOrder != b.displayOrder) {
        return a.displayOrder.compareTo(b.displayOrder);
      }
      final dateA = a.createdAt ?? DateTime(2000);
      final dateB = b.createdAt ?? DateTime(2000);
      return dateB.compareTo(dateA);
    });
    return items;
  }

  Future<void> createBanner(Map<String, dynamic> data) async {
    final payload = Map<String, dynamic>.from(data)
      ..['created_at'] = DateTime.now().toIso8601String()
      ..['updated_at'] = DateTime.now().toIso8601String();

    // Supabase will generate UUID if not provided
    final res = await _client.from('promotional_banners').insert(payload).select().single();
    final newId = res['id']?.toString() ?? 'new-banner';

    await _logAudit('create_promotional_banner', 'promotional_banner', newId, {
      'title': data['title'],
      'placement': data['placement'],
      'category_name': data['category_name'],
    });
  }

  Future<void> updateBanner(String id, Map<String, dynamic> data) async {
    final payload = Map<String, dynamic>.from(data)
      ..['updated_at'] = DateTime.now().toIso8601String();

    await _client.from('promotional_banners').update(payload).eq('id', id);
    await _logAudit('update_promotional_banner', 'promotional_banner', id, {
      'title': data['title'],
      'placement': data['placement'],
    });
  }

  Future<void> toggleBannerStatus(String id, bool isActive) async {
    await _client.from('promotional_banners').update({
      'is_active': isActive,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', id);

    await _logAudit(
      isActive ? 'activate_banner' : 'deactivate_banner',
      'promotional_banner',
      id,
      {'is_active': isActive},
    );
  }

  Future<void> deleteBanner(String id) async {
    await _client.from('promotional_banners').delete().eq('id', id);
    await _logAudit('delete_promotional_banner', 'promotional_banner', id, {});
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
