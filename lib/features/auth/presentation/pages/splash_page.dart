import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../app/theme/colors.dart';

class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
      )
          .animate()
          .fadeIn(duration: 700.ms)
          .then()
          .fadeOut(
            begin: 1,
            duration: 500.ms,
          ),
    );
  }
}