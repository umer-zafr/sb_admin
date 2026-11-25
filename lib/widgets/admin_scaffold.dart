import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/theme/admin_theme.dart';
import '../models/admin_notification_model.dart';
import '../providers/admin_notification_provider.dart';
import '../services/admin_realtime_service.dart';
import 'admin_sidebar.dart';
import 'admin_topbar.dart';

class AdminScaffold extends ConsumerStatefulWidget {
  const AdminScaffold({
    super.key,
    required this.title,
    this.subtitle,
    required this.body,
  });

  final String title;
  final String? subtitle;
  final Widget body;

  @override
  ConsumerState<AdminScaffold> createState() => _AdminScaffoldState();
}

class _AdminScaffoldState extends ConsumerState<AdminScaffold> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  Timer? _dismissTimer;
  bool _isDialogOpen = false;

  @override
  void dispose() {
    _dismissTimer?.cancel();
    super.dispose();
  }

  void _scheduleBannerDismiss() {
    _dismissTimer?.cancel();
    _dismissTimer = Timer(const Duration(seconds: 12), () {
      if (mounted) {
        ref.read(liveBannerAlertProvider.notifier).clear();
      }
    });
  }

  void _showImmediatePopUpDialog(BuildContext context, AdminNotificationItem alert) {
    if (_isDialogOpen) return;
    _isDialogOpen = true;

    final isPayment = alert.type == 'payment';
    final isApplication = alert.type == 'application';
    final themeColor = isPayment
        ? const Color(0xFF10B981)
        : (isApplication ? const Color(0xFFF59E0B) : AdminColors.accentGold);

    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: const Color(0xFF0F172A),
          elevation: 24,
          child: Container(
            width: 500,
            padding: const EdgeInsets.all(26),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: themeColor, width: 2),
              boxShadow: [
                BoxShadow(
                  color: themeColor.withValues(alpha: 0.25),
                  blurRadius: 32,
                  spreadRadius: 2,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top header with pulsing badge and icon
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: themeColor.withValues(alpha: 0.18),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isPayment
                            ? Icons.account_balance_wallet_rounded
                            : (isApplication
                                ? Icons.assignment_ind_rounded
                                : Icons.notifications_active_rounded),
                        color: themeColor,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: themeColor.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              isPayment
                                  ? '💳 IMMEDIATE PAYMENT ALERT'
                                  : '🚨 NEW VISA APPLICATION FILED',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                                color: themeColor,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            alert.title,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white60, size: 20),
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        ref.read(liveBannerAlertProvider.notifier).clear();
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Details Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Text(
                    alert.message,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white,
                      height: 1.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        ref.read(liveBannerAlertProvider.notifier).clear();
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white70,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      child: const Text('Dismiss', style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                    const SizedBox(width: 10),
                    if (alert.route != null)
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: themeColor,
                          foregroundColor: const Color(0xFF0F172A),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () {
                          Navigator.of(ctx).pop();
                          ref.read(liveBannerAlertProvider.notifier).clear();
                          context.go(alert.route!);
                        },
                        icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                        label: Text(
                          isPayment ? 'View Payments' : 'Review Application Now',
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    ).then((_) {
      _isDialogOpen = false;
    });
  }

  Widget _buildFloatingLiveAlert(AdminNotificationItem alert) {
    _scheduleBannerDismiss();

    return Container(
      margin: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AdminColors.accentGold, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AdminColors.accentGold.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.bolt_rounded,
              color: AdminColors.accentGold,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text(
                      'REALTIME ALERT: ${alert.title.toUpperCase()}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: AdminColors.accentGold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AdminColors.successBg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'JUST NOW',
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          color: AdminColors.success,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  alert.message,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          if (alert.route != null)
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AdminColors.accentGold,
                foregroundColor: AdminColors.primaryDark,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              ),
              onPressed: () {
                ref.read(liveBannerAlertProvider.notifier).clear();
                context.go(alert.route!);
              },
              icon: const Icon(Icons.arrow_forward_rounded, size: 14),
              label: const Text('View Dossier', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          IconButton(
            icon: const Icon(Icons.close_rounded, color: Colors.white70, size: 18),
            tooltip: 'Dismiss Alert',
            onPressed: () {
              ref.read(liveBannerAlertProvider.notifier).clear();
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Keep active Supabase Realtime synchronization alive across the dashboard
    ref.watch(adminRealtimeSyncProvider);
    final activeAlert = ref.watch(liveBannerAlertProvider);

    // Immediately pop up modal alert dialog upon receiving real-time event
    ref.listen<AdminNotificationItem?>(liveBannerAlertProvider, (previous, next) {
      if (next != null && next != previous) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _showImmediatePopUpDialog(context, next);
          }
        });
      }
    });

    final currentRoute = GoRouterState.of(context).uri.toString();
    final isDesktop = MediaQuery.of(context).size.width >= 1024;

    if (isDesktop) {
      return Scaffold(
        backgroundColor: AdminColors.background,
        body: Row(
          children: [
            // Permanent Sidebar
            AdminSidebar(currentRoute: currentRoute),

            // Main Content Area
            Expanded(
              child: Column(
                children: [
                  AdminTopbar(
                    title: widget.title,
                    subtitle: widget.subtitle,
                  ),
                  if (activeAlert != null) _buildFloatingLiveAlert(activeAlert),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(28),
                      child: widget.body,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Tablet / Smaller View with Drawer
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AdminColors.background,
      drawer: Drawer(
        elevation: 0,
        child: AdminSidebar(currentRoute: currentRoute),
      ),
      appBar: AdminTopbar(
        title: widget.title,
        subtitle: widget.subtitle,
        onMenuPressed: () {
          _scaffoldKey.currentState?.openDrawer();
        },
      ),
      body: Column(
        children: [
          if (activeAlert != null) _buildFloatingLiveAlert(activeAlert),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: widget.body,
            ),
          ),
        ],
      ),
    );
  }
}