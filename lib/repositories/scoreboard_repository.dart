import '../models/team.dart';
import '../models/field_model.dart';
import '../models/score_history.dart';
import '../models/app_settings.dart';
import '../database/database_helper.dart';
import '../services/firestore_service.dart';
import '../utils/rank_calculator.dart';

class ScoreboardRepository {
  final DatabaseHelper _dbHelper;
  FirestoreService? _firestoreService;
  Map<String, int> _lastOverallRanks = {};
  Map<String, int> _lastFieldRanks = {};

  ScoreboardRepository({
    DatabaseHelper? dbHelper,
    FirestoreService? firestoreService,
  })  : _dbHelper = dbHelper ?? DatabaseHelper(),
        _firestoreService = firestoreService;

  void configureFirestore(String projectId) {
    if (projectId.isNotEmpty) {
      _firestoreService = FirestoreService(projectId: projectId);
    } else {
      _firestoreService = null;
    }
  }

  Future<List<FieldModel>> getFields() async {
    try {
      final fields = await _dbHelper.getAllFields();
      if (fields.isNotEmpty) return fields;
    } catch (_) {}
    return const [
      FieldModel(id: 'field_a', name: 'Field A', displayOrder: 0),
      FieldModel(id: 'field_b', name: 'Field B', displayOrder: 1),
    ];
  }

  Future<void> updateFieldName(String fieldId, String newName) async {
    try {
      await _dbHelper.updateFieldName(fieldId, newName);
      final fields = await getFields();
      final updatedField = fields.firstWhere((f) => f.id == fieldId, orElse: () => FieldModel(id: fieldId, name: newName));
      _firestoreService?.syncField(updatedField);
    } catch (_) {}
  }

  Future<List<Team>> getTeams({bool autoSort = true}) async {
    List<Team> rawTeams = [];
    try {
      rawTeams = await _dbHelper.getAllTeams();
    } catch (_) {}

    if (!autoSort) {
      return rawTeams;
    }

    final rankedTeams = RankCalculator.calculateRanks(
      rawTeams,
      previousRanks: _lastOverallRanks,
    );

    _lastOverallRanks = {for (final t in rankedTeams) t.id: t.rank ?? 0};

    return rankedTeams;
  }

  Future<List<Team>> getTeamsForField(String fieldId, {bool autoSort = true}) async {
    final allTeams = await getTeams(autoSort: false);
    final fieldTeams = allTeams.where((t) => t.fieldId == fieldId).toList();

    if (!autoSort) {
      return fieldTeams;
    }

    final rankedFieldTeams = RankCalculator.calculateRanks(
      fieldTeams,
      previousRanks: _lastFieldRanks,
    );

    _lastFieldRanks = {for (final t in rankedFieldTeams) t.id: t.rank ?? 0};

    return rankedFieldTeams;
  }

  Future<void> updateTeamScore({
    required String teamId,
    required int newScore,
    String? description,
    bool syncToCloud = true,
  }) async {
    try {
      await _dbHelper.updateTeamScore(
        teamId: teamId,
        newScore: newScore,
        description: description,
      );
    } catch (_) {}

    if (syncToCloud && _firestoreService != null) {
      try {
        final teams = await getTeams(autoSort: false);
        final team = teams.where((t) => t.id == teamId).firstOrNull;
        if (team != null) {
          _firestoreService?.syncTeam(team);
        }
      } catch (_) {}
    }
  }

  Future<void> addTeam(Team team) async {
    try {
      await _dbHelper.insertTeam(team);
    } catch (_) {}
    _firestoreService?.syncTeam(team);
  }

  Future<void> updateTeam(Team team) async {
    try {
      await _dbHelper.updateTeam(team);
    } catch (_) {}
    _firestoreService?.syncTeam(team);
  }

  Future<void> deleteTeam(String teamId) async {
    try {
      await _dbHelper.deleteTeam(teamId);
    } catch (_) {}
  }

  Future<void> restoreDefaultTeams() async {
    try {
      await _dbHelper.restoreDefaultTeams();
    } catch (_) {}
  }

  Future<void> resetAllScores() async {
    try {
      await _dbHelper.resetAllScores();
    } catch (_) {}

    if (_firestoreService != null) {
      try {
        final teams = await getTeams(autoSort: false);
        for (final t in teams) {
          _firestoreService?.syncTeam(t);
        }
      } catch (_) {}
    }
  }

  Future<List<ScoreHistory>> getHistory({int limit = 100}) async {
    try {
      return await _dbHelper.getScoreHistory(limit: limit);
    } catch (_) {
      return [];
    }
  }

  Future<void> clearHistory() async {
    try {
      await _dbHelper.clearScoreHistory();
    } catch (_) {}
  }

  Future<AppSettings> loadSettings() async {
    try {
      final allowNeg = await _dbHelper.getSetting('allow_negative_scores');
      final anim = await _dbHelper.getSetting('enable_animations');
      final sound = await _dbHelper.getSetting('enable_sound');
      final autoSort = await _dbHelper.getSetting('enable_automatic_sorting');
      final cloudSync = await _dbHelper.getSetting('firestore_sync_enabled');
      final projId = await _dbHelper.getSetting('firebase_project_id');

      return AppSettings(
        allowNegativeScores: allowNeg == 'true',
        enableAnimations: anim != 'false',
        enableSound: sound != 'false',
        enableAutomaticSorting: autoSort != 'false',
        firestoreSyncEnabled: cloudSync == 'true',
        firebaseProjectId: projId ?? 'scoreboard-app-live-9481',
      );
    } catch (_) {
      return const AppSettings(firebaseProjectId: 'scoreboard-app-live-9481');
    }
  }

  Future<void> saveSettings(AppSettings settings) async {
    try {
      await _dbHelper.saveSetting('allow_negative_scores', settings.allowNegativeScores.toString());
      await _dbHelper.saveSetting('enable_animations', settings.enableAnimations.toString());
      await _dbHelper.saveSetting('enable_sound', settings.enableSound.toString());
      await _dbHelper.saveSetting('enable_automatic_sorting', settings.enableAutomaticSorting.toString());
      await _dbHelper.saveSetting('firestore_sync_enabled', settings.firestoreSyncEnabled.toString());
      await _dbHelper.saveSetting('firebase_project_id', settings.firebaseProjectId);
    } catch (_) {}

    if (settings.firestoreSyncEnabled && settings.firebaseProjectId.isNotEmpty) {
      configureFirestore(settings.firebaseProjectId);
    } else {
      _firestoreService = null;
    }
  }
}
