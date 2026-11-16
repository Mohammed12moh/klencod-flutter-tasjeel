import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'theme/app_theme.dart';
import 'services/supabase_service.dart';
import 'services/sync_service.dart';
import 'screens/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // تهيئة Supabase - عدّل القيم في lib/services/supabase_service.dart
  try {
    await SupabaseService.initialize();
  } catch (_) {
    // إذا لم يتم ضبط المشروع بعد، يستمر التطبيق بالعمل محلياً بدون إنترنت
  }

  // بدء خدمة المزامنة التلقائية في الخلفية
  SyncService.instance.start();

  runApp(const ProviderScope(child: TasjeelApp()));
}

class TasjeelApp extends StatelessWidget {
  const TasjeelApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: kAppName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.dark,
      locale: const Locale('ar'),
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: child!,
        );
      },
      home: const HomeScreen(),
    );
  }
}