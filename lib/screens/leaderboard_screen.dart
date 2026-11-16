import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import '../providers/providers.dart';
import '../models/match_model.dart';

class LeaderboardScreen extends ConsumerWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('لوحة المتصدرين 🏆'),
          bottom: const TabBar(
            indicatorColor: AppColors.gold,
            labelColor: AppColors.gold,
            unselectedLabelColor: AppColors.textSecondary,
            tabs: [
              Tab(text: 'عام'),
              Tab(text: 'ورق'),
              Tab(text: 'دومينو'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _OverallTab(),
            _GameTab(gameType: GameType.cards),
            _GameTab(gameType: GameType.domino),
          ],
        ),
      ),
    );
  }
}

class _OverallTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playersAsync = ref.watch(overallLeaderboardProvider);
    return playersAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('خطأ: $e')),
      data: (players) {
        if (players.isEmpty) {
          return const Center(
              child: Text('لا يوجد لاعبون بعد', style: TextStyle(color: AppColors.textSecondary)));
        }
        final sorted = [...players]..sort((a, b) => b.wins.compareTo(a.wins));
        return _LeaderboardList(
          entries: sorted
              .map((p) => {
                    'name': p.name,
                    'wins': p.wins,
                    'losses': p.losses,
                    'total': p.totalMatches,
                    'winRate': p.winRate,
                  })
              .toList(),
        );
      },
    );
  }
}

class _GameTab extends ConsumerWidget {
  final GameType gameType;
  const _GameTab({required this.gameType});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(gameLeaderboardProvider(gameType));
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('خطأ: $e')),
      data: (rows) {
        if (rows.isEmpty) {
          return const Center(
              child:
                  Text('لا توجد مباريات منتهية بعد', style: TextStyle(color: AppColors.textSecondary)));
        }
        return _LeaderboardList(
          entries: rows
              .map((r) => {
                    'name': r['player'].name,
                    'wins': r['wins'],
                    'losses': r['losses'],
                    'total': r['total'],
                    'winRate': r['winRate'],
                  })
              .toList(),
        );
      },
    );
  }
}

class _LeaderboardList extends StatelessWidget {
  final List<Map<String, dynamic>> entries;
  const _LeaderboardList({required this.entries});

  @override
  Widget build(BuildContext context) {
    const medals = ['🥇', '🥈', '🥉'];
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final e = entries[index];
        final medal = index < 3 ? medals[index] : '${index + 1}';
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: index < 3 ? Border.all(color: AppColors.gold.withOpacity(0.4)) : null,
          ),
          child: Row(
            children: [
              SizedBox(
                  width: 36,
                  child: Text(medal,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.gold.withOpacity(0.15),
                child: const Icon(Icons.person, color: AppColors.gold, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(e['name'] as String,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
              Text('فوز ${e['wins']}', style: const TextStyle(color: AppColors.green)),
              const SizedBox(width: 10),
              Text('خسارة ${e['losses']}', style: const TextStyle(color: AppColors.red)),
              const SizedBox(width: 10),
              Text('${(e['winRate'] as double).toStringAsFixed(0)}%',
                  style: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold)),
            ],
          ),
        );
      },
    );
  }
}
