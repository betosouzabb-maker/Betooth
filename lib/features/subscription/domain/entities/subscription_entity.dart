enum SubscriptionStatus { active, cancelled, expired, trial, pastDue }

enum SubscriptionPlan { monthly }

class SubscriptionEntity {
  const SubscriptionEntity({
    required this.id,
    required this.status,
    required this.plan,
    required this.currentPeriodStart,
    required this.currentPeriodEnd,
    this.trialEndsAt,
    this.cancelledAt,
  });

  final String id;
  final SubscriptionStatus status;
  final SubscriptionPlan plan;
  final DateTime currentPeriodStart;
  final DateTime currentPeriodEnd;
  final DateTime? trialEndsAt;
  final DateTime? cancelledAt;

  bool get isActive =>
      status == SubscriptionStatus.active && currentPeriodEnd.isAfter(DateTime.now());
}

class DownloadQuotaEntity {
  const DownloadQuotaEntity({
    required this.isVip,
    required this.used,
    required this.limit,
    required this.monthKey,
    required this.resetAt,
  });

  final bool isVip;
  final int used;
  final int? limit;
  final String monthKey;
  final DateTime resetAt;

  int get remaining => isVip ? 999 : ((limit ?? 5) - used).clamp(0, limit ?? 5);
  bool get hasQuota => isVip || used < (limit ?? 5);
}
