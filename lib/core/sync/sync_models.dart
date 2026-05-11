/// Data models for sync engine mutations and deltas.
library;

class SyncMutation {
  SyncMutation({
    required this.entityType,
    required this.operation,
    required this.clientMutationId,
    this.payload,
  });

  factory SyncMutation.fromJson(Map<String, dynamic> json) {
    return SyncMutation(
      entityType: json['entityType'] as String,
      operation: json['operation'] as String,
      clientMutationId: json['clientMutationId'] as String,
      payload: json['payload'] as Map<String, dynamic>?,
    );
  }

  final String entityType;
  final String operation; // 'upsert' | 'delete'
  final String clientMutationId;
  final Map<String, dynamic>? payload;

  Map<String, dynamic> toJson() => {
        'entityType': entityType,
        'operation': operation,
        'clientMutationId': clientMutationId,
        if (payload != null) 'payload': payload,
      };
}

class AppliedMutation {
  const AppliedMutation({
    required this.clientMutationId,
    required this.serverId,
    required this.version,
  });

  factory AppliedMutation.fromJson(Map<String, dynamic> json) {
    return AppliedMutation(
      clientMutationId: json['clientMutationId'] as String,
      serverId: json['serverId'] as String?,
      version: json['version'] as int,
    );
  }

  final String clientMutationId;
  final String? serverId;
  final int version;
}

class SyncConflict {
  const SyncConflict({
    required this.clientMutationId,
    required this.reason,
  });

  factory SyncConflict.fromJson(Map<String, dynamic> json) {
    return SyncConflict(
      clientMutationId: json['clientMutationId'] as String,
      reason: json['reason'] as String,
    );
  }

  final String clientMutationId;
  final String reason;
}

class SyncDelta {
  const SyncDelta({
    required this.id,
    required this.entityType,
    required this.entityId,
    required this.operation,
    required this.version,
    required this.createdAt,
    this.payload,
  });

  factory SyncDelta.fromJson(Map<String, dynamic> json) {
    return SyncDelta(
      id: json['id'] as String,
      entityType: json['entityType'] as String,
      entityId: json['entityId'] as String,
      operation: json['operation'] as String,
      payload: json['payload'] as Map<String, dynamic>?,
      version: json['version'] as int,
      createdAt: json['createdAt'] as String,
    );
  }

  final String id;
  final String entityType;
  final String entityId;
  final String operation;
  final Map<String, dynamic>? payload;
  final int version;
  final String createdAt;
}

class PushResult {
  const PushResult({required this.applied, required this.conflicts});

  factory PushResult.fromJson(Map<String, dynamic> json) {
    final appliedList = (json['applied'] as List?)
            ?.map((e) => AppliedMutation.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];
    final conflictsList = (json['conflicts'] as List?)
            ?.map((e) => SyncConflict.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];
    return PushResult(applied: appliedList, conflicts: conflictsList);
  }

  final List<AppliedMutation> applied;
  final List<SyncConflict> conflicts;
}

class PullResult {
  const PullResult({
    required this.changes,
    required this.currentVersion,
    required this.hasMore,
  });

  factory PullResult.fromJson(Map<String, dynamic> json) {
    final changesList = (json['changes'] as List?)
            ?.map((e) => SyncDelta.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];
    return PullResult(
      changes: changesList,
      currentVersion: json['currentVersion'] as int? ?? 0,
      hasMore: json['hasMore'] as bool? ?? false,
    );
  }

  final List<SyncDelta> changes;
  final int currentVersion;
  final bool hasMore;
}
