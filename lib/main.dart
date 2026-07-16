import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config/supabase_config.dart';
import 'providers/auth_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/user_provider.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';
import 'utils/in_memory_storage.dart';

Future<void> main() async {
  // Catch all async errors
  await runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    // Catch all Flutter framework errors
    FlutterError.onError = (FlutterErrorDetails details) {
      debugPrint('FlutterError: ${details.exception}');
      debugPrint('Stack: ${details.stack}');
    };

    try {
      await Supabase.initialize(
        url: SupabaseConfig.supabaseUrl,
        anonKey: SupabaseConfig.supabaseAnonKey,
        authOptions: FlutterAuthClientOptions(
          authFlowType: AuthFlowType.implicit,
          // Use in-memory storage on web to avoid localStorage.init() crash
          localStorage: kIsWeb ? InMemoryLocalStorage() : null,
        ),
      );
      debugPrint('Supabase initialized OK');
    } catch (e, st) {
      debugPrint('Supabase init error: $e\n$st');
    }

    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider()),
          ChangeNotifierProvider(create: (_) => UserProvider()),
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ],
        child: const AreteApp(),
      ),
    );
  }, (error, stack) {
    debugPrint('Uncaught error: $error\n$stack');
  });
}

class AreteApp extends StatelessWidget {
  const AreteApp({super.key});

  @override
  Widget build(BuildContext context) {
    context.watch<AuthProvider>();
    final themeMode = context.watch<ThemeProvider>().mode;

    return MaterialApp.router(
      title: 'Arete',
      debugShowCheckedModeBanner: false,
      routerConfig: appRouter,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
    );
  }
}
