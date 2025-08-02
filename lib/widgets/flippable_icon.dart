import 'package:flutter/material.dart';
import 'dart:math' as math;

import 'package:zmall/constants.dart';

class FlippableCircleIcon extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color frontColor;
  final Color backColor;
  final Color iconColor;
  final TextStyle? textStyle;
  final double radius;

  const FlippableCircleIcon({
    super.key,
    required this.icon,
    required this.label,
    this.frontColor = Colors.blue,
    this.backColor = Colors.white,
    this.iconColor = Colors.white,
    this.textStyle,
    this.radius = 40,
  });

  @override
  State<FlippableCircleIcon> createState() => _FlippableCircleIconState();
}

class _FlippableCircleIconState extends State<FlippableCircleIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _isFront = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(_controller);
  }

  void _flip() {
    if (_isFront) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
    _isFront = !_isFront;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _flip,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          final isFront = _animation.value < 0.5;
          final angle = _animation.value * math.pi;
          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()..rotateY(angle),
            child: isFront ? _buildFront() : _buildBack(icon: widget.icon),
          );
        },
      ),
    );
  }

  Widget _buildFront() {
    return CircleAvatar(
      radius: widget.radius,
      backgroundColor: widget.frontColor,
      child:
          Icon(widget.icon, color: widget.iconColor, size: widget.radius * 0.8),
    );
  }

  Widget _buildBack({required IconData icon}) {
    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.identity()..rotateY(math.pi),
      child: Container(
        padding: EdgeInsets.all(kDefaultPadding / 2),
        decoration: BoxDecoration(
            color: kWhiteColor,
            //  kSecondaryColor.withValues(alpha: 0.2),
            border: Border.all(color: kBlackColor.withValues(alpha: 0.1)
                // kSecondaryColor.withValues(alpha: 0.3),

                ),
            borderRadius: BorderRadius.circular(kDefaultPadding / 2)),
        child: Row(
          spacing: kDefaultPadding / 4,
          children: [
            Icon(
              icon,
              size: 15,
              color: kSecondaryColor,
            ),
            Text(
              widget.label,
              textAlign: TextAlign.center,
              style: widget.textStyle ??
                  TextStyle(color: Colors.black, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  // Widget _buildBack() {
  //   return CircleAvatar(
  //     radius: widget.radius,
  //     backgroundColor: widget.backColor,
  //     child: Text(
  //       widget.label,
  //       textAlign: TextAlign.center,
  //       style: widget.textStyle ??
  //           TextStyle(color: Colors.black, fontSize: 14
  //               // widget.radius * 0.3,
  //               ),
  //     ),
  //   );
  // }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
