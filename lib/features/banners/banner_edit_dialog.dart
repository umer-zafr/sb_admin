// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../../core/theme/admin_theme.dart';
import '../../models/admin_banner_model.dart';
import '../../models/visa_model.dart';
import '../../services/admin_banner_service.dart';
import '../../services/admin_visa_service.dart';

class BannerEditDialog extends ConsumerStatefulWidget {
  const BannerEditDialog({super.key, this.existingBanner});

  final AdminBannerItem? existingBanner;

  static Future<bool?> show(BuildContext context, {AdminBannerItem? banner}) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => BannerEditDialog(existingBanner: banner),
    );
  }

  @override
  ConsumerState<BannerEditDialog> createState() => _BannerEditDialogState();
}

class _BannerEditDialogState extends ConsumerState<BannerEditDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _titleController;
  late final TextEditingController _subtitleController;
  late final TextEditingController _badgeController;
  late final TextEditingController _actionTextController;
  late final TextEditingController _actionUrlController;
  late final TextEditingController _imageUrlController;
  late final TextEditingController _gradientStartController;
  late final TextEditingController _gradientEndController;
  late final TextEditingController _displayOrderController;

  late String _selectedPlacement;
  late String _categoryName;
  bool _isActive = true;
  bool _isSaving = false;
  bool _isUploadingImage = false;

  List<VisaListingItem> _availableVisas = [];
  bool _isLoadingVisas = true;
  String? _selectedVisaId;
  String _destinationType = 'category'; // 'category', 'visa', 'custom'

  static const List<Map<String, String>> _placementOptions = [
    {'value': 'all', 'label': 'All Pages (Home & Global)', 'category': 'All Pages'},
    {'value': 'visas', 'label': 'All Visas Catalog', 'category': 'All Visas'},
    {'value': 'study', 'label': 'Study Visa Page', 'category': 'Study Visa'},
    {'value': 'work', 'label': 'Work Visa Page', 'category': 'Work Visa'},
    {'value': 'visit', 'label': 'Visit Visa Page', 'category': 'Visit Visa'},
    {'value': 'business', 'label': 'Business Visa Page', 'category': 'Business Visa'},
    {'value': 'golden', 'label': 'Golden Visa Page', 'category': 'Golden Visa'},
    {'value': 'jobs', 'label': 'Sponsored Jobs Page', 'category': 'Sponsored Jobs'},
    {'value': 'scholarships', 'label': 'Scholarships Page', 'category': 'Scholarships'},
  ];

  static const List<Map<String, String>> _destinationCategoryOptions = [
    {'route': '/visas', 'label': 'All Visas Catalog (/visas)', 'defaultCta': 'Explore All Visas'},
    {'route': '/study', 'label': 'Study Visa Page (/study)', 'defaultCta': 'Explore Study Visas'},
    {'route': '/work', 'label': 'Work Visa Page (/work)', 'defaultCta': 'Explore Work Visas'},
    {'route': '/visit', 'label': 'Visit Visa Page (/visit)', 'defaultCta': 'Apply Visit Visa'},
    {'route': '/business', 'label': 'Business Visa Page (/business)', 'defaultCta': 'Explore Business'},
    {'route': '/golden', 'label': 'Golden Visa Page (/golden)', 'defaultCta': 'Apply Golden Visa'},
    {'route': '/jobs', 'label': 'Sponsored Jobs Page (/jobs)', 'defaultCta': 'View Sponsored Jobs'},
    {'route': '/scholarships', 'label': 'Scholarships Page (/scholarships)', 'defaultCta': 'View Scholarships'},
  ];

  static const List<Map<String, String>> _gradientPresets = [
    {
      'label': 'Navy Classic',
      'start': '0xFF1B3A5C',
      'end': '0xFF2A5A8C',
    },
    {
      'label': 'Royal Indigo',
      'start': '0xFF1E1B4B',
      'end': '0xFF3730A3',
    },
    {
      'label': 'Emerald Green',
      'start': '0xFF064E3B',
      'end': '0xFF059669',
    },
    {
      'label': 'Deep Amber',
      'start': '0xFF78350F',
      'end': '0xFFD97706',
    },
    {
      'label': 'Crimson Rose',
      'start': '0xFF881337',
      'end': '0xFFE11D48',
    },
    {
      'label': 'Midnight Dark',
      'start': '0xFF0F172A',
      'end': '0xFF334155',
    },
  ];

  @override
  void initState() {
    super.initState();
    final banner = widget.existingBanner;

    _titleController = TextEditingController(text: banner?.title ?? '');
    _subtitleController = TextEditingController(text: banner?.subtitle ?? '');
    _badgeController = TextEditingController(text: banner?.badge ?? '');
    _actionTextController = TextEditingController(text: banner?.actionText ?? 'Explore Visas');
    _actionUrlController = TextEditingController(
      text: (banner?.actionUrl?.isNotEmpty ?? false) ? banner!.actionUrl : '/visas',
    );
    _imageUrlController = TextEditingController(text: banner?.imageUrl ?? '');
    _gradientStartController = TextEditingController(text: banner?.gradientStart ?? '0xFF1B3A5C');
    _gradientEndController = TextEditingController(text: banner?.gradientEnd ?? '0xFF2A5A8C');
    _displayOrderController = TextEditingController(text: (banner?.displayOrder ?? 1).toString());

    _selectedPlacement = banner?.placement ?? 'all';
    _categoryName = banner?.categoryName ?? 'All Pages';
    _isActive = banner?.isActive ?? true;

    // Immediately initialize available visas with comprehensive catalog presets
    _availableVisas = [];
    _isLoadingVisas = true;

    final initialUrl = _actionUrlController.text.trim();
    if (initialUrl.startsWith('/visa-detail/')) {
      _destinationType = 'visa';
      _selectedVisaId = initialUrl.replaceFirst('/visa-detail/', '');
    } else if (initialUrl.startsWith('http://') || initialUrl.startsWith('https://')) {
      _destinationType = 'custom';
    } else {
      _destinationType = 'category';
    }

    // Listeners to refresh live mobile preview
    _titleController.addListener(_onPreviewChanged);
    _subtitleController.addListener(_onPreviewChanged);
    _badgeController.addListener(_onPreviewChanged);
    _actionTextController.addListener(_onPreviewChanged);
    _imageUrlController.addListener(_onPreviewChanged);
    _gradientStartController.addListener(_onPreviewChanged);
    _gradientEndController.addListener(_onPreviewChanged);

    _loadAvailableVisas();
  }

  Future<void> _loadAvailableVisas() async {
    try {
      final dbVisas = await AdminVisaService.instance.getVisas();
      final cleanVisas = dbVisas.where((v) => v.title.trim().isNotEmpty).toList();
      cleanVisas.sort((a, b) {
        final c = a.countryName.compareTo(b.countryName);
        if (c != 0) return c;
        return a.title.compareTo(b.title);
      });
      if (mounted) {
        setState(() {
          _availableVisas = cleanVisas;
          _isLoadingVisas = false;
          if (_destinationType == 'visa' && _selectedVisaId != null) {
            final match = _availableVisas.where(
              (v) => v.id.toLowerCase() == _selectedVisaId!.toLowerCase(),
            );
            if (match.isNotEmpty) {
              _selectedVisaId = match.first.id;
            } else {
              _selectedVisaId = null;
            }
          }
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoadingVisas = false;
        });
      }
    }
  }

  Future<void> _pickAndUploadImage() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: true,
      );

      if (result == null || result.files.isEmpty) return;
      final file = result.files.first;
      final bytes = file.bytes;
      if (bytes == null) return;

      setState(() => _isUploadingImage = true);

      final url = await AdminBannerService.instance.uploadBannerImage(
        bytes,
        file.name,
        'image/${file.extension ?? 'jpeg'}',
      );

      _imageUrlController.text = url;
      if (mounted) {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Banner picture uploaded from your computer successfully!'),
            backgroundColor: AdminColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upload banner picture: $e'),
            backgroundColor: AdminColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploadingImage = false);
    }
  }

  void _onPreviewChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _titleController.dispose();
    _subtitleController.dispose();
    _badgeController.dispose();
    _actionTextController.dispose();
    _actionUrlController.dispose();
    _imageUrlController.dispose();
    _gradientStartController.dispose();
    _gradientEndController.dispose();
    _displayOrderController.dispose();
    super.dispose();
  }

  Color _parseColor(String hex, Color fallback) {
    try {
      final clean = hex.replaceAll('#', '').replaceAll('0x', '').replaceAll('0X', '');
      if (clean.length == 6) {
        return Color(int.parse('0xFF$clean'));
      } else if (clean.length == 8) {
        return Color(int.parse('0x$clean'));
      }
      return fallback;
    } catch (_) {
      return fallback;
    }
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final actionText = _actionTextController.text.trim();
      final effectiveTitle = _titleController.text.trim().isNotEmpty
          ? _titleController.text.trim()
          : (actionText.isNotEmpty
              ? '$_categoryName - $actionText'
              : '$_categoryName Banner');

      final payload = {
        'title': effectiveTitle,
        'subtitle': _subtitleController.text.trim(),
        'badge': _badgeController.text.trim(),
        'action_text': actionText.isNotEmpty ? actionText : 'Explore Visas',
        'action_url': _actionUrlController.text.trim().isNotEmpty
            ? _actionUrlController.text.trim()
            : null,
        'image_url': _imageUrlController.text.trim().isNotEmpty
            ? _imageUrlController.text.trim()
            : null,
        'gradient_start': _gradientStartController.text.trim(),
        'gradient_end': _gradientEndController.text.trim(),
        'display_order': int.tryParse(_displayOrderController.text.trim()) ?? 0,
        'placement': _selectedPlacement,
        'category_name': _categoryName,
        'is_active': _isActive,
      };

      if (widget.existingBanner != null) {
        await AdminBannerService.instance.updateBanner(
          widget.existingBanner!.id,
          payload,
        );
      } else {
        await AdminBannerService.instance.createBanner(payload);
      }

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.existingBanner != null
                  ? 'Banner updated successfully'
                  : 'New promotional banner published',
            ),
            backgroundColor: AdminColors.success,
          ),
        );
      }
    } catch (err) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save banner: $err'),
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
    final isNew = widget.existingBanner == null;
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth >= 960;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Container(
        width: 1060,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.92,
        ),
        child: Column(
          children: [
            // Dialog Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: AdminColors.border)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AdminColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.view_carousel_rounded,
                      color: AdminColors.primary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isNew ? 'Create Advertisement Banner' : 'Edit Advertisement Banner',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AdminColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Configure banner targeting for Visas, Sponsored Jobs, Scholarships, or All Pages',
                          style: TextStyle(
                            fontSize: 12.5,
                            color: AdminColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                    splashRadius: 20,
                  ),
                ],
              ),
            ),

            // Dialog Content
            Expanded(
              child: Form(
                key: _formKey,
                child: isWide
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Left Form Column
                          Expanded(
                            flex: 6,
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.all(24),
                              child: _buildFormFields(),
                            ),
                          ),
                          const VerticalDivider(width: 1, color: AdminColors.border),
                          // Right Live Mobile Preview Column
                          Expanded(
                            flex: 4,
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.all(24),
                              child: _buildLivePreview(),
                            ),
                          ),
                        ],
                      )
                    : SingleChildScrollView(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            _buildLivePreview(),
                            const SizedBox(height: 20),
                            const Divider(color: AdminColors.border),
                            const SizedBox(height: 12),
                            _buildFormFields(),
                          ],
                        ),
                      ),
              ),
            ),

            // Dialog Footer Actions
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AdminColors.border)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Switch(
                        value: _isActive,
                        onChanged: (val) => setState(() => _isActive = val),
                        activeThumbColor: AdminColors.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _isActive ? 'Status: Active (Visible on App)' : 'Status: Inactive (Draft)',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _isActive ? AdminColors.success : AdminColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      OutlinedButton(
                        onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        ),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: _isSaving ? null : _handleSave,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AdminColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(isNew ? 'Publish Banner' : 'Save Changes'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. TARGET PLACEMENT SECTION
        _buildSectionHeader(
          icon: Icons.track_changes_rounded,
          title: 'Target Placement & Category',
          subtitle: 'Choose which screen this advertisement banner appears on in the mobile app',
        ),
        const SizedBox(height: 14),

        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: DropdownButtonFormField<String>(
                initialValue: _selectedPlacement,
                decoration: const InputDecoration(
                  labelText: 'Target Page / Category *',
                  prefixIcon: Icon(Icons.layers_outlined, size: 18),
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
                items: _placementOptions.map((opt) {
                  return DropdownMenuItem<String>(
                    value: opt['value'],
                    child: Text(
                      opt['label']!,
                      style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w500),
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _selectedPlacement = val;
                      final match = _placementOptions.firstWhere((o) => o['value'] == val);
                      _categoryName = match['category']!;
                    });
                  }
                },
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              flex: 2,
              child: TextFormField(
                initialValue: _categoryName,
                key: ValueKey(_categoryName),
                decoration: const InputDecoration(
                  labelText: 'Category Display Label',
                  prefixIcon: Icon(Icons.label_outline, size: 18),
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
                onChanged: (val) => _categoryName = val,
              ),
            ),
          ],
        ),
        const SizedBox(height: 22),

        // 2. CTA BUTTON & DISPLAY ORDER
        _buildSectionHeader(
          icon: Icons.smart_button_rounded,
          title: 'Action Button & Display Order',
          subtitle: 'The action button text displayed below the banner graphic in mobile app, and display order',
        ),
        const SizedBox(height: 14),

        Row(
          children: [
            Expanded(
              flex: 3,
              child: TextFormField(
                controller: _actionTextController,
                decoration: const InputDecoration(
                  labelText: 'CTA Button Text *',
                  hintText: 'e.g., Explore Visas / Apply Now / View Details',
                  prefixIcon: Icon(Icons.smart_button_rounded, size: 18),
                  border: OutlineInputBorder(),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Button text required' : null,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              flex: 1,
              child: TextFormField(
                controller: _displayOrderController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Order',
                  hintText: '1',
                  prefixIcon: Icon(Icons.sort_rounded, size: 18),
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 22),

        // 2B. BUTTON DESTINATION & TARGET NAVIGATION
        _buildSectionHeader(
          icon: Icons.touch_app_rounded,
          title: 'Button Click Action & Destination',
          subtitle: 'Choose where the user is redirected when tapping this banner or its CTA button',
        ),
        const SizedBox(height: 12),

        Material(
          color: const Color(0xFFF8FAFC),
          shape: RoundedRectangleBorder(
            side: const BorderSide(color: AdminColors.border),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                children: [
                  Expanded(
                    child: RadioListTile<String>(
                      title: const Text('Visa Category Page', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      subtitle: const Text('Go to /study, /work, /jobs, etc.', style: TextStyle(fontSize: 11)),
                      value: 'category',
                      groupValue: _destinationType,
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _destinationType = val;
                            if (!_actionUrlController.text.startsWith('/') || _actionUrlController.text.startsWith('/visa-detail/')) {
                              _actionUrlController.text = '/study';
                            }
                          });
                        }
                      },
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<String>(
                      title: const Text('Specific Visa Listing', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      subtitle: const Text('Open exact visa details screen', style: TextStyle(fontSize: 11)),
                      value: 'visa',
                      groupValue: _destinationType,
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _destinationType = val;
                            if (_selectedVisaId != null && _availableVisas.any((v) => v.id == _selectedVisaId)) {
                              _actionUrlController.text = '/visa-detail/$_selectedVisaId';
                              if (_actionTextController.text == 'Apply Now') {
                                _actionTextController.text = 'View Visa Details';
                              }
                            }
                          });
                        }
                      },
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<String>(
                      title: const Text('Custom Link / Web URL', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      subtitle: const Text('Open external website or deep link', style: TextStyle(fontSize: 11)),
                      value: 'custom',
                      groupValue: _destinationType,
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _destinationType = val;
                            if (!_actionUrlController.text.startsWith('http')) {
                              _actionUrlController.text = 'https://';
                            }
                          });
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              if (_destinationType == 'category') ...[
                DropdownButtonFormField<String>(
                  value: _destinationCategoryOptions.any((c) => c['route'] == _actionUrlController.text)
                      ? _actionUrlController.text
                      : '/study',
                  decoration: const InputDecoration(
                    labelText: 'Select Destination Category Page *',
                    prefixIcon: Icon(Icons.explore_rounded, size: 18),
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                  items: _destinationCategoryOptions.map((cat) {
                    return DropdownMenuItem<String>(
                      value: cat['route'],
                      child: Text(cat['label']!, style: const TextStyle(fontSize: 13)),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _actionUrlController.text = val;
                        final match = _destinationCategoryOptions.firstWhere((c) => c['route'] == val);
                        if (_actionTextController.text.isEmpty || _actionTextController.text == 'Apply Now') {
                          _actionTextController.text = match['defaultCta']!;
                        }
                      });
                    }
                  },
                ),
              ] else if (_destinationType == 'visa') ...[
                if (_isLoadingVisas) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Row(
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 12),
                        Text(
                          'Loading live visas from database...',
                          style: TextStyle(fontSize: 13, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ] else if (_availableVisas.isEmpty) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      border: Border.all(color: const Color(0xFFFCD34D)),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info_outline, size: 18, color: Color(0xFFD97706)),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'No live visa listings found in database. Add a visa in "Visa Listings" first.',
                            style: TextStyle(fontSize: 13, color: Color(0xFF92400E)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  DropdownButtonFormField<String>(
                    value: _availableVisas.any((v) => v.id == _selectedVisaId) ? _selectedVisaId : null,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Select Visa Listing to Open *',
                      prefixIcon: Icon(Icons.card_travel_rounded, size: 18),
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                    hint: Text('Choose a live visa listing (${_availableVisas.length} available)'),
                    items: _availableVisas.map((visa) {
                      return DropdownMenuItem<String>(
                        value: visa.id,
                        child: Text(
                          '[${visa.countryName}] ${visa.title} (${visa.categoryName})',
                          style: const TextStyle(fontSize: 13),
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _selectedVisaId = val;
                          _actionUrlController.text = '/visa-detail/$val';
                          if (_actionTextController.text.isEmpty || _actionTextController.text == 'Apply Now') {
                            _actionTextController.text = 'View Visa Details';
                          }
                        });
                      }
                    },
                  ),
                ],
              ] else ...[
                TextFormField(
                  controller: _actionUrlController,
                  decoration: const InputDecoration(
                    labelText: 'External URL or Custom Route *',
                    hintText: 'https://sbconsultants.com/admissions or /custom-page',
                    prefixIcon: Icon(Icons.link_rounded, size: 18),
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
        const SizedBox(height: 22),

        // 2C. BANNER IMAGE / PICTURE SECTION (UPLOAD FROM COMPUTER)
        _buildSectionHeader(
          icon: Icons.image_rounded,
          title: 'Banner Image & Media Asset',
          subtitle: 'Upload a high-quality picture from your computer or supply an image web link',
        ),
        const SizedBox(height: 12),

        Material(
          color: const Color(0xFFF8FAFC),
          shape: RoundedRectangleBorder(
            side: const BorderSide(color: AdminColors.border),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ElevatedButton.icon(
                    onPressed: _isUploadingImage ? null : _pickAndUploadImage,
                    icon: _isUploadingImage
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.upload_file_rounded, size: 18),
                    label: Text(_isUploadingImage ? 'Uploading...' : 'Upload Image from Computer'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AdminColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: TextFormField(
                      controller: _imageUrlController,
                      decoration: InputDecoration(
                        labelText: 'Image Storage URL / Web Link',
                        hintText: 'https://... or uploaded Supabase storage URL',
                        prefixIcon: const Icon(Icons.link_rounded, size: 18),
                        border: const OutlineInputBorder(),
                        suffixIcon: _imageUrlController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded, size: 18),
                                onPressed: () {
                                  setState(() => _imageUrlController.clear());
                                },
                              )
                            : null,
                      ),
                    ),
                  ),
                ],
              ),
              if (_imageUrlController.text.trim().isNotEmpty) ...[
                const SizedBox(height: 14),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Stack(
                    children: [
                      Image.network(
                        _imageUrlController.text.trim(),
                        height: 120,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          height: 80,
                          color: const Color(0xFFFEE2E2),
                          alignment: Alignment.center,
                          child: const Text(
                            'Unable to load image preview. Check link or re-upload.',
                            style: TextStyle(color: Color(0xFF991B1B), fontSize: 12),
                          ),
                        ),
                      ),
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check_circle_rounded, color: Color(0xFF4ADE80), size: 14),
                              SizedBox(width: 4),
                              Text(
                                'Picture Ready',
                                style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
        const SizedBox(height: 22),

        // 3. COLOR GRADIENTS & PRESETS
        _buildSectionHeader(
          icon: Icons.palette_outlined,
          title: 'Banner Color & Gradient Theme',
          subtitle: 'Select from tested aesthetic palettes or input your own hex codes',
        ),
        const SizedBox(height: 14),

        // Gradient preset pills
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _gradientPresets.map((preset) {
            final start = _parseColor(preset['start']!, const Color(0xFF1B3A5C));
            final end = _parseColor(preset['end']!, const Color(0xFF2A5A8C));
            final isSelected = _gradientStartController.text == preset['start'] &&
                _gradientEndController.text == preset['end'];

            return InkWell(
              onTap: () {
                setState(() {
                  _gradientStartController.text = preset['start']!;
                  _gradientEndController.text = preset['end']!;
                });
              },
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected ? AdminColors.primary : AdminColors.border,
                    width: isSelected ? 2 : 1,
                  ),
                  color: isSelected ? AdminColors.primary.withValues(alpha: 0.05) : Colors.white,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        gradient: LinearGradient(
                          colors: [start, end],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      preset['label']!,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected ? AdminColors.primary : AdminColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 14),

        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _gradientStartController,
                decoration: const InputDecoration(
                  labelText: 'Gradient Start Hex',
                  hintText: '0xFF1B3A5C',
                  prefixIcon: Icon(Icons.colorize_rounded, size: 18),
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: TextFormField(
                controller: _gradientEndController,
                decoration: const InputDecoration(
                  labelText: 'Gradient End Hex',
                  hintText: '0xFF2A5A8C',
                  prefixIcon: Icon(Icons.colorize_rounded, size: 18),
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLivePreview() {
    final startColor = _parseColor(_gradientStartController.text, const Color(0xFF1B3A5C));
    final actionText = _actionTextController.text.trim().isNotEmpty
        ? _actionTextController.text.trim()
        : 'Explore Visas';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'LIVE MOBILE PREVIEW',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.8,
                color: AdminColors.textSecondary,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AdminColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'Target: $_categoryName',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AdminColors.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Mobile Phone Shell mockup
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AdminColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Phone Notch / Top Bar indicator
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text(
                    '9:41',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  Row(
                    children: [
                      Icon(Icons.wifi, size: 12, color: Color(0xFF64748B)),
                      SizedBox(width: 4),
                      Icon(Icons.battery_full_rounded, size: 13, color: Color(0xFF64748B)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // The Banner Card Exactly as rendered on mobile: Image on top, Action Button below
              Container(
                width: double.infinity,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 1. Crystal Clear Banner Image - Full clarity, NO text overlay
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                      child: Container(
                        height: 165,
                        width: double.infinity,
                        color: startColor.withValues(alpha: 0.1),
                        child: _imageUrlController.text.trim().isNotEmpty
                            ? Image.network(
                                _imageUrlController.text.trim(),
                                fit: BoxFit.cover,
                                filterQuality: FilterQuality.high,
                                errorBuilder: (_, __, ___) => Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: const [
                                      Icon(Icons.broken_image_rounded, size: 36, color: Color(0xFF94A3B8)),
                                      SizedBox(height: 6),
                                      Text(
                                        'Image preview failed to load',
                                        style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            : Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.add_photo_alternate_rounded, size: 40, color: startColor),
                                    const SizedBox(height: 6),
                                    Text(
                                      'Upload or paste picture URL above\n(Image displays with 100% clarity, no text)',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(fontSize: 11, color: startColor, fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                              ),
                      ),
                    ),

                    // 2. Navigation Button Row Below Image - Navigates user to designated destination
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: const BoxDecoration(
                        color: Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.vertical(bottom: Radius.circular(15)),
                      ),
                      child: SizedBox(
                        height: 38,
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF002444),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.flight_takeoff_rounded,
                                size: 16,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                actionText.isNotEmpty ? actionText : 'Explore Visas',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Icon(
                                Icons.arrow_forward_rounded,
                                size: 14,
                                color: Colors.white,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),
              // Placement & Button Routing Notice
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.info_outline, size: 15, color: AdminColors.primary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Target Screen: ${_selectedPlacement == 'all' ? 'All Pages (/home, etc.)' : '/$_selectedPlacement'}',
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: AdminColors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.touch_app_outlined, size: 15, color: AdminColors.success),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Button Click Destination: ${_actionUrlController.text.trim().isNotEmpty ? _actionUrlController.text.trim() : 'None'} ("$actionText")',
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: AdminColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AdminColors.primary),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AdminColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  color: AdminColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
