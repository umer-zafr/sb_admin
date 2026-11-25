import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/config/supabase_config.dart';
import '../models/admin_user.dart';
import '../models/application_model.dart';
import '../models/booking_model.dart';
import 'admin_application_service.dart';
import 'admin_payment_service.dart';

class DashboardMetrics {
  const DashboardMetrics({
    required this.totalUsers,
    required this.totalApplications,
    required this.pendingApplications,
    required this.approvedApplications,
    required this.rejectedApplications,
    this.totalBookings = 0,
    this.pendingBookings = 0,
    required this.activeVisas,
    required this.activeJobs,
    required this.activeScholarships,
    required this.totalRevenue,
    required this.recentApplications,
    required this.recentUsers,
    this.recentBookings = const [],
  });

  final int totalUsers;
  final int totalApplications;
  final int pendingApplications;
  final int approvedApplications;
  final int rejectedApplications;
  final int totalBookings;
  final int pendingBookings;
  final int activeVisas;
  final int activeJobs;
  final int activeScholarships;
  final double totalRevenue;
  final List<ApplicationItem> recentApplications;
  final List<AdminUserProfile> recentUsers;
  final List<ConsultancyBookingItem> recentBookings;
}

class AdminDashboardService {
  AdminDashboardService._();
  static final instance = AdminDashboardService._();

  SupabaseClient get _client => SupabaseConfig.client;

  Future<DashboardMetrics> getMetrics() async {
    // 1. Total registered clients (excluding administrative and staff accounts)
    int totalUsers = 0;
    try {
      final profilesRes = await _client
          .from('profiles')
          .select('id, role')
          .neq('role', 'admin')
          .neq('role', 'staff')
          .timeout(const Duration(seconds: 8));
      totalUsers = (profilesRes as List).length;
    } catch (e) {
      debugPrint('Dashboard: error fetching total users: $e');
    }

    // 2. Applications stats
    int pendingApps = 0;
    int approvedApps = 0;
    int rejectedApps = 0;
    int totalApplications = 0;
    final Set<String> dbAppIds = <String>{};

    try {
      final appsRes = await _client
          .from('applications')
          .select('id, status')
          .timeout(const Duration(seconds: 8));
      final appRows = List<Map<String, dynamic>>.from(appsRes);

      for (final app in appRows) {
        final s = (app['status']?.toString() ?? '').toLowerCase();
        if (s == 'submitted' || s == 'in_review' || s == 'pending' || s == 'under_review') {
          pendingApps++;
        } else if (s == 'approved' || s == 'completed') {
          approvedApps++;
        } else if (s == 'rejected' || s == 'cancelled') {
          rejectedApps++;
        }
      }

      for (final r in appRows) {
        final id = r['id']?.toString().toLowerCase();
        if (id != null) dbAppIds.add(id);
      }
      totalApplications = appRows.length;
    } catch (e) {
      debugPrint('Dashboard: error fetching applications stats: $e');
    }

    for (final live in AdminApplicationService.instance.liveApplications) {
      if (!dbAppIds.contains(live.id.toLowerCase())) {
        pendingApps++;
      }
    }
    totalApplications += AdminApplicationService.instance.liveApplications
        .where((l) => !dbAppIds.contains(l.id.toLowerCase()))
        .length;

    // 3. Catalog stats
    int activeVisas = 0;
    try {
      activeVisas = await _client
          .from('visa_listings')
          .count(CountOption.exact)
          .timeout(const Duration(seconds: 8));
    } catch (e) {
      debugPrint('Dashboard: error fetching visa count: $e');
    }

    int activeJobs = 0;
    try {
      final activeJobsRows = await _client
          .from('sponsored_jobs')
          .select('id')
          .eq('type', 'job')
          .eq('is_active', true)
          .timeout(const Duration(seconds: 8));
      activeJobs = (activeJobsRows as List).length;
    } catch (e) {
      debugPrint('Dashboard: error fetching jobs count: $e');
    }

    int activeScholarships = 0;
    try {
      final activeScholarshipsRows = await _client
          .from('sponsored_jobs')
          .select('id')
          .eq('type', 'scholarship')
          .eq('is_active', true)
          .timeout(const Duration(seconds: 8));
      activeScholarships = (activeScholarshipsRows as List).length;
    } catch (e) {
      debugPrint('Dashboard: error fetching scholarships count: $e');
    }

    // 4. Total revenue
    double totalRevenue = 0;
    try {
      final paymentsRes = await _client
          .from('payments')
          .select('amount, status')
          .inFilter('status', ['success', 'completed'])
          .timeout(const Duration(seconds: 8));
      for (final p in paymentsRes) {
        totalRevenue += (p['amount'] as num?)?.toDouble() ?? 0.0;
      }
    } catch (_) {
      totalRevenue = 0;
    }
    for (final livePay in AdminPaymentService.instance.livePayments) {
      if (livePay.status == 'success' || livePay.status == 'completed') {
        totalRevenue += livePay.amount;
      }
    }

    // 5. Recent applications
    final combinedRecent = <ApplicationItem>[];
    final seenIds = <String>{};

    for (final live in AdminApplicationService.instance.liveApplications) {
      combinedRecent.add(live);
      if (live.id.isNotEmpty) seenIds.add(live.id.toLowerCase());
      if (live.referenceNumber.isNotEmpty) seenIds.add(live.referenceNumber.toLowerCase());
    }

    try {
      final recentAppsRes = await _client
          .from('applications')
          .select('*')
          .order('applied_at', ascending: false)
          .limit(10)
          .timeout(const Duration(seconds: 8));
      final dbRecentApps = List<Map<String, dynamic>>.from(recentAppsRes)
          .map(ApplicationItem.fromMap)
          .toList();

      for (final app in dbRecentApps) {
        final idLow = app.id.toLowerCase();
        final refLow = app.referenceNumber.toLowerCase();
        if (!seenIds.contains(idLow) && !seenIds.contains(refLow)) {
          combinedRecent.add(app);
          if (idLow.isNotEmpty) seenIds.add(idLow);
          if (refLow.isNotEmpty) seenIds.add(refLow);
        }
      }
    } catch (e) {
      debugPrint('Dashboard: error fetching recent applications: $e');
    }
    final recentApps = combinedRecent.take(6).toList();

    // 6. Recent clients (excluding admins/staff)
    final recentUsers = <AdminUserProfile>[];
    try {
      final recentUsersRes = await _client
          .from('profiles')
          .select('*')
          .neq('role', 'admin')
          .neq('role', 'staff')
          .order('created_at', ascending: false)
          .limit(5)
          .timeout(const Duration(seconds: 8));
      recentUsers.addAll(List<Map<String, dynamic>>.from(recentUsersRes)
          .map((m) => AdminUserProfile.fromMap(m)));
    } catch (e) {
      debugPrint('Dashboard: error fetching recent users: $e');
    }

    return DashboardMetrics(
      totalUsers: totalUsers,
      totalApplications: totalApplications,
      pendingApplications: pendingApps,
      approvedApplications: approvedApps,
      rejectedApplications: rejectedApps,
      totalBookings: 0,
      pendingBookings: 0,
      activeVisas: activeVisas,
      activeJobs: activeJobs,
      activeScholarships: activeScholarships,
      totalRevenue: totalRevenue,
      recentApplications: recentApps,
      recentUsers: recentUsers,
      recentBookings: const [],
    );
  }
}
