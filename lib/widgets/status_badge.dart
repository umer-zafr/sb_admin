import 'package:flutter/material.dart';
import '../core/theme/admin_theme.dart';

class StatusBadge extends StatelessWidget {
  const StatusBadge({
    super.key,
    required this.status,
    this.customLabel,
  });

  final String status;
  final String? customLabel;

  @override
  Widget build(BuildContext context) {
    final s = status.toLowerCase();

    Color bg;
    Color fg;
    Color border;

    if (s == 'approved' ||
        s == 'completed' ||
        s == 'verified' ||
        s == 'success' ||
        s == 'active' ||
        s == 'true') {
      bg = AdminColors.successBg;
      fg = AdminColors.success;
      border = AdminColors.success.withValues(alpha: 0.3);
    } else if (s == 'in_review' ||
        s == 'pending' ||
        s == 'submitted' ||
        s == 'in_progress' ||
        s == 'scheduled') {
      bg = AdminColors.warningBg;
      fg = AdminColors.warning;
      border = AdminColors.warning.withValues(alpha: 0.3);
    } else if (s == 'rejected' ||
        s == 'cancelled' ||
        s == 'failed' ||
        s == 'inactive' ||
        s == 'false') {
      bg = AdminColors.dangerBg;
      fg = AdminColors.danger;
      border = AdminColors.danger.withValues(alpha: 0.3);
    } else {
      bg = AdminColors.infoBg;
      fg = AdminColors.info;
      border = AdminColors.info.withValues(alpha: 0.3);
    }

    final displayText = customLabel ??
        status
            .replaceAll('_', ' ')
            .split(' ')
            .map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '')
            .join(' ');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: fg,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            displayText,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}
