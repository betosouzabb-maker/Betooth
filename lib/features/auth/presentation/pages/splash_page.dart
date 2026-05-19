import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/colors.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _waitAndNavigate();
  }

  Future<void> _waitAndNavigate() async {
    // Show splash for 2 seconds
    await Future.delayed(const Duration(milliseconds: 2000));
    if (!mounted) return;

    if (_navigated || !mounted) return;
    _navigated = true;

    // Always go to login after splash
    context.go('/login');
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
