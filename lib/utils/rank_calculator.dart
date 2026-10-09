import '../models/team.dart';

class RankCalculator {
  /// Sorts teams in descending order of score, breaking ties deterministically
  /// by name or creation order. Assigns standard competition ranking (e.g., 1, 2, 2, 4)
  /// so tied teams share the exact same displayed rank.
  static List<Team> calculateRanks(List<Team> teams, {Map<String, int>? previousRanks}) {
    if (teams.isEmpty) return [];

    // Create a copy to sort
    final sorted = List<Team>.from(teams);

    // Sort descending by score; if tied, break ties deterministically by name
    sorted.sort((a, b) {
      final scoreCompare = b.score.compareTo(a.score);
      if (scoreCompare != 0) return scoreCompare;
      // Secondary deterministic tie breaker
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });

    final rankedList = <Team>[];
    int currentRank = 1;

    for (int i = 0; i < sorted.length; i++) {
      if (i > 0 && sorted[i].score < sorted[i - 1].score) {
        // Standard competition ranking (1224)
        currentRank = i + 1;
      }

      final team = sorted[i];
      final prevRank = previousRanks != null ? previousRanks[team.id] : team.rank;

      rankedList.add(
        team.copyWith(
          rank: currentRank,
          previousRank: prevRank,
        ),
      );
    }

    return rankedList;
  }

  /// Calculates rank movement: >0 means moved up, <0 means moved down, 0 means same
  static int getRankMovement(Team team) {
    if (team.rank == null || team.previousRank == null) return 0;
    // Lower numerical rank = better position (e.g. rank 1 is better than rank 2)
    // So if previous was 3 and current is 1: 3 - 1 = +2 (gained 2 positions)
    return team.previousRank! - team.rank!;
  }
}
