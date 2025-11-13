import 'package:flutter/material.dart';
import '../theme/palette.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.3, 1.0, curve: Curves.easeOutCubic),
    ));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    const Color(0xFF1a1a2e),
                    const Color(0xFF16213e),
                    const Color(0xFF0f3460),
                  ]
                : [
                    TaskyPalette.cream,
                    const Color(0xFFe8d5f2),
                    const Color(0xFFb8e6f0),
                  ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              children: [
                SizedBox(height: screenHeight * 0.1),
                // Logo Animation
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Container(
                      width: 160,
                      height: 160,
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withOpacity(0.1)
                            : Colors.white.withOpacity(0.9),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: (isDark
                                    ? TaskyPalette.mint
                                    : TaskyPalette.lavender)
                                .withOpacity(0.3),
                            blurRadius: 40,
                            spreadRadius: 10,
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Text(
                          '✨',
                          style: TextStyle(fontSize: 80),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 48),
                // Title
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    children: [
                      Text(
                        'Tasky',
                        style: TextStyle(
                          fontSize: 56,
                          fontWeight: FontWeight.w800,
                          foreground: Paint()
                            ..shader = LinearGradient(
                              colors: isDark
                                  ? [
                                      Colors.white,
                                      TaskyPalette.mint,
                                    ]
                                  : [
                                      TaskyPalette.midnight,
                                      TaskyPalette.lavender,
                                    ],
                            ).createShader(
                              const Rect.fromLTWH(0, 0, 200, 70),
                            ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Quản lý công việc thông minh 🎯',
                        style: TextStyle(
                          fontSize: 16,
                          color: isDark
                              ? Colors.white.withOpacity(0.7)
                              : TaskyPalette.midnight.withOpacity(0.6),
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                // Features
                SlideTransition(
                  position: _slideAnimation,
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Column(
                      children: [
                        _FeatureItem(
                          icon: '📋',
                          title: 'Tổ chức task hiệu quả',
                          isDark: isDark,
                        ),
                        const SizedBox(height: 16),
                        _FeatureItem(
                          icon: '👥',
                          title: 'Làm việc nhóm dễ dàng',
                          isDark: isDark,
                        ),
                        const SizedBox(height: 16),
                        _FeatureItem(
                          icon: '🔔',
                          title: 'Thông báo thông minh',
                          isDark: isDark,
                        ),
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                // Buttons
                SlideTransition(
                  position: _slideAnimation,
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Column(
                      children: [
                        _GradientButton(
                          text: 'Bắt đầu ngay 🚀',
                          onPressed: () {
                            Navigator.pushReplacementNamed(
                                context, '/register');
                          },
                          isPrimary: true,
                          isDark: isDark,
                        ),
                        const SizedBox(height: 16),
                        _GradientButton(
                          text: 'Đã có tài khoản',
                          onPressed: () {
                            Navigator.pushReplacementNamed(context, '/login');
                          },
                          isPrimary: false,
                          isDark: isDark,
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FeatureItem extends StatelessWidget {
  const _FeatureItem({
    required this.icon,
    required this.title,
    required this.isDark,
  });

  final String icon;
  final String title;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.05)
            : Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.1)
              : TaskyPalette.mint.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : TaskyPalette.midnight,
            ),
          ),
        ],
      ),
    );
  }
}

class _GradientButton extends StatelessWidget {
  const _GradientButton({
    required this.text,
    required this.onPressed,
    required this.isPrimary,
    required this.isDark,
  });

  final String text;
  final VoidCallback onPressed;
  final bool isPrimary;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: isPrimary
            ? LinearGradient(
                colors: isDark
                    ? [
                        TaskyPalette.mint,
                        TaskyPalette.aqua,
                      ]
                    : [
                        TaskyPalette.lavender,
                        TaskyPalette.mint,
                      ],
              )
            : null,
        color: isPrimary ? null : Colors.transparent,
        borderRadius: BorderRadius.circular(28),
        border: isPrimary
            ? null
            : Border.all(
                color:
                    isDark ? Colors.white.withOpacity(0.3) : TaskyPalette.mint,
                width: 2,
              ),
        boxShadow: isPrimary
            ? [
                BoxShadow(
                  color: (isDark ? TaskyPalette.mint : TaskyPalette.lavender)
                      .withOpacity(0.4),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(28),
          child: Center(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: isPrimary
                    ? Colors.white
                    : (isDark ? Colors.white : TaskyPalette.midnight),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
