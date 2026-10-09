import 'dart:convert';
import 'dart:io' show Directory;
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../models/team.dart';
import '../models/field_model.dart';
import '../models/score_history.dart';

class DatabaseHelper {
  static DatabaseHelper? _instance;
  static Database? _database;

  // Web in-memory & SharedPreferences cache
  static List<FieldModel>? _webFields;
  static List<Team>? _webTeams;
  static List<ScoreHistory>? _webHistory;
  static Map<String, String>? _webSettings;

  DatabaseHelper._internal();

  factory DatabaseHelper() {
    _instance ??= DatabaseHelper._internal();
    return _instance!;
  }

  static void initializeFfi() {
    if (!kIsWeb) {
      try {
        sqfliteFfiInit();
        databaseFactory = databaseFactoryFfi;
      } catch (_) {}
    }
  }

  // ---------------- WEB STORAGE HELPERS ----------------
  static Future<void> _initWebStorage() async {
    if (_webFields != null) return;
    try {
      final prefs = await SharedPreferences.getInstance();

      final fieldsJson = prefs.getString('web_fields');
      if (fieldsJson != null) {
        final List list = jsonDecode(fieldsJson);
        _webFields = list.map((m) => FieldModel.fromMap(Map<String, dynamic>.from(m))).toList();
      }

      if (prefs.containsKey('web_teams')) {
        final teamsJson = prefs.getString('web_teams');
        if (teamsJson != null) {
          final List list = jsonDecode(teamsJson);
          _webTeams = list.map((m) => Team.fromMap(Map<String, dynamic>.from(m))).toList();
        } else {
          _webTeams = [];
        }
      }

      final historyJson = prefs.getString('web_history');
      if (historyJson != null) {
        final List list = jsonDecode(historyJson);
        _webHistory = list.map((m) => ScoreHistory.fromMap(Map<String, dynamic>.from(m))).toList();
      }

      final settingsJson = prefs.getString('web_settings');
      if (settingsJson != null) {
        _webSettings = Map<String, String>.from(jsonDecode(settingsJson));
      }
    } catch (_) {}

    if (_webFields == null || _webFields!.isEmpty) {
      _webFields = [
        const FieldModel(id: 'field_a', name: 'Field A', displayOrder: 0),
        const FieldModel(id: 'field_b', name: 'Field B', displayOrder: 1),
      ];
    }

    if (_webTeams == null) {
      final now = DateTime.now();
      _webTeams = [
        Team(id: 'team_red', name: 'Red', color: 'Red', score: 0, fieldId: 'field_a', createdAt: now, updatedAt: now),
        Team(id: 'team_blue', name: 'Blue', color: 'Blue', score: 0, fieldId: 'field_a', createdAt: now, updatedAt: now),
        Team(id: 'team_green', name: 'Green', color: 'Green', score: 0, fieldId: 'field_a', createdAt: now, updatedAt: now),
        Team(id: 'team_yellow', name: 'Yellow', color: 'Yellow', score: 0, fieldId: 'field_b', createdAt: now, updatedAt: now),
        Team(id: 'team_orange', name: 'Orange', color: 'Orange', score: 0, fieldId: 'field_b', createdAt: now, updatedAt: now),
        Team(id: 'team_purple', name: 'Purple', color: 'Purple', score: 0, fieldId: 'field_b', createdAt: now, updatedAt: now),
      ];
      _saveWebTeams();
    }

    _webHistory ??= [];
    _webSettings ??= {};
  }

  static Future<void> _saveWebFields() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('web_fields', jsonEncode(_webFields!.map((f) => f.toMap()).toList()));
    } catch (_) {}
  }

  static Future<void> _saveWebTeams() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('web_teams', jsonEncode(_webTeams!.map((t) => t.toMap()).toList()));
    } catch (_) {}
  }

  static Future<void> _saveWebHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('web_history', jsonEncode(_webHistory!.map((h) => h.toMap()).toList()));
    } catch (_) {}
  }

  static Future<void> _saveWebSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('web_settings', jsonEncode(_webSettings));
    } catch (_) {}
  }

  // ---------------- SQLITE DESKTOP DATABASE ----------------
  Future<Database> get database async {
    if (kIsWeb) {
      throw UnsupportedError('SQLite FFI database is not used on Web');
    }
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase({String dbName = 'scoreboard.db'}) async {
    initializeFfi();

    String dbPath;
    try {
      final documentsDirectory = await getApplicationDocumentsDirectory();
      dbPath = p.join(documentsDirectory.path, 'ScoreboardApp', dbName);
      final directory = Directory(p.dirname(dbPath));
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }
    } catch (_) {
      dbPath = dbName;
    }

    return await databaseFactory.openDatabase(
      dbPath,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: _onCreate,
      ),
    );
  }

  // Used for in-memory testing
  static Future<Database> createInMemoryDatabase() async {
    initializeFfi();
    return await databaseFactoryFfi.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: _onCreateStatic,
      ),
    );
  }

  static Future<void> _onCreateStatic(Database db, int version) async {
    final helper = DatabaseHelper._internal();
    await helper._onCreate(db, version);
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS fields (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        display_order INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS teams (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        color TEXT NOT NULL,
        score INTEGER NOT NULL DEFAULT 0,
        field_id TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        is_active INTEGER NOT NULL DEFAULT 1
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS score_history (
        id TEXT PRIMARY KEY,
        team_id TEXT NOT NULL,
        previous_score INTEGER NOT NULL,
        new_score INTEGER NOT NULL,
        points_changed INTEGER NOT NULL,
        timestamp TEXT NOT NULL,
        description TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');

    await _seedDefaults(db);
  }

  Future<void> _seedDefaults(Database db) async {
    final existingFields = await db.query('fields');
    if (existingFields.isNotEmpty) return;

    final batch = db.batch();

    // Default Fields
    batch.insert('fields', {
      'id': 'field_a',
      'name': 'Field A',
      'display_order': 0,
    });
    batch.insert('fields', {
      'id': 'field_b',
      'name': 'Field B',
      'display_order': 1,
    });

    final now = DateTime.now().toIso8601String();

    // 6 Standard Color Teams
    final defaultTeams = [
      {'id': 'team_red', 'name': 'Red', 'color': 'Red', 'field_id': 'field_a'},
      {'id': 'team_blue', 'name': 'Blue', 'color': 'Blue', 'field_id': 'field_a'},
      {'id': 'team_green', 'name': 'Green', 'color': 'Green', 'field_id': 'field_a'},
      {'id': 'team_yellow', 'name': 'Yellow', 'color': 'Yellow', 'field_id': 'field_b'},
      {'id': 'team_orange', 'name': 'Orange', 'color': 'Orange', 'field_id': 'field_b'},
      {'id': 'team_purple', 'name': 'Purple', 'color': 'Purple', 'field_id': 'field_b'},
    ];

    for (final t in defaultTeams) {
      batch.insert('teams', {
        'id': t['id'],
        'name': t['name'],
        'color': t['color'],
        'score': 0,
        'field_id': t['field_id'],
        'created_at': now,
        'updated_at': now,
        'is_active': 1,
      });
    }

    await batch.commit(noResult: true);
  }

  // ---------------- FIELDS CRUD ----------------
  Future<List<FieldModel>> getAllFields({Database? dbExecutor}) async {
    if (kIsWeb) {
      await _initWebStorage();
      return List<FieldModel>.from(_webFields!);
    }

    try {
      final db = dbExecutor ?? await database;
      final maps = await db.query('fields', orderBy: 'display_order ASC');
      if (maps.isEmpty) {
        await _seedDefaults(db);
        final seededMaps = await db.query('fields', orderBy: 'display_order ASC');
        return seededMaps.map((m) => FieldModel.fromMap(m)).toList();
      }
      return maps.map((m) => FieldModel.fromMap(m)).toList();
    } catch (_) {
      return const [
        FieldModel(id: 'field_a', name: 'Field A', displayOrder: 0),
        FieldModel(id: 'field_b', name: 'Field B', displayOrder: 1),
      ];
    }
  }

  Future<void> updateFieldName(String id, String newName, {Database? dbExecutor}) async {
    if (kIsWeb) {
      await _initWebStorage();
      final index = _webFields!.indexWhere((f) => f.id == id);
      if (index != -1) {
        _webFields![index] = _webFields![index].copyWith(name: newName);
        await _saveWebFields();
      }
      return;
    }

    final db = dbExecutor ?? await database;
    await db.update(
      'fields',
      {'name': newName},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ---------------- TEAMS CRUD ----------------
  Future<List<Team>> getAllTeams({Database? dbExecutor}) async {
    if (kIsWeb) {
      await _initWebStorage();
      return _webTeams!.where((t) => t.isActive).toList();
    }

    try {
      final db = dbExecutor ?? await database;
      final maps = await db.query('teams', where: 'is_active = ?', whereArgs: [1]);
      if (maps.isEmpty) {
        final allTeams = await db.query('teams');
        if (allTeams.isEmpty) {
          await _seedDefaults(db);
          final seededMaps = await db.query('teams', where: 'is_active = ?', whereArgs: [1]);
          return seededMaps.map((m) => Team.fromMap(m)).toList();
        }
        return [];
      }
      return maps.map((m) => Team.fromMap(m)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> insertTeam(Team team, {Database? dbExecutor}) async {
    if (kIsWeb) {
      await _initWebStorage();
      _webTeams!.removeWhere((t) => t.id == team.id);
      _webTeams!.add(team);
      await _saveWebTeams();
      return;
    }

    final db = dbExecutor ?? await database;
    await db.insert('teams', team.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateTeam(Team team, {Database? dbExecutor}) async {
    if (kIsWeb) {
      await _initWebStorage();
      final idx = _webTeams!.indexWhere((t) => t.id == team.id);
      if (idx != -1) {
        _webTeams![idx] = team;
      } else {
        _webTeams!.add(team);
      }
      await _saveWebTeams();
      return;
    }

    final db = dbExecutor ?? await database;
    await db.update(
      'teams',
      team.toMap(),
      where: 'id = ?',
      whereArgs: [team.id],
    );
  }

  Future<void> deleteTeam(String teamId, {Database? dbExecutor}) async {
    if (kIsWeb) {
      await _initWebStorage();
      _webTeams?.removeWhere((t) => t.id == teamId);
      await _saveWebTeams();
      return;
    }

    final db = dbExecutor ?? await database;
    await db.update(
      'teams',
      {'is_active': 0},
      where: 'id = ?',
      whereArgs: [teamId],
    );
  }

  Future<void> restoreDefaultTeams({Database? dbExecutor}) async {
    if (kIsWeb) {
      final now = DateTime.now();
      _webTeams = [
        Team(id: 'team_red', name: 'Red', color: 'Red', score: 0, fieldId: 'field_a', createdAt: now, updatedAt: now),
        Team(id: 'team_blue', name: 'Blue', color: 'Blue', score: 0, fieldId: 'field_a', createdAt: now, updatedAt: now),
        Team(id: 'team_green', name: 'Green', color: 'Green', score: 0, fieldId: 'field_a', createdAt: now, updatedAt: now),
        Team(id: 'team_yellow', name: 'Yellow', color: 'Yellow', score: 0, fieldId: 'field_b', createdAt: now, updatedAt: now),
        Team(id: 'team_orange', name: 'Orange', color: 'Orange', score: 0, fieldId: 'field_b', createdAt: now, updatedAt: now),
        Team(id: 'team_purple', name: 'Purple', color: 'Purple', score: 0, fieldId: 'field_b', createdAt: now, updatedAt: now),
      ];
      await _saveWebTeams();
      return;
    }

    final db = dbExecutor ?? await database;
    await db.delete('teams');
    await _seedDefaults(db);
  }

  Future<void> updateTeamScore({
    required String teamId,
    required int newScore,
    String? description,
    Database? dbExecutor,
  }) async {
    if (kIsWeb) {
      await _initWebStorage();
      final idx = _webTeams!.indexWhere((t) => t.id == teamId);
      if (idx != -1) {
        final currentTeam = _webTeams![idx];
        final previousScore = currentTeam.score;
        final pointsChanged = newScore - previousScore;
        final now = DateTime.now();

        _webTeams![idx] = currentTeam.copyWith(
          score: newScore,
          updatedAt: now,
        );

        final historyEntry = ScoreHistory(
          id: 'hist_${now.microsecondsSinceEpoch}',
          teamId: teamId,
          previousScore: previousScore,
          newScore: newScore,
          pointsChanged: pointsChanged,
          timestamp: now,
          description: description ?? (pointsChanged >= 0 ? 'Added $pointsChanged pts' : 'Deducted ${-pointsChanged} pts'),
        );
        _webHistory!.insert(0, historyEntry);

        await _saveWebTeams();
        await _saveWebHistory();
      }
      return;
    }

    final db = dbExecutor ?? await database;

    await db.transaction((txn) async {
      final teamRows = await txn.query('teams', where: 'id = ?', whereArgs: [teamId]);
      if (teamRows.isEmpty) return;

      final previousScore = (teamRows.first['score'] as num?)?.toInt() ?? 0;
      final pointsChanged = newScore - previousScore;
      final now = DateTime.now();

      await txn.update(
        'teams',
        {
          'score': newScore,
          'updated_at': now.toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [teamId],
      );

      final historyId = 'hist_${now.microsecondsSinceEpoch}';
      await txn.insert('score_history', {
        'id': historyId,
        'team_id': teamId,
        'previous_score': previousScore,
        'new_score': newScore,
        'points_changed': pointsChanged,
        'timestamp': now.toIso8601String(),
        'description': description ?? (pointsChanged >= 0 ? 'Added $pointsChanged pts' : 'Deducted ${-pointsChanged} pts'),
      });
    });
  }

  Future<void> resetAllScores({Database? dbExecutor}) async {
    if (kIsWeb) {
      await _initWebStorage();
      final now = DateTime.now();
      for (int i = 0; i < _webTeams!.length; i++) {
        final t = _webTeams![i];
        if (t.isActive && t.score != 0) {
          final prev = t.score;
          _webTeams![i] = t.copyWith(score: 0, updatedAt: now);
          _webHistory!.insert(
            0,
            ScoreHistory(
              id: 'hist_reset_${t.id}_${now.microsecondsSinceEpoch}',
              teamId: t.id,
              previousScore: prev,
              newScore: 0,
              pointsChanged: -prev,
              timestamp: now,
              description: 'Reset all scores',
            ),
          );
        }
      }
      await _saveWebTeams();
      await _saveWebHistory();
      return;
    }

    final db = dbExecutor ?? await database;
    final now = DateTime.now();

    await db.transaction((txn) async {
      final teams = await txn.query('teams', where: 'is_active = ?', whereArgs: [1]);
      for (final t in teams) {
        final teamId = t['id'] as String;
        final previousScore = (t['score'] as num?)?.toInt() ?? 0;
        if (previousScore == 0) continue;

        await txn.update(
          'teams',
          {'score': 0, 'updated_at': now.toIso8601String()},
          where: 'id = ?',
          whereArgs: [teamId],
        );

        final historyId = 'hist_reset_${teamId}_${now.microsecondsSinceEpoch}';
        await txn.insert('score_history', {
          'id': historyId,
          'team_id': teamId,
          'previous_score': previousScore,
          'new_score': 0,
          'points_changed': -previousScore,
          'timestamp': now.toIso8601String(),
          'description': 'Reset all scores',
        });
      }
    });
  }

  // ---------------- SCORE HISTORY CRUD ----------------
  Future<List<ScoreHistory>> getScoreHistory({int limit = 100, Database? dbExecutor}) async {
    if (kIsWeb) {
      await _initWebStorage();
      return _webHistory!.take(limit).toList();
    }

    try {
      final db = dbExecutor ?? await database;
      final maps = await db.query(
        'score_history',
        orderBy: 'timestamp DESC',
        limit: limit,
      );
      return maps.map((m) => ScoreHistory.fromMap(m)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> clearScoreHistory({Database? dbExecutor}) async {
    if (kIsWeb) {
      await _initWebStorage();
      _webHistory!.clear();
      await _saveWebHistory();
      return;
    }

    final db = dbExecutor ?? await database;
    await db.delete('score_history');
  }

  // ---------------- SETTINGS ----------------
  Future<void> saveSetting(String key, String value, {Database? dbExecutor}) async {
    if (kIsWeb) {
      await _initWebStorage();
      _webSettings![key] = value;
      await _saveWebSettings();
      return;
    }

    final db = dbExecutor ?? await database;
    await db.insert(
      'settings',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<String?> getSetting(String key, {Database? dbExecutor}) async {
    if (kIsWeb) {
      await _initWebStorage();
      return _webSettings?[key];
    }

    try {
      final db = dbExecutor ?? await database;
      final res = await db.query('settings', where: 'key = ?', whereArgs: [key]);
      if (res.isNotEmpty) {
        return res.first['value'] as String?;
      }
    } catch (_) {}
    return null;
  }
}
