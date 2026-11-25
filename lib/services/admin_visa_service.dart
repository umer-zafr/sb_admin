import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/config/supabase_config.dart';
import '../models/visa_model.dart';

class AdminVisaService {
  AdminVisaService._();
  static final instance = AdminVisaService._();

  SupabaseClient get _client => SupabaseConfig.client;

  Future<List<VisaListingItem>> getVisas({
    String? searchQuery,
    String? categoryId,
    String? countryId,
    bool? isActive,
  }) async {
    var query = _client.from('visa_listings').select('*');

    if (categoryId != null && categoryId.isNotEmpty && categoryId != 'all') {
      query = query.eq('category_id', categoryId);
    }
    if (countryId != null && countryId.isNotEmpty && countryId != 'all') {
      query = query.eq('country_id', countryId);
    }
    if (isActive != null) {
      query = query.eq('is_active', isActive);
    }
    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final q = searchQuery.trim();
      query = query.or('title.ilike.%$q%,country_name.ilike.%$q%');
    }

    final res = await query.order('is_featured', ascending: false).order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(res)
        .map(VisaListingItem.fromMap)
        .toList();
  }

  Future<List<VisaCategoryItem>> getCategories() async {
    final res = await _client
        .from('visa_categories')
        .select('*')
        .order('row_number', ascending: true)
        .order('display_order', ascending: true);
    return List<Map<String, dynamic>>.from(res)
        .map(VisaCategoryItem.fromMap)
        .toList();
  }

  Future<List<CountryItem>> getCountries() async {
    final res = await _client
        .from('countries')
        .select('*')
        .order('display_order', ascending: true);
    return List<Map<String, dynamic>>.from(res)
        .map(CountryItem.fromMap)
        .toList();
  }

  Future<void> createVisa(Map<String, dynamic> data) async {
    final titleSlug = (data['title']?.toString() ?? 'visa')
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]'), '-')
        .replaceAll(RegExp(r'-+'), '-')
        .trim();
    final countrySlug = (data['country_name']?.toString() ?? '')
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]'), '-')
        .replaceAll(RegExp(r'-+'), '-')
        .trim();
    final baseSlug = countrySlug.isNotEmpty ? '$countrySlug-$titleSlug' : titleSlug;
    final cleanId = data['id'] ?? '$baseSlug-${DateTime.now().millisecondsSinceEpoch % 10000}';
    final payload = Map<String, dynamic>.from(data)..['id'] = cleanId;

    await _client.from('visa_listings').insert(payload);
    await _syncFeaturedBanner(cleanId, data);

    await _logAudit('create_visa', 'visa_listing', cleanId, {'title': data['title']});
  }

  Future<void> updateVisa(String id, Map<String, dynamic> data) async {
    final payload = Map<String, dynamic>.from(data)
      ..['updated_at'] = DateTime.now().toIso8601String();
    await _client.from('visa_listings').update(payload).eq('id', id);
    await _syncFeaturedBanner(id, data);

    await _logAudit('update_visa', 'visa_listing', id, {'title': data['title']});
  }

  Future<void> toggleVisaStatus(String id, bool isActive) async {
    await _client.from('visa_listings').update({
      'is_active': isActive,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', id);

    // Synchronize carousel banner status
    try {
      if (!isActive) {
        await _client
            .from('promotional_banners')
            .update({'is_active': false, 'updated_at': DateTime.now().toIso8601String()})
            .eq('id', 'banner_visa_$id');
      } else {
        final visaRes = await _client.from('visa_listings').select('*').eq('id', id).maybeSingle();
        if (visaRes != null && visaRes['is_featured'] == true) {
          await _syncFeaturedBanner(id, visaRes);
        }
      }
    } catch (_) {}

    await _logAudit(
      isActive ? 'publish_visa' : 'unpublish_visa',
      'visa_listing',
      id,
      {'is_active': isActive},
    );
  }

  Future<void> toggleVisaFeatured(String id, bool isFeatured) async {
    await _client.from('visa_listings').update({
      'is_featured': isFeatured,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', id);

    final visaRes =
        await _client.from('visa_listings').select('*').eq('id', id).maybeSingle();
    if (visaRes != null) {
      final payload = Map<String, dynamic>.from(visaRes)
        ..['is_featured'] = isFeatured;
      await _syncFeaturedBanner(id, payload);
    }

    await _logAudit(
      isFeatured ? 'feature_visa_carousel' : 'unfeature_visa_carousel',
      'visa_listing',
      id,
      {'is_featured': isFeatured},
    );
  }

  Future<void> deleteVisa(String id) async {
    try {
      await _client.from('saved_items').delete().eq('listing_id', id);
    } catch (_) {}
    try {
      await _client.from('promotional_banners').delete().eq('id', 'banner_visa_$id');
    } catch (_) {}
    await _client.from('visa_listings').delete().eq('id', id);
    await _logAudit('delete_visa', 'visa_listing', id, {});
  }

  /// Automatically synchronizes the "Feature on Homepage Carousel" switch directly into
  /// the promotional_banners table so the customer mobile app hero carousel updates instantly.
  Future<void> _syncFeaturedBanner(String visaId, Map<String, dynamic> data) async {
    final actionUrl = '/visa-detail/$visaId';
    final isFeatured = data['is_featured'] == true;
    final isActive = data['is_active'] != false;

    try {
      if (isFeatured && isActive) {
        final bannerTitle = data['title']?.toString() ?? 'Featured Visa Program';
        final bannerSubtitle = data['subtitle']?.toString() ??
            '${data['country_name'] ?? 'International'} • High Success Rate • Apply with SB Consultants';
        final imageUrl = data['image_url']?.toString();

        final existing = await _client
            .from('promotional_banners')
            .select('id')
            .eq('action_url', actionUrl)
            .maybeSingle();

        final nowIso = DateTime.now().toIso8601String();
        final payload = {
          'title': bannerTitle,
          'subtitle': bannerSubtitle,
          'badge': 'FEATURED OPPORTUNITY',
          'action_text': 'Apply Now',
          'action_url': actionUrl,
          'gradient_start': '0xFF002444',
          'gradient_end': '0xFF1B3A5C',
          'placement': 'all',
          'category_name': data['category_name']?.toString() ?? 'Featured Visas',
          'is_active': true,
          'image_url': imageUrl,
          'display_order': 0,
          'updated_at': nowIso,
        };

        if (existing != null) {
          await _client
              .from('promotional_banners')
              .update(payload)
              .eq('id', existing['id']);
        } else {
          payload['created_at'] = nowIso;
          await _client.from('promotional_banners').insert(payload);
        }
      } else {
        await _client
            .from('promotional_banners')
            .delete()
            .eq('action_url', actionUrl);
      }
    } catch (_) {}
  }

  Future<void> createCategory(Map<String, dynamic> data) async {
    await _client.from('visa_categories').insert(data);
    await _logAudit('create_category', 'visa_category', data['id']?.toString() ?? '', data);
  }

  Future<void> updateCategory(String id, Map<String, dynamic> data) async {
    await _client.from('visa_categories').update(data).eq('id', id);
    await _logAudit('update_category', 'visa_category', id, data);
  }

  Future<void> deleteCategory(String id) async {
    // Check if any visa listings reference this category
    final referencingVisas = await _client
        .from('visa_listings')
        .select('id, title')
        .eq('category_id', id);

    if (referencingVisas.isNotEmpty) {
      throw Exception(
        'Cannot delete category "$id": ${referencingVisas.length} visa listing(s) currently belong to it. Please delete or reassign those visa listings first.',
      );
    }

    await _client.from('visa_categories').delete().eq('id', id);
    await _logAudit('delete_category', 'visa_category', id, {});
  }

  Future<String> uploadAsset(
    Uint8List bytes,
    String fileName,
    String mimeType,
  ) async {
    final path = 'visas/${DateTime.now().millisecondsSinceEpoch}_$fileName';
    await _client.storage.from('public-assets').uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(contentType: mimeType),
        );
    return _client.storage.from('public-assets').getPublicUrl(path);
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
