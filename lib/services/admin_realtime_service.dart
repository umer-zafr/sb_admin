import 'admin_application_service.dart';
import 'admin_payment_service.dart';
import '../models/application_model.dart';
import '../models/payment_model.dart';
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/config/supabase_config.dart';
import '../models/admin_notification_model.dart';
import '../providers/admin_auth_provider.dart';
import '../providers/admin_dashboard_providers.dart';
import '../providers/admin_notification_provider.dart';

final adminRealtimeSyncProvider = Provider<void>((ref) {
  // Watch auth state to ensure channel is re-created with active JWT upon login
  ref.watch(adminAuthProvider);
  final client = SupabaseConfig.client;

  final session = client.auth.currentSession;
  if (session != null) {
    try {
      client.realtime.setAuth(session.accessToken);
    } catch (_) {}
  }

  // Set of known application IDs to deduplicate alerts across broadcast, postgres WAL, and polling
  final Set<String> knownApplicationIds = {};
  bool isInitialPoll = true;

  void handleNewApplicationAlert({
    required String? id,
    required String? title,
    required String? applicant,
    required String? refNum,
  }) {
    if (id != null && id.isNotEmpty) {
      if (knownApplicationIds.contains(id)) return;
      knownApplicationIds.add(id);
    }

    ref.read(dashboardMetricsRevisionProvider.notifier).increment();
    ref.read(applicationsRevisionProvider.notifier).increment();
    ref.read(bookingsRevisionProvider.notifier).increment();
    ref.invalidate(dashboardMetricsProvider);
    ref.invalidate(applicationsListProvider);
    ref.invalidate(bookingsListProvider);

    final effectiveTitle =
        (title != null && title.trim().isNotEmpty) ? title.trim() : 'Visa Application';
    final effectiveApplicant =
        (applicant != null && applicant.trim().isNotEmpty) ? applicant.trim() : 'Client';
    final effectiveRef =
        (refNum != null && refNum.trim().isNotEmpty) ? ' ($refNum)' : '';
    final appId = id ?? '';

    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final cleanRefNum = (refNum != null && refNum.isNotEmpty) ? refNum.replaceAll(RegExp(r'[()]'), '').trim() : 'SB-$nowMs';
    AdminApplicationService.instance.addLiveApplication(ApplicationItem(
      id: appId.isNotEmpty ? appId : 'app_$nowMs',
      userId: 'c0e78055-61c8-4642-afab-1e88a70659fb',
      referenceNumber: cleanRefNum,
      categoryType: 'VISA',
      title: effectiveTitle,
      applicantName: effectiveApplicant,
      status: 'under_review',
      statusLabel: 'Payment Under Verification',
      currentStep: 1,
      progressPercent: 10,
      appliedAt: DateTime.now(),
    ));

    final notification = AdminNotificationItem(
      id: 'app_${nowMs}_$appId',
      title: 'New Visa Application Received',
      message: '$effectiveApplicant filed application for: $effectiveTitle$effectiveRef',
      timestamp: DateTime.now(),
      type: 'application',
      route: appId.isNotEmpty ? '/applications/$appId' : '/applications',
    );

    ref.read(adminNotificationsProvider.notifier).addNotification(notification);
    ref.read(liveBannerAlertProvider.notifier).setAlert(notification);
  }

  // Supabase Realtime Channel listening to all vital tables and broadcasts
  final channel = client.channel(
    'admin-dashboard-realtime-channel',
    opts: const RealtimeChannelConfig(ack: true),
  );

  // 1. Direct real-time broadcast message from mobile client on visa application
  channel.onBroadcast(
    event: 'new_booking_or_application',
    callback: (payload) {
      handleNewApplicationAlert(
        id: payload['application_id']?.toString(),
        title: payload['title']?.toString(),
        applicant: payload['applicant_name']?.toString(),
        refNum: payload['reference_number']?.toString(),
      );
    },
  );

  channel.onBroadcast(
    event: 'new_visa_application',
    callback: (payload) {
      handleNewApplicationAlert(
        id: payload['application_id']?.toString(),
        title: payload['title']?.toString(),
        applicant: payload['applicant_name']?.toString(),
        refNum: payload['reference_number']?.toString(),
      );
    },
  );

  channel.onBroadcast(
    event: 'new_application',
    callback: (payload) {
      handleNewApplicationAlert(
        id: payload['application_id']?.toString(),
        title: payload['title']?.toString(),
        applicant: payload['applicant_name']?.toString(),
        refNum: payload['reference_number']?.toString(),
      );
    },
  );

  // 1b. Direct real-time payment broadcast message from mobile client
  channel.onBroadcast(
    event: 'new_payment_received',
    callback: (payload) {
      ref.read(dashboardMetricsRevisionProvider.notifier).increment();
      ref.read(applicationsRevisionProvider.notifier).increment();
      ref.read(paymentsRevisionProvider.notifier).increment();
      ref.invalidate(dashboardMetricsProvider);
      ref.invalidate(applicationsListProvider);
      ref.invalidate(paymentsListProvider);

      final title = payload['title']?.toString() ?? 'Visa Application';
      final applicant = payload['applicant_name']?.toString() ?? 'Applicant';
      final refNum = payload['reference_number']?.toString() ?? '';
      final fee = payload['fee_amount']?.toString() ?? '';
      final method = payload['payment_method']?.toString() ?? 'Bank Transfer';
      final appId = payload['application_id']?.toString() ?? '';

      final nowMs = DateTime.now().millisecondsSinceEpoch;
      final cleanRef = refNum.replaceAll(RegExp(r'[()]'), '').trim();
      final effectiveTx = payload['transaction_id']?.toString() ?? 'TXN-$nowMs';
      final parsedFee = double.tryParse(fee) ?? (payload['amount'] as num?)?.toDouble() ?? 30000.0;

      AdminPaymentService.instance.addLivePayment(AdminPaymentItem(
        id: appId.isNotEmpty ? appId : 'pay_$nowMs',
        userId: payload['user_id']?.toString() ?? 'c0e78055-61c8-4642-afab-1e88a70659fb',
        userName: applicant,
        userEmail: payload['applicant_email']?.toString(),
        transactionId: effectiveTx,
        referenceId: cleanRef,
        listingId: payload['listing_id']?.toString(),
        amount: parsedFee,
        currency: 'PKR',
        paymentMethod: (payload['is_bank_transfer'] == true ||
                method.toLowerCase().contains('bank') ||
                effectiveTx.toUpperCase().startsWith('IBFT'))
            ? 'bank_transfer'
            : method,
        gatewayResponse: {
          'channel': (payload['is_bank_transfer'] == true ||
                  method.toLowerCase().contains('bank') ||
                  effectiveTx.toUpperCase().startsWith('IBFT'))
              ? '1link_ibft'
              : 'payfast',
        },
        status: 'pending',
        createdAt: DateTime.now(),
      ));

      final refDisplay = refNum.isNotEmpty ? ' ($refNum)' : '';
      final notification = AdminNotificationItem(
        id: 'bcast_pay_$nowMs',
        title: 'New Client Payment Received',
        message: '$applicant submitted payment of PKR $fee via $method for $title$refDisplay',
        timestamp: DateTime.now(),
        type: 'payment',
        route: appId.isNotEmpty ? '/applications/$appId' : '/payments',
      );

      ref.read(adminNotificationsProvider.notifier).addNotification(notification);
      ref.read(liveBannerAlertProvider.notifier).setAlert(notification);
    },
  );

  // 2. Postgres WAL changes on applications
  channel.onPostgresChanges(
    event: PostgresChangeEvent.all,
    schema: 'public',
    table: 'applications',
    callback: (payload) {
      ref.read(dashboardMetricsRevisionProvider.notifier).increment();
      ref.read(applicationsRevisionProvider.notifier).increment();
      ref.invalidate(dashboardMetricsProvider);
      ref.invalidate(applicationsListProvider);

      final id = payload.newRecord['id'] as String?;
      if (id != null) {
        ref.invalidate(applicationDetailProvider(id));
      }

      if (payload.eventType == PostgresChangeEvent.insert) {
        handleNewApplicationAlert(
          id: id,
          title: payload.newRecord['title']?.toString(),
          applicant: payload.newRecord['applicant_name']?.toString(),
          refNum: payload.newRecord['reference_number']?.toString(),
        );
      }
    },
  );

  // 3. Postgres WAL changes on consultancy_bookings
  channel.onPostgresChanges(
    event: PostgresChangeEvent.all,
    schema: 'public',
    table: 'consultancy_bookings',
    callback: (payload) {
      ref.read(dashboardMetricsRevisionProvider.notifier).increment();
      ref.read(bookingsRevisionProvider.notifier).increment();
      ref.invalidate(dashboardMetricsProvider);
      ref.invalidate(bookingsListProvider);

      if (payload.eventType == PostgresChangeEvent.insert) {
        final service =
            payload.newRecord['service_title']?.toString() ?? 'Consultation Session';
        final date = payload.newRecord['booking_date']?.toString() ?? '';
        final time = payload.newRecord['booking_time_slot']?.toString() ?? '';
        final refNum =
            payload.newRecord['booking_reference']?.toString() ?? '';

        final notification = AdminNotificationItem(
          id: 'book_${DateTime.now().millisecondsSinceEpoch}',
          title: 'New Consultation Session Booked',
          message: '$service scheduled for $date $time ${refNum.isNotEmpty ? "($refNum)" : ""}',
          timestamp: DateTime.now(),
          type: 'booking',
          route: '/dashboard',
        );

        ref.read(adminNotificationsProvider.notifier).addNotification(notification);
        ref.read(liveBannerAlertProvider.notifier).setAlert(notification);
      }
    },
  );

  // 4. Postgres WAL changes on visa_listings
  channel.onPostgresChanges(
    event: PostgresChangeEvent.all,
    schema: 'public',
    table: 'visa_listings',
    callback: (_) {
      ref.read(dashboardMetricsRevisionProvider.notifier).increment();
      ref.read(visasRevisionProvider.notifier).increment();
      ref.invalidate(dashboardMetricsProvider);
      ref.invalidate(visasListProvider);
    },
  );

  // 5. Postgres WAL changes on payments
  channel.onPostgresChanges(
    event: PostgresChangeEvent.all,
    schema: 'public',
    table: 'payments',
    callback: (payload) {
      ref.read(dashboardMetricsRevisionProvider.notifier).increment();
      ref.read(paymentsRevisionProvider.notifier).increment();
      ref.invalidate(dashboardMetricsProvider);
      ref.invalidate(paymentsListProvider);

      if (payload.eventType == PostgresChangeEvent.insert) {
        final amount = payload.newRecord['amount']?.toString() ?? '0';
        final method =
            payload.newRecord['payment_method']?.toString() ?? 'Payment';

        final notification = AdminNotificationItem(
          id: 'pay_${DateTime.now().millisecondsSinceEpoch}',
          title: 'Client Payment Received',
          message: 'PKR $amount settled via $method',
          timestamp: DateTime.now(),
          type: 'payment',
          route: '/payments',
        );

        ref.read(adminNotificationsProvider.notifier).addNotification(notification);
        ref.read(liveBannerAlertProvider.notifier).setAlert(notification);
      }
    },
  );

  // 6. Postgres WAL changes on application_procedures
  channel.onPostgresChanges(
    event: PostgresChangeEvent.all,
    schema: 'public',
    table: 'application_procedures',
    callback: (payload) {
      ref.read(applicationsRevisionProvider.notifier).increment();
      final appId = payload.newRecord['application_id'] as String?;
      if (appId != null) {
        ref.invalidate(applicationDetailProvider(appId));
      }
    },
  );

  // 7. Postgres WAL changes on success_stories
  channel.onPostgresChanges(
    event: PostgresChangeEvent.all,
    schema: 'public',
    table: 'success_stories',
    callback: (payload) {
      ref.read(successStoriesRevisionProvider.notifier).increment();
      ref.invalidate(successStoriesListProvider);
    },
  );

  // 8. Postgres WAL changes on promotional_banners
  channel.onPostgresChanges(
    event: PostgresChangeEvent.all,
    schema: 'public',
    table: 'promotional_banners',
    callback: (payload) {
      ref.read(bannersRevisionProvider.notifier).increment();
      ref.invalidate(bannersListProvider);
    },
  );


  // 8b. Postgres WAL changes on affiliates
  channel.onPostgresChanges(
    event: PostgresChangeEvent.all,
    schema: 'public',
    table: 'affiliates',
    callback: (payload) {
      ref.read(affiliatesRevisionProvider.notifier).increment();
      ref.invalidate(affiliatesListProvider);

      if (payload.eventType == PostgresChangeEvent.insert) {
        final name = payload.newRecord['name']?.toString() ?? 'Partner Applicant';
        final email = payload.newRecord['email']?.toString() ?? '';
        final city = payload.newRecord['city']?.toString() ?? '';
        final nowMs = DateTime.now().millisecondsSinceEpoch;

        final notification = AdminNotificationItem(
          id: 'affiliate_$nowMs',
          title: 'New Affiliate Partner Application',
          message: '$name ($email) from $city applied for Affiliate Program',
          timestamp: DateTime.now(),
          type: 'affiliate',
          route: '/affiliates',
        );

        ref.read(adminNotificationsProvider.notifier).addNotification(notification);
        ref.read(liveBannerAlertProvider.notifier).setAlert(notification);
      }
    },
  );

  // Subscribe channel with auto-retry
  channel.subscribe((status, [error]) {
    if (status == RealtimeSubscribeStatus.channelError ||
        status == RealtimeSubscribeStatus.timedOut) {
      Future.delayed(const Duration(seconds: 3), () {
        try {
          channel.subscribe();
        } catch (_) {}
      });
    }
  });

  // 9. Active zero-miss polling sync: ensures new applications are caught immediately even if websocket drops
  Timer? pollingTimer;
  Future<void> pollLatestApplications() async {
    try {
      final res = await client
          .from('applications')
          .select('id, title, applicant_name, reference_number, applied_at')
          .order('applied_at', ascending: false)
          .limit(15);
      final rows = List<Map<String, dynamic>>.from(res);

      if (isInitialPoll) {
        for (final r in rows) {
          final id = r['id']?.toString();
          if (id != null) knownApplicationIds.add(id);
        }
        isInitialPoll = false;
        return;
      }

      for (final r in rows) {
        final id = r['id']?.toString();
        if (id != null && !knownApplicationIds.contains(id)) {
          handleNewApplicationAlert(
            id: id,
            title: r['title']?.toString(),
            applicant: r['applicant_name']?.toString(),
            refNum: r['reference_number']?.toString(),
          );
        }
      }
    } catch (_) {}
  }


  final Set<String> knownAffiliateIds = {};
  bool isInitialAffiliatePoll = true;

  Future<void> pollLatestAffiliates() async {
    try {
      final res = await client
          .from('affiliates')
          .select('id, name, email, city, status, created_at')
          .order('created_at', ascending: false)
          .limit(20);
      final rows = List<Map<String, dynamic>>.from(res);

      if (isInitialAffiliatePoll) {
        for (final r in rows) {
          final id = r['id']?.toString();
          if (id != null) knownAffiliateIds.add(id);
        }
        isInitialAffiliatePoll = false;
        return;
      }

      bool hasNew = false;
      for (final r in rows) {
        final id = r['id']?.toString();
        if (id != null && !knownAffiliateIds.contains(id)) {
          knownAffiliateIds.add(id);
          hasNew = true;
          final name = r['name']?.toString() ?? 'Partner Applicant';
          final email = r['email']?.toString() ?? '';
          final city = r['city']?.toString() ?? '';
          final nowMs = DateTime.now().millisecondsSinceEpoch;

          final notification = AdminNotificationItem(
            id: 'affiliate_${nowMs}_$id',
            title: 'New Affiliate Partner Application',
            message: '$name ($email) from $city applied for Affiliate Program',
            timestamp: DateTime.now(),
            type: 'affiliate',
            route: '/affiliates',
          );

          ref.read(adminNotificationsProvider.notifier).addNotification(notification);
          ref.read(liveBannerAlertProvider.notifier).setAlert(notification);
        }
      }

      if (hasNew) {
        ref.read(affiliatesRevisionProvider.notifier).increment();
        ref.invalidate(affiliatesListProvider);
      }
    } catch (_) {}
  }

  // Immediate initial load and 3-second recurring poll
  pollLatestApplications();
  pollLatestAffiliates();
  pollingTimer = Timer.periodic(const Duration(seconds: 3), (_) {
    pollLatestApplications();
    pollLatestAffiliates();
  });

  ref.onDispose(() {
    pollingTimer?.cancel();
    channel.unsubscribe();
  });
});
