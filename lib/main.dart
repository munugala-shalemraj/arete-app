import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config/supabase_config.dart';
import 'providers/auth_provider.dart';
import 'providers/user_provider.dart';
import 'router/app_router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: SupabaseConfig.supabaseUrl,
    anonKey: SupabaseConfig.supabaseAnonKey,
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
      ],
      child: const AreteApp(),
    ),
  );
}

class AreteApp extends StatelessWidget {
  const AreteApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Rebuild router when auth state changes so redirects fire correctly
    context.watch<AuthProvider>();

    return MaterialApp.router(
      title: 'Arete',
      debugShowCheckedModeBanner: false,
      routerConfig: appRouter,
      theme: _buildTheme(),
    );
  }

  ThemeData _buildTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF0F0F1A),
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFFC9A84C),
        secondary: Color(0xFF4F8EF7),
        surface: Color(0xFF1A1A2E),
        onPrimary: Colors.black,
        onSecondary: Colors.white,
        onSurface: Colors.white,
      ),
      textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: const Color(0xFF1A1A2E),
        indicatorColor: const Color(0xFFC9A84C).withOpacity(0.2),
        labelTextStyle: WidgetStateProperty.all(
          GoogleFonts.outfit(fontSize: 12),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xFF0F0F1A),
        elevation: 0,
        titleTextStyle: GoogleFonts.outfit(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: Color(0xFF1A1A2E),
        contentTextStyle: TextStyle(color: Colors.white),
      ),
    );
  }
}
