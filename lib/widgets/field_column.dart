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
    // Sort teams specifically within this field
    final rankedFieldTeams = RankCalculator.calculateRanks(teams);
    final fieldLeader = rankedFieldTeams.isNotEmpty && rankedFieldTeams.first.score > 0
        ? rankedFieldTeams.first
        : null;

    final isFieldA = field.id == 'field_a';
    final accentColor = isFieldA ? const Color(0xFF38BDF8) : const Color(0xFFA78BFA);

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.25),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: accentColor.withOpacity(0.35),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.15),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
            ),
            child: Row(
              children: [
                Icon(
                  isFieldA ? Icons.sports_tennis : Icons.stadium,
                  color: accentColor,
                  size: 26,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        field.name.toUpperCase(),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      if (fieldLeader != null)
                        Text(
                          'Leader: ${fieldLeader.name} (${fieldLeader.score} pts)',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: accentColor,
                          ),
                        ),
                    ],
                  ),
                ),
                if (onRename != null && isInteractive)
                  IconButton(
                    icon: const Icon(Icons.edit, size: 18),
                    tooltip: 'Rename ${field.name}',
                    onPressed: onRename,
                  ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${teams.length} teams',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
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
                        'No teams assigned to ${field.name}.\nAssign teams in the Admin Panel.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey.shade500),
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
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
