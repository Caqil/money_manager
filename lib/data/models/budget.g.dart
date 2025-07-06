// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'budget.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class BudgetAdapter extends TypeAdapter<Budget> {
  @override
  final int typeId = 2;

  @override
  Budget read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Budget(
      id: fields[0] as String,
      name: fields[1] as String,
      categoryId: fields[2] as String,
      limit: fields[3] as double,
      period: fields[4] as BudgetPeriod,
      startDate: fields[5] as DateTime,
      endDate: fields[6] as DateTime?,
      isActive: fields[7] as bool,
      alertThreshold: fields[8] as double,
      enableAlerts: fields[9] as bool,
      accountIds: (fields[10] as List?)?.cast<String>(),
      createdAt: fields[11] as DateTime,
      updatedAt: fields[12] as DateTime,
      description: fields[13] as String?,
      rolloverType: fields[14] as BudgetRolloverType,
    );
  }

  @override
  void write(BinaryWriter writer, Budget obj) {
    writer
      ..writeByte(15)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.categoryId)
      ..writeByte(3)
      ..write(obj.limit)
      ..writeByte(4)
      ..write(obj.period)
      ..writeByte(5)
      ..write(obj.startDate)
      ..writeByte(6)
      ..write(obj.endDate)
      ..writeByte(7)
      ..write(obj.isActive)
      ..writeByte(8)
      ..write(obj.alertThreshold)
      ..writeByte(9)
      ..write(obj.enableAlerts)
      ..writeByte(10)
      ..write(obj.accountIds)
      ..writeByte(11)
      ..write(obj.createdAt)
      ..writeByte(12)
      ..write(obj.updatedAt)
      ..writeByte(13)
      ..write(obj.description)
      ..writeByte(14)
      ..write(obj.rolloverType);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BudgetAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class BudgetPeriodAdapter extends TypeAdapter<BudgetPeriod> {
  @override
  final int typeId = 12;

  @override
  BudgetPeriod read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return BudgetPeriod.weekly;
      case 1:
        return BudgetPeriod.monthly;
      case 2:
        return BudgetPeriod.quarterly;
      case 3:
        return BudgetPeriod.yearly;
      case 4:
        return BudgetPeriod.custom;
      default:
        return BudgetPeriod.weekly;
    }
  }

  @override
  void write(BinaryWriter writer, BudgetPeriod obj) {
    switch (obj) {
      case BudgetPeriod.weekly:
        writer.writeByte(0);
        break;
      case BudgetPeriod.monthly:
        writer.writeByte(1);
        break;
      case BudgetPeriod.quarterly:
        writer.writeByte(2);
        break;
      case BudgetPeriod.yearly:
        writer.writeByte(3);
        break;
      case BudgetPeriod.custom:
        writer.writeByte(4);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BudgetPeriodAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class BudgetRolloverTypeAdapter extends TypeAdapter<BudgetRolloverType> {
  @override
  final int typeId = 13;

  @override
  BudgetRolloverType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return BudgetRolloverType.reset;
      case 1:
        return BudgetRolloverType.rollover;
      case 2:
        return BudgetRolloverType.accumulate;
      default:
        return BudgetRolloverType.reset;
    }
  }

  @override
  void write(BinaryWriter writer, BudgetRolloverType obj) {
    switch (obj) {
      case BudgetRolloverType.reset:
        writer.writeByte(0);
        break;
      case BudgetRolloverType.rollover:
        writer.writeByte(1);
        break;
      case BudgetRolloverType.accumulate:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BudgetRolloverTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
