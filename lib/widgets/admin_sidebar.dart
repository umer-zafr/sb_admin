import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/constants/admin_constants.dart';
import '../core/theme/admin_theme.dart';
import '../providers/admin_auth_provider.dart';

class SidebarNavItem {
  const SidebarNavItem({
    required this.title,
    required this.icon,
    required this.route,
    this.badgeCount,
    this.adminOnly = false,
  });

  final String title;
  final IconData icon;
  final String route;
  final int? badgeCount;
  final bool adminOnly;
}

class AdminSidebar extends ConsumerWidget {
  const AdminSidebar({
    super.key,
    required this.currentRoute,
  });

  final String currentRoute;

  static const List<Map<String, dynamic>> rawMenuGroups = [
    {
      'title': 'OVERVIEW',
      'items': [
        SidebarNavItem(
          title: 'Dashboard',
          icon: Icons.grid_view_rounded,
          route: '/dashboard',
        ),
      ],
    },
    {
      'title': 'IMMIGRATION & CATALOG',
      'items': [
        SidebarNavItem(
          title: 'Visa Listings',
          icon: Icons.flight_takeoff_rounded,
          route: '/visas',
        ),
        SidebarNavItem(
          title: 'Visa Categories',
          icon: Icons.category_outlined,
          route: '/visas/categories',
        ),
        SidebarNavItem(
          title: 'Sponsored Jobs',
          icon: Icons.work_outline_rounded,
          route: '/jobs',
        ),
        SidebarNavItem(
          title: 'Scholarships',
          icon: Icons.school_outlined,
          route: '/scholarships',
        ),
        SidebarNavItem(
          title: 'Ad Banners',
          icon: Icons.view_carousel_rounded,
          route: '/banners',
        ),
        SidebarNavItem(
          title: 'Success Stories',
          icon: Icons.stars_rounded,
          route: '/success-stories',
        ),
      ],
    },
    {
      'title': 'OPERATIONS',
      'items': [
        SidebarNavItem(
          title: 'Applications',
          icon: Icons.assignment_outlined,
          route: '/applications',
        ),
        SidebarNavItem(
          title: 'Client Feedback',
          icon: Icons.rate_review_outlined,
          route: '/feedback',
        ),
      ],
    },
    {
      'title': 'MANAGEMENT & FINANCE',
      'items': [
        SidebarNavItem(
          title: 'Users Directory',
          icon: Icons.people_outline_rounded,
          route: '/users',
        ),
        SidebarNavItem(
          title: 'Payments & Revenue',
          icon: Icons.account_balance_wallet_outlined,
          route: '/payments',
          adminOnly: true,
        ),
        SidebarNavItem(
          title: 'Affiliate Partners',
          icon: Icons.campaign_outlined,
          route: '/affiliates',
        ),
      ],
    },
    {
      'title': 'ACCESS CONTROL',
      'items': [
        SidebarNavItem(
          title: 'Team & Permissions',
          icon: Icons.security_rounded,
          route: '/team',
          adminOnly: true,
        ),
      ],
    },
    {
      'title': 'SYSTEM',
      'items': [
        SidebarNavItem(
          title: 'Audit Logs',
          icon: Icons.history_rounded,
          route: '/audit-logs',
        ),
        SidebarNavItem(
          title: 'Settings',
          icon: Icons.settings_outlined,
          route: '/settings',
        ),
      ],
    },
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(adminAuthProvider);
    final isAdmin =
        authState is AdminAuthAuthenticated && authState.profile.isAdmin;
    final staffEmail = authState is AdminAuthAuthenticated
        ? authState.profile.email
        : 'admin@sbconsultant.site';
    final staffName = authState is AdminAuthAuthenticated
        ? (authState.profile.fullName ?? 'Staff Member')
        : 'Staff Member';

    // Filter menu items by role
    final menuGroups = <Map<String, dynamic>>[];
    for (final group in rawMenuGroups) {
      final items = (group['items'] as List<SidebarNavItem>)
          .where((item) => !item.adminOnly || isAdmin)
          .toList();
      if (items.isNotEmpty) {
        menuGroups.add({
          'title': group['title'],
          'items': items,
        });
      }
    }

    return Container(
      width: 260,
      decoration: const BoxDecoration(
        color: AdminColors.primaryDark,
        border: Border(
          right: BorderSide(color: Color(0xFF1E293B), width: 1),
        ),
      ),
      child: Column(
        children: [
          // Brand Emblem Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Color(0xFF1E293B), width: 1),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isAdmin
                          ? AdminColors.accentGold
                          : const Color(0xFF38BDF8),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.25),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Image.asset(
                    'assets/images/logo.jpg',
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: const Color(0xFF002444),
                      child: Center(
                        child: Text(
                          staffName.isNotEmpty ? staffName[0].toUpperCase() : 'S',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        AdminConstants.appName,
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: isAdmin
                                  ? AdminColors.accentGold
                                  : const Color(0xFF38BDF8),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            isAdmin ? 'SUPER ADMIN' : 'STAFF CONSOLE',
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              color: isAdmin
                                  ? AdminColors.accentGold
                                  : const Color(0xFF38BDF8),
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Menu Items List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 14),
              itemCount: menuGroups.length,
              itemBuilder: (context, groupIdx) {
                final group = menuGroups[groupIdx];
                final groupTitle = group['title'] as String;
                final items = group['items'] as List<SidebarNavItem>;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                      child: Text(
                        groupTitle,
                        style: const TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF64748B),
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                    ...items.map((item) {
                      final isSelected = currentRoute == item.route ||
                          (item.route != '/dashboard' &&
                              currentRoute.startsWith(item.route));

                      return Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 2),
                        child: Material(
                          color: isSelected
                              ? const Color(0xFF1B3A5C)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          child: InkWell(
                            onTap: () => context.go(item.route),
                            borderRadius: BorderRadius.circular(8),
                            hoverColor: const Color(0xFF0F2643),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 10),
                              child: Row(
                                children: [
                                  Icon(
                                    item.icon,
                                    size: 19,
                                    color: isSelected
                                        ? AdminColors.accentGold
                                        : const Color(0xFF94A3B8),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      item.title,
                                      style: TextStyle(
                                        fontSize: 13.5,
                                        fontWeight: isSelected
                                            ? FontWeight.w600
                                            : FontWeight.w500,
                                        color: isSelected
                                            ? Colors.white
                                            : const Color(0xFFCBD5E1),
                                      ),
                                    ),
                                  ),
                                  if (item.badgeCount != null)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AdminColors.accentGold,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        '${item.badgeCount}',
                                        style: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: AdminColors.primaryDark,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                );
              },
            ),
          ),

          // User info and sign out footer
          Container(
            padding: const EdgeInsets.all(14),
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: Color(0xFF1E293B), width: 1),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        staffName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        staffEmail,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 10.5,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Sign Out',
                  icon: const Icon(
                    Icons.logout_rounded,
                    size: 18,
                    color: Color(0xFF94A3B8),
                  ),
                  onPressed: () {
                    ref.read(adminAuthProvider.notifier).signOut();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
