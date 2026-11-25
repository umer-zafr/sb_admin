import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/admin_theme.dart';
import '../../models/affiliate_model.dart';
import '../../providers/admin_dashboard_providers.dart';
import '../../services/admin_affiliate_service.dart';
import '../../widgets/admin_scaffold.dart';
import '../../widgets/confirmation_dialog.dart';
import '../../widgets/empty_state_view.dart';
import '../../widgets/search_filter_bar.dart';
import '../../widgets/stat_card.dart';
import '../../widgets/status_badge.dart';
import 'affiliate_approval_dialog.dart';
import 'affiliate_details_dialog.dart';

class AffiliatesManagementScreen extends ConsumerStatefulWidget {
  const AffiliatesManagementScreen({super.key});

  @override
  ConsumerState<AffiliatesManagementScreen> createState() =>
      _AffiliatesManagementScreenState();
}

class _AffiliatesManagementScreenState
    extends ConsumerState<AffiliatesManagementScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _statusFilter = 'all';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _refresh() {
    ref.read(affiliatesRevisionProvider.notifier).increment();
  }

  @override
  Widget build(BuildContext context) {
    final affiliatesAsync = ref.watch(
      affiliatesListProvider((search: _searchQuery, status: _statusFilter)),
    );

    return AdminScaffold(
      title: 'Affiliate Partners & Promo Codes',
      subtitle:
          'Manage influencer partnerships, assign custom app discount codes, and monitor client referral conversions',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // KPI Stat Cards Row
          affiliatesAsync.maybeWhen(
            data: (affiliates) {
              final total = affiliates.length;
              final pending = affiliates.where((a) => a.isPending).length;
              final approved = affiliates.where((a) => a.isApproved).length;
              final totalReferrals = affiliates.fold<int>(
                0,
                (sum, a) => sum + a.referralCount,
              );
              final totalEarnings = affiliates.fold<double>(
                0.0,
                (sum, a) => sum + a.totalEarnings,
              );

              return Row(
                children: [
                  Expanded(
                    child: StatCard(
                      title: 'Total Partners',
                      value: total.toString(),
                      icon: Icons.people_outline_rounded,
                      color: AdminColors.primary,
                      subtitle: 'Registered influencers',
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: StatCard(
                      title: 'Pending Approvals',
                      value: pending.toString(),
                      icon: Icons.hourglass_top_rounded,
                      color: AdminColors.warning,
                      subtitle: 'Applications in review',
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: StatCard(
                      title: 'Active Promo Codes',
                      value: approved.toString(),
                      icon: Icons.confirmation_number_outlined,
                      color: AdminColors.success,
                      subtitle: 'Live in mobile app',
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: StatCard(
                      title: 'Total App Referrals',
                      value: '$totalReferrals clients',
                      icon: Icons.shopping_bag_outlined,
                      color: AdminColors.info,
                      subtitle: 'PKR ${totalEarnings.toInt()} earned',
                    ),
                  ),
                ],
              );
            },
            orElse: () => const SizedBox.shrink(),
          ),

          const SizedBox(height: 20),

          // Search & Filter Bar
          SearchFilterBar<String>(
            searchController: _searchController,
            searchHint:
                'Search partners by name, email, phone, city, or promo code...',
            onSearchChanged: (val) => setState(() => _searchQuery = val),
            filterValue: _statusFilter,
            filterLabel: 'Status',
            filterItems: const [
              FilterDropdownItem(value: 'all', label: 'All Applications'),
              FilterDropdownItem(value: 'pending', label: 'Pending Review ⏳'),
              FilterDropdownItem(value: 'approved', label: 'Approved Partners ✅'),
              FilterDropdownItem(value: 'rejected', label: 'Rejected ❌'),
            ],
            onFilterChanged: (val) {
              if (val != null) setState(() => _statusFilter = val);
            },
            actionLabel: 'New Partner',
            onAction: () => _showManualAddDialog(context),
            onRefresh: _refresh,
          ),

          const SizedBox(height: 18),

          // Affiliate Records Content
          affiliatesAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (err, stack) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: AdminColors.danger),
                    const SizedBox(height: 12),
                    const Text(
                      'Failed to load affiliate partners',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      err.toString(),
                      style: const TextStyle(fontSize: 13, color: AdminColors.textSecondary),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _refresh,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Try Again'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AdminColors.primary,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            data: (affiliates) {
              if (affiliates.isEmpty) {
                return EmptyStateView(
                  icon: Icons.campaign_outlined,
                  title: 'No affiliate partners found',
                  message: _searchQuery.isNotEmpty
                      ? 'No applications match "$_searchQuery". Try clearing your search.'
                      : 'No affiliate applications registered yet. Forms submitted on your website will appear here in real time.',
                );
              }

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: affiliates.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final item = affiliates[index];
                  return _buildAffiliateCard(context, item);
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAffiliateCard(BuildContext context, AffiliateItem item) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AdminColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Avatar, Name, Email, Followers, Status
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: AdminColors.primary.withValues(alpha: 0.1),
                  child: Text(
                    item.name.isNotEmpty ? item.name[0].toUpperCase() : 'A',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AdminColors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            item.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AdminColors.textPrimary,
                            ),
                          ),
                          const SizedBox(width: 10),
                          StatusBadge(status: item.status),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 12,
                        runSpacing: 4,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.email_outlined, size: 14, color: AdminColors.textMuted),
                              const SizedBox(width: 4),
                              Text(
                                item.email,
                                style: const TextStyle(fontSize: 13, color: AdminColors.textSecondary),
                              ),
                            ],
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.phone_outlined, size: 14, color: AdminColors.textMuted),
                              const SizedBox(width: 4),
                              Text(
                                item.phone,
                                style: const TextStyle(fontSize: 13, color: AdminColors.textSecondary),
                              ),
                            ],
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.location_on_outlined, size: 14, color: AdminColors.textMuted),
                              const SizedBox(width: 4),
                              Text(
                                item.city,
                                style: const TextStyle(fontSize: 13, color: AdminColors.textSecondary),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Followers Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AdminColors.surfaceMuted,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AdminColors.border),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.groups_outlined, size: 16, color: AdminColors.primary),
                      const SizedBox(width: 6),
                      Text(
                        '${item.totalFollowers.toString()} Reach',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AdminColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),
            const Divider(height: 1, color: AdminColors.borderLight),
            const SizedBox(height: 14),

            // Middle Row: Promo Code, Referral Stats, Platforms
            Row(
              children: [
                // Promo Code Box (if approved)
                if (item.isApproved && item.promoCode != null) ...[
                  InkWell(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: item.promoCode!));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Promo code ${item.promoCode} copied!'),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: AdminColors.primary.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AdminColors.primary.withValues(alpha: 0.3),
                          style: BorderStyle.solid,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.confirmation_number_rounded,
                              size: 16, color: AdminColors.primary),
                          const SizedBox(width: 8),
                          Text(
                            item.promoCode!,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: AdminColors.primary,
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.copy_rounded, size: 13, color: AdminColors.primaryLight),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Client Discount Label
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AdminColors.infoBg,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      item.discountType == 'percentage'
                          ? '${item.discountValue.toInt()}% Off in App'
                          : 'PKR ${item.discountValue.toInt()} Off in App',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AdminColors.info,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Referral Count Pill
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AdminColors.successBg,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${item.referralCount} clients • PKR ${item.totalEarnings.toInt()} earned',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AdminColors.success,
                      ),
                    ),
                  ),
                ] else if (item.isPending) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AdminColors.warningBg,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'Awaiting review & promo code assignment',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AdminColors.warning,
                      ),
                    ),
                  ),
                ] else ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AdminColors.dangerBg,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'Application Rejected',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AdminColors.danger,
                      ),
                    ),
                  ),
                ],

                const Spacer(),

                // Action Buttons
                TextButton.icon(
                  onPressed: () => AffiliateDetailsDialog.show(context, affiliate: item),
                  icon: const Icon(Icons.visibility_outlined, size: 16),
                  label: const Text('Details'),
                  style: TextButton.styleFrom(
                    foregroundColor: AdminColors.textSecondary,
                  ),
                ),
                const SizedBox(width: 6),

                if (item.isPending || item.isRejected) ...[
                  ElevatedButton.icon(
                    onPressed: () async {
                      final approved = await AffiliateApprovalDialog.show(
                        context,
                        affiliate: item,
                      );
                      if (approved == true) _refresh();
                    },
                    icon: const Icon(Icons.check_rounded, size: 16),
                    label: const Text('Approve & Assign Code'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AdminColors.success,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  if (item.isPending) ...[
                    const SizedBox(width: 6),
                    OutlinedButton(
                      onPressed: () => _confirmReject(item),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AdminColors.danger,
                        side: const BorderSide(color: AdminColors.border),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Reject'),
                    ),
                  ],
                ] else ...[
                  OutlinedButton.icon(
                    onPressed: () async {
                      final updated = await AffiliateApprovalDialog.show(
                        context,
                        affiliate: item,
                      );
                      if (updated == true) _refresh();
                    },
                    icon: const Icon(Icons.edit_outlined, size: 14),
                    label: const Text('Edit Promo / Rate'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AdminColors.primary,
                      side: const BorderSide(color: AdminColors.border),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],

                const SizedBox(width: 6),
                IconButton(
                  onPressed: () => _confirmDelete(item),
                  icon: const Icon(Icons.delete_outline_rounded, size: 18),
                  color: AdminColors.textMuted,
                  tooltip: 'Delete Partner',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmReject(AffiliateItem item) async {
    final confirmed = await ConfirmationDialog.show(
      context,
      title: 'Reject Application?',
      message: 'Are you sure you want to reject the affiliate application for "${item.name}"?',
      confirmLabel: 'Reject Application',
      isDestructive: true,
    );

    if (!confirmed || !mounted) return;

    try {
      await AdminAffiliateService.instance.rejectAffiliate(item.id);
      _refresh();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to reject: $e'),
          backgroundColor: AdminColors.danger,
        ),
      );
    }
  }

  Future<void> _confirmDelete(AffiliateItem item) async {
    final confirmed = await ConfirmationDialog.show(
      context,
      title: 'Delete Partner Record?',
      message:
          'Are you sure you want to delete the record for "${item.name}"? This action cannot be undone.',
      confirmLabel: 'Delete Forever',
      isDestructive: true,
    );

    if (!confirmed || !mounted) return;

    try {
      await AdminAffiliateService.instance.deleteAffiliate(item.id);
      _refresh();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete: $e'),
          backgroundColor: AdminColors.danger,
        ),
      );
    }
  }

  void _showManualAddDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final cityCtrl = TextEditingController();
    final followersCtrl = TextEditingController(text: '5000');
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Add Affiliate Partner Manually',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: 'Full Name *'),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: emailCtrl,
                    decoration: const InputDecoration(labelText: 'Email Address *'),
                    validator: (v) => v == null || !v.contains('@') ? 'Valid email required' : null,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: phoneCtrl,
                    decoration: const InputDecoration(labelText: 'WhatsApp / Phone *'),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: cityCtrl,
                    decoration: const InputDecoration(labelText: 'City *'),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: followersCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Total Followers Reach'),
                  ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              try {
                await AdminAffiliateService.instance.createManualAffiliate(
                  name: nameCtrl.text.trim(),
                  email: emailCtrl.text.trim(),
                  phone: phoneCtrl.text.trim(),
                  city: cityCtrl.text.trim(),
                  totalFollowers: int.tryParse(followersCtrl.text.trim()) ?? 0,
                );
                if (ctx.mounted) Navigator.of(ctx).pop();
                _refresh();
              } catch (e) {
                if (ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(content: Text('Error: $e'), backgroundColor: AdminColors.danger),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AdminColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Add Partner'),
          ),
        ],
      ),
    );
  }
}
