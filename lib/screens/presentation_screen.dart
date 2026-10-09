import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/scoreboard_providers.dart';
import '../models/field_model.dart';
import '../widgets/field_column.dart';
import '../widgets/three_d_trophy_widget.dart';

class PresentationScreen extends ConsumerStatefulWidget {
  const PresentationScreen({super.key});

  @override
  ConsumerState<PresentationScreen> createState() => _PresentationScreenState();
}

class _PresentationScreenState extends ConsumerState<PresentationScreen> {
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // Request focus for keyboard shortcuts like Escape
    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.escape) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final fieldsAsync = ref.watch(fieldsProvider);
    final teamsAsync = ref.watch(teamsProvider);
    final overallLeader = ref.watch(overallLeaderProvider);

    return KeyboardListener(
      focusNode: _focusNode,
      onKeyEvent: _handleKeyEvent,
      child: Scaffold(
        backgroundColor: const Color(0xFF0F172A), // Deep stadium dark slate
        body: SafeArea(
          child: Column(
            children: [
              // Presentation Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                  ),
                  border: Border(
                    bottom: BorderSide(color: Colors.white.withOpacity(0.1)),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red.shade700,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.circle, color: Colors.white, size: 10),
                          SizedBox(width: 6),
                          Text(
                            'LIVE SCOREBOARD',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Text(
                      'CHAMPIONSHIP TOURNAMENT',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                      ),
                    ),
                    const Spacer(),
                    if (overallLeader != null) ...[
                      Row(
                        children: [
                          const SizedBox(
                            width: 38,
                            height: 38,
                            child: ThreeDTrophyWidget(size: 38),
                          ),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text(
                                'CURRENT LEADER',
                                style: TextStyle(
                                  color: Color(0xFFFFD700),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1,
                                ),
                              ),
                              Text(
                                '${overallLeader.name} — ${overallLeader.score} pts',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(width: 24),
                    ],
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white70,
                        side: BorderSide(color: Colors.white.withOpacity(0.3)),
                      ),
                      icon: const Icon(Icons.fullscreen_exit, size: 18),
                      label: const Text('Exit (Esc)'),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),

              // Presentation Dual-Field Display
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: fieldsAsync.when(
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (err, _) => Center(child: Text('Error: $err', style: const TextStyle(color: Colors.white))),
                    data: (fields) {
                      return teamsAsync.when(
                        loading: () => const Center(child: CircularProgressIndicator()),
                        error: (err, _) => Center(child: Text('Error: $err', style: const TextStyle(color: Colors.white))),
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

                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                child: FieldColumn(
                                  field: fieldA,
                                  teams: teamsFieldA,
                                  isInteractive: false, // Prevent accidental edits in presentation mode
                                ),
                              ),
                              const SizedBox(width: 20),
                              Expanded(
                                child: FieldColumn(
                                  field: fieldB,
                                  teams: teamsFieldB,
                                  isInteractive: false, // Prevent accidental edits in presentation mode
                                ),
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
