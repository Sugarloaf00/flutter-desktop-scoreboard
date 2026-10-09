import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/team.dart';
import '../models/field_model.dart';
import '../models/app_settings.dart';
import '../providers/scoreboard_providers.dart';
import '../utils/color_palette.dart';
import '../services/export_import_service.dart';
import 'history_screen.dart';

class AdminScreen extends ConsumerStatefulWidget {
  const AdminScreen({super.key});

  @override
  ConsumerState<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends ConsumerState<AdminScreen> {
  final TextEditingController _projectIdController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final settings = ref.read(settingsProvider);
    _projectIdController.text = settings.firebaseProjectId;
  }

  @override
  void dispose() {
    _projectIdController.dispose();
    super.dispose();
  }

  void _showAddEditTeamDialog([Team? existingTeam]) {
    final nameController = TextEditingController(text: existingTeam?.name ?? '');
    String selectedColor = existingTeam?.color ?? 'Red';
    String selectedField = existingTeam?.fieldId ?? 'field_a';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(existingTeam == null ? 'Add New Team' : 'Edit Team Details'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Team Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Team Color:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: ColorPalette.standardColors.keys.map((cName) {
                    final color = ColorPalette.getColor(cName);
                    final isSelected = selectedColor == cName;
                    return InkWell(
                      onTap: () => setDialogState(() => selectedColor = cName),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected ? Colors.white : Colors.transparent,
                            width: 2.5,
                          ),
                          boxShadow: isSelected
                              ? [BoxShadow(color: color.withOpacity(0.6), blurRadius: 6)]
                              : null,
                        ),
                        child: Text(
                          cName,
                          style: TextStyle(
                            color: ColorPalette.getContrastTextColor(color),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                const Text('Assigned Field:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ref.watch(fieldsProvider).maybeWhen(
                  data: (fields) => DropdownButtonFormField<String>(
                    value: selectedField,
                    decoration: const InputDecoration(border: OutlineInputBorder()),
                    items: fields
                        .map((f) => DropdownMenuItem(value: f.id, child: Text(f.name)))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setDialogState(() => selectedField = val);
                    },
                  ),
                  orElse: () => const SizedBox(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final name = nameController.text.trim();
                if (name.isEmpty) return;

                final now = DateTime.now();
                if (existingTeam == null) {
                  final newTeam = Team(
                    id: 'team_${now.millisecondsSinceEpoch}',
                    name: name,
                    color: selectedColor,
                    score: 0,
                    fieldId: selectedField,
                    createdAt: now,
                    updatedAt: now,
                    isActive: true,
                  );
                  ref.read(teamsProvider.notifier).addTeam(newTeam);
                } else {
                  final updatedTeam = existingTeam.copyWith(
                    name: name,
                    color: selectedColor,
                    fieldId: selectedField,
                    updatedAt: now,
                  );
                  ref.read(teamsProvider.notifier).updateTeam(updatedTeam);
                }
                Navigator.pop(ctx);
              },
              child: const Text('Save Team'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDeleteTeam(Team team) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete Team ${team.name}?'),
        content: const Text('Are you sure you want to remove this team from the scoreboard?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ref.read(teamsProvider.notifier).deleteTeam(team.id);
    }
  }

  Future<void> _confirmRestoreDefaultTeams() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Restore Default Teams?'),
        content: const Text(
          'This will restore the 6 default colored teams (Red, Blue, Green in Field A; Yellow, Orange, Purple in Field B).',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Restore Defaults'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ref.read(teamsProvider.notifier).restoreDefaultTeams();
    }
  }

  Future<void> _confirmResetAllScores() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('RESET ALL SCORES TO ZERO?'),
        content: const Text(
          'CRITICAL ACTION: This will reset the scores of ALL teams across Field A and Field B back to 0. This cannot be undone automatically, but will be saved in audit history.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade800,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('YES, RESET ALL SCORES'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      ref.read(teamsProvider.notifier).resetAllScores();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All scores have been reset to 0.')),
        );
      }
    }
  }

  void _showExportDialog() {
    final teamsAsync = ref.read(teamsProvider);
    final fieldsAsync = ref.read(fieldsProvider);
    final historyAsync = ref.read(historyProvider);

    final teams = teamsAsync.value ?? [];
    final fields = fieldsAsync.value ?? [];
    final history = historyAsync.value ?? [];

    final jsonStr = ExportImportService.exportToJson(fields, teams, history);
    final csvStr = ExportImportService.exportToCsv(teams, fields);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Export Scoreboard Data'),
        content: SizedBox(
          width: 500,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Select format to view/copy export contents:'),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.data_object, color: Colors.blue),
                title: const Text('JSON (Complete Backup)'),
                subtitle: const Text('Includes fields, teams, and score history'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => _showRawDataDialog('JSON Export', jsonStr),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.table_chart, color: Colors.green),
                title: const Text('CSV (Spreadsheet / Teams)'),
                subtitle: const Text('Compatible with Excel and Google Sheets'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => _showRawDataDialog('CSV Export', csvStr),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }

  void _showRawDataDialog(String title, String data) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: SizedBox(
          width: 500,
          height: 300,
          child: SelectableText(
            data,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }

  void _showImportDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Import Scoreboard Data'),
        content: SizedBox(
          width: 500,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Paste valid JSON or CSV export text below:'),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                maxLines: 8,
                decoration: const InputDecoration(
                  hintText: 'Paste JSON or CSV here...',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final text = controller.text.trim();
              if (text.isEmpty) return;
              try {
                if (text.startsWith('{')) {
                  final imported = ExportImportService.importFromJson(text);
                  for (final t in imported.teams) {
                    await ref.read(teamsProvider.notifier).addTeam(t);
                  }
                } else {
                  final teams = ExportImportService.importTeamsFromCsv(text);
                  for (final t in teams) {
                    await ref.read(teamsProvider.notifier).addTeam(t);
                  }
                }
                Navigator.pop(ctx);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Data imported successfully!')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Import error: $e')),
                  );
                }
              }
            },
            child: const Text('Import'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final teamsAsync = ref.watch(teamsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Administrator Controls'),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download),
            tooltip: 'Export Scoreboard',
            onPressed: _showExportDialog,
          ),
          IconButton(
            icon: const Icon(Icons.file_upload),
            tooltip: 'Import Scoreboard',
            onPressed: _showImportDialog,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Section: General Settings
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Preferences & Behavior', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    title: const Text('Automatic Leaderboard Sorting'),
                    subtitle: const Text('Always keep the highest-scoring teams at the top'),
                    value: settings.enableAutomaticSorting,
                    onChanged: (val) {
                      ref.read(settingsProvider.notifier).updateSettings(
                            settings.copyWith(enableAutomaticSorting: val),
                          );
                      ref.read(teamsProvider.notifier).build();
                    },
                  ),
                  SwitchListTile(
                    title: const Text('Allow Negative Scores'),
                    subtitle: const Text('Allow scores to drop below zero'),
                    value: settings.allowNegativeScores,
                    onChanged: (val) {
                      ref.read(settingsProvider.notifier).updateSettings(
                            settings.copyWith(allowNegativeScores: val),
                          );
                    },
                  ),
                  SwitchListTile(
                    title: const Text('Enable Animations'),
                    subtitle: const Text('Smooth number rolling and celebratory particle effects'),
                    value: settings.enableAnimations,
                    onChanged: (val) {
                      ref.read(settingsProvider.notifier).updateSettings(
                            settings.copyWith(enableAnimations: val),
                          );
                    },
                  ),
                  SwitchListTile(
                    title: const Text('Sound Feedback'),
                    subtitle: const Text('Play audio cues on point changes and leader transitions'),
                    value: settings.enableSound,
                    onChanged: (val) {
                      ref.read(settingsProvider.notifier).updateSettings(
                            settings.copyWith(enableSound: val),
                          );
                    },
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Section: Cloud Synchronization (Firestore)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.cloud_sync, color: Colors.blue),
                      const SizedBox(width: 8),
                      Text('Cloud Synchronization (Firestore)', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text('Synchronize live score updates to Firestore cloud in real time.'),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    title: const Text('Enable Firestore Cloud Sync'),
                    subtitle: const Text('Offline-first: changes save locally in SQLite and push to Firestore'),
                    value: settings.firestoreSyncEnabled,
                    onChanged: (val) {
                      ref.read(settingsProvider.notifier).updateSettings(
                            settings.copyWith(firestoreSyncEnabled: val),
                          );
                    },
                  ),
                  if (settings.firestoreSyncEnabled) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _projectIdController,
                            decoration: const InputDecoration(
                              labelText: 'Firebase Project ID',
                              hintText: 'e.g. scoreboard-live-1234',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () {
                            ref.read(settingsProvider.notifier).updateSettings(
                                  settings.copyWith(
                                    firebaseProjectId: _projectIdController.text.trim(),
                                  ),
                                );
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Firebase project ID updated!')),
                            );
                          },
                          child: const Text('Save ID'),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Section: Teams Management
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Participating Teams', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      Row(
                        children: [
                          OutlinedButton.icon(
                            icon: const Icon(Icons.restore, size: 16),
                            label: const Text('Restore Defaults'),
                            onPressed: _confirmRestoreDefaultTeams,
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.add),
                            label: const Text('Add Team'),
                            onPressed: () => _showAddEditTeamDialog(),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  teamsAsync.when(
                    loading: () => const CircularProgressIndicator(),
                    error: (err, _) => Text('Error: $err'),
                    data: (teams) {
                      return ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: teams.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final team = teams[index];
                          final color = ColorPalette.getColor(team.color);

                          return ListTile(
                            leading: CircleAvatar(backgroundColor: color, radius: 12),
                            title: Text(team.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('Field: ${team.fieldId} • Color: ${team.color} • Score: ${team.score}'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit, size: 20),
                                  tooltip: 'Edit Team',
                                  onPressed: () => _showAddEditTeamDialog(team),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                                  tooltip: 'Delete Team',
                                  onPressed: () => _confirmDeleteTeam(team),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Section: Danger Zone
          Card(
            color: Colors.red.withOpacity(0.06),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.red.shade300),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: Colors.red.shade700),
                      const SizedBox(width: 8),
                      Text(
                        'Danger Zone',
                        style: TextStyle(
                          color: Colors.red.shade700,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text('These actions perform tournament-wide resets.'),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade800,
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reset All Scores to 0'),
                    onPressed: _confirmResetAllScores,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
