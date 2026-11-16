import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/local_db_service.dart';
import '../services/supabase_service.dart';
import '../models/player.dart';
import '../models/match_model.dart';

final localDbProvider = Provider<LocalDbService>((ref) => LocalDbService.instance);
final remoteServiceProvider = Provider<SupabaseService>((ref) => SupabaseService.instance);

/// حالة دخول الأدمن الحالية (ينتهي عند إغلاق التطبيق - ليس دائماً)
final isAdminLoggedInProvider = StateProvider<bool>((ref) => false);

/// إعدادات اللعبة القابلة للتعديل من لوحة الأدمن (تُحمّل من SharedPreferences محلياً)
class GameSettings {
  final int dominoWinScore;
  final int cardKnockValue;
  final bool soundEnabled;
  final bool darkMode;

  GameSettings({
    this.dominoWinScore = 101,
    this.cardKnockValue = 25,
    this.soundEnabled = true,
    this.darkMode = true,
  });

  GameSettings copyWith({
    int? dominoWinScore,
    int? cardKnockValue,
    bool? soundEnabled,
    bool? darkMode,
  }) {
    return GameSettings(
      dominoWinScore: dominoWinScore ?? this.dominoWinScore,
      cardKnockValue: cardKnockValue ?? this.cardKnockValue,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      darkMode: darkMode ?? this.darkMode,
    );
  }
}

class GameSettingsNotifier extends StateNotifier<GameSettings> {
  GameSettingsNotifier() : super(GameSettings()) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = GameSettings(
      dominoWinScore: prefs.getInt('domino_win_score') ?? 101,
      cardKnockValue: prefs.getInt('card_knock_value') ?? 25,
      soundEnabled: prefs.getBool('sound_enabled') ?? true,
      darkMode: prefs.getBool('dark_mode') ?? true,
    );
  }

  Future<void> setDominoWinScore(int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('domino_win_score', value);
    state = state.copyWith(dominoWinScore: value);
  }

  Future<void> setCardKnockValue(int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('card_knock_value', value);
    state = state.copyWith(cardKnockValue: value);
  }

  Future<void> setSoundEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('sound_enabled', value);
    state = state.copyWith(soundEnabled: value);
  }

  Future<void> setDarkMode(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('dark_mode', value);
    state = state.copyWith(darkMode: value);
  }
}

final gameSettingsProvider =
    StateNotifierProvider<GameSettingsNotifier, GameSettings>((ref) => GameSettingsNotifier());

/// سجل المباريات (History) مع فلترة نوع اللعبة والبحث
final historyFilterProvider = StateProvider<GameType?>((ref) => null);
final historySearchProvider = StateProvider<String>((ref) => '');

final matchHistoryProvider = FutureProvider.autoDispose<List<MatchModel>>((ref) async {
  final db = ref.watch(localDbProvider);
  final filter = ref.watch(historyFilterProvider);
  final search = ref.watch(historySearchProvider);
  return db.getMatchHistory(gameType: filter, searchQuery: search);
});

/// لوحة المتصدرين العامة (كل الألعاب)
final overallLeaderboardProvider = FutureProvider.autoDispose<List<Player>>((ref) async {
  final db = ref.watch(localDbProvider);
  return db.getLeaderboard();
});

/// لوحة متصدرين لعبة محددة (ورق أو دومينو)
final gameLeaderboardProvider =
    FutureProvider.family.autoDispose<List<Map<String, dynamic>>, GameType>((ref, type) async {
  final db = ref.watch(localDbProvider);
  return db.getLeaderboardForGameType(type);
});
