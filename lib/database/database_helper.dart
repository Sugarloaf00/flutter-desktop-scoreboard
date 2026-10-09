import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../models/team.dart';
import '../models/field_model.dart';
import '../models/score_history.dart';

class DatabaseHelper {
  static DatabaseHelper? _instance;
  static Database? _database;

  DatabaseHelper._internal();

  factory DatabaseHelper() {
    _instance ??= DatabaseHelper._internal();
    return _instance!;
  }

  static void initializeFfi() {
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase({String dbName = 'scoreboard.db'}) async {
    initializeFfi();

    String dbPath;
    if (kIsWeb) {
      dbPath = dbName;
    } else {
      final documentsDirectory = await getApplicationDocumentsDirectory();
      dbPath = p.join(documentsDirectory.path, 'ScoreboardApp', dbName);
      final directory = Directory(p.dirname(dbPath));
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }
    }

    return await openDatabase(
      dbPath,
      version: 1,
      onCreate: _onCreate,
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
      CREATE TABLE fields (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        display_order INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE teams (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        color TEXT NOT NULL,
        score INTEGER NOT NULL DEFAULT 0,
        field_id TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        is_active INTEGER NOT NULL DEFAULT 1,
        FOREIGN KEY (field_id) REFERENCES fields (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE score_history (
        id TEXT PRIMARY KEY,
        team_id TEXT NOT NULL,
        previous_score INTEGER NOT NULL,
        new_score INTEGER NOT NULL,
        points_changed INTEGER NOT NULL,
        timestamp TEXT NOT NULL,
        description TEXT,
        FOREIGN KEY (team_id) REFERENCES teams (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');

    await _seedDefaults(db);
  }

  Future<void> _seedDefaults(Database db) async {
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
    final db = dbExecutor ?? await database;
    final maps = await db.query('fields', orderBy: 'display_order ASC');
    return maps.map((m) => FieldModel.fromMap(m)).toList();
  }

  Future<void> updateFieldName(String id, String newName, {Database? dbExecutor}) async {
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
    final db = dbExecutor ?? await database;
    final maps = await db.query('teams', where: 'is_active = ?', whereArgs: [1]);
    return maps.map((m) => Team.fromMap(m)).toList();
  }

  Future<void> insertTeam(Team team, {Database? dbExecutor}) async {
    final db = dbExecutor ?? await database;
    await db.insert('teams', team.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateTeam(Team team, {Database? dbExecutor}) async {
    final db = dbExecutor ?? await database;
    await db.update(
      'teams',
      team.toMap(),
      where: 'id = ?',
      whereArgs: [team.id],
    );
  }

  Future<void> deleteTeam(String teamId, {Database? dbExecutor}) async {
    final db = dbExecutor ?? await database;
    await db.update(
      'teams',
      {'is_active': 0},
      where: 'id = ?',
      whereArgs: [teamId],
    );
  }

  Future<void> updateTeamScore({
    required String teamId,
    required int newScore,
    String? description,
    Database? dbExecutor,
  }) async {
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
    final db = dbExecutor ?? await database;
    final maps = await db.query(
      'score_history',
      orderBy: 'timestamp DESC',
      limit: limit,
    );
    return maps.map((m) => ScoreHistory.fromMap(m)).toList();
  }

  Future<void> clearScoreHistory({Database? dbExecutor}) async {
    final db = dbExecutor ?? await database;
    await db.delete('score_history');
  }

  // ---------------- SETTINGS ----------------
  Future<void> saveSetting(String key, String value, {Database? dbExecutor}) async {
    final db = dbExecutor ?? await database;
    await db.insert(
      'settings',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<String?> getSetting(String key, {Database? dbExecutor}) async {
    final db = dbExecutor ?? await database;
    final res = await db.query('settings', where: 'key = ?', whereArgs: [key]);
    if (res.isNotEmpty) {
      return res.first['value'] as String?;
    }
    return null;
  }
}
