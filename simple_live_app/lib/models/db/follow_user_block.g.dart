// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'follow_user_block.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class FollowUserBlockAdapter extends TypeAdapter<FollowUserBlock> {
  @override
  final typeId = 7;

  @override
  FollowUserBlock read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return FollowUserBlock(
      id: fields[0] as String,
      roomId: fields[1] as String,
      siteId: fields[2] as String,
      blockAccounts: fields[3] == null
          ? []
          : (fields[3] as List).cast<FollowUserBlockAccount>(),
      blockWords: fields[4] == null ? [] : (fields[4] as List).cast<String>(),
      updateTime: fields[5] == null ? 0 : (fields[5] as num).toInt(),
    );
  }

  @override
  void write(BinaryWriter writer, FollowUserBlock obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.roomId)
      ..writeByte(2)
      ..write(obj.siteId)
      ..writeByte(3)
      ..write(obj.blockAccounts)
      ..writeByte(4)
      ..write(obj.blockWords)
      ..writeByte(5)
      ..write(obj.updateTime);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FollowUserBlockAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class FollowUserBlockAccountAdapter
    extends TypeAdapter<FollowUserBlockAccount> {
  @override
  final typeId = 6;

  @override
  FollowUserBlockAccount read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return FollowUserBlockAccount(
      uid: fields[0] as String,
      name: fields[1] as String,
    );
  }

  @override
  void write(BinaryWriter writer, FollowUserBlockAccount obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.uid)
      ..writeByte(1)
      ..write(obj.name);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FollowUserBlockAccountAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
