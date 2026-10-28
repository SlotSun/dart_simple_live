// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'account.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AccountAdapter extends TypeAdapter<Account> {
  @override
  final typeId = 8;

  @override
  Account read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Account(
      id: fields[0] as String,
      siteId: fields[1] as String,
      userName: fields[2] as String?,
      avatar: fields[3] as String?,
      uid: fields[4] as String?,
      credential: fields[5] == null ? '' : fields[5] as String,
      isActive: fields[6] == null ? true : fields[6] as bool,
      createdAt: fields[7] == null ? 0 : (fields[7] as num).toInt(),
      updatedAt: fields[8] == null ? 0 : (fields[8] as num).toInt(),
      supportCookieLogin: fields[10] == null ? false : fields[10] as bool,
      supportQRLogin: fields[9] == null ? false : fields[9] as bool,
      supportWebLogin: fields[11] == null ? false : fields[11] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, Account obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.siteId)
      ..writeByte(2)
      ..write(obj.userName)
      ..writeByte(3)
      ..write(obj.avatar)
      ..writeByte(4)
      ..write(obj.uid)
      ..writeByte(5)
      ..write(obj.credential)
      ..writeByte(6)
      ..write(obj.isActive)
      ..writeByte(7)
      ..write(obj.createdAt)
      ..writeByte(8)
      ..write(obj.updatedAt)
      ..writeByte(9)
      ..write(obj.supportQRLogin)
      ..writeByte(10)
      ..write(obj.supportCookieLogin)
      ..writeByte(11)
      ..write(obj.supportWebLogin);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is AccountAdapter && runtimeType == other.runtimeType && typeId == other.typeId;
}
