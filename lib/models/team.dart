class Team {
  final String id;
  final String name;
  final String color;
  final int score;
  final String fieldId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;

  // Runtime ranking properties (not persisted in DB)
  final int? rank;
  final int? previousRank;

  const Team({
    required this.id,
    required this.name,
    required this.color,
    this.score = 0,
    required this.fieldId,
    required this.createdAt,
    required this.updatedAt,
    this.isActive = true,
    this.rank,
    this.previousRank,
  });

  Team copyWith({
    String? id,
    String? name,
    String? color,
    int? score,
    String? fieldId,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
    int? rank,
    int? previousRank,
  }) {
    return Team(
      id: id ?? this.id,
      name: name ?? this.name,
      color: color ?? this.color,
      score: score ?? this.score,
      fieldId: fieldId ?? this.fieldId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
      rank: rank ?? this.rank,
      previousRank: previousRank ?? this.previousRank,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'color': color,
      'score': score,
      'field_id': fieldId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_active': isActive ? 1 : 0,
    };
  }

  factory Team.fromMap(Map<String, dynamic> map) {
    return Team(
      id: map['id'] as String,
      name: map['name'] as String,
      color: map['color'] as String,
      score: (map['score'] as num?)?.toInt() ?? 0,
      fieldId: map['field_id'] as String,
      createdAt: DateTime.tryParse(map['created_at'] as String? ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(map['updated_at'] as String? ?? '') ?? DateTime.now(),
      isActive: ((map['is_active'] as num?)?.toInt() ?? 1) == 1,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Team &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          color == other.color &&
          score == other.score &&
          fieldId == other.fieldId &&
          isActive == other.isActive;

  @override
  int get hashCode =>
      id.hashCode ^
      name.hashCode ^
      color.hashCode ^
      score.hashCode ^
      fieldId.hashCode ^
      isActive.hashCode;
}
