import 'package:flutter/material.dart';

class DeadlineUrgencyIcon extends StatelessWidget {
  const DeadlineUrgencyIcon({
    super.key,
    required this.deadline,
    this.size = 32,
  });

  final DateTime? deadline;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (deadline == null) return const SizedBox.shrink();

    final now = DateTime.now();
    final timeLeft = deadline!.difference(now);

    String emoji;
    String tooltip;
    Color color;

    if (timeLeft.isNegative) {
      emoji = '💀'; // Quá hạn
      tooltip = 'Đã quá hạn!';
      color = Colors.red;
    } else if (timeLeft.inHours < 24) {
      emoji = '🐕'; // Chó dữ - Còn ít hơn 1 ngày
      tooltip = 'Gấp lắm! Còn ${timeLeft.inHours}h';
      color = Colors.red.shade700;
    } else if (timeLeft.inDays < 3) {
      emoji = '🐰'; // Thỏ - Còn ít hơn 3 ngày
      tooltip = 'Hơi gấp! Còn ${timeLeft.inDays} ngày';
      color = Colors.orange;
    } else if (timeLeft.inDays < 7) {
      emoji = '🐢'; // Rùa - Còn ít hơn 1 tuần
      tooltip = 'Còn ${timeLeft.inDays} ngày';
      color = Colors.blue;
    } else {
      emoji = '🦥'; // Lười - Còn nhiều thời gian
      tooltip = 'Còn ${timeLeft.inDays} ngày, chill thôi';
      color = Colors.green;
    }

    return Tooltip(
      message: tooltip,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3), width: 1.5),
        ),
        child: Text(
          emoji,
          style: TextStyle(fontSize: size),
        ),
      ),
    );
  }
}
