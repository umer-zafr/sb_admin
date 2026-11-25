import 'admin_push_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/config/supabase_config.dart';
import '../core/constants/admin_constants.dart';
import '../models/application_model.dart';
import '../models/audit_log_model.dart';

class AdminApplicationService {
  AdminApplicationService._();
  static final instance = AdminApplicationService._();

  SupabaseClient get _client => SupabaseConfig.client;

  final List<ApplicationItem> _liveApplications = [];

  void clearLiveApplications() {
    _liveApplications.clear();
  }

  void addLiveApplication(ApplicationItem app) {
    _liveApplications.removeWhere((existing) =>
        existing.id == app.id ||
        (existing.referenceNumber.isNotEmpty &&
            existing.referenceNumber.toLowerCase() == app.referenceNumber.toLowerCase()));
    _liveApplications.insert(0, app);
  }

  List<ApplicationItem> get liveApplications => List.unmodifiable(_liveApplications);

  bool _matchesFilter(
    ApplicationItem app,
    String? searchQuery,
    String? statusFilter,
    String? categoryFilter,
  ) {
    if (statusFilter != null && statusFilter.isNotEmpty && statusFilter != 'all') {
      final s = app.status.toLowerCase();
      final f = statusFilter.toLowerCase();
      if (f == 'submitted' && (s != 'submitted' && s != 'under_review' && s != 'pending')) return false;
      if (f == 'in_review' && (s != 'in_review' && s != 'under_review')) return false;
      if (f != 'submitted' && f != 'in_review' && s != f) return false;
    }
    if (categoryFilter != null && categoryFilter.isNotEmpty && categoryFilter != 'all') {
      if (app.categoryType.toLowerCase() != categoryFilter.toLowerCase()) return false;
    }
    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final q = searchQuery.trim().toLowerCase();
      final match = (app.applicantName?.toLowerCase().contains(q) ?? false) ||
          (app.applicantEmail?.toLowerCase().contains(q) ?? false) ||
          app.referenceNumber.toLowerCase().contains(q) ||
          app.title.toLowerCase().contains(q);
      if (!match) return false;
    }
    return true;
  }

  Future<List<ApplicationItem>> getApplications({
    String? searchQuery,
    String? statusFilter,
    String? categoryFilter,
  }) async {
    try {
      var query = _client.from('applications').select('*, payments(*)');

      if (statusFilter != null && statusFilter.isNotEmpty && statusFilter != 'all') {
        query = query.eq('status', statusFilter);
      }
      if (categoryFilter != null &&
          categoryFilter.isNotEmpty &&
          categoryFilter != 'all') {
        query = query.eq('category_type', categoryFilter);
      }
      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        final q = searchQuery.trim();
        query = query.or('applicant_name.ilike.%$q%,applicant_email.ilike.%$q%,reference_number.ilike.%$q%,title.ilike.%$q%');
      }

      final res = await query.order('applied_at', ascending: false);
      final dbApps = List<Map<String, dynamic>>.from(res)
          .where((row) {
            final fd = row['form_data'] as Map?;
            if (fd?['is_deleted'] == true || fd?['is_archived'] == true) {
              return false;
            }
            return true;
          })
          .map(ApplicationItem.fromMap)
          .toList();
      final combined = <ApplicationItem>[];
      final seenRefs = <String>{};

      for (final live in _liveApplications) {
        if (_matchesFilter(live, searchQuery, statusFilter, categoryFilter)) {
          combined.add(live);
          if (live.referenceNumber.isNotEmpty) seenRefs.add(live.referenceNumber.toLowerCase());
          if (live.id.isNotEmpty) seenRefs.add(live.id.toLowerCase());
        }
      }

      for (final dbApp in dbApps) {
        final refLow = dbApp.referenceNumber.toLowerCase();
        final idLow = dbApp.id.toLowerCase();
        if (!seenRefs.contains(refLow) && !seenRefs.contains(idLow)) {
          combined.add(dbApp);
          if (refLow.isNotEmpty) seenRefs.add(refLow);
          if (idLow.isNotEmpty) seenRefs.add(idLow);
        }
      }
      return combined;
    } catch (_) {
      // Graceful schema relationship fallback:
      // When foreign key constraint between 'applications' and 'payments' is not present in PostgREST cache
      var fallbackQuery = _client.from('applications').select('*');

      if (statusFilter != null && statusFilter.isNotEmpty && statusFilter != 'all') {
        fallbackQuery = fallbackQuery.eq('status', statusFilter);
      }
      if (categoryFilter != null &&
          categoryFilter.isNotEmpty &&
          categoryFilter != 'all') {
        fallbackQuery = fallbackQuery.eq('category_type', categoryFilter);
      }
      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        final q = searchQuery.trim();
        fallbackQuery = fallbackQuery.or('applicant_name.ilike.%$q%,applicant_email.ilike.%$q%,reference_number.ilike.%$q%,title.ilike.%$q%');
      }

      final res = await fallbackQuery.order('applied_at', ascending: false);
      final apps = List<Map<String, dynamic>>.from(res);

      try {
        final paymentsRes = await _client.from('payments').select('*');
        final paymentsList = List<Map<String, dynamic>>.from(paymentsRes);
        for (final app in apps) {
          final appId = app['id']?.toString();
          final appRef = app['reference_number']?.toString();
          final matches = paymentsList.where((p) {
            final pAppId = p['application_id']?.toString();
            final pRef = p['reference_id']?.toString();
            return (appId != null && pAppId == appId) ||
                (appRef != null && pRef == appRef);
          }).toList();
          if (matches.isNotEmpty) {
            app['payments'] = matches;
          }
        }
      } catch (_) {}

      final dbApps = apps
          .map(ApplicationItem.fromMap)
          .toList();
      final combined = <ApplicationItem>[];
      final seenRefs = <String>{};

      for (final live in _liveApplications) {
        if (_matchesFilter(live, searchQuery, statusFilter, categoryFilter)) {
          combined.add(live);
          if (live.referenceNumber.isNotEmpty) seenRefs.add(live.referenceNumber.toLowerCase());
          if (live.id.isNotEmpty) seenRefs.add(live.id.toLowerCase());
        }
      }

      for (final dbApp in dbApps) {
        final refLow = dbApp.referenceNumber.toLowerCase();
        final idLow = dbApp.id.toLowerCase();
        if (!seenRefs.contains(refLow) && !seenRefs.contains(idLow)) {
          combined.add(dbApp);
          if (refLow.isNotEmpty) seenRefs.add(refLow);
          if (idLow.isNotEmpty) seenRefs.add(idLow);
        }
      }

      return combined;
    }
  }

  Future<ApplicationItem> getApplicationDetail(String applicationId) async {
    // Check in-memory live applications first for instant responsiveness
    for (final live in _liveApplications) {
      if (live.id == applicationId || live.referenceNumber == applicationId) {
        return live;
      }
    }
    Map<String, dynamic>? appRes;
    try {
      appRes = await _client
          .from('applications')
          .select('*, payments(*)')
          .eq('id', applicationId)
          .maybeSingle();
    } catch (_) {}

    if (appRes == null) {
      try {
        appRes = await _client
            .from('applications')
            .select('*')
            .or('id.eq.$applicationId,reference_number.eq.$applicationId')
            .maybeSingle();
      } catch (_) {}
    }

    if (appRes == null) {
      return ApplicationItem(
        id: applicationId,
        userId: '',
        referenceNumber: applicationId,
        title: 'Visa Application Dossier',
        categoryType: 'VISA',
        status: 'submitted',
        statusLabel: 'Profile Review',
        currentStep: 1,
        progressPercent: 20,
        appliedAt: DateTime.now(),
      );
    }

    if (appRes['payments'] == null) {
      try {
        final refNum = appRes['reference_number']?.toString();
        final paymentsRes = await _client
            .from('payments')
            .select('*')
            .or('application_id.eq.$applicationId,reference_id.eq.$refNum');
        appRes['payments'] = List<Map<String, dynamic>>.from(paymentsRes);
      } catch (_) {}
    }

    final procRes = await _client
        .from('application_procedures')
        .select('*')
        .eq('application_id', applicationId)
        .order('step_number', ascending: true);
    final procedures = List<Map<String, dynamic>>.from(procRes)
        .map(ApplicationProcedureStep.fromMap)
        .toList();

    final histRes = await _client
        .from('application_status_history')
        .select('*')
        .eq('application_id', applicationId)
        .order('changed_at', ascending: false);
    final history = List<Map<String, dynamic>>.from(histRes)
        .map(ApplicationStatusHistoryItem.fromMap)
        .toList();

    return ApplicationItem.fromMap(
      appRes,
      procedures: procedures,
      history: history,
    );
  }

  /// CORE APPLICATION STEPPER ADVANCEMENT
  /// Moves the application to a new step (1 to 5), updates procedures,
  /// records history audit trail, and synchronizes with customer mobile app.
  Future<void> updateApplicationStep({
    required String applicationId,
    required int newStep,
    String? status,
    String? stepNotes,
  }) async {
    int prevStep = 1;
    String prevStatus = 'submitted';
    String? appRef;
    String? appUserId;

    try {
      final currentAppRes = await _client
          .from('applications')
          .select('current_step, status, title, reference_number, user_id')
          .eq('id', applicationId)
          .maybeSingle();
      if (currentAppRes != null) {
        prevStep = (currentAppRes['current_step'] as num?)?.toInt() ?? 1;
        prevStatus = currentAppRes['status']?.toString() ?? 'submitted';
        appRef = currentAppRes['reference_number']?.toString();
        appUserId = currentAppRes['user_id']?.toString();
      }
    } catch (_) {}

    // Check live in-memory applications
    for (int i = 0; i < _liveApplications.length; i++) {
      if (_liveApplications[i].id == applicationId) {
        prevStep = _liveApplications[i].currentStep;
        prevStatus = _liveApplications[i].status;
        appRef ??= _liveApplications[i].referenceNumber;
        appUserId ??= _liveApplications[i].userId;
      }
    }

    final stepConfig = AdminConstants.procedureSteps.firstWhere(
      (s) => s['step_number'] == newStep,
      orElse: () => {
        'step_number': newStep,
        'title': 'Step $newStep',
      },
    );
    final stepTitle = stepConfig['title'] as String;
    final stepText = 'Step $newStep of 5: $stepTitle';
    final progressPercent = (newStep * 20).clamp(20, 100);

    final finalStatus = status ??
        (newStep == 5
            ? 'approved'
            : (newStep > 1 ? 'under_review' : 'submitted'));

    // Update in-memory state immediately so UI updates with zero latency
    for (int i = 0; i < _liveApplications.length; i++) {
      if (_liveApplications[i].id == applicationId ||
          (appRef != null && _liveApplications[i].referenceNumber == appRef)) {
        _liveApplications[i] = _liveApplications[i].copyWith(
          currentStep: newStep,
          status: finalStatus,
          statusLabel: stepTitle,
          stepText: stepText,
          progressPercent: progressPercent,
        );
      }
    }

    // 1. Update the parent application row in DB
    try {
      await _client.from('applications').update({
        'current_step': newStep,
        'step_text': stepText,
        'progress_percent': progressPercent,
        'status': finalStatus,
        'status_label': stepTitle,
        'has_alert': false,
        'alert_title': null,
        'alert_body': null,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', applicationId);
    } catch (_) {
      try {
        await _client.from('applications').update({
          'current_step': newStep,
          'step_text': stepText,
          'progress_percent': progressPercent,
          'status': finalStatus,
          'status_label': stepTitle,
          'has_alert': false,
          'alert_title': null,
          'alert_body': null,
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('reference_number', applicationId);
      } catch (_) {}
    }

    // 2. Update procedure steps
    try {
      await _client
          .from('application_procedures')
          .update({
            'status': 'completed',
            'completed_at': DateTime.now().toIso8601String(),
          })
          .eq('application_id', applicationId)
          .lt('step_number', newStep);

      await _client
          .from('application_procedures')
          .update({
            'status': newStep == 5 ? 'completed' : 'in_progress',
            'notes': stepNotes,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('application_id', applicationId)
          .eq('step_number', newStep);
    } catch (_) {}

    // 3. Insert audit history record
    final adminId = _client.auth.currentUser?.id;
    try {
      await _client.from('application_status_history').insert({
        'application_id': applicationId,
        'previous_step': prevStep,
        'new_step': newStep,
        'previous_status': prevStatus,
        'new_status': finalStatus,
        'changed_by': adminId,
        'notes': stepNotes ?? 'Moved to Step $newStep: $stepTitle',
      });
    } catch (_) {}

    // 4. Log admin audit action
    try {
      await _logAudit(
        'advance_application_step',
        'application',
        applicationId,
        {
          'previous_step': prevStep,
          'new_step': newStep,
          'status': finalStatus,
        },
      );
    } catch (_) {}

    // 5. Broadcast to mobile clients for real-time synchronization
    try {
      final syncPayload = {
        'application_id': applicationId,
        'reference_number': appRef ?? '',
        'current_step': newStep,
        'status': finalStatus,
        'status_label': stepTitle,
        'step_text': stepText,
        'progress_percent': progressPercent,
      };
      final ch = _client.channel('admin-dashboard-realtime-channel');
      await ch.sendBroadcastMessage(
        event: 'step_updated',
        payload: syncPayload,
      );
      await ch.sendBroadcastMessage(
        event: 'application_updated',
        payload: syncPayload,
      );
      if (newStep >= 5 || finalStatus == 'approved') {
        await ch.sendBroadcastMessage(
          event: 'application_approved',
          payload: syncPayload,
        );
      }

      // Dispatch external push notification via OneSignal
      if (appUserId != null && appUserId.isNotEmpty) {
        final isApproved = newStep >= 5 || finalStatus == 'approved';
        final pushTitle = isApproved
            ? 'SB Consultants • Visa Approved! ✈️'
            : 'SB Consultants • Progress: $stepTitle 📋';
        final pushBody = isApproved
            ? 'Congratulations! Your visa application ($appRef) has been officially approved.'
            : 'Your case ($appRef) has progressed to $stepText.';

        AdminPushService.instance.sendToUser(
          userId: appUserId,
          title: pushTitle,
          message: pushBody,
          route: '/applications',
        );
      }
    } catch (_) {}
  }

  Future<void> updateApplicationStatus({
    required String applicationId,
    required String status,
    String? alertTitle,
    String? alertBody,
    String? adminNotes,
  }) async {
    String prevStatus = '';
    int step = 1;
    String? appRef;
    String? appUserId;

    try {
      final current = await _client
          .from('applications')
          .select('status, current_step, reference_number, user_id')
          .eq('id', applicationId)
          .maybeSingle();
      if (current != null) {
        prevStatus = current['status']?.toString() ?? '';
        step = (current['current_step'] as num?)?.toInt() ?? 1;
        appRef = current['reference_number']?.toString();
        appUserId = current['user_id']?.toString();
      }
    } catch (_) {}

    for (int i = 0; i < _liveApplications.length; i++) {
      if (_liveApplications[i].id == applicationId) {
        prevStatus = _liveApplications[i].status;
        step = _liveApplications[i].currentStep;
        appRef ??= _liveApplications[i].referenceNumber;
        _liveApplications[i] = _liveApplications[i].copyWith(
          status: status,
          hasAlert: alertTitle != null && alertTitle.isNotEmpty,
          alertTitle: alertTitle,
          alertBody: alertBody,
          adminInternalNotes: adminNotes,
        );
      }
    }

    final updates = <String, dynamic>{
      'status': status,
      'has_alert': alertTitle != null && alertTitle.isNotEmpty,
      'alert_title': alertTitle,
      'alert_body': alertBody,
      'updated_at': DateTime.now().toIso8601String(),
    };
    if (adminNotes != null) {
      updates['admin_internal_notes'] = adminNotes;
    }

    try {
      await _client.from('applications').update(updates).eq('id', applicationId);
    } catch (_) {}

    // Record in history
    final adminId = _client.auth.currentUser?.id;
    try {
      await _client.from('application_status_history').insert({
        'application_id': applicationId,
        'previous_step': step,
        'new_step': step,
        'previous_status': prevStatus,
        'new_status': status,
        'changed_by': adminId,
        'notes': 'Status changed to $status',
      });
    } catch (_) {}

    try {
      await _logAudit('update_application_status', 'application', applicationId, {
        'previous_status': prevStatus,
        'new_status': status,
      });
    } catch (_) {}

    // Broadcast status update
    try {
      final syncPayload = {
        'application_id': applicationId,
        'reference_number': appRef ?? '',
        'status': status,
        'current_step': step,
      };
      final ch = _client.channel('admin-dashboard-realtime-channel');
      await ch.sendBroadcastMessage(
        event: 'application_updated',
        payload: syncPayload,
      );
      if (status == 'approved' || status == 'completed') {
        await ch.sendBroadcastMessage(
          event: 'application_approved',
          payload: syncPayload,
        );
      }

      // Dispatch external push notification via OneSignal
      if (appUserId != null && appUserId.isNotEmpty) {
        final pushTitle = status == 'approved'
            ? 'SB Consultants • Visa Approved! ✈️'
            : (alertTitle != null && alertTitle.isNotEmpty
                ? 'SB Consultants • $alertTitle'
                : 'SB Consultants • Application Updated 📋');
        final pushBody = status == 'approved'
            ? 'Congratulations! Your visa application ($appRef) has been approved.'
            : (alertBody != null && alertBody.isNotEmpty
                ? alertBody
                : 'Your application ($appRef) status is now: $status');

        AdminPushService.instance.sendToUser(
          userId: appUserId,
          title: pushTitle,
          message: pushBody,
          route: '/applications',
        );
      }
    } catch (_) {}
  }

  Future<void> rescheduleConsultantCall({
    required String applicationId,
    required String callDate,
    required String callSlot,
    String? consultantName,
  }) async {
    try {
      await _client
          .from('application_procedures')
          .update({
            'scheduled_call_date': callDate,
            'scheduled_call_slot': callSlot,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('application_id', applicationId)
          .eq('step_number', 2);
    } catch (_) {}
  }

  Future<void> addInternalNote(String applicationId, String note) async {
    final adminId = _client.auth.currentUser?.id;
    await _client.from('admin_notes').insert({
      'entity_type': 'application',
      'entity_id': applicationId,
      'author_id': adminId,
      'note': note,
    });
  }

  Future<List<AdminInternalNoteItem>> getInternalNotes(
      String applicationId) async {
    final res = await _client
        .from('admin_notes')
        .select('*')
        .eq('entity_type', 'application')
        .eq('entity_id', applicationId)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(res)
        .map(AdminInternalNoteItem.fromMap)
        .toList();
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
