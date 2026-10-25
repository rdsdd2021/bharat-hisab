enum SyncOperation {
  create,
  update,
  delete,
}

enum SyncStatus {
  pending,
  inProgress,
  synced,
  failed,
}

class SyncQueueEntry {
  final String id;
  final String entityType;
  final String entityId;
  final SyncOperation operation;
  final String payloadJson;
  final DateTime createdAt;
  final int retryCount;
  final DateTime? lastAttemptAt;
  final SyncStatus status;
  final String? errorMessage;

  const SyncQueueEntry({
    required this.id,
    required this.entityType,
    required this.entityId,
    required this.operation,
    required this.payloadJson,
    required this.createdAt,
    this.retryCount = 0,
    this.lastAttemptAt,
    this.status = SyncStatus.pending,
    this.errorMessage,
  });

  SyncQueueEntry copyWith({
    String? id,
    String? entityType,
    String? entityId,
    SyncOperation? operation,
    String? payloadJson,
    DateTime? createdAt,
    int? retryCount,
    DateTime? lastAttemptAt,
    SyncStatus? status,
    String? errorMessage,
  }) {
    return SyncQueueEntry(
      id: id ?? this.id,
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      operation: operation ?? this.operation,
      payloadJson: payloadJson ?? this.payloadJson,
      createdAt: createdAt ?? this.createdAt,
      retryCount: retryCount ?? this.retryCount,
      lastAttemptAt: lastAttemptAt ?? this.lastAttemptAt,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'entityType': entityType,
      'entityId': entityId,
      'operation': operation.name,
      'payloadJson': payloadJson,
      'createdAt': createdAt.toIso8601String(),
      'retryCount': retryCount,
      'lastAttemptAt': lastAttemptAt?.toIso8601String(),
      'status': status.name,
      'errorMessage': errorMessage,
    };
  }

  factory SyncQueueEntry.fromJson(Map<String, dynamic> json) {
    return SyncQueueEntry(
      id: json['id'] as String? ?? '',
      entityType: json['entityType'] as String? ?? '',
      entityId: json['entityId'] as String? ?? '',
      operation: SyncOperation.values.firstWhere(
        (e) => e.name == json['operation'],
        orElse: () => SyncOperation.create,
      ),
      payloadJson: json['payloadJson'] as String? ?? '{}',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      retryCount: (json['retryCount'] as num?)?.toInt() ?? 0,
      lastAttemptAt: json['lastAttemptAt'] != null
          ? DateTime.tryParse(json['lastAttemptAt'] as String)
          : null,
      status: SyncStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => SyncStatus.pending,
      ),
      errorMessage: json['errorMessage'] as String?,
    );
  }
}
