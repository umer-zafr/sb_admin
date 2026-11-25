import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/admin_theme.dart';
import '../../models/admin_banner_model.dart';
import '../../providers/admin_dashboard_providers.dart';
import '../../services/admin_banner_service.dart';
import '../../widgets/admin_scaffold.dart';
import '../../widgets/search_filter_bar.dart';
import 'banner_edit_dialog.dart';

class BannersManagementScreen extends ConsumerStatefulWidget {
  const BannersManagementScreen({super.key});

  @override
  ConsumerState<BannersManagementScreen> createState() => _BannersManagementScreenState();
}

class _BannersManagementScreenState extends ConsumerState<BannersManagementScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _placementFilter = 'all'; // all, visas, jobs, scholarships, study, work, visit, business, golden
  String _statusFilter = 'all'; // all, active, inactive

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool? get _isActiveParam {
    if (_statusFilter == 'active') return true;
    if (_statusFilter == 'inactive') return false;
    return null;
  }

  String? get _placementParam {
    if (_placementFilter == 'all') return null;
    return _placementFilter;
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

  @override
  Widget build(BuildContext context) {
    final bannersAsync = ref.watch(
      bannersListProvider((
        search: _searchQuery,
        placement: _placementParam,
        isActive: _isActiveParam,
      )),
    );

    return AdminScaffold(
      title: 'Advertisement Banners',
      subtitle: 'Manage targeted ad banners for All Visas, Sponsored Jobs, Scholarships, and Category Pages',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filter & Search Bar
          SearchFilterBar<String>(
            searchController: _searchController,
            searchHint: 'Search banners by title, subtitle, placement, or badge...',
            onSearchChanged: (val) => setState(() => _searchQuery = val),
            filterValue: _statusFilter,
            filterItems: const [
              FilterDropdownItem(value: 'all', label: 'All Statuses'),
              FilterDropdownItem(value: 'active', label: 'Live on Mobile App'),
              FilterDropdownItem(value: 'inactive', label: 'Drafts / Inactive'),
            ],
            onFilterChanged: (val) {
              if (val != null) setState(() => _statusFilter = val);
            },
            actionLabel: 'New Ad Banner',
            onAction: () async {
              final created = await BannerEditDialog.show(context);
              if (created == true) {
                ref.read(bannersRevisionProvider.notifier).increment();
                ref.invalidate(
                  bannersListProvider((
                    search: _searchQuery,
                    placement: _placementParam,
                    isActive: _isActiveParam,
                  )),
                );
              }
            },
            onRefresh: () {
              ref.read(bannersRevisionProvider.notifier).increment();
              ref.invalidate(
                bannersListProvider((
                  search: _searchQuery,
                  placement: _placementParam,
                  isActive: _isActiveParam,
                )),
              );
            },
          ),
          const SizedBox(height: 16),

          // Placement Quick-Filter Tabs
          _buildPlacementFilterBar(),
          const SizedBox(height: 20),

          // Banners Content Area
          bannersAsync.when(
            skipLoadingOnReload: true,
            loading: () => const Padding(
              padding: EdgeInsets.all(60),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (err, _) => Card(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text('Error loading advertisement banners: $err'),
              ),
            ),
            data: (banners) {
              final sortedBanners = List<AdminBannerItem>.from(banners)
                ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
              final totalCount = sortedBanners.length;
              final activeCount = sortedBanners.where((b) => b.isActive).length;
              final visasCount = sortedBanners.where((b) => ['visas', 'study', 'work', 'visit', 'business', 'golden'].contains(b.placement)).length;
              final jobsScholarshipsCount = sortedBanners.where((b) => ['jobs', 'scholarships'].contains(b.placement)).length;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // KPI Overview Cards
                  _buildKpiCards(
                    total: totalCount,
                    active: activeCount,
                    visas: visasCount,
                    jobsScholarships: jobsScholarshipsCount,
                  ),
                  const SizedBox(height: 24),

                  if (sortedBanners.isEmpty)
                    _buildEmptyState()
                  else
                    _buildBannersGrid(sortedBanners),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPlacementFilterBar() {
    const tabs = [
      {'key': 'all', 'label': 'All Placements'},
      {'key': 'visas', 'label': 'All Visas'},
      {'key': 'jobs', 'label': 'Sponsored Jobs'},
      {'key': 'scholarships', 'label': 'Scholarships'},
      {'key': 'study', 'label': 'Study Visa'},
      {'key': 'work', 'label': 'Work Visa'},
      {'key': 'visit', 'label': 'Visit Visa'},
      {'key': 'business', 'label': 'Business Visa'},
      {'key': 'golden', 'label': 'Golden Visa'},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: tabs.map((tab) {
          final isSelected = _placementFilter == tab['key'];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(tab['label']!),
              selected: isSelected,
              selectedColor: AdminColors.primary.withValues(alpha: 0.12),
              checkmarkColor: AdminColors.primary,
              labelStyle: TextStyle(
                fontSize: 12.5,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? AdminColors.primary : AdminColors.textPrimary,
              ),
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(
                  color: isSelected ? AdminColors.primary : AdminColors.border,
                ),
              ),
              onSelected: (val) {
                setState(() {
                  _placementFilter = tab['key']!;
                });
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildKpiCards({
    required int total,
    required int active,
    required int visas,
    required int jobsScholarships,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmall = constraints.maxWidth < 800;
        final cardWidth = isSmall ? (constraints.maxWidth - 12) / 2 : (constraints.maxWidth - 36) / 4;

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _buildKpiTile('Total Ad Banners', '$total', Icons.view_carousel_rounded, AdminColors.primary, cardWidth),
            _buildKpiTile('Live on App', '$active', Icons.check_circle_outline_rounded, AdminColors.success, cardWidth),
            _buildKpiTile('Visas Targeted', '$visas', Icons.flight_takeoff_rounded, const Color(0xFF0284C7), cardWidth),
            _buildKpiTile('Jobs & Scholarships', '$jobsScholarships', Icons.work_outline_rounded, const Color(0xFFD97706), cardWidth),
          ],
        );
      },
    );
  }

  Widget _buildKpiTile(String title, String value, IconData icon, Color color, double width) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AdminColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
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
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AdminColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AdminColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBannersGrid(List<AdminBannerItem> banners) {
    final sorted = List<AdminBannerItem>.from(banners)
      ..sort((a, b) {
        if (a.displayOrder != b.displayOrder) {
          return a.displayOrder.compareTo(b.displayOrder);
        }
        final dateA = a.createdAt ?? DateTime(2000);
        final dateB = b.createdAt ?? DateTime(2000);
        return dateB.compareTo(dateA);
      });

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 1150
            ? 3
            : constraints.maxWidth > 750
                ? 2
                : 1;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.34,
          ),
          itemCount: sorted.length,
          itemBuilder: (context, index) {
            final banner = sorted[index];
            return _buildBannerCard(banner);
          },
        );
      },
    );
  }

  Widget _buildBannerCard(AdminBannerItem banner) {
    final startColor = _parseColor(banner.gradientStart, const Color(0xFF1B3A5C));

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: banner.isActive ? AdminColors.border : Colors.grey.shade300,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner Visual Card Preview - Clean Image on Top, Action Button Below
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(13)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Crisp Image Preview with NO text on top
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      color: startColor.withValues(alpha: 0.1),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          if (banner.imageUrl != null && banner.imageUrl!.isNotEmpty)
                            Image.network(
                              banner.imageUrl!,
                              fit: BoxFit.cover,
                              filterQuality: FilterQuality.high,
                              errorBuilder: (_, __, ___) => Center(
                                child: Icon(Icons.broken_image_rounded, size: 36, color: Colors.grey.shade400),
                              ),
                            )
                          else
                            Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.flight_takeoff_rounded, size: 36, color: startColor),
                                  const SizedBox(height: 4),
                                  Text(
                                    banner.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: startColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          // Order and Placement Pill on top right
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.65),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '#${banner.displayOrder} • ${banner.placement.toUpperCase()}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // 2. Navigation Button Row Below Image
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: const BoxDecoration(
                      color: Color(0xFFF8FAFC),
                      border: Border(top: BorderSide(color: Color(0xFFE2E8F0), width: 1)),
                    ),
                    child: SizedBox(
                      height: 32,
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          final updated = await BannerEditDialog.show(
                            context,
                            banner: banner,
                          );
                          if (updated == true) {
                            ref.read(bannersRevisionProvider.notifier).increment();
                            ref.invalidate(bannersListProvider);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: banner.isActive ? const Color(0xFF002444) : Colors.grey.shade700,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.flight_takeoff_rounded,
                              size: 14,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                banner.actionText.isNotEmpty ? banner.actionText : 'Explore Visas',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 11.5,
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.arrow_forward_rounded,
                              size: 12,
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
          ),

          // Bottom Metadata & Actions Bar (Consolidated cohesive row)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Row(
              children: [
                // Target Placement Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AdminColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: AdminColors.primary.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 13,
                        color: AdminColors.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        banner.categoryName,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AdminColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),

                // Live / Draft Switch
                Text(
                  banner.isActive ? 'Active' : 'Draft',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: banner.isActive ? AdminColors.success : Colors.grey,
                  ),
                ),
                const SizedBox(width: 3),
                Transform.scale(
                  scale: 0.72,
                  child: Switch(
                    value: banner.isActive,
                    activeThumbColor: AdminColors.success,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    onChanged: (newVal) async {
                      await AdminBannerService.instance.toggleBannerStatus(
                        banner.id,
                        newVal,
                      );
                      ref.read(bannersRevisionProvider.notifier).increment();
                      ref.invalidate(bannersListProvider);
                    },
                  ),
                ),
                const SizedBox(width: 4),

                // Edit Button
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  tooltip: 'Edit Banner',
                  visualDensity: VisualDensity.compact,
                  splashRadius: 16,
                  onPressed: () async {
                    final updated = await BannerEditDialog.show(
                      context,
                      banner: banner,
                    );
                    if (updated == true) {
                      ref.read(bannersRevisionProvider.notifier).increment();
                      ref.invalidate(bannersListProvider);
                    }
                  },
                ),

                // Delete Button
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, color: AdminColors.danger, size: 16),
                  tooltip: 'Delete Banner',
                  visualDensity: VisualDensity.compact,
                  splashRadius: 16,
                  onPressed: () => _confirmDelete(banner),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(AdminBannerItem banner) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Banner'),
        content: Text('Are you sure you want to permanently remove "${banner.title}" for ${banner.categoryName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AdminColors.danger),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await AdminBannerService.instance.deleteBanner(banner.id);
      ref.read(bannersRevisionProvider.notifier).increment();
      ref.invalidate(bannersListProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Banner deleted successfully'),
            backgroundColor: AdminColors.success,
          ),
        );
      }
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          children: [
            Icon(Icons.view_carousel_outlined, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text(
              'No Advertisement Banners Found',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              _searchQuery.isNotEmpty
                  ? 'No banners matched "$_searchQuery". Try clearing your search.'
                  : 'Get started by creating advertisement banners for Visas, Jobs, or Scholarships.',
              style: const TextStyle(color: AdminColors.textSecondary, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.add_rounded),
              label: const Text('Create First Ad Banner'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AdminColors.primary,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                final created = await BannerEditDialog.show(context);
                if (created == true) {
                  ref.read(bannersRevisionProvider.notifier).increment();
                  ref.invalidate(bannersListProvider);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
