import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

/// Service for dispatching external Push Notifications via OneSignal REST API.
class AdminPushService {
  AdminPushService._();
  static final AdminPushService instance = AdminPushService._();

  String get _appId =>
      dotenv.env['ONESIGNAL_APP_ID']?.trim() ??
      '9ca16da7-ffc6-4a56-82e8-0cc19746e8c3';

  String get _restApiKey =>
      dotenv.env['ONESIGNAL_REST_API_KEY']?.trim() ?? '';

  /// Send a push notification to a specific Supabase user ID.
  Future<bool> sendToUser({
    required String userId,
    required String title,
    required String message,
    String? route,
    String? largeIcon,
    String? bigPicture,
    Map<String, dynamic>? extraData,
  }) async {
    if (_restApiKey.isEmpty) {
      debugPrint('[AdminPushService] Warning: ONESIGNAL_REST_API_KEY is not set in .env');
      return false;
    }

    try {
      final payload = <String, dynamic>{
        'app_id': _appId,
        'include_external_user_ids': [userId],
        'include_aliases': {
          'external_id': [userId],
        },
        'target_channel': 'push',
        'priority': 10,
        // Visual Styling: Prominent large app logo on the right side, navy blue brand accent
        'android_accent_color': 'FF1B3A5C',
        'large_icon': largeIcon ?? 'ic_launcher',
        if (bigPicture != null && bigPicture.isNotEmpty)
          'big_picture': bigPicture,
        'android_visibility': 1,
        'headings': {'en': title},
        'contents': {'en': message},
        'data': {
          if (route != null) 'route': route,
          if (extraData != null) ...extraData,
        },
      };

      final response = await http.post(
        Uri.parse('https://onesignal.com/api/v1/notifications'),
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
          'Authorization': 'Key $_restApiKey',
        },
        body: jsonEncode(payload),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        debugPrint('[AdminPushService] Push sent to user $userId: $title');
        return true;
      } else {
        debugPrint(
            '[AdminPushService] Push failed (${response.statusCode}): ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('[AdminPushService] Error dispatching push: $e');
      return false;
    }
  }

  /// Broadcast a push notification to all subscribed mobile app clients.
  Future<bool> broadcastToAll({
    required String title,
    required String message,
    String? route,
    String? largeIcon,
    String? bigPicture,
    Map<String, dynamic>? extraData,
  }) async {
    if (_restApiKey.isEmpty) {
      debugPrint('[AdminPushService] Warning: ONESIGNAL_REST_API_KEY is not set in .env');
      return false;
    }

    try {
      final payload = <String, dynamic>{
        'app_id': _appId,
        'included_segments': ['Total Subscriptions'],
        'priority': 10,
        // Visual Styling: Prominent large app logo on the right side, navy blue brand accent
        'android_accent_color': 'FF1B3A5C',
        'large_icon': largeIcon ?? 'ic_launcher',
        if (bigPicture != null && bigPicture.isNotEmpty)
          'big_picture': bigPicture,
        'android_visibility': 1,
        'headings': {'en': title},
        'contents': {'en': message},
        'data': {
          if (route != null) 'route': route,
          if (extraData != null) ...extraData,
        },
      };

      final response = await http.post(
        Uri.parse('https://onesignal.com/api/v1/notifications'),
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
          'Authorization': 'Key $_restApiKey',
        },
        body: jsonEncode(payload),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        debugPrint('[AdminPushService] Broadcast push sent: $title');
        return true;
      } else {
        debugPrint(
            '[AdminPushService] Broadcast failed (${response.statusCode}): ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('[AdminPushService] Error broadcasting push: $e');
      return false;
    }
  }
}

