import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/bindings/initial_binding.dart';
import 'app/routes/app_pages.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: '.env');
  await GetStorage.init();

  await Supabase.initialize(
    url: dotenv.env['NEXT_PUBLIC_SUPABASE_URL'] ??
        dotenv.env['SUPABASE_URL'] ??
        '',
    anonKey: dotenv.env['NEXT_PUBLIC_SUPABASE_ANON_KEY'] ??
        dotenv.env['SUPABASE_ANON_KEY'] ??
        '',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    const royalGreen = Color(0xFF0B6B3A);
    return GetMaterialApp(
      title: 'Zulu Inventory',
      debugShowCheckedModeBanner: false,
      initialBinding: InitialBinding(),
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: royalGreen,
          brightness: Brightness.light,
        ),
        appBarTheme: const AppBarTheme(elevation: 0),
        navigationBarTheme: NavigationBarThemeData(
          indicatorColor: royalGreen.withValues(alpha: 0.14),
          iconTheme: WidgetStateProperty.resolveWith<IconThemeData>(
            (states) {
              final selected = states.contains(WidgetState.selected);
              return IconThemeData(
                color: selected ? royalGreen : const Color(0xFF667085),
              );
            },
          ),
          labelTextStyle: WidgetStateProperty.resolveWith<TextStyle>(
            (states) {
              final selected = states.contains(WidgetState.selected);
              return TextStyle(
                color: selected ? royalGreen : const Color(0xFF667085),
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              );
            },
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: const Color(0xFFF3FAF6),
        ),
      ),
      initialRoute: AppPages.INITIAL,
      getPages: AppPages.routes,
    );
  }
}
