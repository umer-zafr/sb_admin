import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/admin_theme.dart';
import '../../models/visa_model.dart';
import '../../providers/admin_dashboard_providers.dart';
import '../../services/admin_visa_service.dart';
import 'visa_presets.dart';

class VisaEditDialog extends ConsumerStatefulWidget {
  const VisaEditDialog({super.key, this.existingVisa});

  final VisaListingItem? existingVisa;

  static Future<bool?> show(BuildContext context, {VisaListingItem? existingVisa}) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => VisaEditDialog(existingVisa: existingVisa),
    );
  }

  @override
  ConsumerState<VisaEditDialog> createState() => _VisaEditDialogState();
}

class _VisaEditDialogState extends ConsumerState<VisaEditDialog>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late final TabController _tabController;

  // Basic Controllers (Tab 1: General)
  late final TextEditingController _titleController;
  late final TextEditingController _subtitleController;
  late final TextEditingController _statusBadgeController;
  late final TextEditingController _imageUrlController;

  // Tab 2: Pricing & Metrics
  late final TextEditingController _salaryController;
  late final TextEditingController _feeController;
  late final TextEditingController _serviceFeeLabelController;
  late final TextEditingController _serviceFeeValueController;
  late final TextEditingController _totalPayableController;
  late final TextEditingController _processingTimeController;
  late final TextEditingController _validityController;
  late final TextEditingController _successRateController;
  late final TextEditingController _applicantsCountController;
  late final TextEditingController _ratingController;
  late final TextEditingController _reviewsCountController;
  late final TextEditingController _externalUrlController;

  // Tab 3: About
  late final TextEditingController _aboutTitleController;
  late final TextEditingController _aboutDescriptionController;

  // Tab 4: Dynamic Lists
  final List<TextEditingController> _eligibilityControllers = [];
  final _newCriterionController = TextEditingController();

  // Tab 5: Mandatory Documents
  final List<Map<String, dynamic>> _documentItems = [];

  // Tab 6: Procedure Steps
  final List<Map<String, dynamic>> _timelineItems = [];

  // Tab 7: Fee Breakdown
  final List<Map<String, dynamic>> _feeBreakdownItems = [];

  // Tab 8: Application Requirements (Admin Managed)
  bool _requireAge = true;
  final _minAgeController = TextEditingController(text: '18');
  final _maxAgeController = TextEditingController(text: '35');
  final _ageBracketController = TextEditingController(text: '18 - 35 Years');

  bool _requireEducation = true;
  String _minQualification = "Bachelor's / Undergrad";
  final _minMarksController = TextEditingController(text: '60% or 2.8+ CGPA');
  final _fieldOfStudyController = TextEditingController(text: 'Relevant Discipline');

  bool _requireLanguage = true;
  String _languageTestType = 'IELTS Academic / PTE';
  final _minLanguageScoreController = TextEditingController(text: '6.0 - 6.5 Overall');
  bool _isLanguageMandatory = true;

  bool _requireExperience = false;
  String _minExperience = 'Fresh Graduate Eligible';
  final _roleLevelController = TextEditingController(text: 'Standard');

  bool _requireFinancial = true;
  final _minBankBalanceController = TextEditingController(text: 'PKR 2,500,000');
  String _holdingPeriod = '28 Days Holding Record';
  final _proofTypeController = TextEditingController(text: 'Bank maintenance certificate');

  bool _priorTravelRequired = false;
  bool _rejectionDeclarationRequired = true;
  bool _policeCertRequired = false;
  bool _medicalCheckRequired = true;

  // Custom Questions
  final List<Map<String, dynamic>> _customQuestions = [];
  final _newQuestionTextController = TextEditingController();
  String _newQuestionType = 'text';
  final _newQuestionOptionsController = TextEditingController();
  final bool _newQuestionRequired = true;

  // Dropdown Selections
  String? _selectedCategoryId;
  String? _selectedCountryId;
  String _selectedCountryName = 'United Kingdom';
  String _selectedCategoryName = 'Work Visa';
  bool _isFeatured = false;
  bool _isActive = true;
  bool _isSaving = false;
  bool _isUploadingImage = false;

  final List<String> _tabTitles = [
    'General & Media',
    'Pricing & Metrics',
    'About & Scope',
    'Eligibility Criteria',
    'Procedure Timeline',
    'Application Requirements',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabTitles.length, vsync: this);

    final v = widget.existingVisa;
    final isNew = v == null;

    _titleController = TextEditingController(text: v?.title ?? '');
    _subtitleController = TextEditingController(text: v?.subtitle ?? '');
    _statusBadgeController =
        TextEditingController(text: v?.statusBadge ?? 'Available');
    _imageUrlController = TextEditingController(
        text: v?.imageUrl ??
            'https://images.unsplash.com/photo-1513635269975-59663e0ac1ad');

    _salaryController =
        TextEditingController(text: v?.salary ?? v?.salaryOrFunding ?? '');
    _feeController = TextEditingController(text: v?.fee ?? 'PKR 35,000');
    _serviceFeeLabelController =
        TextEditingController(text: v?.serviceFeeLabel ?? 'CONSULTANCY CHARGES');
    _serviceFeeValueController =
        TextEditingController(text: v?.serviceFeeValue ?? (v?.fee ?? 'PKR 35,000'));
    _totalPayableController =
        TextEditingController(text: v?.totalPayable ?? (v?.fee ?? 'PKR 35,000'));
    _processingTimeController =
        TextEditingController(text: v?.processingTime ?? '3-4 Weeks');
    _validityController = TextEditingController(text: v?.validity ?? '2-3 Years');
    _successRateController = TextEditingController(text: v?.successRate ?? '96%');
    _applicantsCountController =
        TextEditingController(text: v?.applicantsCount ?? '1,850+ Applicants');
    _ratingController =
        TextEditingController(text: (v?.rating ?? 4.9).toString());
    _reviewsCountController =
        TextEditingController(text: (v?.reviewsCount ?? 120).toString());
    _externalUrlController =
        TextEditingController(text: v?.externalUrl ?? '');

    _aboutTitleController =
        TextEditingController(text: v?.aboutTitle ?? 'About this visa');
    _aboutDescriptionController =
        TextEditingController(text: v?.aboutDescription ?? '');

    _selectedCategoryId = v?.categoryId ?? 'work';
    _selectedCountryId = v?.countryId ?? 'uk';
    _selectedCountryName = v?.countryName ?? 'United Kingdom';
    _selectedCategoryName = v?.categoryName ?? 'Work Visa';
    _isFeatured = v?.isFeatured ?? false;
    _isActive = v?.isActive ?? true;

    if (v != null) {
      _loadFromExisting(v);
    } else if (isNew) {
      _loadPresetData(showSnack: false);
    }
  }

  void _loadFromExisting(VisaListingItem v) {
    // 1. Eligibility Criteria
    if (v.eligibilityCriteria is List && (v.eligibilityCriteria as List).isNotEmpty) {
      for (final item in (v.eligibilityCriteria as List)) {
        _eligibilityControllers.add(TextEditingController(text: item.toString()));
      }
    }

    // 2. Documents
    if (v.mandatoryDocuments is List && (v.mandatoryDocuments as List).isNotEmpty) {
      for (final item in (v.mandatoryDocuments as List)) {
        if (item is Map) {
          _documentItems.add({
            'title': TextEditingController(text: item['title']?.toString() ?? ''),
            'note': TextEditingController(text: item['note']?.toString() ?? ''),
            'icon': item['icon']?.toString() ?? 'description',
          });
        }
      }
    }

    // 3. Timeline steps
    if (v.timelineSteps is List && (v.timelineSteps as List).isNotEmpty) {
      for (final item in (v.timelineSteps as List)) {
        if (item is Map) {
          _timelineItems.add({
            'title': TextEditingController(text: item['title']?.toString() ?? ''),
            'duration': TextEditingController(text: item['duration']?.toString() ?? ''),
            'description': TextEditingController(text: item['description']?.toString() ?? ''),
            'icon': item['icon']?.toString() ?? 'fact_check',
          });
        }
      }
    }

    // 4. Fee breakdown
    if (v.feeBreakdown is List && (v.feeBreakdown as List).isNotEmpty) {
      for (final item in (v.feeBreakdown as List)) {
        if (item is Map) {
          _feeBreakdownItems.add({
            'label': TextEditingController(text: item['label']?.toString() ?? ''),
            'amount': TextEditingController(text: item['amount']?.toString() ?? ''),
            'subNote': TextEditingController(
                text: item['subNote']?.toString() ?? item['sub_note']?.toString() ?? ''),
            'tag': TextEditingController(text: item['tag']?.toString() ?? ''),
          });
        }
      }
    }

    // 5. Application Requirements
    if (v.applicationRequirements is Map) {
      final reqs = Map<String, dynamic>.from(v.applicationRequirements as Map);

      if (reqs['age_requirement'] is Map) {
        final age = reqs['age_requirement'] as Map;
        _requireAge = age['enabled'] != false;
        _minAgeController.text = (age['min_age'] ?? '18').toString();
        _maxAgeController.text = (age['max_age'] ?? '35').toString();
        _ageBracketController.text = age['bracket']?.toString() ?? '18 - 35 Years';
      }

      if (reqs['education_requirement'] is Map) {
        final edu = reqs['education_requirement'] as Map;
        _requireEducation = edu['enabled'] != false;
        _minQualification = edu['min_qualification']?.toString() ?? "Bachelor's / Undergrad";
        _minMarksController.text = edu['min_cgpa_or_marks']?.toString() ?? '60%';
        _fieldOfStudyController.text = edu['field_of_study']?.toString() ?? '';
      }

      if (reqs['language_requirement'] is Map) {
        final lang = reqs['language_requirement'] as Map;
        _requireLanguage = lang['enabled'] != false;
        _languageTestType = lang['test_type']?.toString() ?? 'IELTS Academic / PTE';
        _minLanguageScoreController.text = lang['min_score']?.toString() ?? '6.0 Overall';
        _isLanguageMandatory = lang['is_mandatory'] != false;
      }

      if (reqs['experience_requirement'] is Map) {
        final exp = reqs['experience_requirement'] as Map;
        _requireExperience = exp['enabled'] == true;
        _minExperience = exp['min_years']?.toString() ?? 'Fresh Graduate Eligible';
        _roleLevelController.text = exp['role_level']?.toString() ?? '';
      }

      if (reqs['financial_requirement'] is Map) {
        final fin = reqs['financial_requirement'] as Map;
        _requireFinancial = fin['enabled'] != false;
        _minBankBalanceController.text = fin['min_bank_balance']?.toString() ?? 'PKR 2,500,000';
        _holdingPeriod = fin['holding_period']?.toString() ?? '28 Days Holding Record';
        _proofTypeController.text = fin['proof_type']?.toString() ?? 'Bank statement';
      }

      if (reqs['travel_history_requirement'] is Map) {
        final tr = reqs['travel_history_requirement'] as Map;
        _priorTravelRequired = tr['prior_travel_required'] == true;
        _rejectionDeclarationRequired = tr['rejection_declaration_required'] != false;
        _policeCertRequired = tr['police_certificate_required'] == true;
        _medicalCheckRequired = tr['medical_check_required'] != false;
      }

      if (reqs['custom_questions'] is List) {
        for (final q in (reqs['custom_questions'] as List)) {
          if (q is Map) {
            _customQuestions.add({
              'id': q['id']?.toString() ?? 'q_${DateTime.now().millisecondsSinceEpoch}',
              'question': q['question']?.toString() ?? '',
              'type': q['type']?.toString() ?? 'text',
              'options': q['options']?.toString() ?? '',
              'is_required': q['is_required'] != false,
            });
          }
        }
      }
    }

    if (_eligibilityControllers.isEmpty &&
        _documentItems.isEmpty &&
        _timelineItems.isEmpty &&
        _feeBreakdownItems.isEmpty) {
      _loadPresetData(showSnack: false);
    }
  }

  void _loadPresetData({bool showSnack = true}) {
    final catKey = _selectedCategoryId ?? _selectedCategoryName;
    final preset = VisaCategoryPreset.getPresetForCategory(catKey);

    setState(() {
      if (_aboutDescriptionController.text.trim().isEmpty) {
        _aboutTitleController.text = preset.aboutTitle;
        _aboutDescriptionController.text = preset.aboutDescription;
      }
      if (_salaryController.text.trim().isEmpty) {
        if (catKey.toLowerCase().contains('job') || catKey.toLowerCase().contains('sponsor')) {
          _salaryController.text = r'£38,500 – £44,000 / yr';
        } else if (catKey.toLowerCase().contains('scholarship')) {
          _salaryController.text = '100% Tuition + Monthly Stipend';
        }
      }
      if (_validityController.text.trim().isEmpty) {
        _validityController.text = preset.validity;
      }
      if (_successRateController.text.trim().isEmpty) {
        _successRateController.text = preset.successRate;
      }
      if (_applicantsCountController.text.trim().isEmpty) {
        _applicantsCountController.text = preset.applicantsCount;
      }
      if (_processingTimeController.text.trim().isEmpty) {
        _processingTimeController.text = preset.processingTime;
      }
      if (_feeController.text.trim().isEmpty) {
        _feeController.text = preset.fee;
      }
      if (_serviceFeeLabelController.text.trim().isEmpty) {
        _serviceFeeLabelController.text = preset.serviceFeeLabel;
      }
      if (_totalPayableController.text.trim().isEmpty) {
        _totalPayableController.text = preset.totalPayable;
      }
      if (_serviceFeeValueController.text.trim().isEmpty) {
        _serviceFeeValueController.text = preset.totalPayable;
      }
      if (_statusBadgeController.text.trim().isEmpty) {
        _statusBadgeController.text = preset.statusBadge;
      }

      // Load Eligibility Criteria
      for (final c in _eligibilityControllers) {
        c.dispose();
      }
      _eligibilityControllers.clear();
      for (final crit in preset.eligibilityCriteria) {
        _eligibilityControllers.add(TextEditingController(text: crit));
      }

      // Load Documents
      for (final d in _documentItems) {
        (d['title'] as TextEditingController).dispose();
        (d['note'] as TextEditingController).dispose();
      }
      _documentItems.clear();
      for (final doc in preset.mandatoryDocuments) {
        _documentItems.add({
          'title': TextEditingController(text: doc['title']),
          'note': TextEditingController(text: doc['note']),
          'icon': doc['icon'] ?? 'description',
        });
      }

      // Load Timeline Steps
      for (final t in _timelineItems) {
        (t['title'] as TextEditingController).dispose();
        (t['duration'] as TextEditingController).dispose();
        (t['description'] as TextEditingController).dispose();
      }
      _timelineItems.clear();
      for (final step in preset.timelineSteps) {
        _timelineItems.add({
          'title': TextEditingController(text: step['title']),
          'duration': TextEditingController(text: step['duration']),
          'description': TextEditingController(text: step['description']),
          'icon': step['icon'] ?? 'fact_check',
        });
      }

      // Load Fee Breakdown
      for (final f in _feeBreakdownItems) {
        (f['label'] as TextEditingController).dispose();
        (f['amount'] as TextEditingController).dispose();
        (f['subNote'] as TextEditingController).dispose();
        (f['tag'] as TextEditingController).dispose();
      }
      _feeBreakdownItems.clear();
      for (final fee in preset.feeBreakdown) {
        _feeBreakdownItems.add({
          'label': TextEditingController(text: fee['label']),
          'amount': TextEditingController(text: fee['amount']),
          'subNote': TextEditingController(text: fee['subNote']),
          'tag': TextEditingController(text: fee['tag']),
        });
      }

      // Load Application Requirements Preset
      final reqs = preset.applicationRequirements;
      if (reqs.isNotEmpty) {
        if (reqs['age_requirement'] is Map) {
          final age = reqs['age_requirement'] as Map;
          _requireAge = age['enabled'] != false;
          _minAgeController.text = (age['min_age'] ?? '18').toString();
          _maxAgeController.text = (age['max_age'] ?? '35').toString();
          _ageBracketController.text = age['bracket']?.toString() ?? '18 - 35 Years';
        }
        if (reqs['education_requirement'] is Map) {
          final edu = reqs['education_requirement'] as Map;
          _requireEducation = edu['enabled'] != false;
          _minQualification = edu['min_qualification']?.toString() ?? "Bachelor's / Undergrad";
          _minMarksController.text = edu['min_cgpa_or_marks']?.toString() ?? '60%';
          _fieldOfStudyController.text = edu['field_of_study']?.toString() ?? '';
        }
        if (reqs['language_requirement'] is Map) {
          final lang = reqs['language_requirement'] as Map;
          _requireLanguage = lang['enabled'] != false;
          _languageTestType = lang['test_type']?.toString() ?? 'IELTS Academic / PTE';
          _minLanguageScoreController.text = lang['min_score']?.toString() ?? '6.0 Overall';
          _isLanguageMandatory = lang['is_mandatory'] != false;
        }
        if (reqs['experience_requirement'] is Map) {
          final exp = reqs['experience_requirement'] as Map;
          _requireExperience = exp['enabled'] == true;
          _minExperience = exp['min_years']?.toString() ?? 'Fresh Graduate Eligible';
          _roleLevelController.text = exp['role_level']?.toString() ?? '';
        }
        if (reqs['financial_requirement'] is Map) {
          final fin = reqs['financial_requirement'] as Map;
          _requireFinancial = fin['enabled'] != false;
          _minBankBalanceController.text = fin['min_bank_balance']?.toString() ?? 'PKR 2,500,000';
          _holdingPeriod = fin['holding_period']?.toString() ?? '28 Days Holding Record';
          _proofTypeController.text = fin['proof_type']?.toString() ?? 'Bank statement';
        }
        if (reqs['travel_history_requirement'] is Map) {
          final tr = reqs['travel_history_requirement'] as Map;
          _priorTravelRequired = tr['prior_travel_required'] == true;
          _rejectionDeclarationRequired = tr['rejection_declaration_required'] != false;
          _policeCertRequired = tr['police_certificate_required'] == true;
          _medicalCheckRequired = tr['medical_check_required'] != false;
        }
        if (reqs['custom_questions'] is List) {
          _customQuestions.clear();
          for (final q in (reqs['custom_questions'] as List)) {
            if (q is Map) {
              _customQuestions.add({
                'id': q['id']?.toString() ?? 'q_${DateTime.now().millisecondsSinceEpoch}',
                'question': q['question']?.toString() ?? '',
                'type': q['type']?.toString() ?? 'text',
                'options': q['options']?.toString() ?? '',
                'is_required': q['is_required'] != false,
              });
            }
          }
        }
      }
    });

    if (showSnack && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Loaded recommended requirements preset for "$_selectedCategoryName"!'),
          backgroundColor: AdminColors.primary,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _titleController.dispose();
    _subtitleController.dispose();
    _statusBadgeController.dispose();
    _processingTimeController.dispose();
    _salaryController.dispose();
    _feeController.dispose();
    _imageUrlController.dispose();
    _validityController.dispose();
    _successRateController.dispose();
    _applicantsCountController.dispose();
    _serviceFeeLabelController.dispose();
    _serviceFeeValueController.dispose();
    _totalPayableController.dispose();
    _ratingController.dispose();
    _reviewsCountController.dispose();
    _externalUrlController.dispose();
    _aboutTitleController.dispose();
    _aboutDescriptionController.dispose();
    _newCriterionController.dispose();

    _minAgeController.dispose();
    _maxAgeController.dispose();
    _ageBracketController.dispose();
    _minMarksController.dispose();
    _fieldOfStudyController.dispose();
    _minLanguageScoreController.dispose();
    _roleLevelController.dispose();
    _minBankBalanceController.dispose();
    _proofTypeController.dispose();
    _newQuestionTextController.dispose();
    _newQuestionOptionsController.dispose();

    for (final c in _eligibilityControllers) {
      c.dispose();
    }
    for (final d in _documentItems) {
      (d['title'] as TextEditingController).dispose();
      (d['note'] as TextEditingController).dispose();
    }
    for (final t in _timelineItems) {
      (t['title'] as TextEditingController).dispose();
      (t['duration'] as TextEditingController).dispose();
      (t['description'] as TextEditingController).dispose();
    }
    for (final f in _feeBreakdownItems) {
      (f['label'] as TextEditingController).dispose();
      (f['amount'] as TextEditingController).dispose();
      (f['subNote'] as TextEditingController).dispose();
      (f['tag'] as TextEditingController).dispose();
    }

    super.dispose();
  }

  Future<void> _pickAndUploadImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );

    if (result != null && result.files.isNotEmpty) {
      final file = result.files.first;
      final bytes = file.bytes;
      if (bytes != null) {
        setState(() => _isUploadingImage = true);
        try {
          final url = await AdminVisaService.instance.uploadAsset(
            bytes,
            file.name,
            'image/${file.extension ?? 'jpeg'}',
          );
          _imageUrlController.text = url;
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Image uploaded to Supabase Storage!')),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Upload failed: $e')),
            );
          }
        } finally {
          if (mounted) setState(() => _isUploadingImage = false);
        }
      }
    }
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) {
      _tabController.animateTo(0);
      return;
    }

    setState(() => _isSaving = true);
    try {
      // Serialize eligibility
      final eligibilityPayload = _eligibilityControllers
          .map((c) => c.text.trim())
          .where((t) => t.isNotEmpty)
          .toList();

      // Documents section excluded as requested
      final documentsPayload = const <Map<String, dynamic>>[];

      // Serialize timeline
      final timelinePayload = _timelineItems.map((t) {
        return {
          'title': (t['title'] as TextEditingController).text.trim(),
          'duration': (t['duration'] as TextEditingController).text.trim(),
          'description': (t['description'] as TextEditingController).text.trim(),
          'icon': t['icon']?.toString() ?? 'fact_check',
        };
      }).where((t) => t['title']!.isNotEmpty).toList();

      // Serialize application requirements
      final applicationRequirementsPayload = {
        'age_requirement': {
          'enabled': _requireAge,
          'min_age': int.tryParse(_minAgeController.text.trim()) ?? 18,
          'max_age': int.tryParse(_maxAgeController.text.trim()) ?? 35,
          'bracket': _ageBracketController.text.trim(),
        },
        'education_requirement': {
          'enabled': _requireEducation,
          'min_qualification': _minQualification,
          'min_cgpa_or_marks': _minMarksController.text.trim(),
          'field_of_study': _fieldOfStudyController.text.trim(),
        },
        'language_requirement': {
          'enabled': _requireLanguage,
          'test_type': _languageTestType,
          'min_score': _minLanguageScoreController.text.trim(),
          'is_mandatory': _isLanguageMandatory,
        },
        'experience_requirement': {
          'enabled': _requireExperience,
          'min_years': _minExperience,
          'role_level': _roleLevelController.text.trim(),
        },
        'financial_requirement': {
          'enabled': _requireFinancial,
          'min_bank_balance': _minBankBalanceController.text.trim(),
          'holding_period': _holdingPeriod,
          'proof_type': _proofTypeController.text.trim(),
        },
        'travel_history_requirement': {
          'prior_travel_required': _priorTravelRequired,
          'rejection_declaration_required': _rejectionDeclarationRequired,
          'police_certificate_required': _policeCertRequired,
          'medical_check_required': _medicalCheckRequired,
        },
        'custom_questions': _customQuestions,
      };

      final categoriesList = ref.read(visaCategoriesProvider).value ?? [];
      final countriesList = ref.read(countriesProvider).value ?? [];

      final effectiveCategoryId = _selectedCategoryId ??
          widget.existingVisa?.categoryId ??
          categoriesList.firstOrNull?.id ??
          'study';

      String effectiveCategoryName = _selectedCategoryName;
      if (effectiveCategoryName.isEmpty && widget.existingVisa != null) {
        effectiveCategoryName = widget.existingVisa!.categoryName;
      }
      if (effectiveCategoryName.isEmpty) {
        effectiveCategoryName = categoriesList.any((c) => c.id == effectiveCategoryId)
            ? categoriesList.firstWhere((c) => c.id == effectiveCategoryId).label
            : 'Study Visa';
      }

      final effectiveCountryId = _selectedCountryId ??
          widget.existingVisa?.countryId ??
          countriesList.firstOrNull?.id ??
          'gb';

      String effectiveCountryName = _selectedCountryName;
      if (effectiveCountryName.isEmpty && widget.existingVisa != null) {
        effectiveCountryName = widget.existingVisa!.countryName;
      }
      if (effectiveCountryName.isEmpty) {
        effectiveCountryName = countriesList.any((c) => c.id == effectiveCountryId)
            ? countriesList.firstWhere((c) => c.id == effectiveCountryId).name
            : 'United Kingdom';
      }

      final data = <String, dynamic>{
        'title': _titleController.text.trim(),
        'subtitle': _subtitleController.text.trim(),
        'category_id': effectiveCategoryId,
        'country_id': effectiveCountryId,
        'country_name': effectiveCountryName,
        'category_name': effectiveCategoryName,
        'status_badge': _statusBadgeController.text.trim().isNotEmpty
            ? _statusBadgeController.text.trim()
            : 'Available',
        'processing_time': _processingTimeController.text.trim().isNotEmpty
            ? _processingTimeController.text.trim()
            : '15-20 Working Days',
        'fee': _feeController.text.trim().isNotEmpty
            ? _feeController.text.trim()
            : 'PKR 0',
        'image_url': _imageUrlController.text.trim().isNotEmpty
            ? _imageUrlController.text.trim()
            : 'https://images.unsplash.com/photo-1526778548025-fa2f459cd5c1?auto=format&fit=crop&w=800&q=80',
        'validity': _validityController.text.trim().isNotEmpty
            ? _validityController.text.trim()
            : '1 Year',
        'success_rate': _successRateController.text.trim().isNotEmpty
            ? _successRateController.text.trim()
            : '98%',
        'applicants_count': _applicantsCountController.text.trim().isNotEmpty
            ? _applicantsCountController.text.trim()
            : '500+ Applicants',
        'service_fee_label': _serviceFeeLabelController.text.trim().isNotEmpty
            ? _serviceFeeLabelController.text.trim()
            : 'SERVICE FEE',
        'service_fee_value': _serviceFeeValueController.text.trim().isNotEmpty
            ? _serviceFeeValueController.text.trim()
            : (_feeController.text.trim().isNotEmpty ? _feeController.text.trim() : 'PKR 25,000'),
        'total_payable': _totalPayableController.text.trim().isNotEmpty
            ? _totalPayableController.text.trim()
            : (_feeController.text.trim().isNotEmpty ? _feeController.text.trim() : 'PKR 25,000'),
        'rating': double.tryParse(_ratingController.text.trim()) ?? 4.9,
        'reviews_count': int.tryParse(_reviewsCountController.text.trim()) ?? 120,
        'about_title': _aboutTitleController.text.trim().isNotEmpty
            ? _aboutTitleController.text.trim()
            : 'About this visa',
        'about_description': _aboutDescriptionController.text.trim(),
        'external_url': _externalUrlController.text.trim().isNotEmpty
            ? _externalUrlController.text.trim()
            : null,
        'eligibility_criteria': eligibilityPayload,
        'mandatory_documents': documentsPayload,
        'timeline_steps': timelinePayload,
        'fee_breakdown': null,
        'salary': _salaryController.text.trim().isNotEmpty
            ? _salaryController.text.trim()
            : null,
        'salary_or_funding': _salaryController.text.trim().isNotEmpty
            ? _salaryController.text.trim()
            : null,
        'application_requirements': applicationRequirementsPayload,
        'is_featured': _isFeatured,
        'is_active': _isActive,
      };

      if (widget.existingVisa == null) {
        await AdminVisaService.instance.createVisa(data);
      } else {
        await AdminVisaService.instance.updateVisa(widget.existingVisa!.id, data);
      }

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save visa listing: $e'),
            backgroundColor: AdminColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isNew = widget.existingVisa == null;
    final categoriesAsync = ref.watch(visaCategoriesProvider);
    final countriesAsync = ref.watch(countriesProvider);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 1040,
          maxHeight: MediaQuery.of(context).size.height * 0.92,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Dialog Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                decoration: const BoxDecoration(
                  color: AdminColors.surface,
                  border: Border(bottom: BorderSide(color: AdminColors.border)),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AdminColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.flight_takeoff_rounded,
                          color: AdminColors.primary, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isNew ? 'Create New Visa Listing' : 'Edit Visa Listing: ${_titleController.text}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AdminColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Configure comprehensive visa details, procedure milestones, and applicant requirements',
                            style: TextStyle(fontSize: 12.5, color: AdminColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        foregroundColor: AdminColors.primary,
                        backgroundColor: AdminColors.primary.withValues(alpha: 0.08),
                      ),
                      onPressed: () => _loadPresetData(showSnack: true),
                      icon: const Icon(Icons.auto_fix_high_rounded, size: 16),
                      label: const Text('Auto-fill Category Presets'),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.close, color: AdminColors.textMuted),
                      onPressed: () => Navigator.of(context).pop(false),
                    ),
                  ],
                ),
              ),

              // Tab Navigation Bar
              Container(
                color: Colors.white,
                child: TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  labelColor: AdminColors.primary,
                  unselectedLabelColor: AdminColors.textSecondary,
                  indicatorColor: AdminColors.primary,
                  indicatorWeight: 3,
                  labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                  unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                  tabs: _tabTitles.map((t) => Tab(text: t)).toList(),
                ),
              ),
              const Divider(height: 1, color: AdminColors.border),

              // Tab Views
              Expanded(
                child: Container(
                  color: AdminColors.background,
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildGeneralTab(categoriesAsync, countriesAsync),
                      _buildPricingAndMetricsTab(),
                      _buildAboutTab(),
                      _buildEligibilityTab(),
                      _buildTimelineTab(),
                      _buildApplicationRequirementsTab(),
                    ],
                  ),
                ),
              ),

              // Dialog Footer / Actions
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                decoration: const BoxDecoration(
                  color: AdminColors.surface,
                  border: Border(top: BorderSide(color: AdminColors.border)),
                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
                ),
                child: Row(
                  children: [
                    Text(
                      'Category: $_selectedCategoryName  |  Destination: $_selectedCountryName',
                      style: const TextStyle(fontSize: 12.5, color: AdminColors.textSecondary, fontWeight: FontWeight.w500),
                    ),
                    const Spacer(),
                    OutlinedButton(
                      onPressed: _isSaving ? null : () => Navigator.of(context).pop(false),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AdminColors.primary,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      ),
                      onPressed: _isSaving ? null : _handleSave,
                      icon: _isSaving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.check_circle_outline, size: 18),
                      label: Text(
                        _isSaving
                            ? 'Saving...'
                            : (isNew ? 'Publish Visa Listing' : 'Save All Changes'),
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =========================================================================
  // TAB 1: GENERAL & DESTINATION
  // =========================================================================
  Widget _buildGeneralTab(
    AsyncValue<List<VisaCategoryItem>> categoriesAsync,
    AsyncValue<List<CountryItem>> countriesAsync,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Visa Title *',
                        hintText: 'e.g. UK Student Visa (Tier 4 / Student Route)',
                        prefixIcon: Icon(Icons.title_rounded, size: 18),
                      ),
                      validator: (val) => val == null || val.trim().isEmpty ? 'Title is required' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _subtitleController,
                      decoration: const InputDecoration(
                        labelText: 'Subtitle / Route Tag',
                        hintText: 'e.g. Higher Education Route / Full-Time Employment',
                        prefixIcon: Icon(Icons.subtitles_rounded, size: 18),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        // Category Dropdown
                        Expanded(
                          child: categoriesAsync.when(
                            loading: () => const LinearProgressIndicator(),
                            error: (_, __) => const Text('Error loading categories'),
                            data: (cats) {
                              final allCats = [...cats];
                              if (!allCats.any((c) => c.id == 'jobs' || c.label.toLowerCase().contains('job') || c.label.toLowerCase().contains('sponsor'))) {
                                allCats.add(const VisaCategoryItem(id: 'jobs', label: 'Sponsored Jobs'));
                              }
                              if (!allCats.any((c) => c.id == 'scholarships' || c.label.toLowerCase().contains('scholarship'))) {
                                allCats.add(const VisaCategoryItem(id: 'scholarships', label: 'Scholarships'));
                              }

                              return DropdownButtonFormField<String>(
                                initialValue: allCats.any((c) => c.id == _selectedCategoryId)
                                    ? _selectedCategoryId
                                    : allCats.firstOrNull?.id,
                                decoration: const InputDecoration(
                                  labelText: 'Category *',
                                  prefixIcon: Icon(Icons.category_rounded, size: 18),
                                ),
                                items: allCats.map((c) {
                                  return DropdownMenuItem(value: c.id, child: Text(c.label));
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null) {
                                    final cat = allCats.firstWhere((c) => c.id == val, orElse: () => allCats.first);
                                    setState(() {
                                      _selectedCategoryId = val;
                                      _selectedCategoryName = cat.label;
                                      if (val == 'jobs' || val.toLowerCase().contains('job') || val.toLowerCase().contains('sponsor') || cat.label.toLowerCase().contains('job')) {
                                        if (_salaryController.text.trim().isEmpty) {
                                          _salaryController.text = r'£38,500 – £44,000 / yr';
                                        }
                                        if (_statusBadgeController.text.trim().isEmpty || _statusBadgeController.text == 'Available') {
                                          _statusBadgeController.text = 'Visa Sponsored';
                                        }
                                      } else if (val == 'scholarships' || val.toLowerCase().contains('scholarship') || cat.label.toLowerCase().contains('scholarship')) {
                                        if (_salaryController.text.trim().isEmpty) {
                                          _salaryController.text = '100% Tuition + Monthly Stipend';
                                        }
                                        if (_statusBadgeController.text.trim().isEmpty || _statusBadgeController.text == 'Available') {
                                          _statusBadgeController.text = 'Fully Funded';
                                        }
                                      }
                                    });
                                  }
                                },
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Country Dropdown
                        Expanded(
                          child: countriesAsync.when(
                            loading: () => const LinearProgressIndicator(),
                            error: (_, __) => const Text('Error loading countries'),
                            data: (countries) {
                              return DropdownButtonFormField<String>(
                                initialValue: countries.any((c) => c.id == _selectedCountryId)
                                    ? _selectedCountryId
                                    : countries.firstOrNull?.id,
                                decoration: const InputDecoration(
                                  labelText: 'Destination Country *',
                                  prefixIcon: Icon(Icons.public_rounded, size: 18),
                                ),
                                items: countries.map((c) {
                                  return DropdownMenuItem(
                                    value: c.id,
                                    child: Text('${c.flagEmoji ?? '🌍'}  ${c.name}'),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null) {
                                    final country = countries.firstWhere((c) => c.id == val);
                                    setState(() {
                                      _selectedCountryId = val;
                                      _selectedCountryName = country.name;
                                    });
                                  }
                                },
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Sponsored Jobs Per Annum Pay / Salary package edit field directly in General & Media
                    TextFormField(
                      controller: _salaryController,
                      decoration: const InputDecoration(
                        labelText: 'Sponsored Jobs Per Annum Pay / Salary Package 💰',
                        hintText: r'e.g. £38,500 – £44,000 / yr or CAD$85,000 / yr',
                        prefixIcon: Icon(Icons.payments_outlined, color: AdminColors.success, size: 18),
                        helperText: 'Displayed as the salary package in Sponsored Jobs cards and detail view.',
                      ),
                    ),
                    const SizedBox(height: 16),
                    // External Application URL / Apply on Link
                    TextFormField(
                      controller: _externalUrlController,
                      decoration: const InputDecoration(
                        labelText: 'Application / Portal URL (Apply on Link) 🔗',
                        hintText: 'e.g. https://uk.indeed.com/... or https://jobs.nhs.uk/job-123',
                        prefixIcon: Icon(Icons.link_rounded, color: AdminColors.primary, size: 18),
                        helperText: 'When filled, applicants tap "Apply on Link" to open this application URL directly.',
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _statusBadgeController,
                      decoration: const InputDecoration(
                        labelText: 'Status Badge Text',
                        hintText: 'e.g. Available, Visa Sponsored, Actively Hiring, Fully Funded',
                        prefixIcon: Icon(Icons.verified_user_rounded, size: 18),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              // Cover Image & File Upload
              Expanded(
                flex: 2,
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Cover / Hero Image',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            height: 140,
                            width: double.infinity,
                            color: AdminColors.surfaceMuted,
                            child: Image.network(
                              _imageUrlController.text.trim(),
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Center(
                                child: Icon(Icons.image_not_supported_rounded, size: 36, color: AdminColors.textMuted),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _imageUrlController,
                          decoration: const InputDecoration(
                            labelText: 'Image Web URL',
                            prefixIcon: Icon(Icons.link_rounded, size: 18),
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _isUploadingImage ? null : _pickAndUploadImage,
                            icon: _isUploadingImage
                                ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                                : const Icon(Icons.upload_file_rounded, size: 16),
                            label: Text(_isUploadingImage ? 'Uploading...' : 'Upload Image from PC'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Divider(color: AdminColors.border),
          const SizedBox(height: 16),
          // Visibility & Feature Toggles
          Row(
            children: [
              Expanded(
                child: SwitchListTile(
                  title: const Text('Publish Immediately (Active in Apps)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  subtitle: const Text('Live and visible to applicants in catalog search', style: TextStyle(fontSize: 12)),
                  value: _isActive,
                  activeThumbColor: AdminColors.success,
                  onChanged: (val) => setState(() => _isActive = val),
                ),
              ),
              Expanded(
                child: SwitchListTile(
                  title: const Text('Feature on Homepage Carousel', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  subtitle: const Text('Highlighted prominently in mobile app hero banners', style: TextStyle(fontSize: 12)),
                  value: _isFeatured,
                  activeThumbColor: AdminColors.primary,
                  onChanged: (val) => setState(() => _isFeatured = val),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // TAB 2: PRICING & METRICS
  // =========================================================================
  Widget _buildPricingAndMetricsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Fee Structure & Salary Display (Matches Mobile App)',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AdminColors.textPrimary)),
          const SizedBox(height: 4),
          const Text('Configure annual salary for sponsored jobs/work permits and consultancy charges',
              style: TextStyle(fontSize: 12.5, color: AdminColors.textSecondary)),
          const SizedBox(height: 16),
          TextFormField(
            controller: _salaryController,
            decoration: const InputDecoration(
              labelText: 'Salary Per Annum (As Displayed in App for Jobs)',
              hintText: r'e.g. £36,000 – £44,000 / yr or CAD$85,000 / yr',
              prefixIcon: Icon(Icons.monetization_on_rounded, color: AdminColors.success, size: 18),
              helperText: 'Shown prominently as the annual compensation in mobile app cards and detail view.',
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _feeController,
                  decoration: const InputDecoration(
                    labelText: 'Display Fee (e.g. PKR 35,000) *',
                    prefixIcon: Icon(Icons.payments_rounded, size: 18),
                  ),
                  validator: (val) => val == null || val.trim().isEmpty ? 'Fee is required' : null,
                  onChanged: (val) {
                    if (_serviceFeeValueController.text.isEmpty || _serviceFeeValueController.text == _totalPayableController.text) {
                      _serviceFeeValueController.text = val;
                      _totalPayableController.text = val;
                    }
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _serviceFeeLabelController,
                  decoration: const InputDecoration(
                    labelText: 'Service Fee Label',
                    hintText: 'e.g. CONSULTANCY CHARGES / ADVISORY FEE',
                    prefixIcon: Icon(Icons.label_outline_rounded, size: 18),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _serviceFeeValueController,
                  decoration: const InputDecoration(
                    labelText: 'Service Fee Amount',
                    hintText: 'e.g. PKR 35,000',
                    prefixIcon: Icon(Icons.receipt_rounded, size: 18),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _totalPayableController,
                  decoration: const InputDecoration(
                    labelText: 'Total Payable at Checkout',
                    hintText: 'e.g. PKR 35,000',
                    prefixIcon: Icon(Icons.monetization_on_rounded, size: 18),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Divider(color: AdminColors.border),
          const SizedBox(height: 16),
          const Text('Operational Metrics & Consular Details',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AdminColors.textPrimary)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _processingTimeController,
                  decoration: const InputDecoration(
                    labelText: 'Processing Time *',
                    hintText: 'e.g. 3-4 Weeks / 10-15 Days',
                    prefixIcon: Icon(Icons.timer_rounded, size: 18),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _validityController,
                  decoration: const InputDecoration(
                    labelText: 'Visa Validity',
                    hintText: 'e.g. 2-3 Years / 60 Days Multiple',
                    prefixIcon: Icon(Icons.date_range_rounded, size: 18),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _successRateController,
                  decoration: const InputDecoration(
                    labelText: 'Success Rate (%)',
                    hintText: 'e.g. 96%',
                    prefixIcon: Icon(Icons.auto_graph_rounded, size: 18),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _applicantsCountController,
                  decoration: const InputDecoration(
                    labelText: 'Applicants Served Count',
                    hintText: 'e.g. 1,850+ Applicants',
                    prefixIcon: Icon(Icons.people_alt_rounded, size: 18),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _ratingController,
                  decoration: const InputDecoration(
                    labelText: 'Star Rating (0.0 - 5.0)',
                    hintText: '4.9',
                    prefixIcon: Icon(Icons.star_rounded, size: 18),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _reviewsCountController,
                  decoration: const InputDecoration(
                    labelText: 'Reviews Count',
                    hintText: '120',
                    prefixIcon: Icon(Icons.reviews_rounded, size: 18),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _externalUrlController,
            decoration: const InputDecoration(
              labelText: 'Official Government / Consular Portal Link (Optional)',
              hintText: 'e.g. https://www.gov.uk/student-visa or https://gdrfad.gov.ae',
              prefixIcon: Icon(Icons.open_in_new_rounded, size: 18),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // TAB 3: ABOUT & SCOPE
  // =========================================================================
  Widget _buildAboutTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: _aboutTitleController,
            decoration: const InputDecoration(
              labelText: 'About Title',
              hintText: 'e.g. About this visa / Student Route Overview',
              prefixIcon: Icon(Icons.info_outline_rounded, size: 18),
            ),
          ),
          const SizedBox(height: 20),
          const Text('Comprehensive Visa Description & Permissions',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          const Text(
            'Detail work permissions, study privileges, dependent sponsorship rights, and the specific advisory services delivered by SB Consultants.',
            style: TextStyle(fontSize: 12.5, color: AdminColors.textSecondary),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _aboutDescriptionController,
            maxLines: 12,
            decoration: const InputDecoration(
              hintText: 'Provide complete details regarding the legal scope, work rights, and end-to-end consultancy coverage...',
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // TAB 4: ELIGIBILITY CRITERIA
  // =========================================================================
  Widget _buildEligibilityTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _newCriterionController,
                  decoration: const InputDecoration(
                    labelText: 'Add New Eligibility Criterion',
                    hintText: 'e.g. Minimum IELTS Academic 6.5 band overall...',
                    prefixIcon: Icon(Icons.add_circle_outline, size: 18),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: () {
                  final text = _newCriterionController.text.trim();
                  if (text.isNotEmpty) {
                    setState(() {
                      _eligibilityControllers.add(TextEditingController(text: text));
                      _newCriterionController.clear();
                    });
                  }
                },
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add Rule'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'Configured Eligibility Rules (${_eligibilityControllers.length})',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          if (_eligibilityControllers.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Center(
                  child: Text('No eligibility criteria defined yet. Click "Auto-fill Category Presets" or add custom rules above.'),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _eligibilityControllers.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 14,
                          backgroundColor: AdminColors.primary.withValues(alpha: 0.1),
                          child: Text('${index + 1}',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AdminColors.primary)),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: TextFormField(
                            controller: _eligibilityControllers[index],
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(vertical: 8),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 18, color: AdminColors.danger),
                          onPressed: () {
                            setState(() {
                              _eligibilityControllers[index].dispose();
                              _eligibilityControllers.removeAt(index);
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }



  // =========================================================================
  // TAB 6: PROCEDURE TIMELINE STEPS
  // =========================================================================
  Widget _buildTimelineTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Procedural Milestone Stepper (${_timelineItems.length} Milestones)',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _timelineItems.add({
                      'title': TextEditingController(text: 'New Procedure Milestone'),
                      'duration': TextEditingController(text: '1-2 Weeks'),
                      'description': TextEditingController(text: 'Detailed procedure guidance for this phase'),
                      'icon': 'fact_check',
                    });
                  });
                },
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add Milestone Step'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _timelineItems.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final step = _timelineItems[index];
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: AdminColors.primary,
                        child: Text('${index + 1}',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: TextFormField(
                                    controller: step['title'] as TextEditingController,
                                    decoration: const InputDecoration(labelText: 'Milestone Title', isDense: true),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  flex: 2,
                                  child: TextFormField(
                                    controller: step['duration'] as TextEditingController,
                                    decoration: const InputDecoration(labelText: 'Duration (e.g. 1-2 wks)', isDense: true),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            TextFormField(
                              controller: step['description'] as TextEditingController,
                              maxLines: 2,
                              decoration: const InputDecoration(labelText: 'Milestone Scope & Description', isDense: true),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: AdminColors.danger),
                        onPressed: () {
                          setState(() {
                            (step['title'] as TextEditingController).dispose();
                            (step['duration'] as TextEditingController).dispose();
                            (step['description'] as TextEditingController).dispose();
                            _timelineItems.removeAt(index);
                          });
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // TAB 8: APPLICATION REQUIREMENTS (MANAGED BY ADMIN!)
  // Directly controls what the applicant must provide when applying!
  // =========================================================================
  Widget _buildApplicationRequirementsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AdminColors.primary.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AdminColors.primary.withValues(alpha: 0.2)),
            ),
            child: const Row(
              children: [
                Icon(Icons.tune_rounded, color: AdminColors.primary, size: 24),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Applicant Form Rules & Mandatory Input Configuration',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AdminColors.primary),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Configure which criteria, qualifications, bank proofs, and questions are mandated from applicants when submitting their dossier.',
                        style: TextStyle(fontSize: 12.5, color: AdminColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 1. Academic & Education Requirements
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.school_rounded, color: AdminColors.primary, size: 20),
                      const SizedBox(width: 10),
                      const Text('1. Academic & Qualification Rules',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                      const Spacer(),
                      Switch(
                        value: _requireEducation,
                        activeThumbColor: AdminColors.primary,
                        onChanged: (val) => setState(() => _requireEducation = val),
                      ),
                    ],
                  ),
                  if (_requireEducation) ...[
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Builder(
                            builder: (context) {
                              final qualOptions = [
                                'Any / No Formal Degree',
                                'Matric / O-Levels',
                                'Intermediate / A-Levels',
                                "Bachelor's / Undergrad",
                                "Bachelor's / Associate Degree",
                                "Bachelor's Degree (4-Year)",
                                "Intermediate / Bachelor’s Degree",
                                "Master's / Postgrad",
                                'PhD / Doctorate',
                                'Degree or Accredited Executive Background',
                                'Not Mandatory (Experience Weighted)',
                                'Not Applicable',
                              ];
                              final allQuals = {...qualOptions, _minQualification}.toList();
                              return DropdownButtonFormField<String>(
                                initialValue: allQuals.contains(_minQualification) ? _minQualification : allQuals.first,
                                decoration: const InputDecoration(labelText: 'Minimum Qualification Level'),
                                items: allQuals.map((q) => DropdownMenuItem(value: q, child: Text(q))).toList(),
                                onChanged: (val) {
                                  if (val != null) setState(() => _minQualification = val);
                                },
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _minMarksController,
                            decoration: const InputDecoration(
                              labelText: 'Minimum Required Marks / CGPA',
                              hintText: 'e.g. 60% or 3.0 CGPA',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _fieldOfStudyController,
                      decoration: const InputDecoration(
                        labelText: 'Preferred Field of Study / Relevant Major',
                        hintText: 'e.g. STEM, Business, IT, or Healthcare',
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 2. Language Proficiency Requirements
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.translate_rounded, color: AdminColors.primary, size: 20),
                      const SizedBox(width: 10),
                      const Text('2. English & Language Competency',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                      const Spacer(),
                      Switch(
                        value: _requireLanguage,
                        activeThumbColor: AdminColors.primary,
                        onChanged: (val) => setState(() => _requireLanguage = val),
                      ),
                    ],
                  ),
                  if (_requireLanguage) ...[
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Builder(
                            builder: (context) {
                              final langOptions = [
                                'IELTS Academic / PTE',
                                'IELTS General / UKVI',
                                'IELTS Academic',
                                'TOEFL iBT',
                                'Duolingo English Test',
                                'English Medium of Instruction Letter',
                                'Basic Business English',
                                'Exempt / Basic Communication',
                                'None / Exempt',
                                'None Required',
                              ];
                              final allLang = {...langOptions, _languageTestType}.toList();
                              return DropdownButtonFormField<String>(
                                initialValue: allLang.contains(_languageTestType) ? _languageTestType : allLang.first,
                                decoration: const InputDecoration(labelText: 'Standard Test Required'),
                                items: allLang.map((l) => DropdownMenuItem(value: l, child: Text(l))).toList(),
                                onChanged: (val) {
                                  if (val != null) setState(() => _languageTestType = val);
                                },
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _minLanguageScoreController,
                            decoration: const InputDecoration(
                              labelText: 'Minimum Required Band / Score',
                              hintText: 'e.g. 6.5 Overall (min 6.0 each)',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Strictly Mandatory (Application cannot proceed without score)', style: TextStyle(fontSize: 13)),
                      value: _isLanguageMandatory,
                      activeColor: AdminColors.primary,
                      onChanged: (val) => setState(() => _isLanguageMandatory = val == true),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 3. Age & Experience Rules
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.cake_rounded, color: AdminColors.primary, size: 20),
                      const SizedBox(width: 10),
                      const Text('3. Age Limits & Work Experience Criteria',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                      const Spacer(),
                      Switch(
                        value: _requireAge,
                        activeThumbColor: AdminColors.primary,
                        onChanged: (val) => setState(() => _requireAge = val),
                      ),
                    ],
                  ),
                  if (_requireAge) ...[
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _minAgeController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Minimum Age (Years)'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _maxAgeController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Maximum Age (Years)'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            controller: _ageBracketController,
                            decoration: const InputDecoration(labelText: 'Age Bracket Label', hintText: 'e.g. 18 - 35 Years'),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 16),
                  const Divider(color: AdminColors.border),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Text('Work Experience Verification', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      const Spacer(),
                      Switch(
                        value: _requireExperience,
                        activeThumbColor: AdminColors.primary,
                        onChanged: (val) => setState(() => _requireExperience = val),
                      ),
                    ],
                  ),
                  if (_requireExperience) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Builder(
                            builder: (context) {
                              final expOptions = [
                                'Fresh Graduate Eligible',
                                'No Experience Required',
                                '1 - 2 Years',
                                '2 - 3 Years',
                                '3 - 5 Years',
                                '5+ Years Senior',
                                '1+ Year Employment or Business',
                                '5+ Years Executive / Ownership Experience',
                                '2+ Years Registered Business Operations',
                                'Research or Academic Experience Preferred',
                              ];
                              final allExp = {...expOptions, _minExperience}.toList();
                              return DropdownButtonFormField<String>(
                                initialValue: allExp.contains(_minExperience) ? _minExperience : allExp.first,
                                decoration: const InputDecoration(labelText: 'Minimum Documented Experience'),
                                items: allExp.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                                onChanged: (val) {
                                  if (val != null) setState(() => _minExperience = val);
                                },
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _roleLevelController,
                            decoration: const InputDecoration(labelText: 'Expected Role / Trade Level', hintText: 'e.g. Skilled Professional'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 4. Financial & Bank Statement Requirements
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.account_balance_rounded, color: AdminColors.primary, size: 20),
                      const SizedBox(width: 10),
                      const Text('4. Financial Proof & Bank Maintenance Balance',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                      const Spacer(),
                      Switch(
                        value: _requireFinancial,
                        activeThumbColor: AdminColors.primary,
                        onChanged: (val) => setState(() => _requireFinancial = val),
                      ),
                    ],
                  ),
                  if (_requireFinancial) ...[
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _minBankBalanceController,
                            decoration: const InputDecoration(
                              labelText: 'Minimum Bank Balance',
                              hintText: 'e.g. PKR 3,500,000 / £12,000',
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Builder(
                            builder: (context) {
                              final holdingOptions = [
                                '28 Days Holding Record',
                                '28 Days Continuous Holding',
                                '3 Months Verified Statement',
                                '6 Months Verified Statement',
                                '6 Months Company Bank Statement',
                                '1 Year Audited Turnover',
                                'Audited Financial Statements (Last 2 Years)',
                                'Exempt (Fully Funded by Grant)',
                                'N/A',
                              ];
                              final allHolding = {...holdingOptions, _holdingPeriod}.toList();
                              return DropdownButtonFormField<String>(
                                initialValue: allHolding.contains(_holdingPeriod) ? _holdingPeriod : allHolding.first,
                                decoration: const InputDecoration(labelText: 'Statement Holding Duration'),
                                items: allHolding.map((h) => DropdownMenuItem(value: h, child: Text(h))).toList(),
                                onChanged: (val) {
                                  if (val != null) setState(() => _holdingPeriod = val);
                                },
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _proofTypeController,
                      decoration: const InputDecoration(
                        labelText: 'Maintenance Proof Description',
                        hintText: 'e.g. Personal bank statement with official bank verification letter',
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 5. Travel Background & Legal Checks
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.security_rounded, color: AdminColors.primary, size: 20),
                      SizedBox(width: 10),
                      Text('5. Travel History & Security Clearance Checkpoints',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Require Prior Travel History (Frequent Traveler)', style: TextStyle(fontSize: 13)),
                    value: _priorTravelRequired,
                    activeColor: AdminColors.primary,
                    onChanged: (val) => setState(() => _priorTravelRequired = val == true),
                  ),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Require Declaration of Prior Visa Refusals', style: TextStyle(fontSize: 13)),
                    value: _rejectionDeclarationRequired,
                    activeColor: AdminColors.primary,
                    onChanged: (val) => setState(() => _rejectionDeclarationRequired = val == true),
                  ),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Require Police Character Clearance Certificate', style: TextStyle(fontSize: 13)),
                    value: _policeCertRequired,
                    activeColor: AdminColors.primary,
                    onChanged: (val) => setState(() => _policeCertRequired = val == true),
                  ),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Require Medical / Tuberculosis (TB) Fitness Screening', style: TextStyle(fontSize: 13)),
                    value: _medicalCheckRequired,
                    activeColor: AdminColors.primary,
                    onChanged: (val) => setState(() => _medicalCheckRequired = val == true),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 6. Custom Dynamic Questions
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.help_outline_rounded, color: AdminColors.primary, size: 20),
                      const SizedBox(width: 10),
                      Text('6. Custom Dynamic Applicant Questions (${_customQuestions.length})',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text('Add visa-specific questions that the applicant must answer when filling the application form.',
                      style: TextStyle(fontSize: 12.5, color: AdminColors.textSecondary)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: TextField(
                          controller: _newQuestionTextController,
                          decoration: const InputDecoration(
                            labelText: 'Question Text',
                            hintText: 'e.g. Do you have a CAS letter from an approved UK sponsor?',
                            isDense: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: Builder(
                          builder: (context) {
                            final types = ['text', 'dropdown', 'number', 'yes_no'];
                            final selected = types.contains(_newQuestionType) ? _newQuestionType : types.first;
                            return DropdownButtonFormField<String>(
                              initialValue: selected,
                              decoration: const InputDecoration(labelText: 'Field Type', isDense: true),
                              items: const [
                                DropdownMenuItem(value: 'text', child: Text('Text Input')),
                                DropdownMenuItem(value: 'dropdown', child: Text('Dropdown Choice')),
                                DropdownMenuItem(value: 'number', child: Text('Number Input')),
                                DropdownMenuItem(value: 'yes_no', child: Text('Yes / No Toggle')),
                              ],
                              onChanged: (val) {
                                if (val != null) setState(() => _newQuestionType = val);
                              },
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: () {
                          final qText = _newQuestionTextController.text.trim();
                          if (qText.isNotEmpty) {
                            setState(() {
                              _customQuestions.add({
                                'id': 'q_${DateTime.now().millisecondsSinceEpoch}',
                                'question': qText,
                                'type': _newQuestionType,
                                'options': _newQuestionOptionsController.text.trim(),
                                'is_required': _newQuestionRequired,
                              });
                              _newQuestionTextController.clear();
                              _newQuestionOptionsController.clear();
                            });
                          }
                        },
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('Add Field'),
                      ),
                    ],
                  ),
                  if (_newQuestionType == 'dropdown') ...[
                    const SizedBox(height: 10),
                    TextField(
                      controller: _newQuestionOptionsController,
                      decoration: const InputDecoration(
                        labelText: 'Dropdown Options (Comma-separated)',
                        hintText: 'e.g. Yes - CAS Issued, In Process, No - Need Assistance',
                        isDense: true,
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  if (_customQuestions.isNotEmpty)
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _customQuestions.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final q = _customQuestions[index];
                        return Card(
                          color: AdminColors.surfaceMuted,
                          child: ListTile(
                            dense: true,
                            leading: CircleAvatar(
                              radius: 12,
                              backgroundColor: AdminColors.primary.withValues(alpha: 0.1),
                              child: Text('${index + 1}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AdminColors.primary)),
                            ),
                            title: Text(q['question']?.toString() ?? '', style: const TextStyle(fontWeight: FontWeight.w600)),
                            subtitle: Text('Type: ${(q['type']?.toString() ?? 'text').toUpperCase()} ${q['options']?.toString().isNotEmpty == true ? '• Options: ${q['options']}' : ''}'),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline, size: 18, color: AdminColors.danger),
                              onPressed: () => setState(() => _customQuestions.removeAt(index)),
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
