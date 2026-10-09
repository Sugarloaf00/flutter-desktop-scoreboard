import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/team.dart';
import '../providers/scoreboard_providers.dart';
import '../utils/color_palette.dart';
import 'quick_score_button.dart';

class ScoreEditDialog extends ConsumerStatefulWidget {
  final Team team;

  const ScoreEditDialog({super.key, required this.team});

  @override
  ConsumerState<ScoreEditDialog> createState() => _ScoreEditDialogState();
}

class _ScoreEditDialogState extends ConsumerState<ScoreEditDialog> {
  late int _pendingScore;
  final TextEditingController _exactScoreController = TextEditingController();
  final TextEditingController _customDeltaController = TextEditingController();
  final TextEditingController _reasonController = TextEditingController();
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _pendingScore = widget.team.score;
    _exactScoreController.text = _pendingScore.toString();
  }

  @override
  void dispose() {
    _exactScoreController.dispose();
    _customDeltaController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  void _applyDelta(int delta) {
    final allowNegative = ref.read(settingsProvider).allowNegativeScores;
    final next = _pendingScore + delta;
    if (!allowNegative && next < 0) {
      setState(() {
        _errorMessage = 'Negative scores are disabled in settings.';
      });
      return;
    }
    setState(() {
      _pendingScore = next;
      _exactScoreController.text = _pendingScore.toString();
      _errorMessage = null;
    });
  }

  void _onExactScoreChanged(String val) {
    if (val.isEmpty) return;
    final parsed = int.tryParse(val);
    if (parsed == null) {
      setState(() => _errorMessage = 'Please enter a valid whole number.');
      return;
    }
    final allowNegative = ref.read(settingsProvider).allowNegativeScores;
    if (!allowNegative && parsed < 0) {
      setState(() => _errorMessage = 'Negative scores are disabled in settings.');
      return;
    }
    setState(() {
      _pendingScore = parsed;
      _errorMessage = null;
    });
  }

  void _applyCustomDelta(bool isAdd) {
    final val = int.tryParse(_customDeltaController.text);
    if (val == null || val <= 0) {
      setState(() => _errorMessage = 'Enter a positive point amount.');
      return;
    }
    _applyDelta(isAdd ? val : -val);
    _customDeltaController.clear();
  }

  Future<void> _confirmReset() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Reset ${widget.team.name}\'s Score?'),
        content: const Text(
          'Are you sure you want to reset this team\'s score to 0? This action will be logged in history.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Yes, Reset to 0'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await ref.read(teamsProvider.notifier).resetScore(widget.team.id);
      Navigator.of(context).pop();
    }
  }

  void _save() {
    final delta = _pendingScore - widget.team.score;
    if (delta == 0) {
      Navigator.of(context).pop();
      return;
    }

    final reason = _reasonController.text.trim().isNotEmpty
        ? _reasonController.text.trim()
        : null;

    ref.read(teamsProvider.notifier).updateScore(
      teamId: widget.team.id,
      newScore: _pendingScore,
      description: reason,
    );

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final teamColor = ColorPalette.getColor(widget.team.color);
    final delta = _pendingScore - widget.team.score;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                children: [
                  CircleAvatar(backgroundColor: teamColor, radius: 14),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Edit Score — ${widget.team.name}',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const Divider(height: 24),

              // Current & Projected Score Display
              Container(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        Text('Original Score', style: Theme.of(context).textTheme.labelMedium),
                        const SizedBox(height: 4),
                        Text(
                          '${widget.team.score}',
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                color: Colors.grey.shade600,
                              ),
                        ),
                      ],
                    ),
                    const Icon(Icons.arrow_forward, size: 28, color: Colors.grey),
                    Column(
                      children: [
                        Text('New Score', style: Theme.of(context).textTheme.labelMedium),
                        const SizedBox(height: 4),
                        Text(
                          '$_pendingScore',
                          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: teamColor,
                              ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              if (delta != 0) ...[
                const SizedBox(height: 8),
                Center(
                  child: Chip(
                    label: Text(
                      delta > 0 ? '+$delta points' : '$delta points',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: delta > 0 ? Colors.green.shade700 : Colors.red.shade700,
                      ),
                    ),
                    backgroundColor: (delta > 0 ? Colors.green : Colors.red).withOpacity(0.12),
                  ),
                ),
              ],

              if (_errorMessage != null) ...[
                const SizedBox(height: 8),
                Text(
                  _errorMessage!,
                  style: TextStyle(color: Colors.red.shade700, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ],

              const SizedBox(height: 16),
              Text('Quick Adjustments', style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 8),

              // Positive quick buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  QuickScoreButton(delta: 1, onPressed: () => _applyDelta(1)),
                  QuickScoreButton(delta: 5, onPressed: () => _applyDelta(5)),
                  QuickScoreButton(delta: 10, onPressed: () => _applyDelta(10)),
                ],
              ),
              const SizedBox(height: 8),

              // Negative quick buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  QuickScoreButton(delta: -1, onPressed: () => _applyDelta(-1)),
                  QuickScoreButton(delta: -5, onPressed: () => _applyDelta(-5)),
                  QuickScoreButton(delta: -10, onPressed: () => _applyDelta(-10)),
                ],
              ),

              const SizedBox(height: 16),

              // Direct Numeric / Custom Delta Row
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _exactScoreController,
                      keyboardType: const TextInputType.numberWithOptions(signed: true),
                      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^-?[0-9]*'))],
                      decoration: const InputDecoration(
                        labelText: 'Exact Score',
                        border: OutlineInputBorder(),
                        isDense: true,
                        prefixIcon: Icon(Icons.edit, size: 20),
                      ),
                      onChanged: _onExactScoreChanged,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _customDeltaController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: InputDecoration(
                        labelText: 'Custom Points',
                        border: const OutlineInputBorder(),
                        isDense: true,
                        suffixIcon: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.add, color: Colors.green),
                              onPressed: () => _applyCustomDelta(true),
                              tooltip: 'Add Points',
                            ),
                            IconButton(
                              icon: const Icon(Icons.remove, color: Colors.red),
                              onPressed: () => _applyCustomDelta(false),
                              tooltip: 'Deduct Points',
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),
              TextField(
                controller: _reasonController,
                decoration: const InputDecoration(
                  labelText: 'Reason / Description (optional)',
                  border: OutlineInputBorder(),
                  isDense: true,
                  prefixIcon: Icon(Icons.note_alt_outlined, size: 20),
                ),
              ),

              const SizedBox(height: 20),

              // Actions
              Row(
                children: [
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red.shade700,
                      side: BorderSide(color: Colors.red.shade300),
                    ),
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('Reset to 0'),
                    onPressed: _confirmReset,
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: teamColor,
                      foregroundColor: ColorPalette.getContrastTextColor(teamColor),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    onPressed: _save,
                    child: const Text('Save Score', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
