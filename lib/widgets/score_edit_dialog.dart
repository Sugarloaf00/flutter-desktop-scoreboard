import 'package:flutter/material.dart';
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

  Future<void> _confirmReset() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Reset ${widget.team.name}\'s Score?'),
        content: const Text('Are you sure you want to reset this team\'s score to 0?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Reset to 0'),
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

    ref.read(teamsProvider.notifier).updateScore(
      teamId: widget.team.id,
      newScore: _pendingScore,
      description: delta > 0 ? 'Added $delta pts' : 'Deducted ${-delta} pts',
    );

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final teamColor = ColorPalette.getColor(widget.team.color);

    return Dialog(
      backgroundColor: const Color(0xFF131B2E),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: Color(0xFF243049)),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(22.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: teamColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      widget.team.name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20, color: Color(0xFF94A3B8)),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Large Score Display
              Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFF0B101D),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF1E293B)),
                ),
                child: Column(
                  children: [
                    Text(
                      '$_pendingScore',
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Current: ${widget.team.score} pts',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),

              if (_errorMessage != null) ...[
                const SizedBox(height: 8),
                Text(
                  _errorMessage!,
                  style: const TextStyle(color: Color(0xFFEF4444), fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ],

              const SizedBox(height: 16),

              // Quick Action Buttons (-10, -5, -1, +1, +5, +10)
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: [
                  QuickScoreButton(delta: -10, onPressed: () => _applyDelta(-10)),
                  QuickScoreButton(delta: -5, onPressed: () => _applyDelta(-5)),
                  QuickScoreButton(delta: -1, onPressed: () => _applyDelta(-1)),
                  QuickScoreButton(delta: 1, onPressed: () => _applyDelta(1)),
                  QuickScoreButton(delta: 5, onPressed: () => _applyDelta(5)),
                  QuickScoreButton(delta: 10, onPressed: () => _applyDelta(10)),
                ],
              ),

              const SizedBox(height: 16),

              // Exact Score Field
              TextField(
                controller: _exactScoreController,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  labelText: 'Set Exact Score',
                  labelStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                  isDense: true,
                  filled: true,
                  fillColor: const Color(0xFF0F172A),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFF334155)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFF334155)),
                  ),
                ),
                onChanged: _onExactScoreChanged,
              ),

              const SizedBox(height: 20),

              // Actions Footer
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: _confirmReset,
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFFEF4444),
                    ),
                    child: const Text('Reset to 0'),
                  ),
                  Row(
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancel', style: TextStyle(color: Color(0xFF94A3B8))),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3B82F6),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                        ),
                        onPressed: _save,
                        child: const Text('Save Score', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
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
