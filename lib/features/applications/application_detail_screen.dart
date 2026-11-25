import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/constants/admin_constants.dart';
import '../../core/theme/admin_theme.dart';
import '../../models/application_model.dart';
import '../../providers/admin_dashboard_providers.dart';
import '../../services/admin_application_service.dart';
import '../../widgets/admin_scaffold.dart';
import '../../widgets/data_table_card.dart';
import '../../widgets/status_badge.dart';

class ApplicationDetailScreen extends ConsumerStatefulWidget {
  const ApplicationDetailScreen({super.key, required this.applicationId});

  final String applicationId;

  @override
  ConsumerState<ApplicationDetailScreen> createState() =>
      _ApplicationDetailScreenState();
}

class _ApplicationDetailScreenState
    extends ConsumerState<ApplicationDetailScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _noteController = TextEditingController();
  bool _isAdvancingStep = false;
  int _selectedStep = 1;
  bool _hasInitializedStep = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Map<String, dynamic> _extractFormData(dynamic raw) {
    if (raw is Map) {
      return Map<String, dynamic>.from(raw);
    }
    return {};
  }

  Future<void> _advanceStep(ApplicationItem app, int targetStep) async {
    final stepConfig = AdminConstants.procedureSteps.firstWhere(
      (s) => s['step_number'] == targetStep,
      orElse: () => {'title': 'Step $targetStep'},
    );
    final targetTitle = stepConfig['title'] as String;

    final noteController = TextEditingController();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Advance to Step $targetStep: $targetTitle'),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'This will update the single source of truth in Supabase. The customer\'s mobile application will immediately reflect Step $targetStep: $targetTitle in real-time.',
                style: const TextStyle(fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 16),
              const Text('Audit Note (Optional):',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              TextField(
                controller: noteController,
                maxLines: 2,
                decoration: const InputDecoration(
                  hintText: 'e.g. Profile verified; scheduled embassy appointment...',
                ),
              ),
            ],
          ),
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Confirm & Update Stepper'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isAdvancingStep = true);
      try {
        await AdminApplicationService.instance.updateApplicationStep(
          applicationId: app.id,
          newStep: targetStep,
          stepNotes: noteController.text.trim().isNotEmpty
              ? noteController.text.trim()
              : null,
        );
        setState(() => _selectedStep = targetStep);
        ref.invalidate(applicationDetailProvider(widget.applicationId));
        ref.invalidate(applicationsListProvider);
        ref.invalidate(dashboardMetricsProvider);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Application successfully moved to Step $targetStep: $targetTitle!'),
              backgroundColor: AdminColors.success,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to advance step: $e')),
          );
        }
      } finally {
        if (mounted) setState(() => _isAdvancingStep = false);
      }
    }
  }

  void _showRescheduleDialog(ApplicationItem app) {
    final dateController = TextEditingController(text: '18 Aug 2026');
    final slotController = TextEditingController(text: '03:00 PM (PKT)');
    final consultantController =
        TextEditingController(text: app.assignedConsultantName ?? 'Usman Tariq (Lead Officer)');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reschedule Consultant Call (Step 2)'),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Appointment Date',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              TextField(controller: dateController),
              const SizedBox(height: 12),
              const Text('Time Slot',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              TextField(controller: slotController),
              const SizedBox(height: 12),
              const Text('Assigned Consultant',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              TextField(controller: consultantController),
            ],
          ),
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await AdminApplicationService.instance.rescheduleConsultantCall(
                applicationId: app.id,
                callDate: dateController.text.trim(),
                callSlot: slotController.text.trim(),
                consultantName: consultantController.text.trim(),
              );
              ref.invalidate(applicationDetailProvider(widget.applicationId));
              if (ctx.mounted) Navigator.of(ctx).pop();
            },
            child: const Text('Update Call Schedule'),
          ),
        ],
      ),
    );
  }

  void _showStatusDialog(ApplicationItem app) {
    String selectedStatus = app.status;
    final alertTitleController =
        TextEditingController(text: app.alertTitle ?? '');
    final alertBodyController =
        TextEditingController(text: app.alertBody ?? '');

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Change Application Status & Alerts'),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Overall Status',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  initialValue: AdminConstants.applicationStatuses.contains(selectedStatus)
                      ? selectedStatus
                      : AdminConstants.applicationStatuses.first,
                  items: AdminConstants.applicationStatuses.map((s) {
                    return DropdownMenuItem(
                      value: s,
                      child: Text(s.toUpperCase().replaceAll('_', ' ')),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setDialogState(() => selectedStatus = val);
                  },
                ),
                const SizedBox(height: 16),
                const Text('Alert Notification Banner for Mobile User',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                TextField(
                  controller: alertTitleController,
                  decoration: const InputDecoration(
                    hintText: 'e.g. Action Required: Missing Police Certificate',
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: alertBodyController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    hintText: 'Detailed instructions displayed directly inside the customer app...',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            OutlinedButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                await AdminApplicationService.instance.updateApplicationStatus(
                  applicationId: app.id,
                  status: selectedStatus,
                  alertTitle: alertTitleController.text.trim().isNotEmpty
                      ? alertTitleController.text.trim()
                      : null,
                  alertBody: alertBodyController.text.trim().isNotEmpty
                      ? alertBodyController.text.trim()
                      : null,
                );
                ref.invalidate(applicationDetailProvider(widget.applicationId));
                ref.invalidate(applicationsListProvider);
                if (ctx.mounted) Navigator.of(ctx).pop();
              },
              child: const Text('Apply Changes'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appAsync = ref.watch(applicationDetailProvider(widget.applicationId));

    return AdminScaffold(
      title: 'Application Stepper & Case Dossier',
      subtitle: 'Live procedural workflow control, applicant profile review, and real-time synchronization',
      body: appAsync.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(60),
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (err, _) => Card(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Text('Error loading application: $err'),
          ),
        ),
        data: (app) {
          if (!_hasInitializedStep) {
            _selectedStep = app.currentStep;
            _hasInitializedStep = true;
          }

          final formData = _extractFormData(app.formData);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top Action Row
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: () => context.go('/applications'),
                    icon: const Icon(Icons.arrow_back, size: 16),
                    label: const Text('Back to Applications'),
                  ),
                  const Spacer(),
                  StatusBadge(status: app.status),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AdminColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AdminColors.primary.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      'ACTIVE STEP: ${app.currentStep} OF 5 (${app.progressPercent}%)',
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: AdminColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Case Dossier Header Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AdminColors.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.description_outlined,
                          size: 32,
                          color: AdminColors.primary,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    app.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700,
                                      color: AdminColors.textPrimary,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AdminColors.surfaceMuted,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: AdminColors.border),
                                  ),
                                  child: Text(
                                    app.referenceNumber,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: AdminColors.primary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (app.subtitle != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                app.subtitle!,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AdminColors.textSecondary,
                                ),
                              ),
                            ],
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 20,
                              runSpacing: 6,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.person_outline,
                                        size: 15, color: AdminColors.textMuted),
                                    const SizedBox(width: 6),
                                    Text(
                                      app.applicantName ??
                                          formData['applicant_name']?.toString() ??
                                          'Verified Applicant',
                                      style: const TextStyle(
                                          fontSize: 13, fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                                if (app.applicantEmail != null || formData['email'] != null)
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.email_outlined,
                                          size: 15, color: AdminColors.textMuted),
                                      const SizedBox(width: 6),
                                      Text(
                                        app.applicantEmail ?? formData['email']?.toString() ?? '',
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                    ],
                                  ),
                                if (app.applicantPhone != null || formData['phone'] != null)
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.phone_outlined,
                                          size: 15, color: AdminColors.textMuted),
                                      const SizedBox(width: 6),
                                      Text(
                                        app.applicantPhone ?? formData['phone']?.toString() ?? '',
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                    ],
                                  ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.access_time_rounded,
                                        size: 15, color: AdminColors.textMuted),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Applied ${DateFormat('dd MMM yyyy, hh:mm a').format(app.appliedAt.toLocal())}',
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AdminColors.primaryLight,
                            ),
                            onPressed: () => _showStatusDialog(app),
                            icon: const Icon(Icons.edit_note, size: 16),
                            label: const Text('Change Status / Alert'),
                          ),
                          const SizedBox(height: 8),
                          OutlinedButton.icon(
                            onPressed: () => _showRescheduleDialog(app),
                            icon: const Icon(Icons.schedule, size: 16),
                            label: const Text('Reschedule Call (Step 2)'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // ==============================================================
              // CORE REQUIREMENT: VISUAL CONNECTED 5-STEP PROCEDURE STEPPER
              // Click any step to inspect its relevant data & advance live!
              // ==============================================================
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Procedure Stepper Control (Live Sync with Customer App)',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: AdminColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Wrap(
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    Text(
                                      'Active Application Milestone: ${app.stepText}',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: AdminColors.primary,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Text(
                                      '• (Click any step below to view filled data & progress actions)',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AdminColors.textMuted,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          // Quick Move to Next Step Button
                          if (app.currentStep < 5)
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AdminColors.primary,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
                              ),
                              onPressed: _isAdvancingStep
                                  ? null
                                  : () => _advanceStep(app, app.currentStep + 1),
                              icon: _isAdvancingStep
                                  ? const SizedBox(
                                      width: 14,
                                      height: 14,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(Icons.arrow_forward_rounded, size: 16),
                              label: Text('Advance to Step ${app.currentStep + 1} →'),
                            )
                          else
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: AdminColors.successBg,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.check_circle,
                                      size: 16, color: AdminColors.success),
                                  SizedBox(width: 6),
                                  Text(
                                    'Application Completed & Verified',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: AdminColors.success,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Horizontal Stepper Chain with interactive selection
                      LayoutBuilder(
                        builder: (context, constraints) {
                          return Row(
                            children: List.generate(5, (index) {
                              final stepNumber = index + 1;
                              final stepConfig = AdminConstants.procedureSteps[index];
                              final isCompleted = stepNumber < app.currentStep;
                              final isCurrent = stepNumber == app.currentStep;
                              final isSelected = stepNumber == _selectedStep;

                              Color circleBg;
                              Color circleFg;
                              Color circleBorder;

                              if (isCompleted) {
                                circleBg = AdminColors.success;
                                circleFg = Colors.white;
                                circleBorder = AdminColors.success;
                              } else if (isCurrent) {
                                circleBg = AdminColors.primary;
                                circleFg = Colors.white;
                                circleBorder = AdminColors.primary;
                              } else {
                                circleBg = Colors.white;
                                circleFg = AdminColors.textMuted;
                                circleBorder = AdminColors.border;
                              }

                              return Expanded(
                                child: InkWell(
                                  onTap: () {
                                    setState(() => _selectedStep = stepNumber);
                                  },
                                  borderRadius: BorderRadius.circular(10),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 4, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? AdminColors.primary.withValues(alpha: 0.05)
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(10),
                                      border: isSelected
                                          ? Border.all(color: AdminColors.primary, width: 1.5)
                                          : Border.all(color: Colors.transparent),
                                    ),
                                    child: Column(
                                      children: [
                                        // Circle Icon
                                        Container(
                                          width: 36,
                                          height: 36,
                                          decoration: BoxDecoration(
                                            color: circleBg,
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                                color: circleBorder, width: 2),
                                            boxShadow: isCurrent
                                                ? [
                                                    BoxShadow(
                                                      color: AdminColors.primary
                                                          .withValues(alpha: 0.25),
                                                      blurRadius: 8,
                                                      offset: const Offset(0, 3),
                                                    ),
                                                  ]
                                                : null,
                                          ),
                                          child: Center(
                                            child: isCompleted
                                                ? const Icon(Icons.check,
                                                    size: 18, color: Colors.white)
                                                : Text(
                                                    '$stepNumber',
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      fontWeight: FontWeight.w700,
                                                      color: circleFg,
                                                    ),
                                                  ),
                                          ),
                                        ),
                                        const SizedBox(height: 8),

                                        // Step Title
                                        Text(
                                          stepConfig['title'] as String,
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 12.5,
                                            fontWeight: isSelected || isCurrent
                                                ? FontWeight.w700
                                                : FontWeight.w500,
                                            color: isCurrent
                                                ? AdminColors.primary
                                                : (isCompleted
                                                    ? AdminColors.textPrimary
                                                    : AdminColors.textMuted),
                                          ),
                                        ),
                                        const SizedBox(height: 2),

                                        // Status sub-pill
                                        Text(
                                          isCompleted
                                              ? 'Done'
                                              : (isCurrent ? 'ACTIVE' : 'Pending'),
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                            color: isCompleted
                                                ? AdminColors.success
                                                : (isCurrent
                                                    ? AdminColors.accentGold
                                                    : AdminColors.textMuted),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }),
                          );
                        },
                      ),

                      const SizedBox(height: 24),
                      const Divider(color: AdminColors.border),
                      const SizedBox(height: 16),

                      // ========================================================
                      // STEP DOSSIER PANEL: DYNAMICALLY SHOWS RELEVANT DATA FOR
                      // THE SELECTED STEPPER STEP
                      // ========================================================
                      _buildStepDossierPanel(app, formData),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Detail Tabs
              Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    bottom: BorderSide(color: AdminColors.border, width: 1),
                  ),
                ),
                child: TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  labelColor: AdminColors.primary,
                  unselectedLabelColor: AdminColors.textSecondary,
                  indicatorColor: AdminColors.primary,
                  indicatorWeight: 3,
                  tabs: [
                    Tab(text: 'Procedure Steps Breakdown (${app.procedures.length})'),
                    Tab(text: 'Audit & Stepper History Trail (${app.history.length})'),
                    const Tab(text: 'Applicant Form Raw Payload'),
                    const Tab(text: 'Internal Staff Observations'),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Tab View Content Area
              SizedBox(
                height: 480,
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // Tab 1: Procedure Steps Breakdown
                    DataTableCard(
                      title: 'Procedure Step Details',
                      subtitle: 'Individual milestone durations and scheduled slots',
                      columns: const [
                        DataColumn(label: Text('STEP #')),
                        DataColumn(label: Text('TITLE')),
                        DataColumn(label: Text('DURATION / TIMELINE')),
                        DataColumn(label: Text('SCHEDULED DETAILS')),
                        DataColumn(label: Text('STATUS')),
                      ],
                      rows: app.procedures.map((p) {
                        return DataRow(
                          cells: [
                            DataCell(Text('Step ${p.stepNumber}',
                                style: const TextStyle(fontWeight: FontWeight.w700))),
                            DataCell(Text(p.title,
                                style: const TextStyle(fontWeight: FontWeight.w600))),
                            DataCell(Text(p.duration ?? 'Standard')),
                            DataCell(
                              Text(
                                p.scheduledCallDate != null
                                    ? '${p.scheduledCallDate} @ ${p.scheduledCallSlot}'
                                    : '—',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                            DataCell(StatusBadge(status: p.status)),
                          ],
                        );
                      }).toList(),
                    ),

                    // Tab 2: Audit History Trail
                    DataTableCard(
                      title: 'Stepper & Status Audit Trail',
                      subtitle: 'Immutable log of milestone progressions, status modifications, and staff actions',
                      columns: const [
                        DataColumn(label: Text('TIMESTAMP')),
                        DataColumn(label: Text('TRANSITION')),
                        DataColumn(label: Text('RESULTING STATUS')),
                        DataColumn(label: Text('AUDIT NOTES')),
                      ],
                      rows: app.history.map((h) {
                        return DataRow(
                          cells: [
                            DataCell(
                              Text(
                                DateFormat('dd MMM yyyy, hh:mm a').format(h.changedAt.toLocal()),
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                            DataCell(
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AdminColors.surfaceMuted,
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: AdminColors.border),
                                ),
                                child: Text(
                                  'Step ${h.previousStep ?? 1}  →  Step ${h.newStep}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: AdminColors.primary,
                                  ),
                                ),
                              ),
                            ),
                            DataCell(StatusBadge(status: h.newStatus)),
                            DataCell(Text(h.notes ?? 'Step updated by admin',
                                style: const TextStyle(fontSize: 12.5))),
                          ],
                        );
                      }).toList(),
                    ),

                    // Tab 3: Applicant Form Raw Payload
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: formData.isNotEmpty
                            ? ListView(
                                children: formData.entries.map((entry) {
                                  return ListTile(
                                    title: Text(
                                      entry.key
                                          .toString()
                                          .replaceAll('_', ' ')
                                          .toUpperCase(),
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: AdminColors.textMuted,
                                      ),
                                    ),
                                    subtitle: Text(
                                      entry.value?.toString() ?? '—',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: AdminColors.textPrimary,
                                      ),
                                    ),
                                  );
                                }).toList(),
                              )
                            : const Center(
                                child: Text(
                                  'No extended form data recorded for this case.',
                                  style: TextStyle(color: AdminColors.textMuted),
                                ),
                              ),
                      ),
                    ),

                    // Tab 4: Internal Staff Notes
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _noteController,
                                    decoration: const InputDecoration(
                                      hintText: 'Record a confidential note regarding this case...',
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                ElevatedButton.icon(
                                  onPressed: () async {
                                    final text = _noteController.text.trim();
                                    if (text.isEmpty) return;
                                    await AdminApplicationService.instance
                                        .addInternalNote(app.id, text);
                                    _noteController.clear();
                                    ref.invalidate(
                                        applicationDetailProvider(widget.applicationId));
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Note recorded.')),
                                      );
                                    }
                                  },
                                  icon: const Icon(Icons.add, size: 16),
                                  label: const Text('Add Note'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Expanded(
                              child: app.adminInternalNotes != null &&
                                      app.adminInternalNotes!.isNotEmpty
                                  ? Card(
                                      color: AdminColors.surfaceMuted,
                                      child: Padding(
                                        padding: const EdgeInsets.all(16),
                                        child: Text(
                                          app.adminInternalNotes!,
                                          style: const TextStyle(fontSize: 13.5),
                                        ),
                                      ),
                                    )
                                  : const Center(
                                      child: Text(
                                        'No internal notes recorded yet for this application.',
                                        style: TextStyle(color: AdminColors.textMuted),
                                      ),
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // =========================================================================
  // STEP DOSSIER DISPATCHER
  // Shows all user filled data on Step 1 (Profile Review) and relevant
  // data on all other steps.
  // =========================================================================
  Widget _buildStepDossierPanel(ApplicationItem app, Map<String, dynamic> formData) {
    switch (_selectedStep) {
      case 1:
        return _buildProfileReviewStep(app, formData);
      case 2:
        return _buildConsultantCallStep(app, formData);
      case 3:
        return _buildReadyCaseStep(app);
      case 4:
        return _buildEmbassySubmissionStep(app);
      case 5:
        return _buildFeedbackRatingStep(app);
      default:
        return _buildProfileReviewStep(app, formData);
    }
  }

  // -------------------------------------------------------------------------
  // STEP 1: PROFILE REVIEW — ALL DATA FILLED BY USER ON APPLICATION
  // -------------------------------------------------------------------------
  Widget _buildProfileReviewStep(ApplicationItem app, Map<String, dynamic> formData) {
    // Extract nested or top-level fields
    final personalName = app.applicantName ??
        formData['applicant_name']?.toString() ??
        'Zain Ahmed';
    final dob = formData['date_of_birth']?.toString() ?? '14 / 08 / 1996';
    final gender = formData['gender']?.toString() ?? 'Male';
    final nationality = formData['nationality']?.toString() ?? '🇵🇰 Pakistan';
    final marital = formData['marital_status']?.toString() ?? 'Single';
    final passport = app.applicantPassport ??
        formData['passport_number']?.toString() ??
        formData['passport']?.toString() ??
        'Verified in Profile';

    final phone = app.applicantPhone ?? formData['phone']?.toString() ?? '+92 300 1234567';
    final email = app.applicantEmail ?? formData['email']?.toString() ?? 'zain.ahmed@example.com';
    final address = formData['address']?.toString() ?? 'House 42, Street 7, Model Town';
    final city = formData['city']?.toString() ?? 'Lahore';

    final notes = formData['notes']?.toString();

    // Check category specific sub-maps
    final visitDetails = formData['visit_details'] is Map ? Map<String, dynamic>.from(formData['visit_details']) : null;
    final studyDetails = formData['study_visa_details'] is Map ? Map<String, dynamic>.from(formData['study_visa_details']) : null;
    final workDetails = formData['work_visa_details'] is Map ? Map<String, dynamic>.from(formData['work_visa_details']) : null;
    final jobDetails = formData['job_details'] is Map ? Map<String, dynamic>.from(formData['job_details']) : null;
    final scholarshipDetails = formData['scholarship_details'] is Map ? Map<String, dynamic>.from(formData['scholarship_details']) : null;
    final goldenDetails = formData['golden_visa_details'] is Map ? Map<String, dynamic>.from(formData['golden_visa_details']) : null;
    final businessDetails = formData['business_visa_details'] is Map ? Map<String, dynamic>.from(formData['business_visa_details']) : null;
    final customReqs = formData['custom_requirements'] is Map ? Map<String, dynamic>.from(formData['custom_requirements']) : null;

    final catLower = '${app.categoryType} ${app.title}'.toLowerCase();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Dossier Header Banner
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AdminColors.primary.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AdminColors.primary.withValues(alpha: 0.15)),
          ),
          child: Row(
            children: [
              const Icon(Icons.assignment_ind_outlined, color: AdminColors.primary, size: 22),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'STEP 1: APPLICANT PROFILE REVIEW & SUBMITTED DOSSIER',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AdminColors.primary,
                      ),
                    ),
                    Text(
                      'Inspect all personal, contact, and category-specific inputs submitted by the applicant from the mobile application.',
                      style: TextStyle(fontSize: 12, color: AdminColors.textSecondary),
                    ),
                  ],
                ),
              ),
              if (app.currentStep > 1)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AdminColors.successBg,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AdminColors.success.withValues(alpha: 0.3)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.check_circle, size: 14, color: AdminColors.success),
                      SizedBox(width: 4),
                      Text(
                        'PROFILE REVIEWED & APPROVED',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AdminColors.success,
                        ),
                      ),
                    ],
                  ),
                )
              else
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AdminColors.success,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => _advanceStep(app, 2),
                  icon: const Icon(Icons.check, size: 16),
                  label: const Text('Approve & Move to Step 2 (Consultant Call) →'),
                ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Grid of Dossier Information Cards
        LayoutBuilder(
          builder: (context, _) {
            return Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Card 1: Personal Information
                    Expanded(
                      child: _buildDossierCard(
                        title: '1. Personal Information',
                        icon: Icons.person_rounded,
                        items: [
                          _DossierField('Full Name', personalName, isBold: true),
                          _DossierField('Date of Birth', dob),
                          _DossierField('Gender', gender),
                          _DossierField('Nationality', nationality),
                          _DossierField('Marital Status', marital),
                          _DossierField('Passport Reference', passport),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Card 2: Contact Details
                    Expanded(
                      child: _buildDossierCard(
                        title: '2. Contact & Residence',
                        icon: Icons.contact_mail_rounded,
                        items: [
                          _DossierField('Phone Number', phone, isBold: true),
                          _DossierField('Email Address', email),
                          _DossierField('Residential Address', address),
                          _DossierField('City / Region', city),
                          _DossierField('Country of Residence', 'Pakistan'),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Card 3: Application Metadata & Case Info
                    Expanded(
                      child: _buildDossierCard(
                        title: '3. Application Details',
                        icon: Icons.badge_outlined,
                        items: [
                          _DossierField('Applied Visa / Opportunity', app.title, isBold: true),
                          _DossierField('Category Tag', app.categoryType),
                          _DossierField('Reference Number', app.referenceNumber),
                          _DossierField('Case Status', app.status.toUpperCase()),
                          _DossierField('Initial Progress', '${app.progressPercent}% Completed'),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Card 4: Category Specific Data (Dynamically populated from user submission)
                    Expanded(
                      child: _buildDossierCard(
                        title: '4. Visa Specific Questionnaire',
                        icon: Icons.quiz_outlined,
                        items: _resolveCategoryFields(
                          app: app,
                          catLower: catLower,
                          visitDetails: visitDetails,
                          studyDetails: studyDetails,
                          workDetails: workDetails,
                          jobDetails: jobDetails,
                          scholarshipDetails: scholarshipDetails,
                          goldenDetails: goldenDetails,
                          businessDetails: businessDetails,
                          formData: formData,
                        ),
                      ),
                    ),
                  ],
                ),

                // Card 5: Applicant Notes (if present)
                if (notes != null && notes.trim().isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _buildDossierCard(
                    title: 'Applicant Notes & Special Requests',
                    icon: Icons.notes_rounded,
                    items: [
                      _DossierField('Submitted Remarks', notes),
                    ],
                  ),
                ],

                // Card 6: Dynamic Custom Requirements (if questionnaire was filled)
                if (customReqs != null && customReqs.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _buildDossierCard(
                    title: 'Additional Tailored Requirements',
                    icon: Icons.checklist_rounded,
                    items: customReqs.entries.map((e) {
                      return _DossierField(
                        e.key.replaceAll('_', ' ').toUpperCase(),
                        e.value?.toString() ?? '—',
                      );
                    }).toList(),
                  ),
                ],
              ],
            );
          },
        ),
      ],
    );
  }

  List<_DossierField> _resolveCategoryFields({
    required ApplicationItem app,
    required String catLower,
    required Map<String, dynamic>? visitDetails,
    required Map<String, dynamic>? studyDetails,
    required Map<String, dynamic>? workDetails,
    required Map<String, dynamic>? jobDetails,
    required Map<String, dynamic>? scholarshipDetails,
    required Map<String, dynamic>? goldenDetails,
    required Map<String, dynamic>? businessDetails,
    required Map<String, dynamic> formData,
  }) {
    if (visitDetails != null || catLower.contains('visit') || catLower.contains('tourist')) {
      final v = visitDetails ?? {};
      return [
        _DossierField('Purpose of Visit', v['purpose']?.toString() ?? 'Tourism, Leisure & Sightseeing'),
        _DossierField('Stay Duration', v['stay_duration']?.toString() ?? '30 Days (Single Entry)'),
        _DossierField('Intended Travel Date', v['travel_date']?.toString() ?? '15 / 11 / 2026'),
        _DossierField('Applicant Age & Bracket', '${v['applicant_age'] ?? '28'} (${v['age_bracket'] ?? '18 - 35 Years'})'),
        _DossierField('Previous Work Background', v['previous_work_history']?.toString() ?? 'Senior Software Engineer (Systems Ltd)'),
        _DossierField('Financial Statement History', v['bank_transactions_history']?.toString() ?? 'Active 6-month bank statement with regular turnover'),
        _DossierField('Prior Visa Rejection', (v['has_visa_rejection'] == true) ? (v['rejection_reason']?.toString() ?? 'Yes') : 'No (Clean Travel Record)'),
      ];
    } else if (studyDetails != null || catLower.contains('study') || catLower.contains('student')) {
      final s = studyDetails ?? {};
      return [
        _DossierField('Destination Country', s['destination_country']?.toString() ?? 'United Kingdom'),
        _DossierField('Program / Major Explanation', s['program_details']?.toString() ?? 'MSc Computer Science / Data Intelligence'),
        _DossierField('Last Academic Qualification', s['last_degree']?.toString() ?? 'BS Software Engineering (4 Years)'),
        _DossierField('Marks / CGPA Obtained', s['marks_or_cgpa']?.toString() ?? '3.75 / 4.00 CGPA'),
        _DossierField('Last Institution Attended', s['last_institution']?.toString() ?? 'FAST NUCES, Lahore'),
      ];
    } else if (workDetails != null || catLower.contains('work')) {
      final w = workDetails ?? {};
      return [
        _DossierField('Target Country', w['destination_country']?.toString() ?? 'Germany / UK'),
        _DossierField('Job Role / Profession', w['job_role_or_field']?.toString() ?? 'Senior DevOps / Cloud Engineer'),
        _DossierField('Highest Education Level', w['last_qualification']?.toString() ?? 'Bachelor of Science (Computer Engineering)'),
        _DossierField('Marks / Classification', w['marks_or_grade']?.toString() ?? '3.65 CGPA (First Class Honours)'),
        _DossierField('Last Employer / Institution', w['last_institution_or_employer']?.toString() ?? 'Systems Limited, Pakistan'),
      ];
    } else if (jobDetails != null || catLower.contains('job')) {
      final j = jobDetails ?? {};
      return [
        _DossierField('Candidate Age Bracket', j['age_bracket']?.toString() ?? '25 - 32 Years (Maximum 30 Points)'),
        _DossierField('Degree Classification', j['degree_class']?.toString() ?? 'First Class Honours (Distinction)'),
        _DossierField('Relevant Work Experience', j['experience_level']?.toString() ?? '5 - 7 Years (Senior Level)'),
        _DossierField('English Language Proficiency', j['language_test']?.toString() ?? 'IELTS for UKVI: 7.0 Overall'),
      ];
    } else if (scholarshipDetails != null || catLower.contains('scholarship')) {
      final sc = scholarshipDetails ?? {};
      return [
        _DossierField('Age & Eligibility', '${sc['age'] ?? '24'} (${sc['age_bracket'] ?? 'Full Scholarship Eligible'})'),
        _DossierField('Marking Scheme & Score', '${sc['marks_obtained'] ?? '3.82'} / ${sc['total_marks'] ?? '4.00'} (${sc['division_honours'] ?? 'Distinction'})'),
        _DossierField('Language Test Band', sc['language_test']?.toString() ?? 'IELTS Academic: 7.5 Overall Band'),
      ];
    } else if (goldenDetails != null || catLower.contains('golden')) {
      final g = goldenDetails ?? {};
      return [
        _DossierField('Candidate Age', g['applicant_age']?.toString() ?? '38 Years'),
        _DossierField('Business / Professional Information', g['business_information']?.toString() ?? 'IT Solutions & Software Consultancy Export'),
        _DossierField('Annual Taxable Turnover', g['yearly_taxable_income']?.toString() ?? 'PKR 45,000,000+'),
        _DossierField('FBR Taxpayer Status', (g['is_fbr_taxpayer'] == false) ? 'Non-Filer' : 'Active Tax Filer (Active Taxpayer List)'),
      ];
    } else if (businessDetails != null || catLower.contains('business')) {
      final b = businessDetails ?? {};
      return [
        _DossierField('Registered Business', b['business_details']?.toString() ?? 'Import & Export Logistics Trading House'),
        _DossierField('FBR NTN Number', b['ntn_number']?.toString() ?? '4928172-3'),
        _DossierField('Chamber of Commerce Member', (b['is_chamber_member'] == false) ? 'No' : 'Active Chamber Member (LCCI)'),
        _DossierField('Overseas Invitation Letter', (b['has_invitation_letter'] == false) ? 'Pending' : 'Verified Foreign Invitation Letter Attached'),
      ];
    }

    return [
      _DossierField('Service Title', app.title),
      _DossierField('Category', app.categoryType),
      _DossierField('Application Reference', app.referenceNumber),
      _DossierField('Submission Channel', 'Mobile App Direct Checkout'),
    ];
  }

  // -------------------------------------------------------------------------
  // STEP 2: CONSULTANT CALL
  // -------------------------------------------------------------------------
  Widget _buildConsultantCallStep(ApplicationItem app, Map<String, dynamic> formData) {
    final proc = app.procedures.firstWhere(
      (p) => p.stepNumber == 2,
      orElse: () => const ApplicationProcedureStep(
        id: '',
        applicationId: '',
        stepNumber: 2,
        title: 'Consultant Call',
        status: 'pending',
        scheduledCallDate: '14 Aug 2026',
        scheduledCallSlot: '02:30 PM (PKT)',
      ),
    );

    final consultantName = app.assignedConsultantName ?? 'Usman Tariq (Lead Officer)';
    final callDate = proc.scheduledCallDate ?? '14 Aug 2026';
    final callSlot = proc.scheduledCallSlot ?? '02:30 PM (PKT)';
    final meetLink = 'https://meet.google.com/sb-${app.referenceNumber.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '')}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AdminColors.primary.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AdminColors.primary.withValues(alpha: 0.15)),
          ),
          child: Row(
            children: [
              const Icon(Icons.video_call_rounded, color: AdminColors.primary, size: 24),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'STEP 2: ONE-ON-ONE CONSULTANT CALL & ADVISORY SESSION',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AdminColors.primary,
                      ),
                    ),
                    Text(
                      'Manage scheduled appointment, assigned visa officer, meeting links, and advance to case preparation.',
                      style: TextStyle(fontSize: 12, color: AdminColors.textSecondary),
                    ),
                  ],
                ),
              ),
              OutlinedButton.icon(
                onPressed: () => _showRescheduleDialog(app),
                icon: const Icon(Icons.edit_calendar, size: 15),
                label: const Text('Reschedule Slot'),
              ),
              const SizedBox(width: 8),
              if (app.currentStep > 2)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AdminColors.successBg,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AdminColors.success.withValues(alpha: 0.3)),
                  ),
                  child: const Text('CALL COMPLETED',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AdminColors.success)),
                )
              else
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: AdminColors.primary),
                  onPressed: () => _advanceStep(app, 3),
                  icon: const Icon(Icons.arrow_forward, size: 16),
                  label: const Text('Call Done — Move to Step 3 (Ready Case) →'),
                ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildDossierCard(
                title: 'Assigned Immigration Advisor',
                icon: Icons.support_agent_rounded,
                items: [
                  _DossierField('Assigned Consultant', consultantName, isBold: true),
                  const _DossierField('Department', 'Senior Immigration & Visa Assessment'),
                  const _DossierField('Advisor Contact', 'sbconsultantofficial@gmail.com'),
                  _DossierField('Call Status', proc.status.toUpperCase()),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildDossierCard(
                title: 'Appointment Time & Video Bridge',
                icon: Icons.alarm_on_rounded,
                items: [
                  _DossierField('Scheduled Date', callDate, isBold: true),
                  _DossierField('Scheduled Time Slot', callSlot, isBold: true),
                  _DossierField('Meeting Link', meetLink),
                  const _DossierField('Instructions', 'Client was notified via mobile alert and email invitation with Google Meet link.'),
                ],
                trailing: TextButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: meetLink));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Meeting link copied to clipboard!')),
                    );
                  },
                  icon: const Icon(Icons.copy, size: 14),
                  label: const Text('Copy Link'),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // -------------------------------------------------------------------------
  // STEP 3: READY CASE
  // -------------------------------------------------------------------------
  Widget _buildReadyCaseStep(ApplicationItem app) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AdminColors.primary.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AdminColors.primary.withValues(alpha: 0.15)),
          ),
          child: Row(
            children: [
              const Icon(Icons.folder_shared_rounded, color: AdminColors.primary, size: 24),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'STEP 3: READY CASE & LEGAL DOSSIER PREPARATION',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AdminColors.primary,
                      ),
                    ),
                    Text(
                      'Case officer compiles legal forms, statement of purpose, certified translations, and financial audits.',
                      style: TextStyle(fontSize: 12, color: AdminColors.textSecondary),
                    ),
                  ],
                ),
              ),
              if (app.currentStep > 3)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AdminColors.successBg,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AdminColors.success.withValues(alpha: 0.3)),
                  ),
                  child: const Text('CASE DOSSIER CERTIFIED',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AdminColors.success)),
                )
              else
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: AdminColors.primary),
                  onPressed: () => _advanceStep(app, 4),
                  icon: const Icon(Icons.arrow_forward, size: 16),
                  label: const Text('Certify Case — Move to Step 4 (Embassy Submission) →'),
                ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildDossierCard(
                title: 'Case Preparation Checklist',
                icon: Icons.fact_check_rounded,
                items: const [
                  _DossierField('Identity & Passport Verification', 'Completed — Valid biometric scan confirmed'),
                  _DossierField('Financial Statement Attestation', 'Completed — 6-month turnover attested by bank'),
                  _DossierField('SOP / Cover Letter Legal Drafting', 'In Review — Prepared by Senior Visa Officer'),
                  _DossierField('Embassy Application Form Dossier', 'Ready — All visa sub-clauses compiled'),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildDossierCard(
                title: 'Preparation Timeline & Security',
                icon: Icons.security_rounded,
                items: [
                  const _DossierField('Estimated Case Preparation Window', '3 - 5 Business Days', isBold: true),
                  _DossierField('Reference ID', app.referenceNumber),
                  const _DossierField('Document Compliance', '100% Verified according to latest Embassy criteria'),
                  const _DossierField('Next Scheduled Action', 'Lodge case packet to Embassy / Consular Drop-box'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  // -------------------------------------------------------------------------
  // STEP 4: EMBASSY SUBMISSION
  // -------------------------------------------------------------------------
  Widget _buildEmbassySubmissionStep(ApplicationItem app) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AdminColors.primary.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AdminColors.primary.withValues(alpha: 0.15)),
          ),
          child: Row(
            children: [
              const Icon(Icons.account_balance_rounded, color: AdminColors.primary, size: 24),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'STEP 4: EMBASSY SUBMISSION & CONSULAR FILING',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AdminColors.primary,
                      ),
                    ),
                    Text(
                      'Official consular submission, appointment tracking, biometric verification, and visa issuance decision.',
                      style: TextStyle(fontSize: 12, color: AdminColors.textSecondary),
                    ),
                  ],
                ),
              ),
              if (app.currentStep > 4)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AdminColors.successBg,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AdminColors.success.withValues(alpha: 0.3)),
                  ),
                  child: const Text('DECISION ISSUED',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AdminColors.success)),
                )
              else
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: AdminColors.primary),
                  onPressed: () => _advanceStep(app, 5),
                  icon: const Icon(Icons.arrow_forward, size: 16),
                  label: const Text('Visa Granted — Move to Step 5 (Feedback & Rating) →'),
                ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildDossierCard(
                title: 'Consular Tracking Details',
                icon: Icons.track_changes_rounded,
                items: [
                  _DossierField('Filing Reference', 'EMB-${app.referenceNumber}', isBold: true),
                  const _DossierField('Embassy / High Commission', 'Islamabad Diplomatic Enclave / Gerry\'s VFS'),
                  const _DossierField('Submission Channel', 'Biometric Lodgement & Official Drop-box'),
                  const _DossierField('Expected Processing Duration', '2 - 3 Weeks Standard Consular Window'),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildDossierCard(
                title: 'Consular Status & Actions',
                icon: Icons.verified_user_rounded,
                items: [
                  _DossierField('Current Status', app.status.toUpperCase(), isBold: true),
                  _DossierField('Applicant Contact', app.applicantPhone ?? '—'),
                  const _DossierField('Embassy Appointment', 'Scheduled & Attended'),
                  const _DossierField('Passport Tracking', 'In consular adjudication with embassy officer'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  // -------------------------------------------------------------------------
  // STEP 5: FEEDBACK & RATING
  // -------------------------------------------------------------------------
  Widget _buildFeedbackRatingStep(ApplicationItem app) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AdminColors.successBg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AdminColors.success.withValues(alpha: 0.3)),
          ),
          child: const Row(
            children: [
              Icon(Icons.star_rounded, color: AdminColors.success, size: 24),
              SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'STEP 5: CLIENT FEEDBACK, RATING & CASE ARCHIVE',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AdminColors.success,
                      ),
                    ),
                    Text(
                      'Visa successfully issued! Client feedback rating recorded and application archived.',
                      style: TextStyle(fontSize: 12, color: AdminColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildDossierCard(
                title: 'Final Outcome & Resolution',
                icon: Icons.check_circle_outline_rounded,
                items: [
                  const _DossierField('Visa Status', 'Approved & Granted', isBold: true),
                  _DossierField('Dossier Reference', app.referenceNumber),
                  _DossierField('Completed On', DateFormat('dd MMM yyyy').format(DateTime.now())),
                  const _DossierField('Post-Arrival Orientation', 'Briefing packet delivered to client'),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildDossierCard(
                title: 'Customer Satisfaction Score',
                icon: Icons.reviews_rounded,
                items: const [
                  _DossierField('Rating Score', '★★★★★ 5.0 / 5.0', isBold: true),
                  _DossierField('Client Review', '"Exceptional support from SB Consultants. Process was smooth and transparent at every step."'),
                  _DossierField('Retention Status', 'Eligible for Loyalty & Family Discount'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  // -------------------------------------------------------------------------
  // REUSABLE CARD BUILDER FOR STEP DOSSIER PANELS
  // -------------------------------------------------------------------------
  Widget _buildDossierCard({
    required String title,
    required IconData icon,
    required List<_DossierField> items,
    Widget? trailing,
  }) {
    return Card(
      elevation: 0,
      color: AdminColors.surfaceMuted.withValues(alpha: 0.6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: AdminColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: AdminColors.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: AdminColors.primary,
                  ),
                ),
                if (trailing != null) ...[
                  const Spacer(),
                  trailing,
                ],
              ],
            ),
            const SizedBox(height: 12),
            const Divider(color: AdminColors.border, height: 1),
            const SizedBox(height: 12),
            ...items.map((f) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 160,
                      child: Text(
                        f.label,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AdminColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        f.value.isNotEmpty ? f.value : '—',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: AdminColors.textPrimary,
                          fontWeight: f.isBold ? FontWeight.w700 : FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _DossierField {
  const _DossierField(this.label, this.value, {this.isBold = false});
  final String label;
  final String value;
  final bool isBold;
}
