import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/admin_theme.dart';
import '../../models/visa_model.dart';
import '../../providers/admin_dashboard_providers.dart';
import '../../services/admin_visa_service.dart';
import '../../widgets/admin_scaffold.dart';
import '../../widgets/confirmation_dialog.dart';
import '../../widgets/data_table_card.dart';
import '../../widgets/search_filter_bar.dart';
import '../../widgets/status_badge.dart';
import 'visa_edit_dialog.dart';

class VisasListScreen extends ConsumerStatefulWidget {
  const VisasListScreen({super.key});

  @override
  ConsumerState<VisasListScreen> createState() => _VisasListScreenState();
}

class _VisasListScreenState extends ConsumerState<VisasListScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'all';
  bool _isTableView = false; // Executive Cards view is default: zero horizontal scroll!

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Color _getCategoryColor(String categoryId) {
    switch (categoryId.toLowerCase()) {
      case 'study':
        return const Color(0xFF1B3A5C);
      case 'work':
        return const Color(0xFF0F766E);
      case 'jobs':
      case 'sponsored_jobs':
        return const Color(0xFF0284C7);
      case 'scholarships':
        return const Color(0xFF7C3AED);
      case 'visit':
      case 'tourist':
        return const Color(0xFFD97706);
      case 'business':
      case 'golden':
        return const Color(0xFFB45309);
      default:
        return AdminColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final visasAsync = ref.watch(
      visasListProvider((
        search: _searchQuery,
        categoryId: _selectedCategory,
        countryId: null,
        isActive: null,
      )),
    );
    final categoriesAsync = ref.watch(visaCategoriesProvider);

    return AdminScaffold(
      title: 'Visa Catalog Management',
      subtitle: 'Manage destination country visas, eligibility criteria, fees, and requirements',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Filter & Action Bar
          categoriesAsync.when(
            loading: () => const LinearProgressIndicator(),
            error: (_, __) => const SizedBox.shrink(),
            data: (categories) {
              final items = [
                const FilterDropdownItem(value: 'all', label: 'All Categories'),
                ...categories.map((c) => FilterDropdownItem(value: c.id, label: c.label)),
              ];

              return SearchFilterBar<String>(
                searchController: _searchController,
                searchHint: 'Search visas by title or destination country...',
                onSearchChanged: (val) => setState(() => _searchQuery = val),
                filterValue: _selectedCategory,
                filterItems: items,
                onFilterChanged: (val) {
                  if (val != null) setState(() => _selectedCategory = val);
                },
                actionLabel: 'New Visa Listing',
                onAction: () async {
                  final created = await VisaEditDialog.show(context);
                  if (created == true) {
                    ref.invalidate(visasListProvider);
                    ref.invalidate(dashboardMetricsProvider);
                  }
                },
                onRefresh: () => ref.invalidate(visasListProvider),
              );
            },
          ),
          const SizedBox(height: 16),

          // Quick Links & View Mode Switcher
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              OutlinedButton.icon(
                onPressed: () => context.go('/visas/categories'),
                icon: const Icon(Icons.category_outlined, size: 16),
                label: const Text('Manage Categories & Taxonomies →'),
              ),
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

          // Visa Listings Content
          visasAsync.when(
            skipLoadingOnReload: true,
            loading: () => const Padding(
              padding: EdgeInsets.all(60),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (err, _) => Card(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text('Error loading visas: $err'),
              ),
            ),
            data: (visas) {
              if (visas.isEmpty) {
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(48),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.flight_takeoff_outlined,
                              size: 48, color: AdminColors.textMuted),
                          const SizedBox(height: 12),
                          const Text(
                            'No Visa Listings Found',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AdminColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Try clearing search or click "New Visa Listing" to publish a destination visa.',
                            style: TextStyle(fontSize: 13, color: AdminColors.textMuted),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () async {
                              final created = await VisaEditDialog.show(context);
                              if (created == true) {
                                ref.invalidate(visasListProvider);
                                ref.invalidate(dashboardMetricsProvider);
                              }
                            },
                            icon: const Icon(Icons.add, size: 16),
                            label: const Text('Create New Visa'),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }

              final total = visas.length;
              final activeCount = visas.where((v) => v.isActive).length;
              final hiddenCount = total - activeCount;
              final categoriesCount = visas.map((v) => v.categoryId).toSet().length;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // KPI Metric Highlights
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth >= 800;
                      return Row(
                        children: [
                          Expanded(
                            child: _buildMetricTile(
                              title: 'Total Visa Listings',
                              value: '$total',
                              icon: Icons.flight_takeoff_rounded,
                              color: AdminColors.primary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildMetricTile(
                              title: 'Live on Mobile App',
                              value: '$activeCount',
                              icon: Icons.check_circle_rounded,
                              color: AdminColors.success,
                            ),
                          ),
                          if (isWide) ...[
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildMetricTile(
                                title: 'Draft / Hidden',
                                value: '$hiddenCount',
                                icon: Icons.visibility_off_outlined,
                                color: AdminColors.warning,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildMetricTile(
                                title: 'Active Categories',
                                value: '$categoriesCount',
                                icon: Icons.category_rounded,
                                color: const Color(0xFF7C3AED),
                              ),
                            ),
                          ],
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 20),

                  // Header with Zero Scroll Guarantee
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Published Visa Catalog ($total)',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AdminColors.textPrimary,
                        ),
                      ),
                      const Text(
                        'All Edit, Publish & Delete action buttons visible — zero horizontal scroll required',
                        style: TextStyle(fontSize: 12, color: AdminColors.textMuted),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Display according to view toggle
                  if (!_isTableView)
                    _buildExecutiveCardsList(context, visas)
                  else
                    _buildCompactTable(context, visas),
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

  Widget _buildExecutiveCardsList(BuildContext context, List<VisaListingItem> visas) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: visas.length,
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemBuilder: (context, idx) {
        final visa = visas[idx];
        return _buildVisaCard(context, visa);
      },
    );
  }

  Widget _buildVisaCard(BuildContext context, VisaListingItem visa) {
    final catColor = _getCategoryColor(visa.categoryId);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: visa.isActive ? AdminColors.border : const Color(0xFFCBD5E1),
          width: visa.isActive ? 1.0 : 1.2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Row: Image Thumbnail + Title + Country + Category + Badges
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Cover Image Thumbnail
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    visa.imageUrl,
                    width: 76,
                    height: 54,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 76,
                      height: 54,
                      color: AdminColors.surfaceMuted,
                      child: const Icon(Icons.flight_takeoff_rounded,
                          size: 24, color: AdminColors.primary),
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // Title, Country, Category
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          // Destination Country Badge
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
                                const Icon(Icons.public_rounded, size: 12, color: AdminColors.primary),
                                const SizedBox(width: 4),
                                Text(
                                  visa.countryName,
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

                          // Category Badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                            decoration: BoxDecoration(
                              color: catColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              visa.categoryName.toUpperCase(),
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                                color: catColor,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ),
                          if (visa.isFeatured) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                              decoration: BoxDecoration(
                                color: AdminColors.accentGold.withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.star_rounded, size: 12, color: Color(0xFFB45309)),
                                  SizedBox(width: 3),
                                  Text(
                                    'FEATURED',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFFB45309),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 6),

                      // Visa Title
                      Text(
                        visa.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w700,
                          color: AdminColors.textPrimary,
                        ),
                      ),
                      if (visa.subtitle != null && visa.subtitle!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          visa.subtitle!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AdminColors.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Metadata Chips Row (Fee, Salary, Processing, Validity, Rating)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _buildInfoChip(
                  icon: Icons.payments_outlined,
                  label: 'Fee: ${visa.fee}',
                  color: AdminColors.primary,
                  isBold: true,
                ),
                if (visa.salary != null && visa.salary!.isNotEmpty)
                  _buildInfoChip(
                    icon: Icons.monetization_on_outlined,
                    label: 'Salary: ${visa.salary!}',
                    color: AdminColors.success,
                    isBold: true,
                  ),
                _buildInfoChip(
                  icon: Icons.timer_outlined,
                  label: 'Processing: ${visa.processingTime}',
                  color: AdminColors.textSecondary,
                ),
                if (visa.validity != null && visa.validity!.isNotEmpty)
                  _buildInfoChip(
                    icon: Icons.calendar_today_outlined,
                    label: 'Validity: ${visa.validity!}',
                    color: AdminColors.textSecondary,
                  ),
                _buildInfoChip(
                  icon: Icons.star_rounded,
                  label: '${visa.rating} ★ (${visa.reviewsCount} reviews)',
                  color: Colors.amber.shade800,
                ),
              ],
            ),
            const SizedBox(height: 14),
            const Divider(height: 1, color: AdminColors.border),
            const SizedBox(height: 10),

            // Bottom Actions Row: 100% VISIBLE WITH ZERO HORIZONTAL SCROLL!
            Row(
              children: [
                // Live Switch with Clear Tooltip
                Tooltip(
                  message: visa.isActive
                      ? 'Click to hide this visa listing from the mobile app'
                      : 'Click to publish this visa listing to the customer mobile app',
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      StatusBadge(
                        status: visa.isActive ? 'active' : 'inactive',
                        customLabel: visa.isActive ? 'Live on Mobile App' : 'Hidden / Draft',
                      ),
                      const SizedBox(width: 8),
                      Transform.scale(
                        scale: 0.8,
                        child: Switch(
                          value: visa.isActive,
                          activeThumbColor: AdminColors.success,
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          onChanged: (val) async {
                            await AdminVisaService.instance.toggleVisaStatus(visa.id, val);
                            ref.invalidate(visasListProvider);
                            ref.invalidate(dashboardMetricsProvider);
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      // 1-Click Feature on Homepage Carousel
                      Tooltip(
                        message: visa.isFeatured
                            ? 'Featured on Homepage Carousel (Click to remove)'
                            : 'Click to feature on customer mobile app homepage carousel',
                        child: InkWell(
                          onTap: () async {
                            await AdminVisaService.instance
                                .toggleVisaFeatured(visa.id, !visa.isFeatured);
                            ref.invalidate(visasListProvider);
                          },
                          borderRadius: BorderRadius.circular(6),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: visa.isFeatured
                                  ? AdminColors.accentGold.withValues(alpha: 0.18)
                                  : AdminColors.surfaceMuted,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: visa.isFeatured
                                    ? AdminColors.accentGold
                                    : AdminColors.border,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  visa.isFeatured
                                      ? Icons.star_rounded
                                      : Icons.star_border_rounded,
                                  size: 15,
                                  color: visa.isFeatured
                                      ? const Color(0xFFB45309)
                                      : AdminColors.textMuted,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  visa.isFeatured
                                      ? 'In Carousel'
                                      : 'Add to Carousel',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: visa.isFeatured
                                        ? const Color(0xFFB45309)
                                        : AdminColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),

                // Edit Visa Details Button
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AdminColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    elevation: 0,
                  ),
                  onPressed: () async {
                    final updated = await VisaEditDialog.show(
                      context,
                      existingVisa: visa,
                    );
                    if (updated == true) {
                      ref.invalidate(visasListProvider);
                      ref.invalidate(dashboardMetricsProvider);
                    }
                  },
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: const Text('Edit Visa Details',
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
                      title: 'Delete Visa Listing',
                      message:
                          'Are you sure you want to permanently delete "${visa.title}"? This listing will be immediately removed from the customer mobile and web catalog.',
                      confirmLabel: 'Delete Listing',
                      isDestructive: true,
                    );
                    if (confirm) {
                      try {
                        await AdminVisaService.instance.deleteVisa(visa.id);
                        ref.invalidate(visasListProvider);
                        ref.invalidate(dashboardMetricsProvider);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Visa listing "${visa.title}" deleted.'),
                              backgroundColor: AdminColors.success,
                            ),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error deleting visa: ${e.toString().replaceAll('Exception: ', '')}'),
                              backgroundColor: AdminColors.danger,
                            ),
                          );
                        }
                      }
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

  Widget _buildCompactTable(BuildContext context, List<VisaListingItem> visas) {
    return DataTableCard(
      title: 'Visa Listings (${visas.length})',
      subtitle: 'Compact tabulated view with bounded column widths',
      columns: const [
        DataColumn(label: Text('COVER')),
        DataColumn(label: Text('TITLE & COUNTRY')),
        DataColumn(label: Text('CATEGORY')),
        DataColumn(label: Text('FEE / SALARY')),
        DataColumn(label: Text('PROCESSING')),
        DataColumn(label: Text('STATUS')),
        DataColumn(label: Text('ACTIONS')),
      ],
      rows: visas.map((visa) {
        return DataRow(
          cells: [
            DataCell(
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.network(
                  visa.imageUrl,
                  width: 44,
                  height: 32,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 44,
                    height: 32,
                    color: AdminColors.surfaceMuted,
                    child: const Icon(Icons.flight, size: 16),
                  ),
                ),
              ),
            ),
            DataCell(
              SizedBox(
                width: 200,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      visa.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                    ),
                    Text(
                      visa.countryName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11, color: AdminColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ),
            DataCell(
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _getCategoryColor(visa.categoryId).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  visa.categoryName,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: _getCategoryColor(visa.categoryId),
                  ),
                ),
              ),
            ),
            DataCell(
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (visa.salary != null && visa.salary!.isNotEmpty)
                    Text(
                      '💰 ${visa.salary!}',
                      style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AdminColors.success,
                          fontSize: 11.5),
                    )
                  else
                    Text(
                      visa.fee,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AdminColors.primary,
                          fontSize: 12),
                    ),
                ],
              ),
            ),
            DataCell(Text(visa.processingTime, style: const TextStyle(fontSize: 12))),
            DataCell(
              StatusBadge(
                status: visa.isActive ? 'active' : 'inactive',
                customLabel: visa.isActive ? 'Published' : 'Hidden',
              ),
            ),
            DataCell(
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    tooltip: 'Edit Visa Details',
                    onPressed: () async {
                      final updated = await VisaEditDialog.show(
                        context,
                        existingVisa: visa,
                      );
                      if (updated == true) {
                        ref.invalidate(visasListProvider);
                        ref.invalidate(dashboardMetricsProvider);
                      }
                    },
                  ),
                  IconButton(
                    icon: Icon(
                      visa.isActive ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      size: 18,
                      color: visa.isActive ? AdminColors.warning : AdminColors.success,
                    ),
                    tooltip: visa.isActive ? 'Unpublish Visa' : 'Publish Visa',
                    onPressed: () async {
                      await AdminVisaService.instance.toggleVisaStatus(visa.id, !visa.isActive);
                      ref.invalidate(visasListProvider);
                      ref.invalidate(dashboardMetricsProvider);
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 18, color: AdminColors.danger),
                    tooltip: 'Delete Visa',
                    onPressed: () async {
                      final confirm = await ConfirmationDialog.show(
                        context,
                        title: 'Delete Visa Listing',
                        message:
                            'Are you sure you want to permanently delete "${visa.title}"?',
                        confirmLabel: 'Delete',
                        isDestructive: true,
                      );
                      if (confirm) {
                        await AdminVisaService.instance.deleteVisa(visa.id);
                        ref.invalidate(visasListProvider);
                        ref.invalidate(dashboardMetricsProvider);
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
