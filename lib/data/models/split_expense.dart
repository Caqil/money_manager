import 'package:hive/hive.dart';
import 'package:equatable/equatable.dart';

part 'split_expense.g.dart';

@HiveType(typeId: 7)
class SplitExpense extends Equatable {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String? description;

  @HiveField(3)
  final double totalAmount;

  @HiveField(4)
  final String currency;

  @HiveField(5)
  final String categoryId;

  @HiveField(6)
  final DateTime date;

  @HiveField(7)
  final String paidByUserId; // Who paid initially

  @HiveField(8)
  final List<SplitParticipant> participants;

  @HiveField(9)
  final SplitType splitType;

  @HiveField(10)
  final SplitStatus status;

  @HiveField(11)
  final DateTime createdAt;

  @HiveField(12)
  final DateTime updatedAt;

  @HiveField(13)
  final String? imagePath; // Receipt image

  @HiveField(14)
  final String? notes;

  @HiveField(15)
  final String? relatedTransactionId;

  const SplitExpense({
    required this.id,
    required this.name,
    this.description,
    required this.totalAmount,
    this.currency = 'USD',
    required this.categoryId,
    required this.date,
    required this.paidByUserId,
    required this.participants,
    required this.splitType,
    this.status = SplitStatus.pending,
    required this.createdAt,
    required this.updatedAt,
    this.imagePath,
    this.notes,
    this.relatedTransactionId,
  });

  SplitExpense copyWith({
    String? id,
    String? name,
    String? description,
    double? totalAmount,
    String? currency,
    String? categoryId,
    DateTime? date,
    String? paidByUserId,
    List<SplitParticipant>? participants,
    SplitType? splitType,
    SplitStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? imagePath,
    String? notes,
    String? relatedTransactionId,
  }) {
    return SplitExpense(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      totalAmount: totalAmount ?? this.totalAmount,
      currency: currency ?? this.currency,
      categoryId: categoryId ?? this.categoryId,
      date: date ?? this.date,
      paidByUserId: paidByUserId ?? this.paidByUserId,
      participants: participants ?? this.participants,
      splitType: splitType ?? this.splitType,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      imagePath: imagePath ?? this.imagePath,
      notes: notes ?? this.notes,
      relatedTransactionId: relatedTransactionId ?? this.relatedTransactionId,
    );
  }

  double get totalAmountOwed {
    return participants.fold(0.0, (sum, p) => sum + p.amountOwed);
  }

  double get totalAmountPaid {
    return participants.fold(0.0, (sum, p) => sum + p.amountPaid);
  }

  bool get isFullySettled {
    return participants.every((p) => p.isSettled);
  }

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        totalAmount,
        currency,
        categoryId,
        date,
        paidByUserId,
        participants,
        splitType,
        status,
        createdAt,
        updatedAt,
        imagePath,
        notes,
        relatedTransactionId,
      ];
}

@HiveType(typeId: 20)
class SplitParticipant extends Equatable {
  @HiveField(0)
  final String userId;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final double amountOwed;

  @HiveField(3)
  final double amountPaid;

  @HiveField(4)
  final bool isSettled;

  @HiveField(5)
  final DateTime? settledAt;

  @HiveField(6)
  final String? email; // For notifications

  @HiveField(7)
  final String? phone;

  const SplitParticipant({
    required this.userId,
    required this.name,
    required this.amountOwed,
    this.amountPaid = 0.0,
    this.isSettled = false,
    this.settledAt,
    this.email,
    this.phone,
  });

  SplitParticipant copyWith({
    String? userId,
    String? name,
    double? amountOwed,
    double? amountPaid,
    bool? isSettled,
    DateTime? settledAt,
    String? email,
    String? phone,
  }) {
    return SplitParticipant(
      userId: userId ?? this.userId,
      name: name ?? this.name,
      amountOwed: amountOwed ?? this.amountOwed,
      amountPaid: amountPaid ?? this.amountPaid,
      isSettled: isSettled ?? this.isSettled,
      settledAt: settledAt ?? this.settledAt,
      email: email ?? this.email,
      phone: phone ?? this.phone,
    );
  }

  double get remainingAmount => amountOwed - amountPaid;

  @override
  List<Object?> get props => [
        userId,
        name,
        amountOwed,
        amountPaid,
        isSettled,
        settledAt,
        email,
        phone,
      ];
}

@HiveType(typeId: 21)
enum SplitType {
  @HiveField(0)
  equal, // Split equally among all participants
  @HiveField(1)
  exact, // Specific amounts for each participant
  @HiveField(2)
  percentage, // Percentage-based split
  @HiveField(3)
  shares, // Share-based split (e.g., 2:1:1 ratio)
}

@HiveType(typeId: 22)
enum SplitStatus {
  @HiveField(0)
  pending,
  @HiveField(1)
  partiallySettled,
  @HiveField(2)
  fullySettled,
  @HiveField(3)
  cancelled,
}
