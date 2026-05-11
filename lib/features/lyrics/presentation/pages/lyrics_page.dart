import 'package:flutter/material.dart';

import '../../../../app/theme/colors.dart';
import '../../../../shared/layouts/base_scaffold.dart';

/// Lyrics stub page.
/// Displays a placeholder skeleton while the real sync-lyrics feature
/// is pending backend integration.
class LyricsPage extends StatelessWidget {
  const LyricsPage({super.key, this.trackId, this.trackTitle});

  final String? trackId;
  final String? trackTitle;

  @override
  Widget build(BuildContext context) {
    return BaseScaffold(
      title: trackTitle ?? 'Letra',
      body: _LyricsBody(trackId: trackId),
    );
  }
}

class _LyricsBody extends StatefulWidget {
  const _LyricsBody({this.trackId});

  final String? trackId;

  @override
  State<_LyricsBody> createState() => _LyricsBodyState();
}

class _LyricsBodyState extends State<_LyricsBody> {
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    // Simulate a brief fetch attempt, then show stub content.
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) setState(() => _loading = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return _buildSkeleton(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 12),
          Icon(Icons.lyrics_rounded, size: 56, color: AppColors.primaryAccent),
          const SizedBox(height: 20),
          Text(
            'Letra não disponível',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'A integração de letras está em desenvolvimento.\n'
            'Em breve você poderá acompanhar a letra sincronizada aqui.',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          _StubLyricsPreview(),
        ],
      ),
    );
  }

  Widget _buildSkeleton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: List.generate(
          10,
          (i) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _SkeletonLine(
              width: i.isEven ? 220 : 160,
            ),
          ),
        ),
      ),
    );
  }
}

class _StubLyricsPreview extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const lines = [
      '♪ (Letra em breve)',
      '♪ ...',
      '♪ ...',
      '♪ ...',
    ];

    return Column(
      children: lines
          .map(
            (line) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                line,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.textSecondary,
                      fontStyle: FontStyle.italic,
                    ),
                textAlign: TextAlign.center,
              ),
            ),
          )
          .toList(),
    );
  }
}

class _SkeletonLine extends StatelessWidget {
  const _SkeletonLine({required this.width});

  final double width;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: width,
        height: 16,
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}
