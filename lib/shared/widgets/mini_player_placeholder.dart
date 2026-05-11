import 'package:flutter/material.dart';

import '../../app/theme/colors.dart';

class MiniPlayerPlaceholder extends StatelessWidget {
  const MiniPlayerPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Row(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.primaryAccent,
            child: Icon(Icons.music_note_rounded, color: AppColors.textPrimary),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Mini-player placeholder',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Icon(Icons.play_arrow_rounded),
        ],
      ),
    );
  }
}