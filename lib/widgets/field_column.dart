import 'package:flutter/material.dart';
import '../models/team.dart';
import '../models/field_model.dart';
import '../utils/rank_calculator.dart';
import 'team_tile.dart';

class FieldColumn extends StatelessWidget {
  final FieldModel field;
  final List<Team> teams;
  final bool isInteractive;
  final VoidCallback? onRename;

  const FieldColumn({
    super.key,
    required this.field,
    required this.teams,
    this.isInteractive = true,
    this.onRename,
  });

  @override
  Widget build(BuildContext context) {
    final rankedFieldTeams = RankCalculator.calculateRanks(teams);
    final isFieldA = field.id == 'field_a';
    final accentColor = isFieldA ? const Color(0xFF38BDF8) : const Color(0xFFA78BFA);

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF1E293B),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF131D33),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
              border: Border(
                bottom: BorderSide(
                  color: accentColor.withOpacity(0.3),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                // Minimal field dot indicator
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: accentColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    field.name.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.0,
                      color: Colors.white,
                    ),
                  ),
                ),
                if (onRename != null && isInteractive)
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 16),
                    color: const Color(0xFF94A3B8),
                    tooltip: 'Rename ${field.name}',
                    onPressed: onRename,
                  ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${teams.length} teams',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Team List
          Expanded(
            child: teams.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Text(
                        'No teams assigned to ${field.name}.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Color(0xFF64748B)),
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: rankedFieldTeams.length,
                    itemBuilder: (context, index) {
                      final team = rankedFieldTeams[index];
                      return TeamTile(
                        key: ValueKey(team.id),
                        team: team,
                        isInteractive: isInteractive,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
