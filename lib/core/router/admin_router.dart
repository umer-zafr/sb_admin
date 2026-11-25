import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/affiliates/affiliates_management_screen.dart';
import '../../features/applications/application_detail_screen.dart';
import '../../features/applications/applications_list_screen.dart';
import '../../features/audit/audit_logs_screen.dart';
import '../../features/auth/admin_login_screen.dart';
import '../../features/banners/banners_management_screen.dart';
import '../../features/dashboard/admin_dashboard_screen.dart';
import '../../features/documents/documents_list_screen.dart';
import '../../features/feedback/feedback_list_screen.dart';
import '../../features/jobs/jobs_list_screen.dart';
import '../../features/payments/payments_list_screen.dart';
import '../../features/scholarships/scholarships_list_screen.dart';
import '../../features/settings/admin_settings_screen.dart';
import '../../features/stories/success_stories_screen.dart';
import '../../features/team/team_management_screen.dart';
import '../../features/users/user_detail_screen.dart';
import '../../features/users/users_list_screen.dart';
import '../../features/visas/visa_categories_screen.dart';
import '../../features/visas/visas_list_screen.dart';
import '../../providers/admin_auth_provider.dart';

final adminRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(adminAuthProvider);

  return GoRouter(
    initialLocation: '/login',
    debugLogDiagnostics: false,
    redirect: (context, state) {
      final isLoggingIn = state.uri.path == '/login';

      if (authState is AdminAuthAuthenticated) {
        if (isLoggingIn) return '/dashboard';

        final path = state.uri.path;

        // 1. Permanently redirect removed bookings / consultancy call section to dashboard
        if (path == '/bookings' || path.startsWith('/bookings/')) {
          return '/dashboard';
        }

        // 2. Strict Two-Tier RBAC Guards:
        // Staff / Consultants are blocked from accessing payments and team access control
        if (!authState.profile.isAdmin) {
          if (path.startsWith('/payments') || path.startsWith('/team')) {
            return '/dashboard';
          }
        }

        return null;
      }

      // If NOT authenticated (Loading, Unauthenticated, or Initial), STRICTLY guard all routes!
      if (!isLoggingIn) {
        return '/login';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const AdminLoginScreen(),
      ),
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => const AdminDashboardScreen(),
      ),
      GoRoute(
        path: '/users',
        builder: (context, state) => const UsersListScreen(),
        routes: [
          GoRoute(
            path: ':id',
            builder: (context, state) {
              final id = state.pathParameters['id'] ?? '';
              return UserDetailScreen(userId: id);
            },
          ),
        ],
      ),
      GoRoute(
        path: '/visas',
        builder: (context, state) => const VisasListScreen(),
        routes: [
          GoRoute(
            path: 'categories',
            builder: (context, state) => const VisaCategoriesScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/jobs',
        builder: (context, state) => const JobsListScreen(),
      ),
      GoRoute(
        path: '/scholarships',
        builder: (context, state) => const ScholarshipsListScreen(),
      ),
      GoRoute(
        path: '/success-stories',
        builder: (context, state) => const SuccessStoriesScreen(),
      ),
      GoRoute(
        path: '/banners',
        builder: (context, state) => const BannersManagementScreen(),
      ),
      GoRoute(
        path: '/applications',
        builder: (context, state) => const ApplicationsListScreen(),
        routes: [
          GoRoute(
            path: ':id',
            builder: (context, state) {
              final id = state.pathParameters['id'] ?? '';
              return ApplicationDetailScreen(applicationId: id);
            },
          ),
        ],
      ),
      GoRoute(
        path: '/feedback',
        builder: (context, state) => const FeedbackListScreen(),
      ),
      // Team & Permissions (Super Admin Only)
      GoRoute(
        path: '/team',
        builder: (context, state) => const TeamManagementScreen(),
      ),
      // Payments & Financials (Super Admin Only)
      GoRoute(
        path: '/payments',
        builder: (context, state) => const PaymentsListScreen(),
      ),
      // Affiliate Partners & Influencer Marketing
      GoRoute(
        path: '/affiliates',
        builder: (context, state) => const AffiliatesManagementScreen(),
      ),
      GoRoute(
        path: '/documents',
        builder: (context, state) => const DocumentsListScreen(),
      ),
      GoRoute(
        path: '/audit-logs',
        builder: (context, state) => const AuditLogsScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const AdminSettingsScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text('Page Not Found: ${state.uri}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => context.go('/dashboard'),
              child: const Text('Return to Dashboard'),
            ),
          ],
        ),
      ),
    ),
  );
});
