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
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF312E81), Color(0xFF1E1B4B)],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFFFD700), width: 2),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFFD700).withOpacity(0.3),
                  blurRadius: 16,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Row(
              children: [
                const SizedBox(
                  width: 90,
                  height: 90,
                  child: ThreeDTrophyWidget(size: 90),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.emoji_events, color: Color(0xFFFFD700), size: 22),
                          const SizedBox(width: 6),
                          Text(
                            'OVERALL TOURNAMENT LEADER',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.5,
                              color: const Color(0xFFFFD700),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        overallWinner.name,
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Total Score: ${overallWinner.score} points',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.white.withOpacity(0.9),
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
                key: ValueKey(team.id),
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
