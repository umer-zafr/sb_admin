import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/config/supabase_config.dart';
import '../models/affiliate_model.dart';

class AdminAffiliateService {
  AdminAffiliateService._();
  static final instance = AdminAffiliateService._();

  SupabaseClient get _client => SupabaseConfig.client;

  /// Fetch affiliates with search, status filters, and live referral metrics
  Future<List<AffiliateItem>> getAffiliates({
    String? status,
    String? searchQuery,
  }) async {
    var query = _client.from('affiliates').select('*');

    if (status != null && status != 'all' && status.isNotEmpty) {
      query = query.eq('status', status.toLowerCase());
    }

    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final q = searchQuery.trim();
      query = query.or(
        'name.ilike.%$q%,email.ilike.%$q%,phone.ilike.%$q%,city.ilike.%$q%,promo_code.ilike.%$q%',
      );
    }

    final res = await query.order('created_at', ascending: false);
    final rows = List<Map<String, dynamic>>.from(res);

    // Fetch live referral usage counts from payments table grouped by promo_code
    final promoCounts = <String, int>{};
    try {
      final paymentsRes = await _client
          .from('payments')
          .select('promo_code')
          .not('promo_code', 'is', null);

      for (final row in paymentsRes) {
        final code = row['promo_code']?.toString().trim().toUpperCase();
        if (code != null && code.isNotEmpty) {
          promoCounts[code] = (promoCounts[code] ?? 0) + 1;
        }
      }
    } catch (_) {
      // Non-blocking if payments table is empty or offline
    }

    return rows.map((row) {
      final pCode = row['promo_code']?.toString().trim().toUpperCase();
      final count = (pCode != null && promoCounts.containsKey(pCode))
          ? promoCounts[pCode]!
          : 0;
      return AffiliateItem.fromMap(row, referralCount: count);
    }).toList();
  }

  /// Approve an affiliate and automatically sync the promo code with discount rules
  /// into the promo_codes table for mobile app checkout recognition.
  Future<void> approveAffiliate({
    required String affiliateId,
    required String affiliateName,
    required String promoCode,
    required String discountType,
    required double discountValue,
    double commissionPerReferral = 1000.0,
    String? notes,
  }) async {
    final cleanCode = promoCode.trim().toUpperCase();
    final nowIso = DateTime.now().toIso8601String();

    // 1. Upsert promotional code record into Supabase promo_codes table
    // This allows clients in the mobile app checkout to immediately validate and receive discount!
    await _client.from('promo_codes').upsert({
      'code': cleanCode,
      'description': 'Affiliate partner voucher for $affiliateName',
      'discount_type': discountType, // 'percentage' or 'fixed'
      'discount_value': discountValue,
      'is_active': true,
      'min_order_amount': 0,
      'updated_at': nowIso,
    }, onConflict: 'code');

    // 2. Update affiliate status, assigned promo code, and terms
    await _client.from('affiliates').update({
      'status': 'approved',
      'promo_code': cleanCode,
      'discount_type': discountType,
      'discount_value': discountValue,
      'commission_per_referral': commissionPerReferral,
      if (notes != null) 'notes': notes,
      'updated_at': nowIso,
    }).eq('id', affiliateId);
  }

  /// Reject an affiliate application
  Future<void> rejectAffiliate(String affiliateId, {String? notes}) async {
    await _client.from('affiliates').update({
      'status': 'rejected',
      if (notes != null) 'notes': notes,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', affiliateId);
  }

  /// Delete an affiliate
  Future<void> deleteAffiliate(String affiliateId) async {
    await _client.from('affiliates').delete().eq('id', affiliateId);
  }

  /// Manually add an affiliate partner from dashboard
  Future<void> createManualAffiliate({
    required String name,
    required String email,
    required String phone,
    required String city,
    int totalFollowers = 0,
    List<String> platforms = const [],
    double commissionPerReferral = 1000.0,
    String? notes,
  }) async {
    await _client.from('affiliates').insert({
      'name': name.trim(),
      'email': email.trim().toLowerCase(),
      'phone': phone.trim(),
      'city': city.trim(),
      'total_followers': totalFollowers,
      'platforms': platforms,
      'status': 'pending',
      'commission_per_referral': commissionPerReferral,
      if (notes != null) 'notes': notes.trim(),
    });
  }
}

