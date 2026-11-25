import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/admin_banner_model.dart';
import '../models/admin_success_story_model.dart';
import '../models/admin_user.dart';
import '../models/affiliate_model.dart';
import '../models/application_model.dart';
import '../models/audit_log_model.dart';
import '../models/booking_model.dart';
import '../models/document_model.dart';
import '../models/job_model.dart';
import '../models/payment_model.dart';
import '../models/visa_model.dart';
import '../services/admin_affiliate_service.dart';
import '../services/admin_application_service.dart';
import '../services/admin_audit_service.dart';
import '../services/admin_banner_service.dart';
import '../services/admin_booking_service.dart';
import '../services/admin_dashboard_service.dart';
import '../services/admin_document_service.dart';
import '../services/admin_job_service.dart';
import '../services/admin_payment_service.dart';
import '../services/admin_success_story_service.dart';
import '../services/admin_user_service.dart';
import '../services/admin_visa_service.dart';

// Live Realtime Revision Counters (Forces immediate fresh queries on Postgres changes)
class RevisionNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void increment() {
    state++;
  }
}

final dashboardMetricsRevisionProvider =
    NotifierProvider<RevisionNotifier, int>(RevisionNotifier.new);
final applicationsRevisionProvider =
    NotifierProvider<RevisionNotifier, int>(RevisionNotifier.new);
final bookingsRevisionProvider =
    NotifierProvider<RevisionNotifier, int>(RevisionNotifier.new);
final paymentsRevisionProvider =
    NotifierProvider<RevisionNotifier, int>(RevisionNotifier.new);
final visasRevisionProvider =
    NotifierProvider<RevisionNotifier, int>(RevisionNotifier.new);
final successStoriesRevisionProvider =
    NotifierProvider<RevisionNotifier, int>(RevisionNotifier.new);
final bannersRevisionProvider =
    NotifierProvider<RevisionNotifier, int>(RevisionNotifier.new);
final affiliatesRevisionProvider =
    NotifierProvider<RevisionNotifier, int>(RevisionNotifier.new);

// 1. Dashboard Metrics Provider
final dashboardMetricsProvider = FutureProvider<DashboardMetrics>((ref) async {
  ref.watch(dashboardMetricsRevisionProvider);
  return AdminDashboardService.instance.getMetrics();
});

// 2. Users Provider
final usersListProvider =
    FutureProvider.family<List<AdminUserProfile>, ({String? search, String? role})>(
        (ref, params) async {
  return AdminUserService.instance.getUsers(
    searchQuery: params.search,
    roleFilter: params.role,
  );
});

// 3. User Detail Provider
final userDetailProvider =
    FutureProvider.family<UserDetailData, String>((ref, userId) async {
  return AdminUserService.instance.getUserDetail(userId);
});

// 4. Visas Provider
final visasListProvider = FutureProvider.family<
    List<VisaListingItem>,
    ({String? search, String? categoryId, String? countryId, bool? isActive})>(
  (ref, params) async {
    ref.watch(visasRevisionProvider);
    return AdminVisaService.instance.getVisas(
      searchQuery: params.search,
      categoryId: params.categoryId,
      countryId: params.countryId,
      isActive: params.isActive,
    );
  },
);

final visaCategoriesProvider = FutureProvider<List<VisaCategoryItem>>((ref) async {
  return AdminVisaService.instance.getCategories();
});

final countriesProvider = FutureProvider<List<CountryItem>>((ref) async {
  return AdminVisaService.instance.getCountries();
});

// 5. Jobs & Scholarships Providers
final jobsListProvider = FutureProvider.family<List<SponsoredJobItem>,
    ({String? search, bool? isActive})>((ref, params) async {
  return AdminJobService.instance.getJobs(
    searchQuery: params.search,
    isActive: params.isActive,
  );
});

final scholarshipsListProvider = FutureProvider.family<List<SponsoredJobItem>,
    ({String? search, bool? isActive})>((ref, params) async {
  return AdminJobService.instance.getScholarships(
    searchQuery: params.search,
    isActive: params.isActive,
  );
});

// 6. Applications Providers
final applicationsListProvider = FutureProvider.family<
    List<ApplicationItem>,
    ({String? search, String? status, String? category})>((ref, params) async {
  ref.watch(applicationsRevisionProvider);
  return AdminApplicationService.instance.getApplications(
    searchQuery: params.search,
    statusFilter: params.status,
    categoryFilter: params.category,
  );
});

final applicationDetailProvider =
    FutureProvider.family<ApplicationItem, String>((ref, applicationId) async {
  ref.watch(applicationsRevisionProvider);
  return AdminApplicationService.instance.getApplicationDetail(applicationId);
});

// 7. Bookings Provider
final bookingsListProvider = FutureProvider.family<List<ConsultancyBookingItem>,
    ({String? search, String? status})>((ref, params) async {
  ref.watch(bookingsRevisionProvider);
  return AdminBookingService.instance.getBookings(
    searchQuery: params.search,
    statusFilter: params.status,
  );
});

// 8. Payments Provider
final paymentsListProvider = FutureProvider.family<
    List<AdminPaymentItem>,
    ({String? search, String? status, String? method})>((ref, params) async {
  ref.watch(paymentsRevisionProvider);
  return AdminPaymentService.instance.getPayments(
    searchQuery: params.search,
    statusFilter: params.status,
    methodFilter: params.method,
  );
});

// 9. Documents Provider
final documentsListProvider = FutureProvider.family<
    List<UserDocumentItem>,
    ({String? search, String? status, String? type})>((ref, params) async {
  return AdminDocumentService.instance.getDocuments(
    searchQuery: params.search,
    statusFilter: params.status,
    typeFilter: params.type,
  );
});

// 10. Audit Logs Provider
final auditLogsListProvider =
    FutureProvider<List<AdminAuditLogItem>>((ref) async {
  return AdminAuditService.instance.getAuditLogs();
});

// 11. Success Stories Provider
final successStoriesListProvider = FutureProvider.family<
    List<AdminSuccessStoryItem>,
    ({String? search, bool? isPublished})>((ref, params) async {
  ref.watch(successStoriesRevisionProvider);
  return AdminSuccessStoryService.instance.getStories(
    searchQuery: params.search,
    isPublished: params.isPublished,
  );
});

// 12. Promotional & Category Banners Provider
final bannersListProvider = FutureProvider.family<
    List<AdminBannerItem>,
    ({String? search, String? placement, bool? isActive})>((ref, params) async {
  ref.watch(bannersRevisionProvider);
  return AdminBannerService.instance.getBanners(
    placement: params.placement,
    isActive: params.isActive,
    searchQuery: params.search,
  );
});

// 13. Affiliate Partners & Promo Codes Provider
final affiliatesListProvider = FutureProvider.family<
    List<AffiliateItem>,
    ({String? search, String? status})>((ref, params) async {
  ref.watch(affiliatesRevisionProvider);
  return AdminAffiliateService.instance.getAffiliates(
    searchQuery: params.search,
    status: params.status,
  );
});
