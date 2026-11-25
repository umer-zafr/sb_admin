import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/config/supabase_config.dart';
import '../models/booking_model.dart';

class AdminBookingService {
  AdminBookingService._();
  static final instance = AdminBookingService._();

  SupabaseClient get _client => SupabaseConfig.client;

  Future<List<ConsultancyBookingItem>> getBookings({
    String? searchQuery,
    String? statusFilter,
  }) async {
    var query = _client.from('consultancy_bookings').select('*');

    if (statusFilter != null && statusFilter.isNotEmpty && statusFilter != 'all') {
      query = query.eq('status', statusFilter);
    }
    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final q = searchQuery.trim();
      query = query.or('booking_reference.ilike.%$q%,service_title.ilike.%$q%,consultant_name.ilike.%$q%');
    }

    final res = await query.order('created_at', ascending: false);
    final rows = List<Map<String, dynamic>>.from(res);

    final bookings = <ConsultancyBookingItem>[];
    for (final row in rows) {
      final uid = row['user_id']?.toString() ?? '';
      String? userName;
      String? userEmail;

      if (uid.isNotEmpty) {
        final profile = await _client
            .from('profiles')
            .select('full_name, email')
            .eq('id', uid)
            .maybeSingle();
        userName = profile?['full_name']?.toString();
        userEmail = profile?['email']?.toString();
      }

      bookings.add(ConsultancyBookingItem.fromMap(
        row,
        userName: userName,
        userEmail: userEmail,
      ));
    }
    return bookings;
  }

  Future<void> updateBookingStatus(String bookingId, String newStatus) async {
    await _client.from('consultancy_bookings').update({
      'status': newStatus,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', bookingId);

    await _logAudit('update_booking_status', 'booking', bookingId, {'status': newStatus});
  }

  Future<void> rescheduleBooking({
    required String bookingId,
    required String bookingDate,
    required String timeSlot,
    String? meetingLink,
    String? consultantName,
  }) async {
    final updates = <String, dynamic>{
      'booking_date': bookingDate,
      'booking_time_slot': timeSlot,
      'updated_at': DateTime.now().toIso8601String(),
    };
    if (meetingLink != null) updates['meeting_link'] = meetingLink;
    if (consultantName != null) updates['consultant_name'] = consultantName;

    await _client.from('consultancy_bookings').update(updates).eq('id', bookingId);

    await _logAudit('reschedule_booking', 'booking', bookingId, updates);
  }

  Future<void> addBookingNotes(String bookingId, String notes) async {
    await _client.from('consultancy_bookings').update({
      'admin_notes': notes,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', bookingId);
  }

  Future<void> _logAudit(
    String action,
    String entityType,
    String entityId,
    Map<String, dynamic> details,
  ) async {
    try {
      final adminId = _client.auth.currentUser?.id;
      await _client.from('admin_audit_logs').insert({
        'admin_id': adminId,
        'action': action,
        'entity_type': entityType,
        'entity_id': entityId,
        'details': details,
      });
    } catch (_) {}
  }
}
