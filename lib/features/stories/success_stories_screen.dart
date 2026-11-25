import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/admin_theme.dart';
import '../../models/admin_success_story_model.dart';
import '../../providers/admin_dashboard_providers.dart';
import '../../services/admin_success_story_service.dart';
import '../../widgets/admin_scaffold.dart';
import '../../widgets/search_filter_bar.dart';
import 'success_story_edit_dialog.dart';

class SuccessStoriesScreen extends ConsumerStatefulWidget {
  const SuccessStoriesScreen({super.key});

  @override
  ConsumerState<SuccessStoriesScreen> createState() => _SuccessStoriesScreenState();
}

class _SuccessStoriesScreenState extends ConsumerState<SuccessStoriesScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _publishFilter = 'all'; // all, published, draft

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool? get _isPublishedParam {
    if (_publishFilter == 'published') return true;
    if (_publishFilter == 'draft') return false;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final storiesAsync = ref.watch(
      successStoriesListProvider((search: _searchQuery, isPublished: _isPublishedParam)),
    );

    return AdminScaffold(
      title: 'Success Stories & Approvals',
      subtitle: 'Manage client visa approvals and testimonials displayed on mobile app home screen',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filter & Search Bar
          SearchFilterBar<String>(
            searchController: _searchController,
            searchHint: 'Search stories by client name, visa category, or country...',
            onSearchChanged: (val) => setState(() => _searchQuery = val),
            filterValue: _publishFilter,
            filterItems: const [
              FilterDropdownItem(value: 'all', label: 'All Stories'),
              FilterDropdownItem(value: 'published', label: 'Live on Mobile App'),
              FilterDropdownItem(value: 'draft', label: 'Hidden / Drafts'),
            ],
            onFilterChanged: (val) {
              if (val != null) setState(() => _publishFilter = val);
            },
            actionLabel: 'New Success Story',
            onAction: () async {
              final created = await SuccessStoryEditDialog.show(context);
              if (created == true) {
                ref.read(successStoriesRevisionProvider.notifier).increment();
                ref.invalidate(
                  successStoriesListProvider((search: _searchQuery, isPublished: _isPublishedParam)),
                );
              }
            },
            onRefresh: () {
              ref.read(successStoriesRevisionProvider.notifier).increment();
              ref.invalidate(
                successStoriesListProvider((search: _searchQuery, isPublished: _isPublishedParam)),
              );
            },
          ),
          const SizedBox(height: 20),

          // Stories Content Area
          storiesAsync.when(
            skipLoadingOnReload: true,
            loading: () => const Padding(
              padding: EdgeInsets.all(60),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (err, _) => Card(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text('Error loading success stories: $err'),
              ),
            ),
            data: (stories) {
              final totalCount = stories.length;
              final publishedCount = stories.where((s) => s.isPublished).length;
              final avgRating = stories.isNotEmpty
                  ? (stories.map((s) => s.rating).reduce((a, b) => a + b) / stories.length)
                  : 5.0;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // KPI Stat Cards Row
                  Row(
                    children: [
                      Expanded(
                        child: _buildKpiCard(
                          icon: Icons.auto_stories_rounded,
                          label: 'Total Success Stories',
                          value: totalCount.toString(),
                          color: AdminColors.primary,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildKpiCard(
                          icon: Icons.check_circle_rounded,
                          label: 'Live on App Home Screen',
                          value: publishedCount.toString(),
                          color: AdminColors.success,
                          subtitle: '$publishedCount visible to clients',
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildKpiCard(
                          icon: Icons.star_rounded,
                          label: 'Average Client Rating',
                          value: '${avgRating.toStringAsFixed(1)} ★',
                          color: Colors.amber.shade700,
                          subtitle: 'Verified client reviews',
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildKpiCard(
                          icon: Icons.speed_rounded,
                          label: 'Realtime Sync',
                          value: 'Instant Push',
                          color: Colors.deepPurple,
                          subtitle: 'Zero delay mobile refresh',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  if (stories.isEmpty)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(48),
                        child: Center(
                          child: Column(
                            children: [
                              const Icon(Icons.stars_outlined, size: 48, color: AdminColors.textSecondary),
                              const SizedBox(height: 12),
                              const Text(
                                'No Success Stories Found',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Click "New Success Story" to publish a client visa approval testimonial.',
                                style: TextStyle(color: AdminColors.textSecondary),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: () => SuccessStoryEditDialog.show(context),
                                icon: const Icon(Icons.add_rounded),
                                label: const Text('Add First Success Story'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  else
                    // Grid of Success Story Cards
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final crossAxisCount = constraints.maxWidth > 1200
                            ? 3
                            : (constraints.maxWidth > 800 ? 2 : 1);

                        return GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: crossAxisCount,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            mainAxisExtent: 252,
                          ),
                          itemCount: stories.length,
                          itemBuilder: (context, index) {
                            final story = stories[index];
                            return _buildStoryCard(context, story);
                          },
                        );
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

  Widget _buildKpiCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    String? subtitle,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(fontSize: 12, color: AdminColors.textSecondary),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w500),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStoryCard(BuildContext context, AdminSuccessStoryItem story) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: story.isPublished ? AdminColors.border : AdminColors.border.withValues(alpha: 0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Avatar + Name + Status Tag
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AdminColors.primary.withValues(alpha: 0.1),
                  backgroundImage: story.avatarUrl != null && story.avatarUrl!.isNotEmpty
                      ? NetworkImage(story.avatarUrl!)
                      : null,
                  child: story.avatarUrl == null || story.avatarUrl!.isEmpty
                      ? Text(
                          story.clientName.isNotEmpty ? story.clientName[0].toUpperCase() : 'C',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        )
                      : null,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              story.clientName,
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.verified_rounded, size: 14, color: AdminColors.success),
                        ],
                      ),
                      Text(
                        story.universityOrEmployer ?? '${story.countryFlag} ${story.countryName}',
                        style: const TextStyle(fontSize: 11, color: AdminColors.textSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                  decoration: BoxDecoration(
                    color: story.isPublished
                        ? AdminColors.success.withValues(alpha: 0.1)
                        : AdminColors.textMuted.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    story.isPublished ? 'LIVE' : 'DRAFT',
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.bold,
                      color: story.isPublished ? AdminColors.success : AdminColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Visa & Country Info
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4.5),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  Text(story.countryFlag, style: const TextStyle(fontSize: 13)),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      '${story.countryName} • ${story.visaType}',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (story.processingTime != null && story.processingTime!.isNotEmpty) ...[
                    const SizedBox(width: 4),
                    Text(
                      story.processingTime!,
                      style: const TextStyle(fontSize: 10, color: AdminColors.textSecondary),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Testimonial Quote in encapsulated bubble
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE2E8F0), width: 0.8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.format_quote_rounded,
                      size: 15,
                      color: AdminColors.primary,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        story.quote,
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontStyle: FontStyle.italic,
                          color: Color(0xFF334155),
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Bottom Actions: Star Rating & Publish Toggle & Buttons
            const Divider(height: 1, color: AdminColors.border),
            const SizedBox(height: 6),
            Row(
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star_rounded, size: 15, color: Colors.amber),
                    const SizedBox(width: 3),
                    Text(
                      story.rating.toStringAsFixed(1),
                      style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
                const Spacer(),
                // Fast Live Toggle
                Tooltip(
                  message: story.isPublished ? 'Click to hide from mobile app' : 'Click to publish to mobile app',
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        story.isPublished ? 'App Visible' : 'Hidden',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: story.isPublished ? AdminColors.success : AdminColors.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 3),
                      Transform.scale(
                        scale: 0.75,
                        child: Switch(
                          value: story.isPublished,
                          activeThumbColor: AdminColors.success,
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          onChanged: (val) async {
                            await AdminSuccessStoryService.instance.togglePublish(story.id, val);
                            if (!mounted) return;
                            ref.read(successStoriesRevisionProvider.notifier).increment();
                            ref.invalidate(
                              successStoriesListProvider((search: _searchQuery, isPublished: _isPublishedParam)),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 2),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  tooltip: 'Edit Story',
                  visualDensity: VisualDensity.compact,
                  onPressed: () async {
                    final updated = await SuccessStoryEditDialog.show(context, story: story);
                    if (updated == true && mounted) {
                      ref.read(successStoriesRevisionProvider.notifier).increment();
                      ref.invalidate(
                        successStoriesListProvider((search: _searchQuery, isPublished: _isPublishedParam)),
                      );
                    }
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, size: 16, color: AdminColors.danger),
                  tooltip: 'Delete Story',
                  visualDensity: VisualDensity.compact,
                  onPressed: () => _confirmDelete(story),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(AdminSuccessStoryItem story) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Success Story?'),
        content: Text(
          'Are you sure you want to delete the approval story for "${story.clientName}"? This will immediately remove it from the mobile app.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AdminColors.danger),
            onPressed: () async {
              Navigator.of(ctx).pop();
              await AdminSuccessStoryService.instance.deleteStory(story.id);
              if (!mounted) return;
              ref.read(successStoriesRevisionProvider.notifier).increment();
              ref.invalidate(
                successStoriesListProvider((search: _searchQuery, isPublished: _isPublishedParam)),
              );
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Success story deleted'),
                  backgroundColor: AdminColors.info,
                ),
              );
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
