import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/theme/admin_theme.dart';
import '../../providers/admin_auth_provider.dart';
import '../../providers/admin_dashboard_providers.dart';
import '../../services/admin_user_service.dart';
import '../../widgets/admin_scaffold.dart';
import '../../widgets/data_table_card.dart';
import '../../widgets/status_badge.dart';

class UserDetailScreen extends ConsumerStatefulWidget {
  const UserDetailScreen({super.key, required this.userId});

  final String userId;

  @override
  ConsumerState<UserDetailScreen> createState() => _UserDetailScreenState();
}

class _UserDetailScreenState extends ConsumerState<UserDetailScreen> {
  final _noteController = TextEditingController();
  bool _isAddingNote = false;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _handleAddNote() async {
    final text = _noteController.text.trim();
    if (text.isEmpty) return;

    setState(() => _isAddingNote = true);
    try {
      await AdminUserService.instance.addAdminNote(widget.userId, text);
      _noteController.clear();
      ref.invalidate(userDetailProvider(widget.userId));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Internal note added successfully.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isAddingNote = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(adminAuthProvider);
    final isCurrentAdmin =
        authState is AdminAuthAuthenticated && authState.profile.isAdmin;

    final detailAsync = ref.watch(userDetailProvider(widget.userId));

    return AdminScaffold(
      title: 'Client Profile Dossier',
      subtitle:
          'Comprehensive record of personal identity, visa applications, client documents, and staff notes',
      body: detailAsync.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(60),
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (err, _) => Center(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Text('Error loading user profile: $err'),
            ),
          ),
        ),
        data: (data) {
          final profile = data.profile;
          final tabCount = isCurrentAdmin ? 4 : 3;

          return DefaultTabController(
            length: tabCount,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Back Button & Action Bar
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => context.go('/users'),
                      icon: const Icon(Icons.arrow_back, size: 16),
                      label: const Text('Back to Clients'),
                    ),
                    const Spacer(),
                    StatusBadge(status: profile.role),
                    const SizedBox(width: 8),
                    if (profile.isVerified)
                      const StatusBadge(
                          status: 'verified', customLabel: 'Identity Verified'),
                  ],
                ),
                const SizedBox(height: 16),

                // Profile Header Card (Purely Client identity - no admin promotion here)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 36,
                          backgroundColor: AdminColors.primary,
                          child: Text(
                            (profile.fullName?.isNotEmpty ?? false)
                                ? profile.fullName![0].toUpperCase()
                                : 'U',
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      profile.fullName ?? 'Verified Client',
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
                                      borderRadius: BorderRadius.circular(4),
                                      border:
                                          Border.all(color: AdminColors.border),
                                    ),
                                    child: Text(
                                      'ID: ${profile.id.substring(0, 8)}...',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontFamily: 'monospace',
                                        color: AdminColors.textSecondary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 16,
                                runSpacing: 6,
                                children: [
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.email_outlined,
                                          size: 15,
                                          color: AdminColors.textMuted),
                                      const SizedBox(width: 6),
                                      Text(profile.email,
                                          style:
                                              const TextStyle(fontSize: 13)),
                                    ],
                                  ),
                                  if (profile.phone != null)
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.phone_outlined,
                                            size: 15,
                                            color: AdminColors.textMuted),
                                        const SizedBox(width: 6),
                                        Text(profile.phone!,
                                            style:
                                                const TextStyle(fontSize: 13)),
                                      ],
                                    ),
                                  if (profile.nationality != null)
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.flag_outlined,
                                            size: 15,
                                            color: AdminColors.textMuted),
                                        const SizedBox(width: 6),
                                        Text(profile.nationality!,
                                            style:
                                                const TextStyle(fontSize: 13)),
                                      ],
                                    ),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.calendar_today_outlined,
                                          size: 15,
                                          color: AdminColors.textMuted),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Member since ${DateFormat('MMM yyyy').format(profile.createdAt)}',
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Detail Navigation Tabs (Consultancy Calls removed; Payments restricted to Super Admin)
                Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      bottom: BorderSide(color: AdminColors.border, width: 1),
                    ),
                  ),
                  child: TabBar(
                    isScrollable: true,
                    labelColor: AdminColors.primary,
                    unselectedLabelColor: AdminColors.textSecondary,
                    indicatorColor: AdminColors.primary,
                    indicatorWeight: 3,
                    tabs: [
                      Tab(text: 'Applications (${data.applications.length})'),
                      if (isCurrentAdmin)
                        Tab(text: 'Payments (${data.payments.length})'),
                      Tab(text: 'Documents (${data.documents.length})'),
                      Tab(text: 'Internal Staff Notes (${data.notes.length})'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Tab View Content
                SizedBox(
                  height: 520,
                  child: TabBarView(
                    children: [
                      // 1. Applications Tab
                      DataTableCard(
                        title: 'Client Visa Applications',
                        subtitle:
                            'Active applications and procedures tracked through Supabase',
                        columns: const [
                          DataColumn(label: Text('REFERENCE')),
                          DataColumn(label: Text('SERVICE')),
                          DataColumn(label: Text('STEPPER PROGRESS')),
                          DataColumn(label: Text('STATUS')),
                          DataColumn(label: Text('APPLIED')),
                          DataColumn(label: Text('ACTION')),
                        ],
                        rows: data.applications.map((app) {
                          return DataRow(
                            cells: [
                              DataCell(Text(app.referenceNumber,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700))),
                              DataCell(
                                SizedBox(
                                  width: 200,
                                  child: Text(
                                    app.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                              DataCell(Text(
                                  '${app.stepText} (${app.progressPercent}%)')),
                              DataCell(StatusBadge(status: app.status)),
                              DataCell(Text(DateFormat('dd MMM yyyy')
                                  .format(app.appliedAt))),
                              DataCell(
                                OutlinedButton(
                                  onPressed: () =>
                                      context.go('/applications/${app.id}'),
                                  child: const Text('Open Dossier →'),
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),

                      // 2. Payments Tab (Only present if Super Admin)
                      if (isCurrentAdmin)
                        DataTableCard(
                          title: 'Financial Transactions',
                          subtitle:
                              'PayFast, card, and manual payments recorded in Supabase',
                          columns: const [
                            DataColumn(label: Text('TRANSACTION ID')),
                            DataColumn(label: Text('METHOD')),
                            DataColumn(label: Text('AMOUNT')),
                            DataColumn(label: Text('STATUS')),
                            DataColumn(label: Text('DATE')),
                          ],
                          rows: data.payments.map((p) {
                            return DataRow(
                              cells: [
                                DataCell(Text(p.transactionId,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w700))),
                                DataCell(Text(p.displayPaymentMethod)),
                                DataCell(Text(
                                    'PKR ${p.amount.toStringAsFixed(0)}',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w700))),
                                DataCell(StatusBadge(status: p.status)),
                                DataCell(Text(DateFormat('dd MMM yyyy')
                                    .format(p.createdAt))),
                              ],
                            );
                          }).toList(),
                        ),

                      // 3. Documents Tab
                      DataTableCard(
                        title: 'Uploaded Client Documents',
                        subtitle:
                            'Passports, degree certificates, and financial statements',
                        columns: const [
                          DataColumn(label: Text('DOCUMENT TITLE')),
                          DataColumn(label: Text('TYPE')),
                          DataColumn(label: Text('FILE SIZE')),
                          DataColumn(label: Text('STATUS')),
                          DataColumn(label: Text('UPLOADED')),
                        ],
                        rows: data.documents.map((d) {
                          return DataRow(
                            cells: [
                              DataCell(
                                SizedBox(
                                  width: 200,
                                  child: Text(
                                    d.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                              DataCell(Text(
                                  d.documentType?.toUpperCase() ?? 'DOCUMENT')),
                              DataCell(Text(d.formattedSize)),
                              DataCell(StatusBadge(status: d.status)),
                              DataCell(Text(DateFormat('dd MMM yyyy')
                                  .format(d.createdAt))),
                            ],
                          );
                        }).toList(),
                      ),

                      // 4. Internal Staff Notes Tab
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
                                        hintText:
                                            'Add an internal administrative note about this user (private to staff)...',
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  ElevatedButton.icon(
                                    onPressed:
                                        _isAddingNote ? null : _handleAddNote,
                                    icon: const Icon(Icons.add_comment_outlined,
                                        size: 16),
                                    label: const Text('Add Note'),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              Expanded(
                                child: data.notes.isEmpty
                                    ? const Center(
                                        child: Text(
                                          'No internal notes added yet. Use the input above to record confidential case observations.',
                                          style: TextStyle(
                                              color: AdminColors.textMuted),
                                        ),
                                      )
                                    : ListView.separated(
                                        itemCount: data.notes.length,
                                        separatorBuilder: (_, __) =>
                                            const Divider(),
                                        itemBuilder: (context, idx) {
                                          final n = data.notes[idx];
                                          return ListTile(
                                            leading: const CircleAvatar(
                                              backgroundColor:
                                                  AdminColors.primaryLight,
                                              child: Icon(
                                                  Icons.admin_panel_settings,
                                                  color: Colors.white,
                                                  size: 18),
                                            ),
                                            title: Text(n.note,
                                                style: const TextStyle(
                                                    fontSize: 13.5)),
                                            subtitle: Text(
                                              'Added by ${n.authorName ?? 'Admin'} • ${DateFormat('dd MMM yyyy, hh:mm a').format(n.createdAt.toLocal())}',
                                              style: const TextStyle(
                                                  fontSize: 11,
                                                  color: AdminColors.textMuted),
                                            ),
                                          );
                                        },
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
          );
        },
      ),
    );
  }
}
