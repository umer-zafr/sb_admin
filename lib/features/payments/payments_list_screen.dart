import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/constants/admin_constants.dart';
import '../../core/theme/admin_theme.dart';
import '../../models/payment_model.dart';
import '../../providers/admin_dashboard_providers.dart';
import '../../services/admin_payment_service.dart';
import '../../widgets/admin_scaffold.dart';
import '../../widgets/data_table_card.dart';
import '../../widgets/search_filter_bar.dart';
import '../../widgets/status_badge.dart';

class PaymentsListScreen extends ConsumerStatefulWidget {
  const PaymentsListScreen({super.key});

  @override
  ConsumerState<PaymentsListScreen> createState() => _PaymentsListScreenState();
}

class _PaymentsListScreenState extends ConsumerState<PaymentsListScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _statusFilter = 'all';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showGatewayResponseDialog(AdminPaymentItem payment) {
    String prettyJson = 'No gateway payload recorded.';
    if (payment.gatewayResponse != null) {
      try {
        const encoder = JsonEncoder.withIndent('  ');
        prettyJson = encoder.convert(payment.gatewayResponse);
      } catch (_) {
        prettyJson = payment.gatewayResponse.toString();
      }
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Gateway Payload — ${payment.transactionId}'),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500, maxHeight: 400),
          child: SingleChildScrollView(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(8),
              ),
              child: SelectableText(
                prettyJson,
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
  Widget build(BuildContext context) {
    final paymentsAsync = ref.watch(
      paymentsListProvider((
        search: _searchQuery,
        status: _statusFilter,
        method: null,
      )),
    );

    return AdminScaffold(
      title: 'Payments & Revenue Ledger',
      subtitle: 'Audit transactions initiated via PayFast, credit cards, Easypaisa, JazzCash, and direct bank wire',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SearchFilterBar<String>(
            searchController: _searchController,
            searchHint: 'Search by transaction ID, basket reference, or promo code...',
            onSearchChanged: (val) => setState(() => _searchQuery = val),
            filterValue: _statusFilter,
            filterLabel: 'Status',
            filterItems: [
              const FilterDropdownItem(value: 'all', label: 'All Transactions'),
              ...AdminConstants.paymentStatuses.map(
                (s) => FilterDropdownItem(
                  value: s,
                  label: s.toUpperCase(),
                ),
              ),
            ],
            onFilterChanged: (val) {
              if (val != null) setState(() => _statusFilter = val);
            },
            onRefresh: () => ref.invalidate(paymentsListProvider),
          ),
          const SizedBox(height: 20),

          paymentsAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(60),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (err, _) => Card(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text('Error loading payments: $err'),
              ),
            ),
            data: (payments) {
              return DataTableCard(
                title: 'Transaction Records (${payments.length})',
                subtitle: 'Real ledger rows recorded in public.payments table',
                columns: const [
                  DataColumn(label: Text('TRANSACTION ID & REF')),
                  DataColumn(label: Text('CLIENT PROFILE')),
                  DataColumn(label: Text('GATEWAY METHOD')),
                  DataColumn(label: Text('AMOUNT')),
                  DataColumn(label: Text('PROMO APPLIED')),
                  DataColumn(label: Text('STATUS')),
                  DataColumn(label: Text('DATE')),
                  DataColumn(label: Text('ACTIONS')),
                ],
                rows: payments.map((p) {
                  return DataRow(
                    cells: [
                      DataCell(
                        SizedBox(
                          width: 140,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                p.transactionId,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontWeight: FontWeight.w700, color: AdminColors.primary, fontSize: 12),
                              ),
                              Text(
                                p.referenceId,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 11, color: AdminColors.textMuted),
                              ),
                            ],
                          ),
                        ),
                      ),
                      DataCell(
                        SizedBox(
                          width: 140,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                p.userName ?? 'Verified Client',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5),
                              ),
                              Text(
                                p.userEmail ?? '—',
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
                            p.displayPaymentMethod,
                            style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                      DataCell(
                        Text(
                          'PKR ${p.amount.toStringAsFixed(0)}',
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5),
                        ),
                      ),
                      DataCell(
                        SizedBox(
                          width: 100,
                          child: Text(
                            p.promoCode != null
                                ? '${p.promoCode} (-PKR ${p.discountAmount?.toStringAsFixed(0)})'
                                : 'None',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11.5,
                              color: p.promoCode != null ? AdminColors.success : AdminColors.textMuted,
                              fontWeight: p.promoCode != null ? FontWeight.w600 : FontWeight.normal,
                            ),
                          ),
                        ),
                      ),
                      DataCell(StatusBadge(status: p.status)),
                      DataCell(
                        SizedBox(
                          width: 110,
                          child: Text(
                            DateFormat('dd MMM yy, hh:mm a').format(p.createdAt.toLocal()),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 11),
                          ),
                        ),
                      ),
                      DataCell(
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.code_rounded, size: 18),
                              tooltip: 'Inspect Gateway Response',
                              onPressed: () => _showGatewayResponseDialog(p),
                            ),
                            if (p.isPending) ...[
                              IconButton(
                                icon: const Icon(Icons.check_circle_outline,
                                    size: 18, color: AdminColors.success),
                                tooltip: 'Manually Mark Completed',
                                onPressed: () async {
                                  await AdminPaymentService.instance
                                      .updatePaymentStatus(p.id, 'completed');
                                  ref.invalidate(paymentsListProvider);
                                },
                              ),
                            ],
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
