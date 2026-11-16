import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import '../providers/domino_game_provider.dart';
import '../models/match_model.dart';

class DominoGameScreen extends ConsumerStatefulWidget {
  const DominoGameScreen({super.key});

  @override
  ConsumerState<DominoGameScreen> createState() => _DominoGameScreenState();
}

class _DominoGameScreenState extends ConsumerState<DominoGameScreen> {
  @override
  Widget build(BuildContext context) {
    final match = ref.watch(dominoGameProvider);
    final notifier = ref.read(dominoGameProvider.notifier);
    final finished = match.status == MatchStatus.finished;

    return Scaffold(
      appBar: AppBar(
        title: const Text('تسجيل الدومينو'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_rounded),
            tooltip: 'نقاط الفوز',
            onPressed: () => _editWinScore(context, notifier, match.winScore),
          ),
          IconButton(
            icon: const Icon(Icons.undo_rounded),
            tooltip: 'التراجع',
            onPressed: () => notifier.undoLast(),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.gold.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  finished
                      ? 'انتهت المباراة 🏆 الفائز: ${match.winner == 'A' ? match.teamAName : match.teamBName}'
                      : 'نقاط الفوز: ${match.winScore}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: AppColors.gold, fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _teamCard(context, match, 'A', notifier)),
                  const SizedBox(width: 12),
                  Expanded(child: _teamCard(context, match, 'B', notifier)),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('فارق النقاط', style: TextStyle(color: AppColors.textSecondary)),
                    Text('${match.pointsDifference}',
                        style: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              const Spacer(),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.flag_rounded),
                      label: const Text('إنهاء المباراة'),
                      onPressed: finished
                          ? null
                          : () => _confirmFinish(context, notifier),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('مباراة جديدة'),
                      onPressed: () => _confirmReset(context, notifier),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _teamCard(BuildContext context, match, String team, DominoGameNotifier notifier) {
    final isA = team == 'A';
    final name = isA ? match.teamAName : match.teamBName;
    final score = isA ? match.teamAScore : match.teamBScore;
    final remaining = isA ? match.teamARemaining : match.teamBRemaining;
    final leading = isA
        ? match.teamAScore >= match.teamBScore
        : match.teamBScore >= match.teamAScore;
    final finished = match.status == MatchStatus.finished;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: leading ? AppColors.green.withOpacity(0.6) : AppColors.gold.withOpacity(0.25),
          width: leading ? 1.6 : 1,
        ),
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: () => _renameTeam(context, notifier, team, name),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(name,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.edit, size: 14, color: AppColors.textSecondary),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text('$score',
              style: const TextStyle(
                  fontSize: 40, fontWeight: FontWeight.bold, color: AppColors.gold)),
          Text('متبقٍ للفوز: $remaining', style: const TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _smallBtn('+5', finished ? null : () => notifier.addRoundPoints(team, 5)),
              _smallBtn('+10', finished ? null : () => notifier.addRoundPoints(team, 10)),
              _smallBtn('+15', finished ? null : () => notifier.addRoundPoints(team, 15)),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: finished ? null : () => _customPoints(context, notifier, team),
              child: const Text('إضافة نقاط الجولة'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _smallBtn(String label, VoidCallback? onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 10)),
        child: Text(label),
      ),
    );
  }

  void _customPoints(BuildContext context, DominoGameNotifier notifier, String team) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('إضافة نقاط الجولة'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(hintText: 'أدخل عدد النقاط'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () {
              final val = int.tryParse(controller.text.trim());
              if (val != null) notifier.addRoundPoints(team, val);
              Navigator.pop(ctx);
            },
            child: const Text('إضافة'),
          ),
        ],
      ),
    );
  }

  void _renameTeam(
      BuildContext context, DominoGameNotifier notifier, String team, String current) {
    final controller = TextEditingController(text: current);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('تعديل اسم الفريق'),
        content: TextField(controller: controller, autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () {
              if (team == 'A') {
                notifier.renameTeams(teamA: controller.text.trim());
              } else {
                notifier.renameTeams(teamB: controller.text.trim());
              }
              Navigator.pop(ctx);
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  void _editWinScore(BuildContext context, DominoGameNotifier notifier, int current) {
    final controller = TextEditingController(text: '$current');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('تحديد نقاط الفوز'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(hintText: 'مثال: 101'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () {
              final val = int.tryParse(controller.text.trim());
              if (val != null && val > 0) notifier.setWinScore(val);
              Navigator.pop(ctx);
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  void _confirmFinish(BuildContext context, DominoGameNotifier notifier) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('إنهاء المباراة'),
        content: const Text('هل تريد إنهاء المباراة الحالية الآن وحفظ النتيجة؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () async {
              await notifier.finishMatchManually();
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('تأكيد'),
          ),
        ],
      ),
    );
  }

  void _confirmReset(BuildContext context, DominoGameNotifier notifier) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('تصفير المباراة'),
        content: const Text('سيتم بدء مباراة جديدة، هل أنت متأكد؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () {
              notifier.resetMatch();
              Navigator.pop(ctx);
            },
            child: const Text('تأكيد'),
          ),
        ],
      ),
    );
  }
}
