import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/match_model.dart';
import '../services/local_db_service.dart';
import '../services/supabase_service.dart';
import 'cards_game_provider.dart' show unawaited;

const _uuid = Uuid();

class DominoGameNotifier extends StateNotifier<MatchModel> {
  DominoGameNotifier({required int winScore})
      : super(MatchModel(
          id: _uuid.v4(),
          gameType: GameType.domino,
          teamAName: 'الفريق الأول',
          teamBName: 'الفريق الثاني',
          winScore: winScore,
          createdAt: DateTime.now(),
        ));

  Future<void> _persistAndLog(String team, int value) async {
    await LocalDbService.instance.upsertMatch(state);
    final round = MatchRound(
      id: _uuid.v4(),
      matchId: state.id,
      team: team,
      actionType: 'points',
      value: value,
      createdAt: DateTime.now(),
    );
    await LocalDbService.instance.addRound(round);
    unawaited(SupabaseService.instance.pushRound(round));
  }

  void renameTeams({String? teamA, String? teamB}) {
    state = state.copyWith(teamAName: teamA, teamBName: teamB);
  }

  /// تحديد نقاط الفوز قبل بدء المباراة (قابلة للتغيير، الافتراضي 101)
  void setWinScore(int value) {
    state = state.copyWith(winScore: value);
  }

  /// إضافة نقاط جولة لفريق، مع تحديث فوري للنقاط المتبقية حتى الفوز
  /// وإعلان الفائز تلقائياً عند الوصول لنقاط الفوز
  Future<void> addRoundPoints(String team, int points) async {
    if (team == 'A') {
      state = state.copyWith(teamAScore: state.teamAScore + points);
    } else {
      state = state.copyWith(teamBScore: state.teamBScore + points);
    }
    await _persistAndLog(team, points);

    if (state.teamAScore >= state.winScore || state.teamBScore >= state.winScore) {
      await _declareWinner();
    }
  }

  Future<void> _declareWinner() async {
    final winner = state.teamAScore >= state.winScore ? 'A' : 'B';
    state = state.copyWith(
      status: MatchStatus.finished,
      winner: winner,
      finishedAt: DateTime.now(),
    );
    await LocalDbService.instance.upsertMatch(state);
    unawaited(SupabaseService.instance.pushMatch(state));
  }

  Future<void> undoLast() async {
    final lastRound = await LocalDbService.instance.popLastRound(state.id);
    if (lastRound == null) return;
    if (lastRound.team == 'A') {
      state = state.copyWith(teamAScore: state.teamAScore - lastRound.value);
    } else {
      state = state.copyWith(teamBScore: state.teamBScore - lastRound.value);
    }
    // إذا كانت المباراة قد انتهت وتم التراجع، نعيدها إلى قيد اللعب
    if (state.status == MatchStatus.finished) {
      state = state.copyWith(status: MatchStatus.inProgress, winner: null);
    }
    await LocalDbService.instance.upsertMatch(state);
  }

  Future<void> finishMatchManually() async {
    String winner;
    if (state.teamAScore > state.teamBScore) {
      winner = 'A';
    } else if (state.teamBScore > state.teamAScore) {
      winner = 'B';
    } else {
      winner = 'draw';
    }
    state = state.copyWith(
      status: MatchStatus.finished,
      winner: winner,
      finishedAt: DateTime.now(),
    );
    await LocalDbService.instance.upsertMatch(state);
    unawaited(SupabaseService.instance.pushMatch(state));
  }

  Future<void> cancelMatch() async {
    state = state.copyWith(status: MatchStatus.cancelled, finishedAt: DateTime.now());
    await LocalDbService.instance.upsertMatch(state);
  }

  void resetMatch() {
    state = MatchModel(
      id: _uuid.v4(),
      gameType: GameType.domino,
      teamAName: state.teamAName,
      teamBName: state.teamBName,
      winScore: state.winScore,
      createdAt: DateTime.now(),
    );
  }
}

final dominoGameProvider =
    StateNotifierProvider.autoDispose<DominoGameNotifier, MatchModel>((ref) {
  return DominoGameNotifier(winScore: 101);
});
