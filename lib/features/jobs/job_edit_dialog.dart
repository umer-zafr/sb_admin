import 'package:flutter/material.dart';
import '../../core/theme/admin_theme.dart';
import '../../models/job_model.dart';
import '../../services/admin_job_service.dart';

class JobEditDialog extends StatefulWidget {
  const JobEditDialog({super.key, this.existingJob});

  final SponsoredJobItem? existingJob;

  static Future<bool?> show(BuildContext context, {SponsoredJobItem? existingJob}) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => JobEditDialog(existingJob: existingJob),
    );
  }

  @override
  State<JobEditDialog> createState() => _JobEditDialogState();
}

class _JobEditDialogState extends State<JobEditDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _titleController;
  late final TextEditingController _companyController;
  late final TextEditingController _locationController;
  late final TextEditingController _flagController;
  late final TextEditingController _salaryController;
  late final TextEditingController _typeController;
  late final TextEditingController _descController;
  late final TextEditingController _urlController;

  bool _isFeatured = false;
  bool _isActive = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final j = widget.existingJob;
    _titleController = TextEditingController(text: j?.title ?? '');
    _companyController =
        TextEditingController(text: j?.companyOrInstitution ?? '');
    _locationController = TextEditingController(text: j?.location ?? '');
    _flagController = TextEditingController(text: j?.countryFlag ?? '🇬🇧');
    _salaryController =
        TextEditingController(text: j?.salaryOrFunding ?? '£30,000 - £35,000');
    _typeController =
        TextEditingController(text: j?.employmentType ?? 'Full-Time');
    _descController = TextEditingController(text: j?.description ?? '');
    _urlController = TextEditingController(text: j?.externalUrl ?? '');

    _isFeatured = j?.isFeatured ?? false;
    _isActive = j?.isActive ?? true;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _companyController.dispose();
    _locationController.dispose();
    _flagController.dispose();
    _salaryController.dispose();
    _typeController.dispose();
    _descController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final data = <String, dynamic>{
        'type': 'job',
        'title': _titleController.text.trim(),
        'company_or_institution': _companyController.text.trim(),
        'location': _locationController.text.trim(),
        'country_flag': _flagController.text.trim(),
        'salary_or_funding': _salaryController.text.trim(),
        'employment_type': _typeController.text.trim(),
        'description': _descController.text.trim(),
        'external_url': _urlController.text.trim(),
        'is_featured': _isFeatured,
        'is_active': _isActive,
      };

      if (widget.existingJob != null) {
        await AdminJobService.instance.updateItem(widget.existingJob!.id, data);
      } else {
        await AdminJobService.instance.createItem(data);
      }

      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving job: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingJob != null;

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
                      isEditing ? 'Edit Sponsored Job' : 'Add New Sponsored Job',
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
                        const Text('Job Title *',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _titleController,
                          decoration: const InputDecoration(hintText: 'e.g. Registered Nurse (Band 5)'),
                          validator: (v) => v == null || v.trim().isEmpty ? 'Title required' : null,
                        ),
                        const SizedBox(height: 14),

                        Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Company / Sponsoring Employer *',
                                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 6),
                                  TextFormField(
                                    controller: _companyController,
                                    decoration: const InputDecoration(hintText: 'e.g. St. Jude NHS Trust'),
                                    validator: (v) => v == null || v.trim().isEmpty ? 'Company required' : null,
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
                                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 6),
                                  TextFormField(
                                    controller: _flagController,
                                    decoration: const InputDecoration(hintText: '🇬🇧'),
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
                                  const Text('Location',
                                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 6),
                                  TextFormField(
                                    controller: _locationController,
                                    decoration: const InputDecoration(hintText: 'e.g. Birmingham, UK'),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text('Salary Package *',
                                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                                      InkWell(
                                        onTap: () {
                                          final cur = _salaryController.text.trim();
                                          if (!cur.toLowerCase().contains('annum') && !cur.toLowerCase().contains('/ yr')) {
                                            _salaryController.text = cur.isEmpty ? '£32,000 / yr (Per Annum)' : '$cur / yr (Per Annum)';
                                          }
                                        },
                                        borderRadius: BorderRadius.circular(4),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: AdminColors.primary.withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(4),
                                            border: Border.all(color: AdminColors.primary.withValues(alpha: 0.3)),
                                          ),
                                          child: const Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(Icons.add_circle_outline, size: 12, color: AdminColors.primary),
                                              SizedBox(width: 4),
                                              Text(
                                                'Pay Per Annum (/Yr)',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w700,
                                                  color: AdminColors.primary,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  TextFormField(
                                    controller: _salaryController,
                                    decoration: const InputDecoration(
                                      hintText: 'e.g. £32,000 - £38,000 / yr (Per Annum)',
                                      prefixIcon: Icon(Icons.payments_outlined, size: 18),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Wrap(
                                    spacing: 6,
                                    children: [
                                      ActionChip(
                                        label: const Text('£25k - £35k / yr', style: TextStyle(fontSize: 10.5)),
                                        padding: EdgeInsets.zero,
                                        onPressed: () => _salaryController.text = '£25,000 - £35,000 / yr (Per Annum)',
                                      ),
                                      ActionChip(
                                        label: const Text('£35k - £50k / yr', style: TextStyle(fontSize: 10.5)),
                                        padding: EdgeInsets.zero,
                                        onPressed: () => _salaryController.text = '£35,000 - £50,000 / yr (Per Annum)',
                                      ),
                                      ActionChip(
                                        label: const Text('£50k+ / yr', style: TextStyle(fontSize: 10.5)),
                                        padding: EdgeInsets.zero,
                                        onPressed: () => _salaryController.text = '£50,000+ / yr (Per Annum)',
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        const Text('External Direct Application URL',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _urlController,
                          decoration: const InputDecoration(hintText: 'https://careers.company.com/...'),
                        ),
                        const SizedBox(height: 14),

                        const Text('Job Description & Sponsoring Perks',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _descController,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            hintText: 'Describe relocation allowance, COS sponsorship details, etc.',
                          ),
                        ),
                        const SizedBox(height: 16),

                        Row(
                          children: [
                            Switch(
                              value: _isActive,
                              activeThumbColor: AdminColors.success,
                              onChanged: (val) => setState(() => _isActive = val),
                            ),
                            const SizedBox(width: 8),
                            const Text('Active (Visible in App)'),
                            const SizedBox(width: 24),
                            Switch(
                              value: _isFeatured,
                              activeThumbColor: AdminColors.accentGold,
                              onChanged: (val) => setState(() => _isFeatured = val),
                            ),
                            const SizedBox(width: 8),
                            const Text('Featured Job'),
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
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : Text(isEditing ? 'Save Changes' : 'Publish Job Listing'),
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
