import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/player.dart';
import '../models/match_model.dart';

/// ضع رابط ومفتاح مشروعك في Supabase هنا (anon/public key فقط،
/// ولا تضع أبداً Service Role Key داخل تطبيق Android - هذا مطلوب أمنياً).
class SupabaseConfig {
  static const String url = 'https://YOUR_PROJECT.supabase.co';
  static const String anonKey = 'YOUR_SUPABASE_ANON_KEY';
}

String hashPassword(String plain) {
  final bytes = utf8.encode(plain);
  return sha256.convert(bytes).toString();
}

class SupabaseService {
  SupabaseService._internal();
  static final SupabaseService instance = SupabaseService._internal();

  SupabaseClient get client => Supabase.instance.client;

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: SupabaseConfig.url,
      anonKey: SupabaseConfig.anonKey,
    );
  }

  bool get isConfigured =>
      SupabaseConfig.url.contains('YOUR_PROJECT') == false &&
      SupabaseConfig.anonKey.contains('YOUR_SUPABASE_ANON_KEY') == false;

  // ---------------- Players ----------------

  Future<void> pushPlayer(Player p) async {
    if (!isConfigured) return;
    await client.from('players').upsert(p.toMap());
  }

  // ---------------- Matches ----------------

  Future<void> pushMatch(MatchModel m) async {
    if (!isConfigured) return;
    await client.from('matches').upsert(m.toMap());
  }

  Future<void> pushRound(MatchRound r) async {
    if (!isConfigured) return;
    await client.from('match_rounds').upsert(r.toMap());
  }

  // ---------------- Realtime leaderboard ----------------

  Stream<List<Map<String, dynamic>>> watchLeaderboard() {
    if (!isConfigured) return const Stream.empty();
    return client
        .from('leaderboard_stats')
        .stream(primaryKey: ['player_id']).order('wins', ascending: false);
  }

  // ---------------- Admin ----------------

  /// يتحقق من كلمة مرور الأدمن عبر دالة RPC آمنة (verify_admin_password)
  /// تقارن الهاش داخل قاعدة البيانات نفسها، ولا تكشف عمود password_hash
  /// أبداً للتطبيق (RLS يمنع أي select/insert/update مباشر على admin_settings).
  Future<bool> verifyAdminPassword(String plainPassword) async {
    if (!isConfigured) return false;
    final result = await client.rpc('verify_admin_password', params: {
      'plain_password': plainPassword,
    });
    return result == true;
  }

  Future<void> changeAdminPassword(String newPassword) async {
    if (!isConfigured) return;
    await client.rpc('change_admin_password', params: {
      'new_password': newPassword,
    });
  }

  // ---------------- Announcements / Updates / Maintenance ----------------

  Future<List<Map<String, dynamic>>> getAnnouncements() async {
    if (!isConfigured) return [];
    final rows = await client
        .from('announcements')
        .select()
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(rows);
  }

  Future<void> addAnnouncement(String title, String body, String type) async {
    if (!isConfigured) return;
    await client.from('announcements').insert({
      'title': title,
      'body': body,
      'type': type, // 'ad' | 'update' | 'message'
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<void> deleteAnnouncement(String id) async {
    if (!isConfigured) return;
    await client.from('announcements').delete().eq('id', id);
  }

  Future<Map<String, dynamic>?> getAppSettings() async {
    if (!isConfigured) return null;
    final rows = await client.from('app_settings').select().eq('id', 1).limit(1);
    if (rows.isEmpty) return null;
    return Map<String, dynamic>.from(rows.first);
  }

  Future<void> updateAppSettings(Map<String, dynamic> values) async {
    if (!isConfigured) return;
    await client.from('app_settings').update(values).eq('id', 1);
  }
}
