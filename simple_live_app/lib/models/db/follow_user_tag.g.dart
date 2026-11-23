// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'follow_user_tag.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TagBindingAdapter extends TypeAdapter<TagBinding> {
  @override
  final typeId = 9;

  @override
  TagBinding read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TagBinding(
      siteId: fields[1] as String,
      categoryId: fields[2] as String,
      categoryName: fields[3] == null ? "" : fields[3] as String,
    );
  }

  @override
  void write(BinaryWriter writer, TagBinding obj) {
    writer
      ..writeByte(3)
      ..writeByte(1)
      ..write(obj.siteId)
      ..writeByte(2)
      ..write(obj.categoryId)
      ..writeByte(3)
      ..write(obj.categoryName);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TagBindingAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class FollowUserTagAdapter extends TypeAdapter<FollowUserTag> {
  @override
  final typeId = 3;

  @override
  FollowUserTag read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return FollowUserTag(
      id: fields[1] as String,
      tag: fields[2] as String,
      userId: (fields[3] as List).cast<String>(),
      bindings:
          fields[4] == null ? [] : (fields[4] as List?)?.cast<TagBinding>(),
    );
  }

  @override
  void write(BinaryWriter writer, FollowUserTag obj) {
    writer
      ..writeByte(4)
      ..writeByte(1)
      ..write(obj.id)
      ..writeByte(2)
      ..write(obj.tag)
      ..writeByte(3)
      ..write(obj.userId)
      ..writeByte(4)
      ..write(obj.bindings);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FollowUserTagAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
