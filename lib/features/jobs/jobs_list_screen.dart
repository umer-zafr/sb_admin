import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/admin_theme.dart';
import '../../models/job_model.dart';
import '../../providers/admin_dashboard_providers.dart';
import '../../services/admin_job_service.dart';
import '../../widgets/admin_scaffold.dart';
import '../../widgets/confirmation_dialog.dart';
import '../../widgets/data_table_card.dart';
import '../../widgets/search_filter_bar.dart';
import '../../widgets/status_badge.dart';
import 'job_edit_dialog.dart';

class JobsListScreen extends ConsumerStatefulWidget {
  const JobsListScreen({super.key});

  @override
  ConsumerState<JobsListScreen> createState() => _JobsListScreenState();
}

class _JobsListScreenState extends ConsumerState<JobsListScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _statusFilter = 'all';
  bool _isTableView = false; // Executive Cards is default: zero horizontal scroll!

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool? isActiveFilter;
    if (_statusFilter == 'active') isActiveFilter = true;
    if (_statusFilter == 'inactive') isActiveFilter = false;

    final jobsAsync = ref.watch(
      jobsListProvider((search: _searchQuery, isActive: isActiveFilter)),
    );

    return AdminScaffold(
      title: 'Sponsored Jobs Directory',
      subtitle: 'Verified foreign employer vacancies offering Tier 2 / COS work visa sponsorship',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SearchFilterBar<String>(
            searchController: _searchController,
            searchHint: 'Search jobs by title, company, or location...',
            onSearchChanged: (val) => setState(() => _searchQuery = val),
            filterValue: _statusFilter,
            filterLabel: 'Status',
            filterItems: const [
              FilterDropdownItem(value: 'all', label: 'All Jobs'),
              FilterDropdownItem(value: 'active', label: 'Published Only'),
              FilterDropdownItem(value: 'inactive', label: 'Hidden / Inactive'),
            ],
            onFilterChanged: (val) {
              if (val != null) setState(() => _statusFilter = val);
            },
            actionLabel: 'New Sponsored Job',
            onAction: () async {
              final created = await JobEditDialog.show(context);
              if (created == true) {
                ref.invalidate(jobsListProvider);
                ref.invalidate(dashboardMetricsProvider);
              }
            },
            onRefresh: () => ref.invalidate(jobsListProvider),
          ),
          const SizedBox(height: 16),

          // View Mode Switcher
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AdminColors.border),
                ),
                padding: const EdgeInsets.all(3),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    InkWell(
                      onTap: () => setState(() => _isTableView = false),
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: !_isTableView ? AdminColors.primary : Colors.transparent,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.grid_view_rounded,
                              size: 15,
                              color: !_isTableView ? Colors.white : AdminColors.textSecondary,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              'Executive Cards',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: !_isTableView ? Colors.white : AdminColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    InkWell(
                      onTap: () => setState(() => _isTableView = true),
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: _isTableView ? AdminColors.primary : Colors.transparent,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.table_rows_rounded,
                              size: 15,
                              color: _isTableView ? Colors.white : AdminColors.textSecondary,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              'Compact Table',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: _isTableView ? Colors.white : AdminColors.textSecondary,
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
          ),
          const SizedBox(height: 16),

          jobsAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(60),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (err, _) => Card(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text('Error loading jobs: $err'),
              ),
            ),
            data: (jobs) {
              if (jobs.isEmpty) {
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(48),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.work_outline_rounded,
                              size: 48, color: AdminColors.textMuted),
                          const SizedBox(height: 12),
                          const Text(
                            'No Sponsored Jobs Found',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AdminColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Try clearing search or click "New Sponsored Job" to publish a vacancy.',
                            style: TextStyle(fontSize: 13, color: AdminColors.textMuted),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () async {
                              final created = await JobEditDialog.show(context);
                              if (created == true) {
                                ref.invalidate(jobsListProvider);
                                ref.invalidate(dashboardMetricsProvider);
                              }
                            },
                            icon: const Icon(Icons.add, size: 16),
                            label: const Text('Add Sponsored Job'),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }

              final total = jobs.length;
              final activeCount = jobs.where((j) => j.isActive).length;
              final hiddenCount = total - activeCount;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // KPI Metric Highlights
                  Row(
                    children: [
                      Expanded(
                        child: _buildMetricTile(
                          title: 'Total Sponsored Jobs',
                          value: '$total',
                          icon: Icons.work_outline_rounded,
                          color: const Color(0xFF0284C7),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildMetricTile(
                          title: 'Live in Mobile Directory',
                          value: '$activeCount',
                          icon: Icons.check_circle_rounded,
                          color: AdminColors.success,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildMetricTile(
                          title: 'Hidden / Draft',
                          value: '$hiddenCount',
                          icon: Icons.visibility_off_outlined,
                          color: AdminColors.warning,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Header with Zero Scroll Guarantee
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Verified Job Vacancies ($total)',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AdminColors.textPrimary,
                        ),
                      ),
                      const Text(
                        'Edit & Delete action buttons visible — zero horizontal scroll required',
                        style: TextStyle(fontSize: 12, color: AdminColors.textMuted),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  if (!_isTableView)
                    _buildExecutiveJobsList(context, jobs)
                  else
                    _buildCompactJobsTable(context, jobs),
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11.5,
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExecutiveJobsList(BuildContext context, List<SponsoredJobItem> jobs) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: jobs.length,
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemBuilder: (context, idx) {
        final job = jobs[idx];
        return _buildJobCard(context, job);
      },
    );
  }

  Widget _buildJobCard(BuildContext context, SponsoredJobItem job) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: job.isActive ? AdminColors.border : const Color(0xFFCBD5E1),
          width: job.isActive ? 1.0 : 1.2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Flag Avatar
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0284C7).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF0284C7).withValues(alpha: 0.2)),
                  ),
                  child: Center(
                    child: Text(job.countryFlag ?? '💼', style: const TextStyle(fontSize: 24)),
                  ),
                ),
                const SizedBox(width: 14),

                // Title & Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.location_on_outlined, size: 12, color: AdminColors.primary),
                                const SizedBox(width: 4),
                                Text(
                                  job.location,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AdminColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0284C7).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              (job.employmentType ?? 'Full-Time').toUpperCase(),
                              style: const TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0284C7),
                                letterSpacing: 0.4,
                              ),
                            ),
                          ),
                          if (job.isFeatured) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                              decoration: BoxDecoration(
                                color: AdminColors.accentGold.withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'FEATURED',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFFB45309),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        job.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w700,
                          color: AdminColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        job.companyOrInstitution,
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: AdminColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Metadata Chips
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _buildInfoChip(
                  icon: Icons.payments_outlined,
                  label: job.salaryOrFunding ?? 'Competitive Package',
                  color: AdminColors.success,
                  isBold: true,
                ),
                if (job.postedTime != null && job.postedTime!.isNotEmpty)
                  _buildInfoChip(
                    icon: Icons.schedule_rounded,
                    label: job.postedTime!,
                    color: AdminColors.textSecondary,
                  ),
              ],
            ),
            const SizedBox(height: 14),
            const Divider(height: 1, color: AdminColors.border),
            const SizedBox(height: 10),

            // Bottom Actions Row: 100% VISIBLE WITH ZERO HORIZONTAL SCROLL!
            Row(
              children: [
                StatusBadge(
                  status: job.isActive ? 'active' : 'inactive',
                  customLabel: job.isActive ? 'Live in App' : 'Hidden / Draft',
                ),
                const SizedBox(width: 8),
                Transform.scale(
                  scale: 0.8,
                  child: Switch(
                    value: job.isActive,
                    activeThumbColor: AdminColors.success,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    onChanged: (val) async {
                      await AdminJobService.instance.toggleStatus(job.id, val, 'job');
                      ref.invalidate(jobsListProvider);
                      ref.invalidate(dashboardMetricsProvider);
                    },
                  ),
                ),
                const Spacer(),

                // Edit Button
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AdminColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    elevation: 0,
                  ),
                  onPressed: () async {
                    final updated = await JobEditDialog.show(context, existingJob: job);
                    if (updated == true) {
                      ref.invalidate(jobsListProvider);
                      ref.invalidate(dashboardMetricsProvider);
                    }
                  },
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: const Text('Edit Job',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                ),
                const SizedBox(width: 10),

                // Delete Button
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AdminColors.danger,
                    side: BorderSide(color: AdminColors.danger.withValues(alpha: 0.4)),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                  onPressed: () async {
                    final confirm = await ConfirmationDialog.show(
                      context,
                      title: 'Delete Sponsored Job',
                      message: 'Are you sure you want to permanently delete "${job.title}"?',
                      confirmLabel: 'Delete Vacancy',
                      isDestructive: true,
                    );
                    if (confirm) {
                      await AdminJobService.instance.deleteItem(job.id, 'job');
                      ref.invalidate(jobsListProvider);
                      ref.invalidate(dashboardMetricsProvider);
                    }
                  },
                  icon: const Icon(Icons.delete_outline_rounded, size: 16),
                  label: const Text('Delete',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required Color color,
    bool isBold = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
              color: isBold ? color : AdminColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactJobsTable(BuildContext context, List<SponsoredJobItem> jobs) {
    return DataTableCard(
      title: 'Sponsored Job Vacancies (${jobs.length})',
      subtitle: 'Tabulated layout with bounded cell widths',
      columns: const [
        DataColumn(label: Text('JOB TITLE & EMPLOYER')),
        DataColumn(label: Text('LOCATION')),
        DataColumn(label: Text('SALARY / PERKS')),
        DataColumn(label: Text('TYPE')),
        DataColumn(label: Text('STATUS')),
        DataColumn(label: Text('ACTIONS')),
      ],
      rows: jobs.map((job) {
        return DataRow(
          cells: [
            DataCell(
              SizedBox(
                width: 220,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(job.countryFlag ?? '💼', style: const TextStyle(fontSize: 18)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            job.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          Text(
                            job.companyOrInstitution,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 11.5, color: AdminColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            DataCell(
              SizedBox(
                width: 110,
                child: Text(job.location,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12)),
              ),
            ),
            DataCell(
              SizedBox(
                width: 120,
                child: Text(
                  job.salaryOrFunding ?? 'Competitive',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600, color: AdminColors.primary),
                ),
              ),
            ),
            DataCell(
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AdminColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  job.employmentType ?? 'Full-Time',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            DataCell(
              StatusBadge(
                status: job.isActive ? 'active' : 'inactive',
                customLabel: job.isActive ? 'Published' : 'Hidden',
              ),
            ),
            DataCell(
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    tooltip: 'Edit Job',
                    onPressed: () async {
                      final updated = await JobEditDialog.show(context, existingJob: job);
                      if (updated == true) ref.invalidate(jobsListProvider);
                    },
                  ),
                  IconButton(
                    icon: Icon(
                      job.isActive ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      size: 18,
                      color: job.isActive ? AdminColors.warning : AdminColors.success,
                    ),
                    tooltip: job.isActive ? 'Unpublish' : 'Publish',
                    onPressed: () async {
                      await AdminJobService.instance.toggleStatus(job.id, !job.isActive, 'job');
                      ref.invalidate(jobsListProvider);
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 18, color: AdminColors.danger),
                    tooltip: 'Delete Job',
                    onPressed: () async {
                      final confirm = await ConfirmationDialog.show(
                        context,
                        title: 'Delete Sponsored Job',
                        message: 'Are you sure you want to delete "${job.title}"?',
                        confirmLabel: 'Delete',
                        isDestructive: true,
                      );
                      if (confirm) {
                        await AdminJobService.instance.deleteItem(job.id, 'job');
                        ref.invalidate(jobsListProvider);
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        );
      }).toList(),
    );
  }
}
