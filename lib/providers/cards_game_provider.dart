import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/match_model.dart';
import '../services/local_db_service.dart';
import '../services/supabase_service.dart';

const _uuid = Uuid();

class CardsGameNotifier extends StateNotifier<MatchModel> {
  CardsGameNotifier({required int knockValue})
      : super(MatchModel(
          id: _uuid.v4(),
          gameType: GameType.cards,
          teamAName: 'الفريق الأول',
          teamBName: 'الفريق الثاني',
          knockValue: knockValue,
          createdAt: DateTime.now(),
        ));

  Future<void> _persistAndLog(String team, String actionType, int value) async {
    await LocalDbService.instance.upsertMatch(state);
    final round = MatchRound(
      id: _uuid.v4(),
      matchId: state.id,
      team: team,
      actionType: actionType,
      value: value,
      createdAt: DateTime.now(),
    );
    await LocalDbService.instance.addRound(round);
    unawaited(SupabaseService.instance.pushRound(round));
  }

  void renameTeams({String? teamA, String? teamB}) {
    state = state.copyWith(teamAName: teamA, teamBName: teamB);
  }

  /// إضافة نقاط لفريق معيّن (team = 'A' or 'B'), جمع تلقائي، تحديث مباشر
  Future<void> addPoints(String team, int points) async {
    if (team == 'A') {
      state = state.copyWith(teamAScore: state.teamAScore + points);
    } else {
      state = state.copyWith(teamBScore: state.teamBScore + points);
    }
    await _persistAndLog(team, 'points', points);
  }

  /// تسجيل طرقة لفريق: تضيف نقاط الطرقة (knockValue) لرصيد الفريق تلقائياً
  Future<void> registerKnock(String team) async {
    final kv = state.knockValue;
    if (team == 'A') {
      state = state.copyWith(
        teamAKnocks: state.teamAKnocks + 1,
        teamAScore: state.teamAScore + kv,
      );
    } else {
      state = state.copyWith(
        teamBKnocks: state.teamBKnocks + 1,
        teamBScore: state.teamBScore + kv,
      );
    }
    await _persistAndLog(team, 'knock', kv);
  }

  /// التراجع عن آخر عملية (نقاط أو طرقة)
  Future<void> undoLast() async {
    final lastRound = await LocalDbService.instance.popLastRound(state.id);
    if (lastRound == null) return;

    if (lastRound.actionType == 'points') {
      if (lastRound.team == 'A') {
        state = state.copyWith(teamAScore: state.teamAScore - lastRound.value);
      } else {
        state = state.copyWith(teamBScore: state.teamBScore - lastRound.value);
      }
    } else if (lastRound.actionType == 'knock') {
      if (lastRound.team == 'A') {
        state = state.copyWith(
          teamAKnocks: (state.teamAKnocks - 1).clamp(0, 999999),
          teamAScore: state.teamAScore - lastRound.value,
        );
      } else {
        state = state.copyWith(
          teamBKnocks: (state.teamBKnocks - 1).clamp(0, 999999),
          teamBScore: state.teamBScore - lastRound.value,
        );
      }
    }
    await LocalDbService.instance.upsertMatch(state);
  }

  /// إنهاء المباراة وتحديد الفائز وحفظها في السجل ولوحة المتصدرين
  Future<void> finishMatch() async {
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

  /// إلغاء المباراة (لا تُحتسب في لوحة المتصدرين)
  Future<void> cancelMatch() async {
    state = state.copyWith(status: MatchStatus.cancelled, finishedAt: DateTime.now());
    await LocalDbService.instance.upsertMatch(state);
  }

  /// تصفير المباراة بالكامل بعد تأكيد المستخدم (بنفس الفريقين)
  void resetMatch() {
    state = MatchModel(
      id: _uuid.v4(),
      gameType: GameType.cards,
      teamAName: state.teamAName,
      teamBName: state.teamBName,
      knockValue: state.knockValue,
      createdAt: DateTime.now(),
    );
  }
}

final cardsGameProvider =
    StateNotifierProvider.autoDispose<CardsGameNotifier, MatchModel>((ref) {
  return CardsGameNotifier(knockValue: 25);
});

// Helper بسيط لتفادي استيراد dart:async في كل مكان
void unawaited(Future<void> future) {}
