import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/theme/admin_theme.dart';
import '../../providers/admin_dashboard_providers.dart';
import '../../widgets/admin_scaffold.dart';
import '../../widgets/data_table_card.dart';
import '../../widgets/search_filter_bar.dart';
import '../../widgets/status_badge.dart';

class UsersListScreen extends ConsumerStatefulWidget {
  const UsersListScreen({super.key});

  @override
  ConsumerState<UsersListScreen> createState() => _UsersListScreenState();
}

class _UsersListScreenState extends ConsumerState<UsersListScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _roleFilter = 'all';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(
      usersListProvider((search: _searchQuery, role: _roleFilter)),
    );

    return AdminScaffold(
      title: 'Client Directory',
      subtitle:
          'Directory of registered client profiles and applicants. To grant administrative privileges, navigate to Team & Permissions.',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Search & Filter Header Bar
          SearchFilterBar<String>(
            searchController: _searchController,
            searchHint: 'Search clients by name, email, or phone...',
            onSearchChanged: (val) {
              setState(() => _searchQuery = val);
            },
            filterValue: _roleFilter,
            filterLabel: 'Account Type',
            filterItems: const [
              FilterDropdownItem(value: 'all', label: 'All Registered Accounts'),
              FilterDropdownItem(value: 'user', label: 'Clients / Applicants Only'),
              FilterDropdownItem(value: 'admin', label: 'Administrators'),
              FilterDropdownItem(value: 'consultant', label: 'Consultants / Staff'),
            ],
            onFilterChanged: (val) {
              if (val != null) setState(() => _roleFilter = val);
            },
            onRefresh: () {
              ref.invalidate(usersListProvider);
            },
          ),
          const SizedBox(height: 20),

          // Users Table Card
          usersAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(60),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (err, _) => Card(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text('Error loading users: $err'),
              ),
            ),
            data: (users) {
              return DataTableCard(
                title: 'Client Profiles (${users.length})',
                subtitle: 'All profiles stored securely in Supabase PostgreSQL',
                columns: const [
                  DataColumn(label: Text('CLIENT')),
                  DataColumn(label: Text('CONTACT')),
                  DataColumn(label: Text('ACCOUNT TYPE')),
                  DataColumn(label: Text('APPLICATIONS')),
                  DataColumn(label: Text('REGISTERED')),
                  DataColumn(label: Text('ACTION')),
                ],
                rows: users.map((u) {
                  return DataRow(
                    cells: [
                      // User Identity
                      DataCell(
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: AdminColors.primaryLight,
                              child: Text(
                                (u.fullName?.isNotEmpty ?? false)
                                    ? u.fullName![0].toUpperCase()
                                    : 'U',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            SizedBox(
                              width: 170,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    u.fullName ?? 'Client Profile',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                  ),
                                  Text(
                                    u.email,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AdminColors.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Phone
                      DataCell(Text(u.phone ?? '—', style: const TextStyle(fontSize: 12))),
                      // Role Badge
                      DataCell(StatusBadge(status: u.role)),
                      // Applications count
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AdminColors.surfaceMuted,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${u.applicationsCount} Apps',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      // Registered Date
                      DataCell(
                        Text(
                          DateFormat('dd MMM yyyy').format(u.createdAt),
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                      // Actions (View Dossier only - NO admin promotion here!)
                      DataCell(
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            backgroundColor: AdminColors.primary,
                          ),
                          onPressed: () => context.go('/users/${u.id}'),
                          icon: const Icon(Icons.folder_shared_outlined, size: 14),
                          label: const Text('View Profile →', style: TextStyle(fontSize: 12)),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}
