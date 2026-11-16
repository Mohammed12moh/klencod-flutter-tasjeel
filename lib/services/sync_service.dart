import 'package:connectivity_plus/connectivity_plus.dart';
import 'local_db_service.dart';
import 'supabase_service.dart';

/// يراقب حالة الإنترنت، وعند عودته يرفع كل البيانات غير المتزامنة
/// (المباريات واللاعبين) إلى Supabase دون حذف البيانات المحلية
/// ودون تكرار المباراة نفسها مرتين (upsert بمفتاح id الثابت).
class SyncService {
  SyncService._internal();
  static final SyncService instance = SyncService._internal();

  bool _isSyncing = false;

  Future<void> start() async {
    // مزامنة أولية عند تشغيل التطبيق
    await syncNow();

    Connectivity().onConnectivityChanged.listen((results) async {
      final hasConnection = results.any((r) => r != ConnectivityResult.none);
      if (hasConnection) {
        await syncNow();
      }
    });
  }

  Future<void> syncNow() async {
    if (_isSyncing) return;
    if (!SupabaseService.instance.isConfigured) return;

    final connectivity = await Connectivity().checkConnectivity();
    final hasConnection = connectivity.any((r) => r != ConnectivityResult.none);
    if (!hasConnection) return;

    _isSyncing = true;
    try {
      final db = LocalDbService.instance;
      final remote = SupabaseService.instance;

      final unsyncedPlayers = await db.getUnsyncedPlayers();
      for (final p in unsyncedPlayers) {
        await remote.pushPlayer(p);
        await db.upsertPlayer(p.copyWith(synced: true));
      }

      final unsyncedMatches = await db.getUnsyncedMatches();
      for (final m in unsyncedMatches) {
        await remote.pushMatch(m);
        await db.upsertMatch(m.copyWith(synced: true));
      }
    } catch (_) {
      // فشل الاتصال لا يجب أن يحذف أو يفسد أي بيانات محلية
      // ستتم إعادة المحاولة عند توفر الاتصال مرة أخرى
    } finally {
      _isSyncing = false;
    }
  }
}
