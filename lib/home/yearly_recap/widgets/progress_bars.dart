import 'package:flutter/material.dart';

class ProgressBars extends StatelessWidget {
  final int storyCount;
  final int currentIndex;
  final double progress;

  const ProgressBars({
    super.key,
    required this.storyCount,
    required this.currentIndex,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
      child: Row(
        children: List.generate(
          storyCount,
          (index) => Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              child: _ProgressBar(value: _getProgressValue(index)),
            ),
          ),
        ),
      ),
    );
  }

  double _getProgressValue(int index) {
    if (index < currentIndex) {
      return 1.0;
    } else if (index == currentIndex) {
      return progress;
    } else {
      return 0.0;
    }
  }
}

class _ProgressBar extends StatelessWidget {
  final double value;

  const _ProgressBar({required this.value});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Background
        Container(
          height: 3,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        // Progress
        FractionallySizedBox(
          widthFactor: value,
          alignment: Alignment.centerLeft,
          child: Container(
            height: 3,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(2),
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.5),
                  blurRadius: 4,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
