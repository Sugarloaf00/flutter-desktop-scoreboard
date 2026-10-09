import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/team.dart';
import '../models/field_model.dart';

class FirestoreService {
  final String projectId;
  final http.Client _client;

  FirestoreService({required this.projectId, http.Client? client})
      : _client = client ?? http.Client();

  String get _baseUrl =>
      'https://firestore.googleapis.com/v1/projects/$projectId/databases/(default)/documents';

  /// Syncs a team update to Firestore
  Future<bool> syncTeam(Team team) async {
    if (projectId.isEmpty) return false;
    try {
      final url = Uri.parse('$_baseUrl/teams/${team.id}');
      final body = jsonEncode({
        'fields': {
          'name': {'stringValue': team.name},
          'color': {'stringValue': team.color},
          'score': {'integerValue': team.score.toString()},
          'fieldId': {'stringValue': team.fieldId},
          'updatedAt': {'stringValue': team.updatedAt.toIso8601String()},
          'isActive': {'booleanValue': team.isActive},
        }
      });

      final response = await _client.patch(
        url,
        headers: {'Content-Type': 'application/json'},
        body: body,
      ).timeout(const Duration(seconds: 4));

      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Syncs field names to Firestore
  Future<bool> syncField(FieldModel field) async {
    if (projectId.isEmpty) return false;
    try {
      final url = Uri.parse('$_baseUrl/fields/${field.id}');
      final body = jsonEncode({
        'fields': {
          'name': {'stringValue': field.name},
          'displayOrder': {'integerValue': field.displayOrder.toString()},
        }
      });

      final response = await _client.patch(
        url,
        headers: {'Content-Type': 'application/json'},
        body: body,
      ).timeout(const Duration(seconds: 4));

      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Pushes score history record to Firestore
  Future<bool> recordScoreHistory({
    required String teamId,
    required int previousScore,
    required int newScore,
    required int pointsChanged,
    String? description,
  }) async {
    if (projectId.isEmpty) return false;
    try {
      final historyId = 'hist_${DateTime.now().microsecondsSinceEpoch}';
      final url = Uri.parse('$_baseUrl/score_history/$historyId');
      final body = jsonEncode({
        'fields': {
          'teamId': {'stringValue': teamId},
          'previousScore': {'integerValue': previousScore.toString()},
          'newScore': {'integerValue': newScore.toString()},
          'pointsChanged': {'integerValue': pointsChanged.toString()},
          'timestamp': {'stringValue': DateTime.now().toIso8601String()},
          'description': {'stringValue': description ?? ''},
        }
      });

      final response = await _client.patch(
        url,
        headers: {'Content-Type': 'application/json'},
        body: body,
      ).timeout(const Duration(seconds: 4));

      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
