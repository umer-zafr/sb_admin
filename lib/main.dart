import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/config/supabase_config.dart';
import 'core/constants/admin_constants.dart';
import 'core/router/admin_router.dart';
import 'core/theme/admin_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase client
  await SupabaseConfig.init();

  runApp(
    const ProviderScope(
      child: SbConsultantsAdminApp(),
    ),
  );
}

class SbConsultantsAdminApp extends ConsumerWidget {
  const SbConsultantsAdminApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(adminRouterProvider);

    return MaterialApp.router(
      title: '${AdminConstants.appName} — Enterprise Admin Portal',
      debugShowCheckedModeBanner: false,
      theme: AdminTheme.lightTheme,
      routerConfig: router,
    );
  }
}
