import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/team.dart';
import '../providers/scoreboard_providers.dart';
import '../utils/color_palette.dart';
import '../utils/rank_calculator.dart';
import '../animations/animated_score_counter.dart';
import '../animations/winner_glow.dart';
import 'score_edit_dialog.dart';

class TeamTile extends ConsumerStatefulWidget {
  final Team team;
  final bool isInteractive;
  final double scoreScale;

  const TeamTile({
    super.key,
    required this.team,
    this.isInteractive = true,
    this.scoreScale = 1.0,
  });

  @override
  ConsumerState<TeamTile> createState() => _TeamTileState();
}

class _TeamTileState extends ConsumerState<TeamTile> {
  bool _isHovered = false;

  void _openEditDialog() {
    if (!widget.isInteractive) return;
    showDialog(
      context: context,
      builder: (ctx) => ScoreEditDialog(team: widget.team),
    );
  }

  void _quickAdjust(int delta) {
    if (!widget.isInteractive) return;
    try {
      ref.read(teamsProvider.notifier).adjustScore(
        teamId: widget.team.id,
        delta: delta,
        description: delta > 0 ? 'Quick +$delta' : 'Quick $delta',
      );
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final teamColor = ColorPalette.getColor(widget.team.color);
    final isLeader = (widget.team.rank == 1) && (widget.team.score > 0);
    final rankDelta = RankCalculator.getRankMovement(widget.team);

    final tileContent = AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
      decoration: BoxDecoration(
        color: _isHovered && widget.isInteractive
            ? const Color(0xFF1E293B)
            : const Color(0xFF141C2E),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isLeader
              ? const Color(0xFFFFD700).withOpacity(0.8)
              : _isHovered && widget.isInteractive
                  ? teamColor.withOpacity(0.5)
                  : const Color(0xFF243049),
          width: isLeader ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: widget.isInteractive ? _openEditDialog : null,
          onHover: (hover) => setState(() => _isHovered = hover),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                // Minimal vertical color accent bar
                Container(
                  width: 5,
                  height: 40,
                  decoration: BoxDecoration(
                    color: teamColor,
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: [
                      BoxShadow(
                        color: teamColor.withOpacity(0.6),
                        blurRadius: 6,
                        spreadRadius: 0.5,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),

                // Rank Badge
                Container(
                  width: 34,
                  height: 34,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isLeader
                        ? const Color(0xFFFFD700).withOpacity(0.18)
                        : const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isLeader
                          ? const Color(0xFFFFD700).withOpacity(0.5)
                          : const Color(0xFF334155),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    widget.team.rank != null ? '#${widget.team.rank}' : '-',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isLeader
                          ? const Color(0xFFFFD700)
                          : const Color(0xFF94A3B8),
                    ),
                  ),
                ),

                const SizedBox(width: 8),

                // Movement Indicator (up/down)
                if (rankDelta != 0)
                  Icon(
                    rankDelta > 0 ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                    color: rankDelta > 0 ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                    size: 20,
                  )
                else
                  const SizedBox(width: 12),

                // Team Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              widget.team.name,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 0.2,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isLeader) ...[
                            const SizedBox(width: 6),
                            const Icon(
                              Icons.emoji_events,
                              size: 15,
                              color: Color(0xFFFFD700),
                            ),
                          ],
                        ],
                      ),
                      Text(
                        'Team ${widget.team.color}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                ),

                // Quick Inline +/- Actions (interactive)
                if (widget.isInteractive) ...[
                  IconButton(
                    icon: const Icon(Icons.remove, size: 18),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0xFF1E293B),
                      foregroundColor: const Color(0xFFCBD5E1),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    tooltip: '-1 pt',
                    onPressed: () => _quickAdjust(-1),
                  ),
                  const SizedBox(width: 6),
                  IconButton(
                    icon: const Icon(Icons.add, size: 18),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0xFF1E293B),
                      foregroundColor: const Color(0xFFCBD5E1),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    tooltip: '+1 pt',
                    onPressed: () => _quickAdjust(1),
                  ),
                  const SizedBox(width: 10),
                ],

                // Score Display
                AnimatedScoreCounter(
                  score: widget.team.score,
                  duration: const Duration(milliseconds: 300),
                  textStyle: TextStyle(
                    fontSize: 32 * widget.scoreScale,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    return WinnerGlow(
      isLeading: isLeader,
      baseColor: teamColor,
      child: tileContent,
    );
  }
}
