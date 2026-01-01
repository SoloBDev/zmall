import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';

class RecapConfettiWidget extends StatefulWidget {
  const RecapConfettiWidget({super.key});

  @override
  State<RecapConfettiWidget> createState() => _RecapConfettiWidgetState();
}

class _RecapConfettiWidgetState extends State<RecapConfettiWidget> {
  late ConfettiController _confettiControllerLeft;
  late ConfettiController _confettiControllerRight;

  @override
  void initState() {
    super.initState();
    // Use Duration.zero to make confetti run indefinitely
    _confettiControllerLeft = ConfettiController();
    _confettiControllerRight = ConfettiController();

    // Start confetti immediately
    _confettiControllerLeft.play();
    _confettiControllerRight.play();
  }

  @override
  void dispose() {
    _confettiControllerLeft.dispose();
    _confettiControllerRight.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Left confetti
        Align(
          alignment: Alignment.topLeft,
          child: ConfettiWidget(
            confettiController: _confettiControllerLeft,
            blastDirection: -3.14 / 4, // DOWN-RIGHT
            emissionFrequency: 0.05,
            numberOfParticles: 10,
            maxBlastForce: 20,
            minBlastForce: 5,
            gravity: 0.2,
            colors: const [
              Colors.red,
              Colors.blue,
              Colors.green,
              Colors.yellow,
              Colors.pink,
              Colors.orange,
              Colors.purple,
              Colors.cyan,
            ],
          ),
        ),
        // Right confetti
        Align(
          alignment: Alignment.topRight,
          child: ConfettiWidget(
            confettiController: _confettiControllerRight,
            blastDirection: -3 * 3.14 / 4, // DOWN-LEFT
            emissionFrequency: 0.02,
            numberOfParticles: 10,
            maxBlastForce: 20,
            minBlastForce: 5,
            gravity: 0.2,
            colors: const [
              Colors.red,
              Colors.blue,
              Colors.green,
              Colors.yellow,
              Colors.pink,
              Colors.orange,
              Colors.purple,
              Colors.cyan,
            ],
          ),
        ),
      ],
    );
  }
}
