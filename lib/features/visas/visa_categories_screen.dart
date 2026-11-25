import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/admin_theme.dart';
import '../../models/visa_model.dart';
import '../../providers/admin_dashboard_providers.dart';
import '../../services/admin_visa_service.dart';
import '../../widgets/admin_scaffold.dart';
import '../../widgets/confirmation_dialog.dart';
import '../../widgets/data_table_card.dart';
import '../../widgets/status_badge.dart';

class VisaCategoriesScreen extends ConsumerWidget {
  const VisaCategoriesScreen({super.key});

  void _showCategoryDialog(BuildContext context, WidgetRef ref, [VisaCategoryItem? cat]) {
    final idController = TextEditingController(text: cat?.id ?? '');
    final labelController = TextEditingController(text: cat?.label ?? '');
    final descController = TextEditingController(text: cat?.description ?? '');
    final orderController =
        TextEditingController(text: (cat?.displayOrder ?? 1).toString());
    bool isActive = cat?.isActive ?? true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text(cat == null ? 'Add Visa Category' : 'Edit Category'),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (cat == null) ...[
                  const Text('Category ID (slug) *',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  TextField(
                    controller: idController,
                    decoration: const InputDecoration(hintText: 'e.g. golden-visa'),
                  ),
                  const SizedBox(height: 12),
                ],
                const Text('Category Label *',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                TextField(
                  controller: labelController,
                  decoration: const InputDecoration(hintText: 'e.g. Golden Visa'),
                ),
                const SizedBox(height: 12),
                const Text('Description',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                TextField(
                  controller: descController,
                  decoration: const InputDecoration(hintText: 'Brief summary...'),
                ),
                const SizedBox(height: 12),
                const Text('Display Order',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                TextField(
                  controller: orderController,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Switch(
                      value: isActive,
                      onChanged: (v) => setState(() => isActive = v),
                    ),
                    const SizedBox(width: 8),
                    const Text('Active Category'),
                  ],
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
                final id = cat?.id ?? idController.text.trim();
                final label = labelController.text.trim();
                if (id.isEmpty || label.isEmpty) return;

                final data = {
                  'id': id,
                  'label': label,
                  'description': descController.text.trim(),
                  'display_order': int.tryParse(orderController.text) ?? 1,
                  'is_active': isActive,
                };

                if (cat == null) {
                  await AdminVisaService.instance.createCategory(data);
                } else {
                  await AdminVisaService.instance.updateCategory(cat.id, data);
                }

                ref.invalidate(visaCategoriesProvider);
                if (ctx.mounted) Navigator.of(ctx).pop();
              },
              child: const Text('Save Category'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(visaCategoriesProvider);

    return AdminScaffold(
      title: 'Visa Categories',
      subtitle: 'Taxonomy grouping for visas displayed across the mobile exploration grid',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: () => context.go('/visas'),
                icon: const Icon(Icons.arrow_back, size: 16),
                label: const Text('Back to Visa Listings'),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () => _showCategoryDialog(context, ref),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add Category'),
              ),
            ],
          ),
          const SizedBox(height: 20),

          categoriesAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(60),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (err, _) => Card(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text('Error loading categories: $err'),
              ),
            ),
            data: (categories) {
              return DataTableCard(
                title: 'Visa Categories (${categories.length})',
                subtitle: 'Active classification rows mapped into customer UI filters',
                columns: const [
                  DataColumn(label: Text('ID / KEY')),
                  DataColumn(label: Text('LABEL')),
                  DataColumn(label: Text('DESCRIPTION')),
                  DataColumn(label: Text('ORDER')),
                  DataColumn(label: Text('STATUS')),
                  DataColumn(label: Text('ACTIONS')),
                ],
                rows: categories.map((cat) {
                  return DataRow(
                    cells: [
                      DataCell(Text(cat.id,
                          style: const TextStyle(
                              fontFamily: 'monospace', fontWeight: FontWeight.w700))),
                      DataCell(Text(cat.label,
                          style: const TextStyle(fontWeight: FontWeight.w600))),
                      DataCell(
                        SizedBox(
                          width: 220,
                          child: Text(
                            cat.description ?? '—',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ),
                      DataCell(Text('${cat.displayOrder}')),
                      DataCell(StatusBadge(status: cat.isActive ? 'active' : 'inactive')),
                      DataCell(
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, size: 18),
                              tooltip: 'Edit Category',
                              onPressed: () => _showCategoryDialog(context, ref, cat),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline,
                                  size: 18, color: AdminColors.danger),
                              tooltip: 'Delete Category',
                              onPressed: () async {
                                final confirm = await ConfirmationDialog.show(
                                  context,
                                  title: 'Delete Visa Category',
                                  message:
                                      'Are you sure you want to delete category "${cat.label}" (${cat.id})? This action cannot be undone.',
                                  confirmLabel: 'Delete Category',
                                  isDestructive: true,
                                );
                                if (confirm) {
                                  try {
                                    await AdminVisaService.instance.deleteCategory(cat.id);
                                    ref.invalidate(visaCategoriesProvider);
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Category "${cat.label}" deleted successfully.'),
                                          backgroundColor: AdminColors.success,
                                        ),
                                      );
                                    }
                                  } catch (e) {
                                    if (context.mounted) {
                                      final errorMsg = e.toString().replaceAll('Exception: ', '');
                                      showDialog(
                                        context: context,
                                        builder: (ctx) => AlertDialog(
                                          shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(16)),
                                          title: const Row(
                                            children: [
                                              Icon(Icons.warning_amber_rounded,
                                                  color: AdminColors.danger, size: 24),
                                              SizedBox(width: 10),
                                              Text('Cannot Delete Category',
                                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                                            ],
                                          ),
                                          content: Text(errorMsg,
                                              style: const TextStyle(fontSize: 13.5, height: 1.4)),
                                          actions: [
                                            ElevatedButton(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: AdminColors.primary,
                                                foregroundColor: Colors.white,
                                              ),
                                              onPressed: () => Navigator.of(ctx).pop(),
                                              child: const Text('Understood'),
                                            ),
                                          ],
                                        ),
                                      );
                                    }
                                  }
                                }
                              },
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
