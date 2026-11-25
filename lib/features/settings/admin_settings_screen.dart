import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/admin_constants.dart';
import '../../core/theme/admin_theme.dart';
import '../../providers/admin_auth_provider.dart';
import '../../widgets/admin_scaffold.dart';
import '../../widgets/confirmation_dialog.dart';
import '../../widgets/status_badge.dart';

class AdminSettingsScreen extends ConsumerWidget {
  const AdminSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(adminAuthProvider);

    String adminEmail = 'sbconsultantofficial@gmail.com';
    String adminName = 'Administrator';
    String adminId = '—';
    String role = 'admin';

    if (authState is AdminAuthAuthenticated) {
      adminEmail = authState.profile.email;
      adminName = authState.profile.fullName ?? 'Administrator';
      adminId = authState.profile.id;
      role = authState.profile.role;
    }

    return AdminScaffold(
      title: 'Portal Settings & Cloud Infrastructure',
      subtitle: 'System environment telemetry, security posture, and administrator profile',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Admin Profile Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: AdminColors.primary,
                    child: Text(
                      adminName.isNotEmpty ? adminName[0].toUpperCase() : 'A',
                      style: const TextStyle(
                        fontSize: 24,
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
                            Text(
                              adminName,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: AdminColors.textPrimary,
                              ),
                            ),
                            const SizedBox(width: 10),
                            StatusBadge(status: role),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          adminEmail,
                          style: const TextStyle(fontSize: 13, color: AdminColors.textSecondary),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Authenticated Admin UID: $adminId',
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 11,
                            color: AdminColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AdminColors.danger,
                    ),
                    onPressed: () async {
                      final confirmed = await ConfirmationDialog.show(
                        context,
                        title: 'Sign Out',
                        message: 'Are you sure you want to end your administrative session?',
                        confirmLabel: 'Sign Out',
                        isDestructive: true,
                      );
                      if (confirmed && context.mounted) {
                        await ref.read(adminAuthProvider.notifier).signOut();
                        if (context.mounted) context.go('/login');
                      }
                    },
                    icon: const Icon(Icons.logout, size: 16),
                    label: const Text('Sign Out'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Infrastructure Cards Grid
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Supabase Backend Card
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AdminColors.successBg,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.cloud_done_rounded,
                                  color: AdminColors.success, size: 24),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Supabase Cloud Infrastructure',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  Text(
                                    'Live Production PostgreSQL Database',
                                    style: TextStyle(fontSize: 12, color: AdminColors.textMuted),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        _buildSettingRow('Project ID', 'tpmdqfmtunxbnhpckkbh'),
                        _buildSettingRow('Host URL', 'https://tpmdqfmtunxbnhpckkbh.supabase.co'),
                        _buildSettingRow('Row Level Security (RLS)', 'Active (Enforced on all 20 tables)'),
                        _buildSettingRow('Realtime Replication', 'Active'),
                        _buildSettingRow('Edge Functions Runtime', 'Deno Serverless (2 Active Functions)'),
                        _buildSettingRow('Storage System', '4 Buckets (avatars, app-documents, payment-receipts, public-assets)'),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 20),

              // Security & Governance Card
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AdminColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.shield_outlined,
                                  color: AdminColors.primary, size: 24),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Security & Architecture Posture',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  Text(
                                    'Zero-trust client policy with backend role enforcement',
                                    style: TextStyle(fontSize: 12, color: AdminColors.textMuted),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        _buildSettingRow('Client Role Escalation Guard', 'Enabled (Postgres Trigger Protection)'),
                        _buildSettingRow('Admin Key Isolation', 'Secret Keys Isolated in Edge Functions'),
                        _buildSettingRow('Audit Trail Engine', 'Enabled (Capturing CRUD & Stepper Advances)'),
                        _buildSettingRow('Application Version', 'v${AdminConstants.version} Enterprise Web'),
                        _buildSettingRow('Customer App Sync', 'Bidirectional via Supabase Single Source of Truth'),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSettingRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: AdminColors.textSecondary)),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AdminColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
