import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../providers/providers.dart';
import '../models/match_model.dart';
import '../services/local_db_service.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  final _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final filter = ref.watch(historyFilterProvider);
    final historyAsync = ref.watch(matchHistoryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('سجل المباريات')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'ابحث باسم الفريق...',
                prefixIcon: Icon(Icons.search_rounded),
              ),
              onChanged: (v) => ref.read(historySearchProvider.notifier).state = v,
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _filterChip(context, 'الكل', null, filter),
                const SizedBox(width: 8),
                _filterChip(context, 'ورق', GameType.cards, filter),
                const SizedBox(width: 8),
                _filterChip(context, 'دومينو', GameType.domino, filter),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: historyAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('خطأ: $e')),
              data: (matches) {
                if (matches.isEmpty) {
                  return const Center(
                      child: Text('لا توجد مباريات محفوظة بعد',
                          style: TextStyle(color: AppColors.textSecondary)));
                }
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: matches.length,
                  itemBuilder: (context, i) => _matchTile(context, matches[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(BuildContext context, String label, GameType? value, GameType? current) {
    final selected = value == current;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      selectedColor: AppColors.gold,
      labelStyle: TextStyle(color: selected ? Colors.black : AppColors.textPrimary),
      onSelected: (_) => ref.read(historyFilterProvider.notifier).state = value,
    );
  }

  Widget _matchTile(BuildContext context, MatchModel m) {
    final winnerName = m.winner == 'A'
        ? m.teamAName
        : m.winner == 'B'
            ? m.teamBName
            : 'تعادل';
    final dateStr = DateFormat('yyyy/MM/dd - HH:mm').format(m.createdAt);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(
            m.gameType == GameType.cards ? Icons.style_rounded : Icons.grid_view_rounded,
            color: AppColors.gold,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${m.teamAName} ${m.teamAScore} - ${m.teamBScore} ${m.teamBName}',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('الفائز: $winnerName',
                    style: const TextStyle(color: AppColors.green, fontSize: 12)),
                Text(dateStr, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: AppColors.red),
            onPressed: () => _confirmDelete(context, m.id),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('حذف المباراة'),
        content: const Text('هل أنت متأكد من حذف هذه المباراة نهائياً؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () async {
              await LocalDbService.instance.deleteMatch(id);
              if (ctx.mounted) Navigator.pop(ctx);
              ref.invalidate(matchHistoryProvider);
            },
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }
}
