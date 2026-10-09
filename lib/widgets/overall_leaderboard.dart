import 'package:flutter/material.dart';
import '../models/team.dart';
import '../models/field_model.dart';
import '../utils/rank_calculator.dart';
import 'three_d_trophy_widget.dart';
import 'team_tile.dart';

class OverallLeaderboard extends StatelessWidget {
  final List<Team> teams;
  final List<FieldModel> fields;
  final bool isInteractive;

  const OverallLeaderboard({
    super.key,
    required this.teams,
    required this.fields,
    this.isInteractive = true,
  });

  @override
  Widget build(BuildContext context) {
    final rankedAll = RankCalculator.calculateRanks(teams);
    final overallWinner = rankedAll.isNotEmpty && rankedAll.first.score > 0 ? rankedAll.first : null;

    return Column(
      children: [
        if (overallWinner != null)
          Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFF131D33),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFFFFD700).withOpacity(0.5),
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                const SizedBox(
                  width: 64,
                  height: 64,
                  child: ThreeDTrophyWidget(size: 64),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.emoji_events, color: Color(0xFFFFD700), size: 18),
                          const SizedBox(width: 6),
                          const Text(
                            'OVERALL TOURNAMENT LEADER',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2,
                              color: Color(0xFFFFD700),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        overallWinner.name,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Total Score: ${overallWinner.score} points',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

        Expanded(
          child: ListView.builder(
            itemCount: rankedAll.length,
            itemBuilder: (context, index) {
              final team = rankedAll[index];
              return TeamTile(
                key: ValueKey('overall_${team.id}'),
                team: team,
                isInteractive: isInteractive,
              );
            },
          ),
        ),
      ],
    );
  }
}
