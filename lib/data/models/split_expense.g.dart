// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'split_expense.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SplitExpenseAdapter extends TypeAdapter<SplitExpense> {
  @override
  final int typeId = 7;

  @override
  SplitExpense read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SplitExpense(
      id: fields[0] as String,
      name: fields[1] as String,
      description: fields[2] as String?,
      totalAmount: fields[3] as double,
      currency: fields[4] as String,
      categoryId: fields[5] as String,
      date: fields[6] as DateTime,
      paidByUserId: fields[7] as String,
      participants: (fields[8] as List).cast<SplitParticipant>(),
      splitType: fields[9] as SplitType,
      status: fields[10] as SplitStatus,
      createdAt: fields[11] as DateTime,
      updatedAt: fields[12] as DateTime,
      imagePath: fields[13] as String?,
      notes: fields[14] as String?,
      relatedTransactionId: fields[15] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, SplitExpense obj) {
    writer
      ..writeByte(16)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.totalAmount)
      ..writeByte(4)
      ..write(obj.currency)
      ..writeByte(5)
      ..write(obj.categoryId)
      ..writeByte(6)
      ..write(obj.date)
      ..writeByte(7)
      ..write(obj.paidByUserId)
      ..writeByte(8)
      ..write(obj.participants)
      ..writeByte(9)
      ..write(obj.splitType)
      ..writeByte(10)
      ..write(obj.status)
      ..writeByte(11)
      ..write(obj.createdAt)
      ..writeByte(12)
      ..write(obj.updatedAt)
      ..writeByte(13)
      ..write(obj.imagePath)
      ..writeByte(14)
      ..write(obj.notes)
      ..writeByte(15)
      ..write(obj.relatedTransactionId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SplitExpenseAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class SplitParticipantAdapter extends TypeAdapter<SplitParticipant> {
  @override
  final int typeId = 20;

  @override
  SplitParticipant read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SplitParticipant(
      userId: fields[0] as String,
      name: fields[1] as String,
      amountOwed: fields[2] as double,
      amountPaid: fields[3] as double,
      isSettled: fields[4] as bool,
      settledAt: fields[5] as DateTime?,
      email: fields[6] as String?,
      phone: fields[7] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, SplitParticipant obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.userId)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.amountOwed)
      ..writeByte(3)
      ..write(obj.amountPaid)
      ..writeByte(4)
      ..write(obj.isSettled)
      ..writeByte(5)
      ..write(obj.settledAt)
      ..writeByte(6)
      ..write(obj.email)
      ..writeByte(7)
      ..write(obj.phone);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SplitParticipantAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class SplitTypeAdapter extends TypeAdapter<SplitType> {
  @override
  final int typeId = 21;

  @override
  SplitType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return SplitType.equal;
      case 1:
        return SplitType.exact;
      case 2:
        return SplitType.percentage;
      case 3:
        return SplitType.shares;
      default:
        return SplitType.equal;
    }
  }

  @override
  void write(BinaryWriter writer, SplitType obj) {
    switch (obj) {
      case SplitType.equal:
        writer.writeByte(0);
        break;
      case SplitType.exact:
        writer.writeByte(1);
        break;
      case SplitType.percentage:
        writer.writeByte(2);
        break;
      case SplitType.shares:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SplitTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class SplitStatusAdapter extends TypeAdapter<SplitStatus> {
  @override
  final int typeId = 22;

  @override
  SplitStatus read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return SplitStatus.pending;
      case 1:
        return SplitStatus.partiallySettled;
      case 2:
        return SplitStatus.fullySettled;
      case 3:
        return SplitStatus.cancelled;
      default:
        return SplitStatus.pending;
    }
  }

  @override
  void write(BinaryWriter writer, SplitStatus obj) {
    switch (obj) {
      case SplitStatus.pending:
        writer.writeByte(0);
        break;
      case SplitStatus.partiallySettled:
        writer.writeByte(1);
        break;
      case SplitStatus.fullySettled:
        writer.writeByte(2);
        break;
      case SplitStatus.cancelled:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SplitStatusAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
