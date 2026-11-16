import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import '../providers/providers.dart';
import '../services/supabase_service.dart';

/// لوحة أدمن بسيطة تحتوي فقط على الوظائف الثماني المطلوبة:
/// الإعلانات، التحديثات، الصور، النصوص، إعدادات الألعاب،
/// الرسائل، وضع الصيانة، وتغيير كلمة المرور.
/// لا توجد إحصائيات أو رسوم بيانية أو إدارة مستخدمين هنا عمداً.
class AdminPanelScreen extends ConsumerWidget {
  const AdminPanelScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAdmin = ref.watch(isAdminLoggedInProvider);
    if (!isAdmin) {
      return const Scaffold(body: Center(child: Text('غير مصرح')));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('لوحة الأدمن'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: () {
              ref.read(isAdminLoggedInProvider.notifier).state = false;
              Navigator.pop(context);
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _adminTile(context, Icons.campaign_rounded, 'إدارة الإعلانات',
              'إضافة أو تعديل أو حذف إعلان', () => _showAnnouncementDialog(context, 'ad')),
          _adminTile(context, Icons.system_update_rounded, 'إدارة التحديثات',
              'كتابة تحديث جديد يظهر للمستخدمين', () => _showAnnouncementDialog(context, 'update')),
          _adminTile(context, Icons.image_rounded, 'إدارة الصور',
              'تغيير صورة الورق وصورة الدومينو', () => _showComingFromAssets(context)),
          _adminTile(context, Icons.text_fields_rounded, 'إدارة النصوص',
              'تعديل نصوص الصفحة الرئيسية والتطبيق', () => _showTextSettingsDialog(context)),
          _adminTile(context, Icons.tune_rounded, 'إعدادات الألعاب',
              'نقاط فوز الدومينو وقيمة الطرقة الافتراضية', () => _showGameSettingsDialog(context, ref)),
          _adminTile(context, Icons.notifications_active_rounded, 'الرسائل والتنبيهات',
              'إرسال رسالة تظهر لجميع المستخدمين', () => _showAnnouncementDialog(context, 'message')),
          _MaintenanceTile(),
          _adminTile(context, Icons.password_rounded, 'تغيير كلمة مرور الأدمن',
              'تحديث كلمة المرور المخزنة في Supabase', () => _showChangePasswordDialog(context)),
        ],
      ),
    );
  }

  Widget _adminTile(
      BuildContext context, IconData icon, String title, String subtitle, VoidCallback onTap) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: AppColors.gold),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: const TextStyle(color: AppColors.textSecondary)),
        trailing: const Icon(Icons.chevron_left_rounded),
        onTap: onTap,
      ),
    );
  }

  void _showAnnouncementDialog(BuildContext context, String type) {
    final titleCtrl = TextEditingController();
    final bodyCtrl = TextEditingController();
    final label = type == 'ad'
        ? 'إعلان'
        : type == 'update'
            ? 'تحديث'
            : 'رسالة';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('إضافة $label جديد'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: titleCtrl, decoration: const InputDecoration(hintText: 'العنوان')),
            const SizedBox(height: 10),
            TextField(
                controller: bodyCtrl,
                maxLines: 3,
                decoration: const InputDecoration(hintText: 'النص')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () async {
              await SupabaseService.instance
                  .addAnnouncement(titleCtrl.text.trim(), bodyCtrl.text.trim(), type);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('نشر'),
          ),
        ],
      ),
    );
  }

  void _showComingFromAssets(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('إدارة الصور'),
        content: const Text(
          'حالياً بطاقتا الدومينو والورق في الصفحة الرئيسية تستخدم أيقونات بدل صور، '
          'حتى تضع صورك الخاصة.\n\n'
          'لاستبدالها بصور حقيقية: ضع ملفين مثل\n'
          'assets/images/domino_card.png و assets/images/cards_card.png،\n'
          'أضفهما في pubspec.yaml ضمن assets، ثم استبدل الأيقونة بـ Image.asset '
          'في home_screen.dart. يمكن لاحقاً تطوير هذه الخطوة لرفع الصور مباشرة '
          'إلى Supabase Storage من هذه اللوحة.',
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('حسناً'))],
      ),
    );
  }

  void _showTextSettingsDialog(BuildContext context) {
    final titleCtrl = TextEditingController(text: 'شنو راح تلعب اليوم؟');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('تعديل نص الصفحة الرئيسية'),
        content: TextField(controller: titleCtrl),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () async {
              await SupabaseService.instance
                  .updateAppSettings({'home_title': titleCtrl.text.trim()});
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  void _showGameSettingsDialog(BuildContext context, WidgetRef ref) {
    final settings = ref.read(gameSettingsProvider);
    final winCtrl = TextEditingController(text: '${settings.dominoWinScore}');
    final knockCtrl = TextEditingController(text: '${settings.cardKnockValue}');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('إعدادات الألعاب الافتراضية'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: winCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'نقاط فوز الدومينو الافتراضية'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: knockCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'قيمة الطرقة الافتراضية (ورق)'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () async {
              final win = int.tryParse(winCtrl.text.trim());
              final knock = int.tryParse(knockCtrl.text.trim());
              if (win != null) await ref.read(gameSettingsProvider.notifier).setDominoWinScore(win);
              if (knock != null) {
                await ref.read(gameSettingsProvider.notifier).setCardKnockValue(knock);
              }
              await SupabaseService.instance.updateAppSettings({
                if (win != null) 'default_domino_win_score': win,
                if (knock != null) 'default_card_knock_value': knock,
              });
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context) {
    final newPassCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('تغيير كلمة مرور الأدمن'),
        content: TextField(
          controller: newPassCtrl,
          obscureText: true,
          decoration: const InputDecoration(hintText: 'كلمة المرور الجديدة'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () async {
              if (newPassCtrl.text.trim().length >= 6) {
                await SupabaseService.instance.changeAdminPassword(newPassCtrl.text.trim());
              }
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }
}

class _MaintenanceTile extends ConsumerStatefulWidget {
  @override
  ConsumerState<_MaintenanceTile> createState() => _MaintenanceTileState();
}

class _MaintenanceTileState extends ConsumerState<_MaintenanceTile> {
  bool _maintenance = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: SwitchListTile(
        activeColor: AppColors.red,
        secondary: const Icon(Icons.build_circle_rounded, color: AppColors.gold),
        title: const Text('وضع الصيانة', style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: const Text('إيقاف استخدام التطبيق مؤقتاً مع عرض رسالة صيانة',
            style: TextStyle(color: AppColors.textSecondary)),
        value: _maintenance,
        onChanged: (v) async {
          setState(() => _maintenance = v);
          await SupabaseService.instance.updateAppSettings({'maintenance_mode': v});
        },
      ),
    );
  }
}
