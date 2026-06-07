// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'follow_snapshot.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class FollowSnapshotAdapter extends TypeAdapter<FollowSnapshot> {
  @override
  final typeId = 5;

  @override
  FollowSnapshot read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return FollowSnapshot(
      expireAt: fields[0] == null ? 0 : (fields[0] as num).toInt(),
      followSnapshotItems: fields[1] == null
          ? []
          : (fields[1] as List).cast<FollowSnapshotItem>(),
    );
  }

  @override
  void write(BinaryWriter writer, FollowSnapshot obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.expireAt)
      ..writeByte(1)
      ..write(obj.followSnapshotItems);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FollowSnapshotAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class FollowSnapshotItemAdapter extends TypeAdapter<FollowSnapshotItem> {
  @override
  final typeId = 4;

  @override
  FollowSnapshotItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return FollowSnapshotItem(
      id: fields[0] as String,
      liveStatus: (fields[1] as num).toInt(),
      cover: fields[2] as String,
      title: fields[3] as String,
      online: (fields[4] as num).toInt(),
    );
  }

  @override
  void write(BinaryWriter writer, FollowSnapshotItem obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.liveStatus)
      ..writeByte(2)
      ..write(obj.cover)
      ..writeByte(3)
      ..write(obj.title)
      ..writeByte(4)
      ..write(obj.online);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FollowSnapshotItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
