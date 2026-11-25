import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/feedback_model.dart';
import '../services/admin_feedback_service.dart';

typedef FeedbackFilter = ({String? search, int? rating});

final adminFeedbackListProvider = FutureProvider.autoDispose
    .family<List<AdminFeedbackItem>, FeedbackFilter>((ref, filter) async {
  return AdminFeedbackService.instance.getFeedbackList(
    searchQuery: filter.search,
    ratingFilter: filter.rating,
  );
});
