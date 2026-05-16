import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/layouts/base_scaffold.dart';
import '../../../../shared/widgets/section_placeholder.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0D0F),
        title: const Text('Betooth', style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            onPressed: () => context.push('/player'),
            icon: const Icon(Icons.open_in_full_rounded, color: Colors.white),
          ),
        ],
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.headphones_rounded, color: Colors.white, size: 64),
            SizedBox(height: 16),
            Text(
              'Bem-vindo ao Betooth!',
              style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Seu app de música está pronto.',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}