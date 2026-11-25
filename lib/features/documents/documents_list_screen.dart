import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/admin_theme.dart';
import '../../models/document_model.dart';
import '../../providers/admin_dashboard_providers.dart';
import '../../services/admin_document_service.dart';
import '../../widgets/admin_scaffold.dart';
import '../../widgets/data_table_card.dart';
import '../../widgets/search_filter_bar.dart';
import '../../widgets/status_badge.dart';

class DocumentsListScreen extends ConsumerStatefulWidget {
  const DocumentsListScreen({super.key});

  @override
  ConsumerState<DocumentsListScreen> createState() =>
      _DocumentsListScreenState();
}

class _DocumentsListScreenState extends ConsumerState<DocumentsListScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _statusFilter = 'all';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showVerificationDialog(UserDocumentItem doc) {
    const validStatuses = ['verified', 'rejected', 'pending'];
    String selectedStatus = doc.status == 'pending' ? 'verified' : doc.status;
    if (!validStatuses.contains(selectedStatus)) {
      selectedStatus = 'pending';
    }
    final notesController =
        TextEditingController(text: doc.verificationNotes ?? '');

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text('Verify "${doc.title}"'),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Verification Outcome',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  initialValue: validStatuses.contains(selectedStatus) ? selectedStatus : 'pending',
                  items: const [
                    DropdownMenuItem(value: 'verified', child: Text('VERIFIED & APPROVED')),
                    DropdownMenuItem(value: 'rejected', child: Text('REJECTED / INVALID')),
                    DropdownMenuItem(value: 'pending', child: Text('PENDING REVIEW')),
                  ],
                  onChanged: (val) {
                    if (val != null) setDialogState(() => selectedStatus = val);
                  },
                ),
                const SizedBox(height: 14),
                const Text('Staff Feedback / Reason',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                TextField(
                  controller: notesController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    hintText: 'e.g. Scanned copy clear; dates verified with passport...',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            OutlinedButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                await AdminDocumentService.instance.updateDocumentVerification(
                  doc.id,
                  selectedStatus,
                  notesController.text.trim().isNotEmpty
                      ? notesController.text.trim()
                      : null,
                );
                ref.invalidate(documentsListProvider);
                if (ctx.mounted) Navigator.of(ctx).pop();
              },
              child: const Text('Save Verification'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final docsAsync = ref.watch(
      documentsListProvider((
        search: _searchQuery,
        status: _statusFilter,
        type: null,
      )),
    );

    return AdminScaffold(
      title: 'Document Verification Vault',
      subtitle: 'Inspect, verify, and approve passports, educational credentials, and bank statements',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SearchFilterBar<String>(
            searchController: _searchController,
            searchHint: 'Search documents by title or file name...',
            onSearchChanged: (val) => setState(() => _searchQuery = val),
            filterValue: _statusFilter,
            filterLabel: 'Status',
            filterItems: const [
              FilterDropdownItem(value: 'all', label: 'All Documents'),
              FilterDropdownItem(value: 'pending', label: 'Pending Review'),
              FilterDropdownItem(value: 'verified', label: 'Verified & Approved'),
              FilterDropdownItem(value: 'rejected', label: 'Rejected'),
            ],
            onFilterChanged: (val) {
              if (val != null) setState(() => _statusFilter = val);
            },
            onRefresh: () => ref.invalidate(documentsListProvider),
          ),
          const SizedBox(height: 20),

          docsAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(60),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (err, _) => Card(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text('Error loading documents: $err'),
              ),
            ),
            data: (docs) {
              return DataTableCard(
                title: 'Client Dossier Documents (${docs.length})',
                subtitle: 'Protected with Supabase Storage access controls',
                columns: const [
                  DataColumn(label: Text('DOCUMENT TITLE & FILE')),
                  DataColumn(label: Text('TYPE')),
                  DataColumn(label: Text('CLIENT PROFILE')),
                  DataColumn(label: Text('FILE SIZE')),
                  DataColumn(label: Text('STATUS')),
                  DataColumn(label: Text('UPLOADED')),
                  DataColumn(label: Text('ACTIONS')),
                ],
                rows: docs.map((d) {
                  return DataRow(
                    cells: [
                      DataCell(
                        SizedBox(
                          width: 200,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                d.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontWeight: FontWeight.w700),
                              ),
                              Text(
                                d.fileName ?? 'document.pdf',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 11, color: AdminColors.textMuted),
                              ),
                            ],
                          ),
                        ),
                      ),
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AdminColors.surfaceMuted,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            d.documentType?.toUpperCase() ?? 'DOC',
                            style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                      DataCell(
                        SizedBox(
                          width: 160,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                d.userName ?? 'Verified Client',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                              Text(
                                d.userEmail ?? '—',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 11, color: AdminColors.textMuted),
                              ),
                            ],
                          ),
                        ),
                      ),
                      DataCell(Text(d.formattedSize, style: const TextStyle(fontSize: 12))),
                      DataCell(StatusBadge(status: d.status)),
                      DataCell(
                        Text(
                          DateFormat('dd MMM yyyy').format(d.createdAt.toLocal()),
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                      DataCell(
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                backgroundColor: AdminColors.primary,
                              ),
                              onPressed: () => _showVerificationDialog(d),
                              icon: const Icon(Icons.verified_outlined, size: 14),
                              label: const Text('Verify', style: TextStyle(fontSize: 11.5)),
                            ),
                          ],
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
