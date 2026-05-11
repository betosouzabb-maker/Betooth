import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/subscription_remote_datasource.dart';
import '../../data/models/subscription_model.dart';
import '../entities/subscription_entity.dart';

final subscriptionRepositoryProvider = Provider<SubscriptionRepository>(
  (ref) => SubscriptionRepositoryImpl(ref.watch(subscriptionRemoteDatasourceProvider)),
);

abstract class SubscriptionRepository {
  Future<SubscriptionState> getMySubscription();
  Future<DownloadQuotaEntity> getDownloadQuota();
  Future<String> checkout();
  Future<void> cancelSubscription();
  Future<String> redeemCoupon(String code);
  Future<Map<String, dynamic>> validateCoupon(String code);
}

class SubscriptionState {
  const SubscriptionState({
    required this.isVip,
    this.subscription,
    required this.downloadQuota,
  });

  final bool isVip;
  final SubscriptionEntity? subscription;
  final DownloadQuotaEntity downloadQuota;
}

class SubscriptionRepositoryImpl implements SubscriptionRepository {
  SubscriptionRepositoryImpl(this._datasource);

  final SubscriptionRemoteDatasource _datasource;

  @override
  Future<SubscriptionState> getMySubscription() async {
    final data = await _datasource.getMySubscription();
    final isVip = data['isVip'] as bool? ?? false;

    SubscriptionEntity? subscription;
    if (data['subscription'] != null) {
      subscription = SubscriptionModel.fromJson(
        data['subscription'] as Map<String, dynamic>,
      );
    }

    final quotaRaw = data['downloadQuota'] as Map<String, dynamic>? ?? {};
    final quota = DownloadQuotaModel.fromJson({
      'isVip': isVip,
      ...quotaRaw,
      'resetAt': _nextMonthReset(),
    });

    return SubscriptionState(
      isVip: isVip,
      subscription: subscription,
      downloadQuota: quota,
    );
  }

  @override
  Future<DownloadQuotaEntity> getDownloadQuota() async {
    return _datasource.getDownloadQuota();
  }

  @override
  Future<String> checkout() async {
    final data = await _datasource.checkout();
    return data['checkoutUrl'] as String? ?? '';
  }

  @override
  Future<void> cancelSubscription() async {
    await _datasource.cancelSubscription();
  }

  @override
  Future<String> redeemCoupon(String code) async {
    final data = await _datasource.redeemCoupon(code);
    return data['message'] as String? ?? 'Cupom aplicado com sucesso!';
  }

  @override
  Future<Map<String, dynamic>> validateCoupon(String code) async {
    return _datasource.validateCoupon(code);
  }

  String _nextMonthReset() {
    final now = DateTime.now().toUtc();
    final next = DateTime.utc(now.year, now.month + 1, 1);
    return next.toIso8601String();
  }
}
