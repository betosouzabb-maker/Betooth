import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/colors.dart';
import '../controllers/subscription_controller.dart';

class DownloadQuotaIndicator extends ConsumerWidget {
  const DownloadQuotaIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quota = ref.watch(
      subscriptionControllerProvider.select((s) => s.downloadQuota),
    );

    if (quota == null) return const SizedBox.shrink();
    if (quota.isVip) return const SizedBox.shrink();

    final limit = quota.limit ?? 5;
    final used = quota.used.clamp(0, limit);
    final remaining = limit - used;
    final fraction = limit > 0 ? used / limit : 0.0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.download_rounded,
            size: 15,
            color: remaining == 0 ? Colors.redAccent : AppColors.textSecondary,
          ),
          const SizedBox(width: 6),
          Text(
            remaining == 0
                ? 'Limite atingido'
                : '$remaining download${remaining == 1 ? '' : 's'} restante${remaining == 1 ? '' : 's'}',
            style: TextStyle(
              color: remaining == 0 ? Colors.redAccent : AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 60,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: fraction.toDouble(),
                minHeight: 4,
                backgroundColor: AppColors.surface,
                valueColor: AlwaysStoppedAnimation<Color>(
                  remaining == 0 ? Colors.redAccent : AppColors.primaryAccent,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
