import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/colors.dart';
import '../../../../shared/layouts/base_scaffold.dart';

/// Preset names available in the equalizer.
enum EqualizerPreset { flat, rock, pop, jazz, classical, bass, custom }

extension _PresetLabel on EqualizerPreset {
  String get label {
    switch (this) {
      case EqualizerPreset.flat:
        return 'Plano';
      case EqualizerPreset.rock:
        return 'Rock';
      case EqualizerPreset.pop:
        return 'Pop';
      case EqualizerPreset.jazz:
        return 'Jazz';
      case EqualizerPreset.classical:
        return 'Clássico';
      case EqualizerPreset.bass:
        return 'Graves';
      case EqualizerPreset.custom:
        return 'Personalizado';
    }
  }

  /// dB values for [60Hz, 250Hz, 1kHz, 4kHz, 16kHz].
  List<double> get gains {
    switch (this) {
      case EqualizerPreset.flat:
        return [0, 0, 0, 0, 0];
      case EqualizerPreset.rock:
        return [4, 2, -2, 2, 4];
      case EqualizerPreset.pop:
        return [-1, 2, 4, 2, -1];
      case EqualizerPreset.jazz:
        return [3, 0, 1, 2, 3];
      case EqualizerPreset.classical:
        return [5, 3, -2, 2, 4];
      case EqualizerPreset.bass:
        return [6, 5, 0, -1, -2];
      case EqualizerPreset.custom:
        return [0, 0, 0, 0, 0];
    }
  }
}

class _EqualizerState {
  const _EqualizerState({
    required this.bands,
    this.preset = EqualizerPreset.flat,
    this.enabled = true,
  });

  final List<double> bands; // 5 bands in dB
  final EqualizerPreset preset;
  final bool enabled;

  _EqualizerState copyWith({
    List<double>? bands,
    EqualizerPreset? preset,
    bool? enabled,
  }) {
    return _EqualizerState(
      bands: bands ?? this.bands,
      preset: preset ?? this.preset,
      enabled: enabled ?? this.enabled,
    );
  }
}

class _EqualizerNotifier extends StateNotifier<_EqualizerState> {
  _EqualizerNotifier()
      : super(
          _EqualizerState(bands: List<double>.from(EqualizerPreset.flat.gains)),
        );

  void setPreset(EqualizerPreset preset) {
    state = state.copyWith(
      preset: preset,
      bands: List<double>.from(preset.gains),
    );
  }

  void setBand(int index, double value) {
    final updated = List<double>.from(state.bands);
    updated[index] = value;
    state = state.copyWith(bands: updated, preset: EqualizerPreset.custom);
  }

  void toggleEnabled() {
    state = state.copyWith(enabled: !state.enabled);
  }

  void reset() {
    state = state.copyWith(
      bands: List<double>.from(EqualizerPreset.flat.gains),
      preset: EqualizerPreset.flat,
    );
  }
}

final _equalizerProvider =
    StateNotifierProvider<_EqualizerNotifier, _EqualizerState>(
  (_) => _EqualizerNotifier(),
);

const _bandLabels = ['60 Hz', '250 Hz', '1 kHz', '4 kHz', '16 kHz'];

class EqualizerPage extends ConsumerWidget {
  const EqualizerPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(_equalizerProvider);
    final notifier = ref.read(_equalizerProvider.notifier);

    return BaseScaffold(
      title: 'Equalizador',
      actions: [
        TextButton(
          onPressed: notifier.reset,
          child: const Text('Resetar',
              style: TextStyle(color: AppColors.primaryAccent)),
        ),
      ],
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Equalizador',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                Switch(
                  value: state.enabled,
                  activeThumbColor: AppColors.primaryAccent,
                  onChanged: (_) => notifier.toggleEnabled(),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: DropdownButtonFormField<EqualizerPreset>(
              initialValue: state.preset,
              decoration: InputDecoration(
                labelText: 'Preset',
                filled: true,
                fillColor: AppColors.card,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              dropdownColor: AppColors.card,
              items: EqualizerPreset.values.map((p) {
                return DropdownMenuItem(
                  value: p,
                  child: Text(p.label),
                );
              }).toList(),
              onChanged: state.enabled
                  ? (v) {
                      if (v != null) notifier.setPreset(v);
                    }
                  : null,
            ),
          ),
          Expanded(
            child: Opacity(
              opacity: state.enabled ? 1.0 : 0.4,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: List.generate(5, (i) {
                    return Expanded(
                      child: _BandSlider(
                        label: _bandLabels[i],
                        value: state.bands[i],
                        enabled: state.enabled,
                        onChanged: (v) => notifier.setBand(i, v),
                      ),
                    );
                  }),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded,
                      size: 18, color: AppColors.textSecondary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Funcionalidade de equalizador nativa está em desenvolvimento. '
                      'As configurações são salvas mas ainda não afetam o áudio.',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _BandSlider extends StatelessWidget {
  const _BandSlider({
    required this.label,
    required this.value,
    required this.onChanged,
    required this.enabled,
  });

  final String label;
  final double value;
  final ValueChanged<double> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: RotatedBox(
            quarterTurns: 3,
            child: Slider(
              value: value,
              min: -12,
              max: 12,
              divisions: 24,
              activeColor: AppColors.primaryAccent,
              inactiveColor: AppColors.card,
              onChanged: enabled ? onChanged : null,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${value >= 0 ? '+' : ''}${value.toStringAsFixed(0)} dB',
          style: Theme.of(context)
              .textTheme
              .labelSmall
              ?.copyWith(color: AppColors.primaryAccent),
        ),
        const SizedBox(height: 4),
        Text(label,
            style: Theme.of(context)
                .textTheme
                .labelSmall
                ?.copyWith(color: AppColors.textSecondary)),
      ],
    );
  }
}
