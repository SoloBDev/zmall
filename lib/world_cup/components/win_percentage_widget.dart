import 'package:flutter/material.dart';

class WinPercentageWidget extends StatelessWidget {
  final String homeTeam;
  final String awayTeam;
  final int homeWinCount;
  final int drawCount;
  final int awayWinCount;
  final Color homeColor;
  final Color drawColor;
  final Color awayColor;
  final double padding;
  final bool showColor;
  final TextStyle? textStyle;

  const WinPercentageWidget({
    Key? key,
    required this.homeTeam,
    required this.awayTeam,
    required this.homeWinCount,
    required this.drawCount,
    required this.awayWinCount,
    this.homeColor = Colors.green,
    this.drawColor = Colors.grey,
    this.awayColor = Colors.blue,
    this.padding = 8.0,
    this.textStyle,
    this.showColor = true,
  }) : super(key: key);

  int _percentage(int count) {
    final total = homeWinCount + drawCount + awayWinCount;
    if (total == 0) return 0;
    return ((count / total) * 100).floor();
  }

  @override
  Widget build(BuildContext context) {
    final style = textStyle ??
        Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.black);

    return Column(
      children: [
        /// Top row with labels and percentages
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _teamColumn(homeTeam, _percentage(homeWinCount), homeColor, style),
            _teamColumn("Draw", _percentage(drawCount), drawColor, style),
            _teamColumn(awayTeam, _percentage(awayWinCount), awayColor, style),
          ],
        ),

        SizedBox(height: padding / 2),

        /// Winning percentage bar
        Row(
          children: [
            Expanded(
              flex: homeWinCount == 0 ? 1 : homeWinCount,
              child: _barSegment(homeColor, leftRadius: padding / 2),
            ),
            Expanded(
              flex: drawCount == 0 ? 1 : drawCount,
              child: _barSegment(drawColor),
            ),
            Expanded(
              flex: awayWinCount == 0 ? 1 : awayWinCount,
              child: _barSegment(awayColor, rightRadius: padding / 2),
            ),
          ],
        ),
      ],
    );
  }

  Widget _teamColumn(
      String label, int percentage, Color color, TextStyle? style) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: showColor ? color : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(label, style: const TextStyle(color: Colors.white)),
        ),
        SizedBox(height: padding / 4),
        Text("$percentage%", style: style, textAlign: TextAlign.center),
      ],
    );
  }

  Widget _barSegment(Color color,
      {double leftRadius = 0, double rightRadius = 0}) {
    return Container(
      height: padding * 1.2,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(leftRadius),
          bottomLeft: Radius.circular(leftRadius),
          topRight: Radius.circular(rightRadius),
          bottomRight: Radius.circular(rightRadius),
        ),
      ),
    );
  }
}
