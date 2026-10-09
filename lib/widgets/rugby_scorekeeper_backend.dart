import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/team.dart';
import '../models/field_model.dart';
import '../providers/scoreboard_providers.dart';
import '../utils/color_palette.dart';
import 'score_edit_dialog.dart';

class RugbyScorekeeperBackend extends ConsumerWidget {
  final List<FieldModel> fields;
  final List<Team> teams;

  const RugbyScorekeeperBackend({
    super.key,
    required this.fields,
    required this.teams,
  });

  void _adjustScore(WidgetRef ref, Team team, int delta, String action) {
    ref.read(teamsProvider.notifier).adjustScore(
      teamId: team.id,
      delta: delta,
      description: '$action ($delta pts)',
    );
  }


  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (fields.isEmpty) {
      return const Center(child: Text('No fields available.', style: TextStyle(color: Colors.white)));
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: fields.map((field) {
        final fieldTeams = teams.where((t) => t.fieldId == field.id).toList();

        return Container(
          margin: const EdgeInsets.only(bottom: 20),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF1E293B)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Field Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                decoration: const BoxDecoration(
                  color: Color(0xFF131D33),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
                  border: Border(bottom: BorderSide(color: Color(0xFF1E293B))),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.sports_rugby, color: Color(0xFF38BDF8), size: 20),
                    const SizedBox(width: 10),
                    Text(
                      '${field.name.toUpperCase()} — MATCH SCORER',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.0,
                        color: Colors.white,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${fieldTeams.length} Teams Assigned',
                      style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                    ),
                  ],
                ),
              ),

              if (fieldTeams.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(24.0),
                  child: Center(
                    child: Text('No teams assigned to this field.', style: TextStyle(color: Color(0xFF64748B))),
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    children: fieldTeams.map((team) {
                      final teamColor = ColorPalette.getColor(team.color);

                      return Container(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF151D2E),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF243049)),
                        ),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final isWide = constraints.maxWidth >= 600;

                            return isWide
                                ? Row(
                                    children: [
                                      // Team Info & Big Score
                                      Container(
                                        width: 12,
                                        height: 12,
                                        decoration: BoxDecoration(color: teamColor, shape: BoxShape.circle),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        flex: 2,
                                        child: Text(
                                          team.name,
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                      InkWell(
                                        onTap: () {
                                          showDialog(
                                            context: context,
                                            builder: (_) => ScoreEditDialog(team: team),
                                          );
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF0B101D),
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: const Color(0xFF334155)),
                                          ),
                                          child: Text(
                                            '${team.score}',
                                            style: const TextStyle(
                                              fontSize: 26,
                                              fontWeight: FontWeight.w900,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 16),

                                      // Rugby Buttons Row
                                      Expanded(
                                        flex: 4,
                                        child: _buildRugbyButtonRow(context, ref, team),
                                      ),
                                    ],
                                  )
                                : Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            width: 12,
                                            height: 12,
                                            decoration: BoxDecoration(color: teamColor, shape: BoxShape.circle),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Text(
                                              team.name,
                                              style: const TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF0B101D),
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(color: const Color(0xFF334155)),
                                            ),
                                            child: Text(
                                              '${team.score} pts',
                                              style: const TextStyle(
                                                fontSize: 20,
                                                fontWeight: FontWeight.w900,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                      _buildRugbyButtonRow(context, ref, team),
                                    ],
                                  );
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRugbyButtonRow(BuildContext context, WidgetRef ref, Team team) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      alignment: WrapAlignment.end,
      children: [
        // Try (+5)
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF059669),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          onPressed: () => _adjustScore(ref, team, 5, 'Try'),
          child: const Text('+5 Try', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        ),
        // Conversion (+2)
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0284C7),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          onPressed: () => _adjustScore(ref, team, 2, 'Conversion'),
          child: const Text('+2 Conv', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        ),
        // Penalty (+3)
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFD97706),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          onPressed: () => _adjustScore(ref, team, 3, 'Penalty'),
          child: const Text('+3 Pen', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        ),
        // Drop Goal (+3)
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF7C3AED),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          onPressed: () => _adjustScore(ref, team, 3, 'Drop Goal'),
          child: const Text('+3 Drop', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        ),
        // -1
        IconButton(
          icon: const Icon(Icons.remove, size: 16),
          style: IconButton.styleFrom(
            backgroundColor: const Color(0xFF1E293B),
            foregroundColor: const Color(0xFFCBD5E1),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          tooltip: '-1 point correction',
          onPressed: () => _adjustScore(ref, team, -1, 'Correction'),
        ),
        // +1
        IconButton(
          icon: const Icon(Icons.add, size: 16),
          style: IconButton.styleFrom(
            backgroundColor: const Color(0xFF1E293B),
            foregroundColor: const Color(0xFFCBD5E1),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          tooltip: '+1 point correction',
          onPressed: () => _adjustScore(ref, team, 1, 'Correction'),
        ),
        // Custom edit / reset
        IconButton(
          icon: const Icon(Icons.edit_note, size: 20),
          style: IconButton.styleFrom(
            backgroundColor: const Color(0xFF1E293B),
            foregroundColor: const Color(0xFF38BDF8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          tooltip: 'Edit exact score or reset',
          onPressed: () {
            showDialog(
              context: context,
              builder: (_) => ScoreEditDialog(team: team),
            );
          },
        ),
      ],
    );
  }
}
