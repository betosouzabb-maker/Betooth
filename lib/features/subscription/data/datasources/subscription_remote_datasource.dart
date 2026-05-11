import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_client.dart';
import '../models/subscription_model.dart';

final subscriptionRemoteDatasourceProvider = Provider<SubscriptionRemoteDatasource>(
  (ref) => SubscriptionRemoteDatasource(ref.watch(dioProvider)),
);

class SubscriptionRemoteDatasource {
  SubscriptionRemoteDatasource(this._dio);

  final Dio _dio;

  Future<Map<String, dynamic>> getMySubscription() async {
    final response = await _dio.get<Map<String, dynamic>>('/subscriptions/me');
    return (response.data?['data'] as Map<String, dynamic>?) ?? {};
  }

  Future<DownloadQuotaModel> getDownloadQuota() async {
    final response = await _dio.get<Map<String, dynamic>>('/subscriptions/me');
    final data = (response.data?['data'] as Map<String, dynamic>?) ?? {};
    final quotaData = data['downloadQuota'] as Map<String, dynamic>? ?? {};
    return DownloadQuotaModel.fromJson({
      'isVip': data['isVip'] ?? false,
      ...quotaData,
      'resetAt': _nextMonthReset(),
    });
  }

  Future<Map<String, dynamic>> checkout() async {
    final response = await _dio.post<Map<String, dynamic>>('/subscriptions/checkout');
    return (response.data?['data'] as Map<String, dynamic>?) ?? {};
  }

  Future<Map<String, dynamic>> cancelSubscription() async {
    final response = await _dio.delete<Map<String, dynamic>>('/subscriptions/me');
    return (response.data?['data'] as Map<String, dynamic>?) ?? {};
  }

  Future<Map<String, dynamic>> redeemCoupon(String code) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/subscriptions/coupon/redeem',
      data: {'code': code.toUpperCase()},
    );
    return (response.data?['data'] as Map<String, dynamic>?) ?? {};
  }

  Future<Map<String, dynamic>> validateCoupon(String code) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/subscriptions/coupon/${Uri.encodeComponent(code.toUpperCase())}/validate',
    );
    return (response.data?['data'] as Map<String, dynamic>?) ?? {};
  }

  String _nextMonthReset() {
    final now = DateTime.now().toUtc();
    final next = DateTime.utc(now.year, now.month + 1, 1);
    return next.toIso8601String();
  }
}
