import 'package:flutter/material.dart';

class RoomStatusChip extends StatelessWidget {
  const RoomStatusChip({
    required this.label,
    required this.color,
    super.key,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: CircleAvatar(backgroundColor: color, radius: 5),
      label: Text(label),
    );
  }
}
