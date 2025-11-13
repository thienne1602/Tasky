import 'package:flutter/material.dart';
import '../theme/palette.dart';

class FunNotification {
  static void show(
    BuildContext context, {
    required String emoji,
    required String title,
    required String message,
    Color? color,
    Duration duration = const Duration(seconds: 2),
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: (color ?? TaskyPalette.mint).withOpacity(0.3),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 800),
                curve: Curves.elasticOut,
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: value,
                    child: Transform.rotate(
                      angle: (1 - value) * 0.5,
                      child: Text(emoji, style: const TextStyle(fontSize: 80)),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: TaskyPalette.midnight.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    Future.delayed(duration, () {
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }
    });
  }

  static void success(
    BuildContext context, {
    required String title,
    required String message,
  }) {
    show(
      context,
      emoji: '🎉',
      title: title,
      message: message,
      color: TaskyPalette.mint,
    );
  }

  static void error(
    BuildContext context, {
    required String title,
    required String message,
  }) {
    show(
      context,
      emoji: '😢',
      title: title,
      message: message,
      color: TaskyPalette.coral,
    );
  }

  static void warning(
    BuildContext context, {
    required String title,
    required String message,
  }) {
    show(
      context,
      emoji: '⚠️',
      title: title,
      message: message,
      color: Colors.orange,
    );
  }

  static void info(
    BuildContext context, {
    required String title,
    required String message,
  }) {
    show(
      context,
      emoji: '💡',
      title: title,
      message: message,
      color: TaskyPalette.lavender,
    );
  }

  static void taskComplete(BuildContext context) {
    final messages = [
      ('Bạn giỏi quá! 🌟', '✨'),
      ('Xuất sắc lắm! 💫', '🎯'),
      ('Tuyệt vời! 🎊', '🎉'),
      ('Làm được rồi! 🚀', '💪'),
      ('Quá đỉnh! �', '👏'),
      ('Cực kỳ tuyệt! 🌈', '🦄'),
      ('Amazing! 🎪', '🎨'),
    ];
    final randomMessage = (messages..shuffle()).first;

    show(
      context,
      emoji: randomMessage.$2,
      title: 'Hoàn thành task! 🌸',
      message: randomMessage.$1,
      color: TaskyPalette.mint,
    );
  }

  static void taskDeleted(BuildContext context) {
    show(
      context,
      emoji: '🗑️',
      title: 'Đã xóa task',
      message: 'Tạm biệt task này nhé! 👋',
      color: TaskyPalette.coral,
      duration: const Duration(milliseconds: 1500),
    );
  }

  static void memberAdded(BuildContext context, String memberName) {
    show(
      context,
      emoji: '🎊',
      title: 'Thêm thành viên!',
      message: 'Chào mừng $memberName vào team! 🤗',
      color: TaskyPalette.lavender,
    );
  }

  static void teamCreated(BuildContext context) {
    show(
      context,
      emoji: '🎉',
      title: 'Team mới sẵn sàng chinh phục! 🚀',
      message: 'Cùng nhau làm nên điều kỳ diệu nào 💫',
      color: TaskyPalette.mint,
    );
  }

  static void taskCreated(BuildContext context) {
    show(
      context,
      emoji: '🪄',
      title: 'Task mới đã xuất hiện!',
      message: 'Chuẩn bị "húc" nào! 💪',
      color: TaskyPalette.lavender,
      duration: const Duration(milliseconds: 1500),
    );
  }

  static void taskUpdated(BuildContext context) {
    show(
      context,
      emoji: '✏️',
      title: 'Cập nhật thành công!',
      message: 'Task đã được làm mới nè ✨',
      color: TaskyPalette.mint,
      duration: const Duration(milliseconds: 1500),
    );
  }

  static void commentAdded(BuildContext context) {
    show(
      context,
      emoji: '�',
      title: 'Comment đã gửi!',
      message: 'Ý kiến của bạn rất quan trọng 🌟',
      color: TaskyPalette.aqua,
      duration: const Duration(milliseconds: 1200),
    );
  }
}
