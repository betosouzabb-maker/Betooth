import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/colors.dart';
import '../controllers/auth_controller.dart';

class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage> {
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _waitAndNavigate();
  }

  Future<void> _waitAndNavigate() async {
    // Show splash for at least 1.5s
    await Future.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;

    // Wait until auth is resolved (max 5s)
    for (int i = 0; i < 50; i++) {
      final status = ref.read(authControllerProvider).status;
      if (status != AuthStatus.initial) break;
      await Future.delayed(const Duration(milliseconds: 100));
      if (!mounted) return;
    }

    if (_navigated || !mounted) return;
    _navigated = true;

    final status = ref.read(authControllerProvider).status;
    if (status == AuthStatus.authenticated) {
      context.go('/home');
    } else {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: AppColors.primaryAccent,
                borderRadius: BorderRadius.circular(28),
              ),
              child: const Icon(
                Icons.headphones_rounded,
                color: AppColors.textPrimary,
                size: 48,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Betooth',
              style: Theme.of(context).textTheme.displaySmall,
            ),
          ],
        ),
      ).animate().fadeIn(duration: 700.ms),
    );
  }
}