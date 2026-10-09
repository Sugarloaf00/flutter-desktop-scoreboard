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
        backgroundColor: const Color(0xFF131B2E),
        title: Text('Rename Field ($currentName)', style: const TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            labelText: 'Field Name',
            labelStyle: TextStyle(color: Color(0xFF94A3B8)),
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF94A3B8))),
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
      backgroundColor: const Color(0xFF090D16),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: const Color(0xFF3B82F6).withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.scoreboard_rounded, color: Color(0xFF38BDF8), size: 22),
            ),
            const SizedBox(width: 12),
            const Text(
              'Scoreboard',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
                color: Colors.white,
              ),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFF1E293B), width: 1)),
            ),
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              indicatorColor: const Color(0xFF38BDF8),
              indicatorWeight: 3,
              labelColor: const Color(0xFF38BDF8),
              unselectedLabelColor: const Color(0xFF64748B),
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              tabs: const [
                Tab(text: 'Fields (A & B)'),
                Tab(text: 'Overall Standings'),
              ],
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.tv, size: 20),
            color: const Color(0xFF94A3B8),
            tooltip: 'Live Presentation Mode',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const PresentationScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.history, size: 20),
            color: const Color(0xFF94A3B8),
            tooltip: 'Score History',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const HistoryScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined, size: 20),
            color: const Color(0xFF94A3B8),
            tooltip: 'Settings & Admin',
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
          error: (err, _) => Center(child: Text('Error loading fields: $err', style: const TextStyle(color: Colors.white))),
          data: (fields) {
            return teamsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Error loading teams: $err', style: const TextStyle(color: Colors.white))),
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
                    // Tab 1: Field A and Field B
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
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
                                    height: 380,
                                    child: FieldColumn(
                                      field: fieldA,
                                      teams: teamsFieldA,
                                      onRename: () => _renameField(fieldA.id, fieldA.name),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  SizedBox(
                                    height: 380,
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

                    // Tab 2: Overall Standings
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
