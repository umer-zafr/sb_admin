import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/theme/admin_theme.dart';
import '../../providers/admin_auth_provider.dart';
import '../../providers/admin_dashboard_providers.dart';
import '../../widgets/admin_scaffold.dart';
import '../../widgets/data_table_card.dart';
import '../../widgets/stat_card.dart';
import '../../widgets/status_badge.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(adminAuthProvider);
    final isAdmin =
        authState is AdminAuthAuthenticated && authState.profile.isAdmin;

    final metricsAsync = ref.watch(dashboardMetricsProvider);
    final currencyFormat =
        NumberFormat.currency(symbol: 'PKR ', decimalDigits: 0);

    return AdminScaffold(
      title: 'Operational Dashboard',
      subtitle:
          'Real-time overview of immigration cases, visa catalog, and active client pipeline',
      body: metricsAsync.when(
        skipLoadingOnReload: true,
        loading: () => const Padding(
          padding: EdgeInsets.all(60),
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (err, _) => Center(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text('Error loading dashboard: $err'),
            ),
          ),
        ),
        data: (metrics) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Quick Action Banner
              LayoutBuilder(
                builder: (context, constraints) {
                  final isCompact = constraints.maxWidth < 800;

                  return Card(
                    color: AdminColors.primary,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                      child: Flex(
                        direction: isCompact ? Axis.vertical : Axis.horizontal,
                        crossAxisAlignment: isCompact ? CrossAxisAlignment.start : CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            flex: isCompact ? 0 : 1,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isAdmin
                                      ? 'Welcome to SB Consultants Command Center'
                                      : 'SB Consultants Staff Operational Console',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'You have ${metrics.pendingApplications} pending visa applications requiring administrative review.',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFFCBD5E1),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isCompact) const SizedBox(height: 16),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: [
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AdminColors.accentGold,
                                  foregroundColor: AdminColors.primaryDark,
                                ),
                                onPressed: () => context.go('/visas'),
                                icon: const Icon(Icons.add, size: 16),
                                label: const Text('New Visa Listing'),
                              ),
                              OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  side: const BorderSide(color: Color(0xFF475569)),
                                ),
                                onPressed: () => context.go('/applications'),
                                icon: const Icon(Icons.assignment_outlined, size: 16),
                                label: const Text('Review Applications'),
                              ),
                              if (isAdmin)
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF0F766E),
                                    foregroundColor: Colors.white,
                                  ),
                                  onPressed: () => context.go('/team'),
                                  icon: const Icon(Icons.security, size: 16),
                                  label: const Text('Manage Team'),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),

              // KPI Stats Grid (Row of 4 on desktop)
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 900;
                  final crossAxisCount = isWide ? 4 : 2;

                  return GridView.count(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    childAspectRatio: isWide ? 1.45 : 1.25,
                    children: [
                      StatCard(
                        title: 'TOTAL REGISTERED CLIENTS',
                        value: '${metrics.totalUsers}',
                        icon: Icons.people_outline_rounded,
                        subtitle: 'Synchronized with Supabase Auth',
                        color: AdminColors.primary,
                        onTap: () => context.go('/users'),
                      ),
                      StatCard(
                        title: 'VISA APPLICATIONS',
                        value: '${metrics.totalApplications}',
                        icon: Icons.assignment_outlined,
                        subtitle:
                            '${metrics.pendingApplications} in active review pipeline',
                        color: AdminColors.info,
                        onTap: () => context.go('/applications'),
                      ),
                      StatCard(
                        title: 'ACTIVE VISA CATALOG',
                        value: '${metrics.activeVisas}',
                        icon: Icons.flight_takeoff_rounded,
                        subtitle: 'Published immigration listings',
                        color: AdminColors.primaryLight,
                        onTap: () => context.go('/visas'),
                      ),
                      // Two-Tier RBAC: Revenue only visible to Super Admin. Consultants see Approved Visas.
                      if (isAdmin)
                        StatCard(
                          title: 'SETTLED REVENUE',
                          value: currencyFormat.format(metrics.totalRevenue),
                          icon: Icons.account_balance_wallet_outlined,
                          subtitle: 'Verified payments & transfers',
                          color: AdminColors.success,
                          onTap: () => context.go('/payments'),
                        )
                      else
                        StatCard(
                          title: 'APPROVED VISAS',
                          value: '${metrics.approvedApplications}',
                          icon: Icons.verified_outlined,
                          subtitle: 'Successful client cases',
                          color: AdminColors.success,
                          onTap: () => context.go('/applications'),
                        ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),

              // Secondary Metrics Row (Visas, Jobs, Scholarships, Pipeline)
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 900;
                  final crossAxisCount = isWide ? 4 : 2;

                  return GridView.count(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    childAspectRatio: isWide ? 1.55 : 1.35,
                    children: [
                      StatCard(
                        title: 'SPONSORED JOBS',
                        value: '${metrics.activeJobs}',
                        icon: Icons.work_outline_rounded,
                        color: const Color(0xFF0284C7),
                        onTap: () => context.go('/jobs'),
                      ),
                      StatCard(
                        title: 'SCHOLARSHIPS DIRECTORY',
                        value: '${metrics.activeScholarships}',
                        icon: Icons.school_outlined,
                        color: const Color(0xFF7C3AED),
                        onTap: () => context.go('/scholarships'),
                      ),
                      StatCard(
                        title: 'PENDING ACTION',
                        value: '${metrics.pendingApplications}',
                        icon: Icons.hourglass_top_rounded,
                        color: AdminColors.warning,
                        onTap: () => context.go('/applications'),
                      ),
                      StatCard(
                        title: 'REJECTED / WITHDRAWN',
                        value: '${metrics.rejectedApplications}',
                        icon: Icons.cancel_outlined,
                        color: const Color(0xFF64748B),
                        onTap: () => context.go('/applications'),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 28),

              // Recent Applications Table Card
              DataTableCard(
                title: 'Recent Visa & Procedure Applications',
                subtitle:
                    'Latest applicant submissions with live 5-step status tracking',
                trailing: TextButton.icon(
                  onPressed: () => context.go('/applications'),
                  icon: const Icon(Icons.arrow_forward, size: 16),
                  label: const Text('View All Applications'),
                ),
                columns: const [
                  DataColumn(label: Text('REFERENCE')),
                  DataColumn(label: Text('APPLICANT')),
                  DataColumn(label: Text('VISA / OPPORTUNITY')),
                  DataColumn(label: Text('CURRENT STEP')),
                  DataColumn(label: Text('STATUS')),
                  DataColumn(label: Text('DATE')),
                  DataColumn(label: Text('ACTION')),
                ],
                rows: metrics.recentApplications.map((app) {
                  return DataRow(
                    cells: [
                      DataCell(
                        Text(
                          app.referenceNumber,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AdminColors.primary,
                          ),
                        ),
                      ),
                      DataCell(
                        Text(
                          app.applicantName ?? 'Verified Applicant',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      DataCell(Text(app.title)),
                      DataCell(
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color:
                                    AdminColors.primary.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'Step ${app.currentStep} of 5',
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
                      DataCell(StatusBadge(status: app.status)),
                      DataCell(
                        Text(
                          DateFormat('dd MMM yyyy').format(app.appliedAt.toLocal()),
                          style: const TextStyle(
                              fontSize: 12, color: AdminColors.textSecondary),
                        ),
                      ),
                      DataCell(
                        OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                          ),
                          onPressed: () =>
                              context.go('/applications/${app.id}'),
                          child: const Text('Manage →',
                              style: TextStyle(fontSize: 12)),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
              const SizedBox(height: 28),

              // Split Section: Recent Registrations & Quick Navigation
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 900;

                  final usersCard = DataTableCard(
                    title: 'New Client Registrations',
                    subtitle:
                        'Profiles created across mobile application and web portals',
                    trailing: TextButton(
                      onPressed: () => context.go('/users'),
                      child: const Text('View All'),
                    ),
                    columns: const [
                      DataColumn(label: Text('NAME / EMAIL')),
                      DataColumn(label: Text('ROLE')),
                      DataColumn(label: Text('REGISTERED')),
                    ],
                    rows: metrics.recentUsers.map((u) {
                      return DataRow(
                        cells: [
                          DataCell(
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(u.fullName ?? 'Client',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600)),
                                Text(u.email,
                                    style: const TextStyle(
                                        fontSize: 11,
                                        color: AdminColors.textMuted)),
                              ],
                            ),
                          ),
                          DataCell(StatusBadge(status: u.role)),
                          DataCell(
                            Text(
                              DateFormat('dd MMM yyyy').format(u.createdAt.toLocal()),
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  );

                  final shortcutsCard = Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: AdminColors.border),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AdminColors.primaryLight
                                      .withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.bolt_rounded,
                                  color: AdminColors.primary,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'Console Quick Actions',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: AdminColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const CircleAvatar(
                              backgroundColor: Color(0xFFEFF6FF),
                              child: Icon(Icons.flight_takeoff,
                                  color: Color(0xFF1D4ED8), size: 20),
                            ),
                            title: const Text('Manage Visa Listings',
                                style: TextStyle(
                                    fontWeight: FontWeight.w600, fontSize: 13.5)),
                            subtitle: const Text(
                                'Add or update embassy fees, steps & requirements',
                                style: TextStyle(fontSize: 11.5)),
                            trailing: const Icon(Icons.chevron_right, size: 20),
                            onTap: () => context.go('/visas'),
                          ),
                          const Divider(),
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const CircleAvatar(
                              backgroundColor: Color(0xFFF0FDF4),
                              child: Icon(Icons.assignment,
                                  color: Color(0xFF15803D), size: 20),
                            ),
                            title: const Text('Review Applications Queue',
                                style: TextStyle(
                                    fontWeight: FontWeight.w600, fontSize: 13.5)),
                            subtitle: const Text(
                                'Advance case steppers & upload embassy notes',
                                style: TextStyle(fontSize: 11.5)),
                            trailing: const Icon(Icons.chevron_right, size: 20),
                            onTap: () => context.go('/applications'),
                          ),
                          const Divider(),
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const CircleAvatar(
                              backgroundColor: Color(0xFFFAF5FF),
                              child: Icon(Icons.folder_shared,
                                  color: Color(0xFF7E22CE), size: 20),
                            ),
                            title: const Text('Document Verification',
                                style: TextStyle(
                                    fontWeight: FontWeight.w600, fontSize: 13.5)),
                            subtitle: const Text(
                                'Inspect applicant passport & degree uploads',
                                style: TextStyle(fontSize: 11.5)),
                            trailing: const Icon(Icons.chevron_right, size: 20),
                            onTap: () => context.go('/documents'),
                          ),
                          if (isAdmin) ...[
                            const Divider(),
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: const CircleAvatar(
                                backgroundColor: Color(0xFFFEF3C7),
                                child: Icon(Icons.security,
                                    color: Color(0xFFB45309), size: 20),
                              ),
                              title: const Text('Team & Permissions',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13.5)),
                              subtitle: const Text(
                                  'Grant dashboard authority by verified email',
                                  style: TextStyle(fontSize: 11.5)),
                              trailing:
                                  const Icon(Icons.chevron_right, size: 20),
                              onTap: () => context.go('/team'),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );

                  if (isWide) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 3, child: usersCard),
                        const SizedBox(width: 20),
                        Expanded(flex: 2, child: shortcutsCard),
                      ],
                    );
                  }

                  return Column(
                    children: [
                      usersCard,
                      const SizedBox(height: 20),
                      shortcutsCard,
                    ],
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
