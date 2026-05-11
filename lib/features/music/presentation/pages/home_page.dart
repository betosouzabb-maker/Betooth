import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/layouts/base_scaffold.dart';
import '../../../../shared/widgets/section_placeholder.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BaseScaffold(
      title: 'Home',
      actions: [
        IconButton(
          onPressed: () => context.push('/player'),
          icon: const Icon(Icons.open_in_full_rounded),
        ),
      ],
      body: const SectionPlaceholder(
        title: 'Descobertas da semana',
        subtitle: 'Estrutura inicial da home do Betooth.',
      ),
    );
  }
}