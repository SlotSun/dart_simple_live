// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'follow_user.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class FollowUserAdapter extends TypeAdapter<FollowUser> {
  @override
  final typeId = 1;

  @override
  FollowUser read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return FollowUser(
      id: fields[0] as String,
      roomId: fields[1] as String,
      siteId: fields[2] as String,
      userName: fields[3] as String,
      face: fields[4] as String,
      addTime: fields[5] as DateTime,
      watchDuration: fields[6] == null ? "00:00:00" : fields[6] as String?,
      tag: fields[7] == null ? "全部" : fields[7] as String,
      remark: fields[8] == null ? "" : fields[8] as String?,
      romanName: fields[9] == null ? "" : fields[9] as String?,
      syncDuration: fields[10] == null ? 0 : (fields[10] as num).toInt(),
      watchDurationSec: fields[11] == null ? 0 : (fields[11] as num).toInt(),
      deleted: fields[12] == null ? false : fields[12] as bool,
      updateTime: fields[13] == null ? 0 : (fields[13] as num).toInt(),
      lastWatchTime: fields[14] == null ? 0 : (fields[14] as num?)?.toInt(),
    );
  }

  @override
  void write(BinaryWriter writer, FollowUser obj) {
    writer
      ..writeByte(15)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.roomId)
      ..writeByte(2)
      ..write(obj.siteId)
      ..writeByte(3)
      ..write(obj.userName)
      ..writeByte(4)
      ..write(obj.face)
      ..writeByte(5)
      ..write(obj.addTime)
      ..writeByte(6)
      ..write(obj.watchDuration)
      ..writeByte(7)
      ..write(obj.tag)
      ..writeByte(8)
      ..write(obj.remark)
      ..writeByte(9)
      ..write(obj.romanName)
      ..writeByte(10)
      ..write(obj.syncDuration)
      ..writeByte(11)
      ..write(obj.watchDurationSec)
      ..writeByte(12)
      ..write(obj.deleted)
      ..writeByte(13)
      ..write(obj.updateTime)
      ..writeByte(14)
      ..write(obj.lastWatchTime);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FollowUserAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
