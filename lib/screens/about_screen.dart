import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('معلومات التطبيق')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Image.asset('assets/images/app_icon.png', width: 110, height: 110),
              ),
              const SizedBox(height: 20),
              const Text(kAppName,
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: AppColors.gold)),
              const SizedBox(height: 8),
              const Text('تطبيق تسجيل نتائج ألعاب الورق والدومينو',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 16),
              Text('الإصدار $kAppVersion', style: const TextStyle(color: AppColors.textSecondary)),
            ],
          ),
        ),
      ),
    );
  }
}
