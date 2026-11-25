import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../core/theme/admin_theme.dart';
import '../models/admin_notification_model.dart';
import '../providers/admin_auth_provider.dart';
import '../providers/admin_dashboard_providers.dart';
import '../providers/admin_notification_provider.dart';
import 'confirmation_dialog.dart';

class AdminTopbar extends ConsumerWidget implements PreferredSizeWidget {
  const AdminTopbar({
    super.key,
    required this.title,
    this.subtitle,
    this.onMenuPressed,
  });

  final String title;
  final String? subtitle;
  final VoidCallback? onMenuPressed;

  @override
  Size get preferredSize => const Size.fromHeight(68);

  void _showNotificationsSheet(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => Consumer(
        builder: (context, ref, _) {
          final notifications = ref.watch(adminNotificationsProvider);
          final unreadCount = ref.watch(adminUnreadNotificationsCountProvider);

          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480, maxHeight: 600),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      children: [
                        const Icon(Icons.notifications_active_rounded,
                            color: AdminColors.primary, size: 22),
                        const SizedBox(width: 10),
                        const Text(
                          'Live Realtime Alerts',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AdminColors.textPrimary,
                          ),
                        ),
                        if (unreadCount > 0) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AdminColors.danger,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '$unreadCount new',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                        const Spacer(),
                        if (notifications.isNotEmpty)
                          TextButton(
                            onPressed: () {
                              ref
                                  .read(adminNotificationsProvider.notifier)
                                  .markAllAsRead();
                            },
                            child: const Text('Mark all read',
                                style: TextStyle(fontSize: 12)),
                          ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, size: 20),
                          onPressed: () => Navigator.of(ctx).pop(),
                        ),
                      ],
                    ),
                    const Divider(height: 20),

                    // Notification List
                    if (notifications.isEmpty)
                      const Expanded(
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.notifications_none_rounded,
                                  size: 48, color: AdminColors.textMuted),
                              SizedBox(height: 12),
                              Text(
                                'No notifications yet',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AdminColors.textPrimary,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'When applicants book or submit from mobile, alerts appear here instantly.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AdminColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      Expanded(
                        child: ListView.separated(
                          itemCount: notifications.length,
                          separatorBuilder: (_, __) =>
                              const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final AdminNotificationItem item =
                                notifications[index];
                            final icon = switch (item.type) {
                              'booking' => Icons.event_available_rounded,
                              'payment' => Icons.payments_rounded,
                              _ => Icons.assignment_turned_in_rounded,
                            };
                            final color = switch (item.type) {
                              'booking' => const Color(0xFF2563EB),
                              'payment' => const Color(0xFF16A34A),
                              _ => AdminColors.primary,
                            };

                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 4, vertical: 4),
                              leading: Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(icon, color: color, size: 20),
                              ),
                              title: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      item.title,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: item.isRead
                                            ? FontWeight.w600
                                            : FontWeight.w700,
                                        color: AdminColors.textPrimary,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    DateFormat('hh:mm a').format(item.timestamp),
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AdminColors.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 3),
                                child: Text(
                                  item.message,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AdminColors.textSecondary,
                                  ),
                                ),
                              ),
                              trailing: item.route != null
                                  ? OutlinedButton(
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 6),
                                      ),
                                      onPressed: () {
                                        ref
                                            .read(adminNotificationsProvider
                                                .notifier)
                                            .markAsRead(item.id);
                                        Navigator.of(ctx).pop();
                                        context.go(item.route!);
                                      },
                                      child: const Text('View →',
                                          style: TextStyle(fontSize: 11)),
                                    )
                                  : null,
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _manualRefresh(BuildContext context, WidgetRef ref) {
    ref.read(dashboardMetricsRevisionProvider.notifier).increment();
    ref.read(applicationsRevisionProvider.notifier).increment();
    ref.read(bookingsRevisionProvider.notifier).increment();
    ref.read(paymentsRevisionProvider.notifier).increment();
    ref.read(visasRevisionProvider.notifier).increment();
    ref.invalidate(dashboardMetricsProvider);
    ref.invalidate(applicationsListProvider);
    ref.invalidate(bookingsListProvider);
    ref.invalidate(paymentsListProvider);
    ref.invalidate(visasListProvider);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('⚡ Instant Sync: Live data refreshed directly from Supabase Cloud.'),
        duration: Duration(seconds: 2),
        backgroundColor: AdminColors.primaryDark,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(adminAuthProvider);
    final unreadCount = ref.watch(adminUnreadNotificationsCountProvider);

    String email = 'sbconsultantofficial@gmail.com';
    String name = 'Administrator';
    if (authState is AdminAuthAuthenticated) {
      email = authState.profile.email;
      name = authState.profile.fullName ?? 'Admin';
    }

    return Container(
      height: 68,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: AdminColors.border, width: 1),
        ),
      ),
      child: Row(
        children: [
          if (onMenuPressed != null) ...[
            IconButton(
              icon: const Icon(Icons.menu_rounded),
              onPressed: onMenuPressed,
            ),
            const SizedBox(width: 8),
          ],

          // Page Title & Subtitle
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AdminColors.textPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AdminColors.textMuted,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Instant Sync Button
          IconButton(
            icon: const Icon(Icons.sync_rounded, color: AdminColors.primary),
            tooltip: 'Instant Live Sync from Supabase Cloud',
            onPressed: () => _manualRefresh(context, ref),
          ),
          const SizedBox(width: 8),

          // Realtime Notifications Bell with Badge
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                icon: Icon(
                  unreadCount > 0
                      ? Icons.notifications_active_rounded
                      : Icons.notifications_none_rounded,
                  color: unreadCount > 0
                      ? AdminColors.accentGold
                      : AdminColors.textSecondary,
                ),
                tooltip: 'Live Realtime Alerts',
                onPressed: () => _showNotificationsSheet(context, ref),
              ),
              if (unreadCount > 0)
                Positioned(
                  top: 6,
                  right: 6,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AdminColors.danger,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '$unreadCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 14),

          // Environment & Backend Live Indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AdminColors.successBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AdminColors.success.withValues(alpha: 0.25),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    color: AdminColors.success,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                const Text(
                  'SUPABASE REALTIME ACTIVE',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: AdminColors.success,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),

          // Admin User Avatar & Profile Dropdown / Sign Out
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AdminColors.primary,
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : 'A',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AdminColors.textPrimary,
                    ),
                  ),
                  Text(
                    email,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AdminColors.textMuted,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),

              // Sign Out Button
              IconButton(
                icon: const Icon(
                  Icons.logout_rounded,
                  size: 20,
                  color: AdminColors.danger,
                ),
                tooltip: 'Sign Out of Admin Portal',
                onPressed: () async {
                  final confirmed = await ConfirmationDialog.show(
                    context,
                    title: 'Sign Out',
                    message:
                        'Are you sure you want to end your administrative session?',
                    confirmLabel: 'Sign Out',
                    isDestructive: true,
                  );
                  if (confirmed && context.mounted) {
                    await ref.read(adminAuthProvider.notifier).signOut();
                    if (context.mounted) {
                      context.go('/login');
                    }
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
