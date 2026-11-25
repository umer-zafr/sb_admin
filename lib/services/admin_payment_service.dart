import 'admin_application_service.dart';
import 'admin_push_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/config/supabase_config.dart';
import '../models/payment_model.dart';

class AdminPaymentService {
  AdminPaymentService._();
  static final instance = AdminPaymentService._();

  SupabaseClient get _client => SupabaseConfig.client;

  final List<AdminPaymentItem> _livePayments = [];

  void clearLivePayments() {
    _livePayments.clear();
  }

  void addLivePayment(AdminPaymentItem payment) {
    _livePayments.removeWhere((existing) =>
        existing.id == payment.id ||
        (existing.referenceId.isNotEmpty &&
            existing.referenceId.toLowerCase() == payment.referenceId.toLowerCase()) ||
        (existing.transactionId.isNotEmpty &&
            existing.transactionId.toLowerCase() == payment.transactionId.toLowerCase()));
    _livePayments.insert(0, payment);
  }

  List<AdminPaymentItem> get livePayments => List.unmodifiable(_livePayments);

  bool _matchesFilter(
    AdminPaymentItem payment,
    String? searchQuery,
    String? statusFilter,
    String? methodFilter,
  ) {
    if (statusFilter != null && statusFilter.isNotEmpty && statusFilter != 'all') {
      if (payment.status.toLowerCase() != statusFilter.toLowerCase()) return false;
    }
    if (methodFilter != null && methodFilter.isNotEmpty && methodFilter != 'all') {
      if (!payment.paymentMethod.toLowerCase().contains(methodFilter.toLowerCase())) return false;
    }
    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final q = searchQuery.trim().toLowerCase();
      final match = payment.transactionId.toLowerCase().contains(q) ||
          payment.referenceId.toLowerCase().contains(q) ||
          (payment.userName?.toLowerCase().contains(q) ?? false) ||
          (payment.userEmail?.toLowerCase().contains(q) ?? false);
      if (!match) return false;
    }
    return true;
  }

  Future<List<AdminPaymentItem>> getPayments({
    String? searchQuery,
    String? statusFilter,
    String? methodFilter,
  }) async {
    var query = _client.from('payments').select('*');

    if (statusFilter != null && statusFilter.isNotEmpty && statusFilter != 'all') {
      query = query.eq('status', statusFilter);
    }
    if (methodFilter != null && methodFilter.isNotEmpty && methodFilter != 'all') {
      query = query.eq('payment_method', methodFilter);
    }
    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final q = searchQuery.trim();
      query = query.or('transaction_id.ilike.%$q%,reference_id.ilike.%$q%,promo_code.ilike.%$q%');
    }

    final res = await query.order('created_at', ascending: false);
    final rows = List<Map<String, dynamic>>.from(res);

    final payments = <AdminPaymentItem>[];
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

      payments.add(AdminPaymentItem.fromMap(
        row,
        userName: userName,
        userEmail: userEmail,
      ));
    }

    final combined = <AdminPaymentItem>[];
    final seen = <String>{};

    for (final live in _livePayments) {
      if (_matchesFilter(live, searchQuery, statusFilter, methodFilter)) {
        combined.add(live);
        if (live.transactionId.isNotEmpty) seen.add(live.transactionId.toLowerCase());
        if (live.referenceId.isNotEmpty) seen.add(live.referenceId.toLowerCase());
        if (live.id.isNotEmpty) seen.add(live.id.toLowerCase());
      }
    }

    for (final dbPay in payments) {
      final txLow = dbPay.transactionId.toLowerCase();
      final refLow = dbPay.referenceId.toLowerCase();
      final idLow = dbPay.id.toLowerCase();
      if (!seen.contains(txLow) && !seen.contains(refLow) && !seen.contains(idLow)) {
        combined.add(dbPay);
        if (txLow.isNotEmpty) seen.add(txLow);
        if (refLow.isNotEmpty) seen.add(refLow);
        if (idLow.isNotEmpty) seen.add(idLow);
      }
    }

    return combined;
  }

  Future<void> updatePaymentStatus(String paymentId, String status) async {
    String? matchedRef;
    String? matchedAppId;

    for (int i = 0; i < _livePayments.length; i++) {
      if (_livePayments[i].id == paymentId ||
          _livePayments[i].transactionId == paymentId ||
          _livePayments[i].referenceId == paymentId) {
        _livePayments[i] = _livePayments[i].copyWith(status: status);
        matchedRef = _livePayments[i].referenceId;
      }
    }
    final nowStr = DateTime.now().toIso8601String();
    try {
      await _client.from('payments').update({
        'status': status,
        'updated_at': nowStr,
      }).eq('id', paymentId);
    } catch (_) {}

    if (status == 'completed' || status == 'success') {
      try {
        final paymentRow = await _client
            .from('payments')
            .select('*')
            .eq('id', paymentId)
            .maybeSingle();

        final userId = paymentRow?['user_id']?.toString();
        final refId = paymentRow?['reference_id']?.toString() ?? matchedRef ?? '';
        final cleanRef = refId.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toLowerCase();
        final appId = paymentRow?['application_id']?.toString();
        matchedAppId = appId;

        // Determine if payment is for Scholarships or Sponsored Jobs (strictly isolated)
        final listingId = (paymentRow?['listing_id']?.toString() ?? '').toLowerCase();
        final lowRef = refId.toLowerCase();

        bool isScholarship = listingId.contains('scholarship') ||
            lowRef.contains('scholarship') ||
            lowRef.startsWith('sb-sc') ||
            lowRef.contains('-sc-');

        bool isJob = !isScholarship && (
            listingId.contains('job') ||
            lowRef.contains('job') ||
            lowRef.startsWith('sb-wv') ||
            lowRef.contains('-wv-')
        );

        if (!isScholarship && !isJob) {
          for (final a in AdminApplicationService.instance.liveApplications) {
            final appCleanRef = a.referenceNumber.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toLowerCase();
            if (a.id == matchedAppId || (cleanRef.isNotEmpty && appCleanRef.contains(cleanRef))) {
              final cat = a.categoryType.toLowerCase();
              final t = a.title.toLowerCase();
              if (cat.contains('scholarship') || t.contains('scholarship')) {
                isScholarship = true;
                break;
              } else if (cat.contains('job') || t.contains('job')) {
                isJob = true;
                break;
              }
            }
          }
        }

        // 1. Directory unlocks for Scholarships & Sponsored Jobs (Strict Separation)
        if (userId != null && userId.isNotEmpty) {
          if (isScholarship) {
            try {
              await _client.from('user_directory_unlocks').upsert({
                'user_id': userId,
                'directory_type': 'scholarships',
                'payment_id': paymentId,
                'is_active': true,
                'updated_at': nowStr,
              }, onConflict: 'user_id, directory_type');
            } catch (_) {}
          } else if (isJob) {
            try {
              await _client.from('user_directory_unlocks').upsert({
                'user_id': userId,
                'directory_type': 'sponsored_jobs',
                'payment_id': paymentId,
                'is_active': true,
                'updated_at': nowStr,
              }, onConflict: 'user_id, directory_type');
            } catch (_) {}
          }
        }

        // 2. Application verification in memory
        for (final app in AdminApplicationService.instance.liveApplications) {
          final appCleanRef = app.referenceNumber.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toLowerCase();
          if (app.id == matchedAppId || (cleanRef.isNotEmpty && appCleanRef.contains(cleanRef))) {
            matchedAppId ??= app.id;
            matchedRef = app.referenceNumber;
            AdminApplicationService.instance.addLiveApplication(app.copyWith(
              status: 'submitted',
              statusLabel: 'Profile Review',
              statusBgColor: 0xFFEDF3F9,
              statusTextColor: 0xFF3D6186,
              hasAlert: false,
              alertTitle: null,
              alertBody: null,
              currentStep: 1,
              stepText: 'Step 1 of 5: Profile Review',
              progressPercent: 20,
            ));
          }
        }

        // 3. Application verification in Database
        String? targetAppId = matchedAppId;
        if (targetAppId == null && refId.isNotEmpty) {
          try {
            var matchingApp = await _client
                .from('applications')
                .select('id, category_type, title')
                .eq('reference_number', refId.trim())
                .maybeSingle();

            if (matchingApp == null && refId.contains('PAY-')) {
              final strippedRef = refId.replaceFirst('PAY-', '').trim();
              matchingApp = await _client
                  .from('applications')
                  .select('id, category_type, title')
                  .eq('reference_number', strippedRef)
                  .maybeSingle();
            }

            if (matchingApp == null && cleanRef.isNotEmpty) {
              matchingApp = await _client
                  .from('applications')
                  .select('id, category_type, title')
                  .ilike('reference_number', '%$cleanRef%')
                  .maybeSingle();
            }

            if (matchingApp == null && userId != null && userId.isNotEmpty) {
              final userApps = await _client
                  .from('applications')
                  .select('id, category_type, title')
                  .eq('user_id', userId)
                  .order('applied_at', ascending: false)
                  .limit(1);
              if (userApps.isNotEmpty) {
                matchingApp = userApps.first;
              }
            }

            if (!isScholarship && !isJob && matchingApp != null) {
              final cat = (matchingApp['category_type']?.toString() ?? '').toLowerCase();
              final t = (matchingApp['title']?.toString() ?? '').toLowerCase();
              if (cat.contains('scholarship') || t.contains('scholarship')) {
                isScholarship = true;
              } else if (cat.contains('job') || t.contains('job')) {
                isJob = true;
              }
              if (userId != null && userId.isNotEmpty) {
                if (isScholarship) {
                  try {
                    await _client.from('user_directory_unlocks').upsert({
                      'user_id': userId,
                      'directory_type': 'scholarships',
                      'payment_id': paymentId,
                      'is_active': true,
                      'updated_at': nowStr,
                    }, onConflict: 'user_id, directory_type');
                  } catch (_) {}
                } else if (isJob) {
                  try {
                    await _client.from('user_directory_unlocks').upsert({
                      'user_id': userId,
                      'directory_type': 'sponsored_jobs',
                      'payment_id': paymentId,
                      'is_active': true,
                      'updated_at': nowStr,
                    }, onConflict: 'user_id, directory_type');
                  } catch (_) {}
                }
              }
            }

            targetAppId = matchingApp?['id']?.toString();
          } catch (_) {}
        }

        if (targetAppId != null) {
          try {
            final appRow = await _client
                .from('applications')
                .select('form_data')
                .eq('id', targetAppId)
                .maybeSingle();

            final formData = Map<String, dynamic>.from(appRow?['form_data'] as Map? ?? {});
            formData['payment_verified'] = true;

            await _client.from('applications').update({
              'payment_status': 'completed',
              'status': 'submitted',
              'status_label': 'Profile Review',
              'status_bg_color': 0xFFEDF3F9,
              'status_text_color': 0xFF3D6186,
              'has_alert': false,
              'alert_title': null,
              'alert_body': null,
              'current_step': 1,
              'step_text': 'Step 1 of 5: Profile Review',
              'progress_percent': 20,
              'form_data': formData,
              'updated_at': nowStr,
            }).eq('id', targetAppId);

            await _client.from('payments').update({
              'application_id': targetAppId,
              'status': status,
            }).eq('id', paymentId);
          } catch (_) {}
        }

        // 4. Broadcast real-time event to mobile apps to auto-unlock directory & update application status
        try {
          final String? directoryType = isScholarship
              ? 'scholarships'
              : (isJob ? 'sponsored_jobs' : null);

          final syncPayload = {
            'payment_id': paymentId,
            'user_id': userId,
            'application_id': targetAppId ?? matchedAppId,
            'reference_number': matchedRef ?? refId,
            'status': 'submitted',
            'status_label': 'Profile Review',
            'step_text': 'Step 1 of 5: Profile Review',
            'progress_percent': 20,
            if (directoryType != null) 'directory_type': directoryType,
          };
          final ch = _client.channel('admin-dashboard-realtime-channel');
          await ch.sendBroadcastMessage(
            event: 'payment_verified',
            payload: syncPayload,
          );
          await ch.sendBroadcastMessage(
            event: 'payment_approved',
            payload: syncPayload,
          );
          if (directoryType != null) {
            await ch.sendBroadcastMessage(
              event: 'directory_unlocked',
              payload: syncPayload,
            );
          }
          await ch.sendBroadcastMessage(
            event: 'application_updated',
            payload: syncPayload,
          );

          // Dispatch external push notification to the applicant via OneSignal
          if (userId != null && userId.isNotEmpty) {
            final pushTitle = isScholarship
                ? 'SB Consultants • Scholarships Unlocked! 🎓'
                : (isJob
                    ? 'SB Consultants • Jobs Unlocked! 💼'
                    : 'SB Consultants • Payment Verified! ✅');
            final pushBody = isScholarship
                ? 'Your scholarship directory access has been activated.'
                : (isJob
                    ? 'Your sponsored jobs directory access has been activated.'
                    : 'Your payment (Ref: ${matchedRef ?? refId}) was verified. Dossier in active review.');
            final route = isScholarship
                ? '/scholarships'
                : (isJob ? '/sponsored-jobs' : '/dashboard');

            AdminPushService.instance.sendToUser(
              userId: userId,
              title: pushTitle,
              message: pushBody,
              route: route,
            );
          }
        } catch (_) {}
      } catch (_) {}
    }
  }
}
