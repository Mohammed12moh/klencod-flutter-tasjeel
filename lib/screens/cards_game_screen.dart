import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import '../providers/cards_game_provider.dart';
import '../providers/providers.dart';

class CardsGameScreen extends ConsumerStatefulWidget {
  const CardsGameScreen({super.key});

  @override
  ConsumerState<CardsGameScreen> createState() => _CardsGameScreenState();
}

class _CardsGameScreenState extends ConsumerState<CardsGameScreen> {
  @override
  Widget build(BuildContext context) {
    final match = ref.watch(cardsGameProvider);
    final notifier = ref.read(cardsGameProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('تسجيل الورق'),
        actions: [
          IconButton(
            icon: const Icon(Icons.undo_rounded),
            tooltip: 'التراجع عن آخر عملية',
            onPressed: () => notifier.undoLast(),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(child: _teamScoreCard(context, match, 'A', notifier)),
                  const SizedBox(width: 12),
                  Expanded(child: _teamScoreCard(context, match, 'B', notifier)),
                ],
              ),
              const SizedBox(height: 16),
              _statsRow(match),
              const Spacer(),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.flag_rounded),
                      label: const Text('إنهاء المباراة'),
                      onPressed: () => _confirmFinish(context, notifier),
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

  Widget _statsRow(match) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          _statLine('فارق النقاط', '${match.pointsDifference}'),
          _statLine('فارق الطرّقات', '${match.knocksDifference}'),
          _statLine('قيمة كل طرقة', '${match.knockValue} نقطة'),
        ],
      ),
    );
  }

  Widget _statLine(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary)),
          Text(value,
              style: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _teamScoreCard(BuildContext context, match, String team, CardsGameNotifier notifier) {
    final isA = team == 'A';
    final name = isA ? match.teamAName : match.teamBName;
    final score = isA ? match.teamAScore : match.teamBScore;
    final knocks = isA ? match.teamAKnocks : match.teamBKnocks;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.gold.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: () => _renameTeam(context, notifier, team, name),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    name,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.edit, size: 14, color: AppColors.textSecondary),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text('$score',
              style: const TextStyle(
                  fontSize: 40, fontWeight: FontWeight.bold, color: AppColors.green)),
          Text('طرّقات: $knocks', style: const TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _smallBtn('+1', () => notifier.addPoints(team, 1)),
              _smallBtn('+5', () => notifier.addPoints(team, 5)),
              _smallBtn('+10', () => notifier.addPoints(team, 10)),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _customPoints(context, notifier, team),
              child: const Text('إضافة نقاط'),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => notifier.registerKnock(team),
              style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.red)),
              child: const Text('تسجيل طرقة', style: TextStyle(color: AppColors.red)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _smallBtn(String label, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 10)),
        child: Text(label),
      ),
    );
  }

  void _customPoints(BuildContext context, CardsGameNotifier notifier, String team) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('إضافة نقاط'),
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
              if (val != null) {
                notifier.addPoints(team, val);
              }
              Navigator.pop(ctx);
            },
            child: const Text('إضافة'),
          ),
        ],
      ),
    );
  }

  void _renameTeam(
      BuildContext context, CardsGameNotifier notifier, String team, String current) {
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

  void _confirmFinish(BuildContext context, CardsGameNotifier notifier) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('إنهاء المباراة'),
        content: const Text('هل تريد إنهاء المباراة الحالية وحفظ النتيجة؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () async {
              await notifier.finishMatch();
              if (ctx.mounted) Navigator.pop(ctx);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('تأكيد'),
          ),
        ],
      ),
    );
  }

  void _confirmReset(BuildContext context, CardsGameNotifier notifier) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('تصفير المباراة'),
        content: const Text('سيتم بدء مباراة جديدة وتصفير كل النقاط، هل أنت متأكد؟'),
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
