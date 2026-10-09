import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/team.dart';
import '../models/field_model.dart';
import '../models/score_history.dart';
import '../models/app_settings.dart';
import '../repositories/scoreboard_repository.dart';
import '../services/audio_service.dart';

final scoreboardRepositoryProvider = Provider<ScoreboardRepository>((ref) {
  return ScoreboardRepository();
});

class SettingsNotifier extends Notifier<AppSettings> {
  @override
  AppSettings build() {
    _load();
    return const AppSettings();
  }

  Future<void> _load() async {
    final repo = ref.read(scoreboardRepositoryProvider);
    final settings = await repo.loadSettings();
    state = settings;
    if (settings.firestoreSyncEnabled && settings.firebaseProjectId.isNotEmpty) {
      repo.configureFirestore(settings.firebaseProjectId);
    }
  }

  Future<void> updateSettings(AppSettings newSettings) async {
    state = newSettings;
    final repo = ref.read(scoreboardRepositoryProvider);
    await repo.saveSettings(newSettings);
  }
}

final settingsProvider = NotifierProvider<SettingsNotifier, AppSettings>(SettingsNotifier.new);

class FieldsNotifier extends AsyncNotifier<List<FieldModel>> {
  @override
  Future<List<FieldModel>> build() async {
    final repo = ref.read(scoreboardRepositoryProvider);
    return await repo.getFields();
  }

  Future<void> updateFieldName(String id, String newName) async {
    final repo = ref.read(scoreboardRepositoryProvider);
    await repo.updateFieldName(id, newName);
    ref.invalidateSelf();
  }
}

final fieldsProvider = AsyncNotifierProvider<FieldsNotifier, List<FieldModel>>(FieldsNotifier.new);

class TeamsNotifier extends AsyncNotifier<List<Team>> {
  String? _previousLeaderId;

  @override
  Future<List<Team>> build() async {
    final repo = ref.read(scoreboardRepositoryProvider);
    final settings = ref.watch(settingsProvider);
    final teams = await repo.getTeams(autoSort: settings.enableAutomaticSorting);
    _checkLeaderChange(teams, settings.enableSound);
    return teams;
  }

  void _checkLeaderChange(List<Team> teams, bool soundEnabled) {
    if (teams.isEmpty) return;
    final topTeam = teams.first;
    if (topTeam.score > 0 && topTeam.id != _previousLeaderId) {
      if (_previousLeaderId != null) {
        AudioService.play(SoundEffectType.newLeader, enabled: soundEnabled);
      }
      _previousLeaderId = topTeam.id;
    }
  }

  Future<void> updateScore({
    required String teamId,
    required int newScore,
    String? description,
  }) async {
    final settings = ref.read(settingsProvider);
    if (!settings.allowNegativeScores && newScore < 0) {
      newScore = 0;
    }

    final currentTeams = state.value ?? [];
    final currentTeam = currentTeams.where((t) => t.id == teamId).firstOrNull;
    if (currentTeam != null) {
      if (newScore > currentTeam.score) {
        AudioService.play(SoundEffectType.pointAdded, enabled: settings.enableSound);
      } else if (newScore < currentTeam.score) {
        AudioService.play(SoundEffectType.pointDeducted, enabled: settings.enableSound);
      }
    }

    final repo = ref.read(scoreboardRepositoryProvider);
    await repo.updateTeamScore(
      teamId: teamId,
      newScore: newScore,
      description: description,
    );

    ref.invalidateSelf();
    ref.invalidate(historyProvider);
  }

  Future<void> adjustScore({
    required String teamId,
    required int delta,
    String? description,
  }) async {
    final currentTeams = state.value ?? [];
    final currentTeam = currentTeams.where((t) => t.id == teamId).firstOrNull;
    final currentScore = currentTeam?.score ?? 0;
    await updateScore(
      teamId: teamId,
      newScore: currentScore + delta,
      description: description,
    );
  }

  Future<void> resetScore(String teamId) async {
    final settings = ref.read(settingsProvider);
    AudioService.play(SoundEffectType.reset, enabled: settings.enableSound);
    await updateScore(
      teamId: teamId,
      newScore: 0,
      description: 'Reset score to 0',
    );
  }

  Future<void> resetAllScores() async {
    final settings = ref.read(settingsProvider);
    AudioService.play(SoundEffectType.reset, enabled: settings.enableSound);
    final repo = ref.read(scoreboardRepositoryProvider);
    await repo.resetAllScores();
    _previousLeaderId = null;
    ref.invalidateSelf();
    ref.invalidate(historyProvider);
  }

  Future<void> addTeam(Team team) async {
    final repo = ref.read(scoreboardRepositoryProvider);
    await repo.addTeam(team);
    ref.invalidateSelf();
  }

  Future<void> updateTeam(Team team) async {
    final repo = ref.read(scoreboardRepositoryProvider);
    await repo.updateTeam(team);
    ref.invalidateSelf();
  }

  Future<void> deleteTeam(String teamId) async {
    final repo = ref.read(scoreboardRepositoryProvider);
    await repo.deleteTeam(teamId);
    ref.invalidateSelf();
  }

  Future<void> restoreDefaultTeams() async {
    final repo = ref.read(scoreboardRepositoryProvider);
    await repo.restoreDefaultTeams();
    ref.invalidateSelf();
  }
}

final teamsProvider = AsyncNotifierProvider<TeamsNotifier, List<Team>>(TeamsNotifier.new);

class HistoryNotifier extends AsyncNotifier<List<ScoreHistory>> {
  @override
  Future<List<ScoreHistory>> build() async {
    final repo = ref.read(scoreboardRepositoryProvider);
    return await repo.getHistory();
  }

  Future<void> clearHistory() async {
    final repo = ref.read(scoreboardRepositoryProvider);
    await repo.clearHistory();
    ref.invalidateSelf();
  }
}

final historyProvider = AsyncNotifierProvider<HistoryNotifier, List<ScoreHistory>>(HistoryNotifier.new);

// Helper selector for teams in a specific field
final fieldTeamsProvider = Provider.family<List<Team>, String>((ref, fieldId) {
  final teamsAsync = ref.watch(teamsProvider);
  return teamsAsync.maybeWhen(
    data: (teams) => teams.where((t) => t.fieldId == fieldId).toList(),
    orElse: () => [],
  );
});

// Helper selector for the overall leading team
final overallLeaderProvider = Provider<Team?>((ref) {
  final teamsAsync = ref.watch(teamsProvider);
  return teamsAsync.maybeWhen(
    data: (teams) {
      if (teams.isEmpty) return null;
      final leader = teams.first;
      return leader.score > 0 ? leader : null;
    },
    orElse: () => null,
  );
});
