class ScoreHistory {
  final String id;
  final String teamId;
  final int previousScore;
  final int newScore;
  final int pointsChanged;
  final DateTime timestamp;
  final String? description;

  const ScoreHistory({
    required this.id,
    required this.teamId,
    required this.previousScore,
    required this.newScore,
    required this.pointsChanged,
    required this.timestamp,
    this.description,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'team_id': teamId,
      'previous_score': previousScore,
      'new_score': newScore,
      'points_changed': pointsChanged,
      'timestamp': timestamp.toIso8601String(),
      'description': description,
    };
  }

  factory ScoreHistory.fromMap(Map<String, dynamic> map) {
    return ScoreHistory(
      id: map['id'] as String,
      teamId: map['team_id'] as String,
      previousScore: (map['previous_score'] as num?)?.toInt() ?? 0,
      newScore: (map['new_score'] as num?)?.toInt() ?? 0,
      pointsChanged: (map['points_changed'] as num?)?.toInt() ?? 0,
      timestamp: DateTime.tryParse(map['timestamp'] as String? ?? '') ?? DateTime.now(),
      description: map['description'] as String?,
    );
  }
}
