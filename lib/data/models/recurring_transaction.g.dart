// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recurring_transaction.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class RecurringTransactionAdapter extends TypeAdapter<RecurringTransaction> {
  @override
  final int typeId = 5;

  @override
  RecurringTransaction read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return RecurringTransaction(
      id: fields[0] as String,
      name: fields[1] as String,
      amount: fields[2] as double,
      categoryId: fields[3] as String,
      type: fields[4] as TransactionType,
      accountId: fields[5] as String,
      frequency: fields[6] as RecurrenceFrequency,
      startDate: fields[7] as DateTime,
      endDate: fields[8] as DateTime?,
      isActive: fields[9] as bool,
      lastExecuted: fields[10] as DateTime?,
      nextExecution: fields[11] as DateTime?,
      notes: fields[12] as String?,
      currency: fields[13] as String,
      intervalValue: fields[14] as int,
      weekdays: (fields[15] as List?)?.cast<int>(),
      dayOfMonth: fields[16] as int?,
      monthsOfYear: (fields[17] as List?)?.cast<int>(),
      createdAt: fields[18] as DateTime,
      updatedAt: fields[19] as DateTime,
      enableNotifications: fields[20] as bool,
      notificationDaysBefore: fields[21] as int,
      transferToAccountId: fields[22] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, RecurringTransaction obj) {
    writer
      ..writeByte(23)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.amount)
      ..writeByte(3)
      ..write(obj.categoryId)
      ..writeByte(4)
      ..write(obj.type)
      ..writeByte(5)
      ..write(obj.accountId)
      ..writeByte(6)
      ..write(obj.frequency)
      ..writeByte(7)
      ..write(obj.startDate)
      ..writeByte(8)
      ..write(obj.endDate)
      ..writeByte(9)
      ..write(obj.isActive)
      ..writeByte(10)
      ..write(obj.lastExecuted)
      ..writeByte(11)
      ..write(obj.nextExecution)
      ..writeByte(12)
      ..write(obj.notes)
      ..writeByte(13)
      ..write(obj.currency)
      ..writeByte(14)
      ..write(obj.intervalValue)
      ..writeByte(15)
      ..write(obj.weekdays)
      ..writeByte(16)
      ..write(obj.dayOfMonth)
      ..writeByte(17)
      ..write(obj.monthsOfYear)
      ..writeByte(18)
      ..write(obj.createdAt)
      ..writeByte(19)
      ..write(obj.updatedAt)
      ..writeByte(20)
      ..write(obj.enableNotifications)
      ..writeByte(21)
      ..write(obj.notificationDaysBefore)
      ..writeByte(22)
      ..write(obj.transferToAccountId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecurringTransactionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class RecurrenceFrequencyAdapter extends TypeAdapter<RecurrenceFrequency> {
  @override
  final int typeId = 18;

  @override
  RecurrenceFrequency read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return RecurrenceFrequency.daily;
      case 1:
        return RecurrenceFrequency.weekly;
      case 2:
        return RecurrenceFrequency.monthly;
      case 3:
        return RecurrenceFrequency.quarterly;
      case 4:
        return RecurrenceFrequency.yearly;
      case 5:
        return RecurrenceFrequency.custom;
      default:
        return RecurrenceFrequency.daily;
    }
  }

  @override
  void write(BinaryWriter writer, RecurrenceFrequency obj) {
    switch (obj) {
      case RecurrenceFrequency.daily:
        writer.writeByte(0);
        break;
      case RecurrenceFrequency.weekly:
        writer.writeByte(1);
        break;
      case RecurrenceFrequency.monthly:
        writer.writeByte(2);
        break;
      case RecurrenceFrequency.quarterly:
        writer.writeByte(3);
        break;
      case RecurrenceFrequency.yearly:
        writer.writeByte(4);
        break;
      case RecurrenceFrequency.custom:
        writer.writeByte(5);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecurrenceFrequencyAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
