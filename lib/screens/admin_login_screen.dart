import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import '../providers/providers.dart';
import '../services/supabase_service.dart';
import 'admin_panel_screen.dart';

class AdminLoginScreen extends ConsumerStatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  ConsumerState<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends ConsumerState<AdminLoginScreen> {
  final _controller = TextEditingController();
  bool _loading = false;
  String? _error;

  Future<void> _submit() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final remote = SupabaseService.instance;
    bool ok = false;

    if (!remote.isConfigured) {
      _error = 'لم يتم ربط التطبيق بقاعدة بيانات Supabase بعد.\n'
          'افتح lib/services/supabase_service.dart وضع رابط ومفتاح مشروعك.';
    } else {
      try {
        ok = await remote.verifyAdminPassword(_controller.text.trim());
        if (!ok) _error = 'كلمة المرور غير صحيحة';
      } catch (e) {
        _error = 'تعذّر التحقق من كلمة المرور. تأكد من الاتصال بالإنترنت.';
      }
    }

    setState(() => _loading = false);

    if (ok && mounted) {
      ref.read(isAdminLoggedInProvider.notifier).state = true;
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const AdminPanelScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('دخول الأدمن')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.admin_panel_settings_rounded, size: 72, color: AppColors.gold),
            const SizedBox(height: 24),
            TextField(
              controller: _controller,
              obscureText: true,
              decoration: const InputDecoration(
                hintText: 'كلمة مرور الأدمن',
                prefixIcon: Icon(Icons.lock_outline_rounded),
              ),
              onSubmitted: (_) => _submit(),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: AppColors.red), textAlign: TextAlign.center),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _submit,
                child: _loading
                    ? const SizedBox(
                        height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('دخول'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
