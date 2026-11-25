import 'package:flutter/material.dart';
import '../../core/theme/admin_theme.dart';
import '../../models/job_model.dart';
import '../../services/admin_job_service.dart';

class ScholarshipEditDialog extends StatefulWidget {
  const ScholarshipEditDialog({super.key, this.existingScholarship});

  final SponsoredJobItem? existingScholarship;

  static Future<bool?> show(BuildContext context,
      {SponsoredJobItem? existingScholarship}) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) =>
          ScholarshipEditDialog(existingScholarship: existingScholarship),
    );
  }

  @override
  State<ScholarshipEditDialog> createState() => _ScholarshipEditDialogState();
}

class _ScholarshipEditDialogState extends State<ScholarshipEditDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _titleController;
  late final TextEditingController _institutionController;
  late final TextEditingController _locationController;
  late final TextEditingController _flagController;
  late final TextEditingController _fundingController;
  late final TextEditingController _degreeController;
  late final TextEditingController _descController;
  late final TextEditingController _urlController;

  bool _isFeatured = false;
  bool _isActive = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final s = widget.existingScholarship;
    _titleController = TextEditingController(text: s?.title ?? '');
    _institutionController =
        TextEditingController(text: s?.companyOrInstitution ?? '');
    _locationController = TextEditingController(text: s?.location ?? '');
    _flagController = TextEditingController(text: s?.countryFlag ?? '🇬🇧');
    _fundingController = TextEditingController(
        text: s?.salaryOrFunding ?? '100% Fully Funded');
    _degreeController =
        TextEditingController(text: s?.degreeLevel ?? "Master's Degree");
    _descController = TextEditingController(text: s?.description ?? '');
    _urlController = TextEditingController(text: s?.externalUrl ?? '');

    _isFeatured = s?.isFeatured ?? false;
    _isActive = s?.isActive ?? true;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _institutionController.dispose();
    _locationController.dispose();
    _flagController.dispose();
    _fundingController.dispose();
    _degreeController.dispose();
    _descController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final data = <String, dynamic>{
        'type': 'scholarship',
        'title': _titleController.text.trim(),
        'company_or_institution': _institutionController.text.trim(),
        'location': _locationController.text.trim(),
        'country_flag': _flagController.text.trim(),
        'salary_or_funding': _fundingController.text.trim(),
        'degree_level': _degreeController.text.trim(),
        'description': _descController.text.trim(),
        'external_url': _urlController.text.trim(),
        'is_featured': _isFeatured,
        'is_active': _isActive,
      };

      if (widget.existingScholarship != null) {
        await AdminJobService.instance
            .updateItem(widget.existingScholarship!.id, data);
      } else {
        await AdminJobService.instance.createItem(data);
      }

      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving scholarship: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingScholarship != null;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: Colors.white,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 640,
          maxHeight: MediaQuery.of(context).size.height * 0.92,
        ),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isEditing ? 'Edit Scholarship' : 'Add New Scholarship',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AdminColors.textPrimary,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(false),
                    ),
                  ],
                ),
                const Divider(),
                const SizedBox(height: 12),

                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Scholarship Title *',
                            style: TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _titleController,
                          decoration: const InputDecoration(
                              hintText: 'e.g. Chevening UK Government Fellowship'),
                          validator: (v) => v == null || v.trim().isEmpty
                              ? 'Title required'
                              : null,
                        ),
                        const SizedBox(height: 14),

                        Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Awarding Body / University *',
                                      style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 6),
                                  TextFormField(
                                    controller: _institutionController,
                                    decoration: const InputDecoration(
                                        hintText: 'e.g. UK Foreign Office & Partner Universities'),
                                    validator: (v) =>
                                        v == null || v.trim().isEmpty
                                            ? 'Institution required'
                                            : null,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Country Flag',
                                      style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 6),
                                  TextFormField(
                                    controller: _flagController,
                                    decoration:
                                        const InputDecoration(hintText: '🇬🇧'),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Target Degree Level',
                                      style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 6),
                                  TextFormField(
                                    controller: _degreeController,
                                    decoration: const InputDecoration(
                                        hintText: "e.g. Master's / PhD"),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Coverage / Funding Amount',
                                      style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 6),
                                  TextFormField(
                                    controller: _fundingController,
                                    decoration: const InputDecoration(
                                        hintText: 'e.g. Full Tuition + £1,400/Mo'),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        const Text('Official Application / Information Portal URL',
                            style: TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _urlController,
                          decoration: const InputDecoration(
                              hintText: 'https://chevening.org/apply'),
                        ),
                        const SizedBox(height: 14),

                        const Text('Scholarship Description & Eligibility',
                            style: TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _descController,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            hintText:
                                'Explain GPA prerequisites, IELTS scores, and eligible universities...',
                          ),
                        ),
                        const SizedBox(height: 16),

                        Row(
                          children: [
                            Switch(
                              value: _isActive,
                              activeThumbColor: AdminColors.success,
                              onChanged: (val) =>
                                  setState(() => _isActive = val),
                            ),
                            const SizedBox(width: 8),
                            const Text('Active (Visible in App)'),
                            const SizedBox(width: 24),
                            Switch(
                              value: _isFeatured,
                              activeThumbColor: AdminColors.accentGold,
                              onChanged: (val) =>
                                  setState(() => _isFeatured = val),
                            ),
                            const SizedBox(width: 8),
                            const Text('Featured Scholarship'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 12),

                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: _isSaving ? null : _handleSave,
                      child: _isSaving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : Text(isEditing
                              ? 'Save Changes'
                              : 'Publish Scholarship'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
