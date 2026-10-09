import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/scoreboard_providers.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(historyProvider);
    final teamsAsync = ref.watch(teamsProvider);
    final teamMap = teamsAsync.maybeWhen(
      data: (teams) => {for (var t in teams) t.id: t.name},
      orElse: () => <String, String>{},
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Score Audit History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Clear History',
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Clear Score History?'),
                  content: const Text('Are you sure you want to delete all historical score logs?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Delete'),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                ref.read(historyProvider.notifier).clearHistory();
              }
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: historyAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (history) {
          if (history.isEmpty) {
            return const Center(
              child: Text('No score adjustments recorded yet.'),
            );
          }

          final dateFormat = DateFormat('yyyy-MM-dd HH:mm:ss');

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: history.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final item = history[index];
              final teamName = teamMap[item.teamId] ?? item.teamId;
              final isPositive = item.pointsChanged >= 0;

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: (isPositive ? Colors.green : Colors.red).withOpacity(0.15),
                  child: Icon(
                    isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                    color: isPositive ? Colors.green : Colors.red,
                    size: 20,
                  ),
                ),
                title: Text(
                  '$teamName: ${item.previousScore} → ${item.newScore}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  '${dateFormat.format(item.timestamp)}${item.description != null && item.description!.isNotEmpty ? " • ${item.description}" : ""}',
                ),
                trailing: Chip(
                  label: Text(
                    isPositive ? '+${item.pointsChanged}' : '${item.pointsChanged}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isPositive ? Colors.green.shade800 : Colors.red.shade800,
                    ),
                  ),
                  backgroundColor: (isPositive ? Colors.green : Colors.red).withOpacity(0.12),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
