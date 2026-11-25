import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/config/supabase_config.dart';
import '../models/feedback_model.dart';

class AdminFeedbackService {
  AdminFeedbackService._();
  static final instance = AdminFeedbackService._();

  SupabaseClient get _client => SupabaseConfig.client;

  Future<List<AdminFeedbackItem>> getFeedbackList({
    String? searchQuery,
    int? ratingFilter,
  }) async {
    try {
      var query = _client.from('application_feedback').select(
        '*, profiles:user_id(full_name, email, phone), applications:application_id(reference_number, title, applicant_name, applicant_email, applicant_phone)',
      );

      if (ratingFilter != null && ratingFilter > 0) {
        query = query.eq('rating', ratingFilter);
      }

      final res = await query.order('created_at', ascending: false);
      final allItems = List<Map<String, dynamic>>.from(res)
          .map(AdminFeedbackItem.fromMap)
          .toList();

      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        final q = searchQuery.trim().toLowerCase();
        return allItems.where((item) {
          final name = item.effectiveName.toLowerCase();
          final email = item.effectiveEmail.toLowerCase();
          final phone = item.effectivePhone.toLowerCase();
          final ref = (item.appReference ?? '').toLowerCase();
          final title = (item.visaTitle ?? '').toLowerCase();
          final comments = item.comments.toLowerCase();
          final tag = item.standoutTag.toLowerCase();

          return name.contains(q) ||
              email.contains(q) ||
              phone.contains(q) ||
              ref.contains(q) ||
              title.contains(q) ||
              comments.contains(q) ||
              tag.contains(q);
        }).toList();
      }

      return allItems;
    } catch (_) {
      // Fallback direct query if joins fail on specific RLS
      final res = await _client
          .from('application_feedback')
          .select('*')
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(res)
          .map(AdminFeedbackItem.fromMap)
          .toList();
    }
  }
}
