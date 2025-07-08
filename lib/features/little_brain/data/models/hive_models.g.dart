// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'hive_models.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class HiveMemoryAdapter extends TypeAdapter<HiveMemory> {
  @override
  final int typeId = 0;

  @override
  HiveMemory read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HiveMemory(
      id: fields[0] as String,
      content: fields[1] as String,
      tags: (fields[2] as List).cast<String>(),
      contexts: (fields[3] as List).cast<String>(),
      emotionalWeight: fields[4] as double,
      timestamp: fields[5] as DateTime,
      source: fields[6] as String,
      metadata: (fields[7] as Map).cast<String, dynamic>(),
      type: fields[8] as String?,
      importance: fields[9] as double?,
    );
  }

  @override
  void write(BinaryWriter writer, HiveMemory obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.content)
      ..writeByte(2)
      ..write(obj.tags)
      ..writeByte(3)
      ..write(obj.contexts)
      ..writeByte(4)
      ..write(obj.emotionalWeight)
      ..writeByte(5)
      ..write(obj.timestamp)
      ..writeByte(6)
      ..write(obj.source)
      ..writeByte(7)
      ..write(obj.metadata)
      ..writeByte(8)
      ..write(obj.type)
      ..writeByte(9)
      ..write(obj.importance);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HiveMemoryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class HivePersonalityProfileAdapter
    extends TypeAdapter<HivePersonalityProfile> {
  @override
  final int typeId = 1;

  @override
  HivePersonalityProfile read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HivePersonalityProfile(
      userId: fields[0] as String,
      traits: (fields[1] as Map).cast<String, double>(),
      interests: (fields[2] as List).cast<String>(),
      values: (fields[3] as List).cast<String>(),
      communicationPatterns: (fields[4] as Map).cast<String, int>(),
      lastUpdated: fields[5] as DateTime,
      memoryCount: fields[6] as int,
    );
  }

  @override
  void write(BinaryWriter writer, HivePersonalityProfile obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.userId)
      ..writeByte(1)
      ..write(obj.traits)
      ..writeByte(2)
      ..write(obj.interests)
      ..writeByte(3)
      ..write(obj.values)
      ..writeByte(4)
      ..write(obj.communicationPatterns)
      ..writeByte(5)
      ..write(obj.lastUpdated)
      ..writeByte(6)
      ..write(obj.memoryCount);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HivePersonalityProfileAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class HiveContextAdapter extends TypeAdapter<HiveContext> {
  @override
  final int typeId = 2;

  @override
  HiveContext read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HiveContext(
      id: fields[0] as String,
      name: fields[1] as String,
      type: fields[2] as String,
      parameters: (fields[3] as Map).cast<String, dynamic>(),
      createdAt: fields[4] as DateTime,
      isUserDefined: fields[5] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, HiveContext obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.type)
      ..writeByte(3)
      ..write(obj.parameters)
      ..writeByte(4)
      ..write(obj.createdAt)
      ..writeByte(5)
      ..write(obj.isUserDefined);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HiveContextAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class HiveSyncMetadataAdapter extends TypeAdapter<HiveSyncMetadata> {
  @override
  final int typeId = 3;

  @override
  HiveSyncMetadata read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HiveSyncMetadata(
      userId: fields[0] as String,
      lastSyncTime: fields[1] as DateTime,
      checksum: fields[2] as String,
      memoryCount: fields[3] as int,
      syncPending: fields[4] as bool,
      deviceInfo: (fields[5] as Map).cast<String, dynamic>(),
    );
  }

  @override
  void write(BinaryWriter writer, HiveSyncMetadata obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.userId)
      ..writeByte(1)
      ..write(obj.lastSyncTime)
      ..writeByte(2)
      ..write(obj.checksum)
      ..writeByte(3)
      ..write(obj.memoryCount)
      ..writeByte(4)
      ..write(obj.syncPending)
      ..writeByte(5)
      ..write(obj.deviceInfo);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HiveSyncMetadataAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
