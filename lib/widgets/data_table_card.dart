import 'package:flutter/material.dart';
import '../core/theme/admin_theme.dart';

class DataTableCard extends StatelessWidget {
  const DataTableCard({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    required this.columns,
    required this.rows,
    this.isLoading = false,
    this.emptyWidget,
    this.minWidth,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final List<DataColumn> columns;
  final List<DataRow> rows;
  final bool isLoading;
  final Widget? emptyWidget;
  final double? minWidth;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AdminColors.textPrimary,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AdminColors.textMuted,
                        ),
                      ),
                    ],
                  ],
                ),
                if (trailing != null) trailing!,
              ],
            ),
          ),
          const Divider(),

          // Body Table
          if (isLoading)
            const Padding(
              padding: EdgeInsets.all(48),
              child: Center(
                child: CircularProgressIndicator(strokeWidth: 2.5),
              ),
            )
          else if (rows.isEmpty)
            emptyWidget ??
                const Padding(
                  padding: EdgeInsets.all(48),
                  child: Center(
                    child: Text(
                      'No records found.',
                      style: TextStyle(
                        fontSize: 14,
                        color: AdminColors.textMuted,
                      ),
                    ),
                  ),
                )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(minWidth: minWidth ?? 0),
                child: DataTable(
                  headingRowColor:
                      const WidgetStatePropertyAll(AdminColors.surfaceMuted),
                  headingTextStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AdminColors.textSecondary,
                    letterSpacing: 0.5,
                  ),
                  dataRowMinHeight: 52,
                  dataRowMaxHeight: 56,
                  dataTextStyle: const TextStyle(
                    fontSize: 13,
                    color: AdminColors.textPrimary,
                  ),
                  dividerThickness: 1,
                  horizontalMargin: 16,
                  columnSpacing: 16,
                  columns: columns,
                  rows: rows,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
