class ApplicationProcedureStep {
  const ApplicationProcedureStep({
    required this.id,
    required this.applicationId,
    required this.stepNumber,
    required this.title,
    this.subtitle,
    required this.status, // 'pending', 'in_progress', 'completed'
    this.duration,
    this.scheduledCallDate,
    this.scheduledCallSlot,
    this.completedAt,
    this.notes,
  });

  final String id;
  final String applicationId;
  final int stepNumber;
  final String title;
  final String? subtitle;
  final String status;
  final String? duration;
  final String? scheduledCallDate;
  final String? scheduledCallSlot;
  final DateTime? completedAt;
  final String? notes;

  bool get isCompleted => status == 'completed';
  bool get isInProgress => status == 'in_progress';
  bool get isPending => status == 'pending';

  factory ApplicationProcedureStep.fromMap(Map<String, dynamic> map) {
    return ApplicationProcedureStep(
      id: map['id']?.toString() ?? '',
      applicationId: map['application_id']?.toString() ?? '',
      stepNumber: (map['step_number'] as num?)?.toInt() ?? 1,
      title: map['title']?.toString() ?? '',
      subtitle: map['subtitle']?.toString(),
      status: map['status']?.toString() ?? 'pending',
      duration: map['duration']?.toString(),
      scheduledCallDate: map['scheduled_call_date']?.toString(),
      scheduledCallSlot: map['scheduled_call_slot']?.toString(),
      completedAt: map['completed_at'] != null
          ? DateTime.tryParse(map['completed_at'].toString())?.toLocal()
          : null,
      notes: map['notes']?.toString(),
    );
  }
}

class ApplicationStatusHistoryItem {
  const ApplicationStatusHistoryItem({
    required this.id,
    required this.applicationId,
    this.previousStep,
    required this.newStep,
    this.previousStatus,
    required this.newStatus,
    this.changedBy,
    required this.changedAt,
    this.notes,
  });

  final String id;
  final String applicationId;
  final int? previousStep;
  final int newStep;
  final String? previousStatus;
  final String newStatus;
  final String? changedBy;
  final DateTime changedAt;
  final String? notes;

  factory ApplicationStatusHistoryItem.fromMap(Map<String, dynamic> map) {
    return ApplicationStatusHistoryItem(
      id: map['id']?.toString() ?? '',
      applicationId: map['application_id']?.toString() ?? '',
      previousStep: (map['previous_step'] as num?)?.toInt(),
      newStep: (map['new_step'] as num?)?.toInt() ?? 1,
      previousStatus: map['previous_status']?.toString(),
      newStatus: map['new_status']?.toString() ?? '',
      changedBy: map['changed_by']?.toString(),
      changedAt: map['changed_at'] != null
          ? (DateTime.tryParse(map['changed_at'].toString())?.toLocal() ?? DateTime.now())
          : DateTime.now(),
      notes: map['notes']?.toString(),
    );
  }
}

class ApplicationItem {
  const ApplicationItem({
    required this.id,
    required this.userId,
    required this.referenceNumber,
    this.listingId,
    this.jobId,
    required this.categoryType,
    required this.title,
    this.subtitle,
    required this.status, // 'submitted', 'in_review', 'approved', 'rejected', 'completed', 'cancelled'
    this.statusLabel,
    this.statusBgColor,
    this.statusTextColor,
    required this.currentStep, // 1 to 5
    this.stepText,
    this.progressPercent = 20,
    this.assignedConsultantId,
    this.assignedConsultantName,
    this.applicantName,
    this.applicantEmail,
    this.applicantPhone,
    this.applicantPassport,
    this.formData,
    this.hasAlert = false,
    this.alertTitle,
    this.alertBody,
    this.adminInternalNotes,
    this.paymentInfo,
    required this.appliedAt,
    this.updatedAt,
    this.procedures = const [],
    this.history = const [],
  });

  final String id;
  final String userId;
  final String referenceNumber;
  final String? listingId;
  final String? jobId;
  final String categoryType;
  final String title;
  final String? subtitle;
  final String status;
  final String? statusLabel;
  final int? statusBgColor;
  final int? statusTextColor;
  final int currentStep;
  final String? stepText;
  final int progressPercent;
  final String? assignedConsultantId;
  final String? assignedConsultantName;
  final String? applicantName;
  final String? applicantEmail;
  final String? applicantPhone;
  final String? applicantPassport;
  final dynamic formData;
  final bool hasAlert;
  final String? alertTitle;
  final String? alertBody;
  final String? adminInternalNotes;
  final Map<String, dynamic>? paymentInfo;
  final DateTime appliedAt;
  final DateTime? updatedAt;
  final List<ApplicationProcedureStep> procedures;
  final List<ApplicationStatusHistoryItem> history;

  bool get isApproved => status == 'approved';
  bool get isRejected => status == 'rejected';
  bool get isCompleted => status == 'completed';
  bool get isSubmitted => status == 'submitted';
  bool get isInReview => status == 'in_review';

  String? get transactionId {
    if (paymentInfo != null && paymentInfo!['transaction_id'] != null) {
      final tid = paymentInfo!['transaction_id'].toString().trim();
      if (tid.isNotEmpty) return tid;
    }
    if (formData is Map) {
      final f = formData as Map;
      final tid = f['transaction_ref'] ?? f['transaction_id'] ?? f['txn_id'];
      if (tid != null && tid.toString().trim().isNotEmpty) {
        return tid.toString().trim();
      }
    }
    return null;
  }

  String? get paymentAmount {
    if (paymentInfo != null && paymentInfo!['amount'] != null) {
      final amt = paymentInfo!['amount'];
      final curr = paymentInfo!['currency'] ?? 'PKR';
      return '$curr $amt';
    }
    if (formData is Map) {
      final f = formData as Map;
      final amt = f['fee'] ?? f['amount'] ?? f['total_fee'];
      if (amt != null && amt.toString().trim().isNotEmpty) {
        return 'PKR $amt';
      }
    }
    return null;
  }

  String? get paymentMethod {
    if (paymentInfo != null && paymentInfo!['payment_method'] != null) {
      final raw = paymentInfo!['payment_method'].toString();
      final gw = paymentInfo!['gateway_response'];
      final tx = paymentInfo!['transaction_id']?.toString() ?? '';
      if (tx.toUpperCase().startsWith('IBFT') ||
          raw.toLowerCase().contains('bank') ||
          raw.toLowerCase().contains('ibft') ||
          raw.toLowerCase().contains('wire') ||
          (gw is Map &&
              (gw['channel'] == '1link_ibft' ||
                  gw['channel'] == 'bank_transfer' ||
                  gw['bank'] != null ||
                  gw['sender_name'] != null))) {
        return 'Bank Transfer (1Link IBFT)';
      }
      return raw;
    }
    if (formData is Map) {
      final f = formData as Map;
      final pm = f['payment_method'];
      if (pm != null && pm.toString().trim().isNotEmpty) {
        final raw = pm.toString();
        if (raw.toLowerCase().contains('bank') ||
            raw.toLowerCase().contains('ibft') ||
            raw.toLowerCase().contains('wire')) {
          return 'Bank Transfer (1Link IBFT)';
        }
        return raw;
      }
    }
    return null;
  }

  String? get paymentStatus {
    if (paymentInfo != null && paymentInfo!['status'] != null) {
      return paymentInfo!['status'].toString();
    }
    if (formData is Map) {
      final f = formData as Map;
      if (f['payment_verified'] == true) return 'completed';
      if (f['payment_method'] != null) return 'pending';
    }
    return null;
  }

  String? get passportNumber {
    if (applicantPassport != null && applicantPassport!.trim().isNotEmpty) {
      return applicantPassport!.trim();
    }
    if (formData is Map) {
      final f = formData as Map;
      final pass =
          f['passport_number'] ?? f['passport'] ?? f['applicant_passport'];
      if (pass != null && pass.toString().trim().isNotEmpty) {
        return pass.toString().trim();
      }
    }
    return null;
  }

  String? get nationality {
    if (formData is Map) {
      final f = formData as Map;
      final nat = f['nationality'] ?? f['applicant_nationality'];
      if (nat != null && nat.toString().trim().isNotEmpty) {
        return nat.toString().trim();
      }
    }
    return null;
  }

  ApplicationItem copyWith({
    int? currentStep,
    String? status,
    String? statusLabel,
    int? statusBgColor,
    int? statusTextColor,
    String? stepText,
    int? progressPercent,
    String? assignedConsultantName,
    String? adminInternalNotes,
    dynamic formData,
    bool? hasAlert,
    String? alertTitle,
    String? alertBody,
    Map<String, dynamic>? paymentInfo,
    List<ApplicationProcedureStep>? procedures,
    List<ApplicationStatusHistoryItem>? history,
  }) {
    return ApplicationItem(
      id: id,
      userId: userId,
      referenceNumber: referenceNumber,
      listingId: listingId,
      jobId: jobId,
      categoryType: categoryType,
      title: title,
      subtitle: subtitle,
      status: status ?? this.status,
      statusLabel: statusLabel ?? this.statusLabel,
      statusBgColor: statusBgColor ?? this.statusBgColor,
      statusTextColor: statusTextColor ?? this.statusTextColor,
      currentStep: currentStep ?? this.currentStep,
      stepText: stepText ?? this.stepText,
      progressPercent: progressPercent ?? this.progressPercent,
      assignedConsultantId: assignedConsultantId,
      assignedConsultantName:
          assignedConsultantName ?? this.assignedConsultantName,
      applicantName: applicantName,
      applicantEmail: applicantEmail,
      applicantPhone: applicantPhone,
      applicantPassport: applicantPassport,
      formData: formData ?? this.formData,
      hasAlert: hasAlert ?? this.hasAlert,
      alertTitle: alertTitle ?? this.alertTitle,
      alertBody: alertBody ?? this.alertBody,
      adminInternalNotes: adminInternalNotes ?? this.adminInternalNotes,
      paymentInfo: paymentInfo ?? this.paymentInfo,
      appliedAt: appliedAt,
      updatedAt: updatedAt,
      procedures: procedures ?? this.procedures,
      history: history ?? this.history,
    );
  }

  factory ApplicationItem.fromMap(
    Map<String, dynamic> map, {
    List<ApplicationProcedureStep> procedures = const [],
    List<ApplicationStatusHistoryItem> history = const [],
  }) {
    Map<String, dynamic>? paymentData;
    if (map['payments'] is List && (map['payments'] as List).isNotEmpty) {
      final first = (map['payments'] as List).first;
      if (first is Map) {
        paymentData = Map<String, dynamic>.from(first);
      }
    } else if (map['payments'] is Map) {
      paymentData = Map<String, dynamic>.from(map['payments'] as Map);
    }

    return ApplicationItem(
      id: map['id']?.toString() ?? '',
      userId: map['user_id']?.toString() ?? '',
      referenceNumber: map['reference_number']?.toString() ?? '',
      listingId: map['listing_id']?.toString(),
      jobId: map['job_id']?.toString(),
      categoryType: map['category_type']?.toString() ?? 'VISA',
      title: map['title']?.toString() ?? '',
      subtitle: map['subtitle']?.toString(),
      status: map['status']?.toString() ?? 'submitted',
      statusLabel: map['status_label']?.toString(),
      statusBgColor: (map['status_bg_color'] as num?)?.toInt(),
      statusTextColor: (map['status_text_color'] as num?)?.toInt(),
      currentStep: (map['current_step'] as num?)?.toInt() ?? 1,
      stepText: map['step_text']?.toString() ?? 'Step 1 of 5: Profile Review',
      progressPercent: (map['progress_percent'] as num?)?.toInt() ?? 20,
      assignedConsultantId: map['assigned_consultant_id']?.toString(),
      assignedConsultantName: map['assigned_consultant_name']?.toString(),
      applicantName: map['applicant_name']?.toString(),
      applicantEmail: map['applicant_email']?.toString(),
      applicantPhone: map['applicant_phone']?.toString(),
      applicantPassport: map['applicant_passport']?.toString(),
      formData: map['form_data'],
      hasAlert: map['has_alert'] == true,
      alertTitle: map['alert_title']?.toString(),
      alertBody: map['alert_body']?.toString(),
      adminInternalNotes: map['admin_internal_notes']?.toString(),
      paymentInfo: paymentData,
      appliedAt: map['applied_at'] != null
          ? (DateTime.tryParse(map['applied_at'].toString())?.toLocal() ?? DateTime.now())
          : DateTime.now(),
      updatedAt: map['updated_at'] != null
          ? DateTime.tryParse(map['updated_at'].toString())?.toLocal()
          : null,
      procedures: procedures,
      history: history,
    );
  }
}
