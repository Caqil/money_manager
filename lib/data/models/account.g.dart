// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'account.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AccountAdapter extends TypeAdapter<Account> {
  @override
  final int typeId = 3;

  @override
  Account read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Account(
      id: fields[0] as String,
      name: fields[1] as String,
      balance: fields[2] as double,
      currency: fields[3] as String,
      type: fields[4] as AccountType,
      description: fields[5] as String?,
      iconName: fields[6] as String?,
      color: fields[7] as int?,
      isActive: fields[8] as bool,
      includeInTotal: fields[9] as bool,
      creditLimit: fields[10] as double?,
      lastSyncDate: fields[11] as DateTime?,
      createdAt: fields[12] as DateTime,
      updatedAt: fields[13] as DateTime,
      bankName: fields[14] as String?,
      accountNumber: fields[15] as String?,
      metadata: (fields[16] as Map?)?.cast<String, dynamic>(),
    );
  }

  @override
  void write(BinaryWriter writer, Account obj) {
    writer
      ..writeByte(17)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.balance)
      ..writeByte(3)
      ..write(obj.currency)
      ..writeByte(4)
      ..write(obj.type)
      ..writeByte(5)
      ..write(obj.description)
      ..writeByte(6)
      ..write(obj.iconName)
      ..writeByte(7)
      ..write(obj.color)
      ..writeByte(8)
      ..write(obj.isActive)
      ..writeByte(9)
      ..write(obj.includeInTotal)
      ..writeByte(10)
      ..write(obj.creditLimit)
      ..writeByte(11)
      ..write(obj.lastSyncDate)
      ..writeByte(12)
      ..write(obj.createdAt)
      ..writeByte(13)
      ..write(obj.updatedAt)
      ..writeByte(14)
      ..write(obj.bankName)
      ..writeByte(15)
      ..write(obj.accountNumber)
      ..writeByte(16)
      ..write(obj.metadata);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AccountAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class AccountTypeAdapter extends TypeAdapter<AccountType> {
  @override
  final int typeId = 14;

  @override
  AccountType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return AccountType.cash;
      case 1:
        return AccountType.checking;
      case 2:
        return AccountType.savings;
      case 3:
        return AccountType.creditCard;
      case 4:
        return AccountType.investment;
      case 5:
        return AccountType.loan;
      case 6:
        return AccountType.other;
      default:
        return AccountType.cash;
    }
  }

  @override
  void write(BinaryWriter writer, AccountType obj) {
    switch (obj) {
      case AccountType.cash:
        writer.writeByte(0);
        break;
      case AccountType.checking:
        writer.writeByte(1);
        break;
      case AccountType.savings:
        writer.writeByte(2);
        break;
      case AccountType.creditCard:
        writer.writeByte(3);
        break;
      case AccountType.investment:
        writer.writeByte(4);
        break;
      case AccountType.loan:
        writer.writeByte(5);
        break;
      case AccountType.other:
        writer.writeByte(6);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AccountTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
