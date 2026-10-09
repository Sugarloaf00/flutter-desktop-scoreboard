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
    return await _dbHelper.getAllFields();
  }

  Future<void> updateFieldName(String fieldId, String newName) async {
    await _dbHelper.updateFieldName(fieldId, newName);
    final fields = await _dbHelper.getAllFields();
    final updatedField = fields.firstWhere((f) => f.id == fieldId);
    _firestoreService?.syncField(updatedField);
  }

  Future<List<Team>> getTeams({bool autoSort = true}) async {
    final rawTeams = await _dbHelper.getAllTeams();

    if (!autoSort) {
      return rawTeams;
    }

    final rankedTeams = RankCalculator.calculateRanks(
      rawTeams,
      previousRanks: _lastOverallRanks,
    );

    // Cache current ranks for the next comparison
    _lastOverallRanks = {for (final t in rankedTeams) t.id: t.rank ?? 0};

    return rankedTeams;
  }

  Future<List<Team>> getTeamsForField(String fieldId, {bool autoSort = true}) async {
    final allTeams = await _dbHelper.getAllTeams();
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
    await _dbHelper.updateTeamScore(
      teamId: teamId,
      newScore: newScore,
      description: description,
    );

    if (syncToCloud && _firestoreService != null) {
      final teams = await _dbHelper.getAllTeams();
      final team = teams.where((t) => t.id == teamId).firstOrNull;
      if (team != null) {
        _firestoreService?.syncTeam(team);
      }
    }
  }

  Future<void> addTeam(Team team) async {
    await _dbHelper.insertTeam(team);
    _firestoreService?.syncTeam(team);
  }

  Future<void> updateTeam(Team team) async {
    await _dbHelper.updateTeam(team);
    _firestoreService?.syncTeam(team);
  }

  Future<void> deleteTeam(String teamId) async {
    await _dbHelper.deleteTeam(teamId);
  }

  Future<void> resetAllScores() async {
    await _dbHelper.resetAllScores();
    if (_firestoreService != null) {
      final teams = await _dbHelper.getAllTeams();
      for (final t in teams) {
        _firestoreService?.syncTeam(t);
      }
    }
  }

  Future<List<ScoreHistory>> getHistory({int limit = 100}) async {
    return await _dbHelper.getScoreHistory(limit: limit);
  }

  Future<void> clearHistory() async {
    await _dbHelper.clearScoreHistory();
  }

  Future<AppSettings> loadSettings() async {
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
      firebaseProjectId: projId ?? '',
    );
  }

  Future<void> saveSettings(AppSettings settings) async {
    await _dbHelper.saveSetting('allow_negative_scores', settings.allowNegativeScores.toString());
    await _dbHelper.saveSetting('enable_animations', settings.enableAnimations.toString());
    await _dbHelper.saveSetting('enable_sound', settings.enableSound.toString());
    await _dbHelper.saveSetting('enable_automatic_sorting', settings.enableAutomaticSorting.toString());
    await _dbHelper.saveSetting('firestore_sync_enabled', settings.firestoreSyncEnabled.toString());
    await _dbHelper.saveSetting('firebase_project_id', settings.firebaseProjectId);

    if (settings.firestoreSyncEnabled && settings.firebaseProjectId.isNotEmpty) {
      configureFirestore(settings.firebaseProjectId);
    } else {
      _firestoreService = null;
    }
  }
}
