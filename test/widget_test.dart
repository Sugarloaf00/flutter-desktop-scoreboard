import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_scoreboard_app/models/team.dart';
import 'package:flutter_scoreboard_app/models/field_model.dart';
import 'package:flutter_scoreboard_app/widgets/team_tile.dart';
import 'package:flutter_scoreboard_app/widgets/field_column.dart';
import 'package:flutter_scoreboard_app/widgets/quick_score_button.dart';
import 'package:flutter_scoreboard_app/widgets/overall_leaderboard.dart';

void main() {
  testWidgets('TeamTile renders team name, rank, color, and score correctly', (WidgetTester tester) async {
    final now = DateTime.now();
    final team = Team(
      id: 'test_team',
      name: 'Red Fire',
      color: 'Red',
      score: 42,
      fieldId: 'field_a',
      createdAt: now,
      updatedAt: now,
      rank: 1,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TeamTile(team: team),
        ),
      ),
    );

    expect(find.text('Red Fire'), findsOneWidget);
    expect(find.text('Team Red'), findsOneWidget);
    expect(find.text('42'), findsOneWidget);
    expect(find.text('#1'), findsOneWidget);
  });

  testWidgets('QuickScoreButton triggers callback on tap', (WidgetTester tester) async {
    int tappedDelta = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: QuickScoreButton(
            delta: 5,
            onPressed: () {
              tappedDelta = 5;
            },
          ),
        ),
      ),
    );

    expect(find.text('+5'), findsOneWidget);
    await tester.tap(find.text('+5'));
    expect(tappedDelta, 5);
  });

  testWidgets('FieldColumn renders field heading and team list', (WidgetTester tester) async {
    final now = DateTime.now();
    const field = FieldModel(id: 'field_a', name: 'Court Alpha');
    final teams = [
      Team(id: 't1', name: 'Blue Sky', color: 'Blue', score: 20, fieldId: 'field_a', createdAt: now, updatedAt: now),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FieldColumn(
            field: field,
            teams: teams,
          ),
        ),
      ),
    );

    expect(find.text('COURT ALPHA'), findsOneWidget);
    expect(find.text('Blue Sky'), findsOneWidget);
    expect(find.text('1 teams'), findsOneWidget);
  });

  testWidgets('OverallLeaderboard displays champion banner for top team', (WidgetTester tester) async {
    final now = DateTime.now();
    const field = FieldModel(id: 'field_a', name: 'Field A');
    final teams = [
      Team(id: 't1', name: 'Red Champion', color: 'Red', score: 99, fieldId: 'field_a', createdAt: now, updatedAt: now),
      Team(id: 't2', name: 'Blue Challenger', color: 'Blue', score: 50, fieldId: 'field_a', createdAt: now, updatedAt: now),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: OverallLeaderboard(
            teams: teams,
            fields: const [field],
          ),
        ),
      ),
    );

    expect(find.text('OVERALL TOURNAMENT LEADER'), findsOneWidget);
    expect(find.text('Red Champion'), findsAtLeastNWidgets(1));
    expect(find.text('Total Score: 99 points'), findsOneWidget);
  });
}
