import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../screens/home_screen.dart';
import '../screens/leaderboard_screen.dart';
import '../screens/history_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/about_screen.dart';
import '../screens/admin_login_screen.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 28),
              alignment: Alignment.center,
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 34,
                    backgroundImage: AssetImage('assets/images/app_icon.png'),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    kAppName,
                    style: const TextStyle(
                      color: AppColors.gold,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(),
            _item(context, Icons.home_rounded, 'الرئيسية', () {
              Navigator.pushReplacement(
                  context, MaterialPageRoute(builder: (_) => const HomeScreen()));
            }),
            _item(context, Icons.emoji_events_rounded, 'لوحة المتصدرين', () {
              Navigator.push(
                  context, MaterialPageRoute(builder: (_) => const LeaderboardScreen()));
            }),
            _item(context, Icons.history_rounded, 'سجل المباريات', () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const HistoryScreen()));
            }),
            _item(context, Icons.settings_rounded, 'الإعدادات', () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
            }),
            _item(context, Icons.info_rounded, 'معلومات التطبيق', () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const AboutScreen()));
            }),
            const Spacer(),
            const Divider(),
            _item(context, Icons.admin_panel_settings_rounded, 'دخول الأدمن', () {
              Navigator.push(
                  context, MaterialPageRoute(builder: (_) => const AdminLoginScreen()));
            }, color: AppColors.red),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _item(BuildContext context, IconData icon, String label, VoidCallback onTap,
      {Color? color}) {
    return ListTile(
      leading: Icon(icon, color: color ?? AppColors.gold),
      title: Text(label, style: TextStyle(color: color ?? AppColors.textPrimary)),
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
    );
  }
}
