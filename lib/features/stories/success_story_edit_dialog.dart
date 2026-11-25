import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../../core/theme/admin_theme.dart';
import '../../models/admin_success_story_model.dart';
import '../../services/admin_success_story_service.dart';

class SuccessStoryEditDialog extends ConsumerStatefulWidget {
  const SuccessStoryEditDialog({super.key, this.existingStory});

  final AdminSuccessStoryItem? existingStory;

  static Future<bool?> show(BuildContext context, {AdminSuccessStoryItem? story}) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => SuccessStoryEditDialog(existingStory: story),
    );
  }

  @override
  ConsumerState<SuccessStoryEditDialog> createState() => _SuccessStoryEditDialogState();
}

class _SuccessStoryEditDialogState extends ConsumerState<SuccessStoryEditDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _avatarUrlController;
  late final TextEditingController _visaTypeController;
  late final TextEditingController _countryNameController;
  late final TextEditingController _countryFlagController;
  late final TextEditingController _processingTimeController;
  late final TextEditingController _universityOrEmployerController;
  late final TextEditingController _approvedDateController;
  late final TextEditingController _badgeTextController;
  late final TextEditingController _quoteController;
  late final TextEditingController _ratingController;
  late final TextEditingController _displayOrderController;

  bool _isPublished = true;
  bool _isSaving = false;
  bool _isUploadingAvatar = false;

  Future<void> _pickAndUploadAvatar() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;
      final file = result.files.first;
      final bytes = file.bytes;
      if (bytes == null) return;

      setState(() => _isUploadingAvatar = true);

      final url = await AdminSuccessStoryService.instance.uploadStoryAvatar(
        bytes,
        file.name,
        'image/${file.extension ?? 'jpeg'}',
      );

      _avatarUrlController.text = url;
      if (mounted) {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Client photo uploaded from computer successfully!'),
            backgroundColor: AdminColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upload picture: $e'),
            backgroundColor: AdminColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploadingAvatar = false);
    }
  }

  @override
  void initState() {
    super.initState();
    final story = widget.existingStory;
    _nameController = TextEditingController(text: story?.clientName ?? '');
    _avatarUrlController = TextEditingController(text: story?.avatarUrl ?? '');
    _visaTypeController = TextEditingController(text: story?.visaType ?? '');
    _countryNameController = TextEditingController(text: story?.countryName ?? '');
    _countryFlagController = TextEditingController(text: story?.countryFlag ?? '🌍');
    _processingTimeController = TextEditingController(text: story?.processingTime ?? '');
    _universityOrEmployerController = TextEditingController(text: story?.universityOrEmployer ?? '');
    _approvedDateController = TextEditingController(text: story?.approvedDate ?? '');
    _badgeTextController = TextEditingController(text: story?.badgeText ?? 'Visa Granted');
    _quoteController = TextEditingController(text: story?.quote ?? '');
    _ratingController = TextEditingController(text: (story?.rating ?? 5.0).toString());
    _displayOrderController = TextEditingController(text: (story?.displayOrder ?? 0).toString());
    _isPublished = story?.isPublished ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _avatarUrlController.dispose();
    _visaTypeController.dispose();
    _countryNameController.dispose();
    _countryFlagController.dispose();
    _processingTimeController.dispose();
    _universityOrEmployerController.dispose();
    _approvedDateController.dispose();
    _badgeTextController.dispose();
    _quoteController.dispose();
    _ratingController.dispose();
    _displayOrderController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final payload = <String, dynamic>{
        'client_name': _nameController.text.trim(),
        'avatar_url': _avatarUrlController.text.trim().isNotEmpty ? _avatarUrlController.text.trim() : null,
        'visa_type': _visaTypeController.text.trim(),
        'country_name': _countryNameController.text.trim(),
        'country_flag': _countryFlagController.text.trim().isNotEmpty ? _countryFlagController.text.trim() : '🌍',
        'processing_time': _processingTimeController.text.trim(),
        'rating': double.tryParse(_ratingController.text.trim()) ?? 5.0,
        'quote': _quoteController.text.trim(),
        'university_or_employer': _universityOrEmployerController.text.trim(),
        'approved_date': _approvedDateController.text.trim(),
        'badge_text': _badgeTextController.text.trim().isNotEmpty
            ? _badgeTextController.text.trim()
            : 'Verified Approval',
        'display_order': int.tryParse(_displayOrderController.text.trim()) ?? 0,
        'is_published': _isPublished,
      };

      if (widget.existingStory == null) {
        await AdminSuccessStoryService.instance.createStory(payload);
      } else {
        await AdminSuccessStoryService.instance.updateStory(widget.existingStory!.id, payload);
      }

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save success story: $e'),
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
    final isNew = widget.existingStory == null;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 820,
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
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AdminColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.stars_rounded, color: AdminColors.primary, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isNew ? 'Add Client Success Story' : 'Edit Success Story',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Featured testimonial rendered on the mobile app home screen',
                          style: TextStyle(fontSize: 12.5, color: AdminColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Form Body
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Status Switch Card
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: _isPublished
                              ? AdminColors.success.withValues(alpha: 0.08)
                              : AdminColors.textMuted.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: _isPublished
                                ? AdminColors.success.withValues(alpha: 0.3)
                                : AdminColors.border,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _isPublished ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                              color: _isPublished ? AdminColors.success : AdminColors.textSecondary,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _isPublished
                                        ? 'Published on Mobile App Home Screen'
                                        : 'Hidden (Draft Mode)',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13.5,
                                      color: _isPublished ? AdminColors.success : AdminColors.textPrimary,
                                    ),
                                  ),
                                  const Text(
                                    'When enabled, this approval card immediately shows in the mobile app carousel.',
                                    style: TextStyle(fontSize: 12, color: AdminColors.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                            Switch(
                              value: _isPublished,
                              activeThumbColor: AdminColors.success,
                              onChanged: (val) => setState(() => _isPublished = val),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Section 1: Client & Visa Details
                      const Text(
                        'Client & Approval Information',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              controller: _nameController,
                              decoration: const InputDecoration(
                                labelText: 'Client Full Name *',
                                prefixIcon: Icon(Icons.person_rounded, size: 18),
                              ),
                              validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              controller: _visaTypeController,
                              decoration: const InputDecoration(
                                labelText: 'Visa Category / Type *',
                                prefixIcon: Icon(Icons.badge_rounded, size: 18),
                                hintText: 'e.g. Study Visa / Work Permit',
                              ),
                              validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              controller: _countryNameController,
                              decoration: const InputDecoration(
                                labelText: 'Destination Country *',
                                prefixIcon: Icon(Icons.public_rounded, size: 18),
                              ),
                              validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _countryFlagController,
                              decoration: const InputDecoration(
                                labelText: 'Flag Emoji',
                                hintText: '🇬🇧, 🇨🇦, 🇦🇺, 🇦🇪',
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              controller: _processingTimeController,
                              decoration: const InputDecoration(
                                labelText: 'Processing Time',
                                prefixIcon: Icon(Icons.timer_rounded, size: 18),
                                hintText: 'e.g. 18 Working Days',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              controller: _universityOrEmployerController,
                              decoration: const InputDecoration(
                                labelText: 'University or Employer',
                                prefixIcon: Icon(Icons.domain_rounded, size: 18),
                                hintText: 'e.g. University of Manchester',
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _approvedDateController,
                              decoration: const InputDecoration(
                                labelText: 'Decision Date',
                                prefixIcon: Icon(Icons.calendar_today_rounded, size: 18),
                                hintText: 'e.g. August 2026',
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _ratingController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(
                                labelText: 'Rating (Stars)',
                                prefixIcon: Icon(Icons.star_rounded, size: 18, color: Colors.amber),
                                hintText: '5.0',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Client Photo / Avatar Picker Section
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AdminColors.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Client Profile Picture / Photo *',
                              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AdminColors.textPrimary),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                // Circular Avatar Preview
                                CircleAvatar(
                                  radius: 26,
                                  backgroundColor: AdminColors.primary.withValues(alpha: 0.1),
                                  backgroundImage: _avatarUrlController.text.trim().isNotEmpty
                                      ? NetworkImage(_avatarUrlController.text.trim())
                                      : null,
                                  child: _avatarUrlController.text.trim().isEmpty
                                      ? const Icon(Icons.person_rounded, size: 28, color: AdminColors.primary)
                                      : null,
                                ),
                                const SizedBox(width: 14),
                                ElevatedButton.icon(
                                  onPressed: _isUploadingAvatar ? null : _pickAndUploadAvatar,
                                  icon: _isUploadingAvatar
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                        )
                                      : const Icon(Icons.upload_file_rounded, size: 18),
                                  label: Text(_isUploadingAvatar ? 'Uploading...' : 'Choose Photo from Computer'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AdminColors.primary,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextFormField(
                                    controller: _avatarUrlController,
                                    decoration: InputDecoration(
                                      labelText: 'Photo URL / Storage Link',
                                      hintText: 'Auto-filled on upload or paste link',
                                      prefixIcon: const Icon(Icons.link_rounded, size: 16),
                                      border: const OutlineInputBorder(),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                      suffixIcon: _avatarUrlController.text.isNotEmpty
                                          ? IconButton(
                                              icon: const Icon(Icons.clear, size: 16),
                                              onPressed: () => setState(() => _avatarUrlController.clear()),
                                            )
                                          : null,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              controller: _badgeTextController,
                              decoration: const InputDecoration(
                                labelText: 'Badge Label',
                                prefixIcon: Icon(Icons.verified_rounded, size: 18, color: AdminColors.success),
                                hintText: 'Verified Approval',
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _displayOrderController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Order #',
                                hintText: '0, 1, 2...',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Section 2: Testimonial Quote
                      const Text(
                        'Client Testimonial & Review Quote',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _quoteController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          hintText: 'Share what the client said about SB Consultants services and approval experience...',
                          alignLabelWithHint: true,
                        ),
                        validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 24),

                      // Section 3: Live Preview Card (What Mobile Users See)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AdminColors.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.smartphone_rounded, size: 18, color: AdminColors.primary),
                                SizedBox(width: 8),
                                Text(
                                  'Live Mobile App Preview (As Seen by Clients)',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                    color: AdminColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            ValueListenableBuilder(
                              valueListenable: _nameController,
                              builder: (context, _, __) {
                                return Container(
                                  width: 320,
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.06),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          CircleAvatar(
                                            radius: 20,
                                            backgroundColor: AdminColors.primary.withValues(alpha: 0.1),
                                            backgroundImage: _avatarUrlController.text.trim().isNotEmpty
                                                ? NetworkImage(_avatarUrlController.text.trim())
                                                : null,
                                            child: _avatarUrlController.text.trim().isEmpty
                                                ? Text(
                                                    _nameController.text.isNotEmpty
                                                        ? _nameController.text[0].toUpperCase()
                                                        : 'C',
                                                  )
                                                : null,
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  _nameController.text.isNotEmpty
                                                      ? _nameController.text
                                                      : 'Client Name',
                                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                Text(
                                                  '${_countryFlagController.text} ${_countryNameController.text}',
                                                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: Colors.green.withValues(alpha: 0.1),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              _badgeTextController.text.isNotEmpty
                                                  ? _badgeTextController.text
                                                  : 'Verified',
                                              style: const TextStyle(
                                                fontSize: 9.5,
                                                color: Colors.green,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        '"${_quoteController.text}"',
                                        style: const TextStyle(
                                          fontSize: 11.5,
                                          fontStyle: FontStyle.italic,
                                          color: Color(0xFF334155),
                                        ),
                                        maxLines: 3,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          const Icon(Icons.star_rounded, size: 14, color: Colors.amber),
                                          const SizedBox(width: 3),
                                          Text(
                                            _ratingController.text,
                                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                          ),
                                          const Spacer(),
                                          Text(
                                            _processingTimeController.text,
                                            style: const TextStyle(fontSize: 10.5, color: Colors.grey),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
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
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _isSaving ? null : _handleSave,
                    icon: _isSaving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.check_rounded, size: 18),
                    label: Text(
                      _isSaving
                          ? 'Saving...'
                          : (isNew ? 'Publish Success Story' : 'Save Changes'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
