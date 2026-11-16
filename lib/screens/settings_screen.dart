import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import '../providers/providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(gameSettingsProvider);
    final notifier = ref.read(gameSettingsProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('الإعدادات')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _sectionTitle('المظهر'),
          SwitchListTile(
            activeColor: AppColors.gold,
            title: const Text('الوضع الليلي'),
            subtitle: const Text('التطبيق مصمم أساساً للوضع الداكن',
                style: TextStyle(color: AppColors.textSecondary)),
            value: settings.darkMode,
            onChanged: (v) => notifier.setDarkMode(v),
          ),
          SwitchListTile(
            activeColor: AppColors.gold,
            title: const Text('صوت التنبيهات'),
            value: settings.soundEnabled,
            onChanged: (v) => notifier.setSoundEnabled(v),
          ),
          const Divider(),
          _sectionTitle('معلومات التطبيق'),
          const ListTile(
            title: Text('رقم الإصدار'),
            trailing: Text(kAppVersion, style: TextStyle(color: AppColors.gold)),
          ),
          ListTile(
            title: const Text('سياسة الخصوصية'),
            trailing: const Icon(Icons.chevron_left_rounded),
            onTap: () => _showTextDialog(
              context,
              'سياسة الخصوصية',
              'يحفظ تطبيق "تسجيل" بيانات المباريات واللاعبين لعرض لوحة المتصدرين وسجل المباريات فقط، ولا يتم مشاركة بياناتك مع أي طرف ثالث.',
            ),
          ),
          ListTile(
            title: const Text('سجل التحديثات'),
            trailing: const Icon(Icons.chevron_left_rounded),
            onTap: () => _showTextDialog(
              context,
              'سجل التحديثات',
              'الإصدار $kAppVersion: الإصدار الأول من التطبيق - تسجيل الورق والدومينو، سجل المباريات، لوحة المتصدرين، ولوحة أدمن بسيطة.',
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(title,
          style: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold, fontSize: 15)),
    );
  }

  void _showTextDialog(BuildContext context, String title, String body) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(title),
        content: Text(body),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إغلاق'))],
      ),
    );
  }
}
