import 'package:flutter/material.dart';
import '../models/team.dart';
import '../utils/color_palette.dart';
import '../utils/rank_calculator.dart';
import '../animations/animated_score_counter.dart';
import '../animations/winner_glow.dart';
import 'score_edit_dialog.dart';

class TeamTile extends StatefulWidget {
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
  State<TeamTile> createState() => _TeamTileState();
}

class _TeamTileState extends State<TeamTile> {
  bool _isHovered = false;

  void _openEditDialog() {
    if (!widget.isInteractive) return;
    showDialog(
      context: context,
      builder: (ctx) => ScoreEditDialog(team: widget.team),
    );
  }

  @override
  Widget build(BuildContext context) {
    final teamColor = ColorPalette.getColor(widget.team.color);
    final contrastTextColor = ColorPalette.getContrastTextColor(teamColor);
    final isLeader = (widget.team.rank == 1) && (widget.team.score > 0);
    final rankDelta = RankCalculator.getRankMovement(widget.team);

    final tileContent = AnimatedScale(
      scale: _isHovered && widget.isInteractive ? 1.02 : 1.0,
      duration: const Duration(milliseconds: 150),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: widget.isInteractive ? _openEditDialog : null,
          onHover: (hover) => setState(() => _isHovered = hover),
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              gradient: ColorPalette.getCardGradient(teamColor),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: teamColor.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
              border: Border.all(
                color: isLeader ? const Color(0xFFFFD700) : Colors.white.withOpacity(0.2),
                width: isLeader ? 2.5 : 1.0,
              ),
            ),
            child: Row(
              children: [
                // Rank Badge & Movement Indicator
                Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                    border: isLeader
                        ? Border.all(color: const Color(0xFFFFD700), width: 2)
                        : null,
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      if (isLeader)
                        const Positioned(
                          top: 1,
                          child: Icon(Icons.workspace_premium, color: Color(0xFFFFD700), size: 14),
                        ),
                      Padding(
                        padding: EdgeInsets.only(top: isLeader ? 10 : 0),
                        child: Text(
                          widget.team.rank != null ? '#${widget.team.rank}' : '-',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isLeader ? const Color(0xFFFFD700) : contrastTextColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // Movement indicator icon (up/down/same)
                if (rankDelta != 0)
                  Tooltip(
                    message: rankDelta > 0
                        ? 'Gained $rankDelta position${rankDelta > 1 ? "s" : ""}'
                        : 'Lost ${-rankDelta} position${-rankDelta > 1 ? "s" : ""}',
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: (rankDelta > 0 ? Colors.green : Colors.red).withOpacity(0.85),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        rankDelta > 0 ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  )
                else
                  const SizedBox(width: 18),

                const SizedBox(width: 12),

                // Team Name
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
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: contrastTextColor,
                                letterSpacing: 0.5,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isLeader) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFD700),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'LEADER',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      Text(
                        'Team ${widget.team.color}',
                        style: TextStyle(
                          fontSize: 12,
                          color: contrastTextColor.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ),

                // Large Animated Score
                AnimatedScoreCounter(
                  score: widget.team.score,
                  duration: const Duration(milliseconds: 350),
                  textStyle: TextStyle(
                    fontSize: 36 * widget.scoreScale,
                    fontWeight: FontWeight.w900,
                    color: contrastTextColor,
                    fontFeatures: const [FontFeature.tabularFigures()],
                    shadows: [
                      Shadow(
                        color: Colors.black.withOpacity(0.4),
                        offset: const Offset(1, 1),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),

                if (widget.isInteractive) ...[
                  const SizedBox(width: 8),
                  Icon(
                    Icons.edit_note,
                    color: contrastTextColor.withOpacity(0.7),
                    size: 24,
                  ),
                ],
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
