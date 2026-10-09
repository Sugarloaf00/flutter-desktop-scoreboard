class AppSettings {
  final bool allowNegativeScores;
  final bool enableAnimations;
  final bool enableSound;
  final bool enableAutomaticSorting;
  final bool firestoreSyncEnabled;
  final String firebaseProjectId;

  const AppSettings({
    this.allowNegativeScores = false,
    this.enableAnimations = true,
    this.enableSound = true,
    this.enableAutomaticSorting = true,
    this.firestoreSyncEnabled = false,
    this.firebaseProjectId = 'scoreboard-app-live-9481',
  });

  AppSettings copyWith({
    bool? allowNegativeScores,
    bool? enableAnimations,
    bool? enableSound,
    bool? enableAutomaticSorting,
    bool? firestoreSyncEnabled,
    String? firebaseProjectId,
  }) {
    return AppSettings(
      allowNegativeScores: allowNegativeScores ?? this.allowNegativeScores,
      enableAnimations: enableAnimations ?? this.enableAnimations,
      enableSound: enableSound ?? this.enableSound,
      enableAutomaticSorting: enableAutomaticSorting ?? this.enableAutomaticSorting,
      firestoreSyncEnabled: firestoreSyncEnabled ?? this.firestoreSyncEnabled,
      firebaseProjectId: firebaseProjectId ?? this.firebaseProjectId,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'allow_negative_scores': allowNegativeScores ? 1 : 0,
      'enable_animations': enableAnimations ? 1 : 0,
      'enable_sound': enableSound ? 1 : 0,
      'enable_automatic_sorting': enableAutomaticSorting ? 1 : 0,
      'firestore_sync_enabled': firestoreSyncEnabled ? 1 : 0,
      'firebase_project_id': firebaseProjectId,
    };
  }

  factory AppSettings.fromMap(Map<String, dynamic> map) {
    return AppSettings(
      allowNegativeScores: ((map['allow_negative_scores'] as num?)?.toInt() ?? 0) == 1,
      enableAnimations: ((map['enable_animations'] as num?)?.toInt() ?? 1) == 1,
      enableSound: ((map['enable_sound'] as num?)?.toInt() ?? 1) == 1,
      enableAutomaticSorting: ((map['enable_automatic_sorting'] as num?)?.toInt() ?? 1) == 1,
      firestoreSyncEnabled: ((map['firestore_sync_enabled'] as num?)?.toInt() ?? 0) == 1,
      firebaseProjectId: map['firebase_project_id'] as String? ?? '',
    );
  }
}
