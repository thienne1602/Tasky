import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../providers/auth_provider.dart';
import '../../theme/palette.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isObscure = true;
  bool _rememberMe = false;
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.2, 0.8, curve: Curves.easeOutCubic),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _controller.forward();
    _loadRememberMe();
  }

  Future<void> _loadRememberMe() async {
    final prefs = await SharedPreferences.getInstance();
    final savedEmail = prefs.getString('remembered_email');
    if (savedEmail != null) {
      setState(() {
        _emailController.text = savedEmail;
        _rememberMe = true;
      });
    }
  }

  Future<void> _saveRememberMe() async {
    final prefs = await SharedPreferences.getInstance();
    if (_rememberMe) {
      await prefs.setString('remembered_email', _emailController.text.trim());
    } else {
      await prefs.remove('remembered_email');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    await _saveRememberMe();
    final auth = context.read<AuthProvider>();
    try {
      await auth.login(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/home');
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(child: Text('Oops! ${error.toString()}')),
            ],
          ),
          backgroundColor: TaskyPalette.coral,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
                  ]
                : [
                    TaskyPalette.cream,
                    const Color(0xFFe8d5f2),
                  ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 440),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Logo
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: isDark
                                    ? [
                                        TaskyPalette.mint,
                                        TaskyPalette.aqua,
                                      ]
                                    : [
                                        TaskyPalette.lavender,
                                        TaskyPalette.mint,
                                      ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: (isDark
                                          ? TaskyPalette.mint
                                          : TaskyPalette.lavender)
                                      .withOpacity(0.4),
                                  blurRadius: 20,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Text('✨', style: TextStyle(fontSize: 48)),
                            ),
                          ),
                          const SizedBox(height: 32),
                          // Title
                          Text(
                            'Chào mừng trở lại! 👋',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color:
                                  isDark ? Colors.white : TaskyPalette.midnight,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Đăng nhập để tiếp tục',
                            style: TextStyle(
                              fontSize: 15,
                              color: isDark
                                  ? Colors.white.withOpacity(0.6)
                                  : TaskyPalette.midnight.withOpacity(0.5),
                            ),
                          ),
                          const SizedBox(height: 40),
                          // Form
                          Container(
                            padding: const EdgeInsets.all(28),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.white.withOpacity(0.05)
                                  : Colors.white.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: isDark
                                    ? Colors.white.withOpacity(0.1)
                                    : Colors.white,
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                children: [
                                  // Email/Username field
                                  TextFormField(
                                    controller: _emailController,
                                    style: TextStyle(
                                      color: isDark
                                          ? Colors.white
                                          : TaskyPalette.midnight,
                                    ),
                                    decoration: InputDecoration(
                                      labelText: 'Email hoặc tên đăng nhập',
                                      labelStyle: TextStyle(
                                        color: isDark
                                            ? Colors.white.withOpacity(0.6)
                                            : TaskyPalette.midnight
                                                .withOpacity(0.5),
                                      ),
                                      prefixIcon: Icon(
                                        Icons.person_outline_rounded,
                                        color: isDark
                                            ? TaskyPalette.mint
                                            : TaskyPalette.lavender,
                                      ),
                                      filled: true,
                                      fillColor: isDark
                                          ? Colors.white.withOpacity(0.05)
                                          : TaskyPalette.cream.withOpacity(0.5),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(16),
                                        borderSide: BorderSide.none,
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(16),
                                        borderSide: BorderSide(
                                          color: isDark
                                              ? TaskyPalette.mint
                                              : TaskyPalette.lavender,
                                          width: 2,
                                        ),
                                      ),
                                    ),
                                    validator: (value) => value != null &&
                                            value.isNotEmpty
                                        ? null
                                        : 'Vui lòng nhập email hoặc username',
                                  ),
                                  const SizedBox(height: 20),
                                  // Password field
                                  TextFormField(
                                    controller: _passwordController,
                                    obscureText: _isObscure,
                                    style: TextStyle(
                                      color: isDark
                                          ? Colors.white
                                          : TaskyPalette.midnight,
                                    ),
                                    decoration: InputDecoration(
                                      labelText: 'Mật khẩu',
                                      labelStyle: TextStyle(
                                        color: isDark
                                            ? Colors.white.withOpacity(0.6)
                                            : TaskyPalette.midnight
                                                .withOpacity(0.5),
                                      ),
                                      prefixIcon: Icon(
                                        Icons.lock_outline_rounded,
                                        color: isDark
                                            ? TaskyPalette.mint
                                            : TaskyPalette.lavender,
                                      ),
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          _isObscure
                                              ? Icons.visibility_off_rounded
                                              : Icons.visibility_rounded,
                                          color: isDark
                                              ? Colors.white.withOpacity(0.4)
                                              : TaskyPalette.midnight
                                                  .withOpacity(0.4),
                                        ),
                                        onPressed: () => setState(
                                            () => _isObscure = !_isObscure),
                                      ),
                                      filled: true,
                                      fillColor: isDark
                                          ? Colors.white.withOpacity(0.05)
                                          : TaskyPalette.cream.withOpacity(0.5),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(16),
                                        borderSide: BorderSide.none,
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(16),
                                        borderSide: BorderSide(
                                          color: isDark
                                              ? TaskyPalette.mint
                                              : TaskyPalette.lavender,
                                          width: 2,
                                        ),
                                      ),
                                    ),
                                    validator: (value) =>
                                        value != null && value.length >= 6
                                            ? null
                                            : 'Mật khẩu tối thiểu 6 ký tự',
                                  ),
                                  const SizedBox(height: 16),
                                  // Remember me checkbox
                                  Row(
                                    children: [
                                      SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: Checkbox(
                                          value: _rememberMe,
                                          onChanged: (value) {
                                            setState(() =>
                                                _rememberMe = value ?? false);
                                          },
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(6),
                                          ),
                                          activeColor: isDark
                                              ? TaskyPalette.mint
                                              : TaskyPalette.lavender,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Ghi nhớ đăng nhập',
                                        style: TextStyle(
                                          color: isDark
                                              ? Colors.white.withOpacity(0.7)
                                              : TaskyPalette.midnight
                                                  .withOpacity(0.7),
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 28),
                                  // Login button
                                  Container(
                                    width: double.infinity,
                                    height: 56,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: isDark
                                            ? [
                                                TaskyPalette.mint,
                                                TaskyPalette.aqua,
                                              ]
                                            : [
                                                TaskyPalette.lavender,
                                                TaskyPalette.mint,
                                              ],
                                      ),
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: [
                                        BoxShadow(
                                          color: (isDark
                                                  ? TaskyPalette.mint
                                                  : TaskyPalette.lavender)
                                              .withOpacity(0.4),
                                          blurRadius: 12,
                                          offset: const Offset(0, 6),
                                        ),
                                      ],
                                    ),
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        onTap: auth.isLoading ? null : _submit,
                                        borderRadius: BorderRadius.circular(16),
                                        child: Center(
                                          child: auth.isLoading
                                              ? const SizedBox(
                                                  width: 24,
                                                  height: 24,
                                                  child:
                                                      CircularProgressIndicator(
                                                    color: Colors.white,
                                                    strokeWidth: 3,
                                                  ),
                                                )
                                              : const Text(
                                                  'Đăng nhập 🚀',
                                                  style: TextStyle(
                                                    fontSize: 17,
                                                    fontWeight: FontWeight.w700,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          // Register link
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Chưa có tài khoản? ',
                                style: TextStyle(
                                  color: isDark
                                      ? Colors.white.withOpacity(0.6)
                                      : TaskyPalette.midnight.withOpacity(0.6),
                                ),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pushReplacementNamed(
                                    context, '/register'),
                                child: Text(
                                  'Đăng ký ngay 💫',
                                  style: TextStyle(
                                    color: isDark
                                        ? TaskyPalette.mint
                                        : TaskyPalette.lavender,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
