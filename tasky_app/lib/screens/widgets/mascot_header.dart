import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/palette.dart';

class MascotHeader extends StatelessWidget {
  const MascotHeader({super.key, required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 72,
          width: 72,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: const LinearGradient(
              colors: [TaskyPalette.mint, TaskyPalette.lavender],
            ),
            boxShadow: [
              BoxShadow(
                color: TaskyPalette.lavender.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: const Center(
            child: Text('🫧', style: TextStyle(fontSize: 32)),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: TaskyPalette.midnight,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  color: TaskyPalette.midnight.withOpacity(0.65),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
