import 'package:flutter/material.dart';
import '../theme/palette.dart';

class TaskProgressIndicator extends StatelessWidget {
  const TaskProgressIndicator({
    super.key,
    required this.status,
    this.showLabel = true,
  });

  final String status;
  final bool showLabel;

  @override
  Widget build(BuildContext context) {
    final (progress, color, icon, label) = _getProgressData();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showLabel) ...[
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            backgroundColor: color.withOpacity(0.15),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  (double, Color, IconData, String) _getProgressData() {
    switch (status) {
      case 'done':
        return (
          1.0,
          TaskyPalette.mint,
          Icons.check_circle_rounded,
          'Hoàn thành'
        );
      case 'doing':
        return (0.5, TaskyPalette.lavender, Icons.pending_rounded, 'Đang làm');
      case 'todo':
      default:
        return (
          0.0,
          TaskyPalette.coral,
          Icons.radio_button_unchecked_rounded,
          'Chưa làm'
        );
    }
  }
}
