import 'package:flutter/material.dart';

class FunGifWidget extends StatelessWidget {
  const FunGifWidget({
    super.key,
    required this.gifPath,
    this.size = 80,
    this.fallbackEmoji = '✨',
    this.borderRadius = 20,
  });

  final String gifPath;
  final double size;
  final String fallbackEmoji;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Image.asset(
          gifPath,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(borderRadius),
                color: Theme.of(context).colorScheme.surface,
              ),
              child: Center(
                child: Text(
                  fallbackEmoji,
                  style: TextStyle(fontSize: size * 0.5),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
