import 'package:flutter/material.dart';

class NotificationItem extends StatefulWidget {
  const NotificationItem({
    Key? key,
    required this.itemId,
  }) : super(key: key);

  final String itemId;
  @override
  _NotificationItemState createState() => _NotificationItemState();
}

class _NotificationItemState extends State<NotificationItem> {
  @override
  Widget build(BuildContext context) {
    return Scaffold();
  }
}
