import 'dart:convert';
import '../models/team.dart';
import '../models/field_model.dart';
import '../models/score_history.dart';

class ExportData {
  final List<FieldModel> fields;
  final List<Team> teams;
  final List<ScoreHistory> history;
  final String exportedAt;

  ExportData({
    required this.fields,
    required this.teams,
    required this.history,
    required this.exportedAt,
  });

  Map<String, dynamic> toJson() => {
        'version': 1,
        'exported_at': exportedAt,
        'fields': fields.map((f) => f.toMap()).toList(),
        'teams': teams.map((t) => t.toMap()).toList(),
        'history': history.map((h) => h.toMap()).toList(),
      };

  factory ExportData.fromJson(Map<String, dynamic> json) {
    final fields = (json['fields'] as List? ?? [])
        .map((f) => FieldModel.fromMap(Map<String, dynamic>.from(f)))
        .toList();

    final teams = (json['teams'] as List? ?? [])
        .map((t) => Team.fromMap(Map<String, dynamic>.from(t)))
        .toList();

    final history = (json['history'] as List? ?? [])
        .map((h) => ScoreHistory.fromMap(Map<String, dynamic>.from(h)))
        .toList();

    return ExportData(
      fields: fields,
      teams: teams,
      history: history,
      exportedAt: json['exported_at'] as String? ?? DateTime.now().toIso8601String(),
    );
  }
}

class ExportImportService {
  /// Export to JSON String
  static String exportToJson(List<FieldModel> fields, List<Team> teams, List<ScoreHistory> history) {
    final data = ExportData(
      fields: fields,
      teams: teams,
      history: history,
      exportedAt: DateTime.now().toIso8601String(),
    );
    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(data.toJson());
  }

  /// Import from JSON String
  static ExportData importFromJson(String jsonString) {
    final Map<String, dynamic> decoded = jsonDecode(jsonString);
    if (!decoded.containsKey('teams')) {
      throw const FormatException('Invalid scoreboard export format: missing "teams" property');
    }
    return ExportData.fromJson(decoded);
  }

  /// Export Teams to CSV
  static String exportToCsv(List<Team> teams, List<FieldModel> fields) {
    final fieldNameMap = {for (var f in fields) f.id: f.name};
    final buffer = StringBuffer();

    // CSV Header
    buffer.writeln('Team ID,Team Name,Color,Score,Field ID,Field Name,Is Active,Updated At');

    for (final t in teams) {
      final id = _escapeCsv(t.id);
      final name = _escapeCsv(t.name);
      final color = _escapeCsv(t.color);
      final score = t.score;
      final fieldId = _escapeCsv(t.fieldId);
      final fieldName = _escapeCsv(fieldNameMap[t.fieldId] ?? t.fieldId);
      final isActive = t.isActive ? 'Yes' : 'No';
      final updatedAt = _escapeCsv(t.updatedAt.toIso8601String());

      buffer.writeln('$id,$name,$color,$score,$fieldId,$fieldName,$isActive,$updatedAt');
    }

    return buffer.toString();
  }

  static String _escapeCsv(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }

  /// Import Teams from CSV
  static List<Team> importTeamsFromCsv(String csvString) {
    final lines = csvString.split(RegExp(r'\r?\n'));
    if (lines.length < 2) {
      throw const FormatException('CSV is empty or missing data rows');
    }

    final teams = <Team>[];
    final now = DateTime.now();

    for (int i = 1; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;

      final parts = _parseCsvLine(line);
      if (parts.length < 5) continue;

      final id = parts[0].trim();
      final name = parts[1].trim();
      final color = parts[2].trim();
      final score = int.tryParse(parts[3].trim()) ?? 0;
      final fieldId = parts[4].trim();

      if (id.isEmpty || name.isEmpty) continue;

      teams.add(Team(
        id: id,
        name: name,
        color: color.isEmpty ? 'Blue' : color,
        score: score,
        fieldId: fieldId.isEmpty ? 'field_a' : fieldId,
        createdAt: now,
        updatedAt: now,
        isActive: true,
      ));
    }

    return teams;
  }

  static List<String> _parseCsvLine(String line) {
    final result = <String>[];
    final buffer = StringBuffer();
    bool inQuotes = false;

    for (int i = 0; i < line.length; i++) {
      final char = line[i];
      if (char == '"') {
        if (inQuotes && i + 1 < line.length && line[i + 1] == '"') {
          buffer.write('"');
          i++;
        } else {
          inQuotes = !inQuotes;
        }
      } else if (char == ',' && !inQuotes) {
        result.add(buffer.toString());
        buffer.clear();
      } else {
        buffer.write(char);
      }
    }
    result.add(buffer.toString());
    return result;
  }
}
