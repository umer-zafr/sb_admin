import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  SupabaseConfig._();

  static late final SupabaseClient client;

  static const String fallbackUrl = 'https://tpmdqfmtunxbnhpckkbh.supabase.co';
  static const String fallbackAnonKey =
      'sb_publishable_5n7vzIcQ-hXaBq0s3XliCw_J066pNPo';

  static Future<void> init() async {
    try {
      await dotenv.load(fileName: '.env');
    } catch (_) {
      // In web, fallback if .env is embedded or missing
    }

    final url = dotenv.maybeGet('SUPABASE_URL') ?? fallbackUrl;
    final anonKey = dotenv.maybeGet('SUPABASE_ANON_KEY') ?? fallbackAnonKey;

    await Supabase.initialize(
      url: url,
      // ignore: deprecated_member_use
      anonKey: anonKey,
    );

    client = Supabase.instance.client;
  }
}
