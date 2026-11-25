import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/admin_theme.dart';
import '../../models/audit_log_model.dart';
import '../../providers/admin_dashboard_providers.dart';
import '../../widgets/admin_scaffold.dart';
import '../../widgets/data_table_card.dart';

class AuditLogsScreen extends ConsumerWidget {
  const AuditLogsScreen({super.key});

  void _showPayloadDialog(BuildContext context, AdminAuditLogItem log) {
    String pretty = 'No additional details recorded.';
    if (log.details != null) {
      try {
        const encoder = JsonEncoder.withIndent('  ');
        pretty = encoder.convert(log.details);
      } catch (_) {
        pretty = log.details.toString();
      }
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Audit Action Payload — ${log.action}'),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480, maxHeight: 380),
          child: SingleChildScrollView(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(8),
              ),
              child: SelectableText(
                pretty,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  color: Color(0xFF38BDF8),
                ),
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsAsync = ref.watch(auditLogsListProvider);

    return AdminScaffold(
      title: 'System Audit Trail',
      subtitle: 'Immutable timeline of administrative interventions, step updates, and catalog revisions',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Security & Compliance Logs (Last 60 Operations)',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AdminColors.textSecondary),
              ),
              OutlinedButton.icon(
                onPressed: () => ref.invalidate(auditLogsListProvider),
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Refresh Trail'),
              ),
            ],
          ),
          const SizedBox(height: 16),

          logsAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(60),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (err, _) => Card(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text('Error loading audit trail: $err'),
              ),
            ),
            data: (logs) {
              return DataTableCard(
                title: 'Operational Audit Log Entries (${logs.length})',
                subtitle: 'Enforced via database RLS policy (accessible only by authenticated administrators)',
                columns: const [
                  DataColumn(label: Text('TIMESTAMP')),
                  DataColumn(label: Text('ADMINISTRATOR')),
                  DataColumn(label: Text('ACTION TRIGGERED')),
                  DataColumn(label: Text('TARGET ENTITY')),
                  DataColumn(label: Text('ENTITY ID')),
                  DataColumn(label: Text('PAYLOAD')),
                ],
                rows: logs.map((log) {
                  return DataRow(
                    cells: [
                      DataCell(
                        Text(
                          DateFormat('dd MMM yyyy, hh:mm:ss a').format(log.createdAt.toLocal()),
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                      DataCell(
                        SizedBox(
                          width: 170,
                          child: Text(
                            log.adminEmail ?? 'System Superadmin',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5),
                          ),
                        ),
                      ),
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AdminColors.primary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            log.action.replaceAll('_', ' ').toUpperCase(),
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AdminColors.primary,
                            ),
                          ),
                        ),
                      ),
                      DataCell(Text(log.entityType.toUpperCase(), style: const TextStyle(fontSize: 11.5))),
                      DataCell(
                        Text(
                          log.entityId.length > 12
                              ? '${log.entityId.substring(0, 12)}...'
                              : log.entityId,
                          style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
                        ),
                      ),
                      DataCell(
                        IconButton(
                          icon: const Icon(Icons.data_object_rounded, size: 18),
                          tooltip: 'Inspect Payload',
                          onPressed: () => _showPayloadDialog(context, log),
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
