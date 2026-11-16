enum GameType { cards, domino }

enum MatchStatus { inProgress, finished, cancelled }

String gameTypeToStr(GameType t) => t == GameType.cards ? 'cards' : 'domino';
GameType gameTypeFromStr(String s) => s == 'cards' ? GameType.cards : GameType.domino;

String matchStatusToStr(MatchStatus s) {
  switch (s) {
    case MatchStatus.inProgress:
      return 'in_progress';
    case MatchStatus.finished:
      return 'finished';
    case MatchStatus.cancelled:
      return 'cancelled';
  }
}

MatchStatus matchStatusFromStr(String s) {
  switch (s) {
    case 'finished':
      return MatchStatus.finished;
    case 'cancelled':
      return MatchStatus.cancelled;
    default:
      return MatchStatus.inProgress;
  }
}

class MatchModel {
  final String id;
  final GameType gameType;
  final String teamAName;
  final String teamBName;
  final List<String> teamAPlayerIds;
  final List<String> teamBPlayerIds;
  final int teamAScore;
  final int teamBScore;
  final int teamAKnocks; // للورق فقط
  final int teamBKnocks; // للورق فقط
  final int knockValue; // قيمة الطرقة (افتراضي 25)
  final int winScore; // نقاط الفوز للدومينو (افتراضي 101)
  final MatchStatus status;
  final String? winner; // 'A' or 'B' or 'draw'
  final DateTime createdAt;
  final DateTime? finishedAt;
  final bool synced;

  MatchModel({
    required this.id,
    required this.gameType,
    required this.teamAName,
    required this.teamBName,
    this.teamAPlayerIds = const [],
    this.teamBPlayerIds = const [],
    this.teamAScore = 0,
    this.teamBScore = 0,
    this.teamAKnocks = 0,
    this.teamBKnocks = 0,
    this.knockValue = 25,
    this.winScore = 101,
    this.status = MatchStatus.inProgress,
    this.winner,
    required this.createdAt,
    this.finishedAt,
    this.synced = false,
  });

  int get pointsDifference => (teamAScore - teamBScore).abs();
  int get knocksDifference => (teamAKnocks - teamBKnocks).abs();
  int get teamARemaining => (winScore - teamAScore).clamp(0, winScore);
  int get teamBRemaining => (winScore - teamBScore).clamp(0, winScore);

  MatchModel copyWith({
    String? teamAName,
    String? teamBName,
    int? teamAScore,
    int? teamBScore,
    int? teamAKnocks,
    int? teamBKnocks,
    int? knockValue,
    int? winScore,
    MatchStatus? status,
    String? winner,
    DateTime? finishedAt,
    bool? synced,
  }) {
    return MatchModel(
      id: id,
      gameType: gameType,
      teamAName: teamAName ?? this.teamAName,
      teamBName: teamBName ?? this.teamBName,
      teamAPlayerIds: teamAPlayerIds,
      teamBPlayerIds: teamBPlayerIds,
      teamAScore: teamAScore ?? this.teamAScore,
      teamBScore: teamBScore ?? this.teamBScore,
      teamAKnocks: teamAKnocks ?? this.teamAKnocks,
      teamBKnocks: teamBKnocks ?? this.teamBKnocks,
      knockValue: knockValue ?? this.knockValue,
      winScore: winScore ?? this.winScore,
      status: status ?? this.status,
      winner: winner ?? this.winner,
      createdAt: createdAt,
      finishedAt: finishedAt ?? this.finishedAt,
      synced: synced ?? this.synced,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'game_type': gameTypeToStr(gameType),
        'team_a_name': teamAName,
        'team_b_name': teamBName,
        'team_a_player_ids': teamAPlayerIds.join(','),
        'team_b_player_ids': teamBPlayerIds.join(','),
        'team_a_score': teamAScore,
        'team_b_score': teamBScore,
        'team_a_knocks': teamAKnocks,
        'team_b_knocks': teamBKnocks,
        'knock_value': knockValue,
        'win_score': winScore,
        'status': matchStatusToStr(status),
        'winner': winner,
        'created_at': createdAt.toIso8601String(),
        'finished_at': finishedAt?.toIso8601String(),
        'synced': synced ? 1 : 0,
      };

  factory MatchModel.fromMap(Map<String, dynamic> map) => MatchModel(
        id: map['id'] as String,
        gameType: gameTypeFromStr(map['game_type'] as String),
        teamAName: map['team_a_name'] as String,
        teamBName: map['team_b_name'] as String,
        teamAPlayerIds: (map['team_a_player_ids'] as String? ?? '')
            .split(',')
            .where((e) => e.isNotEmpty)
            .toList(),
        teamBPlayerIds: (map['team_b_player_ids'] as String? ?? '')
            .split(',')
            .where((e) => e.isNotEmpty)
            .toList(),
        teamAScore: map['team_a_score'] as int? ?? 0,
        teamBScore: map['team_b_score'] as int? ?? 0,
        teamAKnocks: map['team_a_knocks'] as int? ?? 0,
        teamBKnocks: map['team_b_knocks'] as int? ?? 0,
        knockValue: map['knock_value'] as int? ?? 25,
        winScore: map['win_score'] as int? ?? 101,
        status: matchStatusFromStr(map['status'] as String? ?? 'in_progress'),
        winner: map['winner'] as String?,
        createdAt: DateTime.parse(map['created_at'] as String),
        finishedAt: map['finished_at'] != null
            ? DateTime.parse(map['finished_at'] as String)
            : null,
        synced: (map['synced'] as int? ?? 0) == 1,
      );
}

/// جولة واحدة داخل المباراة (لسجل العمليات والتراجع)
class MatchRound {
  final String id;
  final String matchId;
  final String team; // 'A' or 'B'
  final String actionType; // 'points' or 'knock'
  final int value;
  final DateTime createdAt;

  MatchRound({
    required this.id,
    required this.matchId,
    required this.team,
    required this.actionType,
    required this.value,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'match_id': matchId,
        'team': team,
        'action_type': actionType,
        'value': value,
        'created_at': createdAt.toIso8601String(),
      };

  factory MatchRound.fromMap(Map<String, dynamic> map) => MatchRound(
        id: map['id'] as String,
        matchId: map['match_id'] as String,
        team: map['team'] as String,
        actionType: map['action_type'] as String,
        value: map['value'] as int,
        createdAt: DateTime.parse(map['created_at'] as String),
      );
}
