import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/field_model.dart';
import '../providers/scoreboard_providers.dart';
import '../widgets/field_column.dart';
import '../widgets/overall_leaderboard.dart';
import '../animations/celebration_particles.dart';
import 'admin_screen.dart';
import 'presentation_screen.dart';
import 'history_screen.dart';

class ScoreboardScreen extends ConsumerStatefulWidget {
  const ScoreboardScreen({super.key});

  @override
  ConsumerState<ScoreboardScreen> createState() => _ScoreboardScreenState();
}

class _ScoreboardScreenState extends ConsumerState<ScoreboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _showCelebration = false;
  String? _lastTopTeamId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _triggerLeaderCelebration() {
    setState(() => _showCelebration = true);
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) setState(() => _showCelebration = false);
    });
  }

  void _renameField(String fieldId, String currentName) {
    final controller = TextEditingController(text: currentName);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Rename Field ($currentName)'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Field Name',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final newName = controller.text.trim();
              if (newName.isNotEmpty) {
                ref.read(fieldsProvider.notifier).updateFieldName(fieldId, newName);
              }
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fieldsAsync = ref.watch(fieldsProvider);
    final teamsAsync = ref.watch(teamsProvider);
    final settings = ref.watch(settingsProvider);
    final overallLeader = ref.watch(overallLeaderProvider);

    // Watch for leader changes to trigger particle celebration
    if (overallLeader != null && overallLeader.id != _lastTopTeamId && overallLeader.score > 0) {
      _lastTopTeamId = overallLeader.id;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (settings.enableAnimations) {
          _triggerLeaderCelebration();
        }
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.scoreboard_outlined, size: 24),
            ),
            const SizedBox(width: 12),
            const Text(
              'Desktop Scoreboard',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 16),
            if (overallLeader != null)
              Chip(
                avatar: const Icon(Icons.emoji_events, color: Color(0xFFFFD700), size: 18),
                label: Text(
                  'Leader: ${overallLeader.name} (${overallLeader.score} pts)',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                backgroundColor: const Color(0xFFFFD700).withOpacity(0.18),
              ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.view_column_outlined), text: 'Field A & Field B'),
            Tab(icon: Icon(Icons.leaderboard_outlined), text: 'Overall Standings'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Score History',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const HistoryScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.tv),
            tooltip: 'Live Presentation Mode (Full Screen)',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const PresentationScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.admin_panel_settings),
            tooltip: 'Administrator Controls',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AdminScreen()),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: CelebrationParticlesOverlay(
        isTriggered: _showCelebration,
        child: fieldsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(child: Text('Error loading fields: $err')),
          data: (fields) {
            return teamsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Error loading teams: $err')),
              data: (teams) {
                final fieldA = fields.firstWhere(
                  (f) => f.id == 'field_a',
                  orElse: () => fields.isNotEmpty ? fields.first : const FieldModel(id: 'field_a', name: 'Field A'),
                );
                final fieldB = fields.firstWhere(
                  (f) => f.id == 'field_b',
                  orElse: () => fields.length > 1 ? fields[1] : const FieldModel(id: 'field_b', name: 'Field B'),
                );

                final teamsFieldA = teams.where((t) => t.fieldId == fieldA.id).toList();
                final teamsFieldB = teams.where((t) => t.fieldId == fieldB.id).toList();

                return TabBarView(
                  controller: _tabController,
                  children: [
                    // Tab 1: Field A and Field B Columns
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          // Side-by-side if screen width is >= 768px, stacked otherwise
                          if (constraints.maxWidth >= 768) {
                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(
                                  child: FieldColumn(
                                    field: fieldA,
                                    teams: teamsFieldA,
                                    onRename: () => _renameField(fieldA.id, fieldA.name),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: FieldColumn(
                                    field: fieldB,
                                    teams: teamsFieldB,
                                    onRename: () => _renameField(fieldB.id, fieldB.name),
                                  ),
                                ),
                              ],
                            );
                          } else {
                            return SingleChildScrollView(
                              child: Column(
                                children: [
                                  SizedBox(
                                    height: 400,
                                    child: FieldColumn(
                                      field: fieldA,
                                      teams: teamsFieldA,
                                      onRename: () => _renameField(fieldA.id, fieldA.name),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  SizedBox(
                                    height: 400,
                                    child: FieldColumn(
                                      field: fieldB,
                                      teams: teamsFieldB,
                                      onRename: () => _renameField(fieldB.id, fieldB.name),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }
                        },
                      ),
                    ),

                    // Tab 2: Overall Leaderboard
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: OverallLeaderboard(
                        teams: teams,
                        fields: fields,
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}
