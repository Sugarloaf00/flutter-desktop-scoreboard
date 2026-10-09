import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:flutter_scoreboard_app/models/team.dart';
import 'package:flutter_scoreboard_app/models/field_model.dart';
import 'package:flutter_scoreboard_app/models/score_history.dart';
import 'package:flutter_scoreboard_app/database/database_helper.dart';
import 'package:flutter_scoreboard_app/utils/rank_calculator.dart';
import 'package:flutter_scoreboard_app/services/export_import_service.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('RankCalculator Tests', () {
    test('Calculates ranks in descending order with highest score at top', () {
      final now = DateTime.now();
      final teams = [
        Team(id: '1', name: 'Blue', color: 'Blue', score: 10, fieldId: 'field_a', createdAt: now, updatedAt: now),
        Team(id: '2', name: 'Red', color: 'Red', score: 35, fieldId: 'field_a', createdAt: now, updatedAt: now),
        Team(id: '3', name: 'Green', color: 'Green', score: 20, fieldId: 'field_a', createdAt: now, updatedAt: now),
      ];

      final ranked = RankCalculator.calculateRanks(teams);

      expect(ranked.first.name, 'Red');
      expect(ranked.first.rank, 1);
      expect(ranked[1].name, 'Green');
      expect(ranked[1].rank, 2);
      expect(ranked[2].name, 'Blue');
      expect(ranked[2].rank, 3);
    });

    test('Handles ties consistently so tied teams share the exact same rank', () {
      final now = DateTime.now();
      final teams = [
        Team(id: '1', name: 'Alpha', color: 'Red', score: 50, fieldId: 'field_a', createdAt: now, updatedAt: now),
        Team(id: '2', name: 'Beta', color: 'Blue', score: 50, fieldId: 'field_a', createdAt: now, updatedAt: now),
        Team(id: '3', name: 'Gamma', color: 'Green', score: 20, fieldId: 'field_a', createdAt: now, updatedAt: now),
      ];

      final ranked = RankCalculator.calculateRanks(teams);

      // Both Alpha and Beta have 50 points, so both are rank 1
      expect(ranked[0].rank, 1);
      expect(ranked[1].rank, 1);
      // Next team is rank 3 (standard competition 1-1-3 ranking)
      expect(ranked[2].rank, 3);
    });

    test('Tracks rank movement correctly (gained or lost position)', () {
      final now = DateTime.now();
      final teamMovedUp = Team(
        id: '1',
        name: 'Red',
        color: 'Red',
        score: 50,
        fieldId: 'field_a',
        createdAt: now,
        updatedAt: now,
        rank: 1,
        previousRank: 3, // was 3rd, now 1st
      );

      final teamMovedDown = Team(
        id: '2',
        name: 'Blue',
        color: 'Blue',
        score: 10,
        fieldId: 'field_a',
        createdAt: now,
        updatedAt: now,
        rank: 4,
        previousRank: 2, // was 2nd, now 4th
      );

      expect(RankCalculator.getRankMovement(teamMovedUp), 2); // +2 positions
      expect(RankCalculator.getRankMovement(teamMovedDown), -2); // -2 positions
    });
  });

  group('SQLite Database & Persistence Tests', () {
    late Database inMemoryDb;
    late DatabaseHelper dbHelper;

    setUp(() async {
      dbHelper = DatabaseHelper();
      inMemoryDb = await DatabaseHelper.createInMemoryDatabase();
    });

    tearDown(() async {
      await inMemoryDb.close();
    });

    test('Default seeding creates Field A, Field B and 6 colored teams', () async {
      final fields = await dbHelper.getAllFields(dbExecutor: inMemoryDb);
      expect(fields.length, 2);
      expect(fields.any((f) => f.id == 'field_a'), isTrue);
      expect(fields.any((f) => f.id == 'field_b'), isTrue);

      final teams = await dbHelper.getAllTeams(dbExecutor: inMemoryDb);
      expect(teams.length, 6);
      expect(teams.map((t) => t.color).toSet(), containsAll(['Red', 'Blue', 'Green', 'Yellow', 'Orange', 'Purple']));
    });

    test('Updating score saves new score and writes to score_history', () async {
      await dbHelper.updateTeamScore(
        teamId: 'team_red',
        newScore: 15,
        description: 'Goal scored',
        dbExecutor: inMemoryDb,
      );

      final teams = await dbHelper.getAllTeams(dbExecutor: inMemoryDb);
      final redTeam = teams.firstWhere((t) => t.id == 'team_red');
      expect(redTeam.score, 15);

      final history = await dbHelper.getScoreHistory(dbExecutor: inMemoryDb);
      expect(history.isNotEmpty, isTrue);
      expect(history.first.teamId, 'team_red');
      expect(history.first.previousScore, 0);
      expect(history.first.newScore, 15);
      expect(history.first.pointsChanged, 15);
      expect(history.first.description, 'Goal scored');
    });

    test('Resetting all scores zeroes out active teams and logs reset history', () async {
      await dbHelper.updateTeamScore(teamId: 'team_blue', newScore: 25, dbExecutor: inMemoryDb);
      await dbHelper.updateTeamScore(teamId: 'team_green', newScore: 40, dbExecutor: inMemoryDb);

      await dbHelper.resetAllScores(dbExecutor: inMemoryDb);

      final teams = await dbHelper.getAllTeams(dbExecutor: inMemoryDb);
      for (final t in teams) {
        expect(t.score, 0);
      }

      final history = await dbHelper.getScoreHistory(dbExecutor: inMemoryDb);
      expect(history.any((h) => h.description == 'Reset all scores'), isTrue);
    });

    test('Renaming field updates field table', () async {
      await dbHelper.updateFieldName('field_a', 'North Court', dbExecutor: inMemoryDb);
      final fields = await dbHelper.getAllFields(dbExecutor: inMemoryDb);
      final fieldA = fields.firstWhere((f) => f.id == 'field_a');
      expect(fieldA.name, 'North Court');
    });
  });

  group('Export and Import Service Tests', () {
    test('JSON export and import preserves fields, teams, and history integrity', () {
      final now = DateTime.now();
      final fields = [
        const FieldModel(id: 'field_a', name: 'Field A', displayOrder: 0),
        const FieldModel(id: 'field_b', name: 'Field B', displayOrder: 1),
      ];
      final teams = [
        Team(id: 'team_red', name: 'Red Dragons', color: 'Red', score: 45, fieldId: 'field_a', createdAt: now, updatedAt: now),
        Team(id: 'team_blue', name: 'Blue Knights', color: 'Blue', score: 30, fieldId: 'field_b', createdAt: now, updatedAt: now),
      ];
      final history = [
        ScoreHistory(id: 'h1', teamId: 'team_red', previousScore: 0, newScore: 45, pointsChanged: 45, timestamp: now, description: 'Initial'),
      ];

      final jsonStr = ExportImportService.exportToJson(fields, teams, history);
      final imported = ExportImportService.importFromJson(jsonStr);

      expect(imported.fields.length, 2);
      expect(imported.teams.length, 2);
      expect(imported.teams.first.name, 'Red Dragons');
      expect(imported.teams.first.score, 45);
      expect(imported.history.length, 1);
    });

    test('CSV export and import preserves team data correctly', () {
      final now = DateTime.now();
      final fields = [const FieldModel(id: 'field_a', name: 'Field A', displayOrder: 0)];
      final teams = [
        Team(id: 'team_1', name: 'Apex Titans', color: 'Green', score: 88, fieldId: 'field_a', createdAt: now, updatedAt: now),
      ];

      final csvStr = ExportImportService.exportToCsv(teams, fields);
      final importedTeams = ExportImportService.importTeamsFromCsv(csvStr);

      expect(importedTeams.length, 1);
      expect(importedTeams.first.id, 'team_1');
      expect(importedTeams.first.name, 'Apex Titans');
      expect(importedTeams.first.score, 88);
      expect(importedTeams.first.color, 'Green');
    });
  });
}
