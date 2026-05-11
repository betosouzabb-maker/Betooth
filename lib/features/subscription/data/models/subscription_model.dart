import '../../domain/entities/subscription_entity.dart';

class SubscriptionModel extends SubscriptionEntity {
  const SubscriptionModel({
    required super.id,
    required super.status,
    required super.plan,
    required super.currentPeriodStart,
    required super.currentPeriodEnd,
    super.trialEndsAt,
    super.cancelledAt,
  });

  factory SubscriptionModel.fromJson(Map<String, dynamic> json) {
    return SubscriptionModel(
      id: json['id'] as String? ?? '',
      status: _parseStatus(json['status'] as String?),
      plan: _parsePlan(json['plan'] as String?),
      currentPeriodStart: DateTime.tryParse(json['currentPeriodStart'] as String? ?? '') ?? DateTime.now(),
      currentPeriodEnd: DateTime.tryParse(json['currentPeriodEnd'] as String? ?? '') ?? DateTime.now(),
      trialEndsAt: json['trialEndsAt'] != null
          ? DateTime.tryParse(json['trialEndsAt'] as String)
          : null,
      cancelledAt: json['cancelledAt'] != null
          ? DateTime.tryParse(json['cancelledAt'] as String)
          : null,
    );
  }

  static SubscriptionStatus _parseStatus(String? value) {
    switch (value?.toUpperCase()) {
      case 'ACTIVE':
        return SubscriptionStatus.active;
      case 'CANCELLED':
        return SubscriptionStatus.cancelled;
      case 'EXPIRED':
        return SubscriptionStatus.expired;
      case 'TRIAL':
        return SubscriptionStatus.trial;
      case 'PAST_DUE':
        return SubscriptionStatus.pastDue;
      default:
        return SubscriptionStatus.expired;
    }
  }

  static SubscriptionPlan _parsePlan(String? value) {
    switch (value?.toUpperCase()) {
      case 'MONTHLY':
        return SubscriptionPlan.monthly;
      default:
        return SubscriptionPlan.monthly;
    }
  }
}

class DownloadQuotaModel extends DownloadQuotaEntity {
  const DownloadQuotaModel({
    required super.isVip,
    required super.used,
    super.limit,
    required super.monthKey,
    required super.resetAt,
  });

  factory DownloadQuotaModel.fromJson(Map<String, dynamic> json) {
    return DownloadQuotaModel(
      isVip: json['isVip'] as bool? ?? false,
      used: json['used'] as int? ?? 0,
      limit: json['limit'] as int?,
      monthKey: json['monthKey'] as String? ?? '',
      resetAt: DateTime.tryParse(json['resetAt'] as String? ?? '') ?? DateTime.now(),
    );
  }
}
