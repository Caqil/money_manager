// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'goal.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class GoalAdapter extends TypeAdapter<Goal> {
  @override
  final int typeId = 4;

  @override
  Goal read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Goal(
      id: fields[0] as String,
      name: fields[1] as String,
      description: fields[2] as String?,
      targetAmount: fields[3] as double,
      currentAmount: fields[4] as double,
      targetDate: fields[5] as DateTime?,
      type: fields[6] as GoalType,
      priority: fields[7] as GoalPriority,
      currency: fields[8] as String,
      isActive: fields[9] as bool,
      categoryId: fields[10] as String?,
      accountIds: (fields[11] as List?)?.cast<String>(),
      createdAt: fields[12] as DateTime,
      updatedAt: fields[13] as DateTime,
      iconName: fields[14] as String?,
      color: fields[15] as int?,
      enableNotifications: fields[16] as bool,
      monthlyTarget: fields[17] as double,
      milestones: (fields[18] as List?)?.cast<GoalMilestone>(),
    );
  }

  @override
  void write(BinaryWriter writer, Goal obj) {
    writer
      ..writeByte(19)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.targetAmount)
      ..writeByte(4)
      ..write(obj.currentAmount)
      ..writeByte(5)
      ..write(obj.targetDate)
      ..writeByte(6)
      ..write(obj.type)
      ..writeByte(7)
      ..write(obj.priority)
      ..writeByte(8)
      ..write(obj.currency)
      ..writeByte(9)
      ..write(obj.isActive)
      ..writeByte(10)
      ..write(obj.categoryId)
      ..writeByte(11)
      ..write(obj.accountIds)
      ..writeByte(12)
      ..write(obj.createdAt)
      ..writeByte(13)
      ..write(obj.updatedAt)
      ..writeByte(14)
      ..write(obj.iconName)
      ..writeByte(15)
      ..write(obj.color)
      ..writeByte(16)
      ..write(obj.enableNotifications)
      ..writeByte(17)
      ..write(obj.monthlyTarget)
      ..writeByte(18)
      ..write(obj.milestones);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GoalAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class GoalMilestoneAdapter extends TypeAdapter<GoalMilestone> {
  @override
  final int typeId = 17;

  @override
  GoalMilestone read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return GoalMilestone(
      id: fields[0] as String,
      name: fields[1] as String,
      amount: fields[2] as double,
      isCompleted: fields[3] as bool,
      completedAt: fields[4] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, GoalMilestone obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.amount)
      ..writeByte(3)
      ..write(obj.isCompleted)
      ..writeByte(4)
      ..write(obj.completedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GoalMilestoneAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class GoalTypeAdapter extends TypeAdapter<GoalType> {
  @override
  final int typeId = 15;

  @override
  GoalType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return GoalType.savings;
      case 1:
        return GoalType.debtPayoff;
      case 2:
        return GoalType.purchase;
      case 3:
        return GoalType.emergency;
      case 4:
        return GoalType.investment;
      case 5:
        return GoalType.vacation;
      case 6:
        return GoalType.education;
      case 7:
        return GoalType.retirement;
      case 8:
        return GoalType.other;
      default:
        return GoalType.savings;
    }
  }

  @override
  void write(BinaryWriter writer, GoalType obj) {
    switch (obj) {
      case GoalType.savings:
        writer.writeByte(0);
        break;
      case GoalType.debtPayoff:
        writer.writeByte(1);
        break;
      case GoalType.purchase:
        writer.writeByte(2);
        break;
      case GoalType.emergency:
        writer.writeByte(3);
        break;
      case GoalType.investment:
        writer.writeByte(4);
        break;
      case GoalType.vacation:
        writer.writeByte(5);
        break;
      case GoalType.education:
        writer.writeByte(6);
        break;
      case GoalType.retirement:
        writer.writeByte(7);
        break;
      case GoalType.other:
        writer.writeByte(8);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GoalTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class GoalPriorityAdapter extends TypeAdapter<GoalPriority> {
  @override
  final int typeId = 16;

  @override
  GoalPriority read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return GoalPriority.low;
      case 1:
        return GoalPriority.medium;
      case 2:
        return GoalPriority.high;
      case 3:
        return GoalPriority.urgent;
      default:
        return GoalPriority.low;
    }
  }

  @override
  void write(BinaryWriter writer, GoalPriority obj) {
    switch (obj) {
      case GoalPriority.low:
        writer.writeByte(0);
        break;
      case GoalPriority.medium:
        writer.writeByte(1);
        break;
      case GoalPriority.high:
        writer.writeByte(2);
        break;
      case GoalPriority.urgent:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GoalPriorityAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
