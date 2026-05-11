import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/colors.dart';
import '../controllers/subscription_controller.dart';

Future<bool> showCouponRedeemDialog(BuildContext context) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (_) => const CouponRedeemDialog(),
  );
  return result ?? false;
}

class CouponRedeemDialog extends ConsumerStatefulWidget {
  const CouponRedeemDialog({super.key});

  @override
  ConsumerState<CouponRedeemDialog> createState() => _CouponRedeemDialogState();
}

class _CouponRedeemDialogState extends ConsumerState<CouponRedeemDialog> {
  final _controller = TextEditingController();
  bool _loading = false;
  String? _error;
  String? _success;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _redeem() async {
    setState(() {
      _error = null;
      _success = null;
      _loading = true;
    });

    final ok = await ref
        .read(subscriptionControllerProvider.notifier)
        .redeemCoupon(_controller.text.trim());

    if (!mounted) return;

    if (ok) {
      final msg = ref.read(subscriptionControllerProvider).successMessage;
      setState(() {
        _loading = false;
        _success = msg ?? 'Cupom aplicado com sucesso!';
      });
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) Navigator.of(context).pop(true);
    } else {
      setState(() {
        _loading = false;
        _error = ref.read(subscriptionControllerProvider).errorMessage ??
            'Cupom inválido.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Row(
        children: [
          Icon(Icons.local_offer_rounded, color: AppColors.primaryAccent, size: 20),
          SizedBox(width: 8),
          Text(
            'Resgatar cupom',
            style: TextStyle(color: AppColors.textPrimary, fontSize: 17),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _controller,
            textCapitalization: TextCapitalization.characters,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              letterSpacing: 2,
              fontWeight: FontWeight.w600,
            ),
            decoration: InputDecoration(
              hintText: 'BETOOTH7DIAS',
              hintStyle: const TextStyle(
                color: AppColors.textSecondary,
                letterSpacing: 1,
                fontWeight: FontWeight.normal,
              ),
              filled: true,
              fillColor: AppColors.card,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.primaryAccent, width: 1.5),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
            onSubmitted: (_) => _loading ? null : _redeem(),
          ),
          if (_error != null) ...[
            const SizedBox(height: 10),
            Text(
              _error!,
              style: const TextStyle(color: Colors.redAccent, fontSize: 13),
            ),
          ],
          if (_success != null) ...[
            const SizedBox(height: 10),
            Text(
              _success!,
              style: const TextStyle(color: AppColors.secondaryAccent, fontSize: 13),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: _loading ? null : () => Navigator.of(context).pop(false),
          child: const Text(
            'Cancelar',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
        FilledButton(
          onPressed: _loading ? null : _redeem,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primaryAccent,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: _loading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text('Resgatar'),
        ),
      ],
    );
  }
}
