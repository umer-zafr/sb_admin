import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/theme/admin_theme.dart';
import '../../models/feedback_model.dart';
import '../../providers/admin_feedback_provider.dart';
import '../../widgets/admin_scaffold.dart';
import '../../widgets/search_filter_bar.dart';

class FeedbackListScreen extends ConsumerStatefulWidget {
  const FeedbackListScreen({super.key});

  @override
  ConsumerState<FeedbackListScreen> createState() => _FeedbackListScreenState();
}

class _FeedbackListScreenState extends ConsumerState<FeedbackListScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  int? _ratingFilter;

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
    final feedbackAsync = ref.watch(
      adminFeedbackListProvider((
        search: _searchQuery,
        rating: _ratingFilter,
      )),
    );

    return AdminScaffold(
      title: 'Customer Feedback & Reviews',
      subtitle:
          'Monitor client satisfaction, star ratings, and detailed experience reviews submitted from mobile apps',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Filter Bar
          SearchFilterBar<String>(
            searchController: _searchController,
            searchHint:
                'Search feedback by user name, email, visa title, or comment...',
            onSearchChanged: (val) => setState(() => _searchQuery = val),
            filterValue: _ratingFilter == null ? 'all' : '$_ratingFilter',
            filterLabel: 'Rating',
            filterItems: const [
              FilterDropdownItem(value: 'all', label: 'All Ratings'),
              FilterDropdownItem(value: '5', label: '5 Stars ★★★★★'),
              FilterDropdownItem(value: '4', label: '4 Stars ★★★★'),
              FilterDropdownItem(value: '3', label: '3 Stars ★★★'),
              FilterDropdownItem(value: '2', label: '2 Stars ★★'),
              FilterDropdownItem(value: '1', label: '1 Star ★'),
            ],
            onFilterChanged: (val) {
              setState(() {
                if (val == null || val == 'all') {
                  _ratingFilter = null;
                } else {
                  _ratingFilter = int.tryParse(val);
                }
              });
            },
            onRefresh: () => ref.invalidate(adminFeedbackListProvider),
          ),
          const SizedBox(height: 20),

          // Feedback List Content
          feedbackAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(60),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (err, _) => Card(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text('Error loading feedback: $err'),
              ),
            ),
            data: (items) {
              if (items.isEmpty) {
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(48),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.rate_review_outlined,
                              size: 48, color: AdminColors.textMuted),
                          const SizedBox(height: 12),
                          const Text(
                            'No client feedback found',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AdminColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Client feedback submitted from mobile apps will appear here with complete details.',
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
              final totalCount = items.length;
              final avgRating =
                  items.fold<double>(0, (sum, item) => sum + item.rating) /
                      totalCount;
              final fiveStarCount =
                  items.where((i) => i.rating == 5).length;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Metric Highlights
                  Row(
                    children: [
                      Expanded(
                        child: _buildMetricTile(
                          title: 'Total Reviews',
                          value: '$totalCount',
                          icon: Icons.reviews_rounded,
                          color: AdminColors.primary,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: _buildMetricTile(
                          title: 'Average Rating',
                          value: '${avgRating.toStringAsFixed(1)} / 5.0',
                          icon: Icons.star_rounded,
                          color: const Color(0xFFD97706),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: _buildMetricTile(
                          title: '5-Star Feedback',
                          value:
                              '$fiveStarCount (${((fiveStarCount / totalCount) * 100).toStringAsFixed(0)}%)',
                          icon: Icons.thumb_up_rounded,
                          color: const Color(0xFF16A34A),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // Feedback Cards List
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 14),
                    itemBuilder: (context, idx) {
                      final item = items[idx];
                      return _buildFeedbackCard(context, item);
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

  Widget _buildFeedbackCard(BuildContext context, AdminFeedbackItem item) {
    final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AdminColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Rating Stars + Standout Tag + Date
            Row(
              children: [
                // Star display
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(
                    5,
                    (starIdx) => Icon(
                      starIdx < item.rating
                          ? Icons.star_rounded
                          : Icons.star_border_rounded,
                      color: const Color(0xFFF59E0B),
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '${item.rating}.0',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: Color(0xFFB45309),
                  ),
                ),
                const SizedBox(width: 12),

                // Standout Tag Pill
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF16A34A).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFF16A34A).withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.verified_rounded,
                          size: 13, color: Color(0xFF16A34A)),
                      const SizedBox(width: 4),
                      Text(
                        item.standoutTag,
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF16A34A),
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // Date/Time
                Icon(Icons.schedule_rounded,
                    size: 14, color: AdminColors.textMuted),
                const SizedBox(width: 4),
                Text(
                  dateFormat.format(item.createdAt.toLocal()),
                  style: const TextStyle(
                    fontSize: 12,
                    color: AdminColors.textMuted,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Client Identification Row (Name, Email, Phone, Visa Title, Ref)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AdminColors.surfaceMuted,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Wrap(
                spacing: 20,
                runSpacing: 10,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  // Client Name
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.person_rounded,
                          size: 16, color: AdminColors.primary),
                      const SizedBox(width: 6),
                      Text(
                        item.effectiveName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13.5,
                          color: AdminColors.textPrimary,
                        ),
                      ),
                    ],
                  ),

                  // Client Email (with Copy)
                  InkWell(
                    onTap: () => _copy(item.effectiveEmail, 'Email'),
                    borderRadius: BorderRadius.circular(4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.email_outlined,
                            size: 15, color: AdminColors.textMuted),
                        const SizedBox(width: 6),
                        Text(
                          item.effectiveEmail,
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: AdminColors.textSecondary,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.copy_rounded,
                            size: 12, color: AdminColors.textMuted),
                      ],
                    ),
                  ),

                  // Client Phone (with Copy)
                  if (item.effectivePhone != 'No phone')
                    InkWell(
                      onTap: () => _copy(item.effectivePhone, 'Phone'),
                      borderRadius: BorderRadius.circular(4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.phone_outlined,
                              size: 15, color: AdminColors.textMuted),
                          const SizedBox(width: 6),
                          Text(
                            item.effectivePhone,
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: AdminColors.textSecondary,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.copy_rounded,
                              size: 12, color: AdminColors.textMuted),
                        ],
                      ),
                    ),

                  // Associated Visa Title
                  if (item.visaTitle != null)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.flight_takeoff_rounded,
                            size: 15, color: AdminColors.primary),
                        const SizedBox(width: 6),
                        Text(
                          item.visaTitle!,
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: AdminColors.primary,
                          ),
                        ),
                      ],
                    ),

                  // App Reference Chip
                  if (item.appReference != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AdminColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        item.appReference!,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AdminColors.primary,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Client Comment in Quote Box
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border(
                  left: BorderSide(
                    color: const Color(0xFFF59E0B),
                    width: 4,
                  ),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'CLIENT EXPERIENCE & REVIEW:',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFFB45309),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.comments.isNotEmpty
                        ? '"${item.comments}"'
                        : '"Client completed the case and awarded a 5-star rating."',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AdminColors.textPrimary,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),

            // Navigation to Application if linked
            if (item.applicationId != null && item.applicationId!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  style: TextButton.styleFrom(
                    foregroundColor: AdminColors.primary,
                    textStyle: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 12.5,
                    ),
                  ),
                  icon: const Icon(Icons.folder_shared_outlined, size: 16),
                  label: const Text('View Linked Application Dossier →'),
                  onPressed: () =>
                      context.go('/applications/${item.applicationId}'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
