// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'badge.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class BadgeAdapter extends TypeAdapter<Badge> {
  @override
  final int typeId = 8;

  @override
  Badge read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Badge(
      id: fields[0] as String,
      name: fields[1] as String,
      description: fields[2] as String,
      iconName: fields[3] as String,
      color: fields[4] as int,
      type: fields[5] as BadgeType,
      category: fields[6] as BadgeCategory,
      isEarned: fields[7] as bool,
      earnedAt: fields[8] as DateTime?,
      targetValue: fields[9] as double?,
      currentValue: fields[10] as double?,
      unit: fields[11] as String?,
      difficulty: fields[12] as int,
      points: fields[13] as int,
      createdAt: fields[14] as DateTime,
      criteria: (fields[15] as Map?)?.cast<String, dynamic>(),
      isHidden: fields[16] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, Badge obj) {
    writer
      ..writeByte(17)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.iconName)
      ..writeByte(4)
      ..write(obj.color)
      ..writeByte(5)
      ..write(obj.type)
      ..writeByte(6)
      ..write(obj.category)
      ..writeByte(7)
      ..write(obj.isEarned)
      ..writeByte(8)
      ..write(obj.earnedAt)
      ..writeByte(9)
      ..write(obj.targetValue)
      ..writeByte(10)
      ..write(obj.currentValue)
      ..writeByte(11)
      ..write(obj.unit)
      ..writeByte(12)
      ..write(obj.difficulty)
      ..writeByte(13)
      ..write(obj.points)
      ..writeByte(14)
      ..write(obj.createdAt)
      ..writeByte(15)
      ..write(obj.criteria)
      ..writeByte(16)
      ..write(obj.isHidden);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BadgeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class BadgeTypeAdapter extends TypeAdapter<BadgeType> {
  @override
  final int typeId = 23;

  @override
  BadgeType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return BadgeType.achievement;
      case 1:
        return BadgeType.milestone;
      case 2:
        return BadgeType.streak;
      case 3:
        return BadgeType.challenge;
      default:
        return BadgeType.achievement;
    }
  }

  @override
  void write(BinaryWriter writer, BadgeType obj) {
    switch (obj) {
      case BadgeType.achievement:
        writer.writeByte(0);
        break;
      case BadgeType.milestone:
        writer.writeByte(1);
        break;
      case BadgeType.streak:
        writer.writeByte(2);
        break;
      case BadgeType.challenge:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BadgeTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class BadgeCategoryAdapter extends TypeAdapter<BadgeCategory> {
  @override
  final int typeId = 24;

  @override
  BadgeCategory read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return BadgeCategory.savings;
      case 1:
        return BadgeCategory.budgeting;
      case 2:
        return BadgeCategory.transactions;
      case 3:
        return BadgeCategory.goals;
      case 4:
        return BadgeCategory.consistency;
      case 5:
        return BadgeCategory.exploration;
      case 6:
        return BadgeCategory.social;
      case 7:
        return BadgeCategory.special;
      default:
        return BadgeCategory.savings;
    }
  }

  @override
  void write(BinaryWriter writer, BadgeCategory obj) {
    switch (obj) {
      case BadgeCategory.savings:
        writer.writeByte(0);
        break;
      case BadgeCategory.budgeting:
        writer.writeByte(1);
        break;
      case BadgeCategory.transactions:
        writer.writeByte(2);
        break;
      case BadgeCategory.goals:
        writer.writeByte(3);
        break;
      case BadgeCategory.consistency:
        writer.writeByte(4);
        break;
      case BadgeCategory.exploration:
        writer.writeByte(5);
        break;
      case BadgeCategory.social:
        writer.writeByte(6);
        break;
      case BadgeCategory.special:
        writer.writeByte(7);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BadgeCategoryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
