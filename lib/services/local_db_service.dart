import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/player.dart';
import '../models/match_model.dart';

/// يخزن كل شيء محلياً أولاً (Offline-first) حتى لا تُفقد أي بيانات
/// عند انقطاع الإنترنت أو إغلاق التطبيق. المزامنة مع Supabase تتم لاحقاً
/// عبر SyncService دون حذف أو تكرار البيانات المحلية.
class LocalDbService {
  LocalDbService._internal();
  static final LocalDbService instance = LocalDbService._internal();

  Database? _db;

  Future<Database> get database async {
    _db ??= await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'tasjeel.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE players (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            normalized_name TEXT NOT NULL,
            avatar_path TEXT,
            wins INTEGER NOT NULL DEFAULT 0,
            losses INTEGER NOT NULL DEFAULT 0,
            draws INTEGER NOT NULL DEFAULT 0,
            total_matches INTEGER NOT NULL DEFAULT 0,
            synced INTEGER NOT NULL DEFAULT 0
          )
        ''');
        await db.execute('CREATE INDEX idx_players_norm ON players(normalized_name)');

        await db.execute('''
          CREATE TABLE matches (
            id TEXT PRIMARY KEY,
            game_type TEXT NOT NULL,
            team_a_name TEXT NOT NULL,
            team_b_name TEXT NOT NULL,
            team_a_player_ids TEXT,
            team_b_player_ids TEXT,
            team_a_score INTEGER NOT NULL DEFAULT 0,
            team_b_score INTEGER NOT NULL DEFAULT 0,
            team_a_knocks INTEGER NOT NULL DEFAULT 0,
            team_b_knocks INTEGER NOT NULL DEFAULT 0,
            knock_value INTEGER NOT NULL DEFAULT 25,
            win_score INTEGER NOT NULL DEFAULT 101,
            status TEXT NOT NULL DEFAULT 'in_progress',
            winner TEXT,
            created_at TEXT NOT NULL,
            finished_at TEXT,
            synced INTEGER NOT NULL DEFAULT 0
          )
        ''');
        await db.execute('CREATE INDEX idx_matches_status ON matches(status)');
        await db.execute('CREATE INDEX idx_matches_type ON matches(game_type)');

        await db.execute('''
          CREATE TABLE match_rounds (
            id TEXT PRIMARY KEY,
            match_id TEXT NOT NULL,
            team TEXT NOT NULL,
            action_type TEXT NOT NULL,
            value INTEGER NOT NULL,
            created_at TEXT NOT NULL,
            FOREIGN KEY (match_id) REFERENCES matches(id) ON DELETE CASCADE
          )
        ''');
        await db.execute('CREATE INDEX idx_rounds_match ON match_rounds(match_id)');

        await db.execute('''
          CREATE TABLE app_settings (
            key TEXT PRIMARY KEY,
            value TEXT
          )
        ''');
      },
    );
  }

  // ---------------- Players ----------------

  Future<Player?> findPlayerByName(String name) async {
    final db = await database;
    final norm = Player.normalize(name);
    final rows = await db.query('players', where: 'normalized_name = ?', whereArgs: [norm]);
    if (rows.isEmpty) return null;
    return Player.fromMap(rows.first);
  }

  Future<void> upsertPlayer(Player p) async {
    final db = await database;
    await db.insert('players', p.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Player>> getAllPlayers() async {
    final db = await database;
    final rows = await db.query('players');
    return rows.map(Player.fromMap).toList();
  }

  Future<List<Player>> getLeaderboard({GameType? filterType}) async {
    // filterType غير مستخدم مباشرة هنا لأن الفوز/الخسارة العامة مجمّعة في جدول players
    // أما إحصائيات كل لعبة على حدة فتُحسب من جدول matches عبر getLeaderboardForGameType
    final db = await database;
    final rows = await db.query('players', orderBy: 'wins DESC, total_matches ASC');
    return rows.map(Player.fromMap).toList();
  }

  /// يحسب ترتيب اللاعبين لنوع لعبة محدد اعتماداً على مباريات game_type المنتهية فقط
  Future<List<Map<String, dynamic>>> getLeaderboardForGameType(GameType type) async {
    final db = await database;
    final matches = await db.query(
      'matches',
      where: 'game_type = ? AND status = ?',
      whereArgs: [gameTypeToStr(type), 'finished'],
    );

    final Map<String, Map<String, dynamic>> stats = {};

    void bump(String playerId, {required bool won, required bool lost, required bool draw}) {
      stats.putIfAbsent(playerId, () => {'wins': 0, 'losses': 0, 'draws': 0, 'total': 0});
      final s = stats[playerId]!;
      if (won) s['wins'] = (s['wins'] as int) + 1;
      if (lost) s['losses'] = (s['losses'] as int) + 1;
      if (draw) s['draws'] = (s['draws'] as int) + 1;
      s['total'] = (s['total'] as int) + 1;
    }

    for (final m in matches) {
      final match = MatchModel.fromMap(m);
      final aIds = match.teamAPlayerIds;
      final bIds = match.teamBPlayerIds;
      final isDraw = match.winner == 'draw';
      for (final id in aIds) {
        bump(id, won: match.winner == 'A', lost: match.winner == 'B', draw: isDraw);
      }
      for (final id in bIds) {
        bump(id, won: match.winner == 'B', lost: match.winner == 'A', draw: isDraw);
      }
    }

    final players = await getAllPlayers();
    final result = <Map<String, dynamic>>[];
    for (final p in players) {
      final s = stats[p.id];
      if (s == null) continue;
      final total = s['total'] as int;
      final wins = s['wins'] as int;
      result.add({
        'player': p,
        'wins': wins,
        'losses': s['losses'],
        'draws': s['draws'],
        'total': total,
        'winRate': total == 0 ? 0.0 : (wins / total) * 100,
      });
    }
    result.sort((a, b) => (b['wins'] as int).compareTo(a['wins'] as int));
    return result;
  }

  // ---------------- Matches ----------------

  Future<void> upsertMatch(MatchModel m) async {
    final db = await database;
    await db.insert('matches', m.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> deleteMatch(String id) async {
    final db = await database;
    await db.delete('match_rounds', where: 'match_id = ?', whereArgs: [id]);
    await db.delete('matches', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<MatchModel>> getMatchHistory({
    GameType? gameType,
    String? searchQuery,
  }) async {
    final db = await database;
    final where = <String>["status = 'finished'"];
    final args = <dynamic>[];
    if (gameType != null) {
      where.add('game_type = ?');
      args.add(gameTypeToStr(gameType));
    }
    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      where.add('(team_a_name LIKE ? OR team_b_name LIKE ?)');
      args.add('%${searchQuery.trim()}%');
      args.add('%${searchQuery.trim()}%');
    }
    final rows = await db.query(
      'matches',
      where: where.join(' AND '),
      whereArgs: args,
      orderBy: 'created_at DESC',
    );
    return rows.map(MatchModel.fromMap).toList();
  }

  Future<MatchModel?> getMatch(String id) async {
    final db = await database;
    final rows = await db.query('matches', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return MatchModel.fromMap(rows.first);
  }

  // ---------------- Match rounds (undo stack) ----------------

  Future<void> addRound(MatchRound r) async {
    final db = await database;
    await db.insert('match_rounds', r.toMap());
  }

  Future<MatchRound?> popLastRound(String matchId) async {
    final db = await database;
    final rows = await db.query(
      'match_rounds',
      where: 'match_id = ?',
      whereArgs: [matchId],
      orderBy: 'created_at DESC',
      limit: 1,
    );
    if (rows.isEmpty) return null;
    final round = MatchRound.fromMap(rows.first);
    await db.delete('match_rounds', where: 'id = ?', whereArgs: [round.id]);
    return round;
  }

  // ---------------- Settings ----------------

  Future<String?> getSetting(String key) async {
    final db = await database;
    final rows = await db.query('app_settings', where: 'key = ?', whereArgs: [key]);
    if (rows.isEmpty) return null;
    return rows.first['value'] as String?;
  }

  Future<void> setSetting(String key, String value) async {
    final db = await database;
    await db.insert(
      'app_settings',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<MatchModel>> getUnsyncedMatches() async {
    final db = await database;
    final rows = await db.query('matches', where: 'synced = 0');
    return rows.map(MatchModel.fromMap).toList();
  }

  Future<List<Player>> getUnsyncedPlayers() async {
    final db = await database;
    final rows = await db.query('players', where: 'synced = 0');
    return rows.map(Player.fromMap).toList();
  }
}
