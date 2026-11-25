import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/constants/admin_constants.dart';
import '../../core/theme/admin_theme.dart';
import '../../models/application_model.dart';
import '../../providers/admin_dashboard_providers.dart';
import '../../widgets/admin_scaffold.dart';
import '../../widgets/search_filter_bar.dart';
import '../../widgets/status_badge.dart';

class ApplicationsListScreen extends ConsumerStatefulWidget {
  const ApplicationsListScreen({super.key});

  @override
  ConsumerState<ApplicationsListScreen> createState() =>
      _ApplicationsListScreenState();
}

class _ApplicationsListScreenState
    extends ConsumerState<ApplicationsListScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _statusFilter = 'all';

  // Set of application IDs whose full user form answers are expanded
  final Set<String> _expandedAppIds = {};

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _copy(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copied to clipboard'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appsAsync = ref.watch(
      applicationsListProvider((
        search: _searchQuery,
        status: _statusFilter,
        category: null,
      )),
    );

    return AdminScaffold(
      title: 'Applications Management',
      subtitle:
          'Track and process client visa petitions, verify transaction fee numbers, and manage 5-step milestone procedures',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Filter Bar
          SearchFilterBar<String>(
            searchController: _searchController,
            searchHint:
                'Search by reference #, transaction ID, applicant name, or email...',
            onSearchChanged: (val) => setState(() => _searchQuery = val),
            filterValue: _statusFilter,
            filterLabel: 'Status',
            filterItems: [
              const FilterDropdownItem(value: 'all', label: 'All Statuses'),
              ...AdminConstants.applicationStatuses.map(
                (s) => FilterDropdownItem(
                  value: s,
                  label: s.toUpperCase().replaceAll('_', ' '),
                ),
              ),
            ],
            onFilterChanged: (val) {
              if (val != null) setState(() => _statusFilter = val);
            },
            onRefresh: () => ref.invalidate(applicationsListProvider),
          ),
          const SizedBox(height: 20),

          // Applications Content
          appsAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(60),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (err, _) => Card(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text('Error loading applications: $err'),
              ),
            ),
            data: (apps) {
              if (apps.isEmpty) {
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(48),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.folder_open_rounded,
                              size: 48, color: AdminColors.textMuted),
                          const SizedBox(height: 12),
                          const Text(
                            'No applications found',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AdminColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Try clearing your search query or choosing a different status filter.',
                            style: TextStyle(
                              fontSize: 13,
                              color: AdminColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }

              // Compute Summary Metrics
              final total = apps.length;
              final pendingPayment = apps.where((a) {
                final st = a.status.toLowerCase();
                return st == 'submitted' ||
                    st == 'under_review' ||
                    a.paymentStatus == 'pending';
              }).length;
              final inProgress = apps
                  .where((a) => a.currentStep >= 1 && a.currentStep < 5)
                  .length;
              final completed = apps.where((a) => a.currentStep == 5).length;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Metric Highlights
                  Row(
                    children: [
                      Expanded(
                        child: _buildMetricTile(
                          title: 'Total Applications',
                          value: '$total',
                          icon: Icons.folder_shared_rounded,
                          color: AdminColors.primary,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: _buildMetricTile(
                          title: 'Review / Payments',
                          value: '$pendingPayment',
                          icon: Icons.receipt_long_rounded,
                          color: const Color(0xFFD97706),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: _buildMetricTile(
                          title: 'In Progress (Steps 1-4)',
                          value: '$inProgress',
                          icon: Icons.sync_rounded,
                          color: const Color(0xFF0284C7),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: _buildMetricTile(
                          title: 'Completed (Step 5)',
                          value: '$completed',
                          icon: Icons.check_circle_rounded,
                          color: const Color(0xFF16A34A),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Header title
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Applicant Files & Dossiers ($total)',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AdminColors.textPrimary,
                        ),
                      ),
                      const Text(
                        'Manage button is front and center — zero horizontal scroll required',
                        style: TextStyle(
                          fontSize: 12,
                          color: AdminColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Executive Dossier Cards List (No horizontal scrolling!)
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: apps.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 16),
                    itemBuilder: (context, idx) {
                      final app = apps[idx];
                      return _buildExecutiveApplicationCard(context, app);
                    },
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AdminColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AdminColors.textMuted,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExecutiveApplicationCard(
      BuildContext context, ApplicationItem app) {
    final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');
    final isExpanded = _expandedAppIds.contains(app.id);

    final applicantName =
        app.applicantName?.isNotEmpty == true ? app.applicantName! : 'Applicant';
    final email =
        app.applicantEmail?.isNotEmpty == true ? app.applicantEmail! : 'No email';
    final phone =
        app.applicantPhone?.isNotEmpty == true ? app.applicantPhone! : 'No phone';
    final passport = app.passportNumber ?? 'Verified in profile';
    final nationality = app.nationality ?? 'Pakistan';

    final transactionId = app.transactionId;
    final feeAmount = app.paymentAmount;
    final paymentMethod = app.paymentMethod ?? 'Bank Transfer';
    final paymentStatus = app.paymentStatus ?? 'Pending';
    final isPaymentVerified = paymentStatus.toLowerCase() == 'completed' ||
        paymentStatus.toLowerCase() == 'success';

    final formDataMap =
        app.formData is Map ? Map<String, dynamic>.from(app.formData as Map) : {};

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: !isPaymentVerified && transactionId != null
              ? const Color(0xFFF59E0B)
              : AdminColors.border,
          width: !isPaymentVerified && transactionId != null ? 1.6 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ================================================================
            // HEADER BAR: REFERENCE + STATUS + DATE + MANAGE BUTTON FRONT & CENTER!
            // ================================================================
            Row(
              children: [
                // Case Reference Pill
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AdminColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AdminColors.primary.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.tag_rounded,
                          size: 13, color: AdminColors.primary),
                      const SizedBox(width: 4),
                      Text(
                        app.referenceNumber,
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          color: AdminColors.primary,
                        ),
                      ),
                      const SizedBox(width: 6),
                      InkWell(
                        onTap: () =>
                            _copy(app.referenceNumber, 'Reference ID'),
                        child: const Icon(Icons.copy_rounded,
                            size: 13, color: AdminColors.primary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),

                // Status Badge
                StatusBadge(status: app.status),
                const SizedBox(width: 12),

                // Applied Date
                Icon(Icons.schedule_rounded,
                    size: 14, color: AdminColors.textMuted),
                const SizedBox(width: 4),
                Text(
                  dateFormat.format(app.appliedAt.toLocal()),
                  style: const TextStyle(
                    fontSize: 12,
                    color: AdminColors.textMuted,
                  ),
                ),

                const Spacer(),

                // ============================================================
                // MANAGE BUTTON IS PROMINENT RIGHT HERE — NO HORIZONTAL SCROLL!
                // ============================================================
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AdminColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: const Icon(Icons.folder_open_rounded, size: 16),
                  label: const Text(
                    'Manage Dossier →',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                  onPressed: () => context.go('/applications/${app.id}'),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Visa Title & Category
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AdminColors.surfaceMuted,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    app.categoryType.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      color: AdminColors.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    app.title,
                    style: const TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w700,
                      color: AdminColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // ================================================================
            // APPLICANT ENTERED DETAILS: ALL FIELDS SHOWN CLEARLY!
            // ================================================================
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AdminColors.surfaceMuted,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Wrap(
                spacing: 24,
                runSpacing: 10,
                children: [
                  // Name
                  _buildDetailItem(
                    icon: Icons.person_rounded,
                    label: 'Applicant Name',
                    value: applicantName,
                    isPrimary: true,
                  ),

                  // Email
                  _buildDetailItem(
                    icon: Icons.email_outlined,
                    label: 'Email',
                    value: email,
                    onCopy: () => _copy(email, 'Email address'),
                  ),

                  // Phone
                  _buildDetailItem(
                    icon: Icons.phone_outlined,
                    label: 'Phone',
                    value: phone,
                    onCopy: () => _copy(phone, 'Phone number'),
                  ),

                  // Passport
                  _buildDetailItem(
                    icon: Icons.badge_outlined,
                    label: 'Passport #',
                    value: passport,
                    onCopy: () => _copy(passport, 'Passport number'),
                  ),

                  // Nationality
                  _buildDetailItem(
                    icon: Icons.public_rounded,
                    label: 'Nationality',
                    value: nationality,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // ================================================================
            // HIGH-VISIBILITY TRANSACTION FEE & RECEIPT HIGHLIGHT CONTAINER
            // ================================================================
            if (transactionId != null || feeAmount != null) ...[
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: isPaymentVerified
                      ? const Color(0xFFF0FDF4)
                      : const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isPaymentVerified
                        ? const Color(0xFF86EFAC)
                        : const Color(0xFFFCD34D),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isPaymentVerified
                            ? const Color(0xFF16A34A).withValues(alpha: 0.15)
                            : const Color(0xFFD97706).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        isPaymentVerified
                            ? Icons.verified_rounded
                            : Icons.receipt_long_rounded,
                        color: isPaymentVerified
                            ? const Color(0xFF16A34A)
                            : const Color(0xFFD97706),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'TRANSACTION FEE RECEIPT NUMBER: ',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w800,
                                  color: isPaymentVerified
                                      ? const Color(0xFF166534)
                                      : const Color(0xFF92400E),
                                  letterSpacing: 0.5,
                                ),
                              ),
                              if (transactionId != null) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: isPaymentVerified
                                          ? const Color(0xFF16A34A)
                                          : const Color(0xFFD97706),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        transactionId,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w800,
                                          color: isPaymentVerified
                                              ? const Color(0xFF166534)
                                              : const Color(0xFF92400E),
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      InkWell(
                                        onTap: () => _copy(transactionId,
                                            'Transaction reference ID'),
                                        child: Icon(
                                          Icons.copy_rounded,
                                          size: 12,
                                          color: isPaymentVerified
                                              ? const Color(0xFF166534)
                                              : const Color(0xFF92400E),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 12,
                            children: [
                              if (feeAmount != null)
                                Text(
                                  'Amount: $feeAmount',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              Text(
                                'Method: $paymentMethod',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AdminColors.textSecondary,
                                ),
                              ),
                              Text(
                                'Status: ${paymentStatus.toUpperCase()}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: isPaymentVerified
                                      ? const Color(0xFF16A34A)
                                      : const Color(0xFFD97706),
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
              const SizedBox(height: 12),
            ],

            // ================================================================
            // PROCEDURE STEPPER MILESTONE TRACKER
            // ================================================================
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Step ${app.currentStep} of 5: ${app.stepText ?? 'In Progress'}',
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: AdminColors.primary,
                      ),
                    ),
                    Text(
                      '${app.progressPercent}% Milestone Complete',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AdminColors.textMuted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: app.progressPercent / 100,
                    minHeight: 7,
                    backgroundColor: AdminColors.surfaceMuted,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      app.currentStep == 5
                          ? const Color(0xFF16A34A)
                          : AdminColors.primary,
                    ),
                  ),
                ),
              ],
            ),

            // ================================================================
            // EXPANDABLE USER-ENTERED ANSWERS / CUSTOM REQUIREMENTS
            // ================================================================
            if (formDataMap.isNotEmpty) ...[
              const SizedBox(height: 10),
              InkWell(
                onTap: () {
                  setState(() {
                    if (isExpanded) {
                      _expandedAppIds.remove(app.id);
                    } else {
                      _expandedAppIds.add(app.id);
                    }
                  });
                },
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Icon(
                        isExpanded
                            ? Icons.expand_less_rounded
                            : Icons.expand_more_rounded,
                        size: 18,
                        color: AdminColors.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isExpanded
                            ? 'Hide User Form Answers & Custom Fields'
                            : 'View All User Form Answers & Submitted Data (${formDataMap.length} fields) ▼',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AdminColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              if (isExpanded) ...[
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AdminColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'CLIENT SUBMITTED FORM PAYLOAD:',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          color: AdminColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 16,
                        runSpacing: 8,
                        children: formDataMap.entries
                            .where((e) =>
                                e.key != 'payments' &&
                                e.value != null &&
                                e.value.toString().isNotEmpty)
                            .map((e) {
                          final label = e.key
                              .toString()
                              .replaceAll('_', ' ')
                              .toUpperCase();
                          final val = e.value is Map || e.value is List
                              ? e.value.toString()
                              : e.value.toString();

                          return Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: AdminColors.surfaceMuted,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  label,
                                  style: const TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w700,
                                    color: AdminColors.textMuted,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  val,
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                    color: AdminColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem({
    required IconData icon,
    required String label,
    required String value,
    bool isPrimary = false,
    VoidCallback? onCopy,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon,
            size: 15,
            color: isPrimary ? AdminColors.primary : AdminColors.textMuted),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label.toUpperCase(),
              style: const TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
                color: AdminColors.textMuted,
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: isPrimary ? 13.5 : 12.5,
                    fontWeight: isPrimary ? FontWeight.w800 : FontWeight.w600,
                    color: isPrimary
                        ? AdminColors.textPrimary
                        : AdminColors.textSecondary,
                  ),
                ),
                if (onCopy != null) ...[
                  const SizedBox(width: 4),
                  InkWell(
                    onTap: onCopy,
                    child: const Icon(Icons.copy_rounded,
                        size: 11, color: AdminColors.textMuted),
                  ),
                ],
              ],
            ),
          ],
        ),
      ],
    );
  }
}
