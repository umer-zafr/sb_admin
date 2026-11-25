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
import 'scholarship_edit_dialog.dart';

class ScholarshipsListScreen extends ConsumerStatefulWidget {
  const ScholarshipsListScreen({super.key});

  @override
  ConsumerState<ScholarshipsListScreen> createState() =>
      _ScholarshipsListScreenState();
}

class _ScholarshipsListScreenState
    extends ConsumerState<ScholarshipsListScreen> {
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

    final scholarshipsAsync = ref.watch(
      scholarshipsListProvider((search: _searchQuery, isActive: isActiveFilter)),
    );

    return AdminScaffold(
      title: 'Global Scholarships Directory',
      subtitle: 'Fully-funded and partial scholarship grants for international study visas',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SearchFilterBar<String>(
            searchController: _searchController,
            searchHint: 'Search scholarships by title, university, or country...',
            onSearchChanged: (val) => setState(() => _searchQuery = val),
            filterValue: _statusFilter,
            filterLabel: 'Status',
            filterItems: const [
              FilterDropdownItem(value: 'all', label: 'All Scholarships'),
              FilterDropdownItem(value: 'active', label: 'Published Only'),
              FilterDropdownItem(value: 'inactive', label: 'Hidden / Inactive'),
            ],
            onFilterChanged: (val) {
              if (val != null) setState(() => _statusFilter = val);
            },
            actionLabel: 'New Scholarship',
            onAction: () async {
              final created = await ScholarshipEditDialog.show(context);
              if (created == true) {
                ref.invalidate(scholarshipsListProvider);
                ref.invalidate(dashboardMetricsProvider);
              }
            },
            onRefresh: () => ref.invalidate(scholarshipsListProvider),
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

          scholarshipsAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(60),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (err, _) => Card(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text('Error loading scholarships: $err'),
              ),
            ),
            data: (scholarships) {
              if (scholarships.isEmpty) {
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(48),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.school_outlined,
                              size: 48, color: AdminColors.textMuted),
                          const SizedBox(height: 12),
                          const Text(
                            'No Scholarships Found',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AdminColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Try clearing search or click "New Scholarship" to publish an opportunity.',
                            style: TextStyle(fontSize: 13, color: AdminColors.textMuted),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () async {
                              final created = await ScholarshipEditDialog.show(context);
                              if (created == true) {
                                ref.invalidate(scholarshipsListProvider);
                                ref.invalidate(dashboardMetricsProvider);
                              }
                            },
                            icon: const Icon(Icons.add, size: 16),
                            label: const Text('Add Scholarship'),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }

              final total = scholarships.length;
              final activeCount = scholarships.where((s) => s.isActive).length;
              final hiddenCount = total - activeCount;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // KPI Metric Highlights
                  Row(
                    children: [
                      Expanded(
                        child: _buildMetricTile(
                          title: 'Total Scholarships',
                          value: '$total',
                          icon: Icons.school_outlined,
                          color: const Color(0xFF7C3AED),
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
                        'Verified Scholarships ($total)',
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
                    _buildExecutiveScholarshipsList(context, scholarships)
                  else
                    _buildCompactScholarshipsTable(context, scholarships),
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

  Widget _buildExecutiveScholarshipsList(BuildContext context, List<SponsoredJobItem> scholarships) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: scholarships.length,
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemBuilder: (context, idx) {
        final sch = scholarships[idx];
        return _buildScholarshipCard(context, sch);
      },
    );
  }

  Widget _buildScholarshipCard(BuildContext context, SponsoredJobItem sch) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: sch.isActive ? AdminColors.border : const Color(0xFFCBD5E1),
          width: sch.isActive ? 1.0 : 1.2,
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
                    color: const Color(0xFF7C3AED).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF7C3AED).withValues(alpha: 0.2)),
                  ),
                  child: Center(
                    child: Text(sch.countryFlag ?? '🎓', style: const TextStyle(fontSize: 24)),
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
                                  sch.location,
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
                              color: const Color(0xFF7C3AED).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              (sch.degreeLevel ?? "Master's").toUpperCase(),
                              style: const TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF7C3AED),
                                letterSpacing: 0.4,
                              ),
                            ),
                          ),
                          if (sch.isFeatured) ...[
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
                        sch.title,
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
                        sch.companyOrInstitution,
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
                  icon: Icons.monetization_on_outlined,
                  label: sch.salaryOrFunding ?? '100% Tuition + Stipend',
                  color: AdminColors.primary,
                  isBold: true,
                ),
                if (sch.postedTime != null && sch.postedTime!.isNotEmpty)
                  _buildInfoChip(
                    icon: Icons.schedule_rounded,
                    label: sch.postedTime!,
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
                  status: sch.isActive ? 'active' : 'inactive',
                  customLabel: sch.isActive ? 'Live in App' : 'Hidden / Draft',
                ),
                const SizedBox(width: 8),
                Transform.scale(
                  scale: 0.8,
                  child: Switch(
                    value: sch.isActive,
                    activeThumbColor: AdminColors.success,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    onChanged: (val) async {
                      await AdminJobService.instance.toggleStatus(sch.id, val, 'scholarship');
                      ref.invalidate(scholarshipsListProvider);
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
                    final updated = await ScholarshipEditDialog.show(context, existingScholarship: sch);
                    if (updated == true) {
                      ref.invalidate(scholarshipsListProvider);
                      ref.invalidate(dashboardMetricsProvider);
                    }
                  },
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: const Text('Edit Scholarship',
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
                      title: 'Delete Scholarship',
                      message: 'Are you sure you want to permanently delete "${sch.title}"?',
                      confirmLabel: 'Delete Scholarship',
                      isDestructive: true,
                    );
                    if (confirm) {
                      await AdminJobService.instance.deleteItem(sch.id, 'scholarship');
                      ref.invalidate(scholarshipsListProvider);
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

  Widget _buildCompactScholarshipsTable(BuildContext context, List<SponsoredJobItem> scholarships) {
    return DataTableCard(
      title: 'International Scholarships (${scholarships.length})',
      subtitle: 'Tabulated layout with bounded cell widths',
      columns: const [
        DataColumn(label: Text('SCHOLARSHIP & INSTITUTION')),
        DataColumn(label: Text('LOCATION')),
        DataColumn(label: Text('COVERAGE / FUNDING')),
        DataColumn(label: Text('DEGREE LEVEL')),
        DataColumn(label: Text('STATUS')),
        DataColumn(label: Text('ACTIONS')),
      ],
      rows: scholarships.map((sch) {
        return DataRow(
          cells: [
            DataCell(
              SizedBox(
                width: 220,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(sch.countryFlag ?? '🎓', style: const TextStyle(fontSize: 18)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            sch.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          Text(
                            sch.companyOrInstitution,
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
                child: Text(sch.location,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12)),
              ),
            ),
            DataCell(
              SizedBox(
                width: 120,
                child: Text(
                  sch.salaryOrFunding ?? 'Fully Funded',
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
                  sch.degreeLevel ?? "Master's",
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            DataCell(
              StatusBadge(
                status: sch.isActive ? 'active' : 'inactive',
                customLabel: sch.isActive ? 'Published' : 'Hidden',
              ),
            ),
            DataCell(
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    tooltip: 'Edit Scholarship',
                    onPressed: () async {
                      final updated = await ScholarshipEditDialog.show(
                        context,
                        existingScholarship: sch,
                      );
                      if (updated == true) ref.invalidate(scholarshipsListProvider);
                    },
                  ),
                  IconButton(
                    icon: Icon(
                      sch.isActive ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      size: 18,
                      color: sch.isActive ? AdminColors.warning : AdminColors.success,
                    ),
                    tooltip: sch.isActive ? 'Unpublish' : 'Publish',
                    onPressed: () async {
                      await AdminJobService.instance.toggleStatus(sch.id, !sch.isActive, 'scholarship');
                      ref.invalidate(scholarshipsListProvider);
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 18, color: AdminColors.danger),
                    tooltip: 'Delete Scholarship',
                    onPressed: () async {
                      final confirm = await ConfirmationDialog.show(
                        context,
                        title: 'Delete Scholarship',
                        message: 'Are you sure you want to delete "${sch.title}"?',
                        confirmLabel: 'Delete',
                        isDestructive: true,
                      );
                      if (confirm) {
                        await AdminJobService.instance.deleteItem(sch.id, 'scholarship');
                        ref.invalidate(scholarshipsListProvider);
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
