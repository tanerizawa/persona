class SyncStatus {
  final String id;
  final String userId;
  final String deviceId;
  final DateTime lastSyncTimestamp;
  final int syncVersion;
  final String? dataHash;
  final bool isActive;

  SyncStatus({
    required this.id,
    required this.userId,
    required this.deviceId,
    required this.lastSyncTimestamp,
    required this.syncVersion,
    this.dataHash,
    required this.isActive,
  });

  factory SyncStatus.fromJson(Map<String, dynamic> json) {
    return SyncStatus(
      id: json['id'],
      userId: json['userId'],
      deviceId: json['deviceId'],
      lastSyncTimestamp: DateTime.parse(json['lastSyncTimestamp']),
      syncVersion: json['syncVersion'],
      dataHash: json['dataHash'],
      isActive: json['isActive'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'deviceId': deviceId,
      'lastSyncTimestamp': lastSyncTimestamp.toIso8601String(),
      'syncVersion': syncVersion,
      'dataHash': dataHash,
      'isActive': isActive,
    };
  }
}

class SyncConflict {
  final String deviceId1;
  final String deviceId2;
  final DateTime timestamp1;
  final DateTime timestamp2;
  final String? dataHash1;
  final String? dataHash2;
  final String conflictType;

  SyncConflict({
    required this.deviceId1,
    required this.deviceId2,
    required this.timestamp1,
    required this.timestamp2,
    this.dataHash1,
    this.dataHash2,
    required this.conflictType,
  });

  factory SyncConflict.fromJson(Map<String, dynamic> json) {
    return SyncConflict(
      deviceId1: json['deviceId1'],
      deviceId2: json['deviceId2'],
      timestamp1: DateTime.parse(json['timestamp1']),
      timestamp2: DateTime.parse(json['timestamp2']),
      dataHash1: json['dataHash1'],
      dataHash2: json['dataHash2'],
      conflictType: json['conflictType'],
    );
  }
}

class BackupResult {
  final String id;
  final String userId;
  final DateTime backupDate;
  final int? dataSize;
  final String? checksum;

  BackupResult({
    required this.id,
    required this.userId,
    required this.backupDate,
    this.dataSize,
    this.checksum,
  });

  factory BackupResult.fromJson(Map<String, dynamic> json) {
    return BackupResult(
      id: json['id'],
      userId: json['userId'],
      backupDate: DateTime.parse(json['backupDate']),
      dataSize: json['dataSize'],
      checksum: json['checksum'],
    );
  }
}

class SyncResult {
  final bool success;
  final String message;
  final bool skipped;
  final int? synced;
  final int? conflicts;
  final Map<String, dynamic>? metadata;

  SyncResult({
    required this.success,
    required this.message,
    this.skipped = false,
    this.synced,
    this.conflicts,
    this.metadata,
  });

  factory SyncResult.fromJson(Map<String, dynamic> json) {
    return SyncResult(
      success: json['success'],
      message: json['message'],
      skipped: json['skipped'] ?? false,
      synced: json['synced'],
      conflicts: json['conflicts'],
      metadata: json['metadata'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'skipped': skipped,
      'synced': synced,
      'conflicts': conflicts,
      'metadata': metadata,
    };
  }
}
