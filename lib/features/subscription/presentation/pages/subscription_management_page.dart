import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../app/theme/colors.dart';
import '../../domain/entities/subscription_entity.dart';
import '../controllers/subscription_controller.dart';
import '../widgets/coupon_redeem_dialog.dart';

class SubscriptionManagementPage extends ConsumerWidget {
  const SubscriptionManagementPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(subscriptionControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Assinatura',
          style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.textSecondary),
            onPressed: () => ref.read(subscriptionControllerProvider.notifier).refresh(),
          ),
        ],
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryAccent))
          : RefreshIndicator(
              color: AppColors.primaryAccent,
              backgroundColor: AppColors.surface,
              onRefresh: () => ref.read(subscriptionControllerProvider.notifier).refresh(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (state.successMessage != null) ...[
                      _FeedbackBanner(
                        message: state.successMessage!,
                        isError: false,
                        onDismiss: () => ref
                            .read(subscriptionControllerProvider.notifier)
                            .clearMessages(),
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (state.errorMessage != null) ...[
                      _FeedbackBanner(
                        message: state.errorMessage!,
                        isError: true,
                        onDismiss: () => ref
                            .read(subscriptionControllerProvider.notifier)
                            .clearMessages(),
                      ),
                      const SizedBox(height: 16),
                    ],
                    _StatusCard(state: state),
                    const SizedBox(height: 20),
                    if (state.downloadQuota != null)
                      _QuotaCard(quota: state.downloadQuota!),
                    if (!state.isVip) ...[
                      const SizedBox(height: 20),
                      _UpgradeCard(onTap: () => context.push('/vip')),
                    ],
                    const SizedBox(height: 20),
                    _CouponCard(
                      onRedeem: () => showCouponRedeemDialog(context),
                    ),
                    if (state.isVip &&
                        state.subscription != null &&
                        state.subscription!.status != SubscriptionStatus.cancelled) ...[
                      const SizedBox(height: 20),
                      _CancelCard(
                        onCancel: () => _confirmCancel(context, ref),
                      ),
                    ],
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }

  Future<void> _confirmCancel(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Cancelar assinatura?',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: const Text(
          'Seu acesso VIP permanece ativo até o fim do período atual. Após isso, os limites gratuitos serão aplicados.',
          style: TextStyle(color: AppColors.textSecondary, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => ctx.pop(false),
            child: const Text('Manter VIP', style: TextStyle(color: AppColors.primaryAccent)),
          ),
          TextButton(
            onPressed: () => ctx.pop(true),
            child: const Text('Cancelar', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(subscriptionControllerProvider.notifier).cancelSubscription();
    }
  }
}

// ---------------------------------------------------------------------------
// Sub-widgets
// ---------------------------------------------------------------------------

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.state});

  final SubscriptionControllerState state;

  @override
  Widget build(BuildContext context) {
    final sub = state.subscription;
    final isVip = state.isVip;
    final df = DateFormat('dd/MM/yyyy');

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: isVip
            ? LinearGradient(
                colors: [
                  AppColors.primaryAccent.withValues(alpha: 0.15),
                  AppColors.secondaryAccent.withValues(alpha: 0.08),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: isVip ? null : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isVip
              ? AppColors.primaryAccent.withValues(alpha: 0.4)
              : AppColors.card,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: isVip
                  ? const LinearGradient(
                      colors: [AppColors.primaryAccent, AppColors.secondaryAccent],
                    )
                  : null,
              color: isVip ? null : AppColors.card,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              isVip ? Icons.workspace_premium_rounded : Icons.lock_outline_rounded,
              color: isVip ? Colors.white : AppColors.textSecondary,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isVip ? 'Betooth VIP Ativo' : 'Plano Gratuito',
                  style: TextStyle(
                    color: isVip ? AppColors.textPrimary : AppColors.textSecondary,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                if (sub != null && isVip) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Renova em ${df.format(sub.currentPeriodEnd)}',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
                if (sub != null && sub.status == SubscriptionStatus.cancelled) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Cancelada — acesso até ${df.format(sub.currentPeriodEnd)}',
                    style: const TextStyle(color: Colors.orangeAccent, fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuotaCard extends StatelessWidget {
  const _QuotaCard({required this.quota});

  final DownloadQuotaEntity quota;

  @override
  Widget build(BuildContext context) {
    if (quota.isVip) return const SizedBox.shrink();

    final limit = quota.limit ?? 5;
    final used = quota.used.clamp(0, limit);
    final remaining = limit - used;
    final fraction = limit > 0 ? used / limit : 0.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.download_rounded, color: AppColors.textSecondary, size: 18),
              SizedBox(width: 8),
              Text(
                'Downloads este mês',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: fraction.toDouble(),
              minHeight: 6,
              backgroundColor: AppColors.card,
              valueColor: AlwaysStoppedAnimation<Color>(
                remaining == 0 ? Colors.redAccent : AppColors.primaryAccent,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            remaining == 0
                ? 'Limite atingido — assine o VIP para downloads ilimitados'
                : '$used de $limit downloads usados ($remaining restante${remaining == 1 ? '' : 's'})',
            style: TextStyle(
              color: remaining == 0 ? Colors.redAccent : AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _UpgradeCard extends StatelessWidget {
  const _UpgradeCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.primaryAccent, AppColors.secondaryAccent],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Row(
          children: [
            Icon(Icons.workspace_premium_rounded, color: Colors.white, size: 22),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Upgrade para VIP',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  Text(
                    'R\$9,99/mês — uploads e downloads ilimitados',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, color: Colors.white70, size: 16),
          ],
        ),
      ),
    );
  }
}

class _CouponCard extends StatelessWidget {
  const _CouponCard({required this.onRedeem});

  final VoidCallback onRedeem;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.card),
      ),
      child: Row(
        children: [
          const Icon(Icons.local_offer_rounded, color: AppColors.primaryAccent, size: 22),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cupom de desconto',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                Text(
                  'Tem um código? Resgate seu acesso VIP.',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: onRedeem,
            child: const Text(
              'Usar',
              style: TextStyle(color: AppColors.primaryAccent, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _CancelCard extends StatelessWidget {
  const _CancelCard({required this.onCancel});

  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.cancel_outlined, color: Colors.redAccent, size: 22),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cancelar assinatura',
                  style: TextStyle(
                    color: Colors.redAccent,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                Text(
                  'Seu acesso permanece até o fim do período pago.',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: onCancel,
            child: const Text(
              'Cancelar',
              style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeedbackBanner extends StatelessWidget {
  const _FeedbackBanner({
    required this.message,
    required this.isError,
    required this.onDismiss,
  });

  final String message;
  final bool isError;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final color = isError ? Colors.redAccent : AppColors.secondaryAccent;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(
            isError ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded,
            color: color,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: color, fontSize: 13),
            ),
          ),
          GestureDetector(
            onTap: onDismiss,
            child: Icon(Icons.close_rounded, color: color, size: 16),
          ),
        ],
      ),
    );
  }
}
